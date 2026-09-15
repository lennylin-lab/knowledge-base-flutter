import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/agents_result.dart';
import 'package:knowledge_base_flutter/shared/models/agents_stream.dart';
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

  group('on-demand AI generation (documentSummaryProvider)', () {
    ProviderContainer containerFor(StubDocumentsRepository repo) {
      final container = ProviderContainer(
        overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
        retry: noAutomaticRetry,
      );
      addTearDown(container.dispose);
      // Keep the family element alive across reads.
      container.listen(documentSummaryProvider('doc-1'), (_, _) {});
      return container;
    }

    test('no fetch on build; generate calls once; in-flight taps no-op', () async {
      final repo = StubDocumentsRepository();
      final pending = Completer<SummaryResult>();
      repo.summarizeHandler = (id) => pending.future;
      final container = containerFor(repo);

      // Building the provider state never touches the repository.
      final state = container.read(documentSummaryProvider('doc-1'));
      expect(state.result, isNull);
      expect(state.isGenerating, isFalse);
      expect(repo.summarizeCalls, isEmpty);

      final notifier = container.read(documentSummaryProvider('doc-1').notifier);
      final first = notifier.generate();
      await container.pump();
      expect(repo.summarizeCalls, ['doc-1']);
      expect(container.read(documentSummaryProvider('doc-1')).isGenerating, isTrue);

      // A second tap while in flight is a no-op.
      await notifier.generate();
      expect(repo.summarizeCalls, hasLength(1));

      pending.complete(
        const SummaryResult(
          documentId: 'doc-1',
          summary: '摘要',
          model: 'glm-4.7',
          latencyMs: 1500,
        ),
      );
      await first;
      final done = container.read(documentSummaryProvider('doc-1'));
      expect(done.result?.summary, '摘要');
      expect(done.isGenerating, isFalse);
      expect(done.error, isNull);
    });

    test('failure keeps the previous result and exposes the raw error', () async {
      final repo = StubDocumentsRepository();
      var fail = false;
      repo.summarizeHandler = (id) async {
        if (fail) {
          throw const ApiException(
            code: 'chat_unavailable',
            message: 'No API key configured',
            statusCode: 503,
          );
        }
        return const SummaryResult(
          documentId: 'doc-1',
          summary: '旧摘要',
          model: 'glm-4.7',
          latencyMs: 1500,
        );
      };
      final container = containerFor(repo);
      final notifier = container.read(documentSummaryProvider('doc-1').notifier);

      await notifier.generate();
      expect(container.read(documentSummaryProvider('doc-1')).result?.summary, '旧摘要');

      fail = true;
      await notifier.generate();
      final failed = container.read(documentSummaryProvider('doc-1'));
      expect(failed.result?.summary, '旧摘要', reason: 'failure keeps the result');
      expect(failed.isGenerating, isFalse);
      final error = failed.error;
      expect(error, isA<ApiException>());
      expect((error as ApiException).code, 'chat_unavailable');
    });

    test('a superseded generation must not overwrite newer state', () async {
      final repo = StubDocumentsRepository();
      final pending = Completer<SummaryResult>();
      repo.summarizeHandler = (id) => pending.future;
      final container = containerFor(repo);
      final notifier = container.read(documentSummaryProvider('doc-1').notifier);

      final stale = notifier.generate();
      await container.pump();

      // The provider rebuilds while the fetch is in flight (generation bump).
      container.invalidate(documentSummaryProvider('doc-1'));
      await container.pump();
      expect(container.read(documentSummaryProvider('doc-1')).isGenerating, isFalse);

      // The stale result lands late — it must be dropped.
      pending.complete(
        const SummaryResult(
          documentId: 'doc-1',
          summary: '过期摘要',
          model: 'glm-4.7',
          latencyMs: 1500,
        ),
      );
      await stale;

      final state = container.read(documentSummaryProvider('doc-1'));
      expect(state.result, isNull);
      expect(state.error, isNull);
    });
  });

  group('on-demand streamed progress (documentSummaryProvider)', () {
    ProviderContainer containerFor(StubDocumentsRepository repo) {
      final container = ProviderContainer(
        overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
        retry: noAutomaticRetry,
      );
      addTearDown(container.dispose);
      container.listen(documentSummaryProvider('doc-1'), (_, _) {});
      return container;
    }

    SummaryResult resultOf(String text) => SummaryResult(
      documentId: 'doc-1',
      summary: text,
      model: 'glm-4.7',
      latencyMs: 1500,
    );

    test('progress updates during generation and clears on success', () async {
      final repo = StubDocumentsRepository();
      final pending = Completer<SummaryResult>();
      repo.summarizeHandler = (id) => pending.future;
      repo.summarizeProgressHandler = (id, report) {
        report(
          const SummaryProgress(
            phase: 'map_pass',
            passIndex: 1,
            passesTotal: 3,
          ),
        );
        report(
          const SummaryProgress(
            phase: 'reduce_pass',
            passIndex: 3,
            passesTotal: 3,
          ),
        );
      };
      final container = containerFor(repo);
      final notifier = container.read(
        documentSummaryProvider('doc-1').notifier,
      );

      final run = notifier.generate();
      await container.pump();

      // Latest progress wins; the generation is still in flight.
      final generating = container.read(documentSummaryProvider('doc-1'));
      expect(generating.isGenerating, isTrue);
      expect(generating.progress?.phase, 'reduce_pass');
      expect(generating.progress?.passIndex, 3);
      expect(generating.progress?.passesTotal, 3);

      pending.complete(resultOf('摘要'));
      await run;

      final done = container.read(documentSummaryProvider('doc-1'));
      expect(done.result?.summary, '摘要');
      expect(done.isGenerating, isFalse);
      expect(done.error, isNull);
      expect(done.progress, isNull, reason: 'terminal state clears progress');
    });

    test('progress clears on failure too (result kept, error set)', () async {
      final repo = StubDocumentsRepository();
      repo.summarizeHandler = (id) async {
        throw const ApiException(
          code: 'chat_unavailable',
          message: 'No API key configured',
          statusCode: 503,
        );
      };
      repo.summarizeProgressHandler = (id, report) => report(
        const SummaryProgress(phase: 'map_pass', passIndex: 1, passesTotal: 2),
      );
      final container = containerFor(repo);
      final notifier = container.read(
        documentSummaryProvider('doc-1').notifier,
      );

      await notifier.generate();

      final failed = container.read(documentSummaryProvider('doc-1'));
      expect(failed.error, isA<ApiException>());
      expect(failed.isGenerating, isFalse);
      expect(failed.progress, isNull);
    });

    test('a new generation starts with progress cleared', () async {
      final repo = StubDocumentsRepository();
      var firstRun = true;
      final pending = Completer<SummaryResult>();
      repo.summarizeHandler = (id) =>
          firstRun ? Future.value(resultOf('第一版')) : pending.future;
      repo.summarizeProgressHandler = (id, report) {
        if (!firstRun) {
          return; // the second generation reports nothing (yet)
        }
        report(
          const SummaryProgress(
            phase: 'map_pass',
            passIndex: 1,
            passesTotal: 2,
          ),
        );
      };
      final container = containerFor(repo);
      final notifier = container.read(
        documentSummaryProvider('doc-1').notifier,
      );

      await notifier.generate();
      expect(
        container.read(documentSummaryProvider('doc-1')).progress,
        isNull,
      );

      firstRun = false;
      final second = notifier.generate();
      await container.pump();

      final regenerating = container.read(documentSummaryProvider('doc-1'));
      expect(regenerating.isGenerating, isTrue);
      expect(
        regenerating.progress,
        isNull,
        reason: "a new generation must not show the previous run's progress",
      );

      pending.complete(resultOf('第二版'));
      await second;
      expect(
        container.read(documentSummaryProvider('doc-1')).result?.summary,
        '第二版',
      );
    });

    test('a superseded generation drops its late progress', () async {
      final repo = StubDocumentsRepository();
      final pending = Completer<SummaryResult>();
      final reports = <void Function(SummaryProgress)>[];
      repo.summarizeHandler = (id) => pending.future;
      repo.summarizeProgressHandler = (id, report) => reports.add(report);
      final container = containerFor(repo);
      final notifier = container.read(
        documentSummaryProvider('doc-1').notifier,
      );

      final stale = notifier.generate();
      await container.pump();

      // The provider rebuilds mid-flight (generation bump).
      container.invalidate(documentSummaryProvider('doc-1'));
      await container.pump();

      // The stale stream reports progress late — it must be dropped.
      for (final report in reports) {
        report(
          const SummaryProgress(
            phase: 'reduce_pass',
            passIndex: 2,
            passesTotal: 2,
          ),
        );
      }
      pending.complete(resultOf('过期摘要'));
      await stale;

      final state = container.read(documentSummaryProvider('doc-1'));
      expect(state.result, isNull);
      expect(state.progress, isNull);
      expect(state.error, isNull);
    });
  });
}
