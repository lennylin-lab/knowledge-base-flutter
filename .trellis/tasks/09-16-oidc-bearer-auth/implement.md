# Implement — Keycloak OIDC login with Bearer token on API/SSE

Ordered checklist. Validation after every batch: `flutter analyze` and
`flutter test` must stay green. Rollback point = each batch is one commit
(no push until the quality gate passes).

## Batch 1 — foundation (config + auth core)

- [ ] Add dependencies: `crypto`, `url_launcher` (+ Android manifest
      `<queries>` https entry), `flutter_secure_storage`; `flutter pub get`.
- [ ] `lib/core/config/oidc_config.dart`: fields, platform default redirect
      (web `${Uri.base.origin}/auth/callback`, windows `localhost:8182`,
      android `127.0.0.1:8182`), dart-define → persisted override
      precedence, `isEnabled`, `oidcConfigProvider`, `load()` for `main()`.
- [ ] `lib/core/auth/auth_session.dart`: value type + JWT `sub` peek +
      validity skew check.
- [ ] `lib/core/auth/token_store*.dart`: `TokenStore` interface, io impl
      (flutter_secure_storage), web impl (shared_preferences), stub;
      conditional import.
- [ ] `lib/core/auth/auth_transaction.dart`: web sessionStorage stash
      (state, verifier, returnTo) with conditional import.
- [ ] `lib/core/auth/oidc_client.dart`: discovery (cached), PKCE helpers,
      authorize URL builder, code exchange, refresh, token-error mapping.
- [ ] `lib/core/auth/loopback_redirect_server.dart`: bind from redirect URI,
      await code/state (or IdP error), HTML completion page, timeout, close.
- [ ] Tests: `test/core/config/oidc_config_test.dart`,
      `test/core/auth/oidc_client_test.dart`.

## Batch 2 — controller + request plumbing

- [ ] `lib/core/auth/auth_controller.dart`: `AuthState`, `AuthController`
      (sign-in per platform, web callback completion, `getValidAccessToken`,
      `refreshAccessToken` single-flight, `signOut`, auto-clear), providers
      (`authEnabledProvider`, `authSeedProvider`,
      `authControllerProvider`, header-builder provider).
- [ ] `main.dart`: load session + OIDC config before first frame, seed
      overrides.
- [ ] `api_client.dart`: optional auth resolvers, request interceptor,
      401 single-retry error interceptor (extra flag guards recursion).
- [ ] `chat_transport.dart` + native/web/stub: `headers` parameter.
- [ ] `sse_client.dart` + `agent_stream_client.dart`: optional headers
      builder, provider wiring.
- [ ] Tests: `test/core/auth/auth_controller_test.dart`, api_client auth
      interceptor tests, sse header propagation test.

## Batch 3 — UI + wiring

- [ ] `lib/core/auth/login_page.dart` (登录 card, busy, error+重试,
      Chinese copy, `AppSizes` tokens only).
- [ ] `lib/core/auth/auth_callback_page.dart` (progress → returnTo, error
      card).
- [ ] `lib/core/auth/auth_gate.dart`; wire into `MaterialApp.builder` in
      `app.dart`; add `/auth/callback` route.
- [ ] Logout affordance on the three root pages' app bars (shared widget;
      hidden in compat mode).
- [ ] Widget tests: gate off/on/signed-in.

## Batch 4 — docs + finish

- [ ] README: OIDC configuration table (dart-defines), Keycloak redirect
      URI matrix per platform, `--web-port` note, `adb reverse` note.
- [ ] Full-scope check (trellis-check): analyze/test + spec compliance.
- [ ] Manual verification on ≥2 platforms (web + windows) against local
      Keycloak; record results in the task journal.
- [ ] Spec update if a durable convention emerged; commit; close issue #2
      with a summary comment.

## Validation commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --dart-define=OIDC_ISSUER=http://localhost:8180/realms/kb   # smoke
```

## Rollback

Each batch is a self-contained commit; reverting Batch 2/3 restores
compat-mode behavior exactly (Batch 1 adds only unused modules + deps).
