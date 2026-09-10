import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/widgets/markdown/code_highlight.dart';
import 'package:knowledge_base_flutter/shared/widgets/markdown_content.dart';

List<TextSpan> _flatten(TextSpan span) {
  final spans = <TextSpan>[span];
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) spans.addAll(_flatten(child));
  }
  return spans;
}

/// Finds the RichText that renders [text]. Requires `selectable: false` —
/// with selection enabled the package renders via EditableText, which has
/// no RichText widget in the tree.
RichText? _richTextContaining(WidgetTester tester, String text) {
  for (final widget in tester.widgetList<RichText>(
    find.byWidgetPredicate((w) => w is RichText),
  )) {
    if (widget.text.toPlainText().contains(text)) return widget;
  }
  return null;
}

Iterable<Color> _spanColors(Iterable<TextSpan> spans) => spans
    .where((s) => s.text != null && s.text!.isNotEmpty)
    .map((s) => s.style?.color)
    .whereType<Color>();

Future<void> _pumpMarkdown(WidgetTester tester, String data) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MarkdownContent(data: data, selectable: false),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('declared language renders multiple token colors', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '```dart\nfinal count = 42; // done\n```\n');

    final richText = _richTextContaining(tester, 'final count');
    expect(richText, isNotNull);

    final spans = _flatten(richText!.text as TextSpan);
    // keyword `final`, numeric literal `42` and the comment must carry the
    // palette colors rather than the single base foreground.
    final colors = _spanColors(spans).toSet();
    expect(colors.length, greaterThanOrEqualTo(3));
    final plain = spans.map((s) => s.text).join();
    expect(plain, contains('final'));
    expect(plain, contains('42'));
  });

  testWidgets('unknown language falls back to monochrome without errors', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '```notalanguage\nplain text here\n```\n');

    final richText = _richTextContaining(tester, 'plain text here');
    expect(richText, isNotNull);
    final spans = _flatten(richText!.text as TextSpan);
    expect(_spanColors(spans).toSet().length, 1);
  });

  testWidgets('missing language falls back to monochrome without errors', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '```\nno info string\n```\n');

    final richText = _richTextContaining(tester, 'no info string');
    expect(richText, isNotNull);
    final spans = _flatten(richText!.text as TextSpan);
    expect(_spanColors(spans).toSet().length, 1);
  });

  testWidgets('inline code spans keep rendering inside the paragraph', (
    tester,
  ) async {
    await _pumpMarkdown(tester, '行内 `code` 仍在段落里。\n');

    // The paragraph text and the inline code stay in the same rich text
    // block — the `pre` interception must not lift `code` into its own block.
    final richText = _richTextContaining(tester, '行内');
    expect(richText, isNotNull);
    expect(richText!.text.toPlainText(), contains('code'));
    expect(richText.text.toPlainText(), contains('仍在段落里'));
  });

  testWidgets('selectable code blocks render as SelectableText', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarkdownContent(
              data: '```dart\nfinal x = 1;\n```\n',
              selectable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final editable = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .where((s) => s.controller.text.contains('final x = 1;'));
    expect(editable, isNotEmpty);
  });

  test('token palette follows brightness', () {
    const source = 'final x = 1;';
    final light = highlightCodeSpan(
      source: source,
      language: 'dart',
      baseStyle: null,
      brightness: Brightness.light,
    );
    final dark = highlightCodeSpan(
      source: source,
      language: 'dart',
      baseStyle: null,
      brightness: Brightness.dark,
    );

    final lightColors = _spanColors(_flatten(light)).toSet();
    final darkColors = _spanColors(_flatten(dark)).toSet();
    // GitHub Light keywords (#d73a49) vs GitHub Dark keywords (#ff7b72).
    expect(lightColors, isNot(equals(darkColors)));
    expect(lightColors, contains(const Color(0xffd73a49)));
    expect(darkColors, contains(const Color(0xffff7b72)));
  });

  test('fallback foreground follows brightness', () {
    final light = highlightCodeSpan(
      source: 'plain',
      language: null,
      baseStyle: null,
      brightness: Brightness.light,
    );
    final dark = highlightCodeSpan(
      source: 'plain',
      language: null,
      baseStyle: null,
      brightness: Brightness.dark,
    );
    expect(light.style!.color, const Color(0xff24292e));
    expect(dark.style!.color, const Color(0xffc9d1d9));
  });
}
