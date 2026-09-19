# draft 流逐字增量对接（issue #4 评论）

## Goal

Adopt the contract update from the issue #4 comment (2026-09-19, server
`09-19-draft-delta-stream` / HEAD `0a5832c`): the draft stream now emits
**verbatim incremental deltas** before the terminal events —

```
run_started → draft_delta* → draft → done        (success)
run_started → draft_delta* → error               (failure; exactly one
                                                  terminal error, no done)
```

`draft_delta` payload: `{run_id, delta}` where `delta` is a **raw JSON
fragment** of the model's structured-output tool-call arguments — forwarded
in provider order, no duplication/omission; their sum equals the final
argument JSON exactly. The server never parses partial JSON; the client
**concatenates for process display only** (no incremental parsing). The
`draft` event still carries the validated complete result and remains the
authoritative settle; on `error` the concatenated partial is discarded.

## Background / Evidence

- Server-verified: `DraftDeltaEvent{run_id: str, delta: str}`
  (`schemas/agent_stream.py:65-77`), event name `draft_delta`
  (`endpoints/operations.py:48`), contract order
  (`services/operation.py:350`). Everything else from task
  `09-17-draft-sse-alignment` stands (priming 404/503 envelopes, terminal
  error → persisted `failed` + `/resume` recovery, no silent apply,
  `OperationDraftResult` fold, history-surfaced recovery, auth header via
  `agentStreamClientProvider`).
- Gateway 60s whole-request deadline still exists (separate task): very
  long generations may be cut into an `error` event — the existing error
  path covers it; nothing new to build.

## Requirements

1. **Event model** (`agents_stream.dart`): add
   `AgentDraftDeltaEvent{runId, delta}` to the sealed union (+ codegen);
   parser maps the `draft_delta` event name. `delta` is opaque raw text —
   never parsed or validated client-side.
2. **Repository**: `draft({documentId, instruction, onDelta})` — forward
   each `draft_delta`'s `delta` string through `onDelta` in wire order
   (mirrors the summary `onProgress` threading inside the shared
   `AgentStreamClient.fold`). The fold still settles on the `draft` event
   (`OperationDraftResult`) and maps failures exactly as today. Raw
   deltas/concatenation never touch the result type.
3. **Writing state machine** (`WritingState`): add a display-only
   `partialContent` (String?) for the concatenation:
   - `generate` accumulates `onDelta` chunks into it under the existing
     workflow generation guard (stale generations drop their deltas;
     latest-wins rendering);
   - terminal `draft` → phase review (the validated result replaces the
     partial — partial cleared);
   - terminal `error` → partial cleared (issue: 丢弃已拼接的部分内容) and
     the existing failure path runs (error copy + history auto-load/refresh
     with the failed op);
   - superseded generation (`clearCurrent`/re-generate) drops both the
     accumulation and any in-flight deltas.
4. **UI**: the generating view renders the accumulating raw text live
   (plain text — it is raw JSON fragments, NOT markdown; keep the spinner +
   seconds hint row and let the partial text scroll inside the bubble per
   the height-bound contract). Review/error/history/apply flows unchanged
   visually otherwise.
5. **Tests**:
   - Parser: `draft_delta` mapping (round-trip incl. CJK/brace-laden delta
     strings).
   - Repository fold: deltas forwarded verbatim in order to `onDelta`
     (empty deltas included), result still settles from the `draft` event;
     error-after-deltas → `ApiException` and no result; existing draft fold
     tests updated (they currently see no deltas).
   - Notifier: accumulation latest-wins + generation guard (a superseded
     generation's deltas dropped); partial cleared on error and replaced on
     review; failure path (history auto-load with failed op) unchanged.
   - Widget: generating view renders live partial text; on error the
     partial disappears and recovery entry appears; on success the review
     shows the validated draft (not the concatenation).
   - All existing suites green; chat/SSE parser tests untouched.
6. `flutter analyze` clean; full `flutter test` green.

## Constraints

- `draft`/`done`/`error`/pre-stream semantics unchanged; summary/
  associations streams untouched (their `fold` gains nothing).
- `delta` is display-only raw text — no JSON parsing, no markdown
  rendering, no result derivation from concatenation.
- Existing guards (workflow + history generation counters, busy no-ops,
  apply invalidations) unchanged.

## Acceptance Criteria

- [ ] `draft_delta` modeled/parsed; repository forwards deltas verbatim in
      order via `onDelta` while still settling on the `draft` event.
- [ ] Generating view renders the accumulating partial live; error clears
      it and keeps the recovery path; review shows the validated draft.
- [ ] Stale generations' deltas are dropped; partial never leaks into
      review/history.
- [ ] Summary/associations/chat behavior unchanged (their tests untouched).
- [ ] `flutter analyze` clean; full `flutter test` green.
