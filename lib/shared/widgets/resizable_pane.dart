import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Which edge of the pane the drag handle sits on.
enum PaneSide { left, right }

/// A pane with a draggable edge handle for desktop/web wide layouts.
///
/// Two-tier shrinking contract ([responsiveMinWidth] = tier one,
/// [absoluteMinWidth] = tier two, `absoluteMinWidth < responsiveMinWidth`):
/// - above tier one the child is laid out at the full pane width and stays
///   responsive (content fully visible, filling the width);
/// - between tier one and tier two the child is laid out at
///   [responsiveMinWidth] but the viewport shrinks with the pane, so content
///   is clipped (no longer responsive);
/// - the width is hard-clamped to `[absoluteMinWidth, maxWidth]` — dragging
///   past tier two or past [maxWidth] simply stops changing the width.
///
/// [width] `null` means "auto": the pane takes its child's intrinsic width
/// (pixel-identical to a non-resizable layout). The first drag converts it
/// to a fixed width starting from the measured intrinsic width.
///
/// The handle overlays the pane edge inside an 8px hit strip (a layout
/// constraint, exempt from the AppSizes scaling tokens) so the pane adds no
/// width of its own. Width changes are reported via [onWidthChanged] during
/// the drag; [onWidthDragEnd] fires once when the drag finishes — persist
/// there, not on every update.
class ResizablePane extends StatefulWidget {
  const ResizablePane({
    super.key,
    required this.width,
    required this.defaultWidth,
    required this.responsiveMinWidth,
    required this.absoluteMinWidth,
    required this.maxWidth,
    required this.onWidthChanged,
    required this.onWidthDragEnd,
    required this.side,
    required this.child,
  }) : assert(
         absoluteMinWidth < responsiveMinWidth,
         'absoluteMinWidth (tier two) must be below responsiveMinWidth (tier one)',
       );

  /// Current fixed width, or `null` for the child's intrinsic width.
  final double? width;

  /// Fallback when the pane is in auto mode and the child has not been
  /// measured yet (e.g. the very first drag tick).
  final double defaultWidth;
  final double responsiveMinWidth;
  final double absoluteMinWidth;
  final double maxWidth;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onWidthDragEnd;
  final PaneSide side;
  final Widget child;

  @override
  State<ResizablePane> createState() => _ResizablePaneState();
}

class _ResizablePaneState extends State<ResizablePane> {
  /// Hit strip around the pane edge; wide enough to grab, exempt from
  /// AppSizes as a layout constraint.
  static const double _handleHitWidth = 8;

  /// Visible indicator line drawn on hover/drag.
  static const double _handleLineWidth = 1;

  double? _measuredWidth;
  double? _dragBase;
  double? _lastWidth;
  bool _hovering = false;

  bool get _active => _hovering || _dragBase != null;

  void _onDragStart(DragStartDetails details) {
    _dragBase = widget.width ?? _measuredWidth ?? widget.defaultWidth;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta =
        widget.side == PaneSide.right ? details.delta.dx : -details.delta.dx;
    final next = _clamp(_dragBase! + delta);
    // Advance the base so the next tick accumulates on top of this one
    // (a single drag gesture arrives as several delta events).
    _dragBase = next;
    _lastWidth = next;
    widget.onWidthChanged(next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_lastWidth != null) widget.onWidthDragEnd(_lastWidth!);
    _dragBase = null;
    _lastWidth = null;
  }

  double _clamp(double width) =>
      math.min(widget.maxWidth, math.max(widget.absoluteMinWidth, width));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = widget.width;
        // Window fallback: a fixed pane must never overflow its slot.
        if (width != null && constraints.maxWidth.isFinite) {
          width = math.min(width, constraints.maxWidth);
        }
        final Widget content = width == null
            // Auto mode: pass through at intrinsic width and keep measuring,
            // so the first drag has a real base to start from.
            ? _MeasureWidth(
                onWidth: (measured) => _measuredWidth = measured,
                child: widget.child,
              )
            : _buildTiered(width);
        final isRight = widget.side == PaneSide.right;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            content,
            Positioned(
              left: isRight ? null : 0,
              right: isRight ? 0 : null,
              top: 0,
              bottom: 0,
              width: _handleHitWidth,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                opaque: false,
                onEnter: (_) => setState(() => _hovering = true),
                onExit: (_) => setState(() => _hovering = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Align(
                    alignment: isRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: _handleLineWidth,
                      color: _active
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Two-tier rendering for a fixed [width] (already clamped).
  Widget _buildTiered(double width) {
    if (width >= widget.responsiveMinWidth) {
      return SizedBox(width: width, child: widget.child);
    }
    // Between the tiers: lay the child out at the tier-one width but clip it
    // to the shrinking viewport — content truncates instead of reflowing.
    return SizedBox(
      width: width,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: widget.responsiveMinWidth,
          child: SizedBox(
            width: widget.responsiveMinWidth,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Reports the laid-out width of its child through [onWidth] after layout.
/// The callback must not call setState — it runs during layout.
class _MeasureWidth extends SingleChildRenderObjectWidget {
  const _MeasureWidth({required this.onWidth, required super.child});

  final ValueChanged<double> onWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureWidth(onWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureWidth renderObject,
  ) {
    renderObject.onWidth = onWidth;
  }
}

class _RenderMeasureWidth extends RenderProxyBox {
  _RenderMeasureWidth(this.onWidth);

  ValueChanged<double> onWidth;
  double _lastReported = -1;

  @override
  void performLayout() {
    super.performLayout();
    if (child != null && size.width != _lastReported) {
      _lastReported = size.width;
      onWidth(size.width);
    }
  }
}
