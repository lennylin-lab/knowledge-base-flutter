import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/token_store.dart';
import 'core/browser/read_only_url_strategy.dart';
import 'core/config/app_config.dart';
import 'core/config/oidc_config.dart';
import 'core/layout/layout_preferences.dart';
import 'core/retry_policy.dart';
import 'core/theme/theme_preferences.dart';
import 'features/documents/document_selection_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URLs (not the default hash strategy) so the OIDC redirect lands on
  // `/auth/callback` as a real path — OAuth redirect URIs forbid fragments.
  // Serving needs an SPA fallback for non-asset paths.
  //
  // The strategy is read-only: the engine's runtime URL writes are
  // unreliable on this Flutter master (stale queued reports regress the
  // address bar), so [ReadOnlyPathUrlStrategy] keeps only its reads and the
  // UrlSync shim owns every write (see core/browser/url_sync_web.dart).
  setUrlStrategy(ReadOnlyPathUrlStrategy());
  final config = await AppConfig.load();
  final oidc = await OidcConfig.load();
  final layoutWidths = await LayoutPreferences.load();
  final themeMode = await ThemePreferences.load();
  final selectedDocumentId = await DocumentSelectionPreferences.load();
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
        documentSelectionSeedProvider.overrideWithValue(selectedDocumentId),
      ],
      retry: noAutomaticRetry,
      child: App(),
    ),
  );
}
