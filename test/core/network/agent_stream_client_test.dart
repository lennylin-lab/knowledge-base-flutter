import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/agent_stream_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/network/chat_transport.dart';
import 'package:knowledge_base_flutter/shared/models/agents_stream.dart';

/// One SSE frame with `\r\n` line endings, as sse-starlette emits them.
String frame(String event, String data) =>
    'event: $event\r\n'
    'data: $data\r\n'
    '\r\n';

/// Scripted transport: `open` hands out a controller-driven byte stream so
/// each test drives chunks, errors and end-of-stream explicitly.
class _FakeTransport implements ChatTransport {
  final _controller = StreamController<Uint8List>();
  ApiException? openError;

  Uri? lastUri;
  String? lastBody;
  Map<String, String>? lastHeaders;

  @override
  Future<Stream<Uint8List>> open(
    Uri uri,
    String? jsonBody, {
    Map<String, String>? headers,
  }) async {
    lastHeaders = headers;
    lastUri = uri;
    lastBody = jsonBody;
    final error = openError;
    if (error != null) throw error;
    return _controller.stream;
  }

  void addBytes(List<int> bytes) => _controller.add(Uint8List.fromList(bytes));

  void addWire(String wire) => addBytes(utf8.encode(wire));

  void emitError(Object error) => _controller.addError(error);

  void closeStream() => _controller.close();
}

/// Subscribes to [stream], lets [drive] push bytes/errors, and returns the
/// collected events once the stream completes.
Future<List<AgentStreamEvent>> _collect(
  Stream<AgentStreamEvent> stream,
  _FakeTransport transport,
  void Function(_FakeTransport) drive,
) async {
  final events = <AgentStreamEvent>[];
  final done = Completer<void>();
  final subscription = stream.listen(events.add, onDone: done.complete);
  // One event-loop turn: enough for `open()` to resolve and the generator
  // to subscribe to the byte stream.
  await Future<void>.delayed(Duration.zero);
  drive(transport);
  await done.future;
  await subscription.cancel();
  return events;
}

const documentId = '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01';

const runStartedJson =
    '{"run_id":"11111111-1111-1111-1111-111111111111","kind":"summary",'
    '"document_id":"$documentId"}';

const summaryResultJson =
    '{"document_id":"$documentId","summary":"这份文档记录了知识库的整体设计思路。",'
    '"model":"glm-4.7","latency_ms":1234.5}';

const summaryDoneJson =
    '{"run_id":"11111111-1111-1111-1111-111111111111",'
    '"outcome":"success","latency_ms":1250.0}';

const draftRunStartedJson =
    '{"run_id":"22222222-2222-2222-2222-222222222222","kind":"draft",'
    '"document_id":"$documentId"}';

const draftEventJson =
    '{"operation_id":"aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d","state":"completed",'
    '"content":"---\\ntitle: 星际旅行草稿\\n---\\n\\n续写正文。","title":"星际旅行草稿"}';

const draftDoneJson =
    '{"run_id":"22222222-2222-2222-2222-222222222222",'
    '"outcome":"success","latency_ms":3450.0}';

