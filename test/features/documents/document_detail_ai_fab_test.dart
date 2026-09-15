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
import 'package:knowledge_base_flutter/shared/models/agents_stream.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

import 'stub_documents_repository.dart';

/// Widget tests for the floating AI entry (collapsed round button + expanded
/// bubble) of [DocumentDetailBody] (rendered by both the full page and the
/// two-pane pane). The bubble carries two in-widget layers — menu ↔ content
/// — and there are no AI routes: all content renders inside the bubble.
/// Opening a document fires zero LLM calls; generation starts only on an
/// explicit menu-entry click, exactly once when uncached.
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
  repo.listHandler = (cursor, limit, tags) async =>
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

/// A menu entry label ('AI 摘要' / '相关文档') scoped to the floating entry.
/// Note: the content layer's header reuses the function title, so content
/// assertions should match result/copy texts instead.
Finder bubbleEntry(String label) => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.text(label),
);

/// Text inside the floating entry's bubble (scoped assertions for content-
/// layer states — everything AI now renders inside the bubble).
Finder bubbleText(String text) =>
    find.descendant(of: find.byType(AiAssistantFab), matching: find.text(text));

/// Text containing [containing] inside the floating entry's bubble.
Finder bubbleTextContaining(String containing) => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.textContaining(containing),
);

/// The content layer's back affordance (返回), scoped to the entry.
Finder bubbleBackButton() => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.byTooltip('返回'),
);

/// Opens the bubble with a tap (the touch path) and settles.
Future<void> openBubble(WidgetTester tester) async {
  await tester.tap(floatingButton());
  await tester.pumpAndSettle();
}

