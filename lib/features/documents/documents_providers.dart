import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/document.dart';
import 'documents_repository.dart';

/// Documents repository wired to the app-wide API client; override this in
/// tests (provider-guidelines spec).
final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => DocumentsRepository(ref.watch(apiClientProvider)),
);

/// Selected tag filters; empty set means "all documents". The actual
/// filtering is server-side via repeated `tag` query params, combined as an
/// AND (documents must carry every selected tag) — never filter a fetched
/// page locally (database-guidelines spec).
class SelectedTagsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String tag) {
    final next = {...state};
    if (!next.add(tag)) next.remove(tag);
    state = next;
  }

  void clear() => state = const {};
}

final selectedTagsProvider =
    NotifierProvider<SelectedTagsNotifier, Set<String>>(
      SelectedTagsNotifier.new,
    );

/// Documents list UI state: keyset pages accumulated under the current tag
/// filter.
@immutable
class DocumentsListState {
  const DocumentsListState({
    this.items = const <DocumentRead>[],
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<DocumentRead> items;

  /// Opaque cursor for the next page; null = end of list (not an error).
  final String? nextCursor;

  final bool isLoadingMore;

  /// Message for the footer retry row when `loadNext` failed; already
  /// loaded items are kept.
  final String? loadMoreError;

  bool get hasMore => nextCursor != null;
}

/// Keyset-paginated documents list (provider-guidelines spec). Rebuilds
/// from page 1 whenever the tag filter changes.
class DocumentsNotifier extends AsyncNotifier<DocumentsListState> {
  int _buildGeneration = 0;
  bool _loadNextInFlight = false;

  DocumentsRepository get _repository => ref.read(documentsRepositoryProvider);

  @override
  Future<DocumentsListState> build() async {
    // Every rebuild (tag change, invalidateSelf from refresh / create /
    // update / delete) starts a new generation; a loadNext fetch of an older
    // generation is stale by the time it resolves and must not append.
    _buildGeneration++;
    _loadNextInFlight = false;
    final tags = ref.watch(selectedTagsProvider);
    final page = await _repository.list(tags: tags.toList());
    return DocumentsListState(items: page.items, nextCursor: page.nextCursor);
  }

  /// Appends the next keyset page (`cursor` = last `nextCursor`; page 1 is
  /// never re-fetched to append). No-op when already loading or at the end
  /// of the list. On failure the loaded items are kept and the message is
  /// surfaced through [DocumentsListState.loadMoreError].
  Future<void> loadNext() async {
    if (_loadNextInFlight) return;
    // A first-page (re)build is in flight — its result supersedes any append,
    // and writing `AsyncData` here would cancel its loading state.
    if (state.isLoading) return;
    final current = state.value;
    if (current == null) return;
    final cursor = current.nextCursor;
    if (cursor == null) return; // end of list

    final generation = _buildGeneration;
    final tags = ref.read(selectedTagsProvider).toList();
    _loadNextInFlight = true;
    state = AsyncData(
      DocumentsListState(
        items: current.items,
        nextCursor: cursor,
        isLoadingMore: true,
      ),
    );
    try {
      final page = await _repository.list(cursor: cursor, tags: tags);
      // The provider rebuilt while the fetch was in flight (tag change or
      // refresh): build() has already reset to page 1 under the current
      // filter — the stale page must not be appended.
      if (_buildGeneration != generation) return;
      state = AsyncData(
        DocumentsListState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (error) {
      if (_buildGeneration != generation) return;
      state = AsyncData(
        DocumentsListState(
          items: current.items,
          nextCursor: cursor,
          loadMoreError: toApiException(error).message,
        ),
      );
    } finally {
      // Only clear the flag for its own generation: a newer build may have
      // started another fetch whose flag a stale `finally` must not clear.
      if (_buildGeneration == generation) _loadNextInFlight = false;
    }
  }

  /// Re-fetches page 1 under the current filter (invalidate + refetch —
  /// the simple MVP strategy per state-management spec).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The failure is already carried by the AsyncValue the UI renders.
    }
  }

  /// Creates a document and refreshes the list (MVP: refetch, no local
  /// patching). Returns the created list item.
  Future<DocumentRead> createDocument(DocumentCreate payload) async {
    final created = await _repository.create(payload);
    await refresh();
    return created;
  }

  /// Updates a document and refreshes list + detail caches.
  Future<DocumentRead> updateDocument(
    String id,
    DocumentUpdate payload,
  ) async {
    final updated = await _repository.update(id, payload);
    ref.invalidate(documentDetailProvider(id));
    await refresh();
    return updated;
  }

  /// Soft-deletes a document and refreshes list + detail caches.
  Future<void> deleteDocument(String id) async {
    await _repository.delete(id);
    ref.invalidate(documentDetailProvider(id));
    await refresh();
  }
}

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, DocumentsListState>(
      DocumentsNotifier.new,
    );

/// Document detail by id; invalidated after update/delete so the detail
/// page refetches (state-management spec).
final documentDetailProvider =
    FutureProvider.family<DocumentReadDetail, String>((ref, id) {
      return ref.watch(documentsRepositoryProvider).get(id);
    });
