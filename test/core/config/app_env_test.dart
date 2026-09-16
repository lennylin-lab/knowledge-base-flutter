import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/config/app_env.dart';

void main() {
  group('AppEnv.fromRaw', () {
    test("'dev' / 'prod' resolve explicitly", () {
      expect(AppEnv.fromRaw('dev'), AppEnv.dev);
      expect(AppEnv.fromRaw('prod'), AppEnv.prod);
    });

    test('case-insensitive', () {
      expect(AppEnv.fromRaw('DEV'), AppEnv.dev);
      expect(AppEnv.fromRaw('Dev'), AppEnv.dev);
      expect(AppEnv.fromRaw('PROD'), AppEnv.prod);
      expect(AppEnv.fromRaw('Prod'), AppEnv.prod);
    });

    test('whitespace tolerance', () {
      expect(AppEnv.fromRaw(' dev '), AppEnv.dev);
      expect(AppEnv.fromRaw('\tPROD\n'), AppEnv.prod);
    });

    test('unknown value falls back to the build mode', () {
      expect(kReleaseMode, isFalse,
          reason: 'precondition: flutter test runs in non-release mode, '
              'so the build-mode fallback below is dev');
      expect(AppEnv.fromRaw('staging'), AppEnv.dev);
      expect(AppEnv.fromRaw('production'), AppEnv.dev);
    });

    test('missing/blank value falls back to the build mode', () {
      expect(AppEnv.fromRaw(null), AppEnv.dev);
      expect(AppEnv.fromRaw(''), AppEnv.dev);
      expect(AppEnv.fromRaw('   '), AppEnv.dev);
    });
  });

  group('AppEnv.current', () {
    test('test binaries compile without APP_ENV and non-release → dev', () {
      // Assert only what is stable: String.fromEnvironment is baked in
      // at compile time (empty here — flutter test never passes
      // --dart-define) and test runners are never release mode.
      expect(AppEnv.current, AppEnv.dev);
    });
  });
}
