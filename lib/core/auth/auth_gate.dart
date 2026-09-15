import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'login_page.dart';

/// Swaps the app shell for [LoginPage] while OIDC is enabled and no valid
/// session exists. Compat mode (no issuer configured) renders the shell
/// unchanged, so the app behaves exactly as before auth existed.
///
/// Mounted inside the `StatefulShellRoute` builder — the `/auth/callback`
/// landing route lives outside the shell and therefore outside this gate,
/// so the web redirect flow can complete while still signed out. Auth
/// state changes rebuild the gate: a failed refresh anywhere drops the
/// user onto the login page.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authEnabledProvider)) return child;
    final auth = ref.watch(authControllerProvider);
    final session = auth.session;
    if (session != null) return child;
    return LoginPage(signingIn: auth.signingIn, errorMessage: auth.errorMessage);
  }
}
