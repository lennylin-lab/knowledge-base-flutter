import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/layout/layout_preferences.dart';
import 'core/retry_policy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  final layoutWidths = await LayoutPreferences.load();
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        layoutWidthsSeedProvider.overrideWithValue(layoutWidths),
      ],
      retry: noAutomaticRetry,
      child: App(),
    ),
  );
}
