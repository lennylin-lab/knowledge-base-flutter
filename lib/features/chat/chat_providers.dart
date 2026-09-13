import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/sse_client.dart';
import '../../shared/models/chat.dart';
import '../../shared/models/search.dart';
import '../../shared/models/session.dart';
import 'chat_repository.dart';
import 'session_repository.dart';

/// Chat repository wired to the app-wide SSE client; override this in tests
/// (provider-guidelines spec).
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(sseClientProvider)),
);

/// Session repository wired to the app-wide API client; override this in
/// tests (provider-guidelines spec).
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(apiClientProvider)),
);

/// Phase of the current chat run (state-management spec):
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

/// Immutable chat UI state: one persisted conversation plus the current
/// streaming run.
///
/// [history] holds the conversation so far — messages loaded from the
/// session detail (via `openSession`) and turns accumulated in-session
/// (a finished run appends the user question and assistant answer). The
/// [sessionId] is server-assigned: taken from `run_started`/`done`, sent
/// back on follow-up questions, cleared by `newSession()`.
///
/// [answer] concatenates `answer_delta` texts **verbatim** — never translate
/// or trim LLM answer text (component-guidelines spec). [sources] accumulates
/// across repeated `sources` events in arrival order; citation `[n]` in the
/// answer maps to the n-th (1-based) item of this list.
@immutable
class ChatState {
  const ChatState({
    this.phase = ChatPhase.idle,
    this.sessionId,
    this.history = const <ChatMessage>[],
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
    this.progress,
    this.rewrite,
    this.toolCallRows = const <ChatToolCallView>[],
  });

  final ChatPhase phase;

  /// Server-assigned id of the active conversation; `null` before the first
  /// `run_started` of a new conversation.
  final String? sessionId;

  /// Persisted conversation messages (chronological), excluding the
  /// in-flight run.
  final List<ChatMessage> history;

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

  /// Progress line announced by the current run's events — `status` phases
  /// and `tool_call_started` write it directly, so the latest event always
  /// wins. Cleared with the run's fresh state.
  final String? progress;

  /// The `query_rewritten` payload of the current run, when the rewrite
  /// changed the retrieval prompt (transparency UI; cleared on the next run).
  final QueryRewrittenEvent? rewrite;

  /// Tool calls of the current run in arrival order, upserted by `call_id`
  /// from `tool_call_started` / `tool_call_finished` events (timeline UI;
  /// cleared with the run's fresh state).
  final List<ChatToolCallView> toolCallRows;

  bool get isRunning => phase == ChatPhase.running || phase == ChatPhase.streaming;

  /// The progress line to show while a run is in flight; falls back to the
  /// phase-less texts matching the pre-progress-events behavior. Cleared
  /// once the answer starts streaming — the text itself is the progress.
  String? progressText() {
    if (!isRunning || answer.isNotEmpty) return null;
    return progress ??
        (phase == ChatPhase.running ? '正在思考…' : '正在生成回答…');
  }

  ChatState copyWith({
    ChatPhase? phase,
    String? sessionId,
    List<ChatMessage>? history,
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
    String? progress,
    QueryRewrittenEvent? rewrite,
    List<ChatToolCallView>? toolCallRows,
  }) {
    return ChatState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      history: history ?? this.history,
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
      progress: progress ?? this.progress,
      rewrite: rewrite ?? this.rewrite,
      toolCallRows: toolCallRows ?? this.toolCallRows,
    );
  }
}

/// One tool call of the current run as rendered in the timeline — a row is
/// created/updated by `tool_call_started` and completed by the matching
/// `tool_call_finished` ([status] stays `null` while the call is in flight).
@immutable
class ChatToolCallView {
  const ChatToolCallView({
    required this.callId,
    required this.toolName,
    this.query,
    this.status,
    this.latencyMs,
  });

  final String callId;
  final String toolName;

  /// Retrieval query for `search_knowledge` calls, from the started event's
  /// `args`.
  final String? query;
  final ChatToolStatus? status;
  final double? latencyMs;

