import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

import 'api_client.dart';
import 'api_exception.dart';
import 'chat_transport.dart';

/// Web SSE transport: `fetch` + `response.body.getReader()`.
///
/// dio's XHR adapter cannot stream response bodies, so the browser fetch API
/// is used directly; the byte chunks feed the same parser as native.
///
/// `--dart-define=KB_SSE_VIA_DIO=true` forces a buffered dio fallback (the
/// whole body arrives at once — no incremental rendering) for debugging
/// fetch/reader issues (design.md §9).
class WebChatTransport implements ChatTransport {
  WebChatTransport({Dio? dio}) : _dio = dio;

  final Dio? _dio;

  static const bool _forceDio = bool.fromEnvironment('KB_SSE_VIA_DIO');

  @override
  Future<Stream<Uint8List>> open(
    Uri uri,
    String? jsonBody, {
    Map<String, String>? headers,
  }) async {
    if (_forceDio) {
      // Debug escape hatch (dart-define) — works even without an injected
      // dio, `_openViaDio` falls back to a fresh instance.
      return _openViaDio(uri, jsonBody, headers);
    }
    return _openViaFetch(uri, jsonBody, headers);
  }

  Future<Stream<Uint8List>> _openViaFetch(
    Uri uri,
    String? jsonBody,
    Map<String, String>? headers,
  ) async {
    // HeadersInit is an opaque JSObject — a plain object with string
    // properties. setProperty comes from dart:js_interop_unsafe.
    final requestHeaders = JSObject()
      ..setProperty('Accept'.toJS, 'text/event-stream'.toJS);
    // A bodyless POST (agent endpoints) carries no content type.
    if (jsonBody != null) {
      requestHeaders.setProperty('Content-Type'.toJS, 'application/json'.toJS);
    }
    headers?.forEach(
      (name, value) => requestHeaders.setProperty(name.toJS, value.toJS),
    );

    final web.Response response;
    try {
      response = await web.window
          .fetch(
            uri.toString().toJS,
            web.RequestInit(
              method: 'POST',
              headers: requestHeaders,
              // Null body: the request is sent without a payload.
              body: jsonBody?.toJS,
            ),
          )
          .toDart;
    } catch (_) {
      // fetch() rejects on network-level failures (DNS, refused, CORS).
      throw const ApiException(
        code: 'network_error',
        message: '网络连接异常，请检查网络后重试',
      );
    }

    if (!response.ok) {
      final text = (await response.text().toDart).toDart;
      final parsed = tryParseErrorEnvelope(text);
      if (parsed != null) throw parsed;
      final serverSide = response.status >= 500;
      throw ApiException(
        code: serverSide ? 'server_error' : 'network_error',
        message: serverSide ? '服务暂不可用，请稍后重试' : '网络连接异常，请检查网络后重试',
        statusCode: response.status,
      );
    }

    final body = response.body;
    if (body == null) {
      // No streaming body exposed — read everything, emit once.
      final text = (await response.text().toDart).toDart;
      return Stream<Uint8List>.value(utf8.encode(text));
    }

    final reader = _SseReader(body.getReader());
    final controller = StreamController<Uint8List>(
      onCancel: () async {
        try {
          await reader.cancel().toDart;
        } catch (_) {
          // Reader already released — nothing to do.
        }
      },
    );

    unawaited(() async {
      try {
        while (!controller.isClosed) {
          final result = await reader.read().toDart;
          if (controller.isClosed) return;
          if (result.done) {
            await controller.close();
            return;
          }
          final value = result.value;
          if (value != null) {
            controller.add((value as JSUint8Array).toDart);
          }
        }
      } catch (e, s) {
        // Surface mid-stream failures as stream errors; SseClient maps them.
        if (!controller.isClosed) {
          controller.addError(e, s);
          await controller.close();
        }
      }
    }());

    return controller.stream;
  }

  Future<Stream<Uint8List>> _openViaDio(
    Uri uri,
    String? jsonBody,
    Map<String, String>? headers,
  ) async {
    final dio = _dio ?? Dio();
    try {
      final response = await dio.post<String>(
        uri.toString(),
        data: jsonBody,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Accept': 'text/event-stream',
            'Content-Type': 'application/json',
            ...?headers,
          },
        ),
      );
      return Stream<Uint8List>.value(utf8.encode(response.data ?? ''));
    } on DioException catch (e) {
      final parsed = tryParseErrorEnvelope(e.response?.data);
      if (parsed != null) throw parsed;
      throw mapDioException(e);
    }
  }
}

/// package:web types `getReader()` as an opaque [JSObject]; these extension
/// types restore the members the chat transport needs. Primary constructors
/// stay public so values can be wrapped straight from interop results.
extension type _SseReader(JSObject _) implements JSObject {
  external JSPromise<_ReadResult> read();

  external JSPromise<JSAny?> cancel([JSAny? reason]);
}

extension type _ReadResult(JSObject _) implements JSObject {
  external bool get done;

  external JSAny? get value;
}

ChatTransport createChatTransport() => WebChatTransport();
