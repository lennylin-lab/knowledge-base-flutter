/// GFM task-list (`- [ ]` / `- [x]`) source scanning and toggling.
///
/// The renderer counts task checkboxes in document order (see
/// `MarkdownContent.onTaskToggle`), so write-back needs to find the same
/// Nth marker in the source. These regexes mirror what package:markdown
/// actually parses (`listPattern` + its `^ {0,3}\[([ xX])\][ \t]` item
/// check, and `CalloutBlockSyntax` in shared/widgets/markdown/callout.dart)
/// so that counted source markers match rendered checkboxes:
///
/// - front matter is skipped (detail view renders the stripped body);
/// - fenced code blocks are skipped;
/// - callout bodies (`> [!type]` blocks) are skipped — the callout renders
///   them through a nested MarkdownContent whose checkboxes are read-only;
/// - plain blockquote layers are stripped before matching, because the
///   blockquote parser re-parses its inner lines in the same renderer.
library;

/// One task marker located in the source: the `[ ]`/`[x]` bracket content
/// spans absolute columns [start]..[end] on [line], [checked] its state.
typedef TaskMarker = ({int line, int start, int end, bool checked});

/// Task-item line: 0–3 leading spaces, `-`/`*`/`+` or `N.`/`N)` marker,
/// whitespace, 0–3 spaces, the checkbox bracket, then whitespace — the
/// same shape package:markdown requires before it flags a task item.
final RegExp _taskLinePattern = RegExp(
  r'^[ ]{0,3}(?:\d{1,9}[.)]|[*+-])[ \t]+[ ]{0,3}\[([ xX])\][ \t]',
);

/// Fenced code boundary: any 3+ backtick or tilde run. The closing-fence
/// length rule (≥ opener) is simplified to "same char" — close enough for
/// marker counting, and a shorter run never falsely closes.
final RegExp _fencePattern = RegExp(r'^ {0,3}(`{3,}|~{3,})');

/// Callout opener, matching `CalloutBlockSyntax.pattern` up to the type.
final RegExp _calloutMarkerPattern = RegExp(r'^ {0,3}> ?\[!');

/// One blockquote layer on a raw line (same shape as the callout syntax).
final RegExp _quoteLayerPattern = RegExp(r'^ {0,3}>[ \t]?');

/// A line that still belongs to some blockquote region.
final RegExp _quotedLinePattern = RegExp(r'^ {0,3}>');

/// Char offset where the body after a YAML front matter block starts —
/// mirrors [stripYamlFrontMatter] (shared/utils/markdown_front_matter.dart)
/// so markers are counted over exactly the text the detail view renders.
int _bodyStartOffset(String markdown) {
  if (!markdown.startsWith('---\n')) return 0;
  final closing = markdown.indexOf('\n---\n', 4);
  return closing == -1 ? markdown.length : closing + '\n---\n'.length;
}

/// Locates every task marker the renderer would show as a checkbox, in
/// document order.
Iterable<TaskMarker> _scanTaskMarkers(String markdown) sync* {
  final lines = markdown.split('\n');
  final bodyStart = _bodyStartOffset(markdown);
  var consumed = 0;
  var fenceChar = '';
  var inFence = false;
  var inCallout = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineStart = consumed;
    consumed += line.length + 1;
    if (lineStart < bodyStart) continue; // YAML front matter line

    final fence = _fencePattern.firstMatch(line);
    if (inFence) {
      if (fence != null && fence.group(1)!.startsWith(fenceChar)) {
        inFence = false;
      }
      continue;
    }
    if (fence != null) {
      inFence = true;
      fenceChar = fence.group(1)![0];
      continue;
    }

    if (inCallout && !_quotedLinePattern.hasMatch(line)) {
      inCallout = false; // callout body ends at the first unquoted line
    }
    if (inCallout) continue;

    // A callout can also open one blockquote layer deeper (`> > [!note]`);
    // check the quote-stripped content so its body gets skipped too.
    final content = _stripQuoteLayers(line);
    if (_calloutMarkerPattern.hasMatch(line) ||
        _calloutMarkerPattern.hasMatch(content)) {
      inCallout = true;
      continue;
    }

    final match = _taskLinePattern.firstMatch(content);
    if (match == null) continue;
    // Dart's RegExpMatch exposes no group spans; the checkbox `[` is the
    // first bracket after the marker, so locate it structurally — nothing
    // before it in a matched line (spaces, `-`/`*`/`+`, digits, `.`/`)`)
    // can contain a `[`.
    final quoteWidth = line.length - content.length;
    final bracket = quoteWidth + content.indexOf('[', match.start) + 1;
    yield (
      line: i,
      start: bracket,
      end: bracket + 1,
      checked: match.group(1) != ' ',
    );
  }
}

String _stripQuoteLayers(String line) {
  var content = line;
  var match = _quoteLayerPattern.firstMatch(content);
  while (match != null) {
    content = content.substring(match.end);
    match = _quoteLayerPattern.firstMatch(content);
  }
  return content;
}

/// Flips the [taskIndex]-th (0-based, document order) task marker in
/// [markdown] — `[ ]` becomes `[x]`, `[x]`/`[X]` become `[ ]` — and returns
/// the updated source. Returns null when [markdown] has fewer than
/// [taskIndex] + 1 markers.
String? toggleTaskListItem(String markdown, int taskIndex) {
  if (taskIndex < 0) return null;
  final lines = markdown.split('\n');
  var seen = 0;
  for (final marker in _scanTaskMarkers(markdown)) {
    if (seen++ != taskIndex) continue;
    // Uncheck preserves the source as a plain `[ ]`; checking always
    // writes lowercase `[x]`.
    lines[marker.line] = lines[marker.line].replaceRange(
      marker.start,
      marker.end,
      marker.checked ? ' ' : 'x',
    );
    return lines.join('\n');
  }
  return null;
}
