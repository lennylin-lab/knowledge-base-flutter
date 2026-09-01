import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/features/search/search_providers.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

import '../documents/stub_documents_repository.dart';
import 'stub_search_repository.dart';

/// Pumps the full app (adaptive shell + real router) with the documents and
/// search repositories stubbed — no dio, no network. Compact surface so the
/// bottom NavigationBar shows all three destination labels.
Future<void> pumpSearchApp(
  WidgetTester tester, {
  required StubSearchRepository searchRepo,
  StubDocumentsRepository? documentsRepo,
}) async {
  final docsRepo =
      documentsRepo ??
      StubDocumentsRepository()
        ..listHandler =
            (cursor, limit, tag) async =>
                const DocumentPage(items: [], nextCursor: null);
  await tester.binding.setSurfaceSize(const Size(480, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(docsRepo),
        searchRepositoryProvider.overrideWithValue(searchRepo),
      ],
      retry: noAutomaticRetry,
      child: App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('搜索').last);
  await tester.pumpAndSettle();
}

/// Types into the search field and submits via the keyboard search action.
Future<void> submitQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the pre-search hint and fetches nothing', (tester) async {
    final repo = StubSearchRepository();

    await pumpSearchApp(tester, searchRepo: repo);

    expect(find.text('输入关键词开始搜索'), findsOneWidget);
    expect(repo.searchCalls, isEmpty);
  });

  testWidgets('submitting a query renders hit cards with snippet, tags, score',
      (tester) async {
    final repo =
        StubSearchRepository()
          ..searchHandler = (q, limit, tag) async => searchResponse(
            items: [
              searchHit(
                documentId: 'a',
                title: '混合检索笔记',
                esRank: 1,
                vectorRank: 3,
              ),
              searchHit(
                documentId: 'b',
                title: '向量检索入门',
                tags: ['rag', 'llm'],
                content: '向量检索在知识库中的实践与踩坑记录',
                score: 0.0123,
                esRank: null,
                vectorRank: 1,
              ),
            ],
          );

    await pumpSearchApp(tester, searchRepo: repo);
    await submitQuery(tester, 'flutter');

    expect(find.text('混合检索笔记'), findsOneWidget);
    expect(find.text('向量检索入门'), findsOneWidget);
    expect(find.textContaining('RRF 融合'), findsOneWidget);
    expect(find.text('#flutter'), findsOneWidget);
    expect(find.text('#rag'), findsOneWidget);
    expect(find.text('ES #1 · 向量 #3'), findsOneWidget);
    expect(find.text('得分 0.012'), findsOneWidget);
    expect(find.text('共 2 条结果 · 混合检索'), findsOneWidget);

    final call = repo.searchCalls.single;
    expect(call.q, 'flutter');
    expect(call.limit, 10);
    expect(call.tag, isNull);
  });

  testWidgets('shows a spinner while the search is in flight', (tester) async {
    final gate = Completer<SearchResponse>();
    final repo =
        StubSearchRepository()..searchHandler = (q, limit, tag) => gate.future;

    await pumpSearchApp(tester, searchRepo: repo);
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete(searchResponse());
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the Chinese error copy and retries', (tester) async {
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
            return searchResponse(
              items: [searchHit(documentId: 'a', title: '重试成功')],
            );
          };

    await pumpSearchApp(tester, searchRepo: repo);
    await submitQuery(tester, 'flutter');

    expect(find.text('搜索失败：网络连接异常，请检查网络后重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(find.text('重试成功'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('renders 无匹配结果 for an empty response', (tester) async {
    final repo =
        StubSearchRepository()
          ..searchHandler =
              (q, limit, tag) async => searchResponse(items: const []);

    await pumpSearchApp(tester, searchRepo: repo);
    await submitQuery(tester, 'flutter');

    expect(find.text('无匹配结果'), findsOneWidget);
  });

  testWidgets('selecting a tag chip re-runs the query server-side', (
    tester,
  ) async {
    final repo =
        StubSearchRepository()
          ..searchHandler = (q, limit, tag) async => searchResponse(
            items: [
              searchHit(documentId: 'a', title: '甲', tags: ['flutter', 'dart']),
            ],
          );

    await pumpSearchApp(tester, searchRepo: repo);
    await submitQuery(tester, 'flutter');
    expect(repo.searchCalls.last.tag, isNull);

    await tester.tap(find.widgetWithText(FilterChip, 'flutter'));
    await tester.pumpAndSettle();

    final filtered = repo.searchCalls.last;
    expect(filtered.q, 'flutter');
    expect(filtered.tag, 'flutter');

    // 全部 clears the filter again.
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(repo.searchCalls.last.tag, isNull);
  });

  testWidgets('tapping a hit opens the document detail page', (tester) async {
    final docsRepo =
        StubDocumentsRepository()
          ..getHandler =
              (id) async =>
                  documentReadDetail(documentRead(id: id, title: '知识库设计笔记'));
    final searchRepo =
        StubSearchRepository()
          ..searchHandler =
              (q, limit, tag) async => searchResponse(
                items: [searchHit(documentId: 'a', title: '知识库设计笔记')],
              );

    await pumpSearchApp(tester, searchRepo: searchRepo, documentsRepo: docsRepo);
    await submitQuery(tester, 'flutter');

    await tester.tap(find.text('知识库设计笔记'));
    await tester.pumpAndSettle();

    // Detail page AppBar + body headline both carry the title; the search
    // branch is offstage in the shell now (default finders skip it).
    expect(find.text('知识库设计笔记'), findsWidgets);
    expect(docsRepo.getCalls.single, 'a');
  });
}
