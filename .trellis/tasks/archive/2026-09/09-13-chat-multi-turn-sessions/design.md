# Design — Chat multi-turn sessions support

## Boundaries

- `shared/models/chat.dart` — extend existing chat DTOs (request/event
  `sessionId`). No wire-format change beyond added optional fields.
- `shared/models/session.dart` (new) — session DTOs, freezed, mirrors backend
  `app/schemas/session.py`:
  - `ChatSessionSummary {id, title, createdAt, updatedAt}` (SessionRead)
  - `ChatMessage {id, role, content, runId, createdAt}` with
    `ChatMessageRole {user, assistant}` enum (unknown → `user` fallback via
    `unknownEnumValue`, mirroring `SearchMode` handling).
  - `SessionDetail = ChatSessionSummary + messages`
  - `SessionPage {items, nextCursor}` (`next_cursor` nullable).
- `features/chat/session_repository.dart` (new) — dio REST:
  `GET /api/v1/chat/sessions?cursor&limit`, `GET …/{id}`,
  `DELETE …/{id}`. Same error normalization pattern as `SearchRepository`
  (`toApiException`, clamp limit 1–100, default 20).
- `features/chat/chat_repository.dart` — `chat({question, limit, sessionId})`.

## Data flow / state

### ChatNotifier (extended, stays a single `Notifier<ChatState>`)

`ChatState` additions:

- `String? sessionId` — active persisted conversation. Set from
  `run_started.sessionId ?? done.sessionId`; cleared by `newSession()`.
- `List<ChatMessage> history` — persisted turns loaded via
  `openSession(id)` (session detail) or accumulated in-session (a finished
  run appends `user(question)` + `assistant(answer)` messages).

Run mechanics unchanged (generation guard, single subscription, terminal
events). `ask(question)` sends `sessionId: state.sessionId`; `retry()` keeps
session id and the displayed turn semantics. `openSession(id)`:

1. cancel any run, bump generation;
2. fetch detail via `SessionRepository`;
3. set `sessionId`, `history = detail.messages`, clear current-run fields;
   404 → terminal error state (`session_not_found`), UI falls back to idle
   new-conversation prompt.

`newSession()` cancels any run, clears sessionId/history/run fields → idle.
The session list provider invalidates after delete so the list stays honest.

### SessionListProvider (new `AsyncNotifier<SessionPage>`)

- `build()` loads page 1 (`limit 20`); `loadMore()` appends the
  `next_cursor` page (guard against double-fire and cursor exhaustion);
  `refresh()` reloads page 1; `remove(id)` calls delete then refreshes
  (optimistic removal rejected — keep server authoritative).
- Lives at feature level; the chat page does not watch it (only the list
  page does), so chat streaming never rebuilds the list.

### Open-session coordination

Chat page reads `sessionId`/`history` from `chatProvider`; the list page
calls `ref.read(chatProvider.notifier).openSession(id)` then navigates back
to `/chat` via the shell branch root. No cross-provider auto-invalidation:
explicit notifier calls only (state-management spec).

## UI shape

- `ChatPage`: ListView of `history` (user rows right-ish `问：` style retained
  as bubbles: user = surfaceVariant container, assistant = plain
  `MarkdownContent`) + current-run view (existing `_AnswerView` content)
  appended below. AppBar actions: `新对话` icon (`Icons.add_comment_outlined`)
  and `历史` (`Icons.history`) → `context.push('/chat/sessions')`.
- `SessionsPage` (`/chat/sessions`, inside chat branch so the tab stays):
  AppBar + `RefreshIndicator`, `ListView` of summary tiles (title, updated
  relative time, message-less), trailing delete icon → confirm dialog →
  `remove`; tapping calls `openSession` then `context.go('/chat')`.
  Footer loader tile appears when `nextCursor != null`; error/loading states
  mirror the documents page patterns.
- Router: add `GoRoute(path: 'sessions', name: 'chat-sessions')` under the
  chat branch.

## Tradeoffs

- History assistant turns render without sources (backend stores none);
  documented at the model + widget site rather than fabricating citations.
- Session list pagination is keyset with a simple "load more" tile — no
  scroll-position-triggered infinite scroll (MVP parity with documents list
  behavior).
- Delete is confirm-dialog guarded (destructive, soft-delete on server).

## Rollout / rollback

Single client-side change; no migration. Rollback = revert commit. Backend
tolerates `session_id`-absent requests, so a reverted client keeps working
against the new server.
