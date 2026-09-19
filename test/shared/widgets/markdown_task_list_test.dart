import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/widgets/markdown_content.dart';

Future<void> _pumpMarkdown(
  WidgetTester tester,
  String data,
  void Function(int taskIndex, bool checked)? onTaskToggle,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MarkdownContent(data: data, onTaskToggle: onTaskToggle),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('task list renders one checkbox icon per item', (tester) async {
    await _pumpMarkdown(tester, '- [ ] 待办\n- [x] 已完成\n', null);

    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
  });

  testWidgets('tapping a checkbox reports the item index and new state', (
    tester,
  ) async {
    final toggles = <(int, bool)>[];
    await _pumpMarkdown(
      tester,
      '- [ ] 甲\n- [x] 乙\n',
      (taskIndex, checked) => toggles.add((taskIndex, checked)),
    );

    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.tap(find.byIcon(Icons.check_box));
    await tester.pump();

    expect(toggles, [(0, true), (1, false)]);
  });

  testWidgets('nested task items index in document order', (tester) async {
    final toggles = <(int, bool)>[];
    await _pumpMarkdown(
      tester,
      '- [ ] 父\n  - [ ] 子\n- [ ] 兄弟\n',
      (taskIndex, checked) => toggles.add((taskIndex, checked)),
    );

    // 同为 outline 图标,按 finder 顺序 = 渲染顺序 = 文档顺序。
    await tester.tap(find.byIcon(Icons.check_box_outline_blank).at(1));
    await tester.pump();

    expect(toggles, [(1, true)]);
  });

  testWidgets('without a callback checkboxes render but stay inert', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '- [ ] 待办\n', null);

    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    // Tap must not crash; nothing observable changes.
    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pump();
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets('a document without task markers renders no checkbox icons', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '- 普通项\n- 另一项\n', null);

    expect(find.byIcon(Icons.check_box), findsNothing);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    expect(find.text('普通项'), findsOneWidget);
  });

  testWidgets('task lists inside callouts stay read-only', (tester) async {
    await _pumpMarkdown(tester, '> [!note] 清单\n> - [ ] 里面的任务\n', null);

    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.text('里面的任务'), findsOneWidget);
  });
}
