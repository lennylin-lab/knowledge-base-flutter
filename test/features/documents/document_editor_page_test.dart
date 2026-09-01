import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

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

/// The editor's content field is the second TextField (title override is
/// the first).
Finder get contentField => find.byType(TextField).at(1);

void main() {
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
}
