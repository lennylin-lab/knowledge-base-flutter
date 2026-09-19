# Clickable citation links in chat answers

Implements issue #6 (Chat 回答中的 [n] 引用支持点击跳转到对应文档).

## Goal

In chat assistant answers, render `[n]` citations as tappable marks that
navigate to the cited document (`/documents/{document_id}`), using the run's
accumulated `sources` list as the index → documentId mapping. No backend
change; unmapped `[n]` stays plain text; streaming behaves correctly.

## Design

- **Custom inline syntax + element builder** in the shared renderer
  (`MarkdownContent`), not raw-text regex: package:markdown tokenizes inline
  code spans (`[1]` in backticks) before scanning inner text, so code-span
  citations are never linkified; real links (`[1](url)`, `[t][ref]`) are
  protected with a negative lookahead (`\[(\d{1,3})\](?!\(|\[)`), and
  reference definitions are stripped before inline parsing.
- Syntax (registered always): matches a bare `[n]` and emits a void `cite`
  element carrying the index in its attributes. Builder (registered always):
  - resolver (optional `String? Function(int index)`) returns a documentId →
    tappable badge: accent-colored `[$n]` with a tap callback;
  - resolver null / returns null (document pages, AI summaries, history
    bubbles, index out of range) → plain text `[$n]`, byte-faithful.
- `MarkdownContent` gains optional `citationDocumentId` + `onCitationTap`
  params; all existing call sites unchanged (citations stay plain text
  there). Only the chat run view passes the resolver built from
  `state.sources` (1-based, `n <= sources.length`) and pushes
  `/documents/{id}` on tap.
- **Streaming**: the whole answer re-renders per event and the resolver is
  consulted at build time, so citations arriving before their sources
  (contract allows extra `sources` batches mid-answer) linkify as soon as the
  mapping exists — no manual re-render hook.
- History bubbles pass no resolver (persisted messages carry no sources —
  citations there stay plain text, per the established semantics).

## Requirements

1. Shared renderer change is additive and opt-in per surface; document detail
   and AI-summary rendering byte-identical to today.
2. Code spans / fenced code containing `[n]` never become links; real
   markdown links are untouched.
3. Tap navigation uses the existing go_router route (citation badge and
   sources-panel tile behave identically).
4. AppSizes tokens for badge sizing/spacing; badge style follows link-ish
   accent (primary color), no underline in code contexts (never applies
   there anyway).

## Acceptance Criteria

- [ ] Renderer test: `[1]`/`[2]` with a resolver render tappable badges and
      invoke the callback with the mapped documentId; `[3]` beyond the map
      renders plain; `` `[1]` `` inside inline code renders as code, not a
      link; a real link `[1](https://x)` is unaffected.
- [ ] Chat page test: streaming answer with `[1]` + sources event — tapping
      the `[1]` badge pushes `/documents/{id}`.
- [ ] Document detail page / AI bubble unaffected (no resolver → plain text).
- [ ] `flutter analyze` clean; all tests pass.
