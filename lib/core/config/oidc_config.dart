import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OIDC (Keycloak-compatible) sign-in configuration.
///
/// Resolution, lowest to highest precedence (mirrors `AppConfig.baseUrl`):
/// 1. platform defaults — issuer empty (**compat mode**: auth disabled,
///    matching a backend without `KB_OIDC_ISSUER`), client `kb-web`,
///    scope `openid`, redirect per platform;
/// 2. compile-time `--dart-define=OIDC_ISSUER / OIDC_CLIENT_ID /
///    OIDC_REDIRECT_URI / OIDC_SCOPES`;
/// 3. persisted user override via `shared_preferences`.
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
  /// existed (no login gate, no Authorization header).
  bool get isEnabled => issuer.trim().isNotEmpty;

  /// Load the effective config (persisted override → dart-define →
  /// platform default). Called once from `main()` before the first frame.
  static Future<OidcConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    String resolve(String prefsKey, String envValue, String fallback) {
      final stored = prefs.getString(prefsKey)?.trim();
      if (stored != null && stored.isNotEmpty) return stored;
      final env = envValue.trim();
      if (env.isNotEmpty) return env;
      return fallback;
    }

    return OidcConfig(
      issuer: resolve(_keyIssuer, _envIssuer, ''),
      clientId: resolve(_keyClientId, _envClientId, defaultClientId),
      redirectUri: resolve(
        _keyRedirectUri,
        _envRedirectUri,
        defaultRedirectUri,
      ),
      scopes: resolve(_keyScopes, _envScopes, defaultScopes),
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
