import 'package:freezed_annotation/freezed_annotation.dart';

part 'agents_result.freezed.dart';
part 'agents_result.g.dart';

/// Results of the synchronous LLM sub-endpoints under
/// `/api/v1/documents/{id}` (`summary` and `associations`), mirroring the
/// backend's `src/app/schemas/agents.py` 1:1: every field is required and
/// non-nullable on the wire.

/// Response of `POST /api/v1/documents/{id}/summary` — an LLM summary of the
/// document. The result is computed on demand and **not persisted**
/// server-side; [latencyMs] is the provider round-trip in milliseconds.
@freezed
abstract class SummaryResult with _$SummaryResult {
  const factory SummaryResult({
    required String documentId,
    required String summary,
    required String model,
    required double latencyMs,
  }) = _SummaryResult;

  factory SummaryResult.fromJson(Map<String, dynamic> json) =>
      _$SummaryResultFromJson(json);
}

/// One LLM-curated related document. [signal] is the backend's free-form
/// retrieval hint (e.g. `tag_overlap`) and [reason] is the LLM-written
/// explanation — both are plain strings on the wire, never enums.
@freezed
abstract class AssociationItem with _$AssociationItem {
  const factory AssociationItem({
    required String documentId,
    required String title,
    required List<String> tags,
    required String reason,
    required String signal,
  }) = _AssociationItem;

  factory AssociationItem.fromJson(Map<String, dynamic> json) =>
      _$AssociationItemFromJson(json);
}

/// Response of `POST /api/v1/documents/{id}/associations`. [associations]
/// may be an empty list (the backend does not guarantee a minimum).
@freezed
abstract class AssociationsResult with _$AssociationsResult {
  const factory AssociationsResult({
    required String documentId,
    required List<AssociationItem> associations,
    required String model,
    required double latencyMs,
  }) = _AssociationsResult;

  factory AssociationsResult.fromJson(Map<String, dynamic> json) =>
      _$AssociationsResultFromJson(json);
}
