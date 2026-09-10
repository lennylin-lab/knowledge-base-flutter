import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/widgets/horizontal_chip_bar.dart';

ScrollableState _scrollableOf(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(HorizontalChipBar),
        matching: find.byType(Scrollable),
      ),
    );

/// Pumps a chip bar wide enough to overflow the default test surface.
Future<void> pumpOverflowingBar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HorizontalChipBar(
          children: [
            for (var i = 0; i < 30; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(label: Text('标签$i'), onSelected: (_) {}),
              ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mouse drag scrolls the overflowing chip row', (tester) async {
    await pumpOverflowingBar(tester);
    expect(_scrollableOf(tester).position.pixels, 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('标签0')),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_scrollableOf(tester).position.pixels, greaterThan(0));
  });

  testWidgets('chips stay tappable — a tap never drag-scrolls', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HorizontalChipBar(
            children: [
              FilterChip(
                label: const Text('标签'),
                selected: false,
                onSelected: (_) => selected = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('标签'));

    expect(selected, isTrue);
    expect(_scrollableOf(tester).position.pixels, 0);
  });

  testWidgets('desktop platforms keep the scrollbar thumb visible', (
    tester,
  ) async {
    // The binding's invariant check runs before tearDowns — reset inline.
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await pumpOverflowingBar(tester);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Scrollbar && widget.thumbVisibility == true,
        ),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('touch platforms keep the transient scrollbar thumb', (
    tester,
  ) async {
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await pumpOverflowingBar(tester);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Scrollbar && widget.thumbVisibility == true,
        ),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
