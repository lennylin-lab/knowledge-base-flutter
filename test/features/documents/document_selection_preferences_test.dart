import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/documents/document_selection_preferences.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The notifier's write-through is fire-and-forget (`unawaited`); give it
  /// a few microtask rounds to land before asserting on storage.
  Future<SharedPreferences> flushedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return prefs;
  }

  group('DocumentSelectionPreferences', () {
    test('load returns null when nothing is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await DocumentSelectionPreferences.load(), isNull);
    });

    test('save writes through and load reads it back', () async {
      SharedPreferences.setMockInitialValues({});
      await DocumentSelectionPreferences.save('doc-42');
      expect(await DocumentSelectionPreferences.load(), 'doc-42');
    });

    test('save(null) clears the persisted selection', () async {
      SharedPreferences.setMockInitialValues({
        'documents.selected_id': 'doc-42',
      });
      await DocumentSelectionPreferences.save(null);
      expect(await DocumentSelectionPreferences.load(), isNull);
    });
  });

  group('selectedDocumentIdProvider', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(retry: noAutomaticRetry);
      addTearDown(container.dispose);
    });

    test('select writes state and persists', () async {
      expect(container.read(selectedDocumentIdProvider), isNull);
      container.read(selectedDocumentIdProvider.notifier).select('a');
      expect(container.read(selectedDocumentIdProvider), 'a');
      final prefs = await flushedPrefs();
      expect(prefs.getString('documents.selected_id'), 'a');
    });

    test('clear resets state and removes the persisted value', () async {
      SharedPreferences.setMockInitialValues({
        'documents.selected_id': 'a',
      });
      final seeded = ProviderContainer(retry: noAutomaticRetry);
      addTearDown(seeded.dispose);
      seeded.read(selectedDocumentIdProvider.notifier).clear();
      expect(seeded.read(selectedDocumentIdProvider), isNull);
      final prefs = await flushedPrefs();
      expect(prefs.getString('documents.selected_id'), isNull);
    });

    test('seed provider overrides the initial state', () {
      final seeded = ProviderContainer(
        retry: noAutomaticRetry,
        overrides: [
          documentSelectionSeedProvider.overrideWithValue('seeded-doc'),
        ],
      );
      addTearDown(seeded.dispose);
      expect(seeded.read(selectedDocumentIdProvider), 'seeded-doc');
    });
  });
}
