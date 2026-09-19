import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/chat/chat_providers.dart';
import 'package:knowledge_base_flutter/features/chat/session_repository.dart';
import 'package:knowledge_base_flutter/features/chat/sessions_page.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:knowledge_base_flutter/shared/models/session.dart';

import '../documents/stub_documents_repository.dart';
import 'stub_chat_repository.dart';

/// Scripted [SessionRepository] for widget tests: session-list pages and
/// message-history pages are each popped per call (last one repeats),
/// deletes are recorded.
class StubSessionRepository implements SessionRepository {
  StubSessionRepository({required this.pages, this.messagePages = const []});

  final List<SessionPage> pages;
  final List<MessagePage> messagePages;
  final List<String> deleteCalls = <String>[];

  @override
  Future<SessionPage> listSessions({String? cursor, int limit = 20}) async =>
      pages.length > 1 ? pages.removeAt(0) : pages.single;

  @override
  Future<MessagePage> getSessionPage(
    String sessionId, {
    int limit = 30,
    String? cursor,
  }) async =>
      messagePages.length > 1 ? messagePages.removeAt(0) : messagePages.single;

  @override
  Future<void> deleteSession(String sessionId) async {
    deleteCalls.add(sessionId);
  }
}

SessionPage _page(int count, {String? nextCursor}) => SessionPage(
      items: [
        for (var i = 1; i <= count; i++)
          ChatSessionSummary(
            id: 's-$i',
            title: '会话 $i',
            createdAt: DateTime.utc(2026, 9, 1),
            updatedAt: DateTime.utc(2026, 9, 2, 10, i),
          ),
      ],
      nextCursor: nextCursor,
    );

Future<void> _pumpSessionsApp(
  WidgetTester tester,
  StubSessionRepository repo, {
  Future<DocumentReadDetail> Function(String id)? docsGetHandler,
}) async {
  final docsRepo = StubDocumentsRepository()
    ..listHandler = (cursor, limit, tag) async {
      return const DocumentPage(items: [], nextCursor: null);
    }
    ..getHandler = docsGetHandler;
  await tester.binding.setSurfaceSize(const Size(480, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(docsRepo),
        chatRepositoryProvider.overrideWithValue(StubChatRepository()),
        sessionRepositoryProvider.overrideWithValue(repo),
      ],
      retry: noAutomaticRetry,
      child: App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('问答').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.history));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists sessions with title and opens the chat page on tap',
      (tester) async {
    final repo = StubSessionRepository(pages: [_page(2)]);
    await _pumpSessionsApp(tester, repo);

    expect(find.text('会话 1'), findsOneWidget);
    expect(find.text('会话 2'), findsOneWidget);

    await tester.tap(find.text('会话 2'));
    await tester.pumpAndSettle();
    // Back on the chat page (the sessions route popped from the stack).
    expect(find.byType(SessionsPage), findsNothing);
  });

  testWidgets('shows a load-more tile when next_cursor is present and loads it',
      (tester) async {
    final repo = StubSessionRepository(
      pages: [
        _page(2, nextCursor: 'c2'),
        SessionPage(
          items: [
            ChatSessionSummary(
              id: 's-3',
              title: '会话 3',
              createdAt: DateTime.utc(2026, 9, 1),
              updatedAt: DateTime.utc(2026, 9, 2, 10, 3),
            ),
          ],
          nextCursor: null,
        ),
      ],
    );
    await _pumpSessionsApp(tester, repo);

    expect(find.text('加载更多'), findsOneWidget);
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();

    expect(find.text('会话 3'), findsOneWidget);
    expect(find.text('加载更多'), findsNothing);
  });

  testWidgets('delete asks for confirmation and removes the session',
      (tester) async {
    final repo = StubSessionRepository(pages: [_page(1), const SessionPage()]);
    await _pumpSessionsApp(tester, repo);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('删除会话'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(repo.deleteCalls, ['s-1']);
    expect(find.text('暂无历史会话'), findsOneWidget);
  });

  testWidgets('open session: newest page at bottom, per-message citation tap, '
      'scroll-up prepends older page then shows exhausted marker', (tester) async {
    // Page 1: 40 short turns (> viewport) + a cited assistant answer;
    // page 2: one older message, exhausted afterwards.
    final sessionRepo = StubSessionRepository(
      pages: [_page(1)],
      messagePages: [
        MessagePage(
          items: [
            for (var i = 1; i <= 40; i++)
              ChatMessage(
                id: 'm-$i',
                role: ChatMessageRole.user,
                content: '第 $i 问',
                createdAt: DateTime.utc(2026, 9, 1),
              ),
            ChatMessage(
              id: 'm-answer',
              role: ChatMessageRole.assistant,
              content: '结论见 [1]。',
              createdAt: DateTime.utc(2026, 9, 2),
              sources: [
                SourceRef(
                  documentId: 'doc-42',
                  documentTitle: '引用文档',
                  chunkIndex: 0,
                ),
              ],
            ),
          ],
          nextCursor: 'cur-2',
        ),
        MessagePage(
          items: [
            ChatMessage(
              id: 'm-old',
              role: ChatMessageRole.user,
              content: '更早的消息',
              createdAt: DateTime.utc(2026, 8, 30),
            ),
          ],
          nextCursor: null,
        ),
      ],
    );
    await _pumpSessionsApp(
      tester,
      sessionRepo,
    );

    await tester.tap(find.text('会话 1'));
    await tester.pumpAndSettle();

    // 首屏（reverse 列表定位在最新一端）：带引用的回答可见，更早页未加载。
    expect(find.textContaining('结论见'), findsOneWidget);
    expect(find.text('[1]'), findsOneWidget, reason: 'per-message citation badge');
    expect(find.text('更早的消息'), findsNothing);
    expect(find.text('已加载全部历史'), findsNothing);

    // 向上滚动到已加载的最顶端 → 触发更早页 → prepend（最新回答仍在）。
    // 反向列表：手指上滑（负 dy）向更早的消息移动；循环滚动直到触底。
    for (var i = 0; i < 12 && find.text('已加载全部历史').evaluate().isEmpty; i++) {
      // 反向列表（AxisDirection.up）：正 dy 把内容拉向底部，视口向更早
      // 的消息推进；滚动到已加载的最顶端（footer 可见）即触发下一页。
      await tester.fling(find.byType(ListView), const Offset(0, 500), 2000);
      await tester.pumpAndSettle();
    }

    expect(find.text('更早的消息'), findsOneWidget);
    expect(find.text('已加载全部历史'), findsOneWidget);
    expect(find.text('第 1 问'), findsOneWidget,
        reason: 'prepend does not shift the viewport (reverse list)');
  });
}
