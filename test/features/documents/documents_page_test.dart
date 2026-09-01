import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
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
  testWidgets('renders rows with title/tags and the three index_status states', (
    tester,
  ) async {
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async => DocumentPage(
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
    // Bounded pumps instead of pumpAndSettle: the pending chip's spinner
    // animates indefinitely.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('待索引文档'), findsOneWidget);
    expect(find.text('索引失败文档'), findsOneWidget);
    expect(find.text('正常文档'), findsOneWidget);
    // pending → spinner + 索引中; failed → error chip; done → nothing.
    expect(find.text('索引中'), findsOneWidget);
    expect(find.text('索引失败'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('loads the next keyset page when scrolled near the end', (
    tester,
  ) async {
    final pageOne = List.generate(
      25,
      (i) => documentRead(id: 'id-$i', title: '文档 $i'),
    );
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async {
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
    expect(last.tag, isNull);
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
    final repo =
        StubDocumentsRepository()
          ..listHandler =
              (cursor, limit, tag) async => throw const ApiException(
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

  testWidgets('tag filter resets to page 1 with the server-side tag param', (
    tester,
  ) async {
    final repo =
        StubDocumentsRepository()
          ..listHandler = (cursor, limit, tag) async => DocumentPage(
            items: [
              documentRead(id: 'a', title: '甲文档', tags: ['flutter']),
              documentRead(id: 'b', title: '乙文档', tags: ['dart']),
            ],
            nextCursor: null,
          );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    expect(repo.listCalls.single.tag, isNull);

    await tester.tap(find.text('flutter'));
    await tester.pumpAndSettle();

    final filtered = repo.listCalls.last;
    expect(filtered.cursor, isNull, reason: 'tag change must reset to page 1');
    expect(filtered.tag, 'flutter');
    expect(find.text('文档 · flutter'), findsOneWidget);

    // 全部 clears the filter again.
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(repo.listCalls.last.tag, isNull);
  });

  testWidgets('renders the empty state for an empty first page', (
    tester,
  ) async {
    final repo =
        StubDocumentsRepository()
          ..listHandler =
              (cursor, limit, tag) async =>
                  const DocumentPage(items: [], nextCursor: null);

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('暂无文档'), findsOneWidget);
    expect(find.text('点击右下角按钮创建第一篇文档'), findsOneWidget);
  });
}
