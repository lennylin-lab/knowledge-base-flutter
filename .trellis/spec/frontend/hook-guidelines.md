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
| Manual-trigger LLM result (summary, associations) | family `NotifierProvider` over `OnDemandGenerationNotifier<T>` — see below |
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

### Pattern: On-demand generation (`OnDemandGenerationNotifier<T>`)

For server calls that are **slow, billed, and not persisted server-side**
(LLM endpoints like `POST /documents/{id}/summary|associations`), never use an
auto-fetching provider — opening a page must fire zero calls. Use a family
`Notifier` whose state is `OnDemandState<T>` (last `result` + `isGenerating` +
last `error`):

- `build()` fetches **nothing**; it only bumps a generation counter.
- `generate(id)` no-ops while `isGenerating` (set synchronously before the
  first `await`, so same-frame double taps cannot double-fire); success
  replaces the prior result; failure keeps the prior result visible and stores
  the error for the UI.
- Late responses are dropped when `_generation != generation` (same
  stale-guard as `DocumentsNotifier.loadNext`) — an invalidate mid-flight must
  not let the stale result land anywhere.
- The UI shows progress while generating and keeps the trigger affordance
  visible on error (component-guidelines: no error dead-ends).
- `generate()` consumes the agent SSE stream through the repository's
  `onProgress` callback; `OnDemandState.progress` is additive state cleared
  on every terminal write, and progress callbacks pass the same generation
  guard as terminal writes (a superseded generation's late progress is
  dropped).
- **In-widget content layers** (the AI assistant bubble on the detail page):
  the bubble is the only AI surface — menu layer (入口) ↔ function content
  layer, no separate routes. Entry click is the explicit trigger: generate
  once when there is no cached result and nothing is in flight (never in
  `build()`), and keep the providers alive while the host surface is open
  (watch them at the menu layer) so re-entering shows the cache instead of
  re-billing. A back affordance returns to the menu layer, every dismiss
  path resets to it, the host page's `PopScope` intercepts system back at
  the content layer, and every error branch inside the bubble carries an
  inline 重试 (no fab to fall back on).

Reference implementation: `lib/features/documents/documents_providers.dart`
(`DocumentSummaryNotifier` / `DocumentAssociationsNotifier`),
`lib/features/documents/document_ai_bubble.dart` (content layer) and
`AiAssistantFab` in `lib/features/documents/document_detail_page.dart`
(layer switching, keep-alive watch, PopScope wiring).

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
