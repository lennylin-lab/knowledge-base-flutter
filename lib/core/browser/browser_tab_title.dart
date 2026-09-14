import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/documents/documents_providers.dart';
import 'tab_title_stub.dart' if (dart.library.js_interop) 'tab_title_web.dart';

/// Keeps the browser tab title in sync with the visible page (web only).
///
/// Listens to [router] navigation; document detail/editor routes watch
/// [documentDetailProvider] so the tab shows the document's own title once
/// it loads. The provider is only touched from [build] (via `ref.watch`) —
/// reads from the navigation listener raced the detail page's own first
/// fetch and broke its 404 pop-back flow. Native platforms compile the stub
/// (`setBrowserTabTitle` no-op).
class BrowserTabTitle extends ConsumerStatefulWidget {
  const BrowserTabTitle({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<BrowserTabTitle> createState() => _BrowserTabTitleState();
}

class _BrowserTabTitleState extends ConsumerState<BrowserTabTitle> {
  static const String _appName = '知识库';

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(covariant BrowserTabTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_onRouteChanged);
      widget.router.routerDelegate.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    // Navigation notifications can arrive mid-build — defer to a safe frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Empty match list before the router resolves its first navigation.
    final matches = widget.router.routerDelegate.currentConfiguration;
    final segments = (matches.isEmpty ? '' : matches.last.matchedLocation)
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    // Doc detail/editor only — `new` has no id segment to watch.
    String? docTitle;
    final onDocument =
        segments.length >= 2 &&
        segments.first == 'documents' &&
        segments[1] != 'new' &&
        (segments.length < 3 || segments[2] != 'new');
    if (onDocument) {
      docTitle = ref.watch(documentDetailProvider(segments[1])).value?.title;
    }

    String page;
    if (onDocument) {
      switch (segments.length >= 3 ? segments[2] : '') {
        case 'edit':
          page = '编辑文档${_suffix(docTitle)}';
        case 'summary':
          page = 'AI 摘要${_suffix(docTitle)}';
        case 'associations':
          page = '相关文档${_suffix(docTitle)}';
        default:
          page = '文档详情${_suffix(docTitle)}';
      }
    } else {
      switch (segments.firstOrNull) {
        case 'documents' when segments.length >= 2 && segments[1] == 'new':
          page = '新建文档';
        case 'documents' || null:
          page = '文档';
        case 'search':
          page = '搜索';
        case 'chat' when segments.contains('sessions'):
          page = '会话记录';
        case 'chat':
          page = '问答';
        default:
          page = _appName;
      }
    }

    setBrowserTabTitle(page == _appName ? _appName : '$page · $_appName');
    return widget.child;
  }

  /// `「标题」` once the document has loaded; empty while pending/error so
  /// the route-level label stays readable.
  String _suffix(String? title) => title == null ? '' : '「$title」';
}
