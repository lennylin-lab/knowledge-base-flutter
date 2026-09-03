import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/config/app_config.dart';
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
}
