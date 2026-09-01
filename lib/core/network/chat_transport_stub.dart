import 'chat_transport.dart';

/// Fallback factory for platforms without a chat SSE transport (none of the
/// MVP targets — web/windows/android all select a real implementation).
ChatTransport createChatTransport() => throw UnsupportedError(
  'No chat SSE transport for this platform',
);
