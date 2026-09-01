import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/search/search_providers.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

import 'stub_search_repository.dart';

/// Notifier-level search tests: success/error transitions, the tag re-run
/// and the stale-response race a widget test cannot make deterministic.
ProviderContainer _makeContainer(StubSearchRepository repo) {
  final container = ProviderContainer(
    overrides: [searchRepositoryProvider.overrideWithValue(repo)],
    retry: noAutomaticRetry,
  );
  addTearDown(container.dispose);
  // Keep the providers alive across awaits.
  container.listen(searchResultsProvider, (_, _) {});
  container.listen(searchQueryProvider, (_, _) {});
  return container;
}

void main() {
  test('starts "never searched" (null value), not an empty result page', () {
    final container = _makeContainer(StubSearchRepository());

    expect(container.read(searchResultsProvider).value, isNull);
    expect(container.read(searchQueryProvider).query, isEmpty);
  });

  test('search records the query, fetches and lands the results', () async {
    final repo =
        StubSearchRepository()
          ..searchHandler =
              (q, limit, tag) async =>
                  searchResponse(items: [searchHit(documentId: 'a', title: '甲')]);
    final container = _makeContainer(repo);

    await container.read(searchResultsProvider.notifier).search('flutter');

    final call = repo.searchCalls.single;
    expect(call.q, 'flutter');
    expect(call.limit, 10, reason: 'default limit, no clamp applied');
    expect(call.tag, isNull);

    expect(
      container.read(searchResultsProvider).value?.items.single.documentTitle,
      '甲',
    );
    expect(container.read(searchQueryProvider).query, 'flutter');
  });

  test('empty or whitespace input is ignored (no request)', () async {
    final repo = StubSearchRepository();
    final container = _makeContainer(repo);

    await container.read(searchResultsProvider.notifier).search('   ');

    expect(repo.searchCalls, isEmpty);
    expect(container.read(searchResultsProvider).value, isNull);
  });

  test('failure lands in AsyncError with the ApiException; retry re-runs', () async {
    var calls = 0;
    final repo =
        StubSearchRepository()
          ..searchHandler = (q, limit, tag) async {
            calls++;
            if (calls == 1) {
              throw const ApiException(
                code: 'network_error',
                message: '网络连接异常，请检查网络后重试',
              );
            }
            return searchResponse(items: [searchHit(documentId: 'a', title: '重试成功')]);
          };
    final container = _makeContainer(repo);

    await container.read(searchResultsProvider.notifier).search('flutter');

    final failed = container.read(searchResultsProvider);
    expect(failed.hasError, isTrue);
    expect((failed.error as ApiException).code, 'network_error');
    expect(container.read(searchQueryProvider).query, 'flutter');

    await container.read(searchResultsProvider.notifier).retry();

    expect(
      container.read(searchResultsProvider).value?.items.single.documentTitle,
      '重试成功',
    );
    expect(repo.searchCalls, hasLength(2));
  });

  test('setTag re-runs the current query with the tag; alone it is a no-op', () async {
    final repo =
        StubSearchRepository()
          ..searchHandler = (q, limit, tag) async => searchResponse();
    final container = _makeContainer(repo);

    // No query yet: selecting a tag stores it but must not fire a request.
    await container.read(searchResultsProvider.notifier).setTag('flutter');
    expect(repo.searchCalls, isEmpty);
    expect(container.read(searchQueryProvider).tag, 'flutter');

    await container.read(searchResultsProvider.notifier).search('dio');
    await container.read(searchResultsProvider.notifier).setTag('dart');

    final last = repo.searchCalls.last;
    expect(last.q, 'dio');
    expect(last.tag, 'dart');
  });

  test('re-selecting the already-active tag does not re-run the search', () async {
    final repo =
        StubSearchRepository()
          ..searchHandler = (q, limit, tag) async => searchResponse();
    final container = _makeContainer(repo);

    await container.read(searchResultsProvider.notifier).search('dio');
    await container.read(searchResultsProvider.notifier).setTag('flutter');
    final callsAfterFilter = repo.searchCalls.length;

    await container.read(searchResultsProvider.notifier).setTag('flutter');

    expect(
      repo.searchCalls.length,
      callsAfterFilter,
      reason: 'no-op: same tag must not fire a redundant request',
    );
  });

  test('a stale in-flight response never overwrites newer results', () async {
    final repo = StubSearchRepository();
    final stale = Completer<SearchResponse>();
    var calls = 0;
    repo.searchHandler = (q, limit, tag) {
      calls++;
      if (calls == 1) return stale.future;
      return Future.value(
        searchResponse(items: [searchHit(documentId: 'b', title: '乙')]),
      );
    };
    final container = _makeContainer(repo);

    final first = container.read(searchResultsProvider.notifier).search('first');
    await container.pump(); // the first request is now pending on `stale`
    final second = container.read(searchResultsProvider.notifier).search('second');
    await second;

    expect(
      container.read(searchResultsProvider).value?.items.single.documentTitle,
      '乙',
    );

    // The superseded request resolves late — it must not clobber [乙].
    stale.complete(
      searchResponse(items: [searchHit(documentId: 'a', title: '甲')]),
    );
    await first;

    expect(
      container.read(searchResultsProvider).value?.items.single.documentTitle,
      '乙',
    );
    expect(container.read(searchQueryProvider).query, 'second');
  });
}
