/// Obsidian-style callouts (`> [!type] Title`), rendered with a type icon,
/// colored background/border and an optional fold interaction.
///
/// Pipeline: [CalloutBlockSyntax] (registered before the built-in blockquote
/// syntax) consumes the marker line and the `>`-quoted body, normalizes the
/// type via the canonical table + alias map, and exposes everything as
/// attributes of a self-closing `callout` element. [CalloutElementBuilder]
/// turns that element into a [CalloutCard]; the inner markdown body is
/// rendered through a nested [MarkdownContent] so embedded markdown, nested
/// callouts and code highlighting all reuse the app's single renderer
/// configuration. (The element builder API of flutter_markdown_plus has no
/// access to the already-built child widgets of a block element, which is
/// why the body travels as raw markdown in the `data` attribute instead of
/// as parsed child nodes.)
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/theme/app_sizes.dart';
import '../markdown_content.dart';

/// Fold behavior requested via the marker suffix: `+` expanded, `-`
/// collapsed, no suffix → the callout cannot be folded at all.
enum CalloutFold { collapsed, expanded, none }

/// Visual + copy specification of one canonical callout type.
class CalloutSpec {
  const CalloutSpec({
    required this.id,
    required this.icon,
    required this.lightColor,
    required this.darkColor,
    required this.defaultTitle,
  });

  final String id;
  final IconData icon;

  /// Obsidian default-theme callout colors, per brightness.
  final Color lightColor;
  final Color darkColor;
  final String defaultTitle;

  Color colorFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkColor : lightColor;
}

// Obsidian canonical callout types with their default-theme colors
// (obsidian.md/help/callouts). Material icon approximations of the Lucide
// glyphs, chosen by type semantics; Chinese default titles follow the
// app's Chinese-first copy convention.
const Map<String, CalloutSpec> _kCalloutSpecs = {
  'note': CalloutSpec(
    id: 'note',
    icon: Icons.sticky_note_2_outlined,
    lightColor: Color(0xff086ddd),
    darkColor: Color(0xff4886f6),
    defaultTitle: '备注',
  ),
  'abstract': CalloutSpec(
    id: 'abstract',
    icon: Icons.format_list_bulleted,
    lightColor: Color(0xff00bfbc),
    darkColor: Color(0xff27c3bf),
    defaultTitle: '摘要',
  ),
  'info': CalloutSpec(
    id: 'info',
    icon: Icons.info_outline,
    lightColor: Color(0xff086ddd),
    darkColor: Color(0xff4886f6),
    defaultTitle: '信息',
  ),
  'todo': CalloutSpec(
    id: 'todo',
    icon: Icons.check_circle_outline,
    lightColor: Color(0xff086ddd),
    darkColor: Color(0xff4886f6),
    defaultTitle: '待办',
  ),
  'tip': CalloutSpec(
    id: 'tip',
    icon: Icons.local_fire_department_outlined,
    lightColor: Color(0xff00bfbc),
    darkColor: Color(0xff27c3bf),
    defaultTitle: '提示',
  ),
  'success': CalloutSpec(
    id: 'success',
    icon: Icons.check_circle_outline,
    lightColor: Color(0xff08b951),
    darkColor: Color(0xff09c957),
    defaultTitle: '成功',
  ),
  'question': CalloutSpec(
    id: 'question',
    icon: Icons.help_outline,
    lightColor: Color(0xffe0ac00),
    darkColor: Color(0xffe6b71c),
    defaultTitle: '问题',
  ),
  'warning': CalloutSpec(
    id: 'warning',
    icon: Icons.warning_amber_outlined,
    lightColor: Color(0xffec7500),
    darkColor: Color(0xfff08616),
    defaultTitle: '警告',
  ),
  'failure': CalloutSpec(
    id: 'failure',
    icon: Icons.cancel_outlined,
    lightColor: Color(0xffe93147),
    darkColor: Color(0xfffd5469),
    defaultTitle: '失败',
  ),
  'danger': CalloutSpec(
    id: 'danger',
    icon: Icons.bolt_outlined,
    lightColor: Color(0xffe93147),
    darkColor: Color(0xfffd5469),
    defaultTitle: '危险',
  ),
  'bug': CalloutSpec(
    id: 'bug',
    icon: Icons.bug_report_outlined,
    lightColor: Color(0xffe93147),
    darkColor: Color(0xfffd5469),
    defaultTitle: '缺陷',
  ),
  'example': CalloutSpec(
    id: 'example',
    icon: Icons.format_list_numbered,
    lightColor: Color(0xff7852ee),
    darkColor: Color(0xffa282ff),
    defaultTitle: '示例',
  ),
  'quote': CalloutSpec(
    id: 'quote',
    icon: Icons.format_quote_outlined,
    lightColor: Color(0xff808080),
    darkColor: Color(0xff9e9e9e),
    defaultTitle: '引用',
  ),
};

// Obsidian type aliases (lowercase → canonical id).
const Map<String, String> _kCalloutAliases = {
  'summary': 'abstract',
  'tldr': 'abstract',
  'hint': 'tip',
  'important': 'tip',
  'check': 'success',
  'done': 'success',
  'help': 'question',
  'faq': 'question',
  'caution': 'warning',
  'attention': 'warning',
  'fail': 'failure',
  'missing': 'failure',
  'error': 'danger',
  'cite': 'quote',
};

/// Resolves a type id to its spec; unknown ids degrade to the neutral note
/// look (Obsidian renders unknown types the same way).
CalloutSpec calloutSpecFor(String type) =>
    _kCalloutSpecs[type] ?? _kCalloutSpecs['note']!;

