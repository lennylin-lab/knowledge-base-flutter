import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/token_store.dart';
import 'core/config/app_config.dart';
import 'core/config/oidc_config.dart';
import 'core/layout/layout_preferences.dart';
import 'core/retry_policy.dart';
import 'core/theme/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URLs (not the default hash strategy) so the OIDC redirect lands on
  // `/auth/callback` as a real path — OAuth redirect URIs forbid fragments.
  // Serving needs an SPA fallback for non-asset paths.
  usePathUrlStrategy();
  final config = await AppConfig.load();
  final oidc = await OidcConfig.load();
  final layoutWidths = await LayoutPreferences.load();
  final themeMode = await ThemePreferences.load();
  final session = oidc.isEnabled ? await loadPersistedSession() : null;
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        oidcConfigProvider.overrideWithValue(oidc),
        if (session != null)
          authSeedProvider.overrideWithValue(AuthState(session: session)),
        layoutWidthsSeedProvider.overrideWithValue(layoutWidths),
        themeModeSeedProvider.overrideWithValue(themeMode),
      ],
      retry: noAutomaticRetry,
      child: App(),
    ),
  );
}
