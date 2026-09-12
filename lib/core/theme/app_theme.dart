import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import 'app_sizes.dart';

/// Material 3 light & dark themes; both grow from one seed color so surfaces
/// stay consistent across brightness.
///
/// Every theme is parameterized by the viewport [scale]
/// ([AppSizes.scaleForWidth]): text sizes multiply through the typography
/// geometry, default icons through iconTheme, and spacing / component
/// metrics ride along as the [AppSizes] extension (`context.sizes`).
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF4F6BED);

  /// Cache keyed by (brightness, quantized scale): scaleForWidth only emits
  /// ~20 distinct values across the whole width range, so window resizes
  /// rebuild ThemeData at most that many times instead of per pixel.
  static final _cache = <(Brightness, int), ThemeData>{};

  static ThemeData light(double scale) => _theme(Brightness.light, scale);

  static ThemeData dark(double scale) => _theme(Brightness.dark, scale);

  static ThemeData _theme(Brightness brightness, double scale) {
    final key = (brightness, (scale * 100).round());
    return _cache.putIfAbsent(key, () => _build(brightness, scale));
  }

  static ThemeData _build(Brightness brightness, double scale) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      // M3 ThemeData.textTheme carries no sizes — geometry joins at
      // Theme.of() via `ThemeData.localize(typography.geometryThemeFor(...))`.
      // Scaling the geometry is therefore the one hook that scales every
      // textTheme role, Material's DefaultTextStyle, and every component
      // default that resolves text through Theme.of().
      typography: Typography.material2021(
        platform: defaultTargetPlatform,
        colorScheme: colorScheme,
        englishLike: Typography.englishLike2021.apply(fontSizeFactor: scale),
        dense: Typography.dense2021.apply(fontSizeFactor: scale),
        tall: Typography.tall2021.apply(fontSizeFactor: scale),
      ),
      iconTheme: IconThemeData(size: 24 * scale, color: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Hairline under the app bar on every page (导航标题分隔线);
        // outlineVariant matches the VerticalDivider color in the shells.
        shape: Border.fromBorderSide(
          BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      splashFactory: InkSparkle.splashFactory,
      extensions: [AppSizes(scale)],
    );
  }
}
