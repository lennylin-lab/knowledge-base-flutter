# State Management

> How state is managed in this project.

---

## Overview

**Riverpod (flutter_riverpod)** is the single state solution — chosen in the
project brief and applied everywhere. No mixing with bloc or setState-based
global state. (`setState` is fine for purely local, ephemeral widget state.)

**Riverpod ≥3.3 auto-retry is DISABLED** (`ProviderScope(retry: noAutomaticRetry)`
from `lib/core/retry_policy.dart`): Riverpod retries failed providers up to
10× with backoff by default, silently re-firing requests — that would hammer
a rate-limited backend and bypass the error-handling spec. Every test scope
must also pass `retry: noAutomaticRetry`. Note: `AsyncValue.valueOrNull` is
gone in Riverpod 3 — use `.value`.

---

## State Categories

| Category | Where it lives | Examples |
|----------|----------------|----------|
| Ephemeral widget state | `StatefulWidget` + `setState` | text field contents, chip toggles |
| Server state | Feature `AsyncNotifier` | documents list + cursor, search results, document detail |
| Streaming state | Feature `Notifier` | chat answer assembly from SSE events |
| App configuration | `Provider<AppConfig>` | API base URL |
| Navigation/route state | `go_router` | current tab, selected document id |

Rule: if the data came from the backend, it belongs in a provider, not in a
widget field.

---

## When to Use Global State

Almost never beyond the categories above. A provider is "global" by default in
Riverpod; keep it feature-scoped by placing it in the feature directory and not
importing it elsewhere. Only `core/` providers (api client, config, theme) are
truly app-wide.

---

## Server State

- Documents list: `AsyncNotifier<DocumentPage>` holding `items` + `next_cursor`;
  actions: `loadNext()`, `applyCreate/Update/Delete` (either patch locally or
  invalidate + refetch first page — prefer simple refetch in MVP).
- Detail: `FutureProvider.family<DocumentReadDetail, String>`, invalidated after
  edit/delete.
- Search: results owned by the search page's notifier; no cross-page cache needed.
- All writes go through the repository; UI optimistically disables controls and
  surfaces errors via `AsyncValue` / `ref.listen`.

---

## Chat SSE State Machine (critical)

Session-persisted multi-turn QA. The chat notifier holds one active
conversation (`sessionId`, server-assigned via `run_started`/`done`) and
implements this state machine per run:

```
idle → run_started (keep run_id, mode)
     → sources*     (append to sources list — event may repeat; first batch
                     of a follow-up may replay the previous run — carry-forward,
                     numbering still restarts per run)
     → [status | query_rewritten | tool_call_started | tool_call_finished]*
                     (progress events — non-terminal, never touch the phase
                      machine; may interleave anywhere before done)
     → answer_delta* (concatenate text deltas verbatim)
     → done          (terminal: outcome success, tool_calls, latency_ms)
     | error         (terminal: code + message → user-facing error)
```

- `sources` is cumulative across multiple `sources` events; citation `[n]`
  indexes into this accumulated list.
- On widget dispose, cancel the subscription and return to `idle`.
- HTTP status may already be 200 when an `error` event arrives — the SSE layer,
  not dio, reports it.
- Follow-up questions send the active `sessionId`; `newSession()` clears it.
  A finished run commits its turn into the client-side `history` when the next
  run starts (the server persists the same turns; history messages carry no
  sources).

### Progress events (wire contract, `docs/chat-api.md` §4.3–4.6)

Scope: cross-layer contract — payload shapes are mirrored 1:1 by freezed DTOs
in `shared/models/chat.dart`.

| Event | Payload (snake_case on wire) | Client handling |
|---|---|---|
| `status` | `phase: "rewriting_query" \| "generating"` | writes the progress line |
| `query_rewritten` | `original`, `rewritten`, `applied`, `changed` | appends a `ChatRewriteEntry` to the run parts (disclosure UI); emitted only when output changed |
| `tool_call_started` | `call_id`, `tool_name`, `args: {query?, limit?}` | `search_knowledge` → progress 「正在检索：{query}」 |
| `tool_call_finished` | `call_id`, `tool_name`, `status: "success" \| "failed"`, `latency_ms` | upserts the matching `ChatToolCallView` in the run parts; `failed` renders in error color (non-fatal — run may still `done`) |

