# 摘要/联想增量事件对接（issue #7）

## Goal

Adopt the incremental-streaming extension from issue #7 (server commit
`3013843`, verified against HEAD): the summary stream gains `summary_delta`
(verbatim text fragments; concatenation == the final `summary` field; **no
deltas on cache hits**) and the associations stream gains `association_item`
(each confirmed association, final-state, 1-based `position`, streamed in
final-list order; none on cache hits / empty-candidate paths). All existing
events and semantics are unchanged — this is purely additive. Client:
consume both for live rendering ("逐字出摘要、逐条出关联"), with the
terminal result events still settling authoritatively.

## Background / Evidence

- Server-verified (`../knowledge-base-server` HEAD `b34a3e8`,
  `schemas/agent_stream.py`): `SummaryDeltaEvent{run_id, text}`,
  `AssociationItemEvent{run_id, position, document_id, title, tags, reason,
  signal}`. Order: `run_started → progress(map) → summary_delta* →
  progress(reduce) → summary → done`; `run_started → association_item* →
  associations → done`. Error semantics unchanged (kept events + one
  terminal `error`, no `done`).
- Existing client machinery (all reuse, no new transport work):
  `AgentStreamClient.fold` with per-stream callback channels
  (`onProgress`/`onDelta` precedent), `OnDemandState` + generation-guard
  idioms, live markdown via shared `MarkdownContent` (summary deltas are
  **plain text** — no partial-JSON extraction needed, unlike draft_delta),
  association tiles (`_AssociationTile` pattern).

## Requirements

1. **Event models** (`agents_stream.dart`): add
   `AgentSummaryDeltaEvent{runId, text}` and
   `AgentAssociationItemEvent{runId, position, documentId, title, tags,
   reason, signal}` to the sealed union (+ codegen); parser maps
   `summary_delta` / `association_item` (both non-terminal). `text` is
   verbatim opaque text; association-item fields mirror `AssociationItem`
   (the model in `agents_result.dart`) — decode into a reusable shape
   (e.g. construct `AssociationItem` from the event payload) so the UI can
   render items with zero adaptation.
2. **Fold channels**: `AgentStreamClient.fold` forwards the new events to
   callers — extend the callback set (e.g. `onSummaryDelta(String text)` /
   `onAssociationItem(AssociationItem item)` or a generalized non-terminal
   event callback; pick what stays cleanest across the three streams).
   Summary/associations call sites consume them; the draft stream is
   untouched (`summary_delta`/`association_item` never occur there, and its
   `onDelta` semantics stay as-is).
3. **Summary on-demand state** (`OnDemandState` or its summary-specific
   extension): additive `partialSummary` (String?) — `summarize` accumulates
   delta text under the existing generation guard (latest-wins, stale
   dropped); cleared on terminal writes (success/error/new generation) like
   the existing `progress`. **Cache hits legitimately have zero deltas** —
   the UI must not assume any (spinner+progress rows render until the
   result lands, exactly as today).
4. **Associations on-demand state**: additive incremental item list —
   `association_item` events insert (ordered by `position`; server streams
   them in order) as final-state items; replaced wholesale by the final
   `associations` result; cleared on error/new generation; same guards.
5. **UI**:
   - Summary generating view: render the accumulated `partialSummary` live
     via the shared `MarkdownContent` (plain text deltas — direct render,
     no extraction), keeping the existing progress rows (map/reduce copy);
     review view unchanged (validated result replaces the partial).
   - Associations generating view: render accumulated items as tiles
     (reuse the association tile pattern) below the spinner row; review
     view unchanged (final list replaces the incremental tiles).
   - Error: partials/items cleared per the existing failure path; dead-end
     rule unchanged.
6. **Tests**:
   - Parser: both events round-trip (item with CJK/multi-tag, deltas with
     unicode); terminal semantics unaffected.
   - Fold: deltas/items forwarded verbatim in order; cache-hit shape (no
     deltas/items) still settles from the result event; error-after-partial
     → `ApiException`, no result.
   - Notifier: accumulation under generation guard (stale dropped,
     latest-wins); terminal replace; error clears; cache-hit (no deltas)
     lands normally.
   - Widget: summary generating view renders live markdown from deltas
     (progress rows kept); associations generating view renders item tiles
     incrementally; final states replace incrementals; error clears; UI
     works with zero deltas (cache-hit).
   - Existing suites green; draft `onDelta` and chat untouched.
7. `flutter analyze` clean; full `flutter test` green.

## Constraints

- Additive only: existing events, `done`/`error` semantics, pre-stream
  envelopes, draft stream, and chat untouched.
- Deltas are plain summary text (no JSON extraction); item events are
  final-state (no client-side dedup/ordering repair needed beyond
  position-ordered insertion as they arrive).
- Guards (workflow + history generation counters, busy no-ops, apply
  invalidations) unchanged; new state fields follow the additive
  clear-on-terminal pattern.
- AppSizes/Chinese-copy/const conventions where touched.

## Acceptance Criteria

- [ ] Both events modeled/parsed; fold forwards them in wire order to the
      summary/associations call sites; result events still settle
      authoritatively.
- [ ] Summary generating view renders live markdown from deltas (progress
      rows kept) and works with zero deltas (cache hit).
- [ ] Associations generating view renders items incrementally (position
      order) and works with zero items (cache hit / empty candidates).
- [ ] Error clears incrementals and keeps the recovery path; stale
      generations' deltas/items dropped.
- [ ] `flutter analyze` clean; full `flutter test` green.
