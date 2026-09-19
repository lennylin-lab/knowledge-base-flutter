import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/document_editor_page.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/features/documents/edit_draft_store.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stub_documents_repository.dart';

Future<void> pumpApp(WidgetTester tester, StubDocumentsRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
      retry: noAutomaticRetry,
      child: App(),
    ),
  );
}

/// Minimal router harness where the editor is the ONLY route: `canPop` is
/// false, so a successful save cannot navigate away — the same editor session
/// keeps running and a second save can be issued (guard-null regression).
Future<void> pumpLoneEditor(
  WidgetTester tester,
  StubDocumentsRepository repo,
  String documentId,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
      retry: noAutomaticRetry,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/documents/$documentId/edit',
          routes: [
            GoRoute(
              path: '/documents/:id/edit',
              builder: (context, state) =>
                  DocumentEditorPage(documentId: state.pathParameters['id']),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The editor's content field is the second TextField (title override is
/// the first).
Finder get contentField => find.byType(TextField).at(1);

Finder get titleField => find.byType(TextField).at(0);

/// Drains snackbar auto-dismiss timers (2s) and pending debounce timers so
/// tests end with no pending `Timer`.
Future<void> flushTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Seeds a persisted draft (simulating a previous session), via the real
/// store so the on-disk shape stays honest.
Future<void> seedDraft(
  String scopeKey, {
  required String content,
  String titleOverride = '',
  String? baselineContentHash,
  String? baselineContent,
}) async {
  await EditDraftStore().save(
    EditDraft(
      scopeKey: scopeKey,
      content: content,
      titleOverride: titleOverride,
      baselineContentHash: baselineContentHash,
      baselineContent: baselineContent,
      savedAt: DateTime.parse('2026-09-19T08:00:00.000'),
    ),
  );
}

const kOriginalContent = '---\ntitle: 旧标题\n---\n\n旧正文';

/// Boots the app, opens [document] in the list and enters the editor.
Future<void> openEditor(
  WidgetTester tester,
  StubDocumentsRepository repo,
  DocumentRead document,
) async {
  await pumpApp(tester, repo);
  await tester.pumpAndSettle();
  await tester.tap(find.text(document.title));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('编辑'));
  await tester.pumpAndSettle();
}

DocumentRead docFixture(String id) => documentRead(id: id, title: '旧标题');

/// List + get(+update) stub for the standard edit-mode editor flow.
StubDocumentsRepository repoFor(
  DocumentRead document, {
  String? contentHash,
  Future<DocumentRead> Function(String id, DocumentUpdate payload)? update,
}) {
  final repo = StubDocumentsRepository();
  repo.listHandler = (cursor, limit, tag) async {
    return DocumentPage(items: [document], nextCursor: null);
  };
  repo.getHandler = (id) async => documentReadDetail(
    document,
    content: kOriginalContent,
    contentHash: contentHash,
  );
  repo.updateHandler =
      update ??
      (id, payload) async => document.copyWith(updatedAt: '2026-09-01T08:00:00Z');
  return repo;
}

void main() {
  setUp(() {
    // Fresh persisted state for every test; the draft store reads/writes the
    // same mock singleton the editor's own store instance resolves.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('create: prefills the front-matter template, saves and opens the new detail', (
    tester,
  ) async {
    // `done` (not the realistic `pending`): a pending status chip renders an
    // indeterminate spinner, which never lets `pumpAndSettle` settle. The
    // pending chip itself is covered in documents_page_test.
    final created = documentRead(id: 'created-1', title: '新文档');
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return const DocumentPage(items: [], nextCursor: null);
          }
          ..createHandler = (payload) async {
            return created;
          }
          ..getHandler =
              (id) async => documentReadDetail(
                created,
                content: '# 新文档正文',
              );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新建文档'));
    await tester.pumpAndSettle();

    // Create mode prefills the YAML front-matter template.
    expect(find.text('新建文档'), findsOneWidget);
    expect(
      tester.widget<TextField>(contentField).controller!.text,
      startsWith('---\ntitle:'),
    );

    const content = '---\ntitle: 测试\n---\n\n# 测试正文';
    await tester.enterText(contentField, content);
    await tester.tap(find.text('保存'));
    await tester.pump(); // save starts
    await tester.pump(const Duration(milliseconds: 100)); // create resolves
    await tester.pumpAndSettle(); // pushReplacement → detail

    // Full markdown posted; no title override sent.
    expect(repo.createCalls.single.content, content);
    expect(repo.createCalls.single.title, isNull);
    // Navigated to the created document's detail.
    expect(repo.getCalls, contains('created-1'));
    expect(find.text('新文档正文'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('create: empty content is rejected client-side (no request)', (
    tester,
  ) async {
    final repo =
        StubDocumentsRepository()
          ..listHandler =
              (cursor, limit, tag) async =>
                  const DocumentPage(items: [], nextCursor: null);

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新建文档'));
    await tester.pumpAndSettle();

    await tester.enterText(contentField, '   ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.createCalls, isEmpty);
    expect(find.text('正文不能为空'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('update: prefills from the loaded document and PATCHes on save', (
    tester,
  ) async {
    const originalContent = '---\ntitle: 旧标题\n---\n\n旧正文';
    final document = documentRead(id: 'doc-1', title: '旧标题');
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler = (id) async {
            return documentReadDetail(document, content: originalContent);
          }
          ..updateHandler =
              (id, payload) async => document.copyWith(
                title: '新标题',
                updatedAt: '2026-09-01T08:00:00Z',
              );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('旧标题'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('编辑'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(contentField).controller!.text,
      originalContent,
    );

    await tester.enterText(contentField, '# 新正文');
    await tester.tap(find.text('保存'));
    await tester.pump(); // save starts
    await tester.pump(const Duration(milliseconds: 100)); // patch resolves
    await tester.pumpAndSettle(); // pop back to the detail

    expect(repo.updateCalls.single.id, 'doc-1');
    expect(repo.updateCalls.single.payload.content, '# 新正文');
    // Detail was invalidated → refetched.
    expect(repo.getCalls.where((id) => id == 'doc-1').length, greaterThanOrEqualTo(2));
    // Editor is gone; detail still shown.
    expect(find.text('编辑文档'), findsNothing);
    expect(find.text('旧标题'), findsWidgets);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  group('dirty flag + local draft', () {
    testWidgets('typing shows the unsaved indicator and persists the draft '
        'after ~1s; reverting to the baseline cleans up', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');

      await openEditor(tester, repo, document);
      expect(find.text('未保存'), findsNothing);

      await tester.enterText(contentField, '# 新正文');
      // enterText schedules the dirty rebuild; pump to flush the frame.
      await tester.pump();
      expect(find.text('未保存'), findsOneWidget);
      // Nothing persisted before the debounce elapses.
      expect(await EditDraftStore().load('doc-1'), isNull);

      await tester.pump(const Duration(milliseconds: 1100));
      final draft = await EditDraftStore().load('doc-1');
      expect(draft, isNotNull);
      expect(draft!.content, '# 新正文');
      expect(draft.titleOverride, '');
      expect(draft.baselineContentHash, 'hash-1');

      // Edit back to the baseline → sticky dirty flips back at the tick and
      // the persisted draft is dropped.
      await tester.enterText(contentField, kOriginalContent);
      await tester.pump();
      expect(find.text('未保存'), findsOneWidget); // still sticky-dirty
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('未保存'), findsNothing);
      expect(await EditDraftStore().load('doc-1'), isNull);

      await flushTimers(tester);
    });

    testWidgets('a title override alone marks the editor dirty', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');

      await openEditor(tester, repo, document);
      await tester.enterText(titleField, '新标题覆盖');
      await tester.pump();
      expect(find.text('未保存'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100));
      final draft = await EditDraftStore().load('doc-1');
      expect(draft!.titleOverride, '新标题覆盖');
      expect(draft.content, kOriginalContent);

      await flushTimers(tester);
    });
  });

  group('save payload guard (expected_content_hash)', () {
    testWidgets('PATCH carries the detail content_hash as the guard', (
      tester,
    ) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');

      await openEditor(tester, repo, document);
      await tester.enterText(contentField, '# 新正文');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(); // pop back to detail

      expect(repo.updateCalls.single.payload.content, '# 新正文');
      expect(repo.updateCalls.single.payload.expectedContentHash, 'hash-1');
      expect(repo.updateCalls.single.payload.toJson()['expected_content_hash'],
          'hash-1');

      await flushTimers(tester);
    });

    testWidgets('no baseline hash (old backend / pre-backfill) → guard stays '
        'off the wire', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: null);

      await openEditor(tester, repo, document);
      await tester.enterText(contentField, '# 新正文');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.single.payload.expectedContentHash, isNull);
      expect(
        repo.updateCalls.single.payload.toJson().containsKey(
              'expected_content_hash',
            ),
        isFalse,
      );

      await flushTimers(tester);
    });

    testWidgets('same-session save after a successful save omits the guard '
        '(stale-hash 409 regression)', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');

      // Lone editor: canPop is false, so the successful save does NOT
      // navigate away and the session continues.
      await pumpLoneEditor(tester, repo, 'doc-1');
      await tester.pumpAndSettle();

      await tester.enterText(contentField, '# 第一次保存');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(repo.updateCalls, hasLength(1));
      expect(repo.updateCalls.first.payload.expectedContentHash, 'hash-1');

      // Re-edit and save again in the same session: the baseline hash was
      // nulled after the first success (the update response carries no new
      // hash), so the second PATCH must not replay the stale guard.
      await tester.enterText(contentField, '# 第二次保存');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(repo.updateCalls, hasLength(2));
      expect(
        repo.updateCalls.last.payload.toJson().containsKey(
              'expected_content_hash',
            ),
        isFalse,
      );
      expect(repo.updateCalls.last.payload.content, '# 第二次保存');

      await flushTimers(tester);
    });
  });

  group('save failures', () {
    testWidgets('409 conflict keeps the document untouched and 「重新加载」 '
        'clears the draft + resets the baseline', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(
        document,
        contentHash: 'hash-1',
        update: (id, payload) async =>
            throw const ApiException(
              code: 'conflict',
              message: '文档已被他人修改',
              statusCode: 409,
            ),
      );

      await openEditor(tester, repo, document);
      await tester.enterText(contentField, '# 冲突编辑');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Conflict surfaced with the reload action; editor stays open.
      expect(find.textContaining('保存失败：文档已被他人修改'), findsOneWidget);
      expect(find.text('编辑文档'), findsOneWidget);
      expect(repo.updateCalls, hasLength(1));

      final getCallsBefore = repo.getCalls.where((id) => id == 'doc-1').length;
      await tester.tap(find.text('重新加载'));
      await tester.pumpAndSettle();

      // Server content re-adopted, guard baseline reset, draft dropped.
      expect(
        tester.widget<TextField>(contentField).controller!.text,
        kOriginalContent,
      );
      expect(find.text('未保存'), findsNothing);
      expect(await EditDraftStore().load('doc-1'), isNull);
      expect(repo.getCalls.where((id) => id == 'doc-1').length,
          getCallsBefore + 1);

      await flushTimers(tester);
    });

    testWidgets('network failure toasts 「未保存内容已保留」 and flushes the draft '
        'immediately (no debounce wait)', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(
        document,
        contentHash: 'hash-1',
        update: (id, payload) async => throw const ApiException(
          code: 'network_error',
          message: '网络连接异常，请检查网络后重试',
        ),
      );

      await openEditor(tester, repo, document);
      await tester.enterText(contentField, '# 网络失败编辑');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('未保存内容已保留，重新登录后可恢复'),
        findsOneWidget,
      );
      // Editor stays open on the failed save.
      expect(find.text('编辑文档'), findsOneWidget);
      // Flushed in the catch, before the debounce could fire.
      final draft = await EditDraftStore().load('doc-1');
      expect(draft, isNotNull);
      expect(draft!.content, '# 网络失败编辑');
      expect(draft.baselineContentHash, 'hash-1');

      await flushTimers(tester);
    });
  });

  group('PopScope back gate', () {
    testWidgets('clean editor pops without any dialog', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');

      await openEditor(tester, repo, document);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('编辑文档'), findsNothing);
      expect(find.text('有未保存的更改'), findsNothing);
    });

    testWidgets('「保留草稿退出」 flushes the latest buffer and exits', (
      tester,
    ) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');

      await openEditor(tester, repo, document);
      await tester.enterText(contentField, '# 退出前的编辑');
      // Flush the dirty rebuild so PopScope.canPop is false when back fires.
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('有未保存的更改'), findsOneWidget);
      expect(find.text('放弃'), findsOneWidget);
      expect(find.text('保留草稿退出'), findsOneWidget);

      await tester.tap(find.text('保留草稿退出'));
      await tester.pumpAndSettle();

      expect(find.text('编辑文档'), findsNothing);
      final draft = await EditDraftStore().load('doc-1');
      expect(draft, isNotNull);
      expect(draft!.content, '# 退出前的编辑');
      expect(repo.updateCalls, isEmpty);
    });

    testWidgets('「放弃」 exits directly without a second confirmation or a save',
        (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');

      await openEditor(tester, repo, document);
      await tester.enterText(contentField, '# 放弃的编辑');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('有未保存的更改'), findsOneWidget);

      await tester.tap(find.text('放弃'));
      await tester.pumpAndSettle();

      expect(find.text('编辑文档'), findsNothing);
      expect(find.text('有未保存的更改'), findsNothing);
      expect(repo.updateCalls, isEmpty);
    });

    testWidgets('「保存」 saves from the dialog and pops on success', (
      tester,
    ) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');

      await openEditor(tester, repo, document);
      await tester.enterText(contentField, '# 对话框保存');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('有未保存的更改'), findsOneWidget);

      // The AppBar also has a 保存 TextButton — target the dialog button.
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.single.payload.content, '# 对话框保存');
      expect(repo.updateCalls.single.payload.expectedContentHash, 'hash-1');
      expect(find.text('编辑文档'), findsNothing);

      await flushTimers(tester);
    });
  });

  group('draft restore on open', () {
    testWidgets('matching baseline hash restores silently with a toast '
        '(app-kill recovery path)', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');
      await seedDraft(
        'doc-1',
        content: '# 草稿正文',
        titleOverride: '草稿标题',
        baselineContentHash: 'hash-1',
      );

      await openEditor(tester, repo, document);

      expect(
        tester.widget<TextField>(contentField).controller!.text,
        '# 草稿正文',
      );
      expect(
        tester.widget<TextField>(titleField).controller!.text,
        '草稿标题',
      );
      expect(find.text('已恢复未保存的草稿'), findsOneWidget);
      expect(find.text('未保存'), findsOneWidget);

      // Saving the restored draft guards with the server's current hash.
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.single.payload.content, '# 草稿正文');
      expect(repo.updateCalls.single.payload.title, '草稿标题');
      expect(repo.updateCalls.single.payload.expectedContentHash, 'hash-1');

      await flushTimers(tester);
    });

    testWidgets('matching baseline content with an inconclusive hash also '
        'restores silently (tier 2)', (tester) async {
      // Draft whose hash tier fails (stale/unknown) but whose verbatim
      // baseline content equals the loaded document: not modified elsewhere.
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');
      await seedDraft(
        'doc-1',
        content: '# 判定二草稿',
        baselineContentHash: 'stale-hash',
        baselineContent: kOriginalContent,
      );

      await openEditor(tester, repo, document);

      expect(find.text('检测到未保存的草稿'), findsNothing);
      expect(
        tester.widget<TextField>(contentField).controller!.text,
        '# 判定二草稿',
      );
      expect(find.text('已恢复未保存的草稿'), findsOneWidget);
      expect(find.text('未保存'), findsOneWidget);

      await flushTimers(tester);
    });

    testWidgets('save → re-edit in the same session → reopen restores '
        'silently via the baseline-content tier', (tester) async {
      // The full post-save flow: the in-session save nulls the baseline
      // hash, so the draft persisted afterwards has an inconclusive hash —
      // only the verbatim baseline content can prove the document survived
      // unchanged.
      final document = docFixture('doc-1');
      var serverContent = kOriginalContent;
      var serverHash = 'hash-1';
      final repo = StubDocumentsRepository();
      repo.listHandler = (cursor, limit, tag) async {
        return DocumentPage(items: [document], nextCursor: null);
      };
      repo.getHandler = (id) async => documentReadDetail(
        document,
        content: serverContent,
        contentHash: serverHash,
      );
      repo.updateHandler = (id, payload) async {
        // The server recomputes content_hash on every mutation.
        serverContent = payload.content!;
        serverHash = 'hash-2';
        return document.copyWith(updatedAt: '2026-09-01T08:00:00Z');
      };

      // Lone editor: canPop is false, so the save keeps the session open.
      await pumpLoneEditor(tester, repo, 'doc-1');
      await tester.pumpAndSettle();

      // 1. Save: the guard carries the freshly loaded hash...
      await tester.enterText(contentField, '# 第一次保存');
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(repo.updateCalls.single.payload.expectedContentHash, 'hash-1');

      // 2. ...and is nulled afterwards; re-editing persists a draft with an
      //    inconclusive hash but the verbatim saved baseline content.
      await tester.enterText(contentField, '# 第二次编辑');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      final stored = await EditDraftStore().load('doc-1');
      expect(stored, isNotNull);
      expect(stored!.baselineContentHash, isNull);
      expect(stored.baselineContent, '# 第一次保存');
      expect(stored.content, '# 第二次编辑');

      // Drain the success toast, then simulate an app kill.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // 3. Reopen: hash tier inconclusive (draft null vs server hash-2) but
      //    the baseline content equals the loaded document → silent restore,
      //    no conflict dialog.
      await pumpLoneEditor(tester, repo, 'doc-1');
      await tester.pumpAndSettle();

      expect(find.text('检测到未保存的草稿'), findsNothing);
      expect(
        tester.widget<TextField>(contentField).controller!.text,
        '# 第二次编辑',
      );
      expect(find.text('已恢复未保存的草稿'), findsOneWidget);
      expect(find.text('未保存'), findsOneWidget);

      // Saving the restored draft guards with the fresh server hash.
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(repo.updateCalls, hasLength(2));
      expect(repo.updateCalls.last.payload.content, '# 第二次编辑');
      expect(repo.updateCalls.last.payload.expectedContentHash, 'hash-2');

      await flushTimers(tester);
    });

    testWidgets('stale baseline hash → 「用草稿」 restores and re-baselines on '
        'the server hash', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');
      await seedDraft(
        'doc-1',
        content: '# 别处没动过的草稿',
        baselineContentHash: 'stale-hash',
      );

      await openEditor(tester, repo, document);

      // Nothing auto-restored; the choice dialog is up.
      expect(find.text('检测到未保存的草稿'), findsOneWidget);
      expect(
        tester.widget<TextField>(contentField).controller!.text,
        kOriginalContent,
      );

      await tester.tap(find.text('用草稿'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(contentField).controller!.text,
        '# 别处没动过的草稿',
      );
      expect(find.text('未保存'), findsOneWidget);

      // The guard must carry the server's CURRENT hash, not the stale one.
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.single.payload.expectedContentHash, 'hash-1');

      await flushTimers(tester);
    });

    testWidgets('stale baseline hash → 「用最新内容」 keeps server content and '
        'clears the draft', (tester) async {
      final document = docFixture('doc-1');
      final repo = repoFor(document, contentHash: 'hash-1');
      await seedDraft(
        'doc-1',
        content: '# 过期草稿',
        baselineContentHash: 'stale-hash',
      );

      await openEditor(tester, repo, document);
      expect(find.text('检测到未保存的草稿'), findsOneWidget);

      await tester.tap(find.text('用最新内容'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(contentField).controller!.text,
        kOriginalContent,
      );
      expect(find.text('未保存'), findsNothing);
      expect(await EditDraftStore().load('doc-1'), isNull);

      await flushTimers(tester);
    });

    testWidgets('create mode restores the "new"-scoped draft with a toast', (
      tester,
    ) async {
      final created = documentRead(id: 'created-1', title: '新文档');
      final repo = StubDocumentsRepository();
      repo.listHandler = (cursor, limit, tag) async {
        return const DocumentPage(items: [], nextCursor: null);
      };
      repo.createHandler = (payload) async => created;
      repo.getHandler = (id) async =>
          documentReadDetail(created, content: '# 新文档正文');
      await seedDraft(
        newDocumentDraftScopeKey,
        content: '# 上次没写完的草稿',
        titleOverride: '草稿标题',
      );

      await pumpApp(tester, repo);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('新建文档'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(contentField).controller!.text,
        '# 上次没写完的草稿',
      );
      expect(
        tester.widget<TextField>(titleField).controller!.text,
        '草稿标题',
      );
      expect(find.text('已恢复未保存的草稿'), findsOneWidget);
      expect(find.text('未保存'), findsOneWidget);

      // Saving moves the draft into a real document and drops the "new"
      // draft so the next create session starts clean.
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(repo.createCalls.single.content, '# 上次没写完的草稿');
      expect(repo.createCalls.single.title, '草稿标题');
      expect(await EditDraftStore().load(newDocumentDraftScopeKey), isNull);

      await flushTimers(tester);
    });
  });
}