/// Selects a menu entry (touch path): switches to the content layer and
/// fires the single generate. Bounded pumps — the in-flight spinner animates
/// indefinitely; tests settle only after a real result/error has landed.
Future<void> selectEntry(WidgetTester tester, String label) async {
  await tester.tap(bubbleEntry(label));
  await tester.pump(); // layer switch renders
  await tester.pump(); // generation state (or its immediate result) renders
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
    expect(find.text('使用右下角悬浮入口生成'), findsNothing);
    expect(find.text('正在生成摘要…'), findsNothing);
    expect(find.text('正在生成关联…'), findsNothing);
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

  testWidgets('tapping outside the entry closes an open bubble', (
    tester,
  ) async {
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
      'upgrades a hover-opened bubble instead of closing (touch-web pin)', (
    tester,
  ) async {
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

  testWidgets('entry click shows the content layer inside the bubble (no '
      'route push) and generates exactly once', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    final pending = Completer<SummaryResult>();
    repo.summarizeHandler = (id) => pending.future;

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);

    await selectEntry(tester, 'AI 摘要');

    // In-bubble content layer, not a route: the detail page is still on top
    // and the generating state renders inside the floating entry.
    expect(find.byType(DocumentDetailPage), findsOneWidget);
    expect(find.text('混合检索正文'), findsOneWidget);
    expect(bubbleText('正在生成摘要…'), findsOneWidget);
    expect(bubbleText('同步生成可能需要数秒'), findsOneWidget);
    expect(repo.summarizeCalls, ['doc-1']);
    // The back affordance of the content layer is showing.
    expect(bubbleBackButton(), findsOneWidget);

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

    // Verbatim answer text (through the shared MarkdownContent pipeline),
    // never translated or trimmed.
    expect(bubbleTextContaining('这是原文摘要，保持原样。'), findsOneWidget);
    expect(bubbleText('glm-4.7 · 1.5 s'), findsOneWidget);
    expect(bubbleText('正在生成摘要…'), findsNothing);
    expect(find.text('重新生成'), findsOneWidget);
  });

  testWidgets('back affordance returns to the menu layer; re-entering shows '
      'the cached result without refetch', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.summarizeHandler = (id) async => const SummaryResult(
      documentId: 'doc-1',
      summary: '已缓存的摘要',
      model: 'glm-4.7',
      latencyMs: 1500,
    );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);

    await selectEntry(tester, 'AI 摘要');
    expect(repo.summarizeCalls, hasLength(1));
    expect(bubbleTextContaining('已缓存的摘要'), findsOneWidget);

    // Back to the menu layer — the content is gone, the entries are back.
    await tester.tap(bubbleBackButton());
    await tester.pumpAndSettle();
    expect(bubbleTextContaining('已缓存的摘要'), findsNothing);
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    expect(bubbleEntry('相关文档'), findsOneWidget);

    // Re-enter: the cached result renders as-is, no second fetch.
    await selectEntry(tester, 'AI 摘要');

    expect(repo.summarizeCalls, hasLength(1));
    expect(bubbleTextContaining('已缓存的摘要'), findsOneWidget);

    // 返回 is the menu-layer reset — and keep-alive preserves the menu
    // layer exactly like a content layer: back to the menu, dismiss,
    // reopen — still the menu.
    await tester.tap(bubbleBackButton());
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    expect(bubbleEntry('相关文档'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pumpAndSettle();
    await openBubble(tester);
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    expect(bubbleEntry('相关文档'), findsOneWidget);
    expect(bubbleTextContaining('已缓存的摘要'), findsNothing);
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
    await openBubble(tester);

    await selectEntry(tester, 'AI 摘要');
    expect(bubbleTextContaining('第一版摘要'), findsOneWidget);
    expect(bubbleText('glm-4.7 · 1.5 s'), findsOneWidget);

    await tester.tap(find.text('重新生成'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(bubbleTextContaining('第二版摘要'), findsOneWidget);
    // Sub-second latency renders as whole milliseconds.
    expect(bubbleText('glm-4.7 · 480 ms'), findsOneWidget);
    expect(bubbleTextContaining('第一版摘要'), findsNothing);
  });

  testWidgets('dismiss (收起) keeps the layer alive: reopening shows the same '
      'content layer with the cached result and zero new calls', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    repo.summarizeHandler = (id) async => const SummaryResult(
      documentId: 'doc-1',
      summary: '收起前后都在的摘要',
      model: 'glm-4.7',
      latencyMs: 1500,
    );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await openBubble(tester);
    await selectEntry(tester, 'AI 摘要');
    expect(bubbleTextContaining('收起前后都在的摘要'), findsOneWidget);
    expect(repo.summarizeCalls, ['doc-1']);

    // 收起 visually dismisses the bubble…
    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pumpAndSettle();
    expect(find.text('AI 摘要'), findsNothing);
    expect(bubbleTextContaining('收起前后都在的摘要'), findsNothing);
    // …but the card stays mounted offstage (keep-alive): the content layer
    // — and with it the scroll position — survives the dismiss.
    expect(find.text('AI 摘要', skipOffstage: false), findsOneWidget);
    expect(
      find.textContaining('收起前后都在的摘要', skipOffstage: false),
      findsOneWidget,
    );

    // Reopening lands directly back on the content layer: cached result as
    // it was, no refetch, no menu detour.
    await openBubble(tester);
    expect(bubbleTextContaining('收起前后都在的摘要'), findsOneWidget);
    expect(bubbleBackButton(), findsOneWidget);
    expect(bubbleText('生成这篇文档的内容摘要'), findsNothing);
    expect(repo.summarizeCalls, ['doc-1']);
  });

  testWidgets('every dismiss path keeps the content layer across reopen '
      '(toggle / outside tap / hover exit)', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    repo.summarizeHandler = (id) async => const SummaryResult(
      documentId: 'doc-1',
      summary: '路径无关的缓存摘要',
      model: 'glm-4.7',
      latencyMs: 1500,
    );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    // Same content layer after each reopen, and still exactly one call.
    Future<void> expectContentLayerKept() async {
      expect(bubbleTextContaining('路径无关的缓存摘要'), findsOneWidget);
      expect(bubbleBackButton(), findsOneWidget);
      expect(bubbleText('生成这篇文档的内容摘要'), findsNothing);
      expect(repo.summarizeCalls, hasLength(1));
    }

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    // Set up the shared keep-alive state: content layer, result cached.
    await openBubble(tester);
    await selectEntry(tester, 'AI 摘要');
    await expectContentLayerKept();

    // Path 1 — round-button toggle.
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();
    expect(find.text('AI 摘要'), findsNothing);
    await openBubble(tester);
    await expectContentLayerKept();

    // Path 2 — tap outside the entry.
    await tester.tap(find.text('混合检索正文'));
    await tester.pumpAndSettle();
    expect(find.text('AI 摘要'), findsNothing);
    await openBubble(tester);
    await expectContentLayerKept();

    // Path 3 — a hover-opened bubble follows the pointer out. A tap-owned
    // bubble ignores pointer exits, so park it closed first (toggle).
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();
    await gesture.moveTo(tester.getCenter(floatingButton()));
    await tester.pumpAndSettle();
    // Hover summoned the bubble straight onto the preserved layer.
    await expectContentLayerKept();
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('AI 摘要'), findsNothing);
    await openBubble(tester);
    await expectContentLayerKept();

    await gesture.removePointer();
    await tester.pumpAndSettle();
  });

  testWidgets('scroll position survives dismiss: reopen restores the content '
      'offset', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = repoWithDoc('# 设计笔记');
    // Tall enough that the internal scroll is clearly engaged.
    final summary = List.generate(120, (i) => '摘要段落 $i。').join('\n\n');
    repo.summarizeHandler = (id) async => SummaryResult(
      documentId: id,
      summary: summary,
      model: 'glm-4.7',
      latencyMs: 900,
    );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await selectEntry(tester, 'AI 摘要');

    // Scroll the summary to the end. The position is resolved from a direct
    // child of the content layer (the 重新生成 action): every markdown
    // paragraph carries its own internal EditableText Scrollable, so a
    // fab-wide Scrollable lookup would be ambiguous (see the height-bound
    // regression test below).
    final position = Scrollable.of(
      tester.element(find.text('重新生成')),
      axis: Axis.vertical,
    ).position;
    expect(position.maxScrollExtent, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final scrolledTo = position.pixels;
    expect(scrolledTo, greaterThan(0));

    // Dismiss (toggle: the bubble is tap-owned)…
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();
    expect(find.text('重新生成'), findsNothing);

    // …reopen: the same offset is still in place.
    await openBubble(tester);
    expect(bubbleTextContaining('摘要段落 0'), findsOneWidget);
    final restored = Scrollable.of(
      tester.element(find.text('重新生成')),
      axis: Axis.vertical,
    ).position;
    expect(restored.pixels, scrolledTo);
    expect(restored.maxScrollExtent, greaterThan(0));
  });

  testWidgets('in-flight generation survives dismiss: reopen shows live '
      'progress without a second call', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final pending = Completer<SummaryResult>();
    repo.summarizeHandler = (id) => pending.future;

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);

    await selectEntry(tester, 'AI 摘要');
    expect(bubbleText('正在生成摘要…'), findsOneWidget);
    expect(repo.summarizeCalls, ['doc-1']);

    // Dismiss mid-generation — bounded pumps: the spinner keeps animating
    // in the offstage card, so pumpAndSettle would never settle.
    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pump();
    await tester.pump();
    expect(find.text('正在生成摘要…'), findsNothing);

    // Reopen: the same generation is still running and its live progress
    // shows; reopening never re-triggers, so still exactly one call.
    await tester.tap(floatingButton());
    await tester.pump();
    await tester.pump();
    expect(bubbleText('正在生成摘要…'), findsOneWidget);
    expect(repo.summarizeCalls, ['doc-1']);

    pending.complete(
      const SummaryResult(
        documentId: 'doc-1',
        summary: '收起期间完成的摘要',
        model: 'glm-4.7',
        latencyMs: 1500,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(bubbleTextContaining('收起期间完成的摘要'), findsOneWidget);
    expect(repo.summarizeCalls, ['doc-1']);
  });

  testWidgets('system back at the content layer returns to the menu layer; '
      'the page stays (PopScope)', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    repo.summarizeHandler = (id) async => const SummaryResult(
      documentId: 'doc-1',
      summary: '返回前的摘要',
      model: 'glm-4.7',
      latencyMs: 1500,
    );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await openBubble(tester);
    await selectEntry(tester, 'AI 摘要');
    expect(bubbleTextContaining('返回前的摘要'), findsOneWidget);

    // System/browser back: the content layer consumes it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Back at the menu layer, still on the detail page.
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    expect(bubbleTextContaining('返回前的摘要'), findsNothing);
    expect(find.byType(DocumentDetailPage), findsOneWidget);
    expect(find.text('混合检索正文'), findsOneWidget);

    // A second system back now pops the page (menu layer = normal back).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DocumentDetailPage), findsNothing);
    expect(find.text('混合检索正文'), findsNothing);
  });

  testWidgets('system back with the bubble closed pops the page as before', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Unchanged behavior: the detail page pops back to the list.
    expect(find.byType(DocumentDetailPage), findsNothing);
    expect(find.text('设计笔记'), findsOneWidget);
  });

  testWidgets('system back with the bubble closed on a content layer still '
      'pops the page (keep-alive must not consume back)', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    repo.summarizeHandler = (id) async => const SummaryResult(
      documentId: 'doc-1',
      summary: '停在内容层的摘要',
      model: 'glm-4.7',
      latencyMs: 1500,
    );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);

    await openBubble(tester);
    await selectEntry(tester, 'AI 摘要');
    expect(bubbleTextContaining('停在内容层的摘要'), findsOneWidget);

    // 收起 parks the bubble closed on the content layer (keep-alive)…
    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pumpAndSettle();
    expect(bubbleTextContaining('停在内容层的摘要'), findsNothing);

    // …closed means unchanged: system back pops the page — the hidden
    // layer must not consume it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailPage), findsNothing);
    expect(find.text('设计笔记'), findsOneWidget);
  });

  testWidgets('association items render title/tags/reason; tapping one pushes '
      'that document detail and closes the bubble', (tester) async {
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
    await openDetail(tester);
    await openBubble(tester);

    await selectEntry(tester, '相关文档');

    expect(repo.listAssociationsCalls, ['doc-1']);
    expect(bubbleText('Riverpod 迁移笔记'), findsOneWidget);
    expect(bubbleText('#flutter'), findsOneWidget);
    expect(bubbleText('#dart'), findsOneWidget);
    expect(bubbleText('共享 Riverpod 迁移要点。'), findsOneWidget);

    // Tap the item → the document-detail route for doc-2, bubble closed.
    await tester.tap(bubbleText('Riverpod 迁移笔记'));
    await tester.pumpAndSettle();

    expect(repo.getCalls, contains('doc-2'));
    expect(find.byType(DocumentDetailPage), findsOneWidget);
    expect(find.text('正文二'), findsOneWidget);
    expect(bubbleText('共享 Riverpod 迁移要点。'), findsNothing);
    // doc-2's own floating entry is present, collapsed again.
    expect(find.byType(AiAssistantFab), findsOneWidget);
    expect(floatingButton(), findsOneWidget);
  });

  testWidgets('empty association result shows 未找到相关文档 inside the bubble', (
    tester,
  ) async {
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
    await openBubble(tester);

    await selectEntry(tester, '相关文档');

    expect(bubbleText('未找到相关文档'), findsOneWidget);
  });

  testWidgets('long content: the bubble is height-bounded by the surface and '
      'the content scrolls inside it', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = repoWithDoc('# 设计笔记');
    // Far more text than any bubble can show at once — the unbounded-
    // constraints regression rendered this ~16000px tall, overflowing the
    // surface upward.
    final summary = List.generate(120, (i) => '摘要段落 $i。').join('\n\n');
    repo.summarizeHandler = (id) async => SummaryResult(
      documentId: id,
      summary: summary,
      model: 'glm-4.7',
      latencyMs: 900,
    );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await selectEntry(tester, 'AI 摘要');

    final viewport = find.descendant(
      of: find.byType(AiAssistantFab),
      matching: find.byType(SingleChildScrollView),
    );
    expect(viewport, findsOneWidget);
    // The bubble card is the scroll view's Material ancestor.
    final bubbleCard = find.ancestor(
      of: viewport,
      matching: find.byType(Material),
    );

    // Bounded: tall enough that the cap is clearly engaged, but never
    // taller than the configured fraction of the surface — and its top
    // edge stays on screen.
    const surfaceHeight = 900.0;
    final bubbleHeight = tester.getSize(bubbleCard.first).height;
    expect(bubbleHeight, lessThanOrEqualTo(surfaceHeight * 0.9));
    expect(bubbleHeight, greaterThan(surfaceHeight * 0.4));
    expect(tester.getTopLeft(bubbleCard.first).dy, greaterThanOrEqualTo(0));

    final viewportRect = tester.getRect(viewport);
    // Markdown renders one paragraph widget per stub line; the first pins
    // the content top, the last its tail.
    final firstRect = tester.getRect(bubbleTextContaining('摘要段落 0'));
    // First content starts inside the viewport…
    expect(firstRect.top, greaterThanOrEqualTo(viewportRect.top - 0.5));

    // …and the rest is reachable by internal scrolling. The position is
    // resolved from a direct child of the content layer (the 重新生成
    // action): every markdown paragraph carries its own internal
    // EditableText Scrollable, so a fab-wide Scrollable lookup would be
    // ambiguous.
    final position = Scrollable.of(
      tester.element(find.text('重新生成')),
      axis: Axis.vertical,
    ).position;
    expect(position.maxScrollExtent, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    // Scrolled to the end: the content has moved up and its tail (the last
    // paragraph) is inside the viewport.
    expect(
      tester.getRect(bubbleTextContaining('摘要段落 0')).top,
      lessThan(firstRect.top),
    );
    final lastRect = tester.getRect(bubbleTextContaining('摘要段落 119'));
    expect(
      lastRect.bottom,
      lessThanOrEqualTo(tester.getRect(viewport).bottom + 0.5),
    );
  });

  testWidgets('summary generating row shows the streamed progress copy '
      '(map_pass → reduce_pass), cleared once the result lands', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    final pending = Completer<SummaryResult>();
    final reports = <void Function(SummaryProgress)>[];
    repo.summarizeHandler = (id) => pending.future;
    repo.summarizeProgressHandler = (id, report) => reports.add(report);

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);

    await selectEntry(tester, 'AI 摘要');

    // Before the first progress event the generic hint shows.
    expect(bubbleText('正在生成摘要…'), findsOneWidget);

    // map_pass progress → live copy with the 1-based pass counter.
    reports.single(
      const SummaryProgress(phase: 'map_pass', passIndex: 1, passesTotal: 3),
    );
    await tester.pump();
    expect(bubbleText('正在阅读第 1/3 段'), findsOneWidget);
    expect(bubbleText('正在生成摘要…'), findsNothing);

    // Later progress replaces the line (latest event wins).
    reports.single(
      const SummaryProgress(phase: 'map_pass', passIndex: 2, passesTotal: 3),
    );
    await tester.pump();
    expect(bubbleText('正在阅读第 2/3 段'), findsOneWidget);
    expect(bubbleText('正在阅读第 1/3 段'), findsNothing);

    reports.single(
      const SummaryProgress(phase: 'reduce_pass', passIndex: 3, passesTotal: 3),
    );
    await tester.pump();
    expect(bubbleText('正在汇总要点'), findsOneWidget);
    // The generic "takes seconds" hint stays alongside the progress line.
    expect(bubbleText('同步生成可能需要数秒'), findsOneWidget);

    pending.complete(
      const SummaryResult(
        documentId: 'doc-1',
        summary: '流式进度后的摘要',
        model: 'glm-4.7',
        latencyMs: 1500,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(bubbleTextContaining('流式进度后的摘要'), findsOneWidget);
    expect(bubbleText('正在汇总要点'), findsNothing);
    expect(bubbleText('同步生成可能需要数秒'), findsNothing);
  });

  testWidgets('associations generation keeps the generic spinner hint (no '
      'progress copy)', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final pending = Completer<AssociationsResult>();
    repo.listAssociationsHandler = (id) => pending.future;

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);

    await selectEntry(tester, '相关文档');

    expect(bubbleText('正在生成关联…'), findsOneWidget);
    expect(bubbleTextContaining('正在阅读'), findsNothing);
    expect(bubbleTextContaining('正在汇总'), findsNothing);

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
    expect(bubbleText('未找到相关文档'), findsOneWidget);
  });

  testWidgets('summary 503 chat_unavailable renders the friendly copy with an '
      'inline 重试 and retry succeeds', (tester) async {
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
    await openBubble(tester);

    await selectEntry(tester, 'AI 摘要');

    expect(bubbleText('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(bubbleTextContaining('生成失败'), findsNothing);
    // Dead-end rule: the retry stays one tap away right here.
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(bubbleTextContaining('重试后的摘要'), findsOneWidget);
    expect(bubbleText('AI 服务暂不可用，请稍后重试'), findsNothing);
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
    await openBubble(tester);

    await selectEntry(tester, 'AI 摘要');

    expect(bubbleText('生成失败：upstream exploded'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.summarizeCalls, hasLength(2));
    expect(bubbleTextContaining('重试后的摘要'), findsOneWidget);
    expect(bubbleText('生成失败：upstream exploded'), findsNothing);
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
    await openDetail(tester);
    await openBubble(tester);

    await selectEntry(tester, '相关文档');

    expect(repo.listAssociationsCalls, hasLength(1));
    expect(bubbleText('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.listAssociationsCalls, hasLength(2));
    expect(bubbleText('重试后的关联'), findsOneWidget);
    expect(bubbleText('AI 服务暂不可用，请稍后重试'), findsNothing);
  });

  testWidgets('document switch (pane selection) closes the bubble and resets '
      'it to the menu layer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final baseA = documentRead(id: 'doc-a', title: '甲文档');
    final baseB = documentRead(id: 'doc-b', title: '乙文档');
    final repo = StubDocumentsRepository();
    repo.listHandler = (cursor, limit, tags) async =>
        DocumentPage(items: [baseA, baseB], nextCursor: null);
    repo.getHandler = (id) async =>
        documentReadDetail(id == 'doc-a' ? baseA : baseB, content: '正文$id');
    repo.summarizeHandler = (id) async => SummaryResult(
      documentId: id,
      summary: '$id 的摘要',
      model: 'glm-4.7',
      latencyMs: 1500,
    );

    // The pane title duplicates the list-row text, so list taps are scoped.
    Finder listItem(String title) => find.descendant(
      of: find.byType(ListView),
      matching: find.text(title),
    );

    await pumpApp(tester, repo);
    await tester.pumpAndSettle();

    // Load both documents once, so the second pass over 甲文档 (below)
    // swaps the pane's detail data in place — the didUpdateWidget
    // document-switch path with a live fab State.
    await tester.tap(listItem('甲文档'));
    await tester.pumpAndSettle();
    await tester.tap(listItem('乙文档'));
    await tester.pumpAndSettle();
    expect(repo.getCalls, ['doc-a', 'doc-b']);

    // Back on 甲文档: switch to the content layer and leave the bubble OPEN…
    await tester.tap(listItem('甲文档'));
    await tester.pumpAndSettle();
    await openBubble(tester);
    await selectEntry(tester, 'AI 摘要');
    expect(bubbleTextContaining('doc-a 的摘要'), findsOneWidget);
    expect(repo.summarizeCalls, ['doc-a']);

    // …then switch documents: the fab closes AND resets to the menu layer.
    await tester.tap(listItem('乙文档'));
    await tester.pumpAndSettle();

    expect(find.text('AI 摘要'), findsNothing);
    expect(floatingButton(), findsOneWidget);
    // The still-mounted card is parked at the menu layer (its entry rows
    // are back, the old content layer is gone), not visible.
    expect(find.text('AI 助手', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('doc-a 的摘要', skipOffstage: false), findsNothing);

    // Reopening starts at the menu; selecting 摘要 generates for the new
    // document (details stay cached — no refetch on the switch).
    await openBubble(tester);
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    expect(bubbleEntry('相关文档'), findsOneWidget);
    await selectEntry(tester, 'AI 摘要');
    expect(repo.summarizeCalls, ['doc-a', 'doc-b']);
    expect(bubbleTextContaining('doc-b 的摘要'), findsOneWidget);
    expect(repo.getCalls, ['doc-a', 'doc-b']);
  });
}
