import 'dart:typed_data';

/// One opened `POST /api/v1/chat` SSE response, as a raw byte stream.
///
/// Implementations must throw [ApiException] (envelope decoded when the
/// server sent one, `network_error`/`server_error` otherwise) when the
/// request cannot be opened; mid-stream failures surface as stream errors.
abstract interface class ChatTransport {
  Future<Stream<Uint8List>> open(Uri uri, String jsonBody);
}
