import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/search.dart';
import 'search_repository.dart';

/// Search repository wired to the app-wide API client; override this in
/// tests (provider-guidelines spec).
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(apiClientProvider)),
);

/// Current query + tag filter of the search page.
///
/// [SearchQueryState.query] is the last submitted query; [SearchQueryState.tag]
/// the active server-side tag filter (null = all documents). Mutated by
/// [SearchResultsNotifier] — the page only watches this state.
@immutable
class SearchQueryState {
  const SearchQueryState({this.query = '', this.tag});

  final String query;
  final String? tag;
}

class SearchQueryNotifier extends Notifier<SearchQueryState> {
  @override
  SearchQueryState build() => const SearchQueryState();

  void updateQuery(String query) =>
      state = SearchQueryState(query: query, tag: state.tag);

  /// Tapping the already-selected chip is a no-op (documents page semantics).
  void selectTag(String? tag) {
    if (tag == state.tag) return;
    state = SearchQueryState(query: state.query, tag: tag);
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, SearchQueryState>(
  SearchQueryNotifier.new,
);

/// Search results UI state.
///
/// A `null` value means **no search has been submitted yet** — distinct from
/// an empty result page (a non-null response with zero items). An
/// `AsyncNotifier` cannot express "never searched" and would fire a request
/// on first watch, so this is a plain [Notifier] holding an [AsyncValue]
/// (state-management spec).
class SearchResultsNotifier extends Notifier<AsyncValue<SearchResponse?>> {
  /// Bumped per search run; a response of an older run is stale and must not
  /// overwrite the newest results (same strategy as
  /// `DocumentsNotifier._buildGeneration`).
  int _generation = 0;

  SearchRepository get _repository => ref.read(searchRepositoryProvider);

  @override
  AsyncValue<SearchResponse?> build() => const AsyncData(null);

  /// Runs a search for [q] (trimmed; empty input is ignored) and records it
  /// as the current query so tag changes can re-run it.
  Future<void> search(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    ref.read(searchQueryProvider.notifier).updateQuery(query);
    await _run(query, ref.read(searchQueryProvider).tag);
  }

  /// Applies the tag filter and re-runs the current query. No-ops when the
  /// tag is already active (tapping the selected chip again) or when no
  /// search has been submitted yet — the same semantics as the documents
  /// page's tag bar. Filtering is server-side via the `tag` query param —
  /// never filter a fetched page locally.
  Future<void> setTag(String? tag) async {
    if (tag == ref.read(searchQueryProvider).tag) return;
    ref.read(searchQueryProvider.notifier).selectTag(tag);
    final query = ref.read(searchQueryProvider).query;
    if (query.isNotEmpty) await _run(query, tag);
  }

  /// Re-runs the last query (error-pane retry button).
  Future<void> retry() async {
    final query = ref.read(searchQueryProvider).query;
    if (query.isEmpty) return;
    await _run(query, ref.read(searchQueryProvider).tag);
  }

  Future<void> _run(String q, String? tag) async {
    final generation = ++_generation;
    state = const AsyncLoading();
    try {
      final response = await _repository.search(q: q, tag: tag);
      if (_generation != generation) return; // superseded — drop it
      state = AsyncData(response);
    } catch (error) {
      if (_generation != generation) return;
      state = AsyncError(toApiException(error), StackTrace.current);
    }
  }
}

final searchResultsProvider =
    NotifierProvider<SearchResultsNotifier, AsyncValue<SearchResponse?>>(
      SearchResultsNotifier.new,
    );
