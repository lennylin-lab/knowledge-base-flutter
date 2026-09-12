# Chat multi-turn sessions support

## Goal

Update the Flutter client to the backend's multi-turn chat API: session-aware
chat requests/events, session list, history loading, and session deletion with
full UI.

## Backend contract (knowledge-base-server, current)

- `POST /api/v1/chat` — request gains optional `session_id` (UUID string):
  absent starts a new persisted session (title derived from the question),
  present continues that session (unknown id → 404 `session_not_found` style
  envelope). SSE events unchanged in order (`run_started → sources* →
  answer_delta* → done | error`); `run_started` and `done` payloads now carry
  `session_id` (nullable in stateless mode — the client always runs persisted
  mode, but must tolerate `null`).
- `GET /api/v1/chat/sessions` — keyset-paginated list, most recently updated
  first: `{items: [SessionRead], next_cursor: string|null}`, query params
  `cursor` (string|null), `limit` (1–100, default 20).
  `SessionRead = {id, title, created_at, updated_at}`.
- `GET /api/v1/chat/sessions/{id}` — `SessionDetail = SessionRead +
  {messages: [MessageRead]}`, messages chronological.
  `MessageRead = {id, role: "user"|"assistant", content, run_id: uuid|null,
  created_at}`.
- `DELETE /api/v1/chat/sessions/{id}` — 204, soft delete.

## Requirements

1. Transport layer mirrors the contract exactly: `ChatRequest.sessionId`
   (optional), `RunStarted.sessionId`, `ChatDone.sessionId`; new session DTOs
   (`ChatSessionSummary`, `ChatMessage`, `SessionDetail`, `SessionPage`) with
   freezed + json_serializable, snake_case JSON mapping per type-safety spec.
2. `ChatRepository.chat` accepts an optional `sessionId` and forwards it.
3. New `SessionRepository` (dio via `ApiClient`) for list / detail / delete,
   errors normalized to `ApiException` via `toApiException`.
4. Chat state becomes session-aware: the notifier remembers the active
   `sessionId` (from `run_started`/`done`), sends it on follow-up questions in
   the same conversation, and exposes `newSession()` to start a fresh one.
5. Chat page renders a conversation (user question + assistant answer per
   turn) instead of a single run; opening an existing session loads its
   stored messages and continues it.
6. Session list UI: route `/chat/sessions` inside the chat branch — list with
   title + relative time, tap to open, pull-to-refresh / refresh on change,
   keyset "load more" when `next_cursor` is present, swipe/long-press delete
   with confirmation. Opening a list entry loads the session into the chat
   page.
7. Chat page AppBar gains "新对话" (start new session) and "历史会话" (session
   list) entries.
8. All UI copy Chinese-first; LLM answer text rendered verbatim.

### Constraints

- Existing single-run semantics (stale-run generation, cancel/dispose, error
  keeping rendered deltas) must survive the refactor.
- History messages from the backend carry no sources; past assistant turns
  render markdown without the sources panel (citations in historical answers
  are not resolvable — acceptable, stated in code docs).
- No auth; no local caching of sessions beyond provider state.

## Acceptance Criteria

- [ ] `ChatRequest` serializes `session_id` only semantics-correctly (absent
      on first question, present on follow-ups); `run_started`/`done`
      `session_id` is parsed and drives the notifier's active session.
- [ ] `SessionRepository` list/detail/delete hit the correct endpoints with
      clamped `limit` (1–100) and cursor passthrough; failures surface as
      `ApiException` codes.
- [ ] Chat page shows the full conversation for the active session, streams
      the newest turn, and follow-up questions reuse the session id.
- [ ] Session list page lists sessions newest-first with working pagination,
      refresh, open, and confirmed delete; deleting the open session resets
      the chat page to a new conversation.
- [ ] `flutter analyze` clean; all tests pass, including new session
      repository/provider tests and updated chat provider/page tests.
