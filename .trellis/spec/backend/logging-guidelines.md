# Logging Guidelines (Client)

> Client-side logging rules for this repo. Backend logging conventions live in
> `../knowledge-base-server/.trellis/spec/backend/logging-guidelines.md`.

---

## What to Log

- Errors with `ApiException.code`, HTTP status, request path and duration —
  enough to debug without exposing content.
- SSE anomalies: terminal `error` events, unexpected event order, stream drops.

## What NOT to Log (privacy)

- Document `content` (it is the user's personal knowledge base).
- Full chat questions/answers — at most length + run_id + outcome.
- Base URLs containing LAN IPs are fine; credentials never appear (no auth in
  MVP anyway).

---

## How

- Use `debugPrint` (or `package:logging`) — output visible in `flutter run`
  consoles on all three platforms; no file logging in MVP, no crash-report SDK.
- Wrap log calls so they compile out or no-op in release builds
  (`kDebugMode` guard) — release builds must stay silent.
- Log levels: `warning` for recoverable API errors (4xx), `severe` for 5xx /
  SSE terminal errors, `info` only for app lifecycle milestones.