String _humanizeType(String type) =>
    type.isEmpty ? type : '${type[0].toUpperCase()}${type.substring(1)}';

/// Block syntax for Obsidian callout markers.
///
/// Registered ahead of the built-in [md.BlockquoteSyntax] (custom
/// `blockSyntaxes` precede the extension-set defaults in markdown's
/// [md.Document]), so plain `> text` quotes still take the stock path.
class CalloutBlockSyntax extends md.BlockSyntax {
  /// Marker: `> [!type]`, `> [!type]-`, `> [!type]+`, optionally followed
  /// by ` Title`. Requires a space before a trailing title, like Obsidian.
  @override
  RegExp get pattern => _markerPattern;

  static final RegExp _markerPattern = RegExp(
    r'^ {0,3}> ?\[!(\w+)\]([+-])?( .*)?$',
  );

  // One blockquote layer on continuation lines: up to 3 spaces, `>`, then
  // an optional space or tab.
  static final RegExp _quotePrefixPattern = RegExp(r'^ {0,3}>[ \t]?');

  const CalloutBlockSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final match = _markerPattern.firstMatch(parser.current.content)!;
    final rawType = match.group(1)!.toLowerCase();
    final foldMarker = match.group(2);
    final explicitTitle = match.group(3)?.trim();

    final canonicalType = _kCalloutAliases[rawType] ?? rawType;
    final spec = _kCalloutSpecs[canonicalType];

    // Collect the quoted body, stripping exactly one blockquote layer.
    final childLines = <md.Line>[];
    parser.advance();
    while (!parser.isDone) {
      final prefix = _quotePrefixPattern.firstMatch(parser.current.content);
      if (prefix == null) break;
      childLines.add(md.Line(parser.current.content.substring(prefix.end)));
      parser.advance();
    }

    final element = md.Element.empty('callout');
    element.attributes['type'] = canonicalType;
    element.attributes['fold'] = switch (foldMarker) {
      '-' => CalloutFold.collapsed.name,
      '+' => CalloutFold.expanded.name,
      _ => CalloutFold.none.name,
    };
    element.attributes['title'] =
        (explicitTitle == null || explicitTitle.isEmpty)
        ? spec?.defaultTitle ?? _humanizeType(rawType)
        : explicitTitle;
    if (childLines.isNotEmpty) {
      element.attributes['data'] = childLines
          .map((line) => line.content)
          .join('\n');
    }
    return element;
  }
}

/// Builds the [CalloutCard] for `callout` elements.
class CalloutElementBuilder extends MarkdownElementBuilder {
  CalloutElementBuilder({this.selectable = true});

  /// Mirrors `MarkdownBody.selectable` for the nested content renderer.
  final bool selectable;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return CalloutCard(
      type: element.attributes['type'] ?? 'note',
      title: element.attributes['title'] ?? '',
      fold: switch (element.attributes['fold']) {
        'collapsed' => CalloutFold.collapsed,
        'expanded' => CalloutFold.expanded,
        _ => CalloutFold.none,
      },
      content: element.attributes['data'] ?? '',
      selectable: selectable,
    );
  }
}

/// The callout chrome: colored tinted card with a left accent bar, a header
/// (type icon + title + chevron) and the markdown body.
class CalloutCard extends StatefulWidget {
  const CalloutCard({
    super.key,
    required this.type,
    required this.title,
    required this.fold,
    this.content = '',
    this.selectable = true,
  });

  final String type;
  final String title;
  final CalloutFold fold;

  /// Raw markdown body (one blockquote layer already stripped).
  final String content;
  final bool selectable;

  @override
  State<CalloutCard> createState() => _CalloutCardState();
}

class _CalloutCardState extends State<CalloutCard> {
  late bool _expanded = widget.fold != CalloutFold.collapsed;

  bool get _foldable => widget.fold != CalloutFold.none;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    final spec = calloutSpecFor(widget.type);
    final color = spec.colorFor(Theme.of(context).brightness);

    final header = Row(
      children: [
        Icon(spec.icon, size: sizes.iconMd, color: color),
        SizedBox(width: sizes.space8),
        Expanded(
          child: Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color),
          ),
        ),
        if (_foldable)
          AnimatedRotation(
            turns: _expanded ? 0 : -0.25,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: sizes.iconMd,
              color: color,
            ),
          ),
      ],
    );

    final content = AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !_foldable || _expanded
          ? Padding(
              // Horizontal inset comes from the Stack's outer padding.
              padding: EdgeInsets.only(bottom: sizes.space8),
              child: widget.content.isEmpty
                  ? const SizedBox.shrink()
                  : MarkdownContent(
                      data: widget.content,
                      selectable: widget.selectable,
                    ),
            )
          : const SizedBox(width: double.infinity),
    );

    // Layout note: flutter_markdown_plus places block-builder results inside
    // a Wrap that hands down unbounded height, so a stretch-Row accent bar
    // cannot be used here — a position-filled accent inside a Stack sizes to
    // the content instead.
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(sizes.radiusSm),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            // 3px left accent stroke — a fixed-width stroke, same class as
            // BorderSide defaults, not an AppSizes spacing metric.
            start: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: ColoredBox(color: color),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: sizes.space12 + 3,
              end: sizes.space12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _foldable
                    ? InkWell(
                        onTap: _toggle,
                        child: ConstrainedBox(
                          // ≥ 48dp touch-target floor for the fold header.
                          constraints: BoxConstraints(minHeight: sizes.space48),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: sizes.space8,
                            ),
                            child: header,
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.space8),
                        child: header,
                      ),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
