import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/layout/layout_preferences.dart';
import 'core/theme/app_sizes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preferences.dart';
import 'features/chat/chat_page.dart';
import 'features/chat/sessions_page.dart';
import 'features/documents/document_detail_page.dart';
import 'features/documents/document_editor_page.dart';
import 'features/documents/documents_page.dart';
import 'features/search/search_page.dart';
import 'shared/widgets/resizable_pane.dart';

/// Root widget: Material 3 app, three-branch shell.
///
/// Brightness follows [themeModeProvider] — system until the user picks
/// light/dark in the app-bar 主题 menu (persisted via `theme_preferences`).
///
/// The router is a per-instance value (not a static) so every `App()` —
/// including each widget test — gets an isolated navigation state; pass a
/// custom router to drive deep links directly.
class App extends ConsumerWidget {
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
                routes: [
                  GoRoute(
                    path: 'sessions',
                    name: 'chat-sessions',
                    builder: (context, state) => const SessionsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One window-level scale drives every size in the app: the theme (text,
    // default icons) and the AppSizes tokens (`context.sizes`) derive from it.
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = AppSizes.scaleForWidth(constraints.maxWidth);
        return MaterialApp.router(
          title: '知识库',
          theme: AppTheme.light(scale),
          darkTheme: AppTheme.dark(scale),
          themeMode: ref.watch(themeModeProvider),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
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
///
/// The rail edge is draggable on wide layouts (persisted width via
/// [layoutWidthsProvider], two-tier shrink bounds in `_rail*` constants).
/// Until the rail has been dragged (`width == null`) the layout is
/// pixel-identical to the pre-resizable shell.
class _AdaptiveShell extends ConsumerWidget {
  const _AdaptiveShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Rail pane sizing (layout constraints, exempt from AppSizes tokens):
  /// default/auto, tier-one (responsive) minimum, tier-two hard minimum,
  /// strict maximum.
  static const String _railPaneId = 'nav.rail';
  static const double _railDefaultWidth = 240;
  static const double _railResponsiveMinWidth = 176;
  static const double _railAbsoluteMinWidth = 88;
  static const double _railMaxWidth = 320;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the current destination again pops back to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NavigationRail/NavigationBar resolve icon size from their own theme
    // data, not the global iconTheme — set it explicitly via the tokens.
    final iconSize = context.sizes.iconLg;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 600;
        if (useRail) {
          final railWidth = ref
              .watch(layoutWidthsProvider)
              .widthOf(_railPaneId);
          // Untouched rail keeps the existing window-breakpoint behavior;
          // once dragged, labels show whenever the pane is above tier one.
          final extended = railWidth != null
              ? railWidth >= _railResponsiveMinWidth
              : constraints.maxWidth >= 840;
          void setWidth(double width, {required bool persist}) {
            final notifier = ref.read(layoutWidthsProvider.notifier);
            if (persist) {
              notifier.saveWidth(_railPaneId, width);
            } else {
              notifier.applyWidth(_railPaneId, width);
            }
          }

          return Scaffold(
            body: Row(
              children: [
                ResizablePane(
                  width: railWidth,
                  defaultWidth: _railDefaultWidth,
                  responsiveMinWidth: _railResponsiveMinWidth,
                  absoluteMinWidth: _railAbsoluteMinWidth,
                  maxWidth: _railMaxWidth,
                  side: PaneSide.right,
                  onWidthChanged: (width) =>
                      setWidth(width, persist: false),
                  onWidthDragEnd: (width) => setWidth(width, persist: true),
                  child: NavigationRail(
                    extended: extended,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _goBranch,
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon, size: iconSize),
                          selectedIcon: Icon(d.selectedIcon, size: iconSize),
                          label: Text(d.label),
                        ),
                    ],
                  ),
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
                  icon: Icon(d.icon, size: iconSize),
                  selectedIcon: Icon(d.selectedIcon, size: iconSize),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
