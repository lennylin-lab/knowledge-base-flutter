import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/document_detail_page.dart';
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

void main() {
  testWidgets('renders title/tags/content and formats the markdown', (
    tester,
  ) async {
    final document = documentRead(id: 'doc-1', title: '设计笔记', tags: ['flutter']);
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler =
              (id) async => documentReadDetail(
                document,
                content:
                    '---\ntitle: 设计笔记\ntags: [flutter]\n---\n\n# 设计笔记\n\n混合检索正文',
              );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('设计笔记'));
    await tester.pumpAndSettle();

    expect(find.text('设计笔记'), findsWidgets); // app bar title + markdown heading
    expect(find.text('#flutter'), findsOneWidget);
    // Front matter is stripped from the rendered body.
    expect(find.text('title: 设计笔记'), findsNothing);
    expect(find.text('tags: [flutter]'), findsNothing);
    // Markdown is rendered: body text exists as selectable text widgets.
    expect(find.text('混合检索正文'), findsOneWidget);
  });

  testWidgets('404 toasts 文档不存在或已删除 and pops back to the list', (
    tester,
  ) async {
    final gone = documentRead(id: 'gone', title: '已删除的文档');
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [gone], nextCursor: null);
          }
          ..getHandler =
              (id) async => throw const ApiException(
                code: 'not_found',
                message: 'Document gone not found',
                statusCode: 404,
              );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('已删除的文档'));
    await tester.pump(); // route push, detail starts loading
    // The floating AI entry only exists while detail data renders — it is
    // hidden in the loading pane...
    expect(find.byType(AiAssistantFab), findsNothing);
    await tester.pump(const Duration(milliseconds: 100)); // future fails
    await tester.pumpAndSettle(); // listener pops back to the list
    // ...and in the error pane.
    expect(find.byType(AiAssistantFab), findsNothing);

    // Back on the list; the toast carries the Chinese copy.
    expect(find.text('已删除的文档'), findsOneWidget);
    expect(find.text('文档不存在或已删除'), findsWidgets);

    // Drain the snackbar timer so the test can end cleanly.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('delete asks for confirmation, then deletes and pops', (
    tester,
  ) async {
    final document = documentRead(id: 'doc-1', title: '要删除的文档');
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler = (id) async {
            return documentReadDetail(document);
          }
          ..deleteHandler = (id) async {};

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('要删除的文档'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();

    // Confirmation dialog first — nothing deleted until confirmed.
    expect(find.text('删除文档'), findsOneWidget);
    expect(repo.deleteCalls, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pump(); // delete starts
    await tester.pump(const Duration(milliseconds: 100)); // 204 resolves
    await tester.pumpAndSettle(); // pop back to the refreshed list

    expect(repo.deleteCalls, ['doc-1']);
    expect(find.text('已删除'), findsOneWidget);
    // List refetched after the delete.
    expect(repo.listCalls.length, greaterThanOrEqualTo(2));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'delete: the post-delete 404 refetch must not double-toast or double-pop',
    (tester) async {
      // The notifier invalidates the detail provider right after the 204;
      // that refetch 404s while the page is still mounted. Hold the list
      // refresh open so the 404 reliably lands BEFORE the 已删除 pop.
      final document = documentRead(id: 'doc-1', title: '要删除的文档');
      final listRefreshed = Completer<void>();
      var getCalls = 0;
      var listCalls = 0;
      final repo =
          StubDocumentsRepository()
            ..listHandler = (cursor, limit, tag) async {
              listCalls++;
              if (listCalls == 1) {
                return DocumentPage(items: [document], nextCursor: null);
              }
              await listRefreshed.future;
              return const DocumentPage(items: [], nextCursor: null);
            }
            ..getHandler = (id) async {
              getCalls++;
              if (getCalls == 1) return documentReadDetail(document);
              throw const ApiException(
                code: 'not_found',
                message: 'Document doc-1 not found',
                statusCode: 404,
              );
            }
            ..deleteHandler = (id) async {};

      await pumpApp(tester, repo);
      await tester.pumpAndSettle();

      await tester.tap(find.text('要删除的文档'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pump(); // delete resolves, detail invalidated → 404 lands
      await tester.pump(const Duration(milliseconds: 100));

      // Release the list refresh: the 已删除 toast fires and the page pops.
      listRefreshed.complete();
      await tester.pump();
      await tester.pumpAndSettle();

      // Back on the list with exactly one snackbar — the 404 from our own
      // deletion was suppressed instead of queueing 文档不存在或已删除.
      expect(repo.deleteCalls, ['doc-1']);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('已删除'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('文档不存在或已删除'),
        ),
        findsNothing,
      );
      expect(find.text('暂无文档'), findsOneWidget); // list, not detail

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );
}
