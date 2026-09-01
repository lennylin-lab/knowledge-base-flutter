import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/chat/chat_providers.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

import '../search/stub_search_repository.dart';
import 'stub_chat_repository.dart';

/// Drains the event loop: broadcast stream events are delivered via the
/// event loop rather than plain microtasks, so Riverpod's `container.pump()`
/// (which only awaits the scheduler) is not enough — a zero-duration timer
/// lands after the delivery timers.
Future<void> flush() => Future<void>.delayed(Duration.zero);

/// Notifier-level chat tests: the full SSE state machine
/// `idle → running → streaming → done | error` plus cancel / retry / dispose
/// semantics. Timing is controlled with broadcast stream controllers (events
/// added with no listener are dropped, so late events can be proven inert) —
/// no sleeps.
ProviderContainer _makeContainer(StubChatRepository repo) {
  final container = ProviderContainer(
    overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    retry: noAutomaticRetry,
  );
  addTearDown(container.dispose);
  // Keep the provider alive across awaits.
  container.listen(chatProvider, (_, _) {});
  return container;
}

void main() {
  test('starts idle with an empty answer and no sources', () {
    final container = _makeContainer(StubChatRepository());

    final state = container.read(chatProvider);
    expect(state.phase, ChatPhase.idle);
    expect(state.question, isEmpty);
    expect(state.answer, isEmpty);
    expect(state.sources, isEmpty);
  });

  test('empty or whitespace question is ignored (no request)', () {
    final repo = StubChatRepository();
    final container = _makeContainer(repo);

    container.read(chatProvider.notifier).ask('   ');

    expect(repo.chatCalls, isEmpty);
    expect(container.read(chatProvider).phase, ChatPhase.idle);
  });

  test('retry() without a previous question is a no-op', () {
    final repo = StubChatRepository();
    final container = _makeContainer(repo);

    container.read(chatProvider.notifier).retry();

    expect(repo.chatCalls, isEmpty);
  });

  test('full machine: run_started → sources ×2 (append) → deltas → done', () async {
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit) => controller.stream;
    final container = _makeContainer(repo);

    container.read(chatProvider.notifier).ask('知识库用什么检索？');
    await flush();

    expect(repo.chatCalls.single, (question: '知识库用什么检索？', limit: 8));
    var state = container.read(chatProvider);
    expect(state.phase, ChatPhase.running);
    expect(state.question, '知识库用什么检索？');

    controller.add(runStarted(runId: 'run-9', mode: SearchMode.bm25));
    await flush();
    state = container.read(chatProvider);
    expect(state.phase, ChatPhase.streaming);
    expect(state.runId, 'run-9');
    expect(state.mode, SearchMode.bm25);

    // Repeated `sources` events append cumulatively in arrival order.
    controller.add(
      sourcesEvent(items: [searchHit(documentId: 'a', title: '甲')]),
    );
    controller.add(
      sourcesEvent(items: [searchHit(documentId: 'b', title: '乙')]),
    );
    await flush();
    state = container.read(chatProvider);
    expect(state.sources.map((s) => s.documentId).toList(), ['a', 'b']);
    expect(state.sources.first.documentTitle, '甲');

    // Deltas concatenate verbatim.
    controller.add(answerDelta('混合'));
    controller.add(answerDelta('检索'));
    await flush();
    expect(container.read(chatProvider).answer, '混合检索');

    controller.add(chatDone(runId: 'run-9', toolCalls: 2, latencyMs: 2300));
    await flush();
    state = container.read(chatProvider);
    expect(state.phase, ChatPhase.done);
    expect(state.outcome, 'success');
    expect(state.toolCalls, 2);
    expect(state.latencyMs, 2300);
    expect(state.errorCode, isNull);
    expect(state.isRunning, isFalse);
    // Terminal `done` detaches the run's subscription — no listener outlives
    // the run (leak fix: _finishRun on the done path).
    expect(controller.hasListener, isFalse);

    await controller.close();
  });

  test('terminal error after deltas keeps rendered content and surfaces it', () async {
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit) => controller.stream;
    final container = _makeContainer(repo);

    container.read(chatProvider.notifier).ask('问题');
    await flush();
    controller.add(runStarted());
    controller.add(sourcesEvent(items: [searchHit(documentId: 'a')]));
    controller.add(answerDelta('部分答案'));
    controller.add(
      chatError(code: 'llm_provider_error', message: 'LLM provider is not configured'),
    );
    await flush();

    final state = container.read(chatProvider);
    expect(state.phase, ChatPhase.error);
    expect(state.errorCode, 'llm_provider_error');
    expect(state.errorMessage, 'LLM provider is not configured');
    // Already-rendered deltas/sources are kept under the error.
    expect(state.answer, '部分答案');
    expect(state.sources, hasLength(1));
    expect(state.isRunning, isFalse);
    // Terminal `error` detaches the run's subscription as well.
    expect(controller.hasListener, isFalse);

    await controller.close();
  });

  test('cancel() aborts the run and keeps the rendered content', () async {
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit) => controller.stream;
    final container = _makeContainer(repo);

    container.read(chatProvider.notifier).ask('问题');
    await flush();
    controller.add(runStarted());
    controller.add(answerDelta('部分'));
    await flush();
    expect(container.read(chatProvider).answer, '部分');
    expect(controller.hasListener, isTrue);

    container.read(chatProvider.notifier).cancel();
    await flush();

    expect(container.read(chatProvider).phase, ChatPhase.idle);
    expect(container.read(chatProvider).answer, '部分');
    expect(controller.hasListener, isFalse);

    // Late events from the cancelled run are dropped, not rendered.
    controller.add(answerDelta('幽灵'));
    await flush();
    expect(container.read(chatProvider).answer, '部分');

    await controller.close();
  });

  test('retry() re-runs the last question with a fresh state', () async {
    final first = StreamController<ChatEvent>.broadcast();
    final second = StreamController<ChatEvent>.broadcast();
    final controllers = [first, second];
    var callIndex = 0;
    final repo =
        StubChatRepository()..chatHandler = (q, limit) => controllers[callIndex++].stream;
    final container = _makeContainer(repo);

    container.read(chatProvider.notifier).ask('问题');
    await flush();
    first.add(runStarted());
    first.add(answerDelta('部分'));
    first.add(chatError());
    await flush();
    expect(container.read(chatProvider).phase, ChatPhase.error);

    container.read(chatProvider.notifier).retry();
    await flush();

    expect(repo.chatCalls.last, (question: '问题', limit: 8));
    var state = container.read(chatProvider);
    expect(state.phase, ChatPhase.running);
    expect(state.answer, isEmpty, reason: 'a fresh run resets the answer');
    expect(first.hasListener, isFalse);

    second.add(runStarted());
    second.add(answerDelta('完整答案'));
    second.add(chatDone());
    await flush();
    state = container.read(chatProvider);
    expect(state.phase, ChatPhase.done);
    expect(state.answer, '完整答案');

    await first.close();
    await second.close();
  });

  test('a new ask while running cancels the previous run', () async {
    final oldRun = StreamController<ChatEvent>.broadcast();
    final newRun = StreamController<ChatEvent>.broadcast();
    final repo =
        StubChatRepository()
          ..chatHandler = (q, limit) => q == 'first' ? oldRun.stream : newRun.stream;
    final container = _makeContainer(repo);

    container.read(chatProvider.notifier).ask('first');
    await flush();
    oldRun.add(runStarted());
    await flush();
    expect(container.read(chatProvider).phase, ChatPhase.streaming);

    container.read(chatProvider.notifier).ask('second');
    await flush();

    expect(repo.chatCalls, hasLength(2));
    expect(container.read(chatProvider).question, 'second');
    expect(container.read(chatProvider).phase, ChatPhase.running);
    expect(oldRun.hasListener, isFalse);

    // Events from the superseded run must not clobber the new run's state.
    oldRun.add(answerDelta('旧回答'));
    newRun.add(runStarted());
    newRun.add(answerDelta('新回答'));
    await flush();

    final state = container.read(chatProvider);
    expect(state.answer, '新回答');
    expect(state.phase, ChatPhase.streaming);

    await oldRun.close();
    await newRun.close();
  });

  test('disposing the container cancels the subscription (no ghost deltas)', () async {
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit) => controller.stream;
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
      retry: noAutomaticRetry,
    );
    container.listen(chatProvider, (_, _) {});

    container.read(chatProvider.notifier).ask('问题');
    await flush();
    expect(controller.hasListener, isTrue);

    container.dispose();
    expect(controller.hasListener, isFalse);

    // Adding after dispose must not throw and must not reach any listener.
    controller.add(answerDelta('幽灵'));
    await flush();
    await controller.close();
  });
}
