import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

import 'visible_url.dart';

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
/// In-app pops (`context.pop()`, the AppBar back button) never reach the
/// provider at all — go_router has no pop [NavigatingType]; the Router's own
/// post-frame report updates the provider value without notifying listeners,
/// and its engine write is exactly what the read-only strategy neutralizes.
/// So `_sync` never fires and the address bar keeps the popped page's URL —
/// reloading then reopens detail/editor (issue #9). The delegate listener
/// reconciles once per frame: the visible stack's URL ([visibleUrl]) already
/// matches for pushes and `go`s, so only stale pop URLs get rewritten
/// (`replaceState` — the current entry is the page being left).
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

  /// Coalesces bursts of delegate changes (a double pop, pop + go) into one
  /// post-frame reconciliation.
  bool _reconcileScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.router.routeInformationProvider.addListener(_sync);
    widget.router.routerDelegate.addListener(_reconcile);
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
      oldWidget.router.routerDelegate.removeListener(_reconcile);
      widget.router.routerDelegate.addListener(_reconcile);
      _sync();
      _reconcile();
    }
  }

  @override
  void dispose() {
    widget.router.routeInformationProvider.removeListener(_sync);
    widget.router.routerDelegate.removeListener(_reconcile);
    web.window.removeEventListener('popstate', _popStateListener);
    super.dispose();
  }

  /// The Router registers its own delegate listener before this widget
  /// exists (it is an ancestor of MaterialApp's `builder`), so its post-frame
  /// report has landed by the time this callback runs; reading the delegate
  /// configuration directly is safe at any rate — it is updated before
  /// notifyListeners.
  void _reconcile() {
    if (_reconcileScheduled) return;
    _reconcileScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcileScheduled = false;
      if (!mounted) return;
      final target = visibleUrl(widget.router);
      if (target.isEmpty || target == _currentLocation) return;
      web.window.history.replaceState(null, '', target);
    });
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
