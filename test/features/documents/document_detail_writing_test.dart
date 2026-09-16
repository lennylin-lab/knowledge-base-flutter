import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/document_detail_page.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/features/operations/operations_providers.dart';
import 'package:knowledge_base_flutter/features/operations/operations_repository.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:knowledge_base_flutter/shared/models/operation.dart';
import 'package:knowledge_base_flutter/shared/widgets/format.dart';
import 'package:knowledge_base_flutter/shared/widgets/markdown_content.dart';

import '../operations/stub_operations_repository.dart';
import 'stub_documents_repository.dart';

/// Widget tests for the 「AI 续写」 writing layer of the AI bubble: menu
/// entry → instruction input → draft review → apply (confirm / 409) plus
/// resume and the on-demand history. All bubble contracts (keep-alive,
/// PopScope gate, height bound, zero-calls-on-open) must hold for the new
/// layer too.
Future<void> pumpApp(
  WidgetTester tester,
  StubDocumentsRepository repo,
  StubOperationsRepository operations,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(repo),
        operationsRepositoryProvider.overrideWithValue(operations),
      ],
      retry: noAutomaticRetry,
      child: App(),
    ),
  );
}

StubDocumentsRepository repoWithDoc(String content) {
  final base = documentRead(id: 'doc-1', title: '设计笔记');
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

Finder floatingButton() => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.byType(FloatingActionButton),
);

Finder bubbleEntry(String label) => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.text(label),
);

Finder bubbleText(String text) =>
    find.descendant(of: find.byType(AiAssistantFab), matching: find.text(text));

Finder bubbleTextContaining(String containing) => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.textContaining(containing),
);

Finder bubbleBackButton() => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.byTooltip('返回'),
);

/// The instruction field of the writing layer (the app's only TextField on
/// the detail surface, scoped anyway).
Finder instructionField() => find.descendant(
  of: find.byType(AiAssistantFab),
  matching: find.byType(TextField),
);

Future<void> openBubble(WidgetTester tester) async {
  await tester.tap(floatingButton());
  await tester.pumpAndSettle();
}

/// Selects the 「AI 续写」 menu entry. The writing layer fires no calls on
/// entry, so pumpAndSettle is safe here.
Future<void> openWritingLayer(WidgetTester tester) async {
  await tester.tap(bubbleEntry('AI 续写'));
  await tester.pumpAndSettle();
}

/// Types an instruction and starts the generation (tap callback path).
Future<void> generateDraft(WidgetTester tester, String instruction) async {
  await tester.enterText(instructionField(), instruction);
  await tester.pump();
  await tester.tap(bubbleText('生成草稿'));
  await tester.pump(); // generating state renders
}

