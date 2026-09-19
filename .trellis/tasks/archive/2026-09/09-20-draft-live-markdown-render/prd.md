# 草稿生成中实时 Markdown 渲染

## Goal

During draft streaming, render the in-progress content as **live Markdown**
(like chat answers) instead of the raw concatenated JSON text. The raw
deltas are JSON-argument fragments, so a **lenient partial-JSON extractor**
(pure function) incrementally decodes the `content` string out of the
accumulated prefix — tolerating escapes, split `\uXXXX`, key order, and
missing keys — and the shared `MarkdownContent` renders it as it grows. The
terminal `draft` event still settles with the validated result; `error`
still clears everything.

## Background

- Current state (task 09-19-draft-delta-streaming, archived): the generating
  view shows `Text(state.partialContent)` — raw JSON fragments (e.g.
  `{"content": "# 草\n\n正文`, ` "title": null}`) — until the `draft`
  event swaps in the validated review view.
- Chat precedent: answer deltas render live through `MarkdownContent`
  (state-management spec). `partialContent` (raw concatenation) stays the
  transport-level truth; extraction is a **render-time** concern.
- Extraction is needed precisely because the deltas are JSON-argument
  fragments, not plain text: the raw text shows escapes and JSON scaffolding
  the user should never see.

## Requirements

1. **Lenient partial-JSON extractor** (pure function, e.g.
   `String? extractPartialContent(String rawPrefix)` in the operations
   feature or shared utils — no IO, fully unit-testable):
   - Scans the accumulated raw JSON prefix and returns the **decoded so-far
     value of the top-level `content` string**, tolerating: complete or
     truncated input at any byte boundary; JSON escapes (`\"`, `\\`, `\/`,
     `\b`, `\f`, `\n`, `\r`, `\t`); a `\uXXXX` escape split mid-sequence
     (drop the incomplete tail escape, keep the rest); a trailing lone `\`;
     key order (find `content` wherever it is — `title` may come first);
     `content` key not yet present → null; content string fully closed →
     return the complete decoded content (still partial relative to the
     whole draft).
   - Never throws on malformed input → null (caller falls back).
   - Only the top-level `content` key is extracted; occurrences of the text
     `"content"` inside string values must not confuse the scan (walk with
     escape/string-state tracking, not naive substring search).
2. **Generating view**: render `MarkdownContent(data: extracted)` live when
   the extractor yields non-empty text; otherwise (no `content` reached yet)
   keep the spinner + seconds hint only — **do not render the raw JSON
   prefix anywhere**. The old plain-`Text(partialContent)` rendering is
   removed. Height bound + internal scroll still apply (markdown content is
   the tall case — keep/extend the regression pin).
3. **Unchanged**: `partialContent` lifecycle (raw concatenation, generation
   guard, cleared on error / replaced by the validated `draft` result at
   review), failure recovery path, apply/resume/history flows, PopScope,
   keep-alive, zero-calls rules, all providers/repository code.
4. **Tests**:
   - Extractor unit tests: feed a realistic streamed draft **split at every
     single byte** (accumulate incrementally) asserting the extracted
     content is always a valid prefix of the final markdown (mirrors the
     chat parser's byte-split discipline); escapes incl. CJK `\uXXXX`
     split mid-sequence; escaped quotes/`\"content\"` decoys inside the
     value; `title`-first key order; missing `content` → null; malformed
     prefixes → null; complete content → full decode.
   - Widget: during generation with deltas, the live markdown renders
     (e.g. a `#` heading parsed as a heading widget / bold text span —
     markdown-parsed, not raw); spinner+hint kept; raw JSON never visible;
     review still shows the validated draft; error clears.
   - Existing suites green (the old "plain Text partial" assertions are
     intentionally reversed — update them).
5. `flutter analyze` clean; full `flutter test` green.

## Constraints

- No repository/provider/transport changes (extraction is render-time; the
  state keeps the raw concatenation).
- Extraction must be O(prefix) per call with no allocations beyond the
  decoded string (typical drafts are ≤ 50k chars; chat re-renders the same
  way).
- AppSizes/Chinese-copy/const conventions where touched.

## Acceptance Criteria

- [ ] Extractor pure function with the full byte-split/escape/decoy/order
      test matrix; never throws.
- [ ] Generating view renders live markdown from the extracted content;
      raw JSON prefix is never rendered; spinner+hint show before content
      arrives.
- [ ] Terminal semantics unchanged (draft settles the review view; error
      clears); all flows regress none.
- [ ] `flutter analyze` clean; full `flutter test` green.
