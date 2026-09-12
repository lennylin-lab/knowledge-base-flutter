import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/layout/layout_preferences.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LayoutPreferences.load', () {
    test('returns an empty map when nothing is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final widths = await LayoutPreferences.load();
      expect(widths.widths, isEmpty);
      expect(widths.widthOf('nav.rail'), isNull);
    });

    test('reads only pane-width keys and strips the prefix', () async {
      SharedPreferences.setMockInitialValues({
        'layout.pane_width.nav.rail': 240.0,
        'layout.pane_width.documents.list': 300.0,
        'app_config.base_url': 'http://localhost:8000',
      });
      final widths = await LayoutPreferences.load();
      expect(widths.widthOf('nav.rail'), 240.0);
      expect(widths.widthOf('documents.list'), 300.0);
      expect(widths.widths.length, 2);
    });
  });

  group('layoutWidthsProvider', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(retry: noAutomaticRetry);
      addTearDown(container.dispose);
    });

    test('applyWidth updates memory only', () async {
      expect(container.read(layoutWidthsProvider).widthOf('nav.rail'), isNull);
      container.read(layoutWidthsProvider.notifier).applyWidth('nav.rail', 280);
      expect(container.read(layoutWidthsProvider).widthOf('nav.rail'), 280);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('layout.pane_width.nav.rail'), isNull);
    });

    test('saveWidth persists the width', () async {
      await container
          .read(layoutWidthsProvider.notifier)
          .saveWidth('documents.list', 420);
      expect(
        container.read(layoutWidthsProvider).widthOf('documents.list'),
        420,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('layout.pane_width.documents.list'), 420.0);
    });

    test('seed provider overrides the initial state', () async {
      final seeded = ProviderContainer(
        retry: noAutomaticRetry,
        overrides: [
          layoutWidthsSeedProvider.overrideWithValue(
            const LayoutWidths(widths: {'nav.rail': 200}),
          ),
        ],
      );
      addTearDown(seeded.dispose);
      expect(seeded.read(layoutWidthsProvider).widthOf('nav.rail'), 200);
    });
  });
}
