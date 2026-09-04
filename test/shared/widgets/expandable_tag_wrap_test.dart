import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/widgets/expandable_tag_wrap.dart';

void main() {
  group('layoutTagsForMaxLines', () {
    const tagStyle = TextStyle(fontSize: 12, height: 1.2);
    const textScaler = TextScaler.noScaling;

    test('returns all tags when they fit within the line budget', () {
      final result = layoutTagsForMaxLines(
        tags: const ['a', 'b'],
        maxWidth: 400,
        maxLines: 2,
        tagStyle: tagStyle,
        spacing: 8,
        textScaler: textScaler,
      );

      expect(result.visibleTags, ['a', 'b']);
      expect(result.hasMore, isFalse);
    });

    test('collapses overflowing tags to the line budget', () {
      final result = layoutTagsForMaxLines(
        tags: List.generate(12, (index) => 'tag-$index'),
        maxWidth: 180,
        maxLines: 2,
        tagStyle: tagStyle,
        spacing: 8,
        textScaler: textScaler,
      );

      expect(result.hasMore, isTrue);
      expect(result.visibleTags.length, lessThan(12));
      expect(result.visibleTags, isNotEmpty);
    });
  });

  group('ExpandableTagWrap', () {
    testWidgets('shows expand row below tags and toggles collapse', (
      tester,
    ) async {
      const tags = [
        'alpha',
        'beta',
        'gamma',
        'delta',
        'epsilon',
        'zeta',
        'eta',
        'theta',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              child: ExpandableTagWrap(tags: tags),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('展开'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.text('#theta'), findsNothing);

      await tester.tap(find.text('展开'));
      await tester.pumpAndSettle();

      expect(find.text('展开'), findsNothing);
      expect(find.text('收起'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.text('#theta'), findsOneWidget);

      await tester.tap(find.text('收起'));
      await tester.pumpAndSettle();

      expect(find.text('展开'), findsOneWidget);
      expect(find.text('#theta'), findsNothing);
    });

    testWidgets('hides toggle row when all tags fit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableTagWrap(tags: ['flutter', 'dart']),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('展开'), findsNothing);
      expect(find.text('收起'), findsNothing);
      expect(find.text('#flutter'), findsOneWidget);
      expect(find.text('#dart'), findsOneWidget);
    });
  });
}
