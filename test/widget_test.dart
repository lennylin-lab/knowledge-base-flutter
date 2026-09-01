import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:knowledge_base_flutter/app.dart';

void main() {
  // Compact surface → bottom NavigationBar with visible labels.
  Future<void> setSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();
  }

  testWidgets('boots on 文档 and switches between all three destinations', (
    tester,
  ) async {
    await setSize(tester, const Size(480, 800));
    await tester.pumpWidget(const ProviderScope(child: App()));

    // Initial branch.
    expect(find.text('文档功能开发中'), findsOneWidget);
    expect(find.text('搜索功能开发中'), findsNothing);
    expect(find.text('问答功能开发中'), findsNothing);

    // '搜索' / '问答' exist only as nav labels at this point, so they are
    // unambiguous; '文档' also appears as the AppBar title, hence `.last`.
    await tester.tap(find.text('搜索').last);
    await tester.pumpAndSettle();
    expect(find.text('搜索功能开发中'), findsOneWidget);

    await tester.tap(find.text('问答').last);
    await tester.pumpAndSettle();
    expect(find.text('问答功能开发中'), findsOneWidget);

    await tester.tap(find.text('文档').last);
    await tester.pumpAndSettle();
    expect(find.text('文档功能开发中'), findsOneWidget);
  });

  testWidgets('wide surface renders the navigation rail shell', (tester) async {
    await setSize(tester, const Size(1200, 800));
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // Extended rail shows the destination labels.
    expect(find.text('文档'), findsWidgets);

    await tester.tap(find.text('问答').last);
    await tester.pumpAndSettle();
    expect(find.text('问答功能开发中'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
