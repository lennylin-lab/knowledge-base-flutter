import 'package:flutter/foundation.dart';

import '../../core/network/agent_stream_client.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../shared/models/agents_stream.dart';
import '../../shared/models/operation.dart';

/// The lightweight result of a streamed draft run — everything the writing
/// layer consumes (review: the draft; apply: the operation id; gating: the
/// state), and deliberately NOT an [OperationReadDetail]: the `draft` event
/// carries no created_at/updated_at/base_document_version, so synthesizing
/// one would mean placeholder timestamps. History items keep the full
/// detail ([OperationsRepository.operationsForDocument]) and map into the
/// providers' `CurrentDraft` exactly like this result does.
@immutable
class OperationDraftResult {
  const OperationDraftResult({
    required this.operationId,
    required this.state,
    required this.draft,
  });

  final String operationId;

  /// Defensive parse of the event's raw wire `state` (the literal
  /// `"completed"` today): a received draft event always means "a draft
  /// arrived" and is presented as reviewable — known values map 1:1, and an
  /// unknown future value falls back to [OperationState.completed] (no
  /// invented sentinels; the draft content is real and applies).
  static OperationState stateFromWire(String wire) =>
      OperationState.values.asNameMap()[wire] ?? OperationState.completed;

  factory OperationDraftResult.fromEvent(AgentDraftEvent event) =>
      OperationDraftResult(
        operationId: event.operationId,
        state: stateFromWire(event.state),
        draft: DraftContent(content: event.content, title: event.title),
      );

  final OperationState state;
  final DraftContent draft;
}

/// All `/api/v1/operations` endpoints — the only place the operations
/// feature calls the network (directory-structure spec). Five routes are
/// synchronous JSON; `draft` streams `text/event-stream`
/// (`run_started → draft → done`, terminal `error` mutually exclusive) and
/// is consumed through the shared [AgentStreamClient.fold]. Errors are
/// normalized to [ApiException] — features never parse the error envelope
/// themselves, so 409 `conflict` (with `details.state` /
/// `details.base_version` / `details.current_version`), 404, 503 and 502
/// surface with codes and details intact.
class OperationsRepository {
  OperationsRepository(this._client, {AgentStreamClient? agentStream})
    : _agentStream = agentStream ?? AgentStreamClient(baseUrl: _client.baseUrl);

  final ApiClient _client;
  final AgentStreamClient _agentStream;

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

  /// Runs the writing agent on the document and folds its SSE stream
  /// (`run_started → draft → done`, terminal `error` mutually exclusive)
  /// into the lightweight [OperationDraftResult] via the shared
  /// [AgentStreamClient.fold]. Parameters travel as **query** params per the
  /// server contract — [instruction] is omitted when null or empty — and the
  /// request carries **no body**.
  ///
  /// Failure surface: 503 `chat_unavailable` (provider not configured) and
  /// 404 `not_found` (missing/soft-deleted document) fire before the first
  /// event as pre-stream envelopes; a mid-stream terminal `error` (e.g.
  /// `llm_provider_error` / `rate_limited`) keeps its wire code — the
  /// operation is already persisted `failed` and recoverable via
  /// `/operations/{id}/resume`. The error event carries **no operation id**,
  /// so the failed operation is located through the document's operation
  /// history (newest first).
  Future<OperationDraftResult> draft({
    required String documentId,
    String? instruction,
  }) {
    return _agentStream.fold(
      Uri.parse('${_client.baseUrl}$_basePath/draft').replace(
        queryParameters: <String, dynamic>{
          'document_id': documentId,
          if (instruction != null && instruction.isNotEmpty)
            'instruction': instruction,
        },
      ),
      extract: (event) => event is AgentDraftEvent
          ? OperationDraftResult.fromEvent(event)
          : null,
    );
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
