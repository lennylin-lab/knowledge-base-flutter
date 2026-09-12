import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/session.dart';
import 'chat_providers.dart' show sessionRepositoryProvider;
import 'session_repository.dart';

/// Keyset-paginated session-list UI state (most recently updated first).
/// Built eagerly on first watch — the list page is the only watcher, so chat
/// streaming never rebuilds it.
class SessionsNotifier extends AsyncNotifier<SessionPage> {
  /// Guards `loadMore` against double-fire while a cursor page is in
  /// flight (AsyncLoading would blank the accumulated list).
  bool _loadingMore = false;

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  @override
  Future<SessionPage> build() =>
      _repository.listSessions(limit: SessionRepository.defaultLimit);

  /// Appends the page addressed by the current `next_cursor`. No-op when a
  /// load is in flight or the list is exhausted; a failed page keeps the
  /// accumulated items — tapping 「加载更多」 again retries.
  Future<void> loadMore() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (cursor == null || cursor.isEmpty || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await _repository.listSessions(cursor: cursor);
      final base = state.value;
      if (base != null) {
        state = AsyncData(
          SessionPage(
            items: [...base.items, ...page.items],
            nextCursor: page.nextCursor,
          ),
        );
      }
    } catch (error) {
      // Keep the accumulated list; the tile surfaces a retry affordance.
      state = AsyncError(toApiException(error), StackTrace.current);
    } finally {
      _loadingMore = false;
    }
  }

  /// Reloads page 1 (pull-to-refresh, post-delete refresh).
  Future<void> refresh() async {
    state = const AsyncLoading<SessionPage>();
    try {
      state = AsyncData(
        await _repository.listSessions(limit: SessionRepository.defaultLimit),
      );
    } catch (error) {
      state = AsyncError(toApiException(error), StackTrace.current);
    }
  }

  /// Soft-deletes [sessionId] server-side and refreshes page 1 — the server
  /// stays authoritative for what the list contains.
  Future<void> remove(String sessionId) async {
    await _repository.deleteSession(sessionId);
    await refresh();
  }
}

final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, SessionPage>(SessionsNotifier.new);
