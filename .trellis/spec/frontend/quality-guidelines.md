# Quality Guidelines

> Code quality standards for the Flutter client.

---

## Overview

Baseline commands (must pass before any task is reported done):

```bash
flutter analyze   # zero errors; treat warnings as must-fix
flutter test      # all green
```

---

## Forbidden Patterns

| Pattern | Why |
|---|---|
| `dio` / repository calls inside widget `build` | rebuild storms; fetch goes through providers |
| Hardcoded API URLs in feature code | base URL is environment/platform-specific (`AppConfig`) |
| Raw `Map<String, dynamic>` in UI | bypasses DTO type safety (see type-safety.md) |
| Swallowing `ApiException` with empty catch | every backend error surfaces to the user in Chinese |
| Adding ios/macos/linux platform dirs | MVP scope is web/windows/android only |
| `flutter_markdown` | discontinued — use `flutter_markdown_plus` |
| Hardcoded UI sizes (`size: N`, magic `EdgeInsets`/`SizedBox`) | sizes must follow the viewport via `AppSizes` tokens (`context.sizes`) — see component-guidelines.md |
| Business logic inside `onPressed` callbacks | move to notifier/repository; callbacks only call methods |

---

## Required Patterns

- Error envelope handling in **one place**: a dio interceptor (or repository
  base) that parses `{ "error": { code, message, details } }` into
  `ApiException(code, message, details)` — features never parse envelopes.
- SSE parser isolated in `core/network/sse_client.dart` with unit tests; no SSE
  string handling in widgets.
- Chinese-first user-facing copy; backend error `message` shown verbatim with a
  Chinese prefix (e.g. "保存失败：{message}").
- Responsive shells per component-guidelines.md (rail on wide, bottom nav on
  compact).

---

## Testing Requirements

Minimum bar (from the project brief):

1. **Unit: SSE parser** — feed sample byte chunks; assert event order
   `run_started → sources → answer_delta* → done`, multi-`sources` append,
   terminal `error`, and partial-chunk buffering.
2. **Unit: error envelope decoding** — envelope → `ApiException` mapping for
   404/409/422/429/502/503 samples, plus non-envelope bodies (proxy errors).
3. **Unit: DTO round-trip** — `fromJson`/`toJson` for the models in
   shared/models against fixture JSON matching the backend OpenAPI schema.
4. **Widget smoke**: app boots, navigation switches between 文档/搜索/问答.

Use fixture JSON files over inline strings when a payload exceeds ~20 lines.
Repository tests may fake `Dio` via a mock adapter rather than a live server.

---

## Code Review Checklist

- [ ] `flutter analyze` / `flutter test` clean
- [ ] New network code went through repository + DTO (no ad-hoc HTTP)
- [ ] Loading / empty / error branches all render
- [ ] Wide and compact layouts both checked
- [ ] Any backend contract change is reflected in DTOs and the type-safety spec
- [ ] No user document content in logs
