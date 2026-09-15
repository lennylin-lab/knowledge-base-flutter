import 'auth_transaction_stub.dart'
    if (dart.library.js_interop) 'auth_transaction_web.dart';

/// One in-flight OIDC authorization round trip. Web only: the browser
/// navigates away and back, so the PKCE verifier + expected state + the
/// pre-login location must survive the reload — web impl stashes them in
/// `sessionStorage`; native keeps them in memory inside `AuthController`
/// and never touches this store.
class AuthTransaction {
  const AuthTransaction({
    required this.state,
    required this.verifier,
    required this.returnTo,
  });

  final String state;
  final String verifier;
  final String returnTo;
}

/// Saves and consumes the web round-trip stash; overridden with a fake in
/// tests (and by the stub elsewhere).
abstract interface class AuthTransactionStore {
  Future<void> save(AuthTransaction transaction);

  /// Reads and removes the stash (one-shot — a replayed callback must not
  /// succeed twice).
  Future<AuthTransaction?> take();
}

AuthTransactionStore createAuthTransactionStore() =>
    createAuthTransactionStoreImpl();
