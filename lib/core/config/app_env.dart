import 'package:flutter/foundation.dart';

/// The environment the running build targets.
///
/// Resolution order for [AppEnv.current]:
/// 1. compile-time `--dart-define=APP_ENV=dev|prod` (case-insensitive,
///    whitespace tolerated) wins;
/// 2. otherwise the build mode decides: `kReleaseMode` → [prod],
///    debug/profile → [dev];
/// 3. an unrecognized `APP_ENV` value (typo, `staging`, ...) silently
///    falls back to the build-mode default — no crash, keeping
///    third-party CI wrappers that inject extra dart-defines safe.
enum AppEnv {
  dev,
  prod;

  /// Compile-time `--dart-define=APP_ENV` value ('' in builds compiled
  /// without the define — including every test binary).
  static const String _envValue = String.fromEnvironment('APP_ENV');

  /// Parses a raw `APP_ENV` value against the current build mode.
  ///
  /// Pure so tests can drive every branch directly (dart-defines are
  /// baked in at compile time and cannot be controlled from tests);
  /// [current] is a thin wrapper over this.
  static AppEnv fromRaw(String? raw) {
    final value = raw?.trim().toLowerCase();
    return switch (value) {
      'dev' => AppEnv.dev,
      'prod' => AppEnv.prod,
      _ => kReleaseMode ? AppEnv.prod : AppEnv.dev,
    };
  }

  /// The environment of the running build — see the resolution order in
  /// the enum docs. Test runners are not release mode and compile
  /// without `APP_ENV`, so this is [dev] under `flutter test`.
  static AppEnv get current => fromRaw(_envValue);
}
