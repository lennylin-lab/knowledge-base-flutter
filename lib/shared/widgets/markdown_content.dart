import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as md;
import 'package:markdown/markdown.dart' as pmd;

import '../../core/theme/app_sizes.dart';
import 'markdown/callout.dart';
import 'markdown/code_highlight.dart';

/// The app's single Markdown renderer configuration — the document detail
/// page and chat answers must render identically (component-guidelines
/// spec). Uses `flutter_markdown_plus` (`flutter_markdown` is
/// discontinued).
class MarkdownContent extends StatelessWidget {
  /// Monospace UI spans (editor, code blocks) don't inherit the theme's
  /// CJK fallback chain, so any place that overrides fontFamily must
  /// re-attach this list or hanzi flash tofu on first paint.
  static const _cjkFallback = [
    'NotoSansSC',
    'Noto Sans CJK SC',
    'PingFang SC',
    'Microsoft YaHei',
  ];

  const MarkdownContent({
    super.key,
    required this.data,
    this.selectable = true,
  });

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    // Default extension set is GitHub-flavored Markdown.
    final baseStyle = md.MarkdownStyleSheet.fromTheme(Theme.of(context));
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    return md.MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: baseStyle.copyWith(
        // Package defaults (pPadding zero + blockSpacing 8) leave consecutive
        // paragraphs only ~2px apart beyond the body line gap, so text reads
        // as one wall. pPadding stacks on top of blockSpacing: 2 + 14 + 2.
        pPadding: const EdgeInsets.symmetric(vertical: 2),
        blockSpacing: 14,
        // Inline code spans: tertiary-tinted monospace, distinguished from
        // body text by color alone (no background chip).
        code: baseStyle.code?.copyWith(
          backgroundColor: Colors.transparent,
          color: colorScheme.tertiary,
          fontWeight: FontWeight.w500,
          // Package default hardcodes monospace without a CJK fallback;
          // re-attach one or inline-code hanzi flash tofu on first paint.
          fontFamilyFallback: _cjkFallback,
        ),
        // Bold (`**text**`): the M3 body face only steps w400 → w600, which
        // reads as barely-different at reading sizes; push the weight and
        // force full-contrast foreground so emphasis pops against body text.
        strong: baseStyle.strong?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      blockSyntaxes: const [CalloutBlockSyntax()],
      builders: {
        // All heading levels get a hairline rule under the heading text,
        // separating the document outline; see _HeadingRuleBuilder.
        'h1': _HeadingRuleBuilder(colorScheme.outlineVariant),
        'h2': _HeadingRuleBuilder(colorScheme.outlineVariant),
        'h3': _HeadingRuleBuilder(colorScheme.outlineVariant),
        'h4': _HeadingRuleBuilder(colorScheme.outlineVariant),
        'h5': _HeadingRuleBuilder(colorScheme.outlineVariant),
        'h6': _HeadingRuleBuilder(colorScheme.outlineVariant),
        // Fenced code blocks: token-level syntax highlighting that follows
        // the theme brightness; see code_highlight.dart.
        'pre': HighlightedCodeBlockBuilder(
          brightness: brightness,
          selectable: selectable,
        ),
        // Obsidian callouts with optional folding; see callout.dart.
        'callout': CalloutElementBuilder(selectable: selectable),
      },
    );
  }
}

/// Renders a heading (`h1`–`h6`) with a bottom hairline rule. The package
/// has no per-element child list API (a builder's returned widget replaces
/// the default rendering wholesale), so text nodes are captured via
/// [visitText] and re-assembled here; headings containing *inline elements*
/// (code, links, images) fall back to the package's default heading
/// rendering rather than risk dropping content.
class _HeadingRuleBuilder extends md.MarkdownElementBuilder {
  _HeadingRuleBuilder(this.color);

  final Color color;
  final List<Widget> _parts = [];

  @override
  bool isBlockElement() => true;

  @override
  void visitElementBefore(pmd.Element element) {
    _parts.clear();
  }

  @override
  Widget? visitText(pmd.Text text, TextStyle? preferredStyle) {
    final widget = Text(text.text, style: preferredStyle);
    _parts.add(widget);
    return widget;
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    pmd.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final children = element.children ?? const <pmd.Node>[];
    final bool textOnly = children.every((node) => node is pmd.Text);
    if (!textOnly) return null;
    return _HeadingRule(
      color: color,
      parts: List.of(_parts),
      paddingBottom: context.sizes.space6,
    );
  }
}

class _HeadingRule extends StatelessWidget {
  const _HeadingRule({
    required this.color,
    required this.parts,
    required this.paddingBottom,
  });

  final Color color;
  final List<Widget> parts;
  final double paddingBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: paddingBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parts,
      ),
    );
  }
}
