import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../shared/models/document.dart';

/// All documents endpoints — the only place this feature calls dio
/// (directory-structure spec). Errors are normalized to [ApiException] via
/// [toApiException]; features never parse the error envelope themselves.
class DocumentsRepository {
  DocumentsRepository(this._client);

  final ApiClient _client;

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
}
