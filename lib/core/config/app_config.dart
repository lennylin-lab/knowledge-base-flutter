import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_env.dart';

/// App configuration — currently just the backend base URL.
///
/// Base URL resolution per environment (`AppEnv`):
///
/// | env | resolution (lowest → highest precedence) |
/// |-----|------------------------------------------|
/// | dev | platform default → compile-time `--dart-define=API_BASE_URL=...` → persisted user override via `shared_preferences`; `http://` allowed |
/// | prod | compile-time URL only — must be a non-empty `https://` URL, otherwise [load] fails fast with a [StateError]; persisted overrides are never read nor written |
///
/// Platform defaults — web / windows: `http://localhost:8000` (backend
/// on the same host); android emulator: `http://10.0.2.2:8000`
/// (emulator loopback alias for the host machine); real devices need an
/// explicit override.
///
/// `defaultTargetPlatform` (not `dart:io`) keeps this file compilable
/// and testable on every platform.
class AppConfig {
  const AppConfig({required this.baseUrl});

  static const _prefsKey = 'app_config.base_url';

  /// Default for web, windows and any other non-android target.
  static const localBaseUrl = 'http://localhost:8000';

  /// Default for the android emulator (host loopback alias).
  static const androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  /// Compile-time default override (`--dart-define=API_BASE_URL=...`).
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Platform-aware default with no user override applied.
  static String get defaultBaseUrl {
    if (kIsWeb) return localBaseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? androidEmulatorBaseUrl
        : localBaseUrl;
  }

  /// Default after applying the compile-time override (still below the
  /// persisted user override in dev).
  static String get _effectiveDefaultBaseUrl {
    final env = _envBaseUrl.trim();
    return env.isNotEmpty ? env : defaultBaseUrl;
  }

  final String baseUrl;

  bool get isDefault => baseUrl == _effectiveDefaultBaseUrl;

  /// Pure decision core for the resolution table above — unit-tested
  /// exhaustively because `String.fromEnvironment` is baked in at
  /// compile time and cannot be controlled from tests; [load] stays a
  /// thin I/O wrapper over this.
  ///
  /// Dev: [persistedOverride] (trimmed, if non-empty) wins, then
  /// [compileTimeUrl] (trimmed, if non-empty), then the platform
  /// default; `http://` is allowed.
  ///
  /// Prod: only [compileTimeUrl] counts and it must be a non-empty
  /// `https://` URL — otherwise a [StateError] naming the required
  /// `--dart-define` is thrown. [persistedOverride] is never consulted,
  /// so a prod build can never be pointed at a dev loopback address by
  /// leftover state on the device.
  static AppConfig resolve({
    required AppEnv env,
    String compileTimeUrl = '',
    String? persistedOverride,
  }) {
    final url = compileTimeUrl.trim();
    if (env == AppEnv.prod) {
      if (url.isEmpty || !url.startsWith('https://')) {
        throw StateError(
          'API_BASE_URL must be set to an https URL for prod builds '
          '(--dart-define=API_BASE_URL=https://...)',
        );
      }
      return AppConfig(baseUrl: url);
    }
    final stored = persistedOverride?.trim() ?? '';
    if (stored.isNotEmpty) return AppConfig(baseUrl: stored);
    if (url.isNotEmpty) return AppConfig(baseUrl: url);
    return AppConfig(baseUrl: defaultBaseUrl);
  }

  /// Load the effective config. Called once from `main()` before the
  /// first frame.
  ///
  /// Defaults to [AppEnv.current]. Dev reads the persisted user override
  /// on top of the platform/compile-time default; prod never reads the
  /// persisted override (see [resolve]) and fails fast on a missing or
  /// non-https compile-time URL.
  static Future<AppConfig> load({AppEnv? env}) async {
    final effective = env ?? AppEnv.current;
    final prefs = await SharedPreferences.getInstance();
    return resolve(
      env: effective,
      compileTimeUrl: _envBaseUrl,
      persistedOverride:
          effective == AppEnv.prod ? null : prefs.getString(_prefsKey),
    );
  }

  /// Persist [baseUrl] as the user override and return the new config.
  ///
  /// Passing an empty/nullish string clears the override and restores
  /// the effective default (platform or compile-time). Malformed URLs
  /// are stored as-is — the failing request surfaces as a
  /// `network_error` later; MVP keeps validation out of core.
  ///
  /// Prod builds ignore this method entirely: with [AppEnv.prod] it is a
  /// no-op returning `this` without touching `shared_preferences` —
  /// defense in depth on top of [load] never reading the key, so a
  /// stray call from a future settings UI can never change a prod
  /// build's network target.
  Future<AppConfig> saveBaseUrl(String baseUrl, {AppEnv? env}) async {
    if ((env ?? AppEnv.current) == AppEnv.prod) return this;
    final prefs = await SharedPreferences.getInstance();
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_prefsKey);
      return AppConfig(baseUrl: _effectiveDefaultBaseUrl);
    }
    await prefs.setString(_prefsKey, trimmed);
    return AppConfig(baseUrl: trimmed);
  }
}

/// App-wide config provider; `main()` overrides it with the loaded value.
/// The placeholder default exists only before `main()` runs — prod
/// correctness is enforced by [AppConfig.load], not here.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig(baseUrl: AppConfig.defaultBaseUrl),
);
