import 'auth_session.dart';
import 'token_store.dart';

/// Fallback for platforms with neither `dart:io` nor web bindings (keeps
/// the conditional import total). Never reached in the MVP targets.
class UnsupportedTokenStore implements TokenStore {
  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

TokenStore createTokenStore() => UnsupportedTokenStore();
