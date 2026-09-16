import 'package:freezed_annotation/freezed_annotation.dart';

import 'document.dart';

part 'operation.freezed.dart';
part 'operation.g.dart';

/// Lifecycle of a backend AI writing operation (`/api/v1/operations`).
///
/// Wire values are the lowercase member names (`running` / `completed` /
/// `interrupted` / `failed` / `applied`). Fields are decoded with
/// `@JsonKey(unknownEnumValue: OperationState.failed)` so an unknown wire
/// value (the backend may grow new ones) parses as [failed] instead of
/// throwing — [failed] is the recoverable presentation closest to "not done"
/// (type-safety spec: enum parsing must stay defensive).
enum OperationState { running, completed, interrupted, failed, applied }

/// Draft text produced by (or fed back into) an operation: the full Markdown
/// including YAML front matter. The server bounds `content` to 1..50_000
/// chars — assert at the call site (no validation library, type-safety
/// spec); [title] mirrors the optional explicit override.
@freezed
abstract class DraftContent with _$DraftContent {
  const factory DraftContent({required String content, String? title}) =
      _DraftContent;

  factory DraftContent.fromJson(Map<String, dynamic> json) =>
      _$DraftContentFromJson(json);
}

/// Create payload for `POST /api/v1/operations`.
///
/// [baseDocumentVersion] is the document's `updated_at` the caller saw,
/// passed through **verbatim** (String — the server compares it for
/// optimistic concurrency with exact equality; never reformat or re-parse).
/// [idempotencyKey] makes a retried create return the original operation
/// server-side.
@freezed
abstract class OperationCreate with _$OperationCreate {
  const factory OperationCreate({
    required String documentId,
    required String baseDocumentVersion,
    required DraftContent draft,
    String? idempotencyKey,
  }) = _OperationCreate;

  factory OperationCreate.fromJson(Map<String, dynamic> json) =>
      _$OperationCreateFromJson(json);
}

/// Full operation view — what every operations route returns, list items
/// included. Timestamps ([createdAt] / [updatedAt] / [baseDocumentVersion])
/// stay verbatim ISO8601 strings. [result] / [error] are the backend's
/// free-form objects (`{"revision_id": …}` / `{"error_class": …}`) kept raw
/// per the type-safety spec.
@freezed
abstract class OperationReadDetail with _$OperationReadDetail {
  const factory OperationReadDetail({
    required String id,
    String? documentId,
    String? baseDocumentVersion,
    @JsonKey(unknownEnumValue: OperationState.failed)
    required OperationState state,
    String? idempotencyKey,
    required String createdAt,
    required String updatedAt,
    DraftContent? draft,
    Map<String, dynamic>? result,
    Map<String, dynamic>? error,
  }) = _OperationReadDetail;

  factory OperationReadDetail.fromJson(Map<String, dynamic> json) =>
      _$OperationReadDetailFromJson(json);
}

/// Projection helper lives in an extension (same reason as
/// `DocumentReadDetailProjection`).
extension OperationReadDetailResult on OperationReadDetail {
  /// The revision id the backend stores in `result` once the operation was
  /// applied; null before that.
  String? get revisionId => result?['revision_id'] as String?;
}

/// Resume body (`POST /operations/{id}/resume`): an optional draft amendment
/// replacing the stored draft. [draft] is omitted from the JSON when unset —
/// "nothing to say" means the repository sends no request body at all.
@freezed
abstract class OperationTransition with _$OperationTransition {
  const factory OperationTransition({
    @JsonKey(includeIfNull: false) DraftContent? draft,
  }) = _OperationTransition;

  factory OperationTransition.fromJson(Map<String, dynamic> json) =>
      _$OperationTransitionFromJson(json);
}

/// Apply body (`POST /operations/{id}/apply`): an optional
/// optimistic-concurrency double-check against the operation's recorded base
/// version — a verbatim timestamp string; a mismatch fails with 409
/// `conflict` before any write. Omitted from the JSON when unset.
@freezed
abstract class ApplyRequest with _$ApplyRequest {
  const factory ApplyRequest({
    @JsonKey(includeIfNull: false) String? expectedBaseDocumentVersion,
  }) = _ApplyRequest;

  factory ApplyRequest.fromJson(Map<String, dynamic> json) =>
      _$ApplyRequestFromJson(json);
}

/// The revision a successful apply created (the backend intentionally
/// exposes no `content` field on revisions).
@freezed
abstract class RevisionRead with _$RevisionRead {
  const factory RevisionRead({
    required String id,
    required String documentId,
    String? operationId,
    required String title,
    required List<String> tags,
    required String createdAt,
  }) = _RevisionRead;

  factory RevisionRead.fromJson(Map<String, dynamic> json) =>
      _$RevisionReadFromJson(json);
}

/// The document as it looks right after an apply (`index_status` reset to
/// `pending`, title/tags re-derived from the draft's front matter).
/// Reuses the shared [IndexStatus] enum — unknown wire value → [IndexStatus.failed].
@freezed
abstract class DocumentInResult with _$DocumentInResult {
  const factory DocumentInResult({
    required String id,
    required String title,
    required List<String> tags,
    @JsonKey(unknownEnumValue: IndexStatus.failed)
    required IndexStatus indexStatus,
    required String updatedAt,
  }) = _DocumentInResult;

  factory DocumentInResult.fromJson(Map<String, dynamic> json) =>
      _$DocumentInResultFromJson(json);
}

/// Response of `POST /operations/{id}/apply`: the applied operation, the
/// revision it created, and the mutated document.
@freezed
abstract class ApplyResult with _$ApplyResult {
  const factory ApplyResult({
    required OperationReadDetail operation,
    required RevisionRead revision,
    required DocumentInResult document,
  }) = _ApplyResult;

  factory ApplyResult.fromJson(Map<String, dynamic> json) =>
      _$ApplyResultFromJson(json);
}
