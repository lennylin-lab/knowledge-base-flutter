import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/document_detail_page.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/agents_result.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

import 'stub_documents_repository.dart';

/// Pumps the full app (adaptive shell + real router) with the documents
/// repository stubbed — no dio, no network.
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
  testWidgets(
    'renders rows with title/tags and no document status anywhere',
    (tester) async {
      final repo = StubDocumentsRepository()
        ..listHandler = (cursor, limit, tags) async => DocumentPage(
          items: [
            documentRead(
              id: 'a',
              title: '待索引文档',
              indexStatus: IndexStatus.pending,
            ),
            documentRead(
              id: 'b',
              title: '索引失败文档',
              indexStatus: IndexStatus.failed,
            ),
            documentRead(id: 'c', title: '正常文档'),
          ],
          nextCursor: null,
        );

      await pumpApp(tester, repo);
      await tester.pump(); // first frame, provider starts fetching
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('待索引文档'), findsOneWidget);
      expect(find.text('索引失败文档'), findsOneWidget);
      expect(find.text('正常文档'), findsOneWidget);
      // Status rendering was removed from the UI: no chips, no spinner,
      // no retry affordance — whatever index_status the backend returns.
      expect(find.text('索引中'), findsNothing);
      expect(find.text('索引失败'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('loads the next keyset page when scrolled near the end', (
    tester,
  ) async {
    final pageOne = List.generate(
      25,
      (i) => documentRead(id: 'id-$i', title: '文档 $i'),
    );
    final repo = StubDocumentsRepository()
      ..listHandler = (cursor, limit, tags) async {
        if (cursor == null) {
          return DocumentPage(items: pageOne, nextCursor: 'cursor-1');
        }
        return DocumentPage(
          items: [documentRead(id: 'id-25', title: '文档 25')],
          nextCursor: null,
        );
      };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    expect(repo.listCalls, hasLength(1));

    await tester.dragUntilVisible(
      find.text('文档 25'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(find.text('文档 25'), findsOneWidget);
    // The append used the opaque next_cursor — never a page-1 re-fetch.
    final last = repo.listCalls.last;
    expect(last.cursor, 'cursor-1');
    expect(last.tags, isEmpty);
    expect(repo.listCalls.length, greaterThanOrEqualTo(2));

    // End of list (next_cursor null) → hint, no error, no further fetch.
    final callsAfterEnd = repo.listCalls.length;
    await tester.dragUntilVisible(
      find.text('没有更多了'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('没有更多了'), findsOneWidget);
    expect(repo.listCalls.length, callsAfterEnd);
  });

  testWidgets('shows the error pane with Chinese copy and retries', (
    tester,
  ) async {
    final repo = StubDocumentsRepository()
      ..listHandler = (cursor, limit, tags) async => throw const ApiException(
        code: 'network_error',
        message: '网络连接异常，请检查网络后重试',
      );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('加载失败：网络连接异常，请检查网络后重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(repo.listCalls, hasLength(1));

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(repo.listCalls, hasLength(2));
  });

  testWidgets('tag filter multi-selects and ANDs tags server-side', (
    tester,
  ) async {
    final repo = StubDocumentsRepository()
      ..listHandler = (cursor, limit, tags) async => DocumentPage(
        items: [
          documentRead(id: 'a', title: '甲文档', tags: ['flutter']),
          documentRead(id: 'b', title: '乙文档', tags: ['dart']),
        ],
        nextCursor: null,
      );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    expect(repo.listCalls.single.tags, isEmpty);

    await tester.tap(find.text('flutter'));
    await tester.pumpAndSettle();

    final single = repo.listCalls.last;
    expect(single.cursor, isNull, reason: 'tag change must reset to page 1');
    expect(single.tags, ['flutter']);
    expect(find.text('文档 · flutter'), findsOneWidget);

    // A second tag joins the selection instead of replacing it.
    await tester.tap(find.text('dart'));
    await tester.pumpAndSettle();

    final filtered = repo.listCalls.last;
    expect(filtered.cursor, isNull, reason: 'tag change must reset to page 1');
    expect(filtered.tags, ['flutter', 'dart']);
    expect(find.text('文档 · flutter + dart'), findsOneWidget);

    // Tapping a selected tag toggles it back off.
    await tester.tap(find.text('flutter'));
    await tester.pumpAndSettle();
    expect(repo.listCalls.last.tags, ['dart']);

    // 全部 clears the multi-select again.
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(repo.listCalls.last.tags, isEmpty);
    expect(find.widgetWithText(AppBar, '文档'), findsOneWidget);
  });

  testWidgets('renders the empty state for an empty first page', (
    tester,
  ) async {
    final repo = StubDocumentsRepository()
      ..listHandler = (cursor, limit, tags) async =>
          const DocumentPage(items: [], nextCursor: null);

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('暂无文档'), findsOneWidget);
    expect(find.text('点击右下角按钮创建第一篇文档'), findsOneWidget);
  });

  group('two-pane (master-detail) wide layout', () {
    // 1400 window − extended rail ≈ 1143 content ≥ the two-pane threshold.
    Future<void> pumpWide(
      WidgetTester tester,
      StubDocumentsRepository repo,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, repo);
      await tester.pumpAndSettle();
    }

    StubDocumentsRepository repoWithDetail() {
      final repo = StubDocumentsRepository()
        ..listHandler = (cursor, limit, tags) async => DocumentPage(
          items: [documentRead(id: 'a', title: '甲文档')],
          nextCursor: null,
        );
      // Separate statement: a trailing `..getHandler` cascade would bind to
      // the DocumentPage inside the listHandler closure, not the repo.
      repo.getHandler = (id) async => documentReadDetail(
        documentRead(id: id, title: '甲文档'),
        content: '正文片段甲内容',
      );
      return repo;
    }

    testWidgets('selects in place: pane renders the detail without routing', (
      tester,
    ) async {
      final repo = repoWithDetail();
      await pumpWide(tester, repo);

      // Nothing selected yet — placeholder guides the first pick.
      expect(find.text('在左侧选择一个文档查看详情'), findsOneWidget);

      await tester.tap(find.text('甲文档'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentDetailPage), findsNothing);
      expect(find.text('正文片段甲内容'), findsOneWidget);
      expect(find.text('在左侧选择一个文档查看详情'), findsNothing);
      // The pane shares DocumentDetailBody: it carries its own floating AI
      // entry (collapsed) and no AI sections — still without any LLM call
      // on selection.
      expect(find.byType(AiAssistantFab), findsOneWidget);
      expect(find.text('AI 助手'), findsNothing);
      expect(find.text('使用右下角悬浮入口生成'), findsNothing);
      expect(repo.summarizeCalls, isEmpty);
      expect(repo.listAssociationsCalls, isEmpty);
      expect(repo.getCalls, ['a']);
    });

    testWidgets('the pane floating AI entry renders the summary inside its '
        'bubble without routing; back returns to the menu', (tester) async {
      final repo = repoWithDetail()
        ..summarizeHandler = (id) async => const SummaryResult(
          documentId: 'a',
          summary: '面板入口后的摘要',
          model: 'glm-4.7',
          latencyMs: 1200,
        );
      await pumpWide(tester, repo);

      await tester.tap(find.text('甲文档'));
      await tester.pumpAndSettle();

      // The floating entry lives inside the pane's own bounds; opening the
      // bubble and selecting 「AI 摘要」 switches to the content layer inside
      // the bubble — no route push, the pane stays.
      final fab = find.byType(AiAssistantFab);
      await tester.tap(
        find.descendant(of: fab, matching: find.byType(FloatingActionButton)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: fab, matching: find.text('AI 摘要')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(DocumentDetailPage), findsNothing);
      expect(find.byType(DocumentDetailPane), findsOneWidget);
      expect(repo.summarizeCalls, ['a']);
      expect(
        find.descendant(of: fab, matching: find.text('面板入口后的摘要')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fab, matching: find.text('glm-4.7 · 1.2 s')),
        findsOneWidget,
      );

      // Back affordance returns to the menu layer; the pane is untouched.
      await tester.tap(
        find.descendant(
          of: find.byType(AiAssistantFab),
          matching: find.byTooltip('返回'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: fab, matching: find.text('面板入口后的摘要')),
        findsNothing,
      );
      expect(
        find.descendant(of: fab, matching: find.text('AI 摘要')),
        findsOneWidget,
      );
      expect(find.byType(DocumentDetailPane), findsOneWidget);
      expect(find.text('正文片段甲内容'), findsOneWidget);
    });

    testWidgets('pane bubble: long association lists are height-bounded and '
        'scroll inside the bubble', (tester) async {
      final repo = repoWithDetail()
        ..listAssociationsHandler = (id) async => AssociationsResult(
          documentId: id,
          associations: [
            for (var i = 0; i < 60; i++)
              AssociationItem(
                documentId: 'rel-$i',
                title: '相关文档 $i',
                tags: const [],
                reason: '理由 $i。',
                signal: 'tag_overlap',
              ),
          ],
          model: 'glm-4.7',
          latencyMs: 900,
        );
      await pumpWide(tester, repo);

      await tester.tap(find.text('甲文档'));
      await tester.pumpAndSettle();

      final fab = find.byType(AiAssistantFab);
      await tester.tap(
        find.descendant(of: fab, matching: find.byType(FloatingActionButton)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: fab, matching: find.text('相关文档')));
      await tester.pump();
      await tester.pumpAndSettle();

      final viewport = find.descendant(
        of: fab,
        matching: find.byType(SingleChildScrollView),
      );
      expect(viewport, findsOneWidget);
      final bubbleCard = find.ancestor(
        of: viewport,
        matching: find.byType(Material),
      );

      // Same bounded-hosting contract as the full-page detail: the pane's
      // bubble never grows past the configured fraction of the surface and
      // stays on screen.
      const surfaceHeight = 800.0;
      final bubbleHeight = tester.getSize(bubbleCard.first).height;
      expect(bubbleHeight, lessThanOrEqualTo(surfaceHeight * 0.9));
      expect(bubbleHeight, greaterThan(surfaceHeight * 0.3));
      expect(tester.getTopLeft(bubbleCard.first).dy, greaterThanOrEqualTo(0));

      final position = tester
          .state<ScrollableState>(
            find.descendant(of: fab, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      // The last association is reachable, inside the bounded viewport.
      final viewportRect = tester.getRect(viewport);
      final lastTile = tester.getRect(
        find.descendant(of: fab, matching: find.text('相关文档 59')),
      );
      expect(lastTile.top, greaterThanOrEqualTo(viewportRect.top - 0.5));
      expect(lastTile.bottom, lessThanOrEqualTo(viewportRect.bottom + 0.5));
    });

    testWidgets('deleting from the pane returns to the placeholder', (
      tester,
    ) async {
      final repo = repoWithDetail()..deleteHandler = (id) async {};
      await pumpWide(tester, repo);

      await tester.tap(find.text('甲文档'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('删除'));
      await tester.pumpAndSettle();
      expect(find.text('删除文档'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pumpAndSettle();

      expect(repo.deleteCalls, ['a']);
      // The delete refreshed the list (keyset refetch) and the pane is gone.
      expect(repo.listCalls, hasLength(2));
      expect(find.text('在左侧选择一个文档查看详情'), findsOneWidget);
    });

    testWidgets('layout follows the breakpoint, selection survives', (
      tester,
    ) async {
      final repo = repoWithDetail();
      await pumpWide(tester, repo);

      await tester.tap(find.text('甲文档'));
      await tester.pumpAndSettle();
      expect(find.text('正文片段甲内容'), findsOneWidget);

      // Collapse to a single-column width: the pane unmounts (the detail
      // page still owns narrow navigation), the selection state persists.
      await tester.binding.setSurfaceSize(const Size(700, 800));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentDetailPane), findsNothing);
      expect(find.text('正文片段甲内容'), findsNothing);

      // Widen again — the same document is selected in the pane.
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentDetailPane), findsOneWidget);
      expect(find.text('正文片段甲内容'), findsOneWidget);
    });
  });
}
