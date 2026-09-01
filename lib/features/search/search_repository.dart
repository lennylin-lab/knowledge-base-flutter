import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../shared/models/search.dart';

/// The search endpoint — the only place this feature calls dio
/// (directory-structure spec). Errors are normalized to [ApiException] via
/// [toApiException]; features never parse the error envelope themselves.
class SearchRepository {
  SearchRepository(this._client);

  final ApiClient _client;

  static const String _basePath = '/api/v1/search';

  /// `limit` bounds of the search endpoint (API contract).
  static const int minLimit = 1;
  static const int maxLimit = 50;
  static const int defaultLimit = 10;

  /// Clamps [limit] into the API's 1–50 range before sending
  /// (type-safety spec: validate at the boundary).
  static int clampLimit(int limit) => limit.clamp(minLimit, maxLimit).toInt();

  /// Hybrid (BM25 + vector) search over document chunks.
  ///
  /// [q] is required (min 1 char, validated server-side as 422
  /// `validation_failed`). [tag] filters hits server-side — the client never
  /// filters a fetched page locally (database-guidelines spec).
  Future<SearchResponse> search({
    required String q,
    int limit = defaultLimit,
    String? tag,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        _basePath,
        queryParameters: <String, dynamic>{
          'q': q,
          'limit': clampLimit(limit),
          if (tag != null && tag.isNotEmpty) 'tag': tag,
        },
      );
      return SearchResponse.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }
}
