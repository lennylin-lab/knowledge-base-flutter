import 'auth_session.dart';
import 'token_store_stub.dart'
    if (dart.library.js_interop) 'token_store_web.dart'
    if (dart.library.io) 'token_store_io.dart';

export 'token_store_stub.dart'
    if (dart.library.js_interop) 'token_store_web.dart'
    if (dart.library.io) 'token_store_io.dart';

/// Persists the [AuthSession] blob across restarts.
///
/// Platform mapping (conditional import, same split as `ChatTransport`):
/// native (windows / android) uses `flutter_secure_storage`, web falls back
/// to `shared_preferences` (same store as the other app prefs — the MVP
/// accepts web-token XSS exposure in exchange for no extra plugin).
abstract interface class TokenStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

/// Loads the persisted session once from `main()`, tolerating a broken or
/// unreadable store (the user then just signs in again).
Future<AuthSession?> loadPersistedSession() async {
  try {
    return await createTokenStore().read();
  } catch (_) {
    return null;
  }
}
