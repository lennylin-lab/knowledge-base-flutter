import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/core/theme/theme_preferences.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/documents/stub_documents_repository.dart';

void main() {
  // The documents branch fetches through the repository provider — stub it
  // with an empty first page so the test stays offline.
  Widget buildApp() => ProviderScope(
    overrides: [
      documentsRepositoryProvider.overrideWithValue(
        StubDocumentsRepository()
          ..listHandler =
              (cursor, limit, tags) async =>
                  const DocumentPage(items: [], nextCursor: null),
      ),
    ],
    retry: noAutomaticRetry,
    child: App(),
  );

  ThemeMode currentThemeMode(WidgetTester tester) =>
      tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      ).themeMode ??
      ThemeMode.system;

  testWidgets('theme menu switches mode and persists the choice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Default stays system — same brightness behavior as before the menu.
    expect(currentThemeMode(tester), ThemeMode.system);

    await tester.tap(find.byTooltip('主题'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('浅色'));
    await tester.pumpAndSettle();
    expect(currentThemeMode(tester), ThemeMode.light);

    await tester.tap(find.byTooltip('主题'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(currentThemeMode(tester), ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme.mode'), 'dark');
  });

  test('load restores the persisted mode', () async {
    SharedPreferences.setMockInitialValues({'theme.mode': 'light'});
    expect(await ThemePreferences.load(), ThemeMode.light);
  });

  test('load falls back to system on empty or unknown values', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ThemePreferences.load(), ThemeMode.system);
    SharedPreferences.setMockInitialValues({'theme.mode': 'bogus'});
    expect(await ThemePreferences.load(), ThemeMode.system);
  });
}