void main() {
  testWidgets('menu shows the AI 续写 entry; entering the writing layer fires '
      'zero calls (idle input + history affordance)', (tester) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    final operations = StubOperationsRepository();

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);

    // Opening the detail and the bubble: zero AI/operations calls.
    expect(bubbleEntry('AI 续写'), findsNothing);
    await openBubble(tester);
    expect(bubbleEntry('AI 续写'), findsOneWidget);
    expect(operations.draftCalls, isEmpty);
    expect(operations.operationsForDocumentCalls, isEmpty);
    expect(repo.summarizeCalls, isEmpty);

    // Entering the writing layer: still zero calls — generation and history
    // load are explicit user actions.
    await openWritingLayer(tester);
    expect(bubbleBackButton(), findsOneWidget);
    expect(bubbleText('想让 AI 重点处理什么？可留空'), findsOneWidget);
    expect(bubbleText('生成草稿'), findsOneWidget);
    expect(bubbleText('历史操作'), findsOneWidget);
    expect(operations.draftCalls, isEmpty);
    expect(operations.operationsForDocumentCalls, isEmpty);
  });

  testWidgets('idle generate flow: pending completer shows the spinner with '
      'the seconds hint and no second call; completing lands the draft', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    final pending = Completer<OperationDraftResult>();
    operations.draftHandler = ({required documentId, instruction}) =>
        pending.future;

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);

    await generateDraft(tester, '续写一章星际旅行');

    expect(bubbleText('正在生成草稿…'), findsOneWidget);
    expect(bubbleText('同步生成可能需要数秒'), findsOneWidget);
    expect(operations.draftCalls, [
      (documentId: 'doc-1', instruction: '续写一章星际旅行'),
    ]);

    // The generating view offers no trigger at all (spinner only) — a
    // second call is impossible from the UI.
    expect(bubbleText('生成草稿'), findsNothing);
    expect(operations.draftCalls, hasLength(1));

    pending.complete(completedDraftResult());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(bubbleText('正在生成草稿…'), findsNothing);
    expect(bubbleText('星际旅行草稿'), findsOneWidget);
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);
    expect(bubbleText('应用到文档'), findsOneWidget);
  });

  testWidgets('draft review renders the shared markdown pipeline with the '
      'front matter stripped and the fallback title', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    // No explicit draft title — the fallback 未命名草稿 shows; the YAML front
    // matter (where the apply-time title derives from) must not render.
    operations.draftHandler = ({required documentId, instruction}) async =>
        completedDraftResult(title: null);

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);

    await generateDraft(tester, '随便续写');
    await tester.pumpAndSettle();

    expect(bubbleText('未命名草稿'), findsOneWidget);
    // Body through MarkdownContent, front matter stripped.
    expect(
      find.descendant(
        of: find.byType(AiAssistantFab),
        matching: find.byType(MarkdownContent),
      ),
      findsOneWidget,
    );
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);
    expect(bubbleTextContaining('title: 星际旅行草稿'), findsNothing);
    expect(bubbleTextContaining('---'), findsNothing);

    // Actions of the draft review view.
    expect(bubbleText('应用到文档'), findsOneWidget);
    expect(bubbleText('重新生成'), findsOneWidget);
    expect(bubbleText('返回菜单'), findsOneWidget);
  });

  testWidgets('apply: confirm dialog (cancel does nothing) → applying with '
      'disabled actions → success view + detail/list refetch; 查看文档 closes '
      'the bubble onto the applied body', (tester) async {
    final base = documentRead(id: 'doc-1', title: '设计笔记');
    final repo = StubDocumentsRepository();
    var getCount = 0;
    repo.listHandler = (cursor, limit, tags) async =>
        DocumentPage(items: [base], nextCursor: null);
    repo.getHandler = (id) async {
      getCount++;
      return documentReadDetail(
        base,
        content: getCount == 1 ? '原始正文' : '已应用的正文',
      );
    };
    final operations = StubOperationsRepository();
    operations.draftHandler = ({required documentId, instruction}) async =>
        completedDraftResult();
    final applyPending = Completer<ApplyResult>();
    operations.applyHandler = (operationId) => applyPending.future;

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    expect(find.textContaining('原始正文'), findsOneWidget);
    await openBubble(tester);
    await openWritingLayer(tester);
    await generateDraft(tester, '续写');
    await tester.pumpAndSettle();

    // Confirm dialog first — mandatory before any apply call.
    await tester.tap(bubbleText('应用到文档'));
    await tester.pumpAndSettle();
    expect(find.text('应用后将以草稿覆盖文档的内容、标题与标签，且无法从客户端撤销。确定应用吗？'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('应用'), findsOneWidget);

    // Cancel does nothing: no call, still the draft view.
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(operations.applyCalls, isEmpty);
    expect(bubbleText('应用到文档'), findsOneWidget);

    // Confirm → applying: every action disabled, apply call fired.
    await tester.tap(bubbleText('应用到文档'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('应用'));
    await tester.pump();
    expect(operations.applyCalls, ['op-1']);
    FilledButton applyButton() => tester.widget<FilledButton>(
      find.ancestor(
        of: bubbleText('应用到文档'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(applyButton().onPressed, isNull);
    final regenerate = tester.widget<TextButton>(
      find.ancestor(of: bubbleText('重新生成'), matching: find.byType(TextButton)),
    );
    expect(regenerate.onPressed, isNull);

    // Apply result lands: success view + both document caches invalidated
    // (the detail body and the documents list refetch).
    applyPending.complete(applyResultFor(completedDraftOperation()));
    await tester.pumpAndSettle();

    expect(bubbleText('已应用到文档'), findsOneWidget);
    expect(bubbleText('文档将在后台重新索引'), findsOneWidget);
    expect(bubbleText('返回菜单'), findsOneWidget);
    expect(bubbleText('查看文档'), findsOneWidget);
    expect(repo.getCalls, ['doc-1', 'doc-1']);
    expect(repo.listCalls, hasLength(2));
    // The refetched body (behind the bubble) is the applied content.
    expect(find.textContaining('已应用的正文'), findsOneWidget);

    // 查看文档 closes the bubble; the applied body stays visible.
    await tester.tap(bubbleText('查看文档'));
    await tester.pumpAndSettle();
    expect(find.text('AI 助手'), findsNothing);
    expect(find.textContaining('已应用的正文'), findsOneWidget);
  });

  testWidgets('409 conflict keeps the draft view with the dedicated copy; '
      '重新生成 returns to the input with the instruction prefilled', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    operations.draftHandler = ({required documentId, instruction}) async =>
        completedDraftResult();
    operations.applyHandler = (operationId) async {
      throw const ApiException(
        code: 'conflict',
        message: 'Document changed since the draft was created',
        details: {
          'base_version': '2026-08-31T12:30:00Z',
          'current_version': '2026-09-16T08:01:00Z',
        },
        statusCode: 409,
      );
    };

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);
    await generateDraft(tester, '写一章星际旅行');
    await tester.pumpAndSettle();

    await tester.tap(bubbleText('应用到文档'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('应用'));
    await tester.pumpAndSettle();

    // Dedicated 409 copy; the draft stays reviewable (not a dead end).
    expect(bubbleText('文档已更新，草稿基于旧版本，请重新生成草稿'), findsOneWidget);
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);
    expect(operations.draftCalls, hasLength(1));

    // 重新生成 → back to the input, previous instruction prefilled.
    await tester.tap(bubbleText('重新生成'));
    await tester.pumpAndSettle();
    expect(bubbleText('生成草稿'), findsOneWidget);
    final field = tester.widget<TextField>(instructionField());
    expect(field.controller!.text, '写一章星际旅行');

    // Regenerating fires the second draft call with the same instruction.
    await tester.tap(bubbleText('生成草稿'));
    await tester.pumpAndSettle();
    expect(operations.draftCalls, hasLength(2));
    expect(operations.draftCalls.last.instruction, '写一章星际旅行');
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);
  });

  testWidgets('failed operation from history shows the recoverable failure '
      'view; 恢复 resumes it to the draft review and refreshes the history', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    operations.operationsForDocumentHandler = (documentId) async => [
      operationFixture(
        id: 'op-f',
        state: OperationState.failed,
        error: {'error_class': 'LLMProviderError'},
      ),
      operationFixture(
        id: 'op-a',
        state: OperationState.applied,
        result: {'revision_id': 'rev-1'},
        updatedAt: '2026-09-15T10:00:00Z',
      ),
    ];
    operations.resumeHandler = (operationId) async =>
        completedDraftOperation(id: operationId);

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);

    // On-demand history: the affordance's first tap loads it.
    await tester.tap(bubbleText('历史操作'));
    await tester.pumpAndSettle();
    expect(operations.operationsForDocumentCalls, ['doc-1']);
    expect(bubbleText('失败'), findsOneWidget);
    expect(bubbleText('已应用'), findsOneWidget);
    expect(
      bubbleText(formatIsoTimestamp('2026-09-15T10:00:00Z')),
      findsOneWidget,
    );

    // The failed item opens the recoverable failure view.
    await tester.tap(bubbleText('失败'));
    await tester.pumpAndSettle();
    expect(bubbleText('该操作未能完成'), findsOneWidget);
    expect(bubbleText('恢复'), findsOneWidget);
    expect(bubbleText('重新生成'), findsOneWidget);

    // 恢复 → resume → completed draft review.
    await tester.tap(bubbleText('恢复'));
    await tester.pumpAndSettle();
    expect(operations.resumeCalls, ['op-f']);
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);

    // 返回菜单 resets the workflow to idle AND returns to the menu layer
    // (the layer switch unmounts the writing content); re-entering shows
    // the input, and re-opening 历史操作 renders the cached — refreshed
    // after the resume — list without a third call.
    await tester.tap(bubbleText('返回菜单'));
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    await openWritingLayer(tester);
    expect(operations.operationsForDocumentCalls, ['doc-1', 'doc-1']);
    expect(bubbleText('生成草稿'), findsOneWidget);
    await tester.tap(bubbleText('历史操作'));
    await tester.pumpAndSettle();
    expect(operations.operationsForDocumentCalls, hasLength(2));
    expect(bubbleText('失败'), findsOneWidget);
  });

  testWidgets('history loads once (spinner while pending), a completed item '
      'opens its draft, and an applied item is not tappable', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    final pending = Completer<List<OperationReadDetail>>();
    operations.operationsForDocumentHandler = (documentId) => pending.future;

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);

    await tester.tap(bubbleText('历史操作'));
    await tester.pump();
    expect(bubbleText('正在加载历史操作…'), findsOneWidget);

    pending.complete([
      completedDraftOperation(id: 'op-h'),
      operationFixture(
        id: 'op-a',
        state: OperationState.applied,
        result: {'revision_id': 'rev-1'},
      ),
    ]);
    await tester.pumpAndSettle();
    // Cached: closing/reopening the section does not refetch.
    expect(operations.operationsForDocumentCalls, ['doc-1']);
    expect(bubbleText('已完成'), findsOneWidget);
    expect(bubbleText('已应用'), findsOneWidget);

    // The completed item opens the draft review (no refetch — list items
    // are full details).
    await tester.tap(bubbleText('已完成'));
    await tester.pumpAndSettle();
    expect(operations.operationCalls, isEmpty);
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);

    // 返回菜单 resets the workflow to idle AND returns to the menu layer;
    // re-entering shows the input, and re-opening 历史操作 renders the
    // cached list without a refetch — the applied item carries no tap
    // target.
    await tester.tap(bubbleText('返回菜单'));
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    await openWritingLayer(tester);
    expect(bubbleText('生成草稿'), findsOneWidget);
    expect(operations.operationsForDocumentCalls, hasLength(1));
    await tester.tap(bubbleText('历史操作'));
    await tester.pumpAndSettle();
    expect(operations.operationsForDocumentCalls, hasLength(1));
    expect(bubbleText('已完成'), findsOneWidget);
    expect(bubbleText('已应用'), findsOneWidget);
    await tester.tap(bubbleText('已应用'));
    await tester.pumpAndSettle();
    expect(
      bubbleText('生成草稿'),
      findsOneWidget,
      reason: 'an applied item must not open',
    );
  });

  testWidgets('clearCurrent (返回菜单) while a history fetch is in flight does '
      'not strand the spinner: the pending fetch still lands and renders', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    final historyPending = Completer<List<OperationReadDetail>>();
    operations.operationsForDocumentHandler = (documentId) =>
        historyPending.future;
    operations.draftHandler = ({required documentId, instruction}) async =>
        completedDraftResult();

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);

    // Open the history section: the fetch starts (pending completer).
    await tester.tap(bubbleText('历史操作'));
    await tester.pump();
    await tester.pump();
    expect(bubbleText('正在加载历史操作…'), findsOneWidget);
    expect(operations.operationsForDocumentCalls, ['doc-1']);

    // Generate a draft while the fetch is still in flight (both controls
    // live in the idle view), then leave via 返回菜单 — the workflow reset
    // happens mid-fetch.
    await tester.enterText(instructionField(), '续写');
    await tester.pump();
    await tester.tap(bubbleText('生成草稿'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(bubbleText('应用到文档'), findsOneWidget);
    await tester.tap(bubbleText('返回菜单'));
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);

    // Re-enter and re-open the section: the in-flight fetch owns the slice
    // (loading guard → no second call) and the spinner shows…
    await openWritingLayer(tester);
    await tester.tap(bubbleText('历史操作'));
    await tester.pump();
    await tester.pump();
    expect(bubbleText('正在加载历史操作…'), findsOneWidget);
    expect(operations.operationsForDocumentCalls, hasLength(1));

    // …the pending fetch lands and renders — no permanent spinner.
    historyPending.complete([completedDraftOperation(id: 'op-h')]);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(bubbleText('正在加载历史操作…'), findsNothing);
    expect(bubbleText('已完成'), findsOneWidget);
    expect(
      bubbleText(formatIsoTimestamp('2026-09-16T08:00:05Z')),
      findsOneWidget,
    );
    expect(operations.operationsForDocumentCalls, hasLength(1));
  });

  testWidgets('the writing layer survives dismissal: instruction text and an '
      'in-flight generation continue across reopen with zero extra calls', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    final pending = Completer<OperationDraftResult>();
    operations.draftHandler = ({required documentId, instruction}) =>
        pending.future;

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);

    // Instruction typed, then dismissed — the keep-alive card preserves it.
    await tester.enterText(instructionField(), '续写一段');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pumpAndSettle();
    // Offstage content is only reachable by unscoped finders.
    final hiddenField = tester.widget<TextField>(
      find.byType(TextField, skipOffstage: false),
    );
    expect(hiddenField.controller!.text, '续写一段');

    // Reopen: the text is still there; generating keeps exactly one call.
    await openBubble(tester);
    expect(
      tester.widget<TextField>(instructionField()).controller!.text,
      '续写一段',
    );
    await tester.tap(bubbleText('生成草稿'));
    await tester.pump();
    await tester.pump();
    expect(bubbleText('正在生成草稿…'), findsOneWidget);
    expect(operations.draftCalls, hasLength(1));

    // Dismiss mid-generation (bounded pumps — the spinner animates)…
    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pump();
    await tester.pump();
    expect(find.text('正在生成草稿…'), findsNothing);

    // …reopen: the same generation is still running live.
    await tester.tap(floatingButton());
    await tester.pump();
    await tester.pump();
    expect(bubbleText('正在生成草稿…'), findsOneWidget);
    expect(operations.draftCalls, hasLength(1));

    pending.complete(completedDraftResult());
    await tester.pump();
    await tester.pumpAndSettle();
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);
    expect(operations.draftCalls, hasLength(1));
  });

  testWidgets('返回菜单 resets the workflow to idle; the header 返回 keeps the '
      'draft (layer navigation only)', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    operations.draftHandler = ({required documentId, instruction}) async =>
        completedDraftResult();

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);
    await generateDraft(tester, '续写');
    await tester.pumpAndSettle();

    // The content-level 返回菜单 is the reset: re-entering shows the input.
    await tester.tap(bubbleText('返回菜单'));
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    await openWritingLayer(tester);
    expect(bubbleText('生成草稿'), findsOneWidget);
    expect(bubbleTextContaining('续写正文第一段'), findsNothing);

    // Generate again, then leave via the header 返回 (layer navigation):
    // re-entering continues presenting the draft — no second call.
    await generateDraft(tester, '续写');
    await tester.pumpAndSettle();
    expect(operations.draftCalls, hasLength(2));
    await tester.tap(bubbleBackButton());
    await tester.pumpAndSettle();
    await openWritingLayer(tester);
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);
    expect(operations.draftCalls, hasLength(2));
  });

  testWidgets('system back at the writing layer returns to the menu (page '
      'stays); closed on the writing layer, back pops the page (PopScope)', (
    tester,
  ) async {
    final repo = repoWithDoc('# 设计笔记\n\n混合检索正文');
    final operations = StubOperationsRepository();

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);
    expect(bubbleText('生成草稿'), findsOneWidget);

    // The content layer consumes system back: menu layer, page stays.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(bubbleEntry('AI 摘要'), findsOneWidget);
    expect(find.byType(DocumentDetailPage), findsOneWidget);
    expect(find.text('混合检索正文'), findsOneWidget);

    // Park the bubble closed on the writing layer: back pops the page.
    await openWritingLayer(tester);
    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DocumentDetailPage), findsNothing);
    expect(find.text('设计笔记'), findsOneWidget);
  });

  testWidgets('long draft: the bubble stays height-bounded by the surface '
      'and the writing layer scrolls internally', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    final draft = List.generate(120, (i) => '草稿段落 $i。').join('\n\n');
    operations.draftHandler = ({required documentId, instruction}) async =>
        completedDraftResult(content: draft, title: null);

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);
    await generateDraft(tester, '长草稿');
    await tester.pumpAndSettle();

    final viewport = find.descendant(
      of: find.byType(AiAssistantFab),
      matching: find.byType(SingleChildScrollView),
    );
    expect(viewport, findsOneWidget);
    final bubbleCard = find.ancestor(
      of: viewport,
      matching: find.byType(Material),
    );

    // Bounded by the configured fraction of the surface, top edge on screen.
    const surfaceHeight = 900.0;
    final bubbleHeight = tester.getSize(bubbleCard.first).height;
    expect(bubbleHeight, lessThanOrEqualTo(surfaceHeight * 0.9));
    expect(bubbleHeight, greaterThan(surfaceHeight * 0.4));
    expect(tester.getTopLeft(bubbleCard.first).dy, greaterThanOrEqualTo(0));

    final viewportRect = tester.getRect(viewport);
    final firstRect = tester.getRect(bubbleTextContaining('草稿段落 0'));
    expect(firstRect.top, greaterThanOrEqualTo(viewportRect.top - 0.5));

    // The tail is reachable by internal scrolling (position resolved from
    // the 重新生成 action — direct child of the content layer).
    final position = Scrollable.of(
      tester.element(bubbleText('重新生成')),
      axis: Axis.vertical,
    ).position;
    expect(position.maxScrollExtent, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    expect(
      tester.getRect(bubbleTextContaining('草稿段落 0')).top,
      lessThan(firstRect.top),
    );
    final lastRect = tester.getRect(bubbleTextContaining('草稿段落 119'));
    expect(
      lastRect.bottom,
      lessThanOrEqualTo(tester.getRect(viewport).bottom + 0.5),
    );
  });

  testWidgets('generate failure (503 chat_unavailable) shows the friendly '
      'copy above the still-working 生成草稿 button', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    operations.draftHandler = ({required documentId, instruction}) async {
      throw const ApiException(
        code: 'chat_unavailable',
        message: 'No API key configured',
        statusCode: 503,
      );
    };
    // A failure auto-loads the history (failure recovery) — the newest
    // failed operation shows up there.
    operations.operationsForDocumentHandler = (documentId) async => [
      operationFixture(
        id: 'op-f',
        state: OperationState.failed,
        error: {'error_class': 'LLMProviderError'},
      ),
    ];

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);

    await generateDraft(tester, '续写');
    await tester.pumpAndSettle();

    expect(bubbleText('AI 服务暂不可用，请稍后重试'), findsOneWidget);
    // Dead-end rule: the input and its button stay available in place.
    expect(bubbleText('生成草稿'), findsOneWidget);
    // The history was auto-loaded by the failure — opening the affordance
    // renders the cached list (no second call).
    expect(operations.operationsForDocumentCalls, ['doc-1']);
    await tester.tap(bubbleText('历史操作'));
    await tester.pumpAndSettle();
    expect(operations.operationsForDocumentCalls, hasLength(1));
    expect(bubbleText('失败'), findsOneWidget);

    // Retry succeeds.
    operations.draftHandler = ({required documentId, instruction}) async =>
        completedDraftResult();
    await tester.tap(bubbleText('生成草稿'));
    await tester.pumpAndSettle();
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);
    expect(bubbleText('AI 服务暂不可用，请稍后重试'), findsNothing);
  });

  testWidgets('mid-stream draft failure → the failed operation is reachable '
      'through 历史操作 → openOperation → 恢复 completes it', (tester) async {
    final repo = repoWithDoc('# 设计笔记');
    final operations = StubOperationsRepository();
    operations.draftHandler = ({required documentId, instruction}) async {
      throw const ApiException(
        code: 'llm_provider_error',
        message: 'provider exploded',
      );
    };
    // The stream error carries no operation id — the auto-loaded history is
    // the only path to the persisted failed operation (newest first).
    operations.operationsForDocumentHandler = (documentId) async => [
      operationFixture(
        id: 'op-f',
        state: OperationState.failed,
        error: {'error_class': 'LLMProviderError'},
      ),
      operationFixture(
        id: 'op-old',
        state: OperationState.completed,
        draft: const DraftContent(content: '旧草稿正文', title: '旧草稿'),
        updatedAt: '2026-09-15T10:00:00Z',
      ),
    ];
    operations.resumeHandler = (operationId) async =>
        completedDraftOperation(id: operationId);

    await pumpApp(tester, repo, operations);
    await tester.pumpAndSettle();
    await openDetail(tester);
    await openBubble(tester);
    await openWritingLayer(tester);

    await generateDraft(tester, '续写');
    await tester.pumpAndSettle();

    // The error view keeps 生成失败 copy + the working 生成草稿…
    expect(bubbleText('生成失败：provider exploded'), findsOneWidget);
    expect(bubbleText('生成草稿'), findsOneWidget);

    // …and the history affordance holds the freshly loaded failed op.
    expect(operations.operationsForDocumentCalls, ['doc-1']);
    await tester.tap(bubbleText('历史操作'));
    await tester.pumpAndSettle();
    expect(bubbleText('失败'), findsOneWidget);

    // tap → openOperation → the recoverable failure view with 恢复…
    await tester.tap(bubbleText('失败'));
    await tester.pumpAndSettle();
    expect(bubbleText('该操作未能完成'), findsOneWidget);
    expect(bubbleText('恢复'), findsOneWidget);

    // …恢复 → resume → completed draft review, end to end.
    await tester.tap(bubbleText('恢复'));
    await tester.pumpAndSettle();
    expect(operations.resumeCalls, ['op-f']);
    expect(bubbleTextContaining('续写正文第一段'), findsOneWidget);
  });
}
