import 'package:go_router/go_router.dart';

/// The browser URL the current route stack maps to: the top-most
/// imperatively pushed match's URI when one exists (`context.push` leaves
/// that wrapper on the stack), otherwise the base configuration URI.
///
/// This mirrors `GoRouteInformationParser.restoreRouteInformation`'s walk,
/// except the imperative drill-down is unconditional. The app keeps
/// `GoRouter.optionURLReflectsImperativeAPIs` false (push URLs are owned by
/// the UrlSync shim instead), so with the stock reporter a push's reported
/// location is the *base* URI — unusable as the visible address.
///
/// Pure and platform-neutral so VM tests can pin the mapping against a real
/// router; the UrlSync web shim drives browser history writes from it.
String visibleUrl(GoRouter router) {
  final config = router.routerDelegate.currentConfiguration;
  if (config.matches.isEmpty) return config.uri.toString();
  RouteMatchBase walker = config.matches.last;
  while (walker is ShellRouteMatch && walker.matches.isNotEmpty) {
    walker = walker.matches.last;
  }
  if (walker is ImperativeRouteMatch) return walker.matches.uri.toString();
  return config.uri.toString();
}
