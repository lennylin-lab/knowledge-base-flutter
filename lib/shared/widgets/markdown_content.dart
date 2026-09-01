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
    return md.MarkdownBody(data: data, selectable: selectable);
  }
}
