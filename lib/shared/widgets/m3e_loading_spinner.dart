import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

/// Material 3 Expressive loading spinner (spec: Compose `LoadingIndicator.kt`):
/// the seven Material shapes morph through a closed sequence on a 650ms
/// underdamped spring (ratio 0.6, stiffness 200, peak ~1.095), each morph
/// rotating the shape +90°, with a 4666ms linear global rotation on top.
class M3eLoadingSpinner extends StatefulWidget {
  const M3eLoadingSpinner({super.key, this.size = 48, this.color});

  /// Rendered edge length (the shape keeps a Material 38/48 margin inside).
  final double size;

  /// Shape color; defaults to the theme's primary color.
  final Color? color;

  @override
  State<M3eLoadingSpinner> createState() => _M3eLoadingSpinnerState();
}

final SpringDescription _m3eSpring = SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: 200,
  ratio: 0.6,
);
final SpringSimulation _m3eSpringSimulation = SpringSimulation(
  _m3eSpring,
  0,
  1,
  0,
);

class _M3eLoadingSpinnerState extends State<M3eLoadingSpinner>
    with TickerProviderStateMixin {
  static const _morphDuration = Duration(milliseconds: 650);
  static const _rotationDuration = Duration(milliseconds: 4666);

  static final List<RoundedPolygon> _polygons = [
    MaterialShapes.softBurst,
    MaterialShapes.cookie9Sided,
    MaterialShapes.pentagon,
    MaterialShapes.pill,
    MaterialShapes.sunny,
    MaterialShapes.cookie4Sided,
    MaterialShapes.oval,
  ];

  /// Closed morph sequence i → i+1 (oval wraps back to softBurst).
  static final List<Morph> _morphs = [
    for (var i = 0; i < _polygons.length; i++)
      Morph(_polygons[i], _polygons[(i + 1) % _polygons.length]),
  ];

  /// Sampled across every morph and the full spring range (including the
    /// ~1.095 overshoot) so the shape never leaves its box while animating.
  static final double _scaleFactor = _computeScaleFactor();

  static double _computeScaleFactor() {
    const progressSamples = 24;
    var maxRadius = 0.0;
    for (final morph in _morphs) {
      for (var i = 0; i <= progressSamples; i++) {
        final path = morph.toPath(progress: i / progressSamples * 1.095);
        for (final metric in path.computeMetrics()) {
          final count = (metric.length / 4).ceil().clamp(12, 200);
          for (var k = 0; k < count; k++) {
            final p =
                metric.getTangentForOffset(metric.length * k / count)!.position;
            final dx = p.dx - 0.5;
            final dy = p.dy - 0.5;
            maxRadius = math.max(maxRadius, math.sqrt(dx * dx + dy * dy));
          }
        }
      }
    }
    return 0.5 / maxRadius;
  }

  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: _morphDuration,
  )..addStatusListener(_onCycleCompleted);

  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: _rotationDuration,
  )..repeat();

  final Path _path = Path();
  var _index = 0;
  var _targetAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _cycle.forward();
  }

  void _onCycleCompleted(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _index = (_index + 1) % _morphs.length;
    _targetAngle += 90;
    _cycle.forward(from: 0);
  }

  @override
  void dispose() {
    _cycle.dispose();
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_cycle, _rotation]),
          builder: (context, _) => CustomPaint(
            painter: _M3eSpinnerPainter(
              morph: _morphs[_index],
              progress: _M3eSpringCurve().transform(_cycle.value),
              morphStepDegrees: _targetAngle,
              globalTurns: _rotation.value,
              scaleFactor: _scaleFactor,
              color: color,
              path: _path,
            ),
          ),
        ),
      ),
    );
  }
}

/// Spring (0.6/200) over the 650ms cycle: converges by ~298ms, then holds
/// at 1 until the next morph starts.
class _M3eSpringCurve extends Curve {
  const _M3eSpringCurve();

  @override
  double transformInternal(double t) =>
      _m3eSpringSimulation.x(t * _morphDurationMs / 1000);
}

const int _morphDurationMs = 650;

class _M3eSpinnerPainter extends CustomPainter {
  const _M3eSpinnerPainter({
    required this.morph,
    required this.progress,
    required this.morphStepDegrees,
    required this.globalTurns,
    required this.scaleFactor,
    required this.color,
    required this.path,
  });

  final Morph morph;
  final double progress;
  final double morphStepDegrees;
  final double globalTurns;
  final double scaleFactor;
  final Color color;
  final Path path;

  @override
  void paint(Canvas canvas, Size size) {
    final drawScale = size.shortestSide * scaleFactor;
    final rotation = (morphStepDegrees + progress * 90 + globalTurns * 360) *
        math.pi /
        180;

    morph.toPath(progress: progress, path: path);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.scale(drawScale, drawScale);
    canvas.translate(-0.5, -0.5);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_M3eSpinnerPainter oldDelegate) =>
      oldDelegate.morph != morph ||
      oldDelegate.progress != progress ||
      oldDelegate.morphStepDegrees != morphStepDegrees ||
      oldDelegate.globalTurns != globalTurns ||
      oldDelegate.color != color;
}
