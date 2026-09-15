import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/sse_parser.dart';

/// Unit tests for the generic SSE frame parser — the wire-framing layer
/// extracted from `SseChatParser` so chat and the document-agent streams
/// share one discipline. JSON decoding / event typing stay with the typed
/// wrappers (see sse_parser_test.dart and agent_stream_client_test.dart).

/// Feeds [wire] through the parser in chunks of [size] to prove buffering.
List<SseFrame> parseChunked(
  String wire,
  SseFrameParser parser, {
  int size = 1,
}) {
  final frames = <SseFrame>[];
  for (var i = 0; i < wire.length; i += size) {
    frames.addAll(
      parser.push(
        wire.substring(i, i + size > wire.length ? wire.length : i + size),
      ),
    );
  }
  return frames;
}

void main() {
  group('SseFrameParser frames', () {
    test('completes one frame per blank line with event and joined data', () {
      const wire =
          'event: summary\r\n'
          'data: {"document_id":"d1"}\r\n'
          '\r\n';
      final frames = SseFrameParser().push(wire);
      expect(frames, hasLength(1));
      expect(frames.single.event, 'summary');
      expect(frames.single.data, '{"document_id":"d1"}');
    });

    test('multiple frames arrive in wire order', () {
      final frames = SseFrameParser().push(
        'event: a\r\ndata: 1\r\n\r\n'
        'event: b\r\ndata: 2\r\n\r\n',
      );
      expect(frames.map((f) => f.event), ['a', 'b']);
      expect(frames.map((f) => f.data), ['1', '2']);
    });

    test('multi-line data joins with newline', () {
      const wire =
          'event: a\r\n'
          'data: first\r\n'
          'data: second\r\n'
          '\r\n';
      final frames = SseFrameParser().push(wire);
      expect(frames.single.data, 'first\nsecond');
    });

    test('only the single optional space after the colon is stripped', () {
      // `data:  two` (two spaces) keeps the second space — only one is
      // stripped per the SSE spec; inner/trailing spaces stay verbatim.
      const wire = 'event:a\r\ndata:  spaced  value \r\n\r\n';
      final frames = SseFrameParser().push(wire);
      expect(frames.single.event, 'a');
      expect(frames.single.data, ' spaced  value ');
    });

    test('a frame without an event line completes with event null', () {
      const wire = 'data: {"x":1}\r\n\r\n';
      final frames = SseFrameParser().push(wire);
      expect(frames.single.event, isNull);
      expect(frames.single.data, '{"x":1}');
    });

    test('a field-less blank line completes an empty frame', () {
      const wire = '\r\n\r\n';
      final frames = SseFrameParser().push(wire);
      expect(frames, hasLength(2));
      expect(frames[0].event, isNull);
      expect(frames[0].data, isEmpty);
    });
  });

  group('SseFrameParser ignored lines', () {
    test('comment lines never enter a frame', () {
      final frames = SseFrameParser().push(
        ': ping - 2026-09-15T00:00:00Z\r\n\r\n'
        'event: a\r\ndata: 1\r\n\r\n',
      );
      expect(frames, hasLength(2)); // empty frame + the real one
      expect(frames[1].event, 'a');
    });

    test('id and retry fields are ignored', () {
      const wire = 'id: 42\r\nretry: 15000\r\nevent: a\r\ndata: 1\r\n\r\n';
      final frames = SseFrameParser().push(wire);
      expect(frames.single.event, 'a');
      expect(frames.single.data, '1');
    });

    test('unknown field names are ignored', () {
      const wire = 'x-custom: whatever\r\nevent: a\r\ndata: 1\r\n\r\n';
      final frames = SseFrameParser().push(wire);
      expect(frames.single.event, 'a');
      expect(frames.single.data, '1');
    });
  });

  group('SseFrameParser chunking', () {
    test('byte-at-a-time feeding yields the same frames', () {
      const wire = 'event: a\r\ndata: {"k":"值"}\r\n\r\n';
      final frames = parseChunked(wire, SseFrameParser(), size: 1);
      expect(frames, hasLength(1));
      expect(frames.single.event, 'a');
      expect(frames.single.data, '{"k":"值"}');
    });

    test('CRLF split across chunks is handled', () {
      final parser = SseFrameParser();
      final frames = [
        ...parser.push('event: a\r'),
        ...parser.push('\ndata: ok\r\n\r\n'),
      ];
      expect(frames.single.event, 'a');
      expect(frames.single.data, 'ok');
    });

    test('lone CR line endings are accepted', () {
      // The closing blank line is `\r\n`: a lone `\r` at the very end of
      // the buffer stays ambiguous by design (maybe `\r\n` split later).
      const wire = 'event: a\rdata: 1\r\r\n';
      final frames = SseFrameParser().push(wire);
      expect(frames.single.event, 'a');
      expect(frames.single.data, '1');
    });

    test('data split mid-JSON is buffered, not dropped', () {
      const wire = 'event: a\r\ndata: {"k":"spli', tail = 't"}\r\n\r\n';
      final parser = SseFrameParser();
      final frames = [...parser.push(wire), ...parser.push(tail)];
      expect(frames.single.data, '{"k":"split"}');
    });

    test('an incomplete trailing frame is discarded on close', () {
      final parser = SseFrameParser();
      expect(parser.push('event: a\r\ndata: lost\r\n'), isEmpty);
      expect(parser.close(), isEmpty);
    });
  });
}
