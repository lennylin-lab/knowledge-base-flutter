/// Keeps the browser URL in sync with GoRouter navigation (web; no-op on
/// native). See the web implementation for why this shim exists.
library;

export 'url_sync_stub.dart' if (dart.library.js_interop) 'url_sync_web.dart';
