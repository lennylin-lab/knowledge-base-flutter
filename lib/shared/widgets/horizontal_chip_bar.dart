import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';

/// Horizontally scrollable chip row that works on every input surface:
/// touch drag (mobile), mouse drag and wheel (desktop / web), plus a
/// scrollbar thumb users can grab. The thumb paints only while the
/// children overflow the bar.
class HorizontalChipBar extends StatefulWidget {
  const HorizontalChipBar({super.key, required this.children});

  final List<Widget> children;

  @override
  State<HorizontalChipBar> createState() => _HorizontalChipBarState();
}

class _HorizontalChipBarState extends State<HorizontalChipBar> {
  final ScrollController _controller = ScrollController();

  /// Pointer-driven surfaces get the persistent thumb as the scroll
  /// affordance (mouse users have no touch drag); touch platforms keep the
  /// transient thumb that appears only while scrolling.
  static bool get _persistentThumb {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    final behavior = ScrollConfiguration.of(context);
    return ScrollConfiguration(
      // The [Scrollbar] below is the one scrollbar; the copied behavior only
      // learns to drag-scroll with the mouse (default dragDevices exclude it).
      behavior: behavior.copyWith(
        scrollbars: false,
        dragDevices: {...behavior.dragDevices, PointerDeviceKind.mouse},
      ),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: _persistentThumb,
        child: SizedBox(
          height: sizes.chipBarHeight,
          child: ListView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: sizes.pagePadHCompact,
              vertical: sizes.space8,
            ),
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
