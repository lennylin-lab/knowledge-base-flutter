import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/chat_page.dart';
import 'features/documents/document_detail_page.dart';
import 'features/documents/document_editor_page.dart';
import 'features/documents/documents_page.dart';
import 'features/search/search_page.dart';

/// Root widget: Material 3 app, system light/dark, three-branch shell.
///
/// The router is a per-instance value (not a static) so every `App()` —
/// including each widget test — gets an isolated navigation state; pass a
/// custom router to drive deep links directly.
class App extends StatelessWidget {
  App({super.key, GoRouter? router}) : router = router ?? buildRouter();

  final GoRouter router;

  /// Route table. Detail/editor live inside the documents branch, so the
  /// three-tab state is kept while they are shown. Static segments
  /// (`new`) are declared before the dynamic one (`:id`).
  static GoRouter buildRouter() => GoRouter(
    initialLocation: '/documents',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AdaptiveShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                name: 'documents',
                builder: (context, state) => const DocumentsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'document-create',
                    builder: (context, state) => const DocumentEditorPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'document-detail',
                    builder: (context, state) => DocumentDetailPage(
                      documentId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'document-edit',
                        builder: (context, state) => DocumentEditorPage(
                          documentId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                builder: (context, state) => const ChatPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '知识库',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

const _destinations = [
  _Destination(
    label: '文档',
    icon: Icons.description_outlined,
    selectedIcon: Icons.description,
    path: '/documents',
  ),
  _Destination(
    label: '搜索',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
    path: '/search',
  ),
  _Destination(
    label: '问答',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
    path: '/chat',
  ),
];

/// Adaptive navigation shell (Material 3 breakpoints): expanded rail ≥ 840,
/// collapsed rail 600–840, bottom bar < 600. Content area is identical in
/// every shell (component-guidelines spec).
class _AdaptiveShell extends StatelessWidget {
  const _AdaptiveShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the current destination again pops back to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 600;
        if (useRail) {
          final extended = constraints.maxWidth >= 840;
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
