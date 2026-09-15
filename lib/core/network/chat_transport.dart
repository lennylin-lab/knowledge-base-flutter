import 'dart:typed_data';

/// One opened SSE `POST` response, as a raw byte stream.
///
/// Implementations must throw [ApiException] (envelope decoded when the
/// server sent one, `network_error`/`server_error` otherwise) when the
/// request cannot be opened; mid-stream failures surface as stream errors.
/// [jsonBody] null sends no request body at all (the document-agent
/// endpoints take only the path id). [headers] carries per-request auth
/// headers (Authorization); implementations merge them with their
/// Accept/Content-Type defaults.
abstract interface class ChatTransport {
  Future<Stream<Uint8List>> open(
    Uri uri,
    String? jsonBody, {
    Map<String, String>? headers,
  });
}
