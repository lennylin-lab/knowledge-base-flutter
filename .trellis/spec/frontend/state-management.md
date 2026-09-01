# State Management

> How state is managed in this project.

---

## Overview

**Riverpod (flutter_riverpod)** is the single state solution — chosen in the
project brief and applied everywhere. No mixing with bloc or setState-based
global state. (`setState` is fine for purely local, ephemeral widget state.)

**Riverpod ≥3.3 auto-retry is DISABLED** (`ProviderScope(retry: noAutomaticRetry)`
from `lib/core/retry_policy.dart`): Riverpod retries failed providers up to
10× with backoff by default, silently re-firing requests — that would hammer
a rate-limited backend and bypass the error-handling spec. Every test scope
must also pass `retry: noAutomaticRetry`. Note: `AsyncValue.valueOrNull` is
gone in Riverpod 3 — use `.value`.

---

## State Categories

| Category | Where it lives | Examples |
|----------|----------------|----------|
| Ephemeral widget state | `StatefulWidget` + `setState` | text field contents, chip toggles |
| Server state | Feature `AsyncNotifier` | documents list + cursor, search results, document detail |
| Streaming state | Feature `Notifier` | chat answer assembly from SSE events |
| App configuration | `Provider<AppConfig>` | API base URL |
| Navigation/route state | `go_router` | current tab, selected document id |

Rule: if the data came from the backend, it belongs in a provider, not in a
widget field.

---

## When to Use Global State

Almost never beyond the categories above. A provider is "global" by default in
Riverpod; keep it feature-scoped by placing it in the feature directory and not
importing it elsewhere. Only `core/` providers (api client, config, theme) are
truly app-wide.

---

## Server State

- Documents list: `AsyncNotifier<DocumentPage>` holding `items` + `next_cursor`;
  actions: `loadNext()`, `applyCreate/Update/Delete` (either patch locally or
  invalidate + refetch first page — prefer simple refetch in MVP).
- Detail: `FutureProvider.family<DocumentReadDetail, String>`, invalidated after
  edit/delete.
- Search: results owned by the search page's notifier; no cross-page cache needed.
- All writes go through the repository; UI optimistically disables controls and
  surfaces errors via `AsyncValue` / `ref.listen`.

---

## Chat SSE State Machine (critical)

Single-turn, stateless QA. The chat notifier implements this state machine:

```
idle → run_started (keep run_id, mode)
     → sources*     (append to sources list — event may repeat)
     → answer_delta* (concatenate text deltas verbatim)
     → done          (terminal: outcome success, tool_calls, latency_ms)
     | error         (terminal: code + message → user-facing error)
```

- `sources` is cumulative across multiple `sources` events; citation `[n]`
  indexes into this accumulated list.
- On widget dispose, cancel the subscription and return to `idle`.
- HTTP status may already be 200 when an `error` event arrives — the SSE layer,
  not dio, reports it.

---

## Common Mistakes

- Keeping a `List` of chat messages — there are no conversation turns in the
  backend (single-turn only). UI may keep local history for display, but each
  question is an independent request.
- Treating `next_cursor == null` as an error — it means "end of list".
- Mutating DTO lists in place — freezed models are immutable; copy/replace.