  ChatToolCallView copyWith({
    String? query,
    ChatToolStatus? status,
    double? latencyMs,
  }) {
    return ChatToolCallView(
      callId: callId,
      toolName: toolName,
      query: query ?? this.query,
      status: status ?? this.status,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
}

/// Upserts the started call (replace in place when the `call_id` is already
/// tracked, append otherwise — wire contract: started precedes finished).
List<ChatToolCallView> _onToolStarted(
  List<ChatToolCallView> rows,
  ToolCallStartedEvent event,
) {
  final query = event.toolName == 'search_knowledge' && event.args['query'] is String
      ? event.args['query'] as String
      : null;
  final row = ChatToolCallView(callId: event.callId, toolName: event.toolName, query: query);
  final index = rows.indexWhere((r) => r.callId == event.callId);
  if (index < 0) return [...rows, row];
  final updated = [...rows];
  updated[index] = row.copyWith(status: rows[index].status, latencyMs: rows[index].latencyMs);
  return updated;
}

/// Completes the call matching [ToolCallFinishedEvent.callId]; a finished
/// event without a started row (defensive) appends a completed row.
List<ChatToolCallView> _onToolFinished(
  List<ChatToolCallView> rows,
  ToolCallFinishedEvent event,
) {
  final index = rows.indexWhere((r) => r.callId == event.callId);
  final base = index >= 0
      ? rows[index]
      : ChatToolCallView(callId: event.callId, toolName: event.toolName);
  final row = base.copyWith(status: event.status, latencyMs: event.latencyMs);
  if (index < 0) return [...rows, row];
  final updated = [...rows];
  updated[index] = row;
  return updated;
}

/// Drives the chat SSE state machine for one persisted conversation
/// `idle → run_started → sources* → answer_delta* → done | error`
/// (state-management spec).
///
/// Follow-up questions in the same conversation reuse the server-assigned
/// [ChatState.sessionId]; `newSession()` starts a fresh one. A finished run
/// appends its turn (`user` question + `assistant` answer) to the history.
///
/// The notifier owns exactly one active subscription; asking a new question
/// or `retry()` cancels any previous run first, and `ref.onDispose` cancels
/// the subscription when the provider dies (no leaked streams, no ghost
/// deltas after the page is gone).
class ChatNotifier extends Notifier<ChatState> {
  StreamSubscription<ChatEvent>? _subscription;

  /// Bumped on every `ask`/`retry`/`cancel`/`openSession`; events of a
  /// superseded run (still in flight after a new run started) are dropped —
  /// same stale-run strategy as `SearchResultsNotifier._generation`.
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

  /// Starts one QA run for [question] (trimmed; empty input is ignored),
  /// continuing the active session when one exists. Any run in progress is
  /// cancelled first — the previous partial answer is replaced by the new
  /// run's state.
  void ask(String question) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;
    _startRun(trimmed, state.sessionId);
  }

  /// Re-runs the last question (error-pane retry button, or after cancel).
  /// No-op when no question has been asked yet.
  void retry() {
    final question = state.question;
    if (question.isEmpty) return;
    _startRun(question, state.sessionId);
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

  /// Starts a fresh conversation: cancels any run and clears the session
  /// id, history, and last run's rendered state.
  void newSession() {
    _runGeneration++;
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    state = const ChatState();
  }

  /// Opens a persisted conversation: loads its messages and continues it on
  /// the next question. Any run in progress is cancelled first. A failed
  /// load (unknown id → 404) lands in [ChatPhase.error] with the envelope's
  /// code/message; the previous conversation state is kept intact.
  Future<void> openSession(String sessionId) async {
    _runGeneration++;
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());

    state = const ChatState(phase: ChatPhase.running);
    try {
      final detail = await ref.read(sessionRepositoryProvider).getSession(sessionId);
      state = ChatState(
        phase: ChatPhase.idle,
        sessionId: detail.id,
        history: detail.messages,
      );
    } catch (error) {
      final api = toApiException(error);
      state = ChatState(
        phase: ChatPhase.error,
        errorCode: api.code,
        errorMessage: api.message,
      );
    }
  }

  void _startRun(String question, String? sessionId) {
    _runGeneration++;
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());

    // Commit the previous run into the persisted-looking history before the
    // new one takes over the screen (history stays client-side rendering of
    // the server-persisted conversation; the server stores the same turns).
    final previous = state;
    final history = previous.question.isNotEmpty
        ? [
            ...previous.history,
            ChatMessage(
              id: previous.runId ?? previous.question,
              role: ChatMessageRole.user,
              content: previous.question,
              createdAt: DateTime.now(),
            ),
            ChatMessage(
              id: previous.runId ?? '${previous.question}-answer',
              role: ChatMessageRole.assistant,
              content: previous.answer,
              runId: previous.runId,
              createdAt: DateTime.now(),
            ),
          ]
        : previous.history;

    state = ChatState(
      sessionId: sessionId,
      history: history,
      question: question,
      phase: ChatPhase.running,
    );
    final generation = _runGeneration;
    _subscription = _repository
        .chat(question: question, sessionId: sessionId)
        .listen(
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
      case RunStarted(:final runId, :final mode, :final sessionId):
        state = state.copyWith(
          phase: ChatPhase.streaming,
          runId: runId,
          mode: mode,
          sessionId: sessionId,
        );
      case SourcesEvent(:final items):
        if (items.isNotEmpty) {
          state = state.copyWith(sources: [...state.sources, ...items]);
        }
      case AnswerDelta(:final text):
        state = state.copyWith(answer: state.answer + text);
      case ChatStatusEvent(:final phase):
        // The latest announced event wins — write the line directly.
        state = state.copyWith(
          progress: phase == ChatStatusPhase.rewritingQuery
              ? '正在理解问题…'
              : '正在生成回答…',
        );
      case QueryRewrittenEvent(:final original, :final rewritten):
        state = state.copyWith(
          rewrite: QueryRewrittenEvent(
            original: original,
            rewritten: rewritten,
          ),
        );
      case ToolCallStartedEvent(:final toolName, :final args):
        final query = args['query'] is String ? args['query'] as String : null;
        state = state.copyWith(
          // The latest announced event wins — write the line directly.
          progress: toolName == 'search_knowledge' && query != null
              ? '正在检索：$query'
              : null,
          toolCallRows: _onToolStarted(state.toolCallRows, event),
        );
      case ToolCallFinishedEvent():
        state = state.copyWith(
          toolCallRows: _onToolFinished(state.toolCallRows, event),
        );
      case ChatDone(
        :final runId,
        :final outcome,
        :final toolCalls,
        :final latencyMs,
        :final sessionId,
      ):
        // The finished turn stays fully rendered (question/answer/sources)
        // until the next run commits it into the history — see `_startRun`.
        _finishRun();
        state = state.copyWith(
          phase: ChatPhase.done,
          runId: runId,
          outcome: outcome,
          toolCalls: toolCalls,
          latencyMs: latencyMs,
          sessionId: sessionId,
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
