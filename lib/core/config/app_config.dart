import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App configuration — currently just the backend base URL.
///
/// Base URL resolution, lowest to highest precedence:
/// 1. platform default — web / windows: `http://localhost:8000`
///    (backend on the same host); android emulator:
///    `http://10.0.2.2:8000` (emulator loopback alias for the host
///    machine); real devices need an explicit override;
/// 2. compile-time `--dart-define=API_BASE_URL=...` (overrides the
///    platform default — handy for CI builds and pointing a web build
///    at a dev proxy; nothing persisted);
/// 3. persisted user override via `shared_preferences` (set in-app;
///    wins over both above).
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
  /// persisted user override).
  static String get _effectiveDefaultBaseUrl {
    final env = _envBaseUrl.trim();
    return env.isNotEmpty ? env : defaultBaseUrl;
  }

  final String baseUrl;

  bool get isDefault => baseUrl == _effectiveDefaultBaseUrl;

  /// Load the persisted user override (if any) on top of the
  /// platform/compile-time default. Called once from `main()` before
  /// the first frame.
  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(_prefsKey);
    if (override == null || override.trim().isEmpty) {
      return AppConfig(baseUrl: _effectiveDefaultBaseUrl);
    }
    return AppConfig(baseUrl: override.trim());
  }

  /// Persist [baseUrl] as the user override and return the new config.
  ///
  /// Passing an empty/nullish string clears the override and restores
  /// the effective default (platform or compile-time). Malformed URLs
  /// are stored as-is — the failing request surfaces as a
  /// `network_error` later; MVP keeps validation out of core.
  Future<AppConfig> saveBaseUrl(String baseUrl) async {
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

/// App-wide config provider; `main()` overrides it with the persisted value.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig(baseUrl: AppConfig.defaultBaseUrl),
);
