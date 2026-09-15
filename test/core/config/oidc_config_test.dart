import 'package:flutter_test/flutter_test.dart';
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
}
