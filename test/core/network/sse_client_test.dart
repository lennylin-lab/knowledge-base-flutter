import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/network/chat_transport.dart';
import 'package:knowledge_base_flutter/core/network/sse_client.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';

/// One SSE frame with `\r\n` line endings, as sse-starlette emits them.
String frame(String event, String data) =>
    'event: $event\r\n'
    'data: $data\r\n'
    '\r\n';

/// Scripted transport: [open] hands out a controller-driven byte stream so
/// each test drives chunks, errors and end-of-stream explicitly.
class _FakeTransport implements ChatTransport {
  final _controller = StreamController<Uint8List>();
  ApiException? openError;

  Uri? lastUri;
  String? lastBody;

  @override
  Future<Stream<Uint8List>> open(Uri uri, String jsonBody) async {
    lastUri = uri;
    lastBody = jsonBody;
    final error = openError;
    if (error != null) throw error;
    return _controller.stream;
  }

  void addBytes(List<int> bytes) =>
      _controller.add(Uint8List.fromList(bytes));

  void emitError(Object error) => _controller.addError(error);

  void closeStream() => _controller.close();
}

/// Subscribes to [client], lets [drive] push bytes/errors, and returns the
/// collected events once the generator completes.
Future<List<ChatEvent>> collect(
  SseClient client,
  ChatRequest request,
  void Function() drive,
) async {
  final events = <ChatEvent>[];
  final done = Completer<void>();
  final subscription = client
      .chatStream(request)
      .listen(events.add, onDone: done.complete);
  // One event-loop turn: enough for `open()` to resolve and the generator to
  // subscribe to the byte stream (microtasks drain before the timer fires).
  await Future<void>.delayed(Duration.zero);
  drive();
  await done.future;
  await subscription.cancel();
  return events;
}

void main() {
  late _FakeTransport transport;
  late SseClient client;

  setUp(() {
    transport = _FakeTransport();
    client = SseClient(baseUrl: 'http://localhost:8000', transport: transport);
  });

  test('posts the serialized request to /api/v1/chat', () async {
    await collect(
      client,
      const ChatRequest(question: '知识库用什么检索？', limit: 8),
      transport.closeStream,
    );
    expect(transport.lastUri.toString(), 'http://localhost:8000/api/v1/chat');
    expect(
      jsonDecode(transport.lastBody!),
      {'question': '知识库用什么检索？', 'limit': 8},
    );
  });

  test('streams events from raw chunks split mid-UTF-8 and ends at done', () async {
    final wire =
        frame('run_started', '{"run_id":"r","mode":"hybrid"}')
        + frame('answer_delta', '{"text":"答案"}')
        + frame('done', '{"run_id":"r","outcome":"success","tool_calls":1,"latency_ms":5.5}');
    final bytes = utf8.encode(wire);
    // Split inside the first multi-byte character (inside 答案) so the shared
    // Utf8StreamDecoder must hold the partial sequence across chunks.
    final splitAt = bytes.indexWhere((b) => b & 0x80 != 0) + 1;

    final events = await collect(client, const ChatRequest(question: 'q'), () {
      transport.addBytes(bytes.sublist(0, splitAt));
      transport.addBytes(bytes.sublist(splitAt));
      transport.closeStream();
    });

    expect(events, hasLength(3));
    expect(events[0], isA<RunStarted>());
    expect((events[1] as AnswerDelta).text, '答案');
    final done = events[2] as ChatDone;
    expect(done.latencyMs, 5.5);
    // A clean close after `done` must NOT synthesize a network error.
    expect(events.last, isA<ChatDone>());
  });

  test('open() failure yields a single terminal error event', () async {
    transport.openError = const ApiException(
      code: 'chat_unavailable',
      message: 'No API key configured',
      statusCode: 503,
    );

    final events = await collect(
      client,
      const ChatRequest(question: 'q'),
      () {},
    );

    final error = events.single as ChatErrorEvent;
    expect(error.code, 'chat_unavailable');
    expect(error.message, 'No API key configured');
  });

  test('mid-stream ApiException keeps earlier deltas and becomes terminal', () async {
    final events = await collect(client, const ChatRequest(question: 'q'), () {
      transport.addBytes(
        utf8.encode(frame('run_started', '{"run_id":"r","mode":"bm25"}')),
      );
      transport.addBytes(utf8.encode(frame('answer_delta', '{"text":"部分"}')));
      transport.emitError(
        const ApiException(code: 'llm_provider_error', message: 'provider boom'),
      );
      transport.closeStream();
    });

    expect(events, hasLength(3));
    expect((events[1] as AnswerDelta).text, '部分');
    final error = events[2] as ChatErrorEvent;
    expect(error.code, 'llm_provider_error');
    expect(error.message, 'provider boom');
  });

  test('non-ApiException stream failure degrades to network_error', () async {
    final events = await collect(client, const ChatRequest(question: 'q'), () {
      transport.emitError(StateError('socket reset'));
      transport.closeStream();
    });

    final error = events.single as ChatErrorEvent;
    expect(error.code, 'network_error');
  });

  test('stream ending without a terminal event yields network_error', () async {
    final events = await collect(client, const ChatRequest(question: 'q'), () {
      transport.addBytes(
        utf8.encode(frame('run_started', '{"run_id":"r","mode":"hybrid"}')),
      );
      transport.addBytes(utf8.encode(frame('answer_delta', '{"text":"…"}')));
      transport.closeStream();
    });

    expect(events, hasLength(3));
    final error = events[2] as ChatErrorEvent;
    expect(error.code, 'network_error');
  });
}
