# PRD — feat(auth): Keycloak OIDC login with Bearer token on API/SSE

Source: GitHub issue #2
(https://github.com/lennylin-lab/knowledge-base-flutter/issues/2). Backend
reference: `../knowledge-base-server/docs/identity-tenants.md` (task
`09-15-gateway-integration-v2`).

## Problem

When the backend runs with `KB_OIDC_ISSUER` set, every business route
(documents, search, sessions, chat/writing SSE, agent operations) requires
`Authorization: Bearer <access_token>`. The Flutter client has no login and
no token injection, so every request fails with 401 `unauthorized`.

## Requirements

1. **OIDC configuration** — new `OidcConfig` (issuer, client id, redirect
   URI, scopes) resolved like `AppConfig.baseUrl`: platform defaults ←
   `--dart-define` (`OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_REDIRECT_URI`,
   `OIDC_SCOPES`) ← persisted user override. Empty issuer = **compat mode**
   (auth fully off, app behaves exactly as today — mirrors backend
   `KB_OIDC_ISSUER` empty).
2. **Login** — Authorization Code + PKCE (`kb-web` public client):
   - Web: full-page redirect to the IdP and back to an `/auth/callback`
     go_router route (code + state handled there).
   - Windows / Android: system browser via `url_launcher` + a loopback
     `HttpServer` redirect listener (`http://localhost:8182/...` on Windows,
     `http://127.0.0.1:8182/...` on Android emulator/device).
   - Discovery document (`{issuer}/.well-known/openid-configuration`) is
     fetched for the authorization/token endpoints — no Keycloak-specific
     paths in client code.
3. **Token lifecycle** — persist session (access token, refresh token,
   expiry, subject) across restarts; silent refresh via
   `grant_type=refresh_token` before expiry and on first 401; single-flight
   refresh (parallel 401s share one refresh); refresh failure clears the
   session and the login gate reappears.
4. **Bearer on every business request** — REST via a dio request
   interceptor on `ApiClient`; SSE (chat, document summary/associations
   agent streams, both native and web transports) via the shared
   `ChatTransport` interface. `/healthz` and token-endpoint calls carry no
   user token. Never send `X-Tenant-ID` / `X-User-ID`; never derive
   authorization from claims.
5. **UI** — when auth is enabled and there is no valid session, the app
   shows a login gate (Chinese-first copy) instead of the content shell;
   401 after a failed refresh drops the user back to the gate; 403
   surfaces as the existing error UI with backend message. Logout clears
   the local session and returns to the gate.
6. **Storage** — native (Windows/Android): `flutter_secure_storage`; web:
   `shared_preferences` (same store as the other app prefs). Tokens never
   enter git; all secrets come from dart-define/runtime config.

## Non-goals

- No custom username/password page (IdP hosts the login UI).
- No multi-tenant switching UI (single `default` tenant MVP).
- No role-based button hiding (403 shown uniformly per issue RBAC section).
- No `flutter_appauth` dependency — a self-contained PKCE client keeps
  Windows support (appauth has none) and avoids two acquisition stacks.

## Acceptance criteria

- [ ] With a local Keycloak + OIDC-enabled backend: login completes, then
      documents list, search, and chat SSE streaming work end to end.
- [ ] Without login / with an invalid token: REST and SSE surface 401 with
      clear UI guidance (login gate).
- [ ] Expired access token refreshes silently (or one retry succeeds)
      without user action.
- [ ] Compat mode (no issuer configured) is byte-for-byte the current
      behavior; no auth UI, no Authorization header.
- [ ] Verified on at least two of: Android emulator, Web (Flutter run),
      Windows build.
- [ ] `flutter analyze` and `flutter test` green; unit tests cover PKCE,
      token refresh/single-flight, interceptor injection + 401 retry, SSE
      header propagation, config resolution.
