import '../../core/network/sse_client.dart';
import '../../shared/models/chat.dart';

/// The chat endpoint — the only place this feature talks to the SSE layer
/// (directory-structure spec). Every transport-level failure (connection
/// refused/dropped, non-2xx error envelope) is normalized by [SseClient]
/// into a terminal [ChatErrorEvent] carrying the envelope's `code` /
/// `message` — the stream itself never throws (state-management spec).
///
/// **Single-turn semantics**: there is no session history API. Each
/// [chat] call is one independent stateless QA run; the UI must not build
/// multi-turn conversation state on top of it (state-management
/// spec).
class ChatRepository {
  ChatRepository(this._sseClient);

  final SseClient _sseClient;

  /// `limit` bounds of the chat endpoint (API contract).
  static const int minLimit = 1;
  static const int maxLimit = 20;
  static const int defaultLimit = 8;

  /// Clamps [limit] into the API's 1–20 range before sending
  /// (type-safety spec: validate at the boundary).
  static int clampLimit(int limit) => limit.clamp(minLimit, maxLimit).toInt();

  /// Streams one single-turn QA run for [question] (min 1 char, validated
  /// server-side as 422 `validation_failed`).
  ///
  /// Event order guarantee: `run_started` → `sources*` → `answer_delta*` →
  /// `done`, or a terminal `error` at any point. `sources` may repeat —
  /// consumers append to the accumulated list. The stream ends right after
  /// the terminal event; a stream that ends without one yields a
  /// `network_error` [ChatErrorEvent].
  Stream<ChatEvent> chat({required String question, int limit = defaultLimit}) {
    return _sseClient.chatStream(
      ChatRequest(question: question, limit: clampLimit(limit)),
    );
  }
}
