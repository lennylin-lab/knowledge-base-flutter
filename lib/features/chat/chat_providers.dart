import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/sse_client.dart';
import '../../shared/models/chat.dart';
import '../../shared/models/search.dart';
import 'chat_repository.dart';

/// Chat repository wired to the app-wide SSE client; override this in tests
/// (provider-guidelines spec).
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(sseClientProvider)),
);

/// Phase of one single-turn QA run (state-management spec):
///
/// `idle → running → streaming → done | error`
///
/// - [ChatPhase.idle]: nothing running; may still hold the last run's
///   rendered answer/sources (after `cancel()`).
/// - [ChatPhase.running]: request opened, no event received yet.
/// - [ChatPhase.streaming]: at least the `run_started` event arrived; deltas
///   and sources are being accumulated.
/// - [ChatPhase.done]: terminal `done` event received.
/// - [ChatPhase.error]: terminal `error` event received; already-rendered
///   deltas/sources are kept.
enum ChatPhase { idle, running, streaming, done, error }

/// Immutable chat UI state: one stateless QA run.
///
/// [answer] concatenates `answer_delta` texts **verbatim** — never translate
/// or trim LLM answer text (component-guidelines spec). [sources] accumulates
/// across repeated `sources` events in arrival order; citation `[n]` in the
/// answer maps to the n-th (1-based) item of this list.
@immutable
class ChatState {
  const ChatState({
    this.phase = ChatPhase.idle,
    this.question = '',
    this.answer = '',
    this.sources = const <SearchHit>[],
    this.runId,
    this.mode,
    this.outcome,
    this.toolCalls,
    this.latencyMs,
    this.errorCode,
    this.errorMessage,
  });

  final ChatPhase phase;

  /// The question of the current (or last) run; `retry()` re-runs it.
  final String question;

  /// Accumulated answer text so far (empty until the first delta).
  final String answer;

  /// Accumulated retrieval sources in arrival order (may span several
  /// `sources` events).
  final List<SearchHit> sources;

  /// Run metadata from the `run_started` event.
  final String? runId;
  final SearchMode? mode;

  /// Terminal `done` metadata.
  final String? outcome;
  final int? toolCalls;
  final double? latencyMs;

  /// Terminal `error` metadata (payload mirrors the REST error envelope).
  final String? errorCode;
  final String? errorMessage;

  bool get isRunning => phase == ChatPhase.running || phase == ChatPhase.streaming;

  ChatState copyWith({
    ChatPhase? phase,
    String? question,
    String? answer,
    List<SearchHit>? sources,
    String? runId,
    SearchMode? mode,
    String? outcome,
    int? toolCalls,
    double? latencyMs,
    String? errorCode,
    String? errorMessage,
  }) {
    return ChatState(
      phase: phase ?? this.phase,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      sources: sources ?? this.sources,
      runId: runId ?? this.runId,
      mode: mode ?? this.mode,
      outcome: outcome ?? this.outcome,
      toolCalls: toolCalls ?? this.toolCalls,
      latencyMs: latencyMs ?? this.latencyMs,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Drives the single-turn chat SSE state machine
/// `idle → run_started → sources* → answer_delta* → done | error`
/// (state-management spec).
///
/// The notifier owns exactly one active subscription; asking a new question
/// or `retry()` cancels any previous run first, and `ref.onDispose` cancels
/// the subscription when the provider dies (no leaked streams, no ghost
/// deltas after the page is gone).
class ChatNotifier extends Notifier<ChatState> {
  StreamSubscription<ChatEvent>? _subscription;

  /// Bumped on every `ask`/`retry`/`cancel`; events of a superseded run
  /// (still in flight after a new run started) are dropped — same stale-run
  /// strategy as `SearchResultsNotifier._generation`.
  int _runGeneration = 0;

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  @override
  ChatState build() {
    // Dispose must not mutate state (the provider is going away) — only
    // cancel the subscription so no ghost deltas arrive after dispose.
    ref.onDispose(() {
      _runGeneration++;
      final subscription = _subscription;
      _subscription = null;
      unawaited(subscription?.cancel());
    });
    return const ChatState();
  }

  /// Starts one single-turn QA run for [question] (trimmed; empty input is
  /// ignored). Any run in progress is cancelled first — the previous partial
  /// answer is replaced by the new run's state.
  void ask(String question) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;
    _startRun(trimmed);
  }

  /// Re-runs the last question (error-pane retry button, or after cancel).
  /// No-op when no question has been asked yet.
  void retry() {
    final question = state.question;
    if (question.isEmpty) return;
    _startRun(question);
  }

  /// Aborts the run in progress. Already-rendered deltas/sources stay
  /// visible on screen; the page returns to [ChatPhase.idle] with the input
  /// re-enabled.
  void cancel() {
    _runGeneration++;
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    if (state.isRunning) {
      state = state.copyWith(phase: ChatPhase.idle);
    }
  }

  void _startRun(String question) {
    _runGeneration++;
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());

    state = ChatState(question: question, phase: ChatPhase.running);
    final generation = _runGeneration;
    _subscription = _repository.chat(question: question).listen(
      (event) {
        if (generation != _runGeneration) return; // superseded run
        _onEvent(event);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _runGeneration) return;
        // SseClient normalizes transport failures into ChatErrorEvent, so
        // this only fires for unexpected errors — surface them the same way.
        final api = toApiException(error);
        _onTerminalError(api.code, api.message);
      },
      onDone: () {
        // The stream closed. SseClient guarantees a terminal event before a
        // clean close; a subscription still active here (cancelled runs skip
        // this via the generation check) means the run is done either way.
        if (generation == _runGeneration) _subscription = null;
      },
    );
  }

  void _onEvent(ChatEvent event) {
    switch (event) {
      case RunStarted(:final runId, :final mode):
        state = state.copyWith(
          phase: ChatPhase.streaming,
          runId: runId,
          mode: mode,
        );
      case SourcesEvent(:final items):
        if (items.isNotEmpty) {
          state = state.copyWith(sources: [...state.sources, ...items]);
        }
      case AnswerDelta(:final text):
        state = state.copyWith(answer: state.answer + text);
      case ChatDone(:final runId, :final outcome, :final toolCalls, :final latencyMs):
        _finishRun();
        state = state.copyWith(
          phase: ChatPhase.done,
          runId: runId,
          outcome: outcome,
          toolCalls: toolCalls,
          latencyMs: latencyMs,
        );
      case ChatErrorEvent(:final code, :final message):
        _onTerminalError(code, message);
    }
  }

  /// Detaches the run's subscription on a terminal event — the stream would
  /// close on its own right after, but cancelling explicitly guarantees no
  /// listener outlives the run (no ghost deltas, no leak even if a transport
  /// misbehaves and keeps the stream open).
  void _finishRun() {
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
  }

  void _onTerminalError(String code, String message) {
    _finishRun();
    // Keep already-rendered deltas/sources; the error renders inline below
    // them (error-handling spec: the SSE layer, not dio, reports this).
    state = state.copyWith(
      phase: ChatPhase.error,
      errorCode: code,
      errorMessage: message,
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
