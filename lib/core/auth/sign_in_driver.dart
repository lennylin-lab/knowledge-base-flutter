import 'sign_in_driver_stub.dart'
    if (dart.library.js_interop) 'sign_in_driver_web.dart'
    if (dart.library.io) 'sign_in_driver_io.dart';

/// The browser could not be opened (no browser available / popup blocked).
class BrowserLaunchFailure implements Exception {
  const BrowserLaunchFailure();
}

/// Opens the IdP authorization page and resolves with the redirect URI
/// (carrying `code` / `state` or an OAuth `error` query parameter).
///
/// Platform mapping (conditional import): native runs the loopback-server
/// round trip, web does a full-page redirect (callback handled by the
/// `/auth/callback` route, so it never resolves there).
abstract interface class SignInDriver {
  Future<Uri> acquire(Uri authorizeUrl);
}

SignInDriver createSignInDriver(String redirectUri) =>
    createSignInDriverImpl(redirectUri);
