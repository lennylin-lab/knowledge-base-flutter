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

  testWidgets('the fixed header shows the description blurb under the tags', (
    tester,
  ) async {
    final document = documentRead(
      id: 'doc-1',
      title: '设计笔记',
      description: '检索与索引的设计要点。',
    );
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler =
              (id) async => documentReadDetail(document, content: '# 设计笔记');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('设计笔记'));
    await tester.pumpAndSettle();

    expect(find.text('检索与索引的设计要点。'), findsOneWidget);
  });

  testWidgets('an empty description renders nothing in the header', (
    tester,
  ) async {
    final document = documentRead(id: 'doc-1', title: '设计笔记');
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler =
              (id) async => documentReadDetail(document, content: '# 设计笔记');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('设计笔记'));
    await tester.pumpAndSettle();

    expect(find.text('设计笔记'), findsWidgets);
    expect(find.text(''), findsNothing);
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

  testWidgets('tapping a task checkbox flips the marker and PATCHes content', (
    tester,
  ) async {
    final document = documentRead(id: 'doc-1', title: '清单文档');
    var stored = '- [ ] 甲\n- [ ] 乙\n';
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler = (id) async {
            return documentReadDetail(document, content: stored);
          }
          ..updateHandler = (id, payload) async {
            stored = payload.content!;
            return documentRead(id: id);
          };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('清单文档'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).first);
    await tester.pump(); // optimistic flip renders before any network I/O
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(
      repo.updateCalls,
      isEmpty,
    ); // debounced: nothing on the wire yet

    await tester.pump(const Duration(milliseconds: 600)); // debounce fires
    await tester.pumpAndSettle(); // PATCH + detail refetch land

    expect(repo.updateCalls, [
      (
        id: 'doc-1',
        payload: const DocumentUpdate(content: '- [x] 甲\n- [ ] 乙\n'),
      ),
    ]);
    // The refetched server content (marker flipped) keeps the box checked.
    expect(find.byIcon(Icons.check_box), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('rapid checkbox bursts collapse into a single PATCH', (
    tester,
  ) async {
    final document = documentRead(id: 'doc-1', title: '清单文档');
    var stored = '- [ ] 甲\n- [ ] 乙\n';
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler = (id) async {
            return documentReadDetail(document, content: stored);
          }
          ..updateHandler = (id, payload) async {
            stored = payload.content!;
            return documentRead(id: id);
          };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('清单文档'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pump(const Duration(milliseconds: 100));
    // Both flips render optimistically; the burst has not hit the wire.
    expect(find.byIcon(Icons.check_box), findsNWidgets(2));
    expect(repo.updateCalls, isEmpty);

    // Each tap re-arms the debounce; only the last content of the burst is
    // sent — one PATCH carrying both flips.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, [
      (
        id: 'doc-1',
        payload: const DocumentUpdate(content: '- [x] 甲\n- [x] 乙\n'),
      ),
    ]);
    expect(find.byIcon(Icons.check_box), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('a refetch echo landing mid-burst keeps the pending flips', (
    tester,
  ) async {
    final document = documentRead(id: 'doc-1', title: '清单文档');
    var stored = '- [ ] 甲\n- [ ] 乙\n';
    final firstPatchReleased = Completer<void>();
    var patches = 0;
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler = (id) async {
            return documentReadDetail(document, content: stored);
          }
          ..updateHandler = (id, payload) async {
            patches += 1;
            if (patches == 1) await firstPatchReleased.future;
            stored = payload.content!;
            return documentRead(id: id);
          };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('清单文档'));
    await tester.pumpAndSettle();

    // 甲 flips; debounce fires while PATCH #1 is held in flight.
    await tester.tap(find.byIcon(Icons.check_box_outline_blank).first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(repo.updateCalls, hasLength(1));

    // 乙 flips while PATCH #1 is still in flight; its debounce re-arms and
    // enqueues PATCH #2 behind the held request.
    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pump(const Duration(milliseconds: 600));

    firstPatchReleased.complete();
    await tester.pumpAndSettle();

    // The refetch after PATCH #1 carries only 甲 — an echo of our own send,
    // not an external edit — so 乙's pending flip must survive it.
    expect(repo.updateCalls, [
      (
        id: 'doc-1',
        payload: const DocumentUpdate(content: '- [x] 甲\n- [ ] 乙\n'),
      ),
      (
        id: 'doc-1',
        payload: const DocumentUpdate(content: '- [x] 甲\n- [x] 乙\n'),
      ),
    ]);
    expect(find.byIcon(Icons.check_box), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('leaving the page flushes an unsent checkbox burst', (
    tester,
  ) async {
    final document = documentRead(id: 'doc-1', title: '清单文档');
    var stored = '- [ ] 甲\n- [ ] 乙\n';
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler = (id) async {
            return documentReadDetail(document, content: stored);
          }
          ..updateHandler = (id, payload) async {
            stored = payload.content!;
            return documentRead(id: id);
          };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('清单文档'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).first);
    await tester.pump();
    expect(repo.updateCalls, isEmpty);

    // Back out before the debounce fires — dispose must flush the burst.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(
      repo.updateCalls,
      [
        (
          id: 'doc-1',
          payload: const DocumentUpdate(content: '- [x] 甲\n- [ ] 乙\n'),
        ),
      ],
    );
    expect(find.text('清单文档'), findsOneWidget); // back on the list

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('a failed checkbox PATCH reverts the flip and toasts', (
    tester,
  ) async {
    final document = documentRead(id: 'doc-1', title: '清单文档');
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
            return DocumentPage(items: [document], nextCursor: null);
          }
          ..getHandler = (id) async {
            return documentReadDetail(document, content: '- [ ] 甲\n');
          }
          ..updateHandler = (id, payload) async => throw const ApiException(
            code: 'server_error',
            message: 'boom',
            statusCode: 500,
          );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('清单文档'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pump();
    // Debounce fires, the stub PATCH fails, the optimistic flip reverts.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box), findsNothing);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.text('保存失败：boom'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
