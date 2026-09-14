import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/document_ai_pages.dart';
import 'package:knowledge_base_flutter/features/documents/document_detail_page.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/agents_result.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

import 'stub_documents_repository.dart';

/// Widget tests for the floating AI entry (collapsed round button + expanded
/// bubble) of [DocumentDetailBody] (rendered by both the full page and the
/// two-pane pane). Selecting a bubble item navigates to the corresponding
/// content page ([DocumentSummaryPage] / [DocumentAssociationsPage]) — the
/// body itself carries no AI sections, and opening a document fires zero LLM
/// calls (generation lives entirely on the content pages).
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

/// A bubble entry ('AI 摘要' / '相关文档') scoped to the floating entry.
Finder bubbleEntry(String label) => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.text(label),
);

/// Opens the bubble with a tap (the touch path) and settles.
Future<void> openBubble(WidgetTester tester) async {
  await tester.tap(floatingButton());
  await tester.pumpAndSettle();
}

/// The full navigation trigger: opens the bubble and selects an entry, then
/// pumps past the route transition. The content page auto-generates on entry
/// (post-frame callback), so the generating state renders on the pushed page;
/// tests that await a completed result settle explicitly afterwards.
Future<void> navigateFromBubble(WidgetTester tester, String label) async {
  await openBubble(tester);
  await tester.tap(bubbleEntry(label));
  await tester.pump(); // selection closes the bubble, route push starts
  // Page mounts, post-frame callback fires the single auto-generate.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(); // generating row renders on the content page
}

void main() {
  testWidgets('opening the detail fires zero LLM calls; bubble collapsed, '
      'no AI sections in the body', (tester) async {
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
    // The bottom display sections are gone entirely (moved to the content
    // pages behind the bubble).
    expect(find.text('使用右下角悬浮入口生成'), findsNothing);
    expect(find.text('正在生成摘要…'), findsNothing);
    expect(find.text('正在生成关联…'), findsNothing);
    expect(find.byType(DocumentSummaryPage), findsNothing);
    expect(find.byType(DocumentAssociationsPage), findsNothing);
    // The markdown content is not blocked by the floating entry.
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

  testWidgets('selecting AI 摘要 closes the bubble, navigates to the summary '
      'content page and auto-generates exactly once there', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final pending = Completer<SummaryResult>();
    repo.summarizeHandler = (id) => pending.future;

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await navigateFromBubble(tester, 'AI 摘要');

    // Navigation, not in-place generation: the content page is on top and
    // it fired exactly one auto-generate. The bubble entries only exist
    // while the bubble is open, so their absence proves the selection
    // closed the bubble (「AI 助手」 itself reappears as the content card's
    // branding header, and the detail body's entry may still be in the
    // tree beneath the covering route during its transition).
    expect(bubbleEntry('AI 摘要'), findsNothing);
    expect(find.byType(DocumentSummaryPage), findsOneWidget);
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
    expect(find.text('重新生成'), findsOneWidget);
  });

  testWidgets('selecting 相关文档 navigates to the associations content page '
      'and auto-generates exactly once there', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final pending = Completer<AssociationsResult>();
    repo.listAssociationsHandler = (id) => pending.future;

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await navigateFromBubble(tester, '相关文档');

    expect(find.byType(DocumentAssociationsPage), findsOneWidget);
    expect(find.byType(DocumentSummaryPage), findsNothing);
    expect(repo.listAssociationsCalls, ['doc-1']);
    expect(find.text('正在生成关联…'), findsOneWidget);

    pending.complete(
      const AssociationsResult(
        documentId: 'doc-1',
        associations: [],
        model: 'glm-4.7',
        latencyMs: 900,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('未找到相关文档'), findsOneWidget);
  });
}
