# Markdown 段落间距优化

## Goal

Rendered Markdown on the document detail page (and chat answers) shows almost
no visible blank space between paragraphs: `flutter_markdown_plus` defaults
give `pPadding: EdgeInsets.zero` and `blockSpacing: 8.0`, which is only ~2px
larger than the natural line gap of `bodyMedium` (14px font, ~20px line height).
Users perceive paragraphs as glued together. Only code blocks / blockquotes /
tables look separated because their decorations add backgrounds and padding.

## Requirements

- Increase the vertical gap between Markdown text blocks so consecutive
  paragraphs read as clearly separated (target: total inter-paragraph gap of
  roughly 12–16 logical px, comparable to GitHub-style ~1em spacing at body
  size).
- Keep the change in the single shared renderer widget
  `lib/shared/widgets/markdown_content.dart` — document detail page and chat
  must stay visually identical (component-guidelines spec).
- Do not change text sizes, colors, or decorations of headings, code blocks,
  tables, or blockquotes; spacing only.
- Works with `selectable: true` (default) without regressions.

## Acceptance Criteria

- [ ] `MarkdownContent` passes a custom `MarkdownStyleSheet` derived from the
      theme defaults, overriding only paragraph/block spacing.
- [ ] `flutter analyze` passes.
- [ ] Existing tests pass (`flutter test`).
- [ ] No changes outside `lib/shared/widgets/markdown_content.dart` (plus this
      task dir).

## Notes

- Spacing sources stack: inter-block gap = `blockSpacing` + bottom `pPadding`
  of the previous block + top `pPadding` of the next block (builder inserts
  `SizedBox(height: blockSpacing)` between blocks and applies `pPadding` per
  paragraph). Pick values accordingly, don't double up to 24px+.
- Suggested baseline: `blockSpacing: 12.0` and `pPadding:
  EdgeInsets.symmetric(vertical: 2)` → ~16px between paragraphs; verify
  visually on the document detail page.
