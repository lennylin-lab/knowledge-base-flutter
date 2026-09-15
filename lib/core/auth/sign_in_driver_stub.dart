import 'sign_in_driver.dart';

/// Fallback for platforms with neither `dart:io` nor web bindings.
SignInDriver createSignInDriverImpl(String redirectUri) =>
    throw UnsupportedError('no sign-in driver on this platform');
