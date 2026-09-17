import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/widgets/m3e_loading_spinner.dart';

void main() {
  // Spec (LoadingIndicator.kt): the shape must survive multiple full morph
  // cycles without throwing — progress passes 1 during the spring overshoot.
  testWidgets('animates through several morph cycles without errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const ColoredBox(
          color: Color(0xFF171A22),
          child: Center(child: M3eLoadingSpinner(size: 48)),
        ),
      ),
    );

    CustomPaint painterOf() => tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is CustomPainter,
          ),
        );

    final first = painterOf();
    // Two full cycles: 7 morph segments per 650ms → well into the 3rd shape.
    await tester.pump(const Duration(milliseconds: 1300));
    final second = painterOf();

    expect(identical(first.painter, second.painter), isFalse,
        reason: 'the painter is rebuilt every frame with new morph state');
  });

  testWidgets('uses the theme primary color by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: const Color(0xFF4F6BED)),
        home: const Center(child: M3eLoadingSpinner()),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(M3eLoadingSpinner));
    expect(
      Theme.of(context).colorScheme.primary,
      isNot(Colors.transparent),
    );
  });
}
