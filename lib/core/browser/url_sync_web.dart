import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

/// Mirrors the router's location into the browser history stack.
///
/// The Flutter master toolchain this project builds with (3.48.0-1.0.pre-717)
/// has a broken runtime URL-reporting pipeline: the framework sends
/// `routeInformationUpdated`, but the browser URL never changes — the visible
/// page does, so any reload lands back on the stale URL (e.g. opening a
/// document detail keeps the URL at `/documents`, and F5 drops the user on
/// the list). Deep links are parsed correctly at startup; only runtime
/// reports are lost.
///
/// This shim re-applies what the engine drops, straight through
/// `history.pushState` / `replaceState`, keyed on go_router's own
/// [NavigatingType]: `push` opens a history entry (browser back unwinds
/// detail pages), every other type replaces the current entry. If a future
/// toolchain fixes the engine pipeline, the engine's own report lands first
/// and the equality guard makes this shim a no-op.
///
/// `popstate` (browser back / forward) is bridged too, defensively: the
/// engine's own popstate → `pushRouteInformation` path may be equally dead.
/// The bridge defers one microtask so a working engine lands first; if the
/// provider already reflects the popped URL this is a no-op, otherwise the
/// router is driven to it.
class UrlSync extends StatefulWidget {
  const UrlSync({super.key, required this.router, required this.child});

  final GoRouter router;

  final Widget child;

  @override
  State<UrlSync> createState() => _UrlSyncStateWeb();
}

class _UrlSyncStateWeb extends State<UrlSync> {
  late final JSFunction _popStateListener;

  @override
  void initState() {
    super.initState();
    widget.router.routeInformationProvider.addListener(_sync);
    _popStateListener = ((web.Event _) {
      // Defer: let a working engine report land first, then only patch up
      // the leftover gap between the popped URL and the router.
      Future<void>.microtask(() {
        if (!mounted) return;
        final target = _currentLocation;
        if (widget.router.routeInformationProvider.value.uri.toString() !=
            target) {
          widget.router.go(target);
        }
      });
    }).toJS;
    web.window.addEventListener('popstate', _popStateListener);
  }

  @override
  void didUpdateWidget(UrlSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routeInformationProvider.removeListener(_sync);
      widget.router.routeInformationProvider.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.router.routeInformationProvider.removeListener(_sync);
    web.window.removeEventListener('popstate', _popStateListener);
    super.dispose();
  }

  String get _currentLocation =>
      '${web.window.location.pathname}${web.window.location.search}';

  void _sync() {
    final info = widget.router.routeInformationProvider.value;
    final target = info.uri.toString();
    if (target == _currentLocation) return;
    final state = info.state;
    final type = state is RouteInformationState
        ? state.type
        : NavigatingType.go;
    switch (type) {
      case NavigatingType.push:
        web.window.history.pushState(null, '', target);
      case NavigatingType.pushReplacement ||
        NavigatingType.replace ||
        NavigatingType.go ||
        NavigatingType.restore:
        web.window.history.replaceState(null, '', target);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
