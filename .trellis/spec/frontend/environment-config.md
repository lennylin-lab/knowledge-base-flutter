# Environment Config (dev / prod)

> Binding contract for `AppEnv`, `AppConfig`, and `OidcConfig`
> (`lib/core/config/`). Introduced by task `09-17-dev-prod-env-isolation`.
> Any change to base-URL / OIDC resolution, a new dart-define key, or a new
> persisted config key must preserve the isolation below.

---

## 1. Scope / Trigger

- Trigger: env wiring (dart-define keys + persisted config) is infra-adjacent;
  a prod build silently pointing at a dev loopback URL or running without
  auth is a release defect that must be impossible by construction.

## 2. Signatures

```dart
// lib/core/config/app_env.dart
enum AppEnv { dev, prod }
AppEnv get AppEnv.current;            // compile-time: APP_ENV ?? kReleaseMode
AppEnv AppEnv.fromRaw(String? raw);   // pure parser (unit-testable)

// lib/core/config/app_config.dart
static AppConfig AppConfig.resolve({required AppEnv env,
    String compileTimeUrl, String? persistedOverride});   // pure, throws in prod
static Future<AppConfig> AppConfig.load({AppEnv? env});   // I/O glue, main()
Future<AppConfig> saveBaseUrl(String baseUrl, {AppEnv? env}); // prod: no-op

// lib/core/config/oidc_config.dart — same shape
static OidcConfig OidcConfig.resolve({required AppEnv env,
    /* compileTime* + persisted* params */});
static Future<OidcConfig> OidcConfig.load({AppEnv? env});
```

## 3. Contracts

**Environment resolution** (lowest → highest):

1. build mode — `kReleaseMode` → prod, debug/profile → dev;
2. `--dart-define=APP_ENV=dev|prod` (case-insensitive, trimmed; an unknown
   value falls back to the build-mode default — no crash).

**dart-define keys**: `APP_ENV`; `API_BASE_URL` (required + https in prod);
`OIDC_ISSUER` (required non-empty in prod); `OIDC_CLIENT_ID` /
`OIDC_REDIRECT_URI` / `OIDC_SCOPES` optional (sane defaults in both envs).

**Resolution matrix**:

| Config | dev | prod |
|---|---|---|
| `baseUrl` | persisted → `API_BASE_URL` → platform default (http ok) | `API_BASE_URL` only, must be `https://` |
| `oidc.*` | persisted → dart-define → default; empty issuer = compat mode | dart-define/default only; issuer required |

## 4. Validation & Error Matrix

| Condition | Behavior |
|---|---|
| prod + missing/empty `API_BASE_URL` | `StateError` naming `--dart-define=API_BASE_URL=https://...` at startup |
| prod + `http://` `API_BASE_URL` | same fail-fast |
| prod + empty `OIDC_ISSUER` | `StateError` naming `--dart-define=OIDC_ISSUER=...` |
| prod + persisted `app_config.base_url` / `oidc.*` | silently ignored (never read) |
| prod `saveBaseUrl()` | no-op — returns `this`, no prefs write |

Fail-fast is deliberate: `load()` runs before `runApp`, so a misconfigured
prod build dies at first launch with the fix in the message.

## 5. Good / Base / Bad Cases

- **Good**: `flutter build web --release --dart-define=APP_ENV=prod
  --dart-define=API_BASE_URL=https://api.example.com
  --dart-define=OIDC_ISSUER=https://idp.example.com/realms/kb`
- **Base**: `flutter run -d chrome` (debug, no defines) → dev,
  `http://localhost:8000`, compat auth mode.
- **Bad**: release build without `API_BASE_URL`/`OIDC_ISSUER` → startup
  crash. Intentional; never "fix" by adding a prod http fallback.

## 6. Tests Required

- `test/core/config/app_env_test.dart`: `fromRaw` explicit values, case and
  whitespace tolerance, unknown → build-mode fallback.
- `test/core/config/app_config_test.dart` / `oidc_config_test.dart`: prod
  ignore-overrides, prod fail-fast errors, dev chain unchanged. The
  pre-existing dev tests are a regression contract — do not edit them.

## 7. Wrong vs Correct

### Wrong

```dart
// Reading/writing persisted config without env gating
final url = prefs.getString('app_config.base_url');  // leaks into prod
```

### Correct

```dart
// Persisted values only ever enter through resolve(..., persistedOverride:),
// and load() passes null in prod
AppConfig.resolve(
  env: env,
  compileTimeUrl: _envBaseUrl,
  persistedOverride: env == AppEnv.prod ? null : prefs.getString(_prefsKey),
);
```

New config keys must follow the same `resolve(env, compileTime, persisted)`
shape and declare their prod rules in this file.
