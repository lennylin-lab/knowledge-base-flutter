import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/widgets/markdown/callout.dart';
import 'package:knowledge_base_flutter/shared/widgets/markdown_content.dart';

Future<void> _pumpMarkdown(WidgetTester tester, String data) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: MarkdownContent(data: data)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('note callout renders icon, tint and default Chinese title', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '> [!note]\n> 内容\n');

    expect(find.byType(CalloutCard), findsOneWidget);
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
    expect(find.text('备注'), findsOneWidget);
    expect(find.text('内容'), findsOneWidget);
  });

  testWidgets('warning callout keeps an explicit title and warning icon', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '> [!warning] 自定义标题\n> 注意事项\n');

    expect(find.text('自定义标题'), findsOneWidget);
    expect(find.text('备注'), findsNothing);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });

  testWidgets('aliases resolve to the canonical type', (tester) async {
    await _pumpMarkdown(tester, '> [!caution]\n> 小心\n');

    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    expect(find.text('警告'), findsOneWidget);
  });

  testWidgets('unknown type degrades to the neutral note look', (tester) async {
    await _pumpMarkdown(tester, '> [!mystery] 谜团\n> 正文\n');

    expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
    expect(find.text('谜团'), findsOneWidget);
  });

  testWidgets('fold marker `-` starts collapsed and toggles on header tap', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '> [!note]- 折叠标题\n> 隐藏内容\n');

    expect(find.text('折叠标题'), findsOneWidget);
    expect(find.text('隐藏内容'), findsNothing);

    await tester.tap(find.text('折叠标题'));
    await tester.pumpAndSettle();
    expect(find.text('隐藏内容'), findsOneWidget);

    await tester.tap(find.text('折叠标题'));
    await tester.pumpAndSettle();
    expect(find.text('隐藏内容'), findsNothing);
  });

  testWidgets('fold marker `+` starts expanded and toggles on header tap', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '> [!note]+ 展开标题\n> 可见内容\n');

    expect(find.text('可见内容'), findsOneWidget);

    await tester.tap(find.text('展开标题'));
    await tester.pumpAndSettle();
    expect(find.text('可见内容'), findsNothing);
  });

  testWidgets('no fold marker: always expanded, header tap does nothing', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '> [!note] 恒展开\n> 永远可见\n');

    expect(find.text('永远可见'), findsOneWidget);

    await tester.tap(find.text('恒展开'));
    await tester.pumpAndSettle();
    expect(find.text('永远可见'), findsOneWidget);
  });

  testWidgets('plain blockquotes keep the stock rendering', (tester) async {
    await _pumpMarkdown(tester, '> 普通引用内容\n');

    expect(find.byType(CalloutCard), findsNothing);
    expect(find.text('普通引用内容'), findsOneWidget);
  });

  testWidgets('callout body renders embedded markdown', (tester) async {
    const data = '> [!info] 信息\n> - 列表项一\n> - 列表项二\n';
    await _pumpMarkdown(tester, data);

    expect(find.text('列表项一'), findsOneWidget);
    expect(find.text('列表项二'), findsOneWidget);
  });

  testWidgets('nested callouts render recursively', (tester) async {
    const data = '> [!note] 外层\n> > [!warning]- 内层\n> > 秘密内容\n';
    await _pumpMarkdown(tester, data);

    expect(find.text('外层'), findsOneWidget);
    expect(find.text('内层'), findsOneWidget);
    // Inner callout starts collapsed.
    expect(find.text('秘密内容'), findsNothing);

    await tester.tap(find.text('内层'));
    await tester.pumpAndSettle();
    expect(find.text('秘密内容'), findsOneWidget);
  });
}
