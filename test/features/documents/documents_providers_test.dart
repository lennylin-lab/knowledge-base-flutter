import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

import 'stub_documents_repository.dart';

/// Notifier-level keyset pagination tests: the races a widget test cannot
/// make deterministic (refresh superseding an in-flight `loadNext`).
void main() {
  test('a refresh supersedes an in-flight loadNext; the stale page is dropped', () async {
    final repo = StubDocumentsRepository();
    final stalePage = Completer<DocumentPage>();
    var calls = 0;
    repo.listHandler = (cursor, limit, tags) async {
      calls++;
      switch (calls) {
        case 1: // initial page 1
          return DocumentPage(items: [documentRead(id: 'a')], nextCursor: 'c1');
        case 2: // loadNext (cursor c1) — stays pending
          return stalePage.future;
        default: // refresh page 1
          return DocumentPage(items: [documentRead(id: 'z')], nextCursor: null);
      }
    };

    final container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
      retry: noAutomaticRetry,
    );
    addTearDown(container.dispose);
    // Keep the provider alive so invalidateSelf rebuilds it.
    container.listen(documentsProvider, (_, _) {});

    await container.read(documentsProvider.future);
    expect(container.read(documentsProvider).value?.items.map((d) => d.id), [
      'a',
    ]);

    final loadNext = container.read(documentsProvider.notifier).loadNext();
    final refresh = container.read(documentsProvider.notifier).refresh();
    await refresh; // fresh page 1 ([z]) landed while the page-2 fetch pends

    expect(container.read(documentsProvider).value?.items.map((d) => d.id), [
      'z',
    ]);

    // The superseded fetch resolves late — its items must NOT be appended.
    stalePage.complete(
      DocumentPage(items: [documentRead(id: 'b')], nextCursor: null),
    );
    await loadNext;

    expect(container.read(documentsProvider).value?.items.map((d) => d.id), [
      'z',
    ]);
    expect(container.read(documentsProvider).value?.nextCursor, isNull);
  });

  test('loadNext is a no-op while the first page is (re)loading', () async {
    final repo = StubDocumentsRepository();
    final reload = Completer<DocumentPage>();
    var calls = 0;
    repo.listHandler = (cursor, limit, tags) async {
      calls++;
      if (calls == 1) {
        return DocumentPage(items: [documentRead(id: 'a')], nextCursor: 'c1');
      }
      return reload.future; // refresh page 1, held open
    };

    final container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
      retry: noAutomaticRetry,
    );
    addTearDown(container.dispose);
    container.listen(documentsProvider, (_, _) {});

    await container.read(documentsProvider.future);

    final refresh = container.read(documentsProvider.notifier).refresh();
    await container.pump();
    // Still loading the refreshed first page: appending now would clobber
    // the loading state and later race the fresh result.
    await container.read(documentsProvider.notifier).loadNext();

    expect(repo.listCalls, hasLength(2), reason: 'no page-2 fetch was started');
    expect(container.read(documentsProvider).isLoading, isTrue);

    reload.complete(
      DocumentPage(items: [documentRead(id: 'a2')], nextCursor: null),
    );
    await refresh;
    expect(container.read(documentsProvider).value?.items.map((d) => d.id), [
      'a2',
    ]);
  });

  test('selectedTags toggles membership and clear empties the selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectedTagsProvider.notifier);

    expect(container.read(selectedTagsProvider), isEmpty);

    notifier.toggle('flutter');
    notifier.toggle('dart');
    expect(container.read(selectedTagsProvider), {'flutter', 'dart'});

    notifier.toggle('flutter');
    expect(container.read(selectedTagsProvider), {'dart'});

    notifier.clear();
    expect(container.read(selectedTagsProvider), isEmpty);
  });

  test('toggling tags rebuilds page 1 carrying the selected tags', () async {
    final repo = StubDocumentsRepository();
    repo.listHandler = (cursor, limit, tags) async {
      assert(cursor == null, 'a selection change must reset to page 1');
      return DocumentPage(
        items: [documentRead(id: tags.isEmpty ? 'all' : tags.join('+'))],
        nextCursor: null,
      );
    };

    final container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
      retry: noAutomaticRetry,
    );
    addTearDown(container.dispose);
    container.listen(documentsProvider, (_, _) {});

    await container.read(documentsProvider.future);
    expect(container.read(documentsProvider).value?.items.single.id, 'all');

    final notifier = container.read(selectedTagsProvider.notifier);
    notifier.toggle('flutter');
    await container.read(documentsProvider.future);
    notifier.toggle('dart');
    await container.read(documentsProvider.future);

    expect(repo.listCalls, hasLength(3));
    expect(repo.listCalls.last.tags, ['flutter', 'dart']);
    expect(
      container.read(documentsProvider).value?.items.single.id,
      'flutter+dart',
    );

    notifier.clear();
    await container.read(documentsProvider.future);
    expect(repo.listCalls.last.tags, isEmpty);
  });
}
