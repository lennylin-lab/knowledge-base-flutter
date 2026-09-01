# Provider Guidelines (Riverpod)

> Custom stateful-logic reuse in this project is done with Riverpod providers —
> the Flutter equivalent of custom hooks. This file replaces a "hooks" guide.

---

## Overview

- State management is **flutter_riverpod** (see also state-management.md).
- Providers are the only sanctioned way to share stateful logic / server data
  between widgets. No singletons, no `InheritedWidget` hand-rolling, no service
  locator.
- Each feature exposes its providers from `<feature>/<feature>_providers.dart`.

---

## Provider Patterns

| Need | Provider kind |
|------|---------------|
| Repository / API client instance | `Provider` (overridable in tests) |
| One-shot fetch with refresh | `FutureProvider.family` (e.g. document detail by id) |
| Paginated / mutable server list | `AsyncNotifierProvider` + `AsyncNotifier` |
| Streaming chat state | `NotifierProvider` + `Notifier<ChatState>` driving an SSE subscription |
| App config (baseUrl) | `Provider<AppConfig>` from `main.dart` |

Example shape:

```dart
final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => DocumentsRepository(ref.watch(apiClientProvider)),
);

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, DocumentPage>(
      DocumentsNotifier.new,
);

class DocumentsNotifier extends AsyncNotifier<DocumentPage> {
  @override
  Future<DocumentPage> build() => _fetchPage();

  Future<void> loadNext() async { /* uses next_cursor; appends */ }
}
```

---

## Data Fetching Rules

1. Widgets `ref.watch(...)` in `build`; side effects (snackbar, navigation) use
   `ref.listen`, never `await` inside `build`.
2. `ref.read(...)` only inside callbacks (`onPressed`), never in `build`.
3. Repositories return typed results and throw `ApiException` — providers let it
   propagate into `AsyncValue.error`; UI maps it to Chinese copy.
4. Pagination is keyset-based: keep the last `next_cursor`; `null` means end of
   list. Never re-fetch page 1 to append.

---

## Naming Conventions

- Provider: `<noun>Provider` (`searchProvider`, `chatProvider`).
- Family: parameter included in name semantics (`documentDetailProvider(id)`).
- Notifier classes: `<Noun>Notifier` / `<Noun>AsyncNotifier`.
- File: one feature's providers together in `<feature>_providers.dart`.

---

## Common Mistakes

- Creating a provider inside `build()` or as a `static` field of a widget —
  providers are top-level finals.
- Watching a `NotifierProvider`'s state object and mutating it in place — always
  return a new state instance.
- Forgetting `ref.onDispose` to cancel an SSE subscription in the chat
  controller → leaked streams and ghost deltas after page exit.
- Storing derived values in state instead of computing them with
  `select` / getters.
