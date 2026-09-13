# Chat SSE progress events

## Goal

Adapt the Flutter chat client to the four new SSE progress events
(`status`, `query_rewritten`, `tool_call_started`, `tool_call_finished`)
with full UI integration, per `docs/chat-api.md` and the server source of
truth `knowledge-base-server/src/app/schemas/chat.py`.

## Contract (new events, all non-terminal)

- `status` → `{phase: "rewriting_query" | "generating"}` — informational
  phase progress; never replaces `done`/`error`.
- `query_rewritten` → `{original, rewritten, applied, changed}` — emitted
  only when rewrite ran and changed the text; history keeps the original
  question.
- `tool_call_started` → `{call_id, tool_name, args: {query, limit?}}` —
  precedes its `sources` batch.
- `tool_call_finished` → `{call_id, tool_name, status: "success"|"failed",
  latency_ms}` — `failed` is non-fatal (run may still `done`).

Ordering / compatibility rules that constrain the client:

- Unknown event names must stay ignorable (parser already does).
- Terminal semantics unchanged: `done`/`error` end the stream; nothing after.
- `sources` carry-forward: first batch of a follow-up may replay the previous
  run's hits — existing per-run append/accumulate already complies (numbering
  restarts per run).

## Requirements

1. Models: four new freezed DTOs on the sealed `ChatEvent` union in
   `shared/models/chat.dart`, snake_case mapping, exact payloads above.
2. Parser: map the four new event names in `SseChatParser._dispatch`; they
   are non-terminal; unknown names stay ignored.
3. State: `ChatNotifier` handles the events into UI-friendly fields:
   - a live progress line (rewriting / searching `{query}` / generating) that
     shows while the run is in flight and clears when the answer streams or
     the run ends;
   - the rewrite pair (`original` → `rewritten`) for transparency UI;
   - tool failure info (non-fatal note) surfaced at most for the latest
     failed call.
4. UI (chat page, full integration per doc §9):
   - progress row text driven by the events: `status(rewriting_query)` →
     「正在理解问题…」, `tool_call_started(search_knowledge)` →
     「正在检索：{query}」, `status(generating)` → 「正在生成回答…」;
   - `query_rewritten` rendered as a collapsible disclosure (original →
     rewritten), cleared with the run state;
   - `tool_call_finished(failed)` → small non-fatal warning text; success
     finishes silently;
   - existing phase machine (`idle → running → streaming → done | error`),
     sources accumulation, citation numbering, and stale-run guards
     unchanged.
5. History/turn semantics untouched: committed turns keep the original
   question text (server persists originals); progress/rewrite/tool state is
   per-run and resets on `newSession`/`openSession`/new run.

## Acceptance Criteria

- [ ] Parser emits typed events for the four new names and still ignores
      unknown names, garbage frames, and post-terminal frames.
- [ ] Follow-up run with rewrite + retrieval renders: 正在理解问题… →
      rewritten-query disclosure → 正在检索：{query} → 正在生成回答… →
      streamed answer, terminal summary unchanged.
- [ ] A failed tool call shows a non-fatal warning and does not turn the run
      into an error.
- [ ] `flutter analyze` clean; all tests pass (parser/provider/widget tests
      extended for the new events).
