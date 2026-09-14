import 'dart:async';

import 'package:flutter/gestures.dart';
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

/// Widget tests for the floating AI entry (collapsed round button + expanded
/// bubble) and the display-only 「AI 摘要」 / 「相关文档」 sections inside
/// [DocumentDetailBody] (rendered by both the full page and the two-pane
/// pane). The bubble is the only generation entry besides the inline
/// 重试 / 重新生成 affordances; opening a document fires zero LLM calls.
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

/// The collapsed round button of the floating AI entry (scoped to the entry
/// so it cannot hit the documents page's 新建文档 FAB below in the stack).
Finder floatingButton() => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.byType(FloatingActionButton),
);

/// A bubble entry ('AI 摘要' / '相关文档') scoped to the floating entry —
/// the same strings double as section titles below the markdown.
Finder bubbleEntry(String label) => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.text(label),
);

/// Opens the bubble with a tap (the touch path) and settles.
Future<void> openBubble(WidgetTester tester) async {
  await tester.tap(floatingButton());
  await tester.pumpAndSettle();
}

/// The full generation trigger: opens the bubble and selects an entry. Pumps
/// one frame afterwards — enough to close the bubble and render the
/// generating row; a full settle would hang on the in-flight spinner, so
/// tests that await a completed result settle explicitly afterwards.
Future<void> triggerFromBubble(WidgetTester tester, String label) async {
  await openBubble(tester);
  await tester.tap(bubbleEntry(label));
  await tester.pump();
}

