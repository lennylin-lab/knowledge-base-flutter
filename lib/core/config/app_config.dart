import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App configuration — currently just the backend base URL.
///
/// Defaults are platform-aware:
/// - web / windows: `http://localhost:8000` (backend on the same host);
/// - android emulator: `http://10.0.2.2:8000` (emulator loopback alias for
///   the host machine); real devices need a LAN-IP override.
///
/// A user override is persisted with `shared_preferences` and wins over the
/// platform default. `defaultTargetPlatform` (not `dart:io`) keeps this file
/// compilable and testable on every platform.
class AppConfig {
  const AppConfig({required this.baseUrl});

  static const _prefsKey = 'app_config.base_url';

  /// Default for web, windows and any other non-android target.
  static const localBaseUrl = 'http://localhost:8000';

  /// Default for the android emulator (host loopback alias).
  static const androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  /// Platform-aware default with no user override applied.
  static String get defaultBaseUrl {
    if (kIsWeb) return localBaseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? androidEmulatorBaseUrl
        : localBaseUrl;
  }

  final String baseUrl;

  bool get isDefault => baseUrl == defaultBaseUrl;

  /// Load the persisted user override (if any) on top of the platform
  /// default. Called once from `main()` before the first frame.
  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(_prefsKey);
    if (override == null || override.trim().isEmpty) {
      return AppConfig(baseUrl: defaultBaseUrl);
    }
    return AppConfig(baseUrl: override.trim());
  }

  /// Persist [baseUrl] as the user override and return the new config.
  ///
  /// Passing an empty/nullish string clears the override and restores the
  /// platform default. Malformed URLs are stored as-is — the failing request
  /// surfaces as a `network_error` later; MVP keeps validation out of core.
  Future<AppConfig> saveBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_prefsKey);
      return AppConfig(baseUrl: defaultBaseUrl);
    }
    await prefs.setString(_prefsKey, trimmed);
    return AppConfig(baseUrl: trimmed);
  }
}

/// App-wide config provider; `main()` overrides it with the persisted value.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig(baseUrl: AppConfig.defaultBaseUrl),
);
