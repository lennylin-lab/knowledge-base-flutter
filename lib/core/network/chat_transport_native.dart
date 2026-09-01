import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'chat_transport.dart';

/// Native (windows / android) SSE transport: dio POST with
/// `ResponseType.stream`, yielding the raw response byte stream.
class NativeChatTransport implements ChatTransport {
  NativeChatTransport({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              // Deliberately no receiveTimeout: an SSE stream is long-lived
              // and only needs progress between chunks (the server sends
              // keep-alive comment frames).
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 300,
            ),
          );

  final Dio _dio;

  @override
  Future<Stream<Uint8List>> open(Uri uri, String jsonBody) async {
    try {
      final response = await _dio.post<ResponseBody>(
        uri.toString(),
        data: jsonBody,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data!.stream;
    } on DioException catch (e) {
      // A non-2xx response still streams the error envelope — read it
      // before mapping so its code/message survive into the ApiException.
      final body = e.response?.data;
      if (body is ResponseBody) {
        final text = await _readAll(body);
        final parsed = tryParseErrorEnvelope(text);
        if (parsed != null) throw parsed;
      }
      throw mapDioException(e);
    }
  }

  Future<String> _readAll(ResponseBody body) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in body.stream) {
      bytes.add(chunk);
    }
    return utf8.decode(bytes.takeBytes(), allowMalformed: true);
  }
}

ChatTransport createChatTransport() => NativeChatTransport();
