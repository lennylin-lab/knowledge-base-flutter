# dev/prod 环境隔离

## Goal

Introduce an explicit dev/prod environment model for the Flutter client so
that release/production builds cannot be pointed at development endpoints —
by leftover persisted overrides, by missing build-time configuration, or by
insecure transport.

## Background

Today the network configuration has a single resolution chain
(`platform default → --dart-define → shared_preferences override`) that is
completely blind to the build mode: a release build picks up whatever URL or
OIDC issuer was persisted on the device, silently falls back to
`http://localhost:8000`, and can enter the no-auth compat mode when the OIDC
issuer is empty.

## Requirements

### R1 — Environment signal

- A new `AppEnv { dev, prod }`, resolved once as `AppEnv.current`:
  1. `--dart-define=APP_ENV=dev|prod` (case-insensitive) wins;
  2. otherwise the build mode decides: `kReleaseMode` → prod,
     debug/profile → dev;
  3. an unrecognized `APP_ENV` value falls back to the build-mode default
     (no crash, documented).

### R2 — Prod isolation of `AppConfig` (base URL)

- **Ignore persisted overrides** in prod: `app_config.base_url` in
  `shared_preferences` is not read; `saveBaseUrl()` is a no-op that does not
  write.
- **HTTPS enforced** in prod: the effective base URL must be `https`.
- **Fail fast** in prod: if no `API_BASE_URL` is provided, or it is not
  `https`, `AppConfig.load()` throws a `StateError` with an actionable
  message (naming the `--dart-define=API_BASE_URL=https://...` fix). A prod
  build must never silently point at a dev loopback URL.
- Dev behavior is unchanged: platform default → dart-define → persisted
  override, http allowed.

### R3 — Prod isolation of `OidcConfig`

- **Issuer required** in prod: an empty issuer must not silently enter the
  no-auth compat mode; `OidcConfig.load()` throws a `StateError` naming the
  `--dart-define=OIDC_ISSUER=...` fix.
- **Ignore persisted overrides** in prod: `oidc.*` keys in
  `shared_preferences` are not read.
- Dev behavior is unchanged, including the empty-issuer compat mode.

### R4 — Testability

- `String.fromEnvironment` / `kReleaseMode` cannot be controlled in tests,
  so the decision logic must be separated from the I/O glue: pure
  `resolve`-style functions taking `(env, compileTimeValue, persistedValue)`
  are unit-tested directly; `load()` stays a thin wrapper.

### R5 — Documentation

- README's configuration sections document `APP_ENV`, the prod resolution
  rules, and the fail-fast requirements.

## Out of scope

- Android `INTERNET` permission for release builds (user decision: keep the
  current "release cannot network on Android" property; revisit when a real
  prod Android artifact ships).
- New environments beyond dev/prod (staging etc.).
- Validation/malformed-URL handling changes in dev mode.

## Acceptance Criteria

- [ ] `AppEnv.current` prefers an explicit `APP_ENV` dart-define, else
      follows `kReleaseMode`; unknown values fall back to build mode.
- [ ] In prod, a persisted `app_config.base_url` is ignored and
      `saveBaseUrl()` does not persist.
- [ ] In prod, `AppConfig.load()` throws when the effective URL is missing
      or not `https`.
- [ ] In dev, all existing `AppConfig` behaviors are preserved
      (existing tests keep passing).
- [ ] In prod, `oidc.*` persisted overrides are ignored.
- [ ] In prod, `OidcConfig.load()` throws when the issuer is empty.
- [ ] In dev, empty-issuer compat mode still works.
- [ ] `flutter analyze` zero errors; `flutter test` all green.
- [ ] README documents the environment model.
