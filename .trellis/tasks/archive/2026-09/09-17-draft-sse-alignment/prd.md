# draft 端点对接 SSE 流式响应（issue #4）

## Goal

Align `POST /operations/draft` consumption with server commit `9be2b39`
(issue #4): the endpoint now answers `text/event-stream`
(`run_started → draft → done`, terminal `error` mutually exclusive) instead
of a synchronous JSON `OperationReadDetail`. The client folds the stream via
the existing `AgentStreamClient` machinery, models the new `draft` event,
adapts the writing state machine to a lightweight current-draft shape, and
keeps the 恢复 entry reachable for mid-stream failures (which carry no
operation id — the failed operation is located through the document's
operation history).

## Background / Evidence

- Server-verified contract: `research-draft-sse-contract.md` in this
  directory (`OperationDraftEvent{operation_id, state: "completed",
  content, title?}` flat; priming 503/404 envelopes; mid-stream single
  `error`; `AgentKind` += "draft").
- Existing machinery from the summary/associations SSE task:
  `SseFrameParser`, `AgentStreamClient.run` (pre-stream envelope →
  `ApiException`; terminal error event → `ApiException`; silent end →
  `network_error`), sealed `AgentStreamEvent` union in
  `lib/shared/models/agents_stream.dart`.
- Writing flow today: `WritingNotifier.generate` → `repository.draft()` →
  `OperationReadDetail` JSON; `WritingState{operation: OperationReadDetail?,
  phase, error, history…}`; the review view consumes draft title/content;
  apply consumes `operation.id`; history items are full details.

## Requirements

1. **Event model** (`agents_stream.dart`): add
   `AgentDraftEvent{operationId, state, content, title?}` to the sealed
   union; parser maps the `draft` event name to it. `state` stays a raw
   wire string (literal `"completed"` today; unknown → the UI treats a
   received draft event as reviewable — do not invent sentinels).
2. **Repository**: `draft({documentId, instruction})` switches from the
   JSON POST to folding the agent stream (same pattern as
   summarize/associations — pre-stream envelope → `ApiException`; terminal
   `error` event → `ApiException(code, message)`; silent end →
   `network_error`). New return type
   `OperationDraftResult{operationId, state, draft: DraftContent}` — do NOT
   synthesize a fake `OperationReadDetail` (its required timestamps would
   be lies). Query params and no-body semantics unchanged.
3. **Writing state machine** (`WritingNotifier`/`WritingState`): replace
   `operation: OperationReadDetail?` with the lightweight current-draft
   shape the layer actually consumes (e.g. `CurrentDraft{operationId, state,
   draft}`) — history-opened operations map into it (`op.id`, `op.state`,
   `op.draft`); stream-generated drafts map from `OperationDraftResult`.
   Apply uses `current.operationId`; resume gating uses `current.state` (
   interrupted/failed only, from history-opened ops). All existing guard
   idioms stay (synchronous busy no-op, generation counters incl. the
   dedicated history counter, failure keeps prior view, apply invalidates
   documentDetailProvider + documentsProvider before the superseded-return).
4. **Failure recovery entry** (issue requirement): after a draft failure
   (mid-stream `error` or pre-stream failure), the error view keeps
   重新生成 and surfaces the failed operation through the history
   affordance — auto-load (or refresh, if already loaded)
   `operationsForDocument(documentId)` so the newest `failed` operation is
   visible and tappable → openOperation → 恢复. Copy gains no new claims
   beyond the existing 生成失败 + the history affordance.
5. **UI unchanged otherwise**: the review view renders the same way from
   `CurrentDraft` (title/content via `MarkdownContent` +
   `stripYamlFrontMatter`); 重新生成 prefill; applying disabled; success
   view + index hint; keep-alive across dismiss; PopScope; height bound;
   zero calls until 生成草稿/历史操作.
6. **Tests**:
   - Stream/parser: `draft` event parsing (incl. null title), kinds, and
     the repository fold — happy path (run_started → draft → done),
     mid-stream error → `ApiException(code)`, premature end →
     `network_error`, pre-stream 404/503 envelopes, cache of existing
     summary/associations streams untouched (byte-identical contract).
   - Notifier: generate success populates `CurrentDraft` (review phase,
     apply/resume gating correct); draft failure → error view + history
     auto-loaded/refreshed with the failed op visible → openOperation →
     恢复; all existing writing tests updated to the new shapes.
   - Widget: flows regress none (menu entry, generate, review, apply,
     conflict, resume, history, keep-alive, PopScope, height bound).
7. `flutter analyze` clean; full `flutter test` green.

## Constraints

- `inspect`/`resume`/`apply` remain plain JSON — do not stream them.
- Other SSE streams byte-identical (chat parser tests zero-diff).
- Repository is the only layer that knows about the stream; providers/UI
  consume the new result type.
- No routing changes; AppSizes/Chinese-copy/const conventions where touched.

## Acceptance Criteria

- [ ] `draft` event modeled and parsed; repository `draft()` folds the SSE
      stream and returns the lightweight result; pre-stream envelopes,
      mid-stream error, and silent end map per contract.
- [ ] Writing state machine uses the lightweight current-draft shape;
      review/apply/resume flows work as before from history-opened and
      stream-generated drafts alike.
- [ ] After a draft failure the failed operation is reachable: history
      auto-loads/refreshes and 恢复 works end-to-end.
- [ ] No silent apply; other SSE streams and JSON endpoints untouched
      (chat parser tests zero-diff).
- [ ] `flutter analyze` clean; full `flutter test` green.
