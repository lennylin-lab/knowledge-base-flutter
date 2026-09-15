import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/chat.dart';
import '../config/app_config.dart';
import '../auth/auth_controller.dart' show authHeadersBuilderProvider;
import 'api_exception.dart';
import 'chat_transport.dart';
import 'chat_transport_stub.dart'
    if (dart.library.js_interop) 'chat_transport_web.dart'
    if (dart.library.io) 'chat_transport_native.dart';
import 'sse_parser.dart';

/// Resolves the per-request auth headers (Authorization bearer) at stream
/// open time; null in compat mode. May return an empty map when the user
/// is unauthenticated — the server's 401 then surfaces as the terminal
/// error event, same as any other request failure.
typedef SseHeadersBuilder = Future<Map<String, String>> Function();

/// Chat SSE client — the single unified entry point for QA streaming
/// (design.md §5): one public method, one typed event stream, one parser
/// shared by both transports.
class SseClient {
  SseClient({required this.baseUrl, ChatTransport? transport, this.headers})
    : _transport = transport ?? createChatTransport();

  final String baseUrl;
  final ChatTransport _transport;
  final SseHeadersBuilder? headers;

  Uri get _chatUri => Uri.parse('$baseUrl/api/v1/chat');

  /// Stream one single-turn QA run.
  ///
  /// Transport-level failures (connection refused or dropped, non-2xx with
  /// an error envelope) are normalized into a terminal [ChatErrorEvent]
  /// instead of a thrown exception, mirroring the SSE contract where the
  /// failure can arrive after HTTP 200. A stream that ends without a
  /// terminal event likewise yields `network_error`. Cancelling the
  /// subscription aborts the underlying request.
  Stream<ChatEvent> chatStream(ChatRequest request) async* {
    final decoder = Utf8StreamDecoder();
    final parser = SseChatParser();

    final Stream<Uint8List> bytes;
    try {
      bytes = await _transport.open(
        _chatUri,
        jsonEncode(request.toJson()),
        headers: await _resolveHeaders(),
      );
    } on ApiException catch (e) {
      yield ChatErrorEvent(code: e.code, message: e.message);
      return;
    }

    var terminated = false;
    try {
      await for (final chunk in bytes) {
        for (final event in parser.push(decoder.add(chunk))) {
          yield event;
          if (event is ChatDone || event is ChatErrorEvent) terminated = true;
        }
      }
    } on ApiException catch (e) {
      if (!terminated) yield ChatErrorEvent(code: e.code, message: e.message);
      return;
    } catch (_) {
      // Unexpected transport failure — degrade to a terminal network error.
      if (!terminated) {
        yield const ChatErrorEvent(
          code: 'network_error',
          message: '网络连接中断，请重试',
        );
      }
      return;
    }

    if (!terminated) {
      yield const ChatErrorEvent(
        code: 'network_error',
        message: '网络连接中断，请重试',
      );
    }
  }

  Future<Map<String, String>?> _resolveHeaders() async {
    final builder = headers;
    if (builder == null) return null;
    return builder();
  }
}

/// App-wide SSE client; rebuilt when the configured base URL changes. The
/// headers builder resolves the bearer token per stream (null in compat
/// mode — no auth header is ever attached).
final sseClientProvider = Provider<SseClient>((ref) {
  return SseClient(
    baseUrl: ref.watch(appConfigProvider).baseUrl,
    headers: ref.watch(authHeadersBuilderProvider),
  );
});
