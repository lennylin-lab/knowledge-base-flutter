import 'dart:convert';

import 'package:web/web.dart' as web;

import 'auth_transaction.dart';

/// Web implementation: `window.sessionStorage` — survives the redirect
/// round trip within the tab and dies with it (no cross-tab leakage).
class WebAuthTransactionStore implements AuthTransactionStore {
  static const _key = 'auth.oidc.tx';

  @override
  Future<void> save(AuthTransaction transaction) async {
    web.window.sessionStorage.setItem(
      _key,
      jsonEncode({
        'state': transaction.state,
        'verifier': transaction.verifier,
        'returnTo': transaction.returnTo,
      }),
    );
  }

  @override
  Future<AuthTransaction?> take() async {
    final raw = web.window.sessionStorage.getItem(_key);
    web.window.sessionStorage.removeItem(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final state = decoded['state'];
      final verifier = decoded['verifier'];
      final returnTo = decoded['returnTo'];
      if (state is String && verifier is String && returnTo is String) {
        return AuthTransaction(
          state: state,
          verifier: verifier,
          returnTo: returnTo,
        );
      }
    } on FormatException {
      // Corrupt stash — treated as a missing transaction below.
    }
    return null;
  }
}

AuthTransactionStore createAuthTransactionStoreImpl() =>
    WebAuthTransactionStore();
