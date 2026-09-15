# Design — Keycloak OIDC login with Bearer token on API/SSE

## Decisions

- **Self-contained OIDC client** (Authorization Code + PKCE, S256) instead of
  `flutter_appauth` / `oauth2_client`: appauth has **no Windows support** and
  the other packages don't cover all three MVP platforms with one stack. The
  protocol surface we need (discovery, authorize URL, code exchange,
  refresh) is small and fully unit-testable offline.
- **One redirect strategy per platform family**:
  - **Web** — full-page redirect to the IdP; the app reloads on the
    `/auth/callback` go_router route and completes the exchange there
    (state + PKCE verifier stashed in `sessionStorage` for the round trip).
  - **Windows / Android** — launch the system browser with `url_launcher`
    and catch the redirect on a **loopback `HttpServer`**
    (`http://localhost:8182/auth/callback` on Windows,
    `http://127.0.0.1:8182/auth/callback` on Android, per RFC 8252 §7.6;
    the browser talks to loopback, so Android cleartext policy is not
    involved). Same dart:io code path for both.
- **Discovery first**: authorization/token endpoints come from
  `{issuer}/.well-known/openid-configuration` (fetched once, cached) — no
  Keycloak-specific paths in client code.
- **Compat mode**: `issuer` empty ⇒ auth disabled everywhere (no gate, no
  header, providers pass through) — mirrors the backend's empty
  `KB_OIDC_ISSUER`. No 401-probing heuristics.
- **Identity claims are display data.** Client decodes `sub` (unverified) for
  the session record only. No `X-Tenant-ID` / `X-User-ID` headers, ever.

## Module layout (all under `lib/core/`)

```
lib/core/config/oidc_config.dart      # OidcConfig + oidcConfigProvider
lib/core/auth/
  auth_session.dart                   # immutable session value (+ JWT sub peek)
  token_store.dart                    # TokenStore interface; conditional impls:
  token_store_io.dart                 #   flutter_secure_storage (windows/android)
  token_store_web.dart                #   shared_preferences (web)
  token_store_stub.dart               #   fallback (avoid conditional-import gaps)
  auth_transaction.dart               # web-only PKCE round-trip stash (sessionStorage)
  oidc_client.dart                    # discovery, PKCE (crypto S256), authorize URL,
                                      #   code exchange, refresh — pure HTTP via own Dio
  loopback_redirect_server.dart       # dart:io loopback listener for native sign-in
  auth_controller.dart                # AuthController (Notifier<AuthState>) + providers
  auth_gate.dart                      # gate widget wired in MaterialApp.builder
  login_page.dart                     # 登录 gate UI
  auth_callback_page.dart             # /auth/callback landing (web exchange)
```

Dependency direction stays features → core; `core/auth` may import
`core/config` and `core/network` (for `ApiException`), nothing else new.

## Key contracts

### OidcConfig (mirrors `AppConfig` precedence)

platform defaults ← `--dart-define` (`OIDC_ISSUER`, `OIDC_CLIENT_ID`,
`OIDC_REDIRECT_URI`, `OIDC_SCOPES`) ← persisted override
(`oidc.issuer`, `oidc.client_id`, `oidc.redirect_uri`, `oidc.scopes` in
`shared_preferences`). Defaults: clientId `kb-web`, scopes `openid`,
redirect per platform (web: `${Uri.base.origin}/auth/callback`).
`bool get isEnabled => issuer.trim().isNotEmpty`.

### AuthSession / persistence

`{ accessToken, refreshToken?, expiresAt, subject? }` stored as one JSON
blob under key `auth.session`. Validity check =
`expiresAt.isAfter(now + 60s skew)`. `expiresAt` from token response
`expires_in`; `subject` = unverified JWT payload `sub` (defensive parse).

### AuthController (Riverpod `Notifier<AuthState>`)

`AuthState { AuthSession? session; bool signingIn; String? errorMessage; }`

- Seed from `main()` (loaded TokenStore value) via `authSeedProvider` — same
  pattern as theme/layout seeds.
- `signIn()` — web: stash transaction, `launchUrl(authorizeUrl, _self)`;
  native: bind loopback server, launch browser, await code (5 min timeout,
  cancel affordance), validate state, exchange, persist, set session.
- `completeWebCallback(code, state)` — consume stash, exchange, persist,
  returns `returnTo` for the callback page navigation.
- `getValidAccessToken()` — cached-if-valid else single-flight refresh;
  returns null when unfixable (clears session). Used by REST interceptor and
  SSE header builder.
