import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/chat/chat_providers.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

import '../documents/stub_documents_repository.dart';
import '../search/stub_search_repository.dart';
import 'stub_chat_repository.dart';

/// Pumps the full app (adaptive shell + real router) with the chat and
/// documents repositories stubbed — no dio, no network. Compact surface so
/// the bottom NavigationBar shows the 问答 destination.
Future<void> pumpChatApp(
  WidgetTester tester, {
  required StubChatRepository chatRepo,
  StubDocumentsRepository? documentsRepo,
}) async {
  final docsRepo =
      documentsRepo ??
      StubDocumentsRepository()
        ..listHandler =
            (cursor, limit, tag) async =>
                const DocumentPage(items: [], nextCursor: null);
  await tester.binding.setSurfaceSize(const Size(480, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(docsRepo),
        chatRepositoryProvider.overrideWithValue(chatRepo),
      ],
      retry: noAutomaticRetry,
      child: App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('问答').last);
  await tester.pumpAndSettle();
}

/// Types into the chat input and taps 发送.
Future<void> sendQuestion(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
  await tester.pump();
}

/// The chat page's send button widget (disabled while a run is in flight).
IconButton sendButton(WidgetTester tester) =>
    tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));

void main() {
  testWidgets('shows the 尚未提问 hint and fetches nothing', (tester) async {
    final repo = StubChatRepository();

    await pumpChatApp(tester, chatRepo: repo);

    expect(find.text('尚未提问'), findsOneWidget);
    expect(repo.chatCalls, isEmpty);
  });

  testWidgets('streams the answer progressively with a spinner; send is disabled '
      'while running; done shows latency/tool metadata', (tester) async {
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit, sessionId) => controller.stream;

    await pumpChatApp(tester, chatRepo: repo);
    await sendQuestion(tester, '什么是 RAG？');

    expect(repo.chatCalls.single, (question: '什么是 RAG？', limit: 8, sessionId: null));
    expect(find.text('正在思考…'), findsOneWidget);
    expect(find.text('问：什么是 RAG？'), findsOneWidget);
    expect(sendButton(tester).onPressed, isNull, reason: 'send disabled while running');

    controller.add(runStarted());
    await tester.pump();
    expect(find.text('正在生成回答…'), findsOneWidget);

    controller.add(answerDelta('混合'));
    await tester.pump();
    expect(find.text('混合'), findsOneWidget, reason: 'delta rendered as markdown');

    controller.add(answerDelta('检索'));
    await tester.pump();
    expect(find.text('混合检索'), findsOneWidget, reason: 'deltas concatenate');
    expect(find.text('混合'), findsNothing);

    controller.add(chatDone(toolCalls: 2, latencyMs: 2300));
    await tester.pumpAndSettle();

    expect(find.text('正在生成回答…'), findsNothing);
    expect(find.text('回答完成 · 耗时 2.3s · 工具调用 2 次'), findsOneWidget);
    expect(sendButton(tester).onPressed, isNotNull, reason: 'send re-enabled after done');

    await controller.close();
  });

  testWidgets('lists sources with citation numbers; tapping one opens the document',
      (tester) async {
    final docsRepo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return const DocumentPage(items: [], nextCursor: null);
          }
          ..getHandler = (id) async {
            return documentReadDetail(
              documentRead(id: id, title: '来源文档 $id'),
              content: '# 详情',
            );
          };
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit, sessionId) => controller.stream;

    await pumpChatApp(tester, chatRepo: repo, documentsRepo: docsRepo);
    await sendQuestion(tester, '来源有哪些？');

    controller.add(runStarted());
    controller.add(
      sourcesEvent(
        items: [
          searchHit(documentId: 'doc-a', title: '检索笔记', content: '混合检索片段'),
          searchHit(documentId: 'doc-b', title: '向量入门'),
        ],
      ),
    );
    controller.add(answerDelta('见来源'));
    controller.add(chatDone());
    await tester.pumpAndSettle();

    expect(find.text('参考来源'), findsOneWidget);
    expect(find.text('答案中的 [1][2] 对应下方来源序号'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('检索笔记'), findsOneWidget);
    expect(find.text('向量入门'), findsOneWidget);
    expect(find.text('混合检索片段'), findsOneWidget);

    await tester.tap(find.text('向量入门'));
    await tester.pumpAndSettle();

    expect(docsRepo.getCalls.single, 'doc-b');
    expect(find.text('来源文档 doc-b'), findsWidgets); // detail app bar + headline

    await controller.close();
  });

  testWidgets('progress events drive the progress line; rewrite is disclosed; '
      'a failed tool shows a non-fatal warning', (tester) async {
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit, sessionId) => controller.stream;

    await pumpChatApp(tester, chatRepo: repo);
    await sendQuestion(tester, '那它的缺点呢？');

    controller.add(runStarted());
    controller.add(statusEvent(ChatStatusPhase.rewritingQuery));
    await tester.pump();
    expect(find.text('正在理解问题…'), findsOneWidget);

    controller.add(queryRewritten());
    await tester.pump();
    expect(find.text('已改写检索词'), findsOneWidget);
    // Collapsed by default — details only after expansion.
    expect(find.text('原始问题：那它的缺点呢？'), findsNothing);
    await tester.tap(find.text('已改写检索词'));
    // Fixed-duration pump: the in-flight run spins an endless progress
    // spinner, so pumpAndSettle would never settle.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('原始问题：那它的缺点呢？'), findsOneWidget);
    expect(find.text('改写检索词：Redis 分布式锁的缺点是什么？'), findsOneWidget);

    controller.add(toolCallStarted());
    await tester.pump();
    expect(find.text('正在检索：Redis 分布式锁的缺点'), findsOneWidget);

    controller.add(statusEvent(ChatStatusPhase.generating));
    await tester.pump();
    expect(find.text('正在生成回答…'), findsOneWidget);

    controller.add(toolCallStarted(toolName: 'mcp_weather', args: {}));
    controller.add(
      toolCallFinished(
        toolName: 'mcp_weather',
        status: ChatToolStatus.failed,
        latencyMs: 42,
      ),
    );
    await tester.pump();
    // Timeline section appears with the failure summary, collapsed by default.
    expect(find.text('工具调用'), findsOneWidget);
    expect(find.text('1 次 · 1 次失败'), findsOneWidget);
    expect(find.text('mcp_weather'), findsNothing);
    await tester.tap(find.text('工具调用'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('mcp_weather'), findsOneWidget);
    expect(find.text('42 ms'), findsOneWidget);

    controller.add(answerDelta('仍能回答 [1]。'));
    controller.add(chatDone());
    await tester.pumpAndSettle();

    expect(find.text('正在生成回答…'), findsNothing);
    expect(find.text('工具调用'), findsOneWidget, reason: 'timeline stays after done');
    expect(find.text('仍能回答 [1]。'), findsOneWidget);

    await controller.close();
  });

  testWidgets('terminal error renders inline, keeps deltas and retries', (
    tester,
  ) async {
    final first = StreamController<ChatEvent>.broadcast();
    final second = StreamController<ChatEvent>.broadcast();
    final controllers = [first, second];
    var calls = 0;
    final repo =
        StubChatRepository()..chatHandler = (q, limit, sessionId) => controllers[calls++].stream;

    await pumpChatApp(tester, chatRepo: repo);
    await sendQuestion(tester, '问题');

    first.add(runStarted());
    first.add(answerDelta('部分答案'));
    first.add(
      chatError(code: 'llm_provider_error', message: 'LLM provider is not configured'),
    );
    await tester.pump();

    expect(find.text('部分答案'), findsOneWidget, reason: 'deltas kept under the error');
    expect(find.text('回答失败：LLM provider is not configured'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();

    expect(calls, 2);
    expect(find.text('正在思考…'), findsOneWidget);

    second.add(runStarted());
    second.add(answerDelta('完整答案'));
    second.add(chatDone());
    await tester.pumpAndSettle();

    expect(find.text('完整答案'), findsOneWidget);
    expect(find.text('回答失败：LLM provider is not configured'), findsNothing);

    await first.close();
    await second.close();
  });

  testWidgets('stopping mid-stream cancels the run and keeps the partial answer', (
    tester,
  ) async {
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit, sessionId) => controller.stream;

    await pumpChatApp(tester, chatRepo: repo);
    await sendQuestion(tester, '问题');

    controller.add(runStarted());
    controller.add(answerDelta('部分'));
    await tester.pump();
    // The progress line cleared once the answer started streaming (PRD:
    // progress is superseded by the answer text itself).
    expect(find.text('正在生成回答…'), findsNothing);

    await tester.tap(find.byTooltip('停止'));
    await tester.pump();

    expect(find.text('部分'), findsOneWidget, reason: 'partial answer stays visible');
    expect(sendButton(tester).onPressed, isNotNull, reason: 'input re-enabled');
    expect(controller.hasListener, isFalse, reason: 'subscription cancelled');

    await controller.close();
  });

  testWidgets('a done run without deltas renders 未生成回答内容', (tester) async {
    final controller = StreamController<ChatEvent>.broadcast();
    final repo = StubChatRepository()..chatHandler = (q, limit, sessionId) => controller.stream;

    await pumpChatApp(tester, chatRepo: repo);
    await sendQuestion(tester, '问题');

    controller.add(runStarted());
    controller.add(chatDone());
    await tester.pumpAndSettle();

    expect(find.text('未生成回答内容'), findsOneWidget);
    expect(find.textContaining('回答完成'), findsOneWidget);

    await controller.close();
  });
}
