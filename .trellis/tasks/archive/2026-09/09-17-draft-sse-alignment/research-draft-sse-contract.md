# Research: draft SSE contract (issue #4, server 9be2b39)

Verified 2026-09-17 against server HEAD (`../knowledge-base-server`,
`src/app/schemas/agent_stream.py`, `src/app/api/v1/endpoints/operations.py`,
commit `9be2b39`).

## Wire contract

`POST /api/v1/operations/draft` (query `document_id` required,
`instruction` optional — unchanged) now answers `text/event-stream` via the
shared serializer + priming pattern.

Success order (fixed):

1. `run_started` — `{run_id, kind: "draft" | "summary" | "associations",
   document_id}` (`AgentKind` extended with `"draft"`).
2. `draft` — **new event** `OperationDraftEvent`, flat:
   `{operation_id: UUID, state: "completed" (literal), content: str,
   title: str | null}`. Emitted AFTER the terminal state is committed — a
   client that stops reading never sees a draft for unpersisted work. No
   incremental tokens: the structured draft arrives atomically.
3. `done` — `{run_id, outcome: "success", latency_ms}`; stream closes.

Failure:

- **Pre-stream** (priming, non-200 JSON envelope): 503 `chat_unavailable`
  (no API key), 404 `not_found` (missing/soft-deleted document).
- **Mid-stream** (after 200): exactly one terminal `error` event (chat
  `ErrorEvent` shape: `{code, message}` — e.g. `llm_provider_error`,
  `rate_limited`), then close. The operation is already persisted `failed`
  and recoverable via `/resume`. **The error event carries no operation
  id** — a client offering 恢复 must locate the failed operation via
  `GET /operations/documents/{document_id}` (newest first).

Unchanged: terminal state committed before the terminal event; no silent
apply/publish; `inspect`/`resume`/`apply` stay plain JSON; chat/writing/
summarize/associations streams byte-identical. `done`/`error` are mutually
exclusive, each appearing at most once.

## Client impact

- `AgentStreamClient`/`AgentStreamParser` already handle the transport +
  framing + normalization (pre-stream envelope → `ApiException`, terminal
  error event → `ApiException`, silent end → `network_error`) — the draft
  stream is a new event type + fold, not new machinery.
- The writing flow's `repository.draft()` currently returns
  `Future<OperationReadDetail>` from a JSON body. With SSE, the stream
  yields `operation_id + state + content + title` — **not** a full
  `OperationReadDetail` (no created_at/updated_at/base_document_version).
  Synthesizing one would require placeholder timestamps; the honest shape
  is a lightweight result (`operationId`, `state`, `draft`), which is all
  the writing layer consumes (review: draft title/content; apply:
  operationId; gating: state).
- Failed-draft recovery (issue requirement: keep the 恢复 entry): after a
  draft failure, surface the failed operation through the existing history
  affordance — auto-load/refresh `operationsForDocument(documentId)` so the
  newest failed operation is visible/openable (tap → 恢复). The error view
  itself only knows code/message.
