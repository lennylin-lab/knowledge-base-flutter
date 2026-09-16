import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/features/operations/operations_providers.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:knowledge_base_flutter/shared/models/operation.dart';

import '../documents/stub_documents_repository.dart';
import 'stub_operations_repository.dart';

void main() {
  /// A container wired to both stubs — apply invalidates the documents
  /// feature's providers, so those need a stub repository too.
  (ProviderContainer, StubOperationsRepository, StubDocumentsRepository)
  containerFor({
    StubOperationsRepository? operations,
    StubDocumentsRepository? documents,
  }) {
    final ops = operations ?? StubOperationsRepository();
    final docs = documents ?? StubDocumentsRepository();
    final container = ProviderContainer(
      overrides: [
        operationsRepositoryProvider.overrideWithValue(ops),
        documentsRepositoryProvider.overrideWithValue(docs),
      ],
      retry: noAutomaticRetry,
    );
    addTearDown(container.dispose);
    // Keep the family element alive so a mid-flight invalidate rebuilds
    // immediately (bumping the generation) instead of disposing lazily.
    container.listen(writingProvider('doc-1'), (_, _) {});
    return (container, ops, docs);
  }

  group('writingProvider.generate', () {
    test(
      'no fetch on build; generate calls once; in-flight taps no-op',
      () async {
        final (container, ops, _) = containerFor();
        final pending = Completer<OperationReadDetail>();
        ops.draftHandler = ({required documentId, instruction}) =>
            pending.future;

        // Building the provider state never touches the repository.
        final initial = container.read(writingProvider('doc-1'));
        expect(initial.phase, WritingPhase.idle);
        expect(initial.operation, isNull);
        expect(ops.draftCalls, isEmpty);

        final notifier = container.read(writingProvider('doc-1').notifier);
        final first = notifier.generate(instruction: '续写一章');
        await container.pump();
        expect(ops.draftCalls, [(documentId: 'doc-1', instruction: '续写一章')]);
        expect(
          container.read(writingProvider('doc-1')).phase,
          WritingPhase.generating,
        );

        // A second tap while in flight is a synchronous no-op.
        await notifier.generate(instruction: '另一条指示');
        expect(ops.draftCalls, hasLength(1));

        pending.complete(completedDraftOperation());
        await first;

        final done = container.read(writingProvider('doc-1'));
        expect(done.phase, WritingPhase.review);
        expect(done.operation?.state, OperationState.completed);
        expect(done.operation?.draft?.title, '星际旅行草稿');
        expect(done.error, isNull);
      },
    );

    test(
      'failure restores the prior view and surfaces the raw error',
      () async {
        final (container, ops, _) = containerFor();
        ops.draftHandler = ({required documentId, instruction}) async {
          throw const ApiException(
            code: 'chat_unavailable',
            message: 'No API key configured',
            statusCode: 503,
          );
        };
        final notifier = container.read(writingProvider('doc-1').notifier);

        await notifier.generate();

        final failed = container.read(writingProvider('doc-1'));
        expect(failed.phase, WritingPhase.idle, reason: 'idle input stays up');
        expect(failed.operation, isNull);
        final error = failed.error;
        expect(error, isA<ApiException>());
        expect((error as ApiException).code, 'chat_unavailable');
      },
    );

    test('a superseded generation must not write stale state', () async {
      final (container, ops, _) = containerFor();
      final pending = Completer<OperationReadDetail>();
      ops.draftHandler = ({required documentId, instruction}) => pending.future;
      final notifier = container.read(writingProvider('doc-1').notifier);

      final stale = notifier.generate();
      await container.pump();

      // The provider rebuilds mid-flight (generation bump).
      container.invalidate(writingProvider('doc-1'));
      await container.pump();
      expect(container.read(writingProvider('doc-1')).phase, WritingPhase.idle);

      pending.complete(completedDraftOperation());
      await stale;

      final state = container.read(writingProvider('doc-1'));
      expect(state.phase, WritingPhase.idle);
      expect(state.operation, isNull);
      expect(state.error, isNull);
    });

    test(
      'clearCurrent drops an in-flight generate (late result never lands)',
      () async {
        final (container, ops, _) = containerFor();
        final pending = Completer<OperationReadDetail>();
        ops.draftHandler = ({required documentId, instruction}) =>
            pending.future;
        final notifier = container.read(writingProvider('doc-1').notifier);

        final run = notifier.generate();
        await container.pump();
        notifier.clearCurrent();
        expect(
          container.read(writingProvider('doc-1')).phase,
          WritingPhase.idle,
        );

        // The superseded result resolves late — it must not resurrect the view.
        pending.complete(completedDraftOperation());
        await run;

        final state = container.read(writingProvider('doc-1'));
        expect(state.phase, WritingPhase.idle);
        expect(state.operation, isNull);
      },
    );
  });

  group('writingProvider.resumeCurrent', () {
    test(
      'failed operation: openOperation → resume → completed review',
      () async {
        final (container, ops, _) = containerFor();
        final failedOp = operationFixture(
          id: 'op-f',
          state: OperationState.failed,
          error: {'error_class': 'LLMProviderError'},
        );
        ops.resumeHandler = (operationId) async =>
            completedDraftOperation(id: operationId);
        final notifier = container.read(writingProvider('doc-1').notifier);

        notifier.openOperation(failedOp);
        expect(
          container.read(writingProvider('doc-1')).phase,
          WritingPhase.review,
        );

        await notifier.resumeCurrent();

        expect(ops.resumeCalls, ['op-f']);
        final resumed = container.read(writingProvider('doc-1'));
        expect(resumed.phase, WritingPhase.review);
        expect(resumed.operation?.state, OperationState.completed);
        expect(resumed.error, isNull);
      },
    );

    test('resume only fires for interrupted/failed operations', () async {
      final (container, ops, _) = containerFor();
      final notifier = container.read(writingProvider('doc-1').notifier);

      // No operation: no-op.
      await notifier.resumeCurrent();
      expect(ops.resumeCalls, isEmpty);

      // Completed draft: the server would 409 — never fire the call.
      notifier.openOperation(completedDraftOperation());
      await notifier.resumeCurrent();
      expect(ops.resumeCalls, isEmpty);
    });

    test('interrupted operation resumes too', () async {
      final (container, ops, _) = containerFor();
      ops.resumeHandler = (operationId) async =>
          completedDraftOperation(id: operationId);
      final notifier = container.read(writingProvider('doc-1').notifier);

      notifier.openOperation(
        operationFixture(id: 'op-i', state: OperationState.interrupted),
      );
      await notifier.resumeCurrent();

      expect(ops.resumeCalls, ['op-i']);
      expect(
        container.read(writingProvider('doc-1')).operation?.state,
        OperationState.completed,
      );
    });
  });

  group('writingProvider.applyCurrent', () {
    test('apply success stores the applied operation and invalidates '
        'documentDetailProvider + documentsProvider', () async {
      final docs = StubDocumentsRepository();
      docs.listHandler = (cursor, limit, tags) async =>
          DocumentPage(items: [documentRead(id: 'doc-1')], nextCursor: null);
      docs.getHandler = (id) async =>
          documentReadDetail(documentRead(id: id), content: '正文$id');
      final (container, ops, _) = containerFor(documents: docs);
      ops.draftHandler = ({required documentId, instruction}) async =>
          completedDraftOperation();
      ops.applyHandler = (operationId) async =>
          applyResultFor(completedDraftOperation(id: operationId));

      // Load both document caches once so the invalidations below have
      // live elements to rebuild.
      container.listen(documentsProvider, (_, _) {});
      container.listen(documentDetailProvider('doc-1'), (_, _) {});
      await container.read(documentsProvider.future);
      await container.read(documentDetailProvider('doc-1').future);
      expect(docs.listCalls, hasLength(1));
      expect(docs.getCalls, ['doc-1']);

      final notifier = container.read(writingProvider('doc-1').notifier);
      await notifier.generate();
      await notifier.applyCurrent();

      // The applied operation (state applied + revision id) is the new
      // presentation; the workflow is reviewable again.
      final applied = container.read(writingProvider('doc-1'));
      expect(applied.phase, WritingPhase.review);
      expect(applied.operation?.state, OperationState.applied);
      expect(applied.operation?.revisionId, 'rev-1');

      // Both caches invalidated: detail + list refetch.
      await container.read(documentDetailProvider('doc-1').future);
      await container.read(documentsProvider.future);
      expect(docs.getCalls, ['doc-1', 'doc-1']);
      expect(docs.listCalls, hasLength(2));
    });

    test('apply fires with no expected base version and 409 keeps the prior '
        'draft state + surfaces the conflict code', () async {
      final (container, ops, _) = containerFor();
      ops.draftHandler = ({required documentId, instruction}) async =>
          completedDraftOperation();
      ops.applyHandler = (operationId) async {
        throw const ApiException(
          code: 'conflict',
          message:
              'Document changed since the draft was created; re-draft or '
              'resume the operation',
          details: {
            'base_version': '2026-08-31T12:30:00Z',
            'current_version': '2026-09-16T08:01:00Z',
          },
          statusCode: 409,
        );
      };
      final notifier = container.read(writingProvider('doc-1').notifier);
      await notifier.generate();
      expect(ops.applyCalls, isEmpty);

      await notifier.applyCurrent();

      expect(ops.applyCalls, ['op-1']);
      final conflicted = container.read(writingProvider('doc-1'));
      // Prior state kept: the draft stays reviewable with the error set.
      expect(conflicted.phase, WritingPhase.review);
      expect(conflicted.operation?.state, OperationState.completed);
      final error = conflicted.error;
      expect(error, isA<ApiException>());
      expect((error as ApiException).code, 'conflict');
      expect(error.statusCode, 409);

      // clearCurrent (重新生成) resets the workflow to the idle input.
      notifier.clearCurrent();
      final cleared = container.read(writingProvider('doc-1'));
      expect(cleared.phase, WritingPhase.idle);
      expect(cleared.operation, isNull);
      expect(cleared.error, isNull);
    });

    test(
      'a superseded apply still invalidates the mutated document caches',
      () async {
        final docs = StubDocumentsRepository();
        docs.listHandler = (cursor, limit, tags) async =>
            DocumentPage(items: [documentRead(id: 'doc-1')], nextCursor: null);
        docs.getHandler = (id) async =>
            documentReadDetail(documentRead(id: id), content: '正文');
        final (container, ops, _) = containerFor(documents: docs);
        final pending = Completer<ApplyResult>();
        ops.draftHandler = ({required documentId, instruction}) async =>
            completedDraftOperation();
        ops.applyHandler = (operationId) => pending.future;

        container.listen(documentsProvider, (_, _) {});
        container.listen(documentDetailProvider('doc-1'), (_, _) {});
        await container.read(documentsProvider.future);
        await container.read(documentDetailProvider('doc-1').future);

        final notifier = container.read(writingProvider('doc-1').notifier);
        await notifier.generate();
        final run = notifier.applyCurrent();
        await container.pump();
        expect(
          container.read(writingProvider('doc-1')).phase,
          WritingPhase.applying,
        );

        // The provider rebuilds while the apply is in flight…
        container.invalidate(writingProvider('doc-1'));
        await container.pump();
        pending.complete(applyResultFor(completedDraftOperation()));
        await run;

        // …the late result is dropped from state, but the document HAS been
        // mutated server-side — the invalidations must still have fired.
        final state = container.read(writingProvider('doc-1'));
        expect(state.phase, WritingPhase.idle);
        expect(state.operation, isNull);
        await container.read(documentDetailProvider('doc-1').future);
        await container.read(documentsProvider.future);
        expect(docs.getCalls, ['doc-1', 'doc-1']);
        expect(docs.listCalls, hasLength(2));
      },
    );

    test('apply is a no-op without an operation', () async {
      final (container, ops, _) = containerFor();
      await container.read(writingProvider('doc-1').notifier).applyCurrent();
      expect(ops.applyCalls, isEmpty);
    });
  });

  group('writingProvider history', () {
    test('loadHistory loads once on demand and caches; refreshHistory '
        'no-ops when never loaded', () async {
      final (container, ops, _) = containerFor();
      ops.operationsForDocumentHandler = (documentId) async => [
        completedDraftOperation(),
        operationFixture(id: 'op-2', state: OperationState.applied),
      ];
      final notifier = container.read(writingProvider('doc-1').notifier);

      // refreshHistory without a prior load stays zero-call.
      await notifier.refreshHistory();
      expect(ops.operationsForDocumentCalls, isEmpty);

      await notifier.loadHistory();
      expect(ops.operationsForDocumentCalls, ['doc-1']);
      final loaded = container.read(writingProvider('doc-1'));
      expect(loaded.history, hasLength(2));
      expect(loaded.history?[0].state, OperationState.completed);
      expect(loaded.history?[1].state, OperationState.applied);

      // Cached: a second open does not refetch.
      await notifier.loadHistory();
      expect(ops.operationsForDocumentCalls, hasLength(1));
    });

    test(
      'refreshHistory refetches a loaded list (apply/resume hook)',
      () async {
        final (container, ops, _) = containerFor();
        var applied = false;
        ops.operationsForDocumentHandler = (documentId) async => [
          completedDraftOperation(id: 'op-1').copyWith(
            state: applied ? OperationState.applied : OperationState.completed,
          ),
        ];
        final notifier = container.read(writingProvider('doc-1').notifier);

        await notifier.loadHistory();
        expect(ops.operationsForDocumentCalls, hasLength(1));
        expect(
          container.read(writingProvider('doc-1')).history?.single.state,
          OperationState.completed,
        );

        applied = true;
        await notifier.refreshHistory();
        expect(ops.operationsForDocumentCalls, hasLength(2));
        expect(
          container.read(writingProvider('doc-1')).history?.single.state,
          OperationState.applied,
        );
      },
    );

    test('failed load surfaces historyError; retry refetches', () async {
      final (container, ops, _) = containerFor();
      var fail = true;
      ops.operationsForDocumentHandler = (documentId) async {
        if (fail) {
          throw const ApiException(code: 'network_error', message: 'boom');
        }
        return [completedDraftOperation()];
      };
      final notifier = container.read(writingProvider('doc-1').notifier);

      await notifier.loadHistory();
      final failed = container.read(writingProvider('doc-1'));
      expect(failed.history, isNull);
      expect(failed.historyError, isA<ApiException>());

      fail = false;
      await notifier.loadHistory();
      final retried = container.read(writingProvider('doc-1'));
      expect(retried.history, hasLength(1));
      expect(retried.historyError, isNull);
    });

    test('openOperation presents a history item without any fetch', () async {
      final (container, ops, _) = containerFor();
      ops.operationsForDocumentHandler = (documentId) async => [
        completedDraftOperation(id: 'op-h'),
      ];
      final notifier = container.read(writingProvider('doc-1').notifier);

      await notifier.loadHistory();
      final item = container.read(writingProvider('doc-1')).history!.single;
      notifier.openOperation(item);

      final state = container.read(writingProvider('doc-1'));
      expect(state.phase, WritingPhase.review);
      expect(state.operation?.id, 'op-h');
      expect(
        ops.operationCalls,
        isEmpty,
        reason: 'list items are full details',
      );
    });

    test('clearCurrent (返回菜单) mid-fetch does not strand historyLoading; '
        'the fetch lands without clobbering newer workflow state', () async {
      final (container, ops, _) = containerFor();
      final historyPending = Completer<List<OperationReadDetail>>();
      final draftPending = Completer<OperationReadDetail>();
      ops.operationsForDocumentHandler = (documentId) => historyPending.future;
      ops.draftHandler = ({required documentId, instruction}) =>
          draftPending.future;
      final notifier = container.read(writingProvider('doc-1').notifier);

      final fetch = notifier.loadHistory();
      await container.pump();
      expect(container.read(writingProvider('doc-1')).historyLoading, isTrue);

      // 返回菜单 mid-fetch: the workflow resets, the fetch slice stays live.
      notifier.clearCurrent();
      final cleared = container.read(writingProvider('doc-1'));
      expect(cleared.phase, WritingPhase.idle);
      expect(cleared.historyLoading, isTrue);

      // Re-opening the section mid-fetch is a single-live-fetch no-op —
      // not a second call racing the first.
      await notifier.loadHistory();
      expect(ops.operationsForDocumentCalls, hasLength(1));

      // A workflow action lands while the fetch is still in flight…
      final run = notifier.generate(instruction: '续写');
      await container.pump();
      expect(
        container.read(writingProvider('doc-1')).phase,
        WritingPhase.generating,
      );
      draftPending.complete(completedDraftOperation());
      await run;
      expect(
        container.read(writingProvider('doc-1')).phase,
        WritingPhase.review,
      );

      // …and the fetch lands afterwards WITHOUT clobbering the workflow
      // slice — and without leaving the spinner stranded.
      historyPending.complete([completedDraftOperation(id: 'op-h')]);
      await fetch;

      final landed = container.read(writingProvider('doc-1'));
      expect(landed.historyLoading, isFalse);
      expect(landed.history?.single.id, 'op-h');
      expect(landed.phase, WritingPhase.review);
      expect(landed.operation?.id, 'op-1');

      // Cached again: a later open does not refetch.
      await notifier.loadHistory();
      expect(ops.operationsForDocumentCalls, hasLength(1));
    });

    test('a provider rebuild supersedes an in-flight history fetch and '
        'resets the loading flag with the state', () async {
      final (container, ops, _) = containerFor();
      final pending = Completer<List<OperationReadDetail>>();
      ops.operationsForDocumentHandler = (documentId) => pending.future;
      final notifier = container.read(writingProvider('doc-1').notifier);

      final fetch = notifier.loadHistory();
      await container.pump();
      expect(container.read(writingProvider('doc-1')).historyLoading, isTrue);

      // The provider rebuilds mid-fetch (the only history-fetch
      // superseder): the rebuild resets the whole state…
      container.invalidate(writingProvider('doc-1'));
      await container.pump();
      final fresh = container.read(writingProvider('doc-1'));
      expect(fresh.historyLoading, isFalse);
      expect(fresh.history, isNull);

      // …so the late result is dropped and nothing strands.
      pending.complete([completedDraftOperation()]);
      await fetch;
      final state = container.read(writingProvider('doc-1'));
      expect(state.history, isNull);
      expect(state.historyLoading, isFalse);
      expect(state.historyError, isNull);

      // The section can load again normally.
      ops.operationsForDocumentHandler = (documentId) async => [
        completedDraftOperation(id: 'op-late'),
      ];
      await notifier.loadHistory();
      expect(
        container.read(writingProvider('doc-1')).history?.single.id,
        'op-late',
      );
    });
  });
}
