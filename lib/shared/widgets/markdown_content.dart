import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as md;
import 'package:markdown/markdown.dart' as pmd;

import '../../core/theme/app_sizes.dart';
import 'markdown/callout.dart';
import 'markdown/code_highlight.dart';
import 'markdown/citations.dart';

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
    this.onTaskToggle,
    this.citationDocumentId,
    this.onCitationTap,
  });

  final String data;
  final bool selectable;

  /// Maps a 1-based `[n]` citation index in [data] to the cited document id.
  /// When null (document pages, AI summaries, history bubbles without
  /// sources) or when the index is unmapped, `[n]` renders as plain text —
  /// never a dead link.
  final String? Function(int citationIndex)? citationDocumentId;

  /// Invoked when a mapped citation badge is tapped. Only effective together
  /// with [citationDocumentId].
  final void Function(int citationIndex, String documentId)? onCitationTap;

  /// Called with the 0-based document-order index of a GFM task-list item
  /// and its new checked state when the user taps its checkbox. When null
  /// (chat answers, AI summaries) every checkbox renders read-only.
  ///
  /// The index counts markers over [data] exactly like
  /// `toggleTaskListItem` in shared/utils/markdown_tasks.dart, so callers
  /// can write the flip back into their source string.
  final void Function(int taskIndex, bool checked)? onTaskToggle;

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
      inlineSyntaxes: [CitationInlineSyntax()],
      // The interactive checkbox itself is built from the task item's
      // `input` element (see builders below); this only silences the
      // package's own static icon bullet so the checkbox isn't doubled.
      checkboxBuilder: (_) => const SizedBox.shrink(),
      builders: {
        // GFM task-list checkboxes: tappable when [onTaskToggle] is set.
        // Registered on `input` — NOT `li`: the package routes every text
        // node of a block tag through that tag's builder `visitText`
        // (default null ⇒ text dropped), while inline tags keep the
        // default text flow. The `input` element also constructs its
        // checkbox at visit time, capturing its document-order task index
        // even inside nested lists.
        'input': _TaskCheckboxBuilder(
          onToggle: onTaskToggle,
          colorScheme: colorScheme,
        ),
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
        // `[n]` answer citations (issue #6): tappable when the caller maps
        // the index to a document; plain text otherwise; see citations.dart.
        'cite': CitationElementBuilder(
          resolver: citationDocumentId,
          onTap: onCitationTap,
        ),
      },
    );
  }
}

/// Builds the interactive checkbox for a GFM task-list item from its
/// `input[type=checkbox]` element. Visits happen in document order (nested
/// lists included), so the checkbox widget is constructed with its own
/// 0-based task index right away — no late lookup that could go stale.
class _TaskCheckboxBuilder extends md.MarkdownElementBuilder {
  _TaskCheckboxBuilder({this.onToggle, required this.colorScheme});

  final ColorScheme colorScheme;
  final void Function(int taskIndex, bool checked)? onToggle;

  int _assigned = 0;
  _PendingTask _pending = (index: 0, checked: false);

  @override
  void visitElementBefore(pmd.Element element) {
    _pending = (
      index: _assigned++,
      checked: element.attributes.containsKey('checked'),
    );
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    pmd.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final task = _pending;
    return _TaskCheckbox(
      key: ValueKey('task-checkbox-${task.index}'),
      checked: task.checked,
      taskIndex: task.index,
      colorScheme: colorScheme,
      onToggle: onToggle,
    );
  }
}

typedef _PendingTask = ({int index, bool checked});

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({
    super.key,
    required this.checked,
    required this.taskIndex,
    required this.colorScheme,
    this.onToggle,
  });

  final bool checked;
  final int taskIndex;
  final ColorScheme colorScheme;

  /// Null in read-only surfaces (chat answers, AI summaries): the box still
  /// renders at full strength, it just doesn't respond to taps.
  final void Function(int taskIndex, bool checked)? onToggle;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return Padding(
      // Small gap between the box and the item text inside the line Wrap.
      padding: EdgeInsetsDirectional.only(end: sizes.space6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle == null
            ? null
            : () => onToggle!(taskIndex, !checked),
        child: SizedBox(
          width: sizes.space24,
          height: sizes.space24,
          child: Center(
            child: Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: sizes.iconMd,
              // Checked boxes take the primary; unchecked stay quiet but at
              // full strength so read-only views don't render washed-out
              // "disabled" boxes.
              color: checked ? colorScheme.primary : colorScheme.outline,
            ),
          ),
        ),
      ),
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
