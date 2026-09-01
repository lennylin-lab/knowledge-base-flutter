import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/sse_parser.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

/// Serializes one SSE frame exactly like sse-starlette (`\r\n` line endings).
String frame(String event, String data, {String eol = '\r\n'}) =>
    'event: $event$eol'
    'data: $data$eol'
    '$eol';

/// Feeds [wire] through the parser in chunks of [size] to prove buffering.
List<ChatEvent> parseChunked(String wire, SseChatParser parser, {int size = 1}) {
  final events = <ChatEvent>[];
  for (var i = 0; i < wire.length; i += size) {
    events.addAll(parser.push(wire.substring(i, i + size > wire.length ? wire.length : i + size)));
  }
  return events;
}

const happyPathWire = ''
    'event: run_started\r\n'
    'data: {"run_id":"11111111-1111-1111-1111-111111111111","mode":"hybrid"}\r\n'
    '\r\n'
    'event: sources\r\n'
    'data: {"items":[{"document_id":"d1","document_title":"文档一","document_tags":["a"],"chunk_index":0,"content":"片段一","score":0.5,"es_rank":1,"vector_rank":2}]}\r\n'
    '\r\n'
    'event: sources\r\n'
    'data: {"items":[{"document_id":"d2","document_title":"文档二","document_tags":[],"chunk_index":3,"content":"片段二","score":0.25,"es_rank":null,"vector_rank":null}]}\r\n'
    '\r\n'
    'event: answer_delta\r\n'
    'data: {"text":"根据"}\r\n'
    '\r\n'
    'event: answer_delta\r\n'
    'data: {"text":"知识库"}\r\n'
    '\r\n'
    'event: answer_delta\r\n'
    'data: {"text":"内容回答"}\r\n'
    '\r\n'
    'event: done\r\n'
    'data: {"run_id":"11111111-1111-1111-1111-111111111111","outcome":"success","tool_calls":2,"latency_ms":1234.5}\r\n'
    '\r\n';

