import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

/// Lifecycle of the backend indexing pipeline for a document's content.
///
/// Wire values are the lowercase member names (`pending` / `done` / `failed`).
/// Fields are decoded with `@JsonKey(unknownEnumValue: IndexStatus.failed)` so
/// an unknown wire value (the backend may grow new ones) parses as [failed]
/// instead of throwing — enum parsing must stay defensive (type-safety spec).
enum IndexStatus { pending, done, failed }

/// Create payload: `content` is the full Markdown (YAML front matter
/// included); the backend derives `title` and `tags` from the front matter,
/// so [title] is only an explicit optional override.
@freezed
abstract class DocumentCreate with _$DocumentCreate {
  const factory DocumentCreate({
    required String content,
    String? title,
  }) = _DocumentCreate;

  factory DocumentCreate.fromJson(Map<String, dynamic> json) =>
      _$DocumentCreateFromJson(json);
}

/// Partial-update payload; at least one field must be set (validated
/// server-side, surfaced as 422 `validation_failed`).
@freezed
abstract class DocumentUpdate with _$DocumentUpdate {
  const factory DocumentUpdate({
    String? content,
    String? title,
  }) = _DocumentUpdate;

  factory DocumentUpdate.fromJson(Map<String, dynamic> json) =>
      _$DocumentUpdateFromJson(json);
}

/// Document list item; `content` is intentionally excluded (payload bloat).
///
/// `id` is a UUID string and timestamps are ISO8601 strings — display-only
/// formatting happens in the UI layer, never on the DTO.
@freezed
abstract class DocumentRead with _$DocumentRead {
  const factory DocumentRead({
    required String id,
    required String title,
    required List<String> tags,
    @JsonKey(unknownEnumValue: IndexStatus.failed)
    required IndexStatus indexStatus,
    required String createdAt,
    required String updatedAt,
  }) = _DocumentRead;

  factory DocumentRead.fromJson(Map<String, dynamic> json) =>
      _$DocumentReadFromJson(json);
}

/// Single-document view: everything in [DocumentRead] plus the full Markdown
/// `content`.
///
/// freezed has no field inheritance, so the fields are repeated and a
/// projection helper converts back to the list-item shape.
@freezed
abstract class DocumentReadDetail with _$DocumentReadDetail {
  const factory DocumentReadDetail({
    required String id,
    required String title,
    required List<String> tags,
    @JsonKey(unknownEnumValue: IndexStatus.failed)
    required IndexStatus indexStatus,
    required String createdAt,
    required String updatedAt,
    required String content,
  }) = _DocumentReadDetail;

  factory DocumentReadDetail.fromJson(Map<String, dynamic> json) =>
      _$DocumentReadDetailFromJson(json);
}

/// Projection helper lives in an extension: freezed does not relay
/// user-declared methods to its `implements`-style impl class, and extensions
/// apply to every generated instance all the same.
extension DocumentReadDetailProjection on DocumentReadDetail {
  /// Drop `content` and project to the list-item DTO.
  DocumentRead toDocumentRead() => DocumentRead(
        id: id,
        title: title,
        tags: tags,
        indexStatus: indexStatus,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// One page of a keyset-paginated document list.
///
/// [nextCursor] is opaque — pass it back as the `cursor` query param, never
/// parse or construct it. `null` means end of list (not an error).
@freezed
abstract class DocumentPage with _$DocumentPage {
  const factory DocumentPage({
    required List<DocumentRead> items,
    String? nextCursor,
  }) = _DocumentPage;

  factory DocumentPage.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageFromJson(json);
}

