import 'package:flutter_web_plugins/url_strategy.dart';

/// A [PathUrlStrategy] that never writes the browser URL or history state.
///
/// Deep links keep working (getPath/getState read the real browser URL), and
/// the engine's popstate → framework bridge stays wired; but every engine
/// side `pushState` / `replaceState` is a no-op. On the current Flutter
/// master toolchain the engine's runtime URL reporting is unreliable — stale
/// queued reports can land long after the fact and stomp newer URLs (the
/// visible page navigates, the address bar regresses). All URL *writes* are
/// therefore owned by the [UrlSync] shim, driven by go_router's own
/// navigation events; this strategy only keeps the engine's *reads* honest.
class ReadOnlyPathUrlStrategy extends PathUrlStrategy {
  @override
  void pushState(Object? state, String title, String url) {}

  @override
  void replaceState(Object? state, String title, String url) {}
}
