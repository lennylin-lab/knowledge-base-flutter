import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:knowledge_base_flutter/app.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/core/theme/app_sizes.dart';
import 'package:knowledge_base_flutter/core/theme/app_theme.dart';
import 'package:knowledge_base_flutter/features/documents/documents_providers.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

import '../../features/documents/stub_documents_repository.dart';

void main() {
  group('AppSizes.scaleForWidth', () {
    test('compact stays at the 1.0 baseline', () {
      expect(AppSizes.scaleForWidth(0), 1.0);
      expect(AppSizes.scaleForWidth(360), 1.0);
      expect(AppSizes.scaleForWidth(599.9), 1.0);
      expect(AppSizes.scaleForWidth(600), 1.0);
    });

    test('grows linearly across 600–1600 and clamps at 1.2', () {
      expect(AppSizes.scaleForWidth(800), 1.04);
      expect(AppSizes.scaleForWidth(1100), 1.1);
      expect(AppSizes.scaleForWidth(1599.9), 1.2);
      expect(AppSizes.scaleForWidth(1600), 1.2);
      expect(AppSizes.scaleForWidth(5000), 1.2);
    });

    test('is monotonic across the whole range', () {
      var previous = AppSizes.scaleForWidth(500);
      for (var width = 510; width <= 1900; width += 10) {
        final current = AppSizes.scaleForWidth(width.toDouble());
        expect(current, greaterThanOrEqualTo(previous));
        previous = current;
      }
    });
  });

  group('AppSizes tokens', () {
    test('baseline (scale 1.0) equals the previously hardcoded values', () {
      const sizes = AppSizes(1.0);
      expect(sizes.space4, 4);
      expect(sizes.space120, 120);
      expect(sizes.iconXs, 14);
      expect(sizes.iconLg, 24);
      expect(sizes.iconHero, 48);
      expect(sizes.chipBarHeight, 56);
      expect(sizes.spinnerMd, 20);
      expect(sizes.avatarRadius, 12);
      expect(sizes.radiusLg, 24);
      expect(sizes.cardGapVWide, 6);
      expect(sizes.pagePadH, 16);
      expect(sizes.pagePadHCompact, 12);
    });

    test('metrics multiply by the scale', () {
      const sizes = AppSizes(1.2);
      expect(sizes.space4, closeTo(4.8, 1e-9));
      expect(sizes.iconHero, closeTo(57.6, 1e-9));
      expect(sizes.chipBarHeight, closeTo(67.2, 1e-9));
    });
  });

  group('AppTheme', () {
    /// What `Theme.of(context)` does: merges the typography geometry (the
    /// only place M3 sizes live) into the raw textTheme.
    ThemeData localized(ThemeData theme) =>
        ThemeData.localize(theme, theme.typography.geometryThemeFor(
          ScriptCategory.englishLike,
        ));

    test('textTheme scales with the factor through Theme.of resolution', () {
      expect(localized(AppTheme.light(1.0)).textTheme.bodyMedium!.fontSize, 14);
      expect(
        localized(AppTheme.light(1.2)).textTheme.bodyMedium!.fontSize,
        closeTo(14 * 1.2, 1e-9),
      );
      expect(
        localized(AppTheme.dark(1.2)).textTheme.titleLarge!.fontSize,
        closeTo(22 * 1.2, 1e-9),
      );
    });

    test('iconTheme scales from 24 and keeps the M3 onSurface color', () {
      final theme = AppTheme.light(1.2);
      expect(theme.iconTheme.size, closeTo(24 * 1.2, 1e-9));
      expect(theme.iconTheme.color, theme.colorScheme.onSurface);
    });

    test('AppSizes rides on the theme, lerps and compares by scale', () {
      final theme = AppTheme.light(1.1);
      final sizes = theme.extension<AppSizes>()!;
      expect(sizes.scale, 1.1);
      expect(sizes.space16, closeTo(16 * 1.1, 1e-9));

      const a = AppSizes(1.0);
      const b = AppSizes(1.2);
      final mid = a.lerp(b, 0.5);
      expect(mid.scale, closeTo(1.1, 1e-9));
      expect(mid.space8, closeTo(8.8, 1e-9));
      expect(a.lerp(null, 0.5), a);
      expect(a, const AppSizes(1.0));
      expect(a == b, isFalse);
    });
  });

  group('widget: App derives the scale from the window width', () {
    // The documents branch fetches through the repository provider — stub it
    // with an empty first page so the probes stay offline (widget_test
    // pattern).
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

    Future<void> setSize(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpAndSettle();
    }

    double scaleAtSurface(WidgetTester tester) {
      final context = tester.element(find.byType(Scaffold).first);
      return Theme.of(context).extension<AppSizes>()!.scale;
    }

    testWidgets('compact surface stays at the baseline', (tester) async {
      await setSize(tester, const Size(480, 800));
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(scaleAtSurface(tester), 1.0);
    });

    testWidgets('wide surface scales up continuously', (tester) async {
      await setSize(tester, const Size(1200, 800));
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      // 600 → 1600 maps to 1.0 → 1.2, so 1200 is exactly halfway.
      expect(scaleAtSurface(tester), closeTo(1.12, 1e-9));

      // End to end: resolved textTheme sizes follow the same factor.
      final context = tester.element(find.byType(Scaffold).first);
      expect(
        Theme.of(context).textTheme.bodyMedium!.fontSize,
        closeTo(14 * 1.12, 1e-9),
      );
    });
  });
}
