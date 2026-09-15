import '../../core/network/agent_stream_client.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../shared/models/agents_result.dart';
import '../../shared/models/agents_stream.dart';
import '../../shared/models/document.dart';

/// All documents endpoints — the only place this feature calls the network
/// (directory-structure spec). Plain REST goes through dio; errors are
/// normalized to [ApiException] via [toApiException] — features never parse
/// the error envelope themselves. The two synchronous LLM sub-endpoints
/// (`summary` / `associations`) stream `text/event-stream` and are consumed
/// through the shared [AgentStreamClient] (web-safe transport, one frame
/// parser); they still resolve to the same typed results as before.
class DocumentsRepository {
  DocumentsRepository(this._client, {AgentStreamClient? agentStream})
    : _agentStream = agentStream ?? AgentStreamClient(baseUrl: _client.baseUrl);

  final ApiClient _client;
  final AgentStreamClient _agentStream;

  static const String _basePath = '/api/v1/documents';

  /// `limit` bounds of the documents list endpoint (API contract).
  static const int minLimit = 1;
  static const int maxLimit = 100;
  static const int defaultLimit = 20;

  /// Clamps [limit] into the API's 1–100 range before sending
  /// (type-safety spec: validate at the boundary).
  static int clampLimit(int limit) => limit.clamp(minLimit, maxLimit).toInt();

  /// Keyset-paginated list. [cursor] is the opaque `next_cursor` of the
  /// previous page (null = first page) — never parsed or constructed
  /// client-side. A `null` [DocumentPage.nextCursor] in the result means
  /// end of list, not an error. [tags] filters server-side: each tag is a
  /// repeated `tag` query param and the backend ANDs them (a document must
  /// carry every tag).
  Future<DocumentPage> list({
    String? cursor,
    int limit = defaultLimit,
    List<String> tags = const [],
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        _basePath,
        queryParameters: <String, dynamic>{
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': clampLimit(limit),
          if (tags.isNotEmpty) 'tag': tags,
        },
      );
      return DocumentPage.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Single document including the full Markdown `content`.
  Future<DocumentReadDetail> get(String id) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '$_basePath/$id',
      );
      return DocumentReadDetail.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Creates a document from the full Markdown (YAML front matter
  /// included). The backend derives `title`/`tags` from the front matter;
  /// the returned item starts with `index_status: pending`.
  Future<DocumentRead> create(DocumentCreate payload) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        _basePath,
        data: payload.toJson(),
      );
      return DocumentRead.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Partial update (`content` and/or `title`, at least one — validated
  /// server-side as 422 `validation_failed`).
  Future<DocumentRead> update(String id, DocumentUpdate payload) async {
    try {
      final response = await _client.dio.patch<Map<String, dynamic>>(
        '$_basePath/$id',
        data: payload.toJson(),
      );
      return DocumentRead.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Soft-deletes the document (204). Subsequent reads of the id return
  /// 404 `not_found`.
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<void>('$_basePath/$id');
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Computes an LLM summary of the document by consuming its agent SSE
  /// stream (`run_started → summary_progress* → summary → done`). Sends no
  /// body and no query — the server takes only the path id.
  ///
  /// [onProgress] fires for every `summary_progress` event, in wire order.
  /// The future completes with the `summary` event payload (identical
  /// fields to the old JSON body). Failures surface as [ApiException]:
  /// a terminal `error` event keeps its wire `code`/`message` (e.g. 503
  /// `chat_unavailable`, `llm_provider_error`), a pre-stream non-2xx error
  /// envelope (404 `not_found`, 401/403) keeps its code, and a stream that
  /// ends — or a transport that drops — without a result is a
  /// `network_error` (mirroring `SseClient`'s normalization).
  Future<SummaryResult> summarize(
    String id, {
    void Function(SummaryProgress progress)? onProgress,
  }) {
    return _runAgentStream(
      Uri.parse('${_client.baseUrl}$_basePath/$id/summary'),
      onProgress: onProgress,
      extract: (event) => event is AgentSummaryEvent ? event.result : null,
    );
  }

  /// Computes LLM-curated related documents by consuming its agent SSE
  /// stream (`run_started → associations → done`). Sends no body and no
  /// query — the server takes only the path id; the result may be empty.
  /// [onProgress] mirrors [summarize]'s for shape symmetry, but the
  /// associations stream has no progress events today, so it never fires.
  /// Same failure surface as [summarize].
  Future<AssociationsResult> listAssociations(
    String id, {
    void Function(SummaryProgress progress)? onProgress,
  }) {
    return _runAgentStream(
      Uri.parse('${_client.baseUrl}$_basePath/$id/associations'),
      onProgress: onProgress,
      extract: (event) => event is AgentAssociationsEvent ? event.result : null,
    );
  }

  /// Opens one agent stream and folds its events into a single result.
  /// [extract] unwraps the expected result event's payload (null for the
  /// other kind — a server mix-up is treated like a missing result).
  /// Terminal `error` events throw with their wire `code`/`message`; a
  /// stream that ends without a result is a `network_error` (the
  /// [AgentStreamClient] already normalizes transport drops to error
  /// events, so this backstop means "ended silently, no payload").
  Future<T> _runAgentStream<T>(
    Uri uri, {
    required T? Function(AgentStreamEvent event) extract,
    void Function(SummaryProgress progress)? onProgress,
  }) async {
    await for (final event in _agentStream.run(uri)) {
      switch (event) {
        case AgentRunStarted() || AgentDoneEvent():
          break; // stream lifecycle only — nothing to render, nothing to keep
        case final SummaryProgress progress:
          onProgress?.call(progress);
        case AgentErrorEvent(:final code, :final message, :final statusCode):
          throw ApiException(
            code: code,
            message: message,
            statusCode: statusCode,
          );
        case AgentSummaryEvent() || AgentAssociationsEvent():
          final result = extract(event);
          if (result != null) return result;
      }
    }
    throw const ApiException(code: 'network_error', message: '网络连接中断，请重试');
  }
}
