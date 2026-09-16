import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_env.dart';

/// OIDC (Keycloak-compatible) sign-in configuration.
///
/// Resolution per environment (`AppEnv`), mirroring `AppConfig.baseUrl`:
///
/// | env | resolution (lowest → highest precedence) |
/// |-----|------------------------------------------|
/// | dev | platform defaults → compile-time `--dart-define=OIDC_*` → persisted override via `shared_preferences`; empty issuer = **compat mode** (auth disabled, matching a backend without `KB_OIDC_ISSUER`) |
/// | prod | compile-time values only (`oidc.*` prefs ignored); issuer must be non-empty after trim, otherwise [load] fails fast with a [StateError]; clientId/scopes/redirect keep their defaults when the dart-define is absent |
///
/// Platform defaults — issuer empty, client `kb-web`, scope `openid`,
/// redirect per platform.
///
/// The redirect URI default follows RFC 8252 §7.6: web redirects back to
/// the app origin (`/auth/callback`), native platforms listen on a fixed
/// loopback port so the IdP client can whitelist it.
class OidcConfig {
  const OidcConfig({
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    required this.scopes,
  });

  static const _keyIssuer = 'oidc.issuer';
  static const _keyClientId = 'oidc.client_id';
  static const _keyRedirectUri = 'oidc.redirect_uri';
  static const _keyScopes = 'oidc.scopes';

  static const String _envIssuer = String.fromEnvironment('OIDC_ISSUER');
  static const String _envClientId = String.fromEnvironment('OIDC_CLIENT_ID');
  static const String _envRedirectUri = String.fromEnvironment(
    'OIDC_REDIRECT_URI',
  );
  static const String _envScopes = String.fromEnvironment('OIDC_SCOPES');

  /// Dev realm's public PKCE client (backend Compose Keycloak).
  static const defaultClientId = 'kb-web';

  /// The access token must carry a `sub` claim; `openid` guarantees it.
  static const defaultScopes = 'openid';

  /// Fixed loopback port for native redirects (whitelisted in the IdP
  /// client config; override with `--dart-define=OIDC_REDIRECT_URI=...`).
  static const nativeLoopbackPort = 8182;

  /// Platform default redirect: web bounces back to the app origin, the
  /// Android emulator addresses loopback as `127.0.0.1`, everything else
  /// (windows) uses `localhost`.
  static String get defaultRedirectUri {
    if (kIsWeb) return '${Uri.base.origin}/auth/callback';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://127.0.0.1:$nativeLoopbackPort/auth/callback'
        : 'http://localhost:$nativeLoopbackPort/auth/callback';
  }

  final String issuer;
  final String clientId;
  final String redirectUri;
  final String scopes;

  /// Empty issuer = compat mode: the app behaves exactly as before auth
  /// existed (no login gate, no Authorization header). Prod never runs
  /// in compat mode — [resolve] fails fast instead.
  bool get isEnabled => issuer.trim().isNotEmpty;

  /// Pure decision core for the resolution table above — unit-tested
  /// directly because `String.fromEnvironment` is baked in at compile
  /// time; [load] stays a thin I/O wrapper over this.
  ///
  /// Dev: each field resolves persisted → compile-time → platform
  /// default. Prod: persisted values are ignored entirely and a
  /// non-empty issuer is required (a [StateError] naming the
  /// `--dart-define` fix — the no-auth compat mode must not be reachable
  /// in a prod build), while clientId/scopes/redirect fall back to their
  /// sane defaults. No `https` check on the issuer: the https
  /// requirement is deliberately scoped to the API base URL
  /// (`AppConfig.resolve`); Keycloak realms behind http are a
  /// backend/infra concern.
  static OidcConfig resolve({
    required AppEnv env,
    String compileTimeIssuer = '',
    String compileTimeClientId = '',
    String compileTimeRedirectUri = '',
    String compileTimeScopes = '',
    String? persistedIssuer,
    String? persistedClientId,
    String? persistedRedirectUri,
    String? persistedScopes,
  }) {
    final prod = env == AppEnv.prod;

    String pick(String? persisted, String compileTime, String fallback) {
      if (prod) {
        final value = compileTime.trim();
        return value.isNotEmpty ? value : fallback;
      }
      final stored = persisted?.trim();
      if (stored != null && stored.isNotEmpty) return stored;
      final value = compileTime.trim();
      return value.isNotEmpty ? value : fallback;
    }

    final issuer = pick(persistedIssuer, compileTimeIssuer, '');
    if (prod && issuer.isEmpty) {
      throw StateError(
        'OIDC_ISSUER must be set for prod builds '
        '(--dart-define=OIDC_ISSUER=...)',
      );
    }
    return OidcConfig(
      issuer: issuer,
      clientId: pick(persistedClientId, compileTimeClientId, defaultClientId),
      redirectUri: pick(
        persistedRedirectUri,
        compileTimeRedirectUri,
        defaultRedirectUri,
      ),
      scopes: pick(persistedScopes, compileTimeScopes, defaultScopes),
    );
  }

  /// Load the effective config. Called once from `main()` before the
  /// first frame.
  ///
  /// Defaults to [AppEnv.current]. Dev resolves persisted override →
  /// dart-define → platform default; prod ignores the `oidc.*` prefs
  /// keys entirely (see [resolve]) and fails fast on an empty issuer.
  static Future<OidcConfig> load({AppEnv? env}) async {
    final effective = env ?? AppEnv.current;
    final prefs = await SharedPreferences.getInstance();
    return effective == AppEnv.prod
        ? resolve(
            env: effective,
            compileTimeIssuer: _envIssuer,
            compileTimeClientId: _envClientId,
            compileTimeRedirectUri: _envRedirectUri,
            compileTimeScopes: _envScopes,
          )
        : resolve(
            env: effective,
            compileTimeIssuer: _envIssuer,
            compileTimeClientId: _envClientId,
            compileTimeRedirectUri: _envRedirectUri,
            compileTimeScopes: _envScopes,
            persistedIssuer: prefs.getString(_keyIssuer),
            persistedClientId: prefs.getString(_keyClientId),
            persistedRedirectUri: prefs.getString(_keyRedirectUri),
            persistedScopes: prefs.getString(_keyScopes),
          );
  }
}

/// App-wide OIDC config; `main()` overrides it with the loaded value.
final oidcConfigProvider = Provider<OidcConfig>(
  (ref) => OidcConfig(
    issuer: '',
    clientId: OidcConfig.defaultClientId,
    redirectUri: OidcConfig.defaultRedirectUri,
    scopes: OidcConfig.defaultScopes,
  ),
);
