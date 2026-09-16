import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../shared/models/operation.dart';

/// All `/api/v1/operations` endpoints — the only place the operations
/// feature calls the network (directory-structure spec). All six routes are
/// synchronous JSON (draft is NOT part of the agent SSE family); errors are
/// normalized to [ApiException] via [toApiException] — features never parse
/// the error envelope themselves, so 409 `conflict` (with `details.state` /
/// `details.base_version` / `details.current_version`), 404, 503 and 502
/// surface with codes and details intact.
class OperationsRepository {
  OperationsRepository(this._client);

  final ApiClient _client;

  static const String _basePath = '/api/v1/operations';

  /// Creates an operation from an existing draft (201). Idempotent on
  /// `OperationCreate.idempotencyKey`: a retry with the same key returns the
  /// original operation verbatim (server-side — the client only pins the key
  /// in the body).
  Future<OperationReadDetail> createOperation(OperationCreate payload) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        _basePath,
        data: payload.toJson(),
      );
      return OperationReadDetail.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Runs the writing agent synchronously on the document and returns the
  /// finished operation (`completed` + draft, or `failed` + error).
  /// Parameters travel as **query** params per the server contract —
  /// [instruction] is omitted when null or empty — and the request carries
  /// **no body**. 503 `chat_unavailable` (provider not configured) fires
  /// before validation; LLM failures surface as 502 `llm_provider_error` /
  /// 429 `rate_limited` with the operation left `failed` (resumable).
  Future<OperationReadDetail> draft({
    required String documentId,
    String? instruction,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '$_basePath/draft',
        queryParameters: <String, dynamic>{
          'document_id': documentId,
          if (instruction != null && instruction.isNotEmpty)
            'instruction': instruction,
        },
      );
      return OperationReadDetail.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Fetches one operation by id (404 `not_found` when missing or owned by
  /// another tenant).
  Future<OperationReadDetail> operation(String operationId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '$_basePath/$operationId',
      );
      return OperationReadDetail.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Lists a document's operations, newest first — the server caps the list
  /// at 50 and does not paginate.
  Future<List<OperationReadDetail>> operationsForDocument(
    String documentId,
  ) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '$_basePath/documents/$documentId',
      );
      return response.data!
          .map(
            (item) =>
                OperationReadDetail.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Resumes an interrupted/failed operation (any other state → 409
  /// `conflict` with `details.state`). Sends no body unless [draft]
  /// amends the stored draft (the server re-validates its front matter —
  /// invalid YAML → 422). Success sets `completed` and clears the error.
  Future<OperationReadDetail> resume(
    String operationId, {
    DraftContent? draft,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '$_basePath/$operationId/resume',
        data: draft == null ? null : OperationTransition(draft: draft).toJson(),
      );
      return OperationReadDetail.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Applies the operation's draft to its document and returns the applied
  /// operation, the created revision, and the mutated document (indexing
  /// restarted, `updated_at` bumped — which invalidates other operations'
  /// base versions). [expectedBaseDocumentVersion] — the document
  /// `updated_at` the caller saw, passed through verbatim — makes a stale
  /// apply fail with 409 `conflict` before any write. An already-applied
  /// operation replays its original revision idempotently.
  Future<ApplyResult> apply(
    String operationId, {
    String? expectedBaseDocumentVersion,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '$_basePath/$operationId/apply',
        data: expectedBaseDocumentVersion == null
            ? null
            : ApplyRequest(
                expectedBaseDocumentVersion: expectedBaseDocumentVersion,
              ).toJson(),
      );
      return ApplyResult.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }
}
