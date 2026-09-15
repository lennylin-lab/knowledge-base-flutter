import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/network/chat_transport.dart';
import 'package:knowledge_base_flutter/core/network/sse_client.dart';
import 'package:knowledge_base_flutter/features/chat/chat_repository.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';

/// One SSE frame, as sse-starlette emits it (`\r\n` line endings).
String _frame(String event, String data) =>
    'event: $event\r\n'
    'data: $data\r\n'
    '\r\n';

/// Scripted transport: records the request and hands out a controller-driven
/// byte stream (same pattern as sse_client_test's fake).
class _FakeTransport implements ChatTransport {
  final _controller = StreamController<Uint8List>();
  ApiException? openError;

  Uri? lastUri;
  String? lastBody;

  @override
  Future<Stream<Uint8List>> open(Uri uri, String? jsonBody) async {
    lastUri = uri;
    lastBody = jsonBody;
    final error = openError;
    if (error != null) throw error;
    return _controller.stream;
  }

  void emit(String wire) =>
      _controller.add(Uint8List.fromList(utf8.encode(wire)));

  void closeStream() => _controller.close();
}

/// Collects everything [repository.chat] yields for one run.
Future<List<ChatEvent>> collect(
  ChatRepository repository,
  void Function() drive, {
  String question = '什么是 RAG？',
  int limit = ChatRepository.defaultLimit,
}) async {
  final events = <ChatEvent>[];
  final done = Completer<void>();
  final subscription = repository
      .chat(question: question, limit: limit)
      .listen(events.add, onDone: done.complete);
  await Future<void>.delayed(Duration.zero);
  drive();
  await done.future;
  await subscription.cancel();
  return events;
}

void main() {
  late _FakeTransport transport;
  late ChatRepository repository;

  setUp(() {
    transport = _FakeTransport();
    repository = ChatRepository(
      SseClient(baseUrl: 'http://localhost:8000', transport: transport),
    );
  });

  test('posts the question with the clamped limit to /api/v1/chat', () async {
    await collect(repository, transport.closeStream, question: ' 知识库 ');

    expect(transport.lastUri.toString(), 'http://localhost:8000/api/v1/chat');
    expect(
      jsonDecode(transport.lastBody!),
      {'question': ' 知识库 ', 'limit': ChatRepository.defaultLimit},
    );
  });

  test('clamps limit into the API 1–20 range before sending', () async {
    Future<Object?> sentLimit(int limit) async {
      final t = _FakeTransport();
      final repo = ChatRepository(
        SseClient(baseUrl: 'http://localhost:8000', transport: t),
      );
      await collect(repo, t.closeStream, limit: limit);
      return jsonDecode(t.lastBody!)['limit'];
    }

    expect(await sentLimit(0), 1);
    expect(await sentLimit(100), 20);
    expect(await sentLimit(5), 5);
  });

  test('streams the run_started → answer_delta → done events untouched', () async {
    final events = await collect(repository, () {
      transport.emit(
        _frame('run_started', '{"run_id":"r","mode":"hybrid"}'),
      );
      transport.emit(_frame('answer_delta', '{"text":"答案"}'));

      transport.emit(
        _frame(
          'done',
          '{"run_id":"r","outcome":"success","tool_calls":2,"latency_ms":1234.5}',
        ),
      );
      transport.closeStream();
    });

    expect(events, hasLength(3));
    expect(events[0], isA<RunStarted>());
    expect((events[1] as AnswerDelta).text, '答案');
    final done = events[2] as ChatDone;
    expect(done.latencyMs, 1234.5);
    expect(done.toolCalls, 2);
  });

  test('normalizes an open() failure into a terminal ChatErrorEvent', () async {
    transport.openError = const ApiException(
      code: 'chat_unavailable',
      message: 'Chat service is unavailable',
      statusCode: 503,
    );

    final events = await collect(repository, () {});

    final error = events.single as ChatErrorEvent;
    expect(error.code, 'chat_unavailable');
    expect(error.message, 'Chat service is unavailable');
  });

  test('an SSE terminal error event passes through as-is (HTTP may be 200)', () async {
    final events = await collect(repository, () {
      transport.emit(_frame('run_started', '{"run_id":"r","mode":"bm25"}'));
      transport.emit(_frame('answer_delta', '{"text":"部分"}'));

      transport.emit(
        _frame('error', '{"code":"llm_provider_error","message":"provider down"}'),
      );
      transport.closeStream();
    });

    expect(events, hasLength(3));
    expect((events[1] as AnswerDelta).text, '部分');
    final error = events[2] as ChatErrorEvent;
    expect(error.code, 'llm_provider_error');
    expect(error.message, 'provider down');
  });
}
