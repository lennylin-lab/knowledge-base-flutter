# Directory Structure

> How frontend code is organized in this project.

---

## Overview

This is a **Flutter** cross-platform app (Web / Windows / Android) that talks to a
separate FastAPI backend (`../knowledge-base-server`). The layout is
**feature-first**: everything a feature needs lives under `lib/features/<name>/`,
while cross-cutting infrastructure lives under `lib/core/` and truly shared
pieces under `lib/shared/`.

The full layout is defined by the project brief and must not drift:

```
knowledge-base-flutter/
├── lib/
│   ├── main.dart                 # entry point: bootstrap config + providers
│   ├── app.dart                  # MaterialApp + go_router routes + theme
│   ├── core/
│   │   ├── config/app_config.dart    # baseUrl etc. (env/platform-aware)
│   │   ├── network/
│   │   │   ├── api_client.dart       # dio instance, interceptors
│   │   │   ├── api_exception.dart    # unified error envelope model
│   │   │   └── sse_client.dart       # Chat SSE stream parsing
│   │   └── theme/                    # ThemeData, light/dark
│   ├── features/
│   │   ├── documents/    # list / detail / editor pages + repository
│   │   ├── search/       # search page + repository
│   │   └── chat/         # QA page + SSE stream controller
│   └── shared/
│       ├── models/       # freezed DTOs, mirror backend schemas exactly
│       └── widgets/      # reusable widgets (status chips, error views)
├── test/                  # mirrors lib/ layout
├── web/  windows/  android/   # ONLY these three platforms; no ios/macos/linux
└── pubspec.yaml
```

---

## Module Organization

Each `features/<name>/` directory contains:

| File | Role |
|------|------|
| `<name>_repository.dart` | The ONLY place that calls dio for this feature |
| `<name>_page.dart` (or several pages) | Screen widgets |
| `widgets/` | Feature-private widgets (prefix `_` if in same file) |
| `<name>_providers.dart` | Riverpod providers/notifiers for this feature |

Rules:

1. **Features never import each other's internals.** Cross-feature navigation
   goes through go_router path names, not direct widget imports.
2. **DTOs live in `lib/shared/models/`**, not inside features — they mirror the
   backend's `src/app/schemas/` and are shared by all features.
3. `core/network/` must not import from `features/` or `shared/widgets/`
   (dependency direction: features → core/shared).
4. `core/auth/` (OIDC/session) may import `core/config` and
   `core/network/api_exception.dart`; conversely `core/network` providers
   (`api_client.dart`, `sse_client.dart`, `agent_stream_client.dart`) may
   import `core/auth` only to wire the auth resolvers/header builders —
   file-level imports stay acyclic, `ref.watch` of auth state in
   `apiClientProvider` is forbidden (dio must not rebuild per token).
5. Flutter web uses the **path URL strategy** (`usePathUrlStrategy()` in
   `main()`) — OAuth redirect URIs forbid fragments, so hash-mode URLs
   (`/#/route`) cannot carry the OIDC callback; serving `build/web`
   requires an SPA fallback for non-asset paths.

---

## Naming Conventions

- Files and directories: `snake_case.dart`, named after the main public symbol.
- One public widget per page file; small private widgets may share the file.
- Providers: `documentsProvider`, `documentDetailProvider(id)`, notifiers
  `DocumentsNotifier` / `DocumentsAsyncNotifier`.
- Repositories: `DocumentsRepository`, `SearchRepository`, `ChatRepository`.
- Pages end in `Page` (`DocumentEditorPage`), reusable widgets do not
  (`IndexStatusChip`, `ErrorPane`).

---

## Platform Rules

- `flutter create` was run with `--platforms=web,windows,android` —
  do NOT add ios/macos/linux directories in the MVP.
- Android id: `dev.lenny.knowledge_base_flutter`.
- Platform differences (base URL, SSE transport) are resolved inside
  `core/config/` and `core/network/`, never inside widgets.
- User-visible app metadata is Chinese (product name 知识库): Android
  `android:label`, web `<title>`/manifest name, Windows window title.
  Windows titles use UTF-8 BOM in `main.cpp` so MSVC decodes the wide
  literal correctly; `Runner.rc` stays ASCII (codepage 1252).
- Android debug builds allow cleartext HTTP (dev-only, debug overlay);
  release must never set `usesCleartextTraffic`.

---

## Examples

- Referenced by the task brief in the repo root (`tmp.md`) — the layout above
  is the authoritative version; update this file when the structure changes.
