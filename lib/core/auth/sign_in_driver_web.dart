import 'package:url_launcher/url_launcher.dart';

import 'sign_in_driver.dart';

/// Web sign-in driver: full-page navigation to the IdP. The page unloads;
/// the flow resumes on the `/auth/callback` route (transaction — verifier,
/// state, return location — stashed in sessionStorage beforehand), so
/// [acquire] never returns a redirect URI.
class RedirectSignInDriver implements SignInDriver {
  const RedirectSignInDriver();

  @override
  Future<Uri> acquire(Uri authorizeUrl) async {
    final launched = await launchUrl(
      authorizeUrl,
      webOnlyWindowName: '_self',
    );
    if (!launched) {
      throw const BrowserLaunchFailure();
    }
    // Navigation started; the isolate goes away with the page.
    return Future<Uri>.delayed(const Duration(days: 1));
  }
}

SignInDriver createSignInDriverImpl(String redirectUri) =>
    const RedirectSignInDriver();
