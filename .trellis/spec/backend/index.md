# Backend Contract Guidelines (Client Perspective)

> This repository is the Flutter **frontend**. The backend is the sibling repo
> `../knowledge-base-server`, which owns its own coding spec under its
> `.trellis/spec/backend/`. The files here document what the client needs from
> the backend: where the contract lives, its data semantics, and its error
> model.

---

## Guidelines Index

| Guide | Description | Status |
|-------|-------------|--------|
| [Directory Structure](./directory-structure.md) | Backend repo map, contract sources, run commands, base URLs | Filled |
| [Data Semantics](./database-guidelines.md) | Keyset pagination, soft delete, index_status lifecycle, tags | Filled |
| [Error Contract](./error-handling.md) | Error envelope, code→HTTP table, SSE error events, UI rules | Filled |
| [Logging Guidelines](./logging-guidelines.md) | Client-side logging rules and privacy limits | Filled |
| [Quality Guidelines](./quality-guidelines.md) | Contract drift prevention, smoke checks, cross-repo etiquette | Filled |

## Endpoints (verified against backend `src/app/api/v1/endpoints/`)

| Method & Path | Purpose |
|---|---|
| `GET /healthz` | liveness → `{ "status": "ok" }` |
| `POST /api/v1/documents` | create (201, DocumentRead) |
| `GET /api/v1/documents` | list — `cursor`/`limit`/`tag` (DocumentPage) |
| `GET /api/v1/documents/{id}` | detail incl. `content` |
| `PATCH /api/v1/documents/{id}` | partial update (`content` and/or `title`) |
| `DELETE /api/v1/documents/{id}` | soft delete (204) |
| `GET /api/v1/search` | `q`/`limit`/`tag` (SearchResponse) |
| `POST /api/v1/chat` | SSE stream: `run_started → sources* → answer_delta* → done \| error` |

---

**Language**: All documentation should be written in **English**.
