import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:re_highlight/languages/all.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/github-dark.dart';
import 'package:re_highlight/styles/github.dart';

/// Element builder for fenced code blocks, registered under the `pre` tag.
///
/// `pre` is intercepted (instead of `code`) so that *inline* code spans —
/// which the markdown parser also emits as `Element('code')` — keep their
/// normal inline rendering. For fenced/indented code the parser produces
/// `pre > code`, with the fenced info string stored as
/// `code.attributes['class'] = 'language-<lang>'` (markdown >= 7.x).
///
/// The raw source arrives through [visitText]; tokens are colored with
/// `re_highlight` (highlight.js grammars, pure Dart). Unknown or undeclared
/// languages fall back to a single monochrome span. The token palette
/// follows [brightness] (GitHub Light / GitHub Dark).
class HighlightedCodeBlockBuilder extends MarkdownElementBuilder {
  HighlightedCodeBlockBuilder({
    required this.brightness,
    this.selectable = true,
    this.padding = EdgeInsets.zero,
  });

  /// Theme brightness selecting the token palette (AC4: follows
  /// `Theme.of(context).brightness`, resolved by `MarkdownContent`).
  final Brightness brightness;

  /// Mirrors `MarkdownBody.selectable` so code stays text-selectable there.
  final bool selectable;

  /// Horizontal scroll padding inside the code block; pass
  /// `styleSheet.codeblockPadding` to keep the package's default look.
  final EdgeInsetsGeometry padding;

  String? _language;

  static Highlight? _highlighter;

  @override
  bool isBlockElement() => true;

  @override
  void visitElementBefore(md.Element element) {
    _language = _readLanguage(element);
  }

  /// Reads the language from the child `code` element's
  /// `class="language-<lang>"` attribute; absent for plain fenced blocks.
  static String? _readLanguage(md.Element element) {
    final List<md.Node>? children = element.children;
    if (children == null || children.isEmpty) return null;
    final md.Node first = children.first;
    if (first is! md.Element || first.tag != 'code') return null;
    final Object? cssClass = first.attributes['class'];
    if (cssClass is! String) return null;
    for (final String token in cssClass.split(' ')) {
      const prefix = 'language-';
      if (token.startsWith(prefix) && token.length > prefix.length) {
        return token.substring(prefix.length);
      }
    }
    return null;
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    return _HighlightedCodeView(
      source: text.text,
      language: _language,
      baseStyle: preferredStyle,
      brightness: brightness,
      selectable: selectable,
      padding: padding,
    );
  }
}

/// Highlighted code content: horizontally scrollable selectable rich text.
class _HighlightedCodeView extends StatefulWidget {
  const _HighlightedCodeView({
    required this.source,
    required this.language,
    required this.baseStyle,
    required this.brightness,
    required this.selectable,
    required this.padding,
  });

  final String source;
  final String? language;
  final TextStyle? baseStyle;
  final Brightness brightness;
  final bool selectable;
  final EdgeInsetsGeometry padding;

  @override
  State<_HighlightedCodeView> createState() => _HighlightedCodeViewState();
}

class _HighlightedCodeViewState extends State<_HighlightedCodeView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextSpan span = highlightCodeSpan(
      source: widget.source,
      language: widget.language,
      baseStyle: widget.baseStyle,
      brightness: widget.brightness,
    );
    final Widget content = widget.selectable
        ? SelectableText.rich(span)
        : Text.rich(span);
    // Horizontal scroll (with thumb on desktop) mirrors the package's own
    // `pre` handling so long lines overflow instead of soft-wrapping.
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: content,
      ),
    );
  }
}

/// Maps [source] to a colored [TextSpan] using the highlight.js grammar for
/// [language]; unknown/undeclared languages yield a monochrome span.
TextSpan highlightCodeSpan({
  required String source,
  required String? language,
  required TextStyle? baseStyle,
  required Brightness brightness,
}) {
  final Map<String, TextStyle> theme = brightness == Brightness.dark
      ? githubDarkTheme
      : githubTheme;
  // Fallback foreground from the palette's own root color so plain code and
  // highlighted code share one visual baseline per theme.
  final Color foreground =
      theme['root']?.color ??
      (brightness == Brightness.dark
          ? const Color(0xffc9d1d9)
          : const Color(0xff24292e));
  // Rebuild the geometry-only base: `styles['code']` carries the monospace
  // font plus an inline-code background that would double-paint under the
  // codeblock decoration.
  final TextStyle base = TextStyle(
    color: foreground,
    fontFamily: baseStyle?.fontFamily ?? 'monospace',
    fontFamilyFallback: baseStyle?.fontFamilyFallback,
    fontSize: baseStyle?.fontSize,
    height: baseStyle?.height,
    letterSpacing: baseStyle?.letterSpacing,
  );

  final String? lang = language?.trim();
  if (lang == null || lang.isEmpty) {
    return TextSpan(text: source, style: base);
  }

  try {
    final Highlight highlighter = _ensureHighlighter();
    // getLanguage covers aliases (py, golang, c++, yml, ...); parse throws
    // on unknown languages, so resolve first and degrade gracefully.
    if (highlighter.getLanguage(lang) == null) {
      return TextSpan(text: source, style: base);
    }
    final HighlightResult result = highlighter.highlight(
      code: source,
      language: lang,
    );
    final TextSpanRenderer renderer = TextSpanRenderer(base, theme);
    result.render(renderer);
    return renderer.span ?? TextSpan(text: source, style: base);
  } catch (_) {
    // Safe mode already swallows grammar errors; this is a last resort so a
    // highlighter bug can never take down document rendering.
    return TextSpan(text: source, style: base);
  }
}

Highlight _ensureHighlighter() {
  // Registered lazily on first code block; grammars themselves compile
  // on-demand per language at parse time.
  return HighlightedCodeBlockBuilder._highlighter ??= Highlight()
    ..registerLanguages(builtinAllLanguages);
}
