import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/document_ai_pages.dart';
import 'package:knowledge_base_flutter/features/documents/document_detail_page.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/agents_result.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

import 'stub_documents_repository.dart';

/// Widget tests for the AI content pages (「AI 摘要」 / 「相关文档」, layer 2
/// of the assistant's two-layer routing): entry auto-generates exactly once
/// when uncached, cached results show without refetch, and back always lands
/// on the detail entry surface — including the direct deep-link case.
Future<void> pumpApp(
  WidgetTester tester,
  StubDocumentsRepository repo, {
  String initialLocation = '/documents',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
      retry: noAutomaticRetry,
      child: App(
        router: App.buildRouter(initialLocation: initialLocation),
      ),
    ),
  );
}

StubDocumentsRepository repoWithDoc(String content) {
  final base = documentRead(id: 'doc-1', title: '设计笔记');
  // Separate statements: a trailing cascade would bind to the expression
  // inside the listHandler closure (same hazard documents_page_test notes).
  final repo = StubDocumentsRepository();
  repo.listHandler =
      (cursor, limit, tags) async =>
          DocumentPage(items: [base], nextCursor: null);
  repo.getHandler = (id) async => documentReadDetail(base, content: content);
  return repo;
}

/// Deep-links straight to a detail page (from the list, where the title is
/// unambiguous) and opens [label]'s content page via the floating entry's
/// bubble (the touch path), settling afterwards.
Future<void> openContentPage(WidgetTester tester, String label) async {
  await openDetailFromList(tester);
  await selectFromBubble(tester, label);
}

/// Opens the detail page by tapping its list row.
Future<void> openDetailFromList(WidgetTester tester) async {
  await tester.tap(find.text('设计笔记'));
  await tester.pumpAndSettle();
}