- `refreshAccessToken()` — force single-flight refresh (used only by the
  REST 401-retry path).
- `signOut()` / auto-clear — delete store blob, reset state to signed-out.

### REST: `ApiClient`

Optional `AuthTokenResolver` (`Future<String?> Function()`) +
`ForceRefreshResolver` injected via `apiClientProvider` (reads the
controller notifier — never `ref.watch`es auth state, so dio is not rebuilt
on token changes):

- request interceptor: resolve token (if resolver present) →
  `Authorization: Bearer …`; resolver null (compat mode / tests) = no header.
- error interceptor (added before the envelope mapper): on
  `statusCode == 401` and not already retried (`requestOptions.extra['kbAuthRetried']`)
  → force refresh → if new token, mutate headers and `dio.fetch` the retry,
  `handler.resolve`; else fall through (envelope mapper → `unauthorized`).

### SSE: `ChatTransport`

Interface gains `open(Uri uri, String? jsonBody, {Map<String, String>? headers})`.
- native: headers merged into dio `Options.headers`.
- web: headers set on the fetch `RequestInit` JSObject; dio debug fallback
  merges likewise.
- `SseClient` / `AgentStreamClient` gain an optional
  `Future<Map<String, String>> Function()? headers` and pass it through;
  providers wire it from `authControllerProvider` via `ref.read` at open
  time (SSE has no retry — an `unauthorized` terminal error event is the
  surface, as today's chat error path already renders).

### UI wiring

- `app.dart`: `MaterialApp.builder` wraps the child with `AuthGate(router: …)`
  next to the existing `BrowserTabTitle`.
- `AuthGate`: disabled → child; enabled + session → child; enabled + no
  session → `LoginPage` (busy state while `signingIn`, error + 重试);
  `/auth/callback` path passes through (the callback page needs to run while
  still signed out). Auth state changes rebuild the gate, so a failed
  refresh anywhere drops the user onto the login page.
- Router: add top-level `GoRoute('/auth/callback')` (outside the shell).
- Logout affordance: compact icon button in each root page's app bar actions
  (shared widget) → `signOut()`; compat mode hides it.
- 403 keeps today's error rendering (backend message verbatim with Chinese
  prefix) per issue RBAC note.

## New dependencies

`crypto` (PKCE S256), `url_launcher` (browser launch; adds the Android 11+
`<queries>` https entry to the manifest), `flutter_secure_storage`
(native token store). Web token store reuses `shared_preferences`.

## Platform / dev-environment notes

- Web dev must run on a fixed port that Keycloak lists as a valid redirect
  (realm example allows 3000/5173): `flutter run -d chrome --web-port 5173`.
- Android emulator: Keycloak/backend on the host are reached through the
  issuer as written (`localhost:8180`) → document `adb reverse tcp:8180
  tcp:8180` (+ backend port) in the README; the issuer string must equal
  the backend's `KB_OIDC_ISSUER` verbatim.
- Native redirect ports (`8182`) must be added to the Keycloak client's
  valid redirect URIs (backend realm file) — documented, backend-repo change.
- Cleartext `http://` issuers are dev-only; production uses https issuers.

## Test plan (all offline, host VM)

1. `oidc_config_test` — defaults, persisted override precedence, compat flag.
2. `oidc_client_test` — verifier charset/length, challenge = S256(verifier),
   authorize URL params, discovery parse, code exchange + refresh against a
   mock `HttpClientAdapter`, token-error → ApiException mapping.
3. `auth_controller_test` — faked `TokenStore` + `OidcClient` + clock:
   sign-in completion, `getValidAccessToken` cache/skew, single-flight
   refresh (concurrent callers, one exchange), refresh failure clears
   session, signOut.
4. `api_client` auth tests — header present/absent; 401 → one forced refresh
   → retry succeeds; refresh failure → `unauthorized` surfaces.
5. `sse_client` — headers reach the transport; compat mode passes none.
6. Widget — gate off renders documents shell; gate on + signed out renders
   `LoginPage`; signed in renders shell.

## Risks / mitigations

- Browser round-trip latency and cancel paths on native: loopback server has
  a timeout + explicit 取消 button; server close is guaranteed via `finally`.
- Keycloak CORS for the token endpoint from Flutter web: dev realm sets
  `webOrigins` to the same localhost origins as redirect URIs — keep the web
  port aligned (README).
- `flutter_secure_storage` channel unavailability in `flutter test`: storage
  is behind the `TokenStore` interface; tests always inject fakes.
