import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'documents.selected_id';

/// Seed value loaded in `main()` before the first frame.
final documentSelectionSeedProvider = Provider<String?>((ref) => null);

/// Persisted two-pane document selection (documents page wide layout).
///
/// Follows the `LayoutPreferences` pattern: `main()` loads the persisted
/// value once before the first frame and overrides
/// [documentSelectionSeedProvider]; [SelectedDocumentIdNotifier] keeps the
/// live value and writes through on every select / clear. A browser reload
/// resets every in-memory provider — the seed is what reopens the embedded
/// detail pane on the same document instead of dropping the user on the
/// bare list.
class DocumentSelectionPreferences {
  const DocumentSelectionPreferences._();

  /// Reads the persisted selection. Called once from `main()`.
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  /// Write-through from the notifier; `null` clears the persisted value.
  static Future<void> save(String? documentId) async {
    final prefs = await SharedPreferences.getInstance();
    if (documentId == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, documentId);
    }
  }
}
