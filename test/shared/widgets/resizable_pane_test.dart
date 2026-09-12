import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/widgets/resizable_pane.dart';

// Thresholds exercising every tier branch.
const responsiveMin = 300.0;
const absoluteMin = 240.0;
const maxWidth = 520.0;
const defaultWidth = 340.0;

Future<void> pumpPane(
  WidgetTester tester, {
  double? width,
  PaneSide side = PaneSide.right,
  ValueChanged<double>? onWidthChanged,
  ValueChanged<double>? onWidthDragEnd,
  Size surface = const Size(1200, 600),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        // Zero slop so test drags report exact deltas.
        data: MediaQueryData(
          gestureSettings: const DeviceGestureSettings(touchSlop: 0),
        ),
        child: Scaffold(
          body: Center(
            child: ResizablePane(
              width: width,
              defaultWidth: defaultWidth,
              responsiveMinWidth: responsiveMin,
              absoluteMinWidth: absoluteMin,
              maxWidth: maxWidth,
              side: side,
              onWidthChanged: onWidthChanged ?? (_) {},
              onWidthDragEnd: onWidthDragEnd ?? (_) {},
              child: const SizedBox(
                key: Key('pane-content'),
                width: 340,
                child: FlutterLogo(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _contentWidth(WidgetTester tester) =>
    tester.getSize(find.byKey(const Key('pane-content'))).width;

double _paneWidth(WidgetTester tester) =>
    tester.getSize(find.byType(ResizablePane)).width;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResizablePane fixed-width tiers', () {
    testWidgets('above tier one: child fills the full pane width', (
      tester,
    ) async {
      await pumpPane(tester, width: 400);
      expect(_paneWidth(tester), 400);
      expect(_contentWidth(tester), 400);
    });

    testWidgets('between the tiers: child laid out at tier-one width while '
        'the viewport shrinks', (tester) async {
      await pumpPane(tester, width: 260);
      expect(_paneWidth(tester), 260);
      // The content itself keeps its tier-one layout width (300): it is
      // clipped by the 260 viewport, not reflowed.
      expect(_contentWidth(tester), 300);
    });

    testWidgets('fixed width is clamped to the available slot', (tester) async {
      await pumpPane(tester, width: 500, surface: const Size(400, 600));
      expect(_paneWidth(tester), 400);
    });
  });

  group('ResizablePane auto width', () {
    testWidgets('null width: pane takes the intrinsic child width', (
      tester,
    ) async {
      await pumpPane(tester, width: null);
      expect(_paneWidth(tester), 340);
    });

    testWidgets('dragging from auto starts at the measured width', (
      tester,
    ) async {
      double? reported;
      await pumpPane(
        tester,
        width: null,
        onWidthChanged: (w) => reported = w,
      );
      final handle = find.byType(GestureDetector).last;
      await tester.drag(handle, const Offset(60, 0));
      // Intrinsic width 340 + 60 to the right.
      expect(reported, 400);
    });
  });

  group('ResizablePane drag bounds', () {
    testWidgets('dragging right stops at the strict maximum', (tester) async {
      double? last;
      await pumpPane(
        tester,
        width: 400,
        onWidthChanged: (w) => last = w,
      );
      final handle = find.byType(GestureDetector).last;
      await tester.drag(handle, const Offset(500, 0));
      expect(last, maxWidth);
    });

    testWidgets('dragging left below tier one keeps reporting, below tier '
        'two clamps', (tester) async {
      final widths = <double>[];
      double? end;
      await pumpPane(
        tester,
        width: 340,
        onWidthChanged: widths.add,
        onWidthDragEnd: (w) => end = w,
      );
      final handle = find.byType(GestureDetector).last;
      // 340 - 60 = 280: between the tiers.
      await tester.drag(handle, const Offset(-60, 0));
      expect(widths.last, 280);
      // Far below tier two: clamped to the hard floor.
      await tester.drag(handle, const Offset(-500, 0));
      expect(widths.last, absoluteMin);
      expect(end, absoluteMin);
    });

    testWidgets('drag end persists the final width', (tester) async {
      double? end;
      await pumpPane(
        tester,
        width: 340,
        onWidthDragEnd: (w) => end = w,
      );
      final handle = find.byType(GestureDetector).last;
      final gesture = await tester.startGesture(
        tester.getCenter(handle),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(30, 0));
      await gesture.up();
      await tester.pump();
      expect(end, 370);
    });

    testWidgets('left-side handle: dragging left widens the pane', (
      tester,
    ) async {
      double? reported;
      await pumpPane(
        tester,
        width: 340,
        side: PaneSide.left,
        onWidthChanged: (w) => reported = w,
      );
      final handle = find.byType(GestureDetector).last;
      await tester.drag(handle, const Offset(-40, 0));
      expect(reported, 380);
    });
  });
}
