# Frontend Development Guidelines

> Flutter client (Web / Windows / Android) for the knowledge-base FastAPI
> backend. Specs below are binding for every implement/check session.

---

## Guidelines Index

| Guide | Description | Status |
|-------|-------------|--------|
| [Directory Structure](./directory-structure.md) | Feature-first `lib/` layout, platform dirs, naming | Filled |
| [Component Guidelines](./component-guidelines.md) | Widget rules, adaptive shells, domain patterns (index_status, citations, markdown) | Filled |
| [Provider Guidelines](./hook-guidelines.md) | Riverpod provider patterns (replaces a "hooks" guide) | Filled |
| [State Management](./state-management.md) | Riverpod state categories, chat SSE state machine | Filled |
| [Type Safety](./type-safety.md) | freezed DTO ↔ backend schema mapping, JSON rules, enums | Filled |
| [Quality Guidelines](./quality-guidelines.md) | analyze/test gates, forbidden patterns, testing bar | Filled |

## Stack (fixed by project brief)

Riverpod (state) · go_router (routing) · dio (HTTP) · freezed +
json_serializable (DTOs) · build_runner · shared_preferences (local config) ·
flutter_markdown_plus for rendering (**flutter_markdown is discontinued**).

## Key Facts

- API base URL is platform-aware (`AppConfig`): web/windows
  `http://localhost:8000`, Android emulator `http://10.0.2.2:8000`.
- UI copy is Chinese-first; LLM answers render verbatim.
- MVP platforms only: web, windows, android — no ios/macos/linux dirs.
- Backend contract lives in the backend repo: `knowledge-base-server/.trellis/spec/backend/`.

---

**Language**: All documentation should be written in **English**.
