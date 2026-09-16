# Research: Server /api/v1/operations contract (source of truth)

Verified 2026-09-16 against server HEAD (`../knowledge-base-server`, commit
b4a7109). Files: `src/app/api/v1/endpoints/operations.py`,
`src/app/schemas/operation.py`, `src/app/services/operation.py`,
`src/app/models/operation.py`.

## Headline: all six routes are synchronous JSON — draft is NOT SSE

`a16d933` (agent SSE) touched only chat/documents endpoints; operations last
changed in `5dcd7ce`/`ddbc8b2`. `POST /operations/draft` returns a plain JSON
`OperationReadDetail` (synchronous LLM call).

## Routes

| Method | Path | Status | Params | Notes |
|---|---|---|---|---|
| POST | `/api/v1/operations` | 201 | body `OperationCreate` | idempotent on `idempotency_key` (returns the existing operation verbatim) |
| POST | `/api/v1/operations/draft` | 200 | **query** `document_id` (UUID, required), `instruction` (str, optional) | runs the writing agent synchronously; persists `running` before the model call, then `completed`+draft or `failed`+`error{error_class}` and re-raises mapped AppError; never auto-applies; no body |
| GET | `/api/v1/operations/{operation_id}` | 200 | path UUID | 404 missing/other-tenant |
| GET | `/api/v1/operations/documents/{document_id}` | 200 | path UUID | newest first, capped at 50, no pagination; distinct segment count from `/{operation_id}` so no route clash |
| POST | `/api/v1/operations/{operation_id}/resume` | 200 | optional body `OperationTransition` | 409 `conflict` (`details.state`) unless state ∈ {interrupted, failed}; optional `draft` replaces stored draft (front matter re-validated → 422); sets completed, clears error |
| POST | `/api/v1/operations/{operation_id}/apply` | 200 | optional body `ApplyRequest` | see apply semantics |

`document_id`/`instruction` on `/draft` are **query params**, not body.

## Schemas (`schemas/operation.py`; `DRAFT_MAX_CHARS = 50_000`)

- `DraftContent`: `content` str (1..50_000, required), `title` str|null.
- `OperationCreate`: `document_id` UUID, `base_document_version` datetime
  (required — the document `updated_at` the caller saw), `draft`
  DraftContent, `idempotency_key` str|null (1..255).
- `OperationReadDetail` (= what every route returns; list items included):
  `id` UUID, `document_id` UUID|null, `base_document_version` datetime|null,
  `state`, `idempotency_key` str|null, `created_at` datetime,
  `updated_at` datetime, `draft` DraftContent|null, `result` object|null
  (on apply: `{"revision_id": "<uuid>"}`), `error` object|null (on failure:
  `{"error_class": "<ExcClassName>"}`).
- `OperationState` (StrEnum, lowercase): `running` | `completed` |
  `interrupted` | `failed` | `applied` — exactly five, no others.
- `OperationTransition`: `draft` DraftContent|null (optional amendment).
- `RevisionRead`: `id`, `document_id`, `operation_id` (nullable), `title`,
  `tags` list[str], `created_at`. **No `content` field exposed.**
- `ApplyRequest`: `expected_base_document_version` datetime|null (optional
  double-check vs the operation's recorded base; mismatch → 409, zero
  writes).
- `ApplyResult`: `operation` OperationReadDetail, `revision` RevisionRead,
  `document` DocumentInResult{id, title, tags, index_status
  (pending|done|failed), updated_at}.

## Lifecycle semantics (`services/operation.py`)

- `create`: idempotency lookup first (return existing verbatim; lost race →
  winner); 404 missing/soft-deleted document; front matter parsed early
  (invalid YAML / non-list tags → 422); inserts `completed` directly.
- `draft`: 503 `chat_unavailable` gate (no `CHAT_API_KEY`) fires **before**
  body/query validation per spec; commits `running` first (crash leaves a
  resumable row) → `completed`+draft, or `failed`+`error={"error_class"}` +
  re-raise 502 `llm_provider_error` / 429 `rate_limited`. No server-side
  timeout flips `running→interrupted`; `interrupted` is set externally.
- `resume`: 409 unless {interrupted, failed}; optional draft amendment
  (re-validated); → completed, error cleared.
- `apply` guards, all pre-mutation: already `applied` → idempotent replay of
  the ORIGINAL revision (same ApplyResult, never a second revision); state
  ∉ {completed, interrupted} → 409 (`details.state`); no draft → 409;
  `expected_base_document_version` ≠ recorded base → 409
  (`details.expected`/`details.base`); live document missing → 404;
  `document.updated_at != base_document_version` → 409
  (`details.base_version`/`details.current_version`, message "Document
  changed since the draft was created; re-draft or resume the operation").
  Then ONE transaction: document `content` = draft.content (front matter
  included), title/tags re-derived from front matter, `index_status` →
  `pending`, revision row created, state → `applied`,
  `result={"revision_id"}`.
- Apply mutates `document.updated_at`, which invalidates other operations'
  `base_document_version` — the optimistic-concurrency anchor.

## Errors (envelope unchanged)

`validation_failed` 422 (incl. FastAPI body errors, `details.errors`),
`not_found` 404, `conflict` 409 (details carry `state` / `base_version` /
`current_version` / `expected` / `base`), `forbidden` 403, `chat_unavailable`
503, `llm_provider_error` 502, `rate_limited` 429, `internal_error` 500.
All arrive as the standard `{error:{code,message,details}}` envelope.

## Client-relevant wire notes

- Datetimes serialize as ISO-8601 with UTC offset (`Z`/`+00:00`). Apply's
  optimistic-concurrency check is **exact string-sensitive server-side
  equality** on parsed datetimes — the client must pass the document's
  `updated_at` through **verbatim** (no reformatting, no re-parsing to
  local time). Keeping timestamps as `String` on DTOs (existing
  type-safety convention) makes this automatic.
- `resume`/`apply` bodies are optional: send **no request body** when there
  is nothing to say (server models default to None); send only the filled
  payload otherwise.
- RBAC exists (editor: create+apply; member: create; viewer: read-only) but
  the client runs in single-tenant compat mode (no auth headers today).