void main() {
  late _FakeTransport transport;
  late AgentStreamClient client;

  setUp(() {
    transport = _FakeTransport();
    client = AgentStreamClient(
      baseUrl: 'http://localhost:8000',
      transport: transport,
    );
  });

  group('AgentStreamParser (typed decoding)', () {
    test('parses every agent event in wire order', () {
      final parser = AgentStreamParser();
      final events = parser.push(
        frame('run_started', runStartedJson) +
            frame(
              'summary_progress',
              '{"phase":"map_pass","pass_index":1,"passes_total":2}',
            ) +
            frame(
              'summary_progress',
              '{"phase":"reduce_pass","pass_index":2,"passes_total":2}',
            ) +
            frame('summary', summaryResultJson) +
            frame('done', summaryDoneJson),
      );

      expect(events, hasLength(5));

      final started = events[0] as AgentRunStarted;
      expect(started.runId, '11111111-1111-1111-1111-111111111111');
      expect(started.kind, 'summary');
      expect(started.documentId, documentId);

      final first = events[1] as SummaryProgress;
      expect(first.phase, 'map_pass');
      expect(first.passIndex, 1);
      expect(first.passesTotal, 2);
      expect((events[2] as SummaryProgress).phase, 'reduce_pass');

      final summary = (events[3] as AgentSummaryEvent).result;
      expect(summary.documentId, documentId);
      expect(summary.summary, '这份文档记录了知识库的整体设计思路。');
      expect(summary.model, 'glm-4.7');
      expect(summary.latencyMs, 1234.5);

      expect(events[4], isA<AgentDoneEvent>());
      expect(parser.isTerminated, isTrue);
    });

    test('associations events reuse the existing result DTO', () {
      final events = AgentStreamParser().push(
        frame(
          'associations',
          '{"document_id":"$documentId","associations":[],'
              '"model":"glm-4.7","latency_ms":12}',
        ),
      );
      final result = (events.single as AgentAssociationsEvent).result;
      expect(result.associations, isEmpty);
      expect(result.latencyMs, 12.0);
      expect(result.latencyMs, isA<double>());
    });

    test(
      'draft events parse flat; the title is nullable and kind stays raw',
      () {
        final parser = AgentStreamParser();
        final events = parser.push(
          frame('run_started', draftRunStartedJson) +
              frame('draft', draftEventJson) +
              frame('done', draftDoneJson),
        );

        expect(events, hasLength(3));

        // The writing stream's kind — a raw wire string, no enum sentinel.
        final started = events[0] as AgentRunStarted;
        expect(started.kind, 'draft');
        expect(started.kind, isA<String>());

        final draft = events[1] as AgentDraftEvent;
        expect(draft.operationId, 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d');
        expect(draft.state, 'completed');
        expect(draft.content, '---\ntitle: 星际旅行草稿\n---\n\n续写正文。');
        expect(draft.title, '星际旅行草稿');

        expect(events[2], isA<AgentDoneEvent>());
        expect(parser.isTerminated, isTrue);
      },
    );

    test('a draft event without a title parses with a null title', () {
      final events = AgentStreamParser().push(
        frame(
          'draft',
          '{"operation_id":"aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d",'
              '"state":"completed","content":"无标题正文","title":null}',
        ),
      );
      final draft = events.single as AgentDraftEvent;
      expect(draft.title, isNull);
      expect(draft.content, '无标题正文');
    });

    test('error events parse and terminate', () {
      final parser = AgentStreamParser();
      final events = parser.push(
        frame('error', '{"code":"llm_provider_error","message":"boom"}'),
      );
      final error = events.single as AgentErrorEvent;
      expect(error.code, 'llm_provider_error');
      expect(error.message, 'boom');
      expect(parser.isTerminated, isTrue);
      // Post-terminal frames are ignored.
      expect(parser.push(frame('summary', summaryResultJson)), isEmpty);
      expect(parser.close(), isEmpty);
    });

    test('comments, unknown events and non-JSON data are ignored', () {
      final events = AgentStreamParser().push(
        ': ping\r\n\r\n'
        'event: ping\r\ndata: {}\r\n\r\n'
        'event: future_event\r\ndata: {"x":1}\r\n\r\n'
        'event: summary\r\ndata: not-json\r\n\r\n',
      );
      expect(events, isEmpty);
    });
  });

  group('AgentStreamClient.run', () {
    test('posts to the given URI with no request body', () async {
      await _collect(
        client.run(
          Uri.parse('http://localhost:8000/api/v1/documents/x/summary'),
        ),
        transport,
        (t) => t.closeStream(),
      );
      expect(
        transport.lastUri.toString(),
        'http://localhost:8000/api/v1/documents/x/summary',
      );
      expect(
        transport.lastBody,
        isNull,
        reason: 'the agent endpoints take only the path id',
      );
    });

    test('full happy path: progress order, then result, then done', () async {
      final events = await _collect(
        client.run(Uri.parse('http://localhost:8000/x')),
        transport,
        (t) {
          t.addWire(
            frame('run_started', runStartedJson) +
                frame(
                  'summary_progress',
                  '{"phase":"map_pass","pass_index":1,"passes_total":2}',
                ) +
                frame(
                  'summary_progress',
                  '{"phase":"map_pass","pass_index":2,"passes_total":2}',
                ) +
                frame(
                  'summary_progress',
                  '{"phase":"reduce_pass","pass_index":2,"passes_total":2}',
                ) +
                frame('summary', summaryResultJson) +
                frame('done', summaryDoneJson),
          );
          t.closeStream();
        },
      );

      expect(events, hasLength(6));
      expect(events[0], isA<AgentRunStarted>());
      final progress = events.whereType<SummaryProgress>().toList();
      expect(
        progress.map((p) => '${p.phase}:${p.passIndex}/${p.passesTotal}'),
        ['map_pass:1/2', 'map_pass:2/2', 'reduce_pass:2/2'],
      );
      expect(events[4], isA<AgentSummaryEvent>());
      expect(events[5], isA<AgentDoneEvent>());
    });

    test(
      'cache-hit shape: no progress events, straight to the result',
      () async {
        final events = await _collect(
          client.run(Uri.parse('http://localhost:8000/x')),
          transport,
          (t) {
            t.addWire(
              frame('run_started', runStartedJson) +
                  frame('summary', summaryResultJson) +
                  frame('done', summaryDoneJson),
            );
            t.closeStream();
          },
        );

        expect(events.whereType<SummaryProgress>(), isEmpty);
        expect(events[1], isA<AgentSummaryEvent>());
        expect(events[2], isA<AgentDoneEvent>());
      },
    );

    test('terminal error event maps to code + message', () async {
      final events = await _collect(
        client.run(Uri.parse('http://localhost:8000/x')),
        transport,
        (t) {
          t.addWire(
            frame('run_started', runStartedJson) +
                frame(
                  'error',
                  '{"code":"chat_unavailable","message":"no key"}',
                ),
          );
          t.closeStream();
        },
      );

      expect(events, hasLength(2));
      final error = events[1] as AgentErrorEvent;
      expect(error.code, 'chat_unavailable');
      expect(error.message, 'no key');
    });

    test('frames split mid-UTF-8 across chunks still parse', () async {
      final wire =
          frame('run_started', runStartedJson) +
          frame('summary', summaryResultJson) +
          frame('done', summaryDoneJson);
      final bytes = utf8.encode(wire);
      // Split inside the first multi-byte character so the shared
      // Utf8StreamDecoder must hold the partial sequence across chunks.
      final splitAt = bytes.indexWhere((b) => b & 0x80 != 0) + 1;

      final events = await _collect(
        client.run(Uri.parse('http://localhost:8000/x')),
        transport,
        (t) {
          t.addBytes(bytes.sublist(0, splitAt));
          t.addBytes(bytes.sublist(splitAt));
          t.closeStream();
        },
      );

      expect(events, hasLength(3));
      expect(events[0], isA<AgentRunStarted>());
      expect(events[1], isA<AgentSummaryEvent>());
      expect(events[2], isA<AgentDoneEvent>());
    });

    test('premature stream end yields a terminal network_error', () async {
      final events = await _collect(
        client.run(Uri.parse('http://localhost:8000/x')),
        transport,
        (t) {
          t.addWire(frame('run_started', runStartedJson));
          t.closeStream();
        },
      );

      expect(events, hasLength(2));
      expect((events[1] as AgentErrorEvent).code, 'network_error');
    });

    test('mid-stream transport drop degrades to network_error', () async {
      final events = await _collect(
        client.run(Uri.parse('http://localhost:8000/x')),
        transport,
        (t) {
          t.addWire(frame('run_started', runStartedJson));
          t.emitError(StateError('socket reset'));
          t.closeStream();
        },
      );

      expect(events, hasLength(2));
      expect((events[1] as AgentErrorEvent).code, 'network_error');
    });

    test('mid-stream ApiException keeps its code', () async {
      final events = await _collect(
        client.run(Uri.parse('http://localhost:8000/x')),
        transport,
        (t) {
          t.addWire(frame('run_started', runStartedJson));
          t.emitError(
            const ApiException(
              code: 'llm_provider_error',
              message: 'provider boom',
            ),
          );
          t.closeStream();
        },
      );

      final error = events[1] as AgentErrorEvent;
      expect(error.code, 'llm_provider_error');
      expect(error.message, 'provider boom');
    });

    test('pre-stream 404 envelope keeps not_found', () async {
      transport.openError = const ApiException(
        code: 'not_found',
        message: 'Document not found',
        statusCode: 404,
      );

      final events = await _collect(
        client.run(Uri.parse('http://localhost:8000/x')),
        transport,
        (_) {},
      );

      final error = events.single as AgentErrorEvent;
      expect(error.code, 'not_found');
      expect(error.message, 'Document not found');
    });
  });
}
