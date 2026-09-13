# Chat tool-call timeline UI

## Goal

Render per-run tool calls in the chat page as a collapsible timeline (tool
name, query, success/failed badge, latency) keyed by `call_id`, replacing the
single tool-failure note.

## Background

The chat client already parses `tool_call_started` / `tool_call_finished`
(`lib/shared/models/chat.dart`), but only surfaces two transient traces: the
progress line (search query) and one warning for the latest failed call
(`ChatState.toolFailure`). Per-call detail the wire already provides — order,
tool name, query, status, `latency_ms` — is not rendered.

## Requirements

1. State: `ChatState` replaces `String? toolFailure` with
   `List<ChatToolCallView> toolCallRows` (named `toolCallRows` — `toolCalls`
   already holds the `done` count) — one entry per call, upserted by
   `call_id` (started creates / updates; finished sets status + latency;
   finished without a started entry appends defensively). Each entry holds
   `callId`, `toolName`, optional `query` (from `search_knowledge` args),
   nullable `status` (null = still running), optional `latencyMs`.
2. UI: new collapsible 「工具调用」 section in the run view (after sources):
   - collapsed subtitle summarizes: `N 次` (+ `· M 次失败` when M > 0);
   - rows in arrival order: tool name (search rows show the query), status
     mark (spinner while running / check / failure mark), `latency_ms` as
     「xxx ms」 when present;
   - failed rows render with the error color; the standalone
     「工具调用 x 失败…」 warning row is removed (timeline supersedes it);
   - visible while running and after done; cleared with the run's fresh
     state (next run / newSession / openSession).
3. Progress line behavior unchanged (search query still drives
   「正在检索：{query}」; status phases still write their lines).
4. Terminal semantics, history commit, sources accumulation untouched.

## Acceptance Criteria

- [ ] Two calls with different `call_id`s (even the same tool) render as two
      rows with correct statuses and latencies.
- [ ] A running call (started, not finished) shows a spinner row; finishing
      updates the same row (upsert by `call_id`).
- [ ] A failed call is visible in the timeline with the error color, run
      still ends `done`.
- [ ] Old `toolFailure` warnings and tests are replaced by the timeline;
      `flutter analyze` clean and all tests pass.
