import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Viewport-responsive sizing tokens.
///
/// Every metric is its baseline value (the app's current hardcoded size at
/// the compact breakpoint) multiplied by one window-derived [scale] — see
/// [scaleForWidth] for the curve. Text and default-size icons scale through
/// `AppTheme` (textTheme / iconTheme); everything else — spacing, explicit
/// icon sizes, component metrics — reads these tokens via `context.sizes`.
@immutable
class AppSizes extends ThemeExtension<AppSizes> {
  const AppSizes(this.scale);

  /// The window-width scale factor all metrics derive from.
  final double scale;

  // Spacing scale (base values mirror the previously hardcoded steps).
  double get space2 => 2 * scale;
  double get space4 => 4 * scale;
  double get space6 => 6 * scale;
  double get space8 => 8 * scale;
  double get space10 => 10 * scale;
  double get space12 => 12 * scale;
  double get space16 => 16 * scale;
  double get space24 => 24 * scale;
  double get space28 => 28 * scale;
  double get space32 => 32 * scale;
  double get space48 => 48 * scale;
  double get space120 => 120 * scale;

  // Explicit icon sizes; the default 24 flows from the scaled iconTheme.
  double get iconXs => 14 * scale;
  double get iconSm => 18 * scale;
  double get iconMd => 20 * scale;
  double get iconLg => 24 * scale;
  double get iconHero => 48 * scale;

  // Component metrics.
  double get chipBarHeight => 56 * scale;
  double get spinnerXs => 12 * scale;
  double get spinnerSm => 16 * scale;
  double get spinnerMd => 20 * scale;
  double get codeMetaFontSize => 12 * scale;
  double get avatarRadius => 12 * scale;
  double get radiusSm => 8 * scale;
  double get radiusMd => 12 * scale;
  double get radiusLg => 24 * scale;
  double get cardGapV => 4 * scale;
  double get cardGapVWide => 6 * scale;
  double get pagePadH => 16 * scale;
  double get pagePadHCompact => 12 * scale;

  static const double _minScale = 1.0;
  static const double _maxScale = 1.4;
  static const double _startWidth = 600;
  static const double _endWidth = 1600;

  /// Window width → scale: 1.0 at the compact baseline (< 600), linear
  /// 1.0 → 1.4 across 600–1600, clamped above. Quantized to 0.01 so a
  /// window drag rebuilds the theme ~40 times instead of per pixel (a
  /// 16px font then steps by ≤ 0.16px — imperceptible).
  static double scaleForWidth(double width) {
    if (width <= _startWidth) return _minScale;
    if (width >= _endWidth) return _maxScale;
    final t = (width - _startWidth) / (_endWidth - _startWidth);
    final raw = _minScale + (_maxScale - _minScale) * t;
    return (raw * 100).roundToDouble() / 100;
  }

  // All metrics derive from [scale], so scale is the only sound copyWith /
  // equality axis; per-field overrides would break the derived invariant.
  @override
  AppSizes copyWith({double? scale}) => AppSizes(scale ?? this.scale);

  @override
  AppSizes lerp(AppSizes? other, double t) {
    if (other == null) return this;
    return AppSizes(lerpDouble(scale, other.scale, t)!);
  }

  @override
  bool operator ==(Object other) => other is AppSizes && other.scale == scale;

  @override
  int get hashCode => Object.hash(runtimeType, scale);

  @override
  String toString() => 'AppSizes($scale)';
}

extension AppSizesX on BuildContext {
  /// Responsive sizing tokens of the ambient theme. Falls back to the
  /// unscaled baseline when the ambient theme carries no [AppSizes]
  /// (e.g. widget tests pumping shared widgets on a plain MaterialApp).
  AppSizes get sizes => Theme.of(this).extension<AppSizes>() ?? const AppSizes(1.0);
}
