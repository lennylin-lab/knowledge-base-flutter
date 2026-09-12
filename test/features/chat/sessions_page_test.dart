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

/// Scripted [SessionRepository] for widget tests: pages are popped per call
/// (last one repeats), deletes are recorded.
class StubSessionRepository implements SessionRepository {
  StubSessionRepository({required this.pages});

  final List<SessionPage> pages;
  final List<String> deleteCalls = <String>[];

  @override
  Future<SessionPage> listSessions({String? cursor, int limit = 20}) async =>
      pages.length > 1 ? pages.removeAt(0) : pages.single;

  @override
  Future<SessionDetail> getSession(String sessionId) => throw UnimplementedError();

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

Future<void> _pumpSessionsApp(WidgetTester tester, StubSessionRepository repo) async {
  final docsRepo = StubDocumentsRepository()
    ..listHandler = (cursor, limit, tag) async =>
        const DocumentPage(items: [], nextCursor: null);
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
}
