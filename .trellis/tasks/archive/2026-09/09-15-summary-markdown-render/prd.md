# 摘要结果 Markdown 渲染

## Goal

Render the AI summary result in the assistant bubble through the shared
`MarkdownContent` widget instead of a bare `Text` — same rendering pipeline
as the detail body and chat answers. The source text itself is untouched
(still rendered verbatim, never translated/trimmed); association tiles and
their `reason` stay compact plain text (user-confirmed scope).

## Background

- `lib/features/documents/document_ai_bubble.dart` currently renders the
  summary result with a bare `Text(result.summary)` ("原文呈现").
- `MarkdownContent` (`lib/shared/widgets/markdown_content.dart`) is the
  project's single configured renderer (component-guidelines: detail body
  and chat answers must render identically through it; fenced-code
  highlighting and callouts are configured inside it).
- Generated summaries contain no YAML front matter — no stripping needed
  (unlike the detail body).

## Requirements

1. Summary result branch in the bubble renders
   `MarkdownContent(data: result.summary)`; the 「{model} · {latency}」
   caption and 重新生成 action stay as-is.
2. Nothing else changes: associations layer (title/tags/reason plain text),
   progress/error states, provider/repository layers untouched.
3. The summary markdown lives inside the bubble's scrollable content layer —
   the height-bound and internal-scroll regression tests must keep passing.
4. Tests: update the bubble/fab tests that pin the summary text —
   `find.text(<exact summary>)` becomes markdown-tolerant
   (`find.textContaining` on a distinctive substring or the same
   span-aware matcher style the chat answer tests use). All other flows
   regress none.
5. `flutter analyze` clean; full `flutter test` green.

## Acceptance Criteria

- [ ] Summary result renders through the shared `MarkdownContent` pipeline
      (source text unchanged, verbatim).
- [ ] Associations layer unchanged; progress/error states unchanged.
- [ ] Height-bound / internal-scroll regression tests still pass; full
      suite green; analyze clean.
