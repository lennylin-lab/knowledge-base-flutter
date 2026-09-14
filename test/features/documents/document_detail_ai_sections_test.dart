import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/agents_result.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

import 'stub_documents_repository.dart';

/// Widget tests for the on-demand 「AI 摘要」 / 「相关文档」 sections inside
/// [DocumentDetailBody] (rendered by both the full page and the two-pane
/// pane). Generation is manual: opening a document fires zero LLM calls.
Future<void> pumpApp(WidgetTester tester, StubDocumentsRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
      retry: noAutomaticRetry,
      child: App(),
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

Future<void> openDetail(WidgetTester tester) async {
  await tester.tap(find.text('设计笔记'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opening the detail fires zero LLM calls and shows both sections', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    // Manual generation only — no summary/association fetch on open.
    expect(repo.summarizeCalls, isEmpty);
    expect(repo.listAssociationsCalls, isEmpty);
    expect(find.text('生成摘要'), findsOneWidget);
    expect(find.text('生成关联'), findsOneWidget);
    // The markdown content is not blocked by the new sections.
    expect(find.text('混合检索正文'), findsOneWidget);
  });

  testWidgets('生成摘要: exactly one call, loading copy, then verbatim summary '
      'with model/latency caption', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final pending = Completer<SummaryResult>();
    repo.summarizeHandler = (id) => pending.future;

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(find.text('生成摘要'));
    await tester.pump(); // loading frame

    expect(repo.summarizeCalls, ['doc-1']);
    expect(find.text('正在生成摘要…'), findsOneWidget);
    expect(find.text('同步生成可能需要数秒'), findsOneWidget);

    // Bounded pumps: the spinner animates until the result lands.
    pending.complete(
      const SummaryResult(
        documentId: 'doc-1',
        summary: '这是原文摘要，保持原样。',
        model: 'glm-4.7',
        latencyMs: 1500,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    // Verbatim answer text, never translated or trimmed.
    expect(find.text('这是原文摘要，保持原样。'), findsOneWidget);
    expect(find.text('glm-4.7 · 1.5 s'), findsOneWidget);
    expect(find.text('正在生成摘要…'), findsNothing);
    expect(find.text('生成摘要'), findsNothing);
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
    await openDetail(tester);

    await tester.tap(find.text('生成摘要'));
    await tester.pumpAndSettle();
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

  testWidgets('association items render title/tags/reason; tapping pushes '
      'that document', (tester) async {
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
    // document under test) must keep resolving too, or the sections under
    // test never render.
    final docTwo = documentRead(id: 'doc-2', title: '关联文档');
    repo.getHandler = (id) async {
      if (id == 'doc-2') return documentReadDetail(docTwo, content: '正文二');
      if (id == 'doc-1') {
        return documentReadDetail(
          documentRead(id: 'doc-1', title: '设计笔记'),
          content: '# 设计笔记',
        );
      }
      throw StateError('unexpected get: $id');
    };

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(find.text('生成关联'));
    await tester.pumpAndSettle();

    expect(repo.listAssociationsCalls, ['doc-1']);
    expect(find.text('Riverpod 迁移笔记'), findsOneWidget);
    expect(find.text('#flutter'), findsOneWidget);
    expect(find.text('#dart'), findsOneWidget);
    expect(find.text('共享 Riverpod 迁移要点。'), findsOneWidget);

    // Tap the item → the document-detail route for doc-2.
    await tester.tap(find.text('Riverpod 迁移笔记'));
    await tester.pumpAndSettle();

    expect(repo.getCalls, contains('doc-2'));
    expect(find.text('关联文档'), findsWidgets);
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
    await openDetail(tester);

    await tester.tap(find.text('生成关联'));
    await tester.pumpAndSettle();

    expect(find.text('未找到相关文档'), findsOneWidget);
  });

  testWidgets('503 chat_unavailable renders the friendly copy without 重试', (
    tester,
  ) async {
    // Content fixture carries body text so the assertion below can prove the
    // markdown survived the failure.
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    repo.summarizeHandler =
        (id) async => throw const ApiException(
          code: 'chat_unavailable',
          message: 'No API key configured',
          statusCode: 503,
        );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(find.text('生成摘要'));
    await tester.pumpAndSettle();

    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.textContaining('生成失败'), findsNothing);
    expect(find.text('重试'), findsNothing);
    // The failure leaves the section (and the page) usable.
    expect(find.text('混合检索正文'), findsOneWidget);
  });

  testWidgets('summary 503 failure keeps 生成摘要 visible as the in-place '
      'retry, which succeeds on the second tap', (tester) async {
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
    await openDetail(tester);

    await tester.tap(find.text('生成摘要'));
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(1));
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    // The trigger stays available next to the friendly copy — no dead end.
    expect(find.text('生成摘要'), findsOneWidget);
    expect(find.text('重试'), findsNothing);

    await tester.tap(find.text('生成摘要'));
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(find.text('重试后的摘要'), findsOneWidget);
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsNothing);
  });

  testWidgets('generic error shows 生成失败：{message} + 重试, which succeeds', (
    tester,
  ) async {
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
    await openDetail(tester);

    await tester.tap(find.text('生成摘要'));
    await tester.pumpAndSettle();

    expect(find.text('生成失败：upstream exploded'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(find.text('重试后的摘要'), findsOneWidget);
    expect(find.text('生成失败：upstream exploded'), findsNothing);
  });

  testWidgets('associations: 503 chat_unavailable renders the friendly copy', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.listAssociationsHandler =
        (id) async => throw const ApiException(
          code: 'chat_unavailable',
          message: 'No API key configured',
          statusCode: 503,
        );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(find.text('生成关联'));
    await tester.pumpAndSettle();

    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
  });

  testWidgets('associations: 503 failure keeps 生成关联 visible as the '
      'in-place retry, which succeeds on the second tap', (tester) async {
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
    await openDetail(tester);

    await tester.tap(find.text('生成关联'));
    await tester.pumpAndSettle();

    expect(repo.listAssociationsCalls, hasLength(1));
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    // The trigger stays available next to the friendly copy — no dead end.
    expect(find.text('生成关联'), findsOneWidget);

    await tester.tap(find.text('生成关联'));
    await tester.pumpAndSettle();

    expect(repo.listAssociationsCalls, hasLength(2));
    expect(find.text('重试后的关联'), findsOneWidget);
    expect(find.text('重试成功后的关联。'), findsOneWidget);
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsNothing);
  });
}
