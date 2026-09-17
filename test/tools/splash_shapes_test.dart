// ignore_for_file: avoid_print — printing the JSON blob is this tool's output.
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

/// Generator for the web splash's M3E-style morphing spinner
/// (web/index.html): samples each Material shape's contour at [n] fixed
/// angles (starting at 12 o'clock, same order for every shape so linear
/// interpolation between shapes does not swirl) and emits per-shape radii
/// normalized to max = 1. Run `flutter test` and copy the printed
/// SPLASH_SHAPES_JSON into the splash script.
void main() {
  test('samples the 7 spinner shapes into polar radii', () {
    const n = 96;
    final shapes = <String, RoundedPolygon>{
      'softBurst': MaterialShapes.softBurst,
      'cookie9': MaterialShapes.cookie9Sided,
      'pentagon': MaterialShapes.pentagon,
      'pill': MaterialShapes.pill,
      'sunny': MaterialShapes.sunny,
      'cookie4': MaterialShapes.cookie4Sided,
      'oval': MaterialShapes.oval,
    };

    final out = <String, List<double>>{};
    shapes.forEach((name, polygon) {
      final path = polygon.toPath();

      // Center from the DENSE CONTOUR SAMPLES, not path.getBounds(): that
      // reports the control-point hull, which sits outside the shape for
      // rounded corners and skews the polar sampling asymmetrically.
      const steps = 720;
      var minX = double.infinity, minY = double.infinity;
      var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      for (final metric in path.computeMetrics()) {
        for (var i = 0; i < steps; i++) {
          final p = metric.getTangentForOffset(metric.length * i / steps)!.position;
          minX = math.min(minX, p.dx);
          maxX = math.max(maxX, p.dx);
          minY = math.min(minY, p.dy);
          maxY = math.max(maxY, p.dy);
        }
      }
      final cx = (minX + maxX) / 2;
      final cy = (minY + maxY) / 2;

      // Dense contour sampling: (angle, radius) around the shape center.
      final angles = <double>[];
      final radii = <double>[];
      for (final metric in path.computeMetrics()) {
        for (var i = 0; i < steps; i++) {
          final tangent = metric.getTangentForOffset(metric.length * i / steps)!;
          final dx = tangent.position.dx - cx;
          final dy = tangent.position.dy - cy;
          angles.add(math.atan2(dy, dx));
          radii.add(math.sqrt(dx * dx + dy * dy));
        }
      }

      var maxR = 0.0;
      for (final r in radii) {
        if (r > maxR) maxR = r;
      }
      final normalized = List<double>.filled(n, 0);
      for (var k = 0; k < n; k++) {
        final target = -math.pi / 2 + 2 * math.pi * k / n;
        var best = 0.0;
        var bestDiff = double.infinity;
        for (var i = 0; i < angles.length; i++) {
          // Minimal angular distance: reduce to [0, 2π) first — targets
          // above π push the raw difference past 2π, and a bare `2π - diff`
          // would then go negative, matching a far-side notch and producing
          // the quarter-turn asymmetry bug.
          var diff = (angles[i] - target) % (2 * math.pi);
          if (diff > math.pi) diff = 2 * math.pi - diff;
          if (diff < bestDiff) {
            bestDiff = diff;
            best = radii[i];
          }
        }
        normalized[k] = double.parse((best / maxR).toStringAsFixed(4));
      }
      out[name] = normalized;
      expect(normalized.reduce(math.max), closeTo(1, 0.001));
    });

    print('SPLASH_SHAPES_JSON=${jsonEncode(out)}');
  });
}