void main() {
  testWidgets('opening the detail fires zero LLM calls; bubble collapsed, '
      'sections idle with hint rows', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    // Manual generation only — no summary/association fetch on open.
    expect(repo.summarizeCalls, isEmpty);
    expect(repo.listAssociationsCalls, isEmpty);
    // Collapsed by default: the round entry is visible, the bubble is not.
    expect(find.byType(AiAssistantFab), findsOneWidget);
    expect(floatingButton(), findsOneWidget);
    expect(find.text('AI 助手'), findsNothing);
    // Inline trigger buttons are gone; idle sections render the hint row.
    expect(find.text('生成摘要'), findsNothing);
    expect(find.text('生成关联'), findsNothing);
    expect(find.text('使用右下角悬浮入口生成'), findsNWidgets(2));
    // The markdown content is not blocked by the new UI.
    expect(find.text('混合检索正文'), findsOneWidget);
  });

  testWidgets('tapping the round button toggles the bubble open and closed '
      'with zero LLM calls', (tester) async {
    final repo = repoWithDoc('# 设计笔记');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.tap(floatingButton());
    await tester.pumpAndSettle();

    // Expanded: header, both entries and the dismiss affordance.
    expect(find.text('AI 助手'), findsOneWidget);
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    expect(bubbleEntry('相关文档'), findsOneWidget);
    expect(find.byIcon(Icons.close_outlined), findsOneWidget);
    expect(repo.summarizeCalls, isEmpty);
    expect(repo.listAssociationsCalls, isEmpty);

    // Second tap on the round button closes it again.
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();

    expect(find.text('AI 助手'), findsNothing);
    expect(bubbleEntry('AI 摘要'), findsNothing);
    expect(repo.summarizeCalls, isEmpty);
    expect(repo.listAssociationsCalls, isEmpty);
  });

  testWidgets('tapping outside the entry closes an open bubble', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await openBubble(tester);
    expect(find.text('AI 助手'), findsOneWidget);

    await tester.tap(find.text('混合检索正文'));
    await tester.pumpAndSettle();

    expect(find.text('AI 助手'), findsNothing);
    expect(repo.summarizeCalls, isEmpty);
  });

  testWidgets('hover opens the bubble; the pointer leaving dismisses it', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    await gesture.moveTo(tester.getCenter(floatingButton()));
    await tester.pumpAndSettle();

    // Hover opened the bubble (asserted via the entries: the round button's
    // tooltip also carries the 「AI 助手」 string while hovered).
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    expect(bubbleEntry('相关文档'), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();

    // Hover-summoned bubbles follow the pointer out.
    expect(bubbleEntry('AI 摘要'), findsNothing);
    expect(bubbleEntry('相关文档'), findsNothing);

    await gesture.removePointer();
    await tester.pumpAndSettle();
  });

  testWidgets('a tap-opened bubble survives a mouse pointer exit; a tap '
      'upgrades a hover-opened bubble instead of closing', (tester) async {
    final repo = repoWithDoc('# 设计笔记');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    // Hover-open first — on touch-web, compatibility mouse events (a
    // mouseenter) precede every tap, so this is the pre-tap state there.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(floatingButton()));
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);

    // The tap upgrades the hover-opened bubble to tap-owned instead of
    // closing it — otherwise the first tap could never open the entry.
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);

    // Now tap-owned: the mouse pointer leaving no longer dismisses it.
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);

    // A tap-owned bubble closes on the next tap.
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsNothing);

    await gesture.removePointer();
    await tester.pumpAndSettle();
  });

  testWidgets('the bubble dismiss affordance closes it', (tester) async {
    final repo = repoWithDoc('# 设计笔记');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await openBubble(tester);
    expect(find.text('AI 助手'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pumpAndSettle();

    expect(find.text('AI 助手'), findsNothing);
    expect(repo.summarizeCalls, isEmpty);
  });

  testWidgets('selecting AI 摘要 closes the bubble, fires exactly one call '
      'and shows the generating state', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final pending = Completer<SummaryResult>();
    repo.summarizeHandler = (id) => pending.future;

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await openBubble(tester);
    await tester.tap(bubbleEntry('AI 摘要'));
    await tester.pump(); // bubble closes + generating row renders

    expect(find.text('AI 助手'), findsNothing); // selection closes the bubble
    expect(repo.summarizeCalls, ['doc-1']); // exactly one generate call
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
    expect(find.text('重新生成'), findsOneWidget);
  });

  testWidgets('selecting an entry scrolls its section into view', (
    tester,
  ) async {
    final paragraphs = List.generate(
      30,
      (i) => '第$i段正文内容，用来把 AI 区块推到首屏之外。',
    ).join('\n\n');
    final repo = repoWithDoc('# 设计笔记\n\n$paragraphs');
    repo.summarizeHandler =
        (id) async => const SummaryResult(
          documentId: 'doc-1',
          summary: '滚动后摘要',
          model: 'glm-4.7',
          latencyMs: 1500,
        );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    // Before: the summary section header sits below the fold.
    final before = tester.getRect(find.text('AI 摘要'));
    expect(before.top, greaterThan(viewportHeight));

    await openBubble(tester);
    await tester.tap(bubbleEntry('AI 摘要'));
    await tester.pumpAndSettle();

    // After: the section was scrolled into the viewport (and the bubble
    // closed, so the section title is unambiguous again).
    final after = tester.getRect(find.text('AI 摘要'));
    expect(after.top, greaterThanOrEqualTo(0));
    expect(after.bottom, lessThanOrEqualTo(viewportHeight));
    expect(repo.summarizeCalls, ['doc-1']);
  });

  testWidgets('生成摘要 via the bubble: one call, then verbatim summary with '
      'model/latency caption', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final pending = Completer<SummaryResult>();
    repo.summarizeHandler = (id) => pending.future;

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await triggerFromBubble(tester, 'AI 摘要');
    expect(find.text('正在生成摘要…'), findsOneWidget);

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

    expect(find.text('这是原文摘要，保持原样。'), findsOneWidget);
    expect(find.text('glm-4.7 · 1.5 s'), findsOneWidget);
    expect(find.text('正在生成摘要…'), findsNothing);
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

    await triggerFromBubble(tester, 'AI 摘要');
    await tester.pumpAndSettle();
    expect(find.text('第一版摘要'), findsOneWidget);
    expect(find.text('glm-4.7 · 1.5 s'), findsOneWidget);

    // The inline 重新生成 stays as the regenerate affordance.
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

    await triggerFromBubble(tester, '相关文档');
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

    await triggerFromBubble(tester, '相关文档');
    await tester.pumpAndSettle();

    expect(find.text('未找到相关文档'), findsOneWidget);
  });

  testWidgets('summary 503 chat_unavailable renders the friendly copy with '
      'the floating entry as the standing retry', (tester) async {
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

    await triggerFromBubble(tester, 'AI 摘要');
    await tester.pumpAndSettle();

    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.textContaining('生成失败'), findsNothing);
    expect(find.text('重试'), findsNothing);
    // The failure leaves the section (and the page) usable, and the
    // always-visible floating entry is the standing retry affordance —
    // no dead end.
    expect(find.byType(AiAssistantFab), findsOneWidget);
    expect(find.text('混合检索正文'), findsOneWidget);
  });

  testWidgets('summary 503 failure can be retried through the floating '
      'entry and succeeds on the second select', (tester) async {
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

    await triggerFromBubble(tester, 'AI 摘要');
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(1));
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.text('重试'), findsNothing);

    await triggerFromBubble(tester, 'AI 摘要');
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
    await openDetail(tester);

    await triggerFromBubble(tester, 'AI 摘要');
    await tester.pumpAndSettle();

    expect(find.text('生成失败：upstream exploded'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(find.text('重试后的摘要'), findsOneWidget);
    expect(find.text('生成失败：upstream exploded'), findsNothing);
  });

  testWidgets('associations: 503 chat_unavailable renders the friendly copy '
      'with the floating entry as the standing retry', (tester) async {
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

    await triggerFromBubble(tester, '相关文档');
    await tester.pumpAndSettle();

    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    expect(find.byType(AiAssistantFab), findsOneWidget);
  });

  testWidgets('associations: 503 failure can be retried through the floating '
      'entry and succeeds on the second select', (tester) async {
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

    await triggerFromBubble(tester, '相关文档');
    await tester.pumpAndSettle();

    expect(repo.listAssociationsCalls, hasLength(1));
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.text('重试'), findsNothing);

    await triggerFromBubble(tester, '相关文档');
    await tester.pumpAndSettle();

    expect(repo.listAssociationsCalls, hasLength(2));
    expect(find.text('重试后的关联'), findsOneWidget);
    expect(find.text('重试成功后的关联。'), findsOneWidget);
    expect(find.text('AI 服务暂不可用，请稍后重试'), findsNothing);
  });
}
