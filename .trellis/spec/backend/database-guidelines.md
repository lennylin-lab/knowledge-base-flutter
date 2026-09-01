# Data Semantics (Client View)

> The client never touches a database. This file documents backend data
> semantics the UI **must** respect: pagination, deletion, indexing lifecycle,
> and tag filtering. Server-side DB conventions live in
> `../knowledge-base-server/.trellis/spec/backend/database-guidelines.md`.

---

## Keyset Pagination

- `GET /api/v1/documents` returns `{ "items": [...], "next_cursor": "..." | null }`.
- `next_cursor` is **opaque** — never parse, sort, or construct cursors
  client-side; only pass it back as the `cursor` query param.
- `next_cursor == null` means end of list (not an error).
- `limit` bounds: documents 1–100 (default 20), search 1–50 (default 10),
  chat 1–20 (default 8). Clamp before sending; out-of-range yields 422.

---

## Soft Delete

`DELETE /api/v1/documents/{id}` returns **204** and soft-deletes. Afterwards:

- `GET` / `PATCH` on that id → 404 `not_found` (errors, not "deleted" state).
- The document disappears from list and search results (backend reindexes).
- Client behavior: remove from local list optimistically; on 404 during
  detail/edit, treat as deleted and navigate back with a toast.

---

## `index_status` Lifecycle

`pending → done | failed`, maintained by the backend indexer after
create/update (content is parsed for YAML front matter → title/tags):

- `pending`: new/edited doc; show an indexing indicator; search may not hit it
  yet.
- `done`: searchable.
- `failed`: indexing error; document still readable/editable; UI should offer
  re-save to retry indexing. The client cannot retry indexing directly — there
  is no endpoint for it; re-saving (PATCH with content) re-enqueues.

---

## Tags & Front Matter

- Tags are **not** set through a dedicated field on create: the client sends
  full Markdown `content` (YAML front matter included) and the backend derives
  `title` and `tags`.
- Filter lists with `?tag=<name>` server-side; do not filter the fetched page
  client-side (breaks pagination).
- `created_at` / `updated_at` are ISO8601 strings, server-managed.

---

## Concurrency

Single-user MVP, but PATCH may still race: always send `DocumentUpdate` built
from the **currently loaded** content; a 404 means deleted elsewhere, a 409
`conflict` means the edit was rejected — surface the message, don't silently
overwrite.