- **Non-terminal**: none of them set the parser's terminal flag; only
  `done`/`error` end the stream. Unknown event names stay ignored.
- **Chronological rendering**: the run view renders `ChatState.parts`
  (`ChatRunPart` union: answer segments / `ChatRewriteEntry` /
  `ChatToolCallView`) strictly in event arrival order. An `answer_delta`
  appends to the trailing answer segment or opens a new one — a process
  event arriving between `answer_delta` chunks splits the answer around its
  row (docs §5.1 allows mid-answer retrievals). Never pin process entries to
  fixed slots (top/bottom); the wire order is the render order.
- **Latest event wins**: progress events write the progress line directly
  (no phase-priority math) — `status(rewriting_query)` → 「正在理解问题…」,
  `tool_call_started(search_knowledge)` → 「正在检索：{query}」,
  `status(generating)` → 「正在生成回答…」. The line is hidden once the
  first `answer_delta` arrives (the text is the progress) or the run ends.
- **History keeps the original question**: `query_rewritten` is UI-only
  transparency; never store the rewritten query as the turn's question
  (server persists originals too).
- **Wrong vs Correct**: deriving the line from a `statusPhase` enum with
  priority rules breaks the moment a `status(generating)` event is optional
  (§5.1) — a stale 「正在检索：…」 would outlive its tool call. Write the
  literal line per event instead.
- Tests: parser (each payload + unknown phase fallback), provider (progress
  sequence, `call_id` upsert, failed-tool-is-still-`done`), widget (progress
  line texts, rewrite disclosure expansion, `getTopLeft` ordering of parts —
  including a mid-answer tool call splitting two answer segments).

---

## Document Agent SSE (summary / associations / draft)

The document-agent endpoints stream `text/event-stream` over the **same wire
discipline as chat** (issue #1 / server commits a16d933 + 9be2b39). Event
order (server `schemas/agent_stream.py`; backend error-handling spec):

- summary: `run_started → summary_progress* → summary → done`
- associations: `run_started → associations → done`
- draft (`POST /operations/draft`): `run_started (kind "draft") → draft →
  done`; the `draft` event is flat `{operation_id, state: "completed",
  content, title?}` — no timestamps, so the client models it as a
  lightweight `OperationDraftResult`, never a synthesized
  `OperationReadDetail`. A mid-stream `error` leaves the operation
  persisted `failed`; the error event carries no operation id, so the UI's
  recovery path re-loads the document's operation history to surface it.

```
run_started → [summary_progress …] (summary only) → summary|associations → done
failure after HTTP 200: … → error (terminal; stream closes)
```

- Result events carry the old **flat** `SummaryResult` / `AssociationsResult`
  payloads — the DTOs did not change.
- The repository folds the stream into `Future<Result>` (+
  `onProgress(SummaryProgress)`): terminal `error` → `ApiException(code,
  message)`; stream ending without a result → `ApiException(network_error)`;
  pre-stream 404/401/403 envelopes keep the normal path (the server primes
  document validation before the first event).
- Framing lives in the shared `SseFrameParser` (`sse_parser.dart`); chat's
  parser is a typed wrapper on it — one wire discipline for chat + agent
  streams. Web streaming goes through `ChatTransport` only (never dio
  `ResponseType.stream`).
- `summary_progress` is informational: map passes + one reduce
  (`pass_index == passes_total`), emitted even for single-chunk documents;
  cache hits emit none. UI copy: map → 「正在阅读第 x/y 段」, reduce →
  「正在汇总要点」. Progress writes go through the same generation guard as
  terminal writes — a superseded generation's late progress must be dropped.

---

## Common Mistakes

- Sending `session_id: null` on the wire — omit it (`includeIfNull: false` on
  `ChatRequest.sessionId`); absent == new session server-side.
- Treating `next_cursor == null` as an error — it means "end of list".
- Mutating DTO lists in place — freezed models are immutable; copy/replace.
