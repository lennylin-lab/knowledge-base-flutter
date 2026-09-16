import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/config/app_env.dart';
import 'package:knowledge_base_flutter/core/config/oidc_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OidcConfig.load', () {
    test('empty store → compat mode defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final config = await OidcConfig.load();
      expect(config.isEnabled, isFalse,
          reason: 'no issuer configured → auth off, like the backend');
      expect(config.clientId, OidcConfig.defaultClientId);
      expect(config.scopes, OidcConfig.defaultScopes);
      expect(config.redirectUri, isNotEmpty);
    });

    test('persisted override wins and is trimmed', () async {
      SharedPreferences.setMockInitialValues({
        'oidc.issuer': '  http://localhost:8180/realms/kb  ',
        'oidc.client_id': 'kb-web',
        'oidc.redirect_uri': 'http://127.0.0.1:8182/auth/callback',
        'oidc.scopes': 'openid profile',
      });
      final config = await OidcConfig.load();
      expect(config.issuer, 'http://localhost:8180/realms/kb');
      expect(config.isEnabled, isTrue);
      expect(config.scopes, 'openid profile');
    });

    test('blank persisted value falls back to defaults', () async {
      SharedPreferences.setMockInitialValues({'oidc.issuer': '   '});
      final config = await OidcConfig.load();
      expect(config.isEnabled, isFalse);
    });

    test('native loopback redirect uses the fixed port', () {
      expect(
        OidcConfig.defaultRedirectUri,
        contains(':${OidcConfig.nativeLoopbackPort}'),
      );
    });
  });

  group('dev resolve (pure)', () {
    test('empty everything → compat mode', () {
      final config = OidcConfig.resolve(env: AppEnv.dev);
      expect(config.isEnabled, isFalse);
      expect(config.clientId, OidcConfig.defaultClientId);
      expect(config.scopes, OidcConfig.defaultScopes);
      expect(config.redirectUri, OidcConfig.defaultRedirectUri);
    });

    test('persisted wins over compile-time, compile-time over default', () {
      final withPersisted = OidcConfig.resolve(
        env: AppEnv.dev,
        compileTimeIssuer: 'http://compile-time-realm',
        persistedIssuer: '  http://persisted-realm  ',
      );
      expect(withPersisted.issuer, 'http://persisted-realm');

      final withCompileTime = OidcConfig.resolve(
        env: AppEnv.dev,
        compileTimeIssuer: 'http://compile-time-realm',
      );
      expect(withCompileTime.issuer, 'http://compile-time-realm');
      expect(withCompileTime.isEnabled, isTrue);
    });
  });

  group('prod (AppEnv.prod)', () {
    test('resolve throws on an empty issuer (compat mode forbidden)', () {
      expect(
        () => OidcConfig.resolve(env: AppEnv.prod),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('--dart-define=OIDC_ISSUER='),
          ),
        ),
      );
    });

    test('resolve throws even with persisted values set (prefs ignored)', () {
      expect(
        () => OidcConfig.resolve(
          env: AppEnv.prod,
          persistedIssuer: 'http://persisted-realm',
          persistedClientId: 'persisted-client',
          persistedRedirectUri: 'http://persisted:8182/auth/callback',
          persistedScopes: 'openid profile',
        ),
        throwsStateError,
      );
    });

    test('resolve accepts an explicit issuer', () {
      final config = OidcConfig.resolve(
        env: AppEnv.prod,
        compileTimeIssuer: 'https://idp.example.com/realms/kb',
      );
      expect(config.issuer, 'https://idp.example.com/realms/kb');
      expect(config.isEnabled, isTrue);
    });

    test('http issuer accepted in prod (https rule is API base URL only)',
        () {
      final config = OidcConfig.resolve(
        env: AppEnv.prod,
        compileTimeIssuer: 'http://localhost:8180/realms/kb',
      );
      expect(config.isEnabled, isTrue);
    });

    test('clientId/scopes/redirect defaults still apply in prod', () {
      final config = OidcConfig.resolve(
        env: AppEnv.prod,
        compileTimeIssuer: 'https://idp.example.com/realms/kb',
      );
      expect(config.clientId, OidcConfig.defaultClientId);
      expect(config.scopes, OidcConfig.defaultScopes);
      expect(config.redirectUri, OidcConfig.defaultRedirectUri);
    });

    test('compile-time values win over persisted ones in prod', () {
      final config = OidcConfig.resolve(
        env: AppEnv.prod,
        compileTimeIssuer: 'https://idp.example.com/realms/kb',
        compileTimeClientId: 'prod-client',
        persistedIssuer: 'http://persisted-realm',
        persistedClientId: 'persisted-client',
      );
      expect(config.issuer, 'https://idp.example.com/realms/kb');
      expect(config.clientId, 'prod-client');
    });

    test('load ignores all four persisted keys and fails fast', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'oidc.issuer': 'http://persisted-realm',
        'oidc.client_id': 'persisted-client',
        'oidc.redirect_uri': 'http://persisted:8182/auth/callback',
        'oidc.scopes': 'openid profile',
      });
      // No compile-time issuer in the test binary → prod must fail fast
      // rather than enter compat mode or use the persisted issuer.
      await expectLater(OidcConfig.load(env: AppEnv.prod), throwsStateError);
    });
  });
}
