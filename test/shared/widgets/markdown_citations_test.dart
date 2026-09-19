import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_base_flutter/core/theme/app_theme.dart';
import 'package:knowledge_base_flutter/shared/widgets/markdown_content.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(1),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('mapped [n] citations render tappable and report their documentId',
      (tester) async {
    final tapped = <(int, String)>[];
    await tester.pumpWidget(_wrap(
      MarkdownContent(
        data: '见 [1] 与 [2]，超出范围的 [3] 保持纯文本。',
        citationDocumentId: (index) => switch (index) {
          1 => 'doc-a',
          2 => 'doc-b',
          _ => null,
        },
        onCitationTap: (index, documentId) => tapped.add((index, documentId)),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('[1]'), findsOneWidget);
    expect(find.text('[2]'), findsOneWidget);
    expect(find.text('[3]'), findsOneWidget, reason: 'unmapped stays plain');

    await tester.tap(find.text('[1]'));
    await tester.tap(find.text('[2]'));
    expect(tapped, [((1, 'doc-a')), ((2, 'doc-b'))]);
  });

  testWidgets('no resolver renders plain text, never links', (tester) async {
    await tester.pumpWidget(_wrap(
      MarkdownContent(
        data: '引用 [1] 与 [2]。',
        onCitationTap: (_, _) => fail('must not be tappable without resolver'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('[1]'), findsOneWidget);
    expect(find.text('[2]'), findsOneWidget);
  });

  testWidgets('citations inside inline code spans are never linkified', (tester) async {
    await tester.pumpWidget(_wrap(
      MarkdownContent(
        data: '代码里的 ` [1] ` 不应可点击。',
        citationDocumentId: (index) => 'doc-a',
        onCitationTap: (_, _) => fail('code span must stay inert'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('[1]'), findsNothing,
        reason: 'code span text is not split into a citation badge');
  });

  testWidgets('a real link with numeric text still parses as a link', (tester) async {
    await tester.pumpWidget(_wrap(
      MarkdownContent(
        data: '[1](https://example.com)',
        citationDocumentId: (index) => 'doc-a',
        onCitationTap: (_, _) => fail('real links must not become citations'),
      ),
    ));
    await tester.pumpAndSettle();

    // The link syntax wins over the citation syntax; the anchor text renders
    // as one link widget (no separate [1] badge).
    expect(find.text('[1]'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('chat answer citation navigates to the document page', (tester) async {
    final router = GoRouter(
      initialLocation: '/answer',
      routes: [
        GoRoute(
          path: '/answer',
          builder: (context, state) => Scaffold(
            body: MarkdownContent(
              data: '结论见 [1]。',
              citationDocumentId: (index) => index == 1 ? 'doc-42' : null,
              onCitationTap: (index, documentId) => context.push('/documents/$documentId'),
            ),
          ),
        ),
        GoRoute(
          path: '/documents/:id',
          builder: (context, state) =>
              Scaffold(appBar: AppBar(title: Text('文档 ${state.pathParameters['id']}'))),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('[1]'));
    await tester.pumpAndSettle();

    expect(find.text('文档 doc-42'), findsOneWidget);
  });
}
