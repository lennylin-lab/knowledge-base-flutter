import 'auth_transaction.dart';

/// Fallback (native platforms / tests without web bindings): never called
/// — native sign-in keeps the transaction in memory.
class NoopAuthTransactionStore implements AuthTransactionStore {
  @override
  Future<void> save(AuthTransaction transaction) async {}

  @override
  Future<AuthTransaction?> take() async => null;
}

AuthTransactionStore createAuthTransactionStoreImpl() =>
    NoopAuthTransactionStore();
