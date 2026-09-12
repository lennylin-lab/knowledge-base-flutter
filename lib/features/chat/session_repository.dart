import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../shared/models/session.dart';

/// The chat-sessions REST endpoints — the only place this feature calls dio
/// for sessions (directory-structure spec). Errors are normalized to
/// [ApiException] via [toApiException]; features never parse the error
/// envelope themselves.
class SessionRepository {
  SessionRepository(this._client);

  final ApiClient _client;

  static const String _basePath = '/api/v1/chat/sessions';

  /// `limit` bounds of the sessions list endpoint (API contract).
  static const int minLimit = 1;
  static const int maxLimit = 100;
  static const int defaultLimit = 20;

  /// Clamps [limit] into the API's 1–100 range before sending
  /// (type-safety spec: validate at the boundary).
  static int clampLimit(int limit) => limit.clamp(minLimit, maxLimit).toInt();

  /// Lists chat sessions, most recently updated first, keyset-paginated.
  /// [cursor] comes from the previous page's `next_cursor` — the client
  /// never paginates locally (database-guidelines spec).
  Future<SessionPage> listSessions({String? cursor, int limit = defaultLimit}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        _basePath,
        queryParameters: <String, dynamic>{
          'limit': clampLimit(limit),
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );
      return SessionPage.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Returns one session with its messages in chronological order.
  /// Unknown [sessionId] surfaces as a 404 [ApiException].
  Future<SessionDetail> getSession(String sessionId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '$_basePath/$sessionId',
      );
      return SessionDetail.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Soft-deletes a session; it disappears from every read path (204).
  Future<void> deleteSession(String sessionId) async {
    try {
      await _client.dio.delete<void>('$_basePath/$sessionId');
    } catch (error) {
      throw toApiException(error);
    }
  }
}
