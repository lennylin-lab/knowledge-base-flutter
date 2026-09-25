import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_base_flutter/core/browser/visible_url.dart';

/// Pins the route-stack → browser-URL mapping the UrlSync shim reconciles
/// against (issue #9): after an in-app pop the visible stack must map back to
/// the page actually shown — detail → list, edit → detail — instead of
/// keeping the popped page's URL (a reload then reopens it).
///
/// The structural twin of the real documents branch (shell + nested `:id` +
/// `edit`) is enough: the mapping is decided by go_router's match types
/// (`ImperativeRouteMatch` vs base matches), not by these page builders.
Future<GoRouter> pumpRouter(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/documents',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) =>
                    const Scaffold(body: Text('list')),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        const Scaffold(body: Text('detail')),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) =>
                            const Scaffold(body: Text('edit')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('maps list, pushed detail and pushed edit to their URLs', (
    tester,
  ) async {
    final router = await pumpRouter(tester);
    expect(visibleUrl(router), '/documents');

    final listContext = tester.element(find.text('list'));
    unawaited(listContext.push('/documents/1'));
    await tester.pumpAndSettle();
    expect(visibleUrl(router), '/documents/1');

    final detailContext = tester.element(find.text('detail'));
    unawaited(detailContext.push('/documents/1/edit'));
    await tester.pumpAndSettle();
    expect(visibleUrl(router), '/documents/1/edit');
  });

  testWidgets('popping edit lands on detail, popping detail on list', (
    tester,
  ) async {
    final router = await pumpRouter(tester);

    final listContext = tester.element(find.text('list'));
    unawaited(listContext.push('/documents/1'));
    await tester.pumpAndSettle();
    final detailContext = tester.element(find.text('detail'));
    unawaited(detailContext.push('/documents/1/edit'));
    await tester.pumpAndSettle();

    router.routerDelegate.pop();
    await tester.pumpAndSettle();
    expect(visibleUrl(router), '/documents/1');

    router.routerDelegate.pop();
    await tester.pumpAndSettle();
    expect(visibleUrl(router), '/documents');
  });
}
