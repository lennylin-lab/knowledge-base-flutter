# Implement — Chat multi-turn sessions support

Ordered checklist; run gates at each `[gate]`.

1. [ ] Models
   - `shared/models/session.dart`: `ChatMessageRole` enum, `ChatMessage`,
     `ChatSessionSummary`, `SessionDetail`, `SessionPage` (freezed +
     json_serializable, snake_case keys).
   - `shared/models/chat.dart`: `sessionId` on `ChatRequest`,
     `RunStarted`, `ChatDone`; update single-turn doc comments.
   - Run `dart run build_runner build --delete-conflicting-outputs`.
2. [ ] Transport
   - `ChatRepository.chat({question, limit, sessionId})`.
   - New `features/chat/session_repository.dart` (list/detail/delete,
     clamp 1–100 default 20, `toApiException`).
   - Wire `sessionRepositoryProvider` in `chat_providers.dart`.
3. [ ] State
   - `ChatState`: `sessionId`, `history`; `ChatNotifier`: send active
     sessionId, record it from `run_started`/`done`, append finished turns to
     history, `newSession()`, `openSession(id)` (loads detail, 404-safe).
   - New `SessionsNotifier` (AsyncNotifier): page-1 build, `loadMore`,
     `refresh`, `remove`.
4. [ ] UI
   - `chat_page.dart`: conversation list rendering history + current run,
     AppBar actions (新对话 / 历史会话).
   - New `sessions_page.dart`; router entry `/chat/sessions`
     (chat branch, `name: 'chat-sessions'`).
5. [ ] Tests `[gate: flutter test]`
   - `session_repository_test.dart` (mock dio via existing test patterns).
   - Update `chat_repository_test.dart` (sessionId passthrough),
     `chat_providers_test.dart` (session continuation, newSession,
     openSession), `chat_page_test.dart` (history rendering, actions).
6. [ ] Gates
   - `flutter analyze` clean, `flutter test` green.
   - Full-scope trellis-check on last iteration.
