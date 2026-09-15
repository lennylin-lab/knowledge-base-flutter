import 'package:url_launcher/url_launcher.dart';

import 'loopback_redirect_server.dart';
import 'sign_in_driver.dart';

/// Native (windows / android) sign-in driver: bind the loopback listener
/// first, then open the system browser and wait for the IdP redirect.
class LoopbackSignInDriver implements SignInDriver {
  LoopbackSignInDriver({required this.redirectUri});

  /// Whitelisted loopback redirect (from [OidcConfig]).
  final String redirectUri;

  @override
  Future<Uri> acquire(Uri authorizeUrl) async {
    final server = await LoopbackRedirectServer.bind(Uri.parse(redirectUri));
    try {
      final launched = await launchUrl(
        authorizeUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const BrowserLaunchFailure();
      }
      return await server.wait();
    } finally {
      await server.close();
    }
  }
}

SignInDriver createSignInDriverImpl(String redirectUri) =>
    LoopbackSignInDriver(redirectUri: redirectUri);
