# implement — dev/prod 环境隔离

Ordered checklist. Validation after every step: `flutter analyze` (zero
errors) and `flutter test` (green). Full gate re-run at the end.

## Step 1 — `AppEnv` signal

- [ ] Create `lib/core/config/app_env.dart`: `enum AppEnv { dev, prod }`
      + `AppEnv.current` (compile-time `APP_ENV` dart-define,
      case-insensitive `dev`/`prod`; fallback `kReleaseMode → prod : dev`;
      unknown values fall back to build mode).
- [ ] Doc comment states the resolution order and the unknown-value rule.

## Step 2 — `AppConfig` prod isolation

- [ ] Add pure `AppConfig.resolve({required AppEnv env, String compileTimeUrl, String? persistedOverride})`
      implementing: dev = persisted → compile-time → platform default;
      prod = compile-time only, non-empty + `https://` required, else
      `StateError` naming `--dart-define=API_BASE_URL=https://...`.
- [ ] `load({AppEnv env = AppEnv.current})` reads prefs and delegates to
      `resolve`, passing `null` override in prod.
- [ ] `saveBaseUrl()` returns `this` unchanged in prod (no prefs write);
      dev path untouched.
- [ ] Update the class doc comment (resolution table, prod rules).

## Step 3 — `OidcConfig` prod isolation

- [ ] Add pure `OidcConfig.resolve({required AppEnv env, persisted* params})`:
      dev = existing chain; prod = prefs ignored, issuer must be non-empty
      after trim, else `StateError` naming `--dart-define=OIDC_ISSUER=...`.
- [ ] `load({AppEnv env = AppEnv.current})` skips prefs reads in prod.
- [ ] Update the class doc comment.

## Step 4 — Tests

- [ ] `test/core/config/app_env_test.dart`: explicit dev/prod (both cases),
      unknown value → build-mode fallback (assert dev on non-release test
      runner), whitespace tolerance. (`AppEnv.current` in tests always
      resolves to dev since test runners are not release mode — assert only
      what is stable.)
- [ ] `test/core/config/app_config_test.dart`: keep existing dev tests;
      add groups — prod ignores persisted override (`load(env: prod)` with
      mock prefs set), prod `saveBaseUrl` no-op (prefs stay empty),
      `resolve` prod throws on empty URL, throws on `http://` URL, accepts
      `https://`, `isDefault` correct; dev `resolve` keeps http defaults.
- [ ] `test/core/config/oidc_config_test.dart`: keep existing dev tests;
      add — prod ignores all four persisted keys, `resolve` prod throws on
      empty issuer, accepts explicit issuer, defaults for
      clientId/scopes/redirect still apply in prod; dev compat mode
      (empty issuer) still loads.

## Step 5 — README

- [ ] Document `APP_ENV` in the dart-define table; add a short "环境隔离"
      paragraph: prod rules (prefs ignored, https required, OIDC issuer
      required, fail-fast at startup) and that debug/profile builds are dev
      by default.

## Step 6 — Full gate + review

- [ ] `flutter analyze` → zero errors.
- [ ] `flutter test` → all green.
- [ ] Cross-check: `grep -rn 'http://' lib/` — only dev-loopback literals in
      `app_config.dart` / `oidc_config.dart` remain.

## Validation commands

```bash
flutter analyze
flutter test
```

## Rollback points

- After each step the tree is analyze-clean; a failure mid-way can be
  reverted per-file without breaking the build (Step 2/3 depend on Step 1;
  nothing else depends on Steps 4–5).