void main() {
  group('SseChatParser happy path', () {
    test('emits run_started → sources ×2 → answer_delta ×3 → done in order',
        () {
      final events = SseChatParser().push(happyPathWire);

      expect(events, hasLength(7));
      final started = events[0] as RunStarted;
      expect(started.runId, '11111111-1111-1111-1111-111111111111');
      expect(started.mode, SearchMode.hybrid);

      final first = events[1] as SourcesEvent;
      expect(first.items, hasLength(1));
      expect(first.items.first.documentId, 'd1');
      expect(first.items.first.documentTitle, '文档一');
      expect(first.items.first.esRank, 1);
      expect(first.items.first.vectorRank, 2);

      final second = events[2] as SourcesEvent;
      expect(second.items.first.documentId, 'd2');
      expect(second.items.first.esRank, isNull);
      expect(second.items.first.vectorRank, isNull);

      expect((events[3] as AnswerDelta).text, '根据');
      expect((events[4] as AnswerDelta).text, '知识库');
      expect((events[5] as AnswerDelta).text, '内容回答');

      final done = events[6] as ChatDone;
      expect(done.runId, '11111111-1111-1111-1111-111111111111');
      expect(done.outcome, 'success');
      expect(done.toolCalls, 2);
      expect(done.latencyMs, 1234.5);

      expect(SseChatParser().push(happyPathWire).last, isA<ChatDone>());
    });

    test('byte-at-a-time chunking yields the same events', () {
      final parser = SseChatParser();
      final events = parseChunked(happyPathWire, parser, size: 1);
      expect(events, hasLength(7));
      expect(events.first, isA<RunStarted>());
      expect(events.last, isA<ChatDone>());
    });

    test('chunks split inside the JSON payload are buffered, not dropped', () {
      final parser = SseChatParser();
      const wire =
          'event: run_started\r\n'
          'data: {"run_i'
          'd":"abc","mode":"bm25"}\r\n\r\n';
      final events = parseChunked(wire, parser, size: 5);
      expect(events, hasLength(1));
      final started = events.single as RunStarted;
      expect(started.runId, 'abc');
      expect(started.mode, SearchMode.bm25);
    });

    test('LF-only line endings are accepted too', () {
      final parser = SseChatParser();
      const wire =
          'event: answer_delta\n'
          'data: {"text":"hello"}\n\n';
      final events = parser.push(wire);
      expect((events.single as AnswerDelta).text, 'hello');
    });
  });

  group('terminal events', () {
    test('terminal error after deltas is emitted, later events ignored', () {
      final parser = SseChatParser();
      const wire = ''
          'event: run_started\r\n'
          'data: {"run_id":"r","mode":"hybrid"}\r\n'
          '\r\n'
          'event: answer_delta\r\n'
          'data: {"text":"部分"}\r\n'
          '\r\n'
          'event: answer_delta\r\n'
          'data: {"text":"答案"}\r\n'
          '\r\n'
          'event: error\r\n'
          'data: {"code":"llm_provider_error","message":"provider boom"}\r\n'
          '\r\n'
          'event: answer_delta\r\n'
          'data: {"text":"should be ignored"}\r\n'
          '\r\n'
          'event: done\r\n'
          'data: {"run_id":"r","outcome":"success","tool_calls":0,"latency_ms":1}\r\n'
          '\r\n';
      final events = parser.push(wire);

      expect(events, hasLength(4)); // started + 2 deltas + error
      final error = events.last as ChatErrorEvent;
      expect(error.code, 'llm_provider_error');
      expect(error.message, 'provider boom');
      expect(parser.isTerminated, isTrue);

      // A trailing chunk after close must not resurrect the stream.
      expect(parser.push(frame('answer_delta', '{"text":"x"}')), isEmpty);
      expect(parser.close(), isEmpty);
    });

    test('events after terminal done are ignored', () {
      final parser = SseChatParser();
      final events = parser.push(
        frame('done', '{"run_id":"r","outcome":"success","tool_calls":0,"latency_ms":9.0}')
            + frame('answer_delta', '{"text":"late"}'),
      );
      expect(events, hasLength(1));
      expect(events.single, isA<ChatDone>());
    });
  });

  group('robustness', () {
    test('multi-line data joins with newline before JSON parsing', () {
      final parser = SseChatParser();
      const wire =
          'event: answer_delta\r\n'
          'data: {"text":\r\n'
          'data: "joined"}\r\n'
          '\r\n';
      final events = parser.push(wire);
      expect((events.single as AnswerDelta).text, 'joined');
    });

    test('comment frames and unknown event names are ignored', () {
      final parser = SseChatParser();
      final wire = ': ping - 2026-09-01T00:00:00Z\r\n\r\n'
          'event: ping\r\n'
          'data: {}\r\n'
          '\r\n'
          'id: 42\r\n'
          'retry: 15000\r\n'
          'event: answer_delta\r\n'
          'data: {"text":"kept"}\r\n'
          '\r\n';
      final events = parser.push(wire);
      expect(events, hasLength(1));
      expect((events.single as AnswerDelta).text, 'kept');
    });

    test('non-JSON data frames are ignored without throwing', () {
      final parser = SseChatParser();
      final events = parser.push('event: answer_delta\r\ndata: not-json\r\n\r\n');
      expect(events, isEmpty);
      expect(parser.isTerminated, isFalse);
    });

    test('frames without an event name are ignored', () {
      final parser = SseChatParser();
      final events = parser.push('data: {"text":"x"}\r\n\r\n');
      expect(events, isEmpty);
    });

    test('CRLF split across chunks is handled', () {
      final parser = SseChatParser();
      final head = 'event: answer_delta\r'; // CR at chunk end
      final tail = '\ndata: {"text":"ok"}\r\n\r\n';
      final events = [...parser.push(head), ...parser.push(tail)];
      expect((events.single as AnswerDelta).text, 'ok');
    });

    test('an incomplete trailing frame is discarded on close', () {
      final parser = SseChatParser();
      final events = parser.push('event: answer_delta\r\ndata: {"text":"lost"}\r\n');
      expect(events, isEmpty);
      expect(parser.close(), isEmpty);
    });
  });

  group('Utf8StreamDecoder', () {
    test('reassembles multi-byte characters split across chunks', () {
      final decoder = Utf8StreamDecoder();
      final bytes = utf8.encode('你好，世界 👋');
      final out = StringBuffer();
      for (final b in bytes) {
        out.write(decoder.add(Uint8List.fromList([b])));
      }
      out.write(decoder.close());
      expect(out.toString(), '你好，世界 👋');
    });

    test('feeds the parser end-to-end from byte chunks', () {
      final decoder = Utf8StreamDecoder();
      final parser = SseChatParser();
      final bytes = utf8.encode(
        frame('answer_delta', '{"text":"中文内容"}', eol: '\n'),
      );
      final events = <ChatEvent>[];
      // Split after byte 3: lands inside the first multi-byte character.
      const splitAt = 3;
      events.addAll(parser.push(decoder.add(bytes.sublist(0, splitAt))));
      events.addAll(parser.push(decoder.add(bytes.sublist(splitAt))));
      expect(events, hasLength(1));
      expect((events.single as AnswerDelta).text, '中文内容');
    });

    test('empty and full-chunk adds behave', () {
      final decoder = Utf8StreamDecoder();
      expect(decoder.add(const <int>[]), '');
      expect(decoder.add(utf8.encode('abc')), 'abc');
      expect(decoder.close(), '');
    });
  });
}
