# Chat run parts chronological rendering

## Goal

Render the chat run view strictly in event arrival order: answer text split
into segments interleaved with rewrite entries and tool-call rows (upserted by
`call_id`), replacing the fixed-position rewrite disclosure (top) and
tool-call section (bottom).

## Problem

`_RunView` renders fixed slots — question, rewrite, progress, answer,
inline sources, tool calls — so process items land at predetermined positions
regardless of when their events arrived. The wire contract allows retrieval
tool calls between `answer_delta` chunks (docs/chat-api.md §5.1), so a
faithful rendering must interleave process entries into the answer text flow
at the point they occurred.

## Design

### State (chat_providers.dart)

- New sealed `ChatRunPart` union with three kinds:
  - `ChatAnswerPart { text }` — one contiguous answer segment;
  - `ChatRewriteEntry { original, rewritten }` — from `query_rewritten`;
  - `ChatToolCallEntry` (the existing `ChatToolCallView`, re-based onto the
    union) — upserted by `call_id` exactly as today (started creates/updates
    in place, finished completes in place, unpaired finished appends).
- `ChatState` replaces the `answer: String`, `rewrite`, `toolCallRows` fields
  with `List<ChatRunPart> parts` (arrival order). `String get answer` becomes
  a derived getter (concatenated answer segments) so history commit,
  `progressText()` gating, and existing assertions keep working.
- Notifier event handling:
  - `answer_delta` → append to the trailing `ChatAnswerPart`, or open a new
    one when the trailing part is a process entry;
  - `query_rewritten` → close the current answer segment, append a
    `ChatRewriteEntry`;
  - `tool_call_started` → close the current answer segment, upsert the call
    entry (progress line behavior unchanged); `tool_call_finished` → update
    in place.
- Terminal/history semantics untouched: a finished run keeps its parts
  rendered until the next run commits the turn (user question + full answer
  text) into history; fresh state on new run / newSession / openSession
  clears parts.

### UI (chat_page.dart)

- `_RunView` iterates `state.parts` in order: `ChatAnswerPart` →
  `MarkdownContent`; `ChatRewriteEntry` → expandable row (same texts and
  interaction as the current `_RewriteSection`); `ChatToolCallEntry` →
  compact row (status icon, tool name + query, latency) adapted from the
  current `_ToolCallsSection` rows.
- The fixed `_RewriteSection` slot and bottom `_ToolCallsSection` wrapper are
  removed; inline sources (narrow), error pane, done summary, progress line,
  and the wide sources panel are unchanged.

## Requirements

1. Strict order: rendered order == event arrival order for all run parts,
   including mid-answer tool calls (their rows appear between answer
   segments).
2. `answer` getter, `progressText()` rules, history commit, citations
   `[n]` → accumulated sources, stale-run guards: unchanged behavior.
3. AppSizes tokens; Chinese-first copy; no new provider state beyond parts.

## Acceptance Criteria

- [ ] Follow-up run `run_started → status(rewriting) → query_rewritten →
      tool_call_started → sources → tool_call_finished → status(generating) →
      answer_delta*` renders: question → 正在理解问题… → rewrite row → tool
      row (running → done with latency) → answer, top-to-bottom in that
      order.
- [ ] A tool call arriving between `answer_delta` chunks renders its row
      between the two answer segments.
- [ ] Two tool calls with distinct `call_id`s render as two rows in arrival
      order; a failed call renders in the error color and the run still ends
      `done`.
- [ ] `flutter analyze` clean; all tests pass (provider tests re-based onto
      parts, widget tests assert the interleaved order).
