import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/agents_result.dart';
import '../../shared/models/agents_stream.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'chat_transport.dart';
import 'chat_transport_stub.dart'
    if (dart.library.js_interop) 'chat_transport_web.dart'
    if (dart.library.io) 'chat_transport_native.dart';
import 'sse_parser.dart';

/// Pure incremental parser for the document-agent SSE wire format — the
/// typed counterpart of [SseChatParser] (same framing rules via
/// [SseFrameParser]). Feed decoded text chunks with [push]; the returned
/// list holds the events those chunks completed.
///
/// Typing rules on top of the shared framing:
/// - unnamed / empty-data frames and unknown event names are ignored;
/// - frames with non-JSON `data` are ignored, never thrown;
/// - everything after a terminal `done`/`error` event is ignored.
class AgentStreamParser {
  final _frames = SseFrameParser();
  bool _terminated = false;

  /// Whether a terminal `done`/`error` event has already been emitted.
  bool get isTerminated => _terminated;

  /// Feed one decoded text chunk; returns the events it completed.
  List<AgentStreamEvent> push(String chunk) {
    final events = <AgentStreamEvent>[];
    for (final frame in _frames.push(chunk)) {
      final event = _decode(frame);
      if (event != null) events.add(event);
    }
    return events;
  }

  /// Signal end of stream. An unterminated trailing frame is discarded.
  List<AgentStreamEvent> close() => const [];

  AgentStreamEvent? _decode(SseFrame frame) {
    if (_terminated) return null;
    final name = frame.event;
    if (name == null || frame.data.isEmpty) return null;

    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(frame.data);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } on FormatException {
      return null; // tolerate garbage frames, keep the stream alive
    }

    switch (name) {
      case 'run_started':
        return AgentRunStarted.fromJson(json);
      case 'summary_progress':
        return SummaryProgress.fromJson(json);
      case 'summary':
        return AgentSummaryEvent(SummaryResult.fromJson(json));
      case 'associations':
        return AgentAssociationsEvent(AssociationsResult.fromJson(json));
      case 'done':
        _terminated = true;
        return const AgentDoneEvent();
      case 'error':
        _terminated = true;
        return AgentErrorEvent.fromJson(json);
      default:
        return null; // unknown event (keep-alive, future events)
    }
  }
}

/// Document-agent SSE client — the streaming counterpart of the JSON POSTs
/// the documents repository used to make: opens one `POST` via the shared
/// [ChatTransport] (no request body) and parses the typed event stream with
/// [AgentStreamParser].
class AgentStreamClient {
  AgentStreamClient({required this.baseUrl, ChatTransport? transport})
    : _transport = transport ?? createChatTransport();

  final String baseUrl;
  final ChatTransport _transport;

  /// Run one agent stream ([uri] of `…/summary` or `…/associations`).
  ///
  /// Transport-level failures (connection refused, non-2xx with an error
  /// envelope) are normalized into a terminal [AgentErrorEvent] instead of
  /// a thrown exception, mirroring `SseClient.chatStream` where the failure
  /// can arrive after HTTP 200. A stream that ends without a terminal
  /// event likewise yields `network_error`. Cancelling the subscription
  /// aborts the underlying request.
  Stream<AgentStreamEvent> run(Uri uri) async* {
    final decoder = Utf8StreamDecoder();
    final parser = AgentStreamParser();

    final Stream<Uint8List> bytes;
    try {
      bytes = await _transport.open(uri, null);
    } on ApiException catch (e) {
      yield AgentErrorEvent(
        code: e.code,
        message: e.message,
        statusCode: e.statusCode,
      );
      return;
    }

    var terminated = false;
    try {
      await for (final chunk in bytes) {
        for (final event in parser.push(decoder.add(chunk))) {
          yield event;
          if (event is AgentDoneEvent || event is AgentErrorEvent) {
            terminated = true;
          }
        }
      }
    } on ApiException catch (e) {
      if (!terminated) {
        yield AgentErrorEvent(
          code: e.code,
          message: e.message,
          statusCode: e.statusCode,
        );
      }
      return;
    } catch (_) {
      // Unexpected transport failure — degrade to a terminal network error.
      if (!terminated) {
        yield const AgentErrorEvent(
          code: 'network_error',
          message: '网络连接中断，请重试',
        );
      }
      return;
    }

    if (!terminated) {
      yield const AgentErrorEvent(code: 'network_error', message: '网络连接中断，请重试');
    }
  }
}

/// App-wide agent stream client; rebuilt when the configured base URL
/// changes (same wiring as `sseClientProvider`).
final agentStreamClientProvider = Provider<AgentStreamClient>(
  (ref) => AgentStreamClient(baseUrl: ref.watch(appConfigProvider).baseUrl),
);
