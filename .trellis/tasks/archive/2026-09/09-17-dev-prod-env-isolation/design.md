# design — dev/prod 环境隔离

## Boundaries

All changes live in `lib/core/config/` + tests + README. No network client,
repository, or widget code changes: `api_client.dart` / `sse_client.dart` /
`agent_stream_client.dart` keep reading `appConfigProvider.baseUrl`, and
`main.dart` keeps calling the same two `load()` functions — the isolation is
enforced inside the config layer, before any provider exists.

## New: `lib/core/config/app_env.dart`

```dart
enum AppEnv { dev, prod }

extension AppEnvX / static helper on AppEnv (or a tiny class):
  static const String _envValue = String.fromEnvironment('APP_ENV');

  /// Compile-time resolution: explicit APP_ENV wins (case-insensitive),
  /// otherwise kReleaseMode decides (release → prod, else dev).
  static AppEnv get current { ... }
```

- Kept dependency-free (`package:flutter/foundation.dart` for `kReleaseMode`
  only) so both config files and tests can import it.
- Unknown `APP_ENV` values (typos, `staging`) fall back to the build-mode
  default; documented in the doc comment. Debug-only assert is not used —
  silent fallback keeps third-party CI wrappers safe.

## `AppConfig` changes (`app_config.dart`)

Split pure logic from I/O so tests can drive every combination
(`String.fromEnvironment` is baked at compile time and unreadable from
tests):

```dart
/// Pure decision core — unit-tested exhaustively.
static AppConfig resolve({
  required AppEnv env,
  String compileTimeUrl = '',     // _envBaseUrl in production code
  String? persistedOverride,      // prefs value in production code
})

static Future<AppConfig> load({AppEnv env = AppEnv.current}) async {
  final prefs = await SharedPreferences.getInstance();
  return resolve(
    env: env,
    compileTimeUrl: _envBaseUrl,
    persistedOverride: env == AppEnv.prod ? null : prefs.getString(_prefsKey),
  );
}
```

`resolve` rules:

| env | resolution |
|-----|-----------|
| dev | unchanged: persisted → compile-time → platform default (http ok) |
| prod | compile-time URL only; must be non-empty and `https://`; else `throw StateError('API_BASE_URL must be set to an https URL for prod builds (--dart-define=API_BASE_URL=https://...)')` |

`isDefault` compares against the same resolution the instance was built
from; it stays a simple equality against the effective default for the
current env.

`saveBaseUrl()`:

- dev: unchanged (persist, empty clears).
- prod: no-op — returns `this` without touching `shared_preferences`
  (defense in depth on top of `load()` ignoring the key; a stray write from
  a future settings UI can never affect a prod build's network target).

Provider fallback (`appConfigProvider`) keeps `defaultBaseUrl` — it exists
only before `main()` overrides it; prod correctness is enforced by
`load()`, not the placeholder.

## `OidcConfig` changes (`oidc_config.dart`)

Same shape:

```dart
static OidcConfig resolve({
  required AppEnv env,
  String? persistedIssuer, String? persistedClientId,
  String? persistedRedirectUri, String? persistedScopes,
})

static Future<OidcConfig> load({AppEnv env = AppEnv.current}) async {
  final prefs = await SharedPreferences.getInstance();
  return env == AppEnv.prod
      ? resolve(env: env)                    // prefs ignored entirely
      : resolve(env: env, persistedIssuer: ..., ...);
}
```

Rules:

| env | resolution |
|-----|-----------|
| dev | unchanged: persisted → dart-define → platform default; empty issuer = compat mode |
| prod | dart-define / platform defaults only; issuer must be non-empty after trim, else `throw StateError('OIDC_ISSUER must be set for prod builds (--dart-define=OIDC_ISSUER=...)')` |

Prod keeps a non-empty issuer check only — clientId/scopes keep their
sane defaults (`kb-web`, `openid`) when the dart-define is absent; redirect
URI keeps the platform default. No https check on the issuer here: Keycloak
realms behind http are a backend/infra concern and the existing dev realm
uses http (the https requirement is deliberately scoped to the API base
URL).

## Data flow / compatibility

- `main.dart` calls `load()` with the default `env: AppEnv.current` — no
  call-site change.
- Existing tests express dev contracts; they must pass untouched. New tests
  target `resolve()` directly (pure, no prefs mocking needed) plus a few
  `load(env: ...)` tests with `SharedPreferences.setMockInitialValues` for
  the ignore-override paths.
- Serialization keys unchanged; no migration needed (prod simply ignores
  stale dev keys).

## Failure semantics

- Fail fast beats graceful degradation here: a misconfigured prod build is a
  packaging defect that QA must see at first launch, not a runtime error
  users hit after install. `load()` runs before `runApp`, so the throw
  surfaces as an immediate startup failure with the fix in the message.

## Known consequence (accepted)

- Android release builds still lack the `INTERNET` permission (debug/profile
  overlays only), so a prod Android artifact cannot reach the network at the
  OS level regardless of this work. Accepted in the PRD (out of scope);
  revisit before shipping a real prod Android build.

## Rollout / rollback

- Pure client-side change, no backend contract, no persisted-format change.
- Rollback = revert the commit; no data migration.
