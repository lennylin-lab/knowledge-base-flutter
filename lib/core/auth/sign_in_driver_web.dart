import 'dart:async';

import 'package:web/web.dart' as web;

import 'sign_in_driver.dart';

/// Web sign-in driver: full-page navigation to the IdP. The page unloads;
/// the flow resumes on the `/auth/callback` route (transaction — verifier,
/// state, return location — stashed in sessionStorage beforehand), so
/// [acquire] never returns a redirect URI.
///
/// Navigation is a direct `window.location.href` assignment, NOT
/// `url_launcher` (which goes through `window.open(url, '_self',
/// 'noopener')`): the assignment is atomic and cannot be reported as a
/// blocked popup.
class RedirectSignInDriver implements SignInDriver {
  const RedirectSignInDriver();

  @override
  Future<Uri> acquire(Uri authorizeUrl) async {
    try {
      web.window.location.href = authorizeUrl.toString();
    } catch (_) {
      // The assignment itself dispatches the unload; anything throwing
      // around it must never surface — the flow resumes on /auth/callback
      // after the IdP redirect, and a torn-down page renders nothing anyway.
    }
    // Navigation started; the isolate goes away with the page, so there is
    // no meaningful failure surface (and no redirect URI to return). Never
    // `Future<Uri>.delayed(...)`: with a null computation it throws
    // `ArgumentError: The type parameter is not nullable` on modern SDKs,
    // surfacing a bogus sign-in failure while the redirect is under way.
    final completer = Completer<Uri>();
    return completer.future;
  }
}

SignInDriver createSignInDriverImpl(String redirectUri) =>
    const RedirectSignInDriver();
