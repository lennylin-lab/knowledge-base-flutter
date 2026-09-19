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

  /// Default page size for message-history loads (issue #6 follow-up:
  /// first screen shows the newest page, older history loads on scroll).
  static const int defaultHistoryLimit = 30;

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

  /// Returns one page of the session's message history: the newest
  /// [limit] messages (chronological within the page), [cursor] stepping
  /// strictly older via the previous page's `next_cursor`. The legacy
  /// full-detail response (no params) is intentionally not used — long
  /// sessions must never be fetched wholesale (issue #6 follow-up).
  Future<MessagePage> getSessionPage(
    String sessionId, {
    int limit = defaultHistoryLimit,
    String? cursor,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '$_basePath/$sessionId',
        queryParameters: <String, dynamic>{
          'limit': clampLimit(limit),
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );
      return MessagePage.fromJson(response.data!);
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
