import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/config/app_config.dart';
import 'package:knowledge_base_flutter/core/config/app_env.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('platform default when no prefs override and no dart-define', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final config = await AppConfig.load();
    expect(config.baseUrl, AppConfig.defaultBaseUrl);
    expect(config.isDefault, isTrue);
  });

  test('persisted user override wins over the default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_config.base_url': 'http://192.168.1.50:8000',
    });
    final config = await AppConfig.load();
    expect(config.baseUrl, 'http://192.168.1.50:8000');
    expect(config.isDefault, isFalse);
  });

  test('saveBaseUrl persists; empty clears back to the default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    var config = await AppConfig.load();
    config = await config.saveBaseUrl('  http://10.0.0.7:8000  ');
    expect(config.baseUrl, 'http://10.0.0.7:8000');

    config = await config.saveBaseUrl('   ');
    expect(config.baseUrl, AppConfig.defaultBaseUrl);
    expect(config.isDefault, isTrue);
  });

  group('dev resolve (pure)', () {
    test('no persisted, no compile-time → platform default (http allowed)',
        () {
      final config = AppConfig.resolve(env: AppEnv.dev);
      expect(config.baseUrl, AppConfig.defaultBaseUrl);
      expect(config.baseUrl, startsWith('http://'));
      expect(config.isDefault, isTrue);
    });

    test('compile-time url wins over the platform default (trimmed)', () {
      final config = AppConfig.resolve(
        env: AppEnv.dev,
        compileTimeUrl: '  http://192.168.1.7:8000  ',
      );
      expect(config.baseUrl, 'http://192.168.1.7:8000');
      expect(config.isDefault, isFalse,
          reason: 'isDefault compares against the real compile-time '
              'dart-define (empty in the test binary), so an injected '
              'compileTimeUrl counts as an override');
    });

    test('persisted override wins over compile-time and is trimmed', () {
      final config = AppConfig.resolve(
        env: AppEnv.dev,
        compileTimeUrl: 'http://compile-time:8000',
        persistedOverride: '  http://10.0.0.7:8000  ',
      );
      expect(config.baseUrl, 'http://10.0.0.7:8000');
      expect(config.isDefault, isFalse);
    });

    test('blank persisted override falls through to the compile-time url',
        () {
      final config = AppConfig.resolve(
        env: AppEnv.dev,
        compileTimeUrl: 'http://compile-time:8000',
        persistedOverride: '   ',
      );
      expect(config.baseUrl, 'http://compile-time:8000');
    });
  });

  group('prod (AppEnv.prod)', () {
    test('resolve throws on an empty compile-time url', () {
      expect(
        () => AppConfig.resolve(env: AppEnv.prod),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('--dart-define=API_BASE_URL=https://'),
          ),
        ),
      );
    });

    test('resolve throws on an http:// url', () {
      expect(
        () => AppConfig.resolve(
          env: AppEnv.prod,
          compileTimeUrl: 'http://api.example.com',
        ),
        throwsStateError,
      );
    });

    test('resolve accepts a trimmed https:// url', () {
      final config = AppConfig.resolve(
        env: AppEnv.prod,
        compileTimeUrl: '  https://api.example.com  ',
      );
      expect(config.baseUrl, 'https://api.example.com');
      expect(config.isDefault, isFalse,
          reason: 'isDefault compares against the real compile-time '
              'dart-define (empty in the test binary); in a real prod '
              'build baseUrl == the dart-define, so it is true there');
    });

    test('resolve ignores a persisted override in prod', () {
      final config = AppConfig.resolve(
        env: AppEnv.prod,
        compileTimeUrl: 'https://api.example.com',
        persistedOverride: 'http://persisted.example.com',
      );
      expect(config.baseUrl, 'https://api.example.com');
    });

    test('load fails fast even with a valid https persisted override',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_config.base_url': 'https://persisted.example.com',
      });
      // No compile-time URL in the test binary → prod must fail fast
      // rather than fall back to the persisted (or any dev) address.
      await expectLater(AppConfig.load(env: AppEnv.prod), throwsStateError);
    });

    test('saveBaseUrl is a no-op and never writes prefs in prod', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final config = AppConfig.resolve(
        env: AppEnv.prod,
        compileTimeUrl: 'https://api.example.com',
      );
      final result = await config.saveBaseUrl(
        'http://evil.example.com',
        env: AppEnv.prod,
      );
      expect(result, same(config), reason: 'prod returns this unchanged');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_config.base_url'), isNull);
    });
  });
}
