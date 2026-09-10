import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as md;

/// The app's single Markdown renderer configuration — the document detail
/// page and chat answers must render identically (component-guidelines
/// spec). Uses `flutter_markdown_plus` (`flutter_markdown` is
/// discontinued).
class MarkdownContent extends StatelessWidget {
  const MarkdownContent({super.key, required this.data, this.selectable = true});

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    // Default extension set is GitHub-flavored Markdown.
    final baseStyle = md.MarkdownStyleSheet.fromTheme(Theme.of(context));
    return md.MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: baseStyle.copyWith(
        // Package defaults (pPadding zero + blockSpacing 8) leave consecutive
        // paragraphs only ~2px apart beyond the body line gap, so text reads
        // as one wall. pPadding stacks on top of blockSpacing: 2 + 12 + 2.
        pPadding: const EdgeInsets.symmetric(vertical: 2),
        blockSpacing: 12,
      ),
    );
  }
}
