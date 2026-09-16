import 'package:web/web.dart' as web;

import 'sign_in_driver.dart';

/// Web sign-in driver: full-page navigation to the IdP. The page unloads;
/// the flow resumes on the `/auth/callback` route (transaction — verifier,
/// state, return location — stashed in sessionStorage beforehand), so
/// [acquire] never returns a redirect URI.
///
/// Navigation is a direct `window.location.href` assignment, NOT
/// `url_launcher` (which goes through `window.open(url, '_self',
/// 'noopener')`): the assignment is atomic, cannot be reported as a
//  blocked popup, and is not intercepted by the dwds debug injection
/// client — whose `window.open` wrapper threw
/// `ArgumentError: The type parameter is not nullable` in debug
/// (`flutter run`) sessions before the IdP page ever opened.
class RedirectSignInDriver implements SignInDriver {
  const RedirectSignInDriver();

  @override
  Future<Uri> acquire(Uri authorizeUrl) async {
    try {
      web.window.location.href = authorizeUrl.toString();
    } catch (_) {
      // The assignment itself dispatches the unload; the dwds debug
      // injection may still throw around it. Errors past this point must
      // never surface — the flow resumes on /auth/callback after the IdP
      // redirect, and a torn-down page renders nothing anyway.
    }
    // Navigation started; the isolate goes away with the page, so there is
    // no meaningful failure surface (and no redirect URI to return).
    return Future<Uri>.delayed(const Duration(days: 1));
  }
}

SignInDriver createSignInDriverImpl(String redirectUri) =>
    const RedirectSignInDriver();