/// Selects [label] in the floating entry's bubble from the current detail
/// surface (touch path), settling after the content page has mounted and
/// its entry auto-generate has resolved.
Future<void> selectFromBubble(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(AiAssistantFab),
    matching: find.byType(FloatingActionButton),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(
    of: find.byType(AiAssistantFab),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

/// The AppBar back affordance of a content page, scoped to that page so it
/// cannot match back buttons of pages stacked beneath it.
Finder pageBackButton(Type pageType) => find.descendant(
  of: find.byType(pageType),
  matching: find.byType(BackButton),
);

void main() {
  testWidgets('summary page auto-generates exactly once on entry and renders '
      'the result verbatim with the model/latency caption', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.summarizeHandler = (id) async {
      // If entry ever double-fired, both results would land here.
      return SummaryResult(
        documentId: id,
        summary: '这是原文摘要，保持原样。',
        model: 'glm-4.7',
        latencyMs: repo.summarizeCalls.length * 100.0,
      );
    };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, 'AI 摘要');

    expect(repo.summarizeCalls, ['doc-1']);
    expect(find.text('这是原文摘要，保持原样。'), findsOneWidget);
    expect(find.text('glm-4.7 · 100 ms'), findsOneWidget);
    expect(find.text('重新生成'), findsOneWidget);
  });

  testWidgets('a cached result shows without refetch on re-entry', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.summarizeHandler =
        (id) async => const SummaryResult(
          documentId: 'doc-1',
          summary: '已缓存的摘要',
          model: 'glm-4.7',
          latencyMs: 1500,
        );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, 'AI 摘要');
    expect(repo.summarizeCalls, hasLength(1));

    // Back to the entry surface…
    await tester.tap(pageBackButton(DocumentSummaryPage));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentDetailPage), findsOneWidget);

    // …and re-enter: the cached result renders as-is, no second fetch.
    await selectFromBubble(tester, 'AI 摘要');

    expect(repo.summarizeCalls, hasLength(1));
    expect(find.text('已缓存的摘要'), findsOneWidget);
  });

  testWidgets('重新生成 refetches and replaces the previous result', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.summarizeHandler = (id) async {
      if (repo.summarizeCalls.length == 1) {
        return const SummaryResult(
          documentId: 'doc-1',
          summary: '第一版摘要',
          model: 'glm-4.7',
          latencyMs: 1500,
        );
      }
      return const SummaryResult(
        documentId: 'doc-1',
        summary: '第二版摘要',
        model: 'glm-4.7',
        latencyMs: 480,
      );
    };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, 'AI 摘要');
    expect(find.text('第一版摘要'), findsOneWidget);
    expect(find.text('glm-4.7 · 1.5 s'), findsOneWidget);

    await tester.tap(find.text('重新生成'));
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(find.text('第二版摘要'), findsOneWidget);
    // Sub-second latency renders as whole milliseconds.
    expect(find.text('glm-4.7 · 480 ms'), findsOneWidget);
    expect(find.text('第一版摘要'), findsNothing);
  });

  testWidgets('AppBar back returns from the content page to the detail entry '
      'surface', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    repo.summarizeHandler =
        (id) async => const SummaryResult(
          documentId: 'doc-1',
          summary: '返回前的摘要',
          model: 'glm-4.7',
          latencyMs: 1500,
        );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, 'AI 摘要');
    expect(find.byType(DocumentSummaryPage), findsOneWidget);

    await tester.tap(pageBackButton(DocumentSummaryPage));
    await tester.pumpAndSettle();

    // The entry surface (full-page detail) is back on top.
    expect(find.byType(DocumentSummaryPage), findsNothing);
    expect(find.byType(DocumentDetailPage), findsOneWidget);
    expect(find.text('混合检索正文'), findsOneWidget);
  });

  testWidgets('direct deep link to the summary page auto-generates (explicit '
      'intent) and back still lands on the detail route', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    repo.summarizeHandler =
        (id) async => const SummaryResult(
          documentId: 'doc-1',
          summary: '深链进入后的摘要',
          model: 'glm-4.7',
          latencyMs: 1500,
        );

    await pumpApp(
      tester,
      repo,
      initialLocation: '/documents/doc-1/summary',
    );
    await tester.pumpAndSettle();

    // Deep link counts as explicit intent: exactly one auto-generate.
    expect(find.byType(DocumentSummaryPage), findsOneWidget);
    expect(repo.summarizeCalls, ['doc-1']);
    expect(find.text('深链进入后的摘要'), findsOneWidget);

    await tester.tap(pageBackButton(DocumentSummaryPage));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailPage), findsOneWidget);
    expect(find.text('混合检索正文'), findsOneWidget);
  });

  testWidgets('association items render title/tags/reason; tapping pushes '
      'that document detail', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.listAssociationsHandler = (id) async {
      return const AssociationsResult(
        documentId: 'doc-1',
        associations: [
          AssociationItem(
            documentId: 'doc-2',
            title: 'Riverpod 迁移笔记',
            tags: ['flutter', 'dart'],
            reason: '共享 Riverpod 迁移要点。',
            signal: 'tag_overlap',
          ),
        ],
        model: 'glm-4.7',
        latencyMs: 900,
      );
    };
    // The pushed detail of doc-2 resolves from the same stub; doc-1 (the
    // document under test) must keep resolving too.
    final docTwo = documentRead(id: 'doc-2', title: '关联文档');
    final fallbackGet = repo.getHandler;
    repo.getHandler = (id) async {
      if (id == 'doc-2') return documentReadDetail(docTwo, content: '正文二');
      return fallbackGet!(id);
    };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, '相关文档');

    expect(repo.listAssociationsCalls, ['doc-1']);
    expect(find.text('Riverpod 迁移笔记'), findsOneWidget);
    expect(find.text('#flutter'), findsOneWidget);
    expect(find.text('#dart'), findsOneWidget);
    expect(find.text('共享 Riverpod 迁移要点。'), findsOneWidget);

    // Tap the item → the document-detail route for doc-2.
    await tester.tap(find.text('Riverpod 迁移笔记'));
    await tester.pumpAndSettle();

    expect(repo.getCalls, contains('doc-2'));
    expect(find.byType(DocumentDetailPage), findsOneWidget);
    expect(find.text('正文二'), findsOneWidget);
  });

  testWidgets('empty association result shows 未找到相关文档', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.listAssociationsHandler = (id) async {
      return const AssociationsResult(
        documentId: 'doc-1',
        associations: [],
        model: 'glm-4.7',
        latencyMs: 900,
      );
    };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, '相关文档');

    expect(find.text('未找到相关文档'), findsOneWidget);
  });

  testWidgets('summary 503 chat_unavailable renders the friendly copy with an '
      'inline 重试 (no floating entry on this surface) and retry succeeds', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.summarizeHandler = (id) async {
      if (repo.summarizeCalls.length == 1) {
        throw const ApiException(
          code: 'chat_unavailable',
          message: 'No API key configured',
          statusCode: 503,
        );
      }
      return const SummaryResult(
        documentId: 'doc-1',
        summary: '重试后的摘要',
        model: 'glm-4.7',
        latencyMs: 1500,
      );
    };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, 'AI 摘要');

    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.textContaining('生成失败'), findsNothing);
    // Dead-end rule: this page has no floating AI entry, so the retry stays
    // one tap away right here.
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(find.text('重试后的摘要'), findsOneWidget);
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsNothing);
  });

  testWidgets('generic error shows 生成失败：{message} + inline 重试, which '
      'succeeds', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.summarizeHandler = (id) async {
      if (repo.summarizeCalls.length == 1) {
        throw const ApiException(
          code: 'llm_provider_error',
          message: 'upstream exploded',
          statusCode: 502,
        );
      }
      return const SummaryResult(
        documentId: 'doc-1',
        summary: '重试后的摘要',
        model: 'glm-4.7',
        latencyMs: 1500,
      );
    };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, 'AI 摘要');

    expect(find.text('生成失败：upstream exploded'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(find.text('重试后的摘要'), findsOneWidget);
    expect(find.text('生成失败：upstream exploded'), findsNothing);
  });

  testWidgets('associations: 503 chat_unavailable renders the friendly copy '
      'and retries inline to success', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.listAssociationsHandler = (id) async {
      if (repo.listAssociationsCalls.length == 1) {
        throw const ApiException(
          code: 'chat_unavailable',
          message: 'No API key configured',
          statusCode: 503,
        );
      }
      return const AssociationsResult(
        documentId: 'doc-1',
        associations: [
          AssociationItem(
            documentId: 'doc-2',
            title: '重试后的关联',
            tags: ['flutter'],
            reason: '重试成功后的关联。',
            signal: 'tag_overlap',
          ),
        ],
        model: 'glm-4.7',
        latencyMs: 900,
      );
    };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openContentPage(tester, '相关文档');

    expect(repo.listAssociationsCalls, hasLength(1));
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(repo.listAssociationsCalls, hasLength(2));
    expect(find.text('重试后的关联'), findsOneWidget);
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsNothing);
  });
}
