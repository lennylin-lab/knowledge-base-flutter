import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders the vector mark without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: AppLogo(size: 96)),
        ),
      ),
    );

    // The logo painter (with its 6 vector paths) is on the logo's own
    // CustomPaint, not on any wrapping decoration.
    final paint = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is CustomPainter,
    );
    expect(paint, findsOneWidget);
  });

  testWidgets('stays square inside a stretch parent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [AppLogo(size: 48)],
          ),
        ),
      ),
    );

    // A stretch column imposes its full width; the logo must keep its
    // square (undistorted) layout anyway.
    expect(
      tester.getSize(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter != null),
      ),
      const Size(48, 48),
    );
  });
}
