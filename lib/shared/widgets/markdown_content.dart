import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as md;

import 'markdown/callout.dart';
import 'markdown/code_highlight.dart';

/// The app's single Markdown renderer configuration — the document detail
/// page and chat answers must render identically (component-guidelines
/// spec). Uses `flutter_markdown_plus` (`flutter_markdown` is
/// discontinued).
class MarkdownContent extends StatelessWidget {
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
    return md.MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: baseStyle.copyWith(
        // Package defaults (pPadding zero + blockSpacing 8) leave consecutive
        // paragraphs only ~2px apart beyond the body line gap, so text reads
        // as one wall. pPadding stacks on top of blockSpacing: 2 + 14 + 2.
        pPadding: const EdgeInsets.symmetric(vertical: 2),
        blockSpacing: 14,
      ),
      blockSyntaxes: const [CalloutBlockSyntax()],
      builders: {
        // Fenced code blocks: token-level syntax highlighting that follows
        // the theme brightness; see code_highlight.dart.
        'pre': HighlightedCodeBlockBuilder(
          brightness: brightness,
          selectable: selectable,
          padding: baseStyle.codeblockPadding ?? EdgeInsets.zero,
        ),
        // Obsidian callouts with optional folding; see callout.dart.
        'callout': CalloutElementBuilder(selectable: selectable),
      },
    );
  }
}
