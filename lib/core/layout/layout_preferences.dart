import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsPrefix = 'layout.pane_width.';

/// Persisted pane widths (dragged sidebar sizes), keyed by pane id.
///
/// Follows the `AppConfig` pattern: `main()` loads the persisted map once
/// before the first frame and overrides [layoutWidthsSeedProvider]; the
/// notifier keeps the live map and writes through to `shared_preferences`
/// (key prefix `layout.pane_width.<paneId>`, same naming scheme as
/// `app_config.base_url`).
class LayoutWidths {
  const LayoutWidths({this.widths = const {}});

  final Map<String, double> widths;

  /// The persisted width for [paneId], or `null` when the pane was never
  /// dragged (callers fall back to their default/auto layout).
  double? widthOf(String paneId) => widths[paneId];

  LayoutWidths withWidth(String paneId, double width) =>
      LayoutWidths(widths: {...widths, paneId: width});
}

/// Seed value loaded in `main()` before the first frame.
final layoutWidthsSeedProvider = Provider<LayoutWidths>(
  (ref) => const LayoutWidths(),
);

/// Live pane widths. `applyWidth` updates memory only (per drag tick);
/// `saveWidth` also persists (per drag end).
class LayoutWidthsNotifier extends Notifier<LayoutWidths> {
  @override
  LayoutWidths build() => ref.watch(layoutWidthsSeedProvider);

  void applyWidth(String paneId, double width) {
    state = state.withWidth(paneId, width);
  }

  Future<void> saveWidth(String paneId, double width) async {
    applyWidth(paneId, width);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_prefsPrefix$paneId', width);
  }
}

final layoutWidthsProvider =
    NotifierProvider<LayoutWidthsNotifier, LayoutWidths>(
      LayoutWidthsNotifier.new,
    );

/// Reads every persisted pane width. Called once from `main()`.
class LayoutPreferences {
  const LayoutPreferences._();

  static Future<LayoutWidths> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LayoutWidths(
      widths: {
        for (final key in prefs.getKeys())
          if (key.startsWith(_prefsPrefix))
            key.substring(_prefsPrefix.length): prefs.getDouble(key)!,
      },
    );
  }
}
