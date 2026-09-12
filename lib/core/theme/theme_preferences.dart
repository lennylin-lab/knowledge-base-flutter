import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'theme.mode';

/// Persisted theme mode ([ThemeMode.system] until the user picks one).
///
/// Follows the `LayoutWidths` pattern: `main()` loads the persisted value
/// once before the first frame and overrides [themeModeSeedProvider]; the
/// notifier keeps the live mode and writes through to `shared_preferences`
/// (key `theme.mode`, same naming scheme as `app_config.base_url`).

/// Seed value loaded in `main()` before the first frame.
final themeModeSeedProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

/// Live theme mode consumed by `MaterialApp.router` in `app.dart`.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(themeModeSeedProvider);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Reads the persisted theme mode. Called once from `main()`.
class ThemePreferences {
  const ThemePreferences._();

  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    for (final mode in ThemeMode.values) {
      if (mode.name == stored) return mode;
    }
    return ThemeMode.system;
  }
}
