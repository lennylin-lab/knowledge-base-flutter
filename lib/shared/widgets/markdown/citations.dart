import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as md;
import 'package:markdown/markdown.dart' as pmd;

import '../../../core/theme/app_sizes.dart';

/// Matches a bare `[n]` citation in answer text.
///
/// The negative lookaheads keep real markdown constructs intact: `[1](url)`
/// (inline link) and `[1][ref]` (reference link) must reach the package's
/// link syntaxes, which run with the defaults. Backslash-escaped `\[1\]` is
/// consumed by the escape handling before this syntax sees the bracket, and
/// inline code spans are tokenized by the code syntax before their inner
/// text is scanned — so neither is ever linkified.
class CitationInlineSyntax extends pmd.InlineSyntax {
  CitationInlineSyntax()
    : super(r'\[([1-9][0-9]{0,2})\](?!\()(?!\[)');

  @override
  bool onMatch(pmd.InlineParser parser, Match match) {
    final index = int.parse(match[1]!);
    parser.addNode(
      pmd.Element('cite', null)..attributes['index'] = '$index',
    );
    return true;
  }
}

/// Builds the `cite` element produced by [CitationInlineSyntax].
///
/// With a [resolver] that maps the 1-based index to a document id, the badge
/// renders accent-colored and tappable ([onTap] receives index + document
/// id). Without a mapping — other surfaces, late/out-of-range indexes — it
/// degrades to the plain `[n]` text, byte-faithful to the source.
class CitationElementBuilder extends md.MarkdownElementBuilder {
  CitationElementBuilder({this.resolver, this.onTap});

  final String? Function(int index)? resolver;
  final void Function(int index, String documentId)? onTap;

  int? _index;

  @override
  void visitElementBefore(pmd.Element element) {
    final raw = element.attributes['index'];
    _index = raw == null ? null : int.tryParse(raw);
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    pmd.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final index = _index;
    _index = null;
    if (index == null) return null;
    final theme = Theme.of(context);
    final documentId = resolver?.call(index);
    if (documentId == null || documentId.isEmpty) {
      return Text('[$index]', style: preferredStyle);
    }
    return _CitationBadge(
      index: index,
      documentId: documentId,
      onTap: onTap,
      style: (preferredStyle ?? theme.textTheme.bodyMedium)?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// One tappable `[n]` citation mark inside the answer flow.
class _CitationBadge extends StatelessWidget {
  const _CitationBadge({
    required this.index,
    required this.documentId,
    required this.onTap,
    required this.style,
  });

  final int index;
  final String documentId;
  final void Function(int index, String documentId)? onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () => onTap!(index, documentId),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sizes.space2),
        child: Text('[$index]', style: style),
      ),
    );
  }
}
