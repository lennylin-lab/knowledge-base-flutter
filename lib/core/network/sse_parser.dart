import 'dart:convert';

import '../../shared/models/chat.dart';

/// Incremental UTF-8 → text decoder shared by both SSE transports.
///
/// Multi-byte sequences split across chunk boundaries are held internally by
/// the chunked decoder, so callers can feed arbitrary byte slices.
class Utf8StreamDecoder {
  final _buffer = _StringSink();

  late final ByteConversionSink _sink =
      const Utf8Decoder(allowMalformed: true).startChunkedConversion(_buffer);

  /// Feed raw bytes; returns the text they completed (possibly empty).
  String add(List<int> bytes) {
    _sink.add(bytes);
    return _take();
  }

  /// Flush trailing decoder state (e.g. a lone truncated sequence, which
  /// `allowMalformed` renders as U+FFFD).
  String close() {
    _sink.close();
    return _take();
  }

  String _take() {
    if (_buffer.isEmpty) return '';
    final text = _buffer.toString();
    _buffer.clear();
    return text;
  }
}

/// [StringBuffer] is a [StringSink], not a [Sink<String>] — this adapter is
/// what the chunked UTF-8 decoder requires.
class _StringSink implements Sink<String> {
  final _buffer = StringBuffer();

  @override
  void add(String data) => _buffer.write(data);

  @override
  void close() {}

  bool get isEmpty => _buffer.isEmpty;

  @override
  String toString() => _buffer.toString();

  void clear() {
    _buffer.clear();
  }
}

/// Pure incremental parser for the chat SSE wire format — no IO, fully unit
/// testable. Feed decoded text chunks with [push]; the returned list holds
/// the events those chunks completed.
///
/// Implemented rules:
/// - events are terminated by a blank line; `\n`, `\r\n` and lone `\r` all
///   count as line terminators, even when the pair is split across chunks;
/// - `event:` / `data:` field lines; multi-line `data` joins with `\n`;
///   the single optional space after `:` is stripped;
/// - comments (`:`-prefixed lines), `id:` and `retry:` are ignored;
/// - unknown event names (e.g. keep-alive `ping` frames) are ignored;
/// - frames with non-JSON `data` are ignored, never thrown;
/// - everything after a terminal `done`/`error` event is ignored;
/// - [close] discards an unterminated trailing frame, per the SSE spec.
class SseChatParser {
  String _buffer = '';
  String? _eventName;
  final _dataLines = <String>[];
  bool _terminated = false;

  /// Whether a terminal `done`/`error` event has already been emitted.
  bool get isTerminated => _terminated;

  /// Feed one decoded text chunk; returns the events it completed.
  List<ChatEvent> push(String chunk) {
    if (chunk.isEmpty) return const [];
    _buffer += chunk;
    return _drain();
  }

  /// Signal end of stream. An unterminated trailing frame is discarded.
  List<ChatEvent> close() => const [];

  List<ChatEvent> _drain() {
    final events = <ChatEvent>[];
    while (true) {
      final line = _nextLine();
      if (line == null) break;
      if (line.isEmpty) {
        final event = _dispatch();
        if (event != null) events.add(event);
        continue;
      }
      if (line.startsWith(':')) continue; // comment (keep-alive ping)
      _consumeField(line);
    }
    return events;
  }

  /// Extracts the first complete line from [_buffer], or `null` while no
  /// terminator is buffered.
  ///
  /// A `\r` at the very end of the buffer is ambiguous (lone terminator vs.
  /// first half of a `\r\n` split across chunks): wait for more input. This
  /// is lossless — an event always needs its closing blank line anyway.
  String? _nextLine() {
    final nl = _buffer.indexOf('\n');
    final cr = _buffer.indexOf('\r');
    if (nl >= 0 && (cr < 0 || nl < cr)) {
      final line = _buffer.substring(0, nl);
      _buffer = _buffer.substring(nl + 1);
      return line;
    }
    if (cr >= 0) {
      if (nl < 0 && cr == _buffer.length - 1) return null; // maybe `\r\n`
      var consumed = cr + 1;
      if (cr + 1 < _buffer.length && _buffer.codeUnitAt(cr + 1) == 0x0A) {
        consumed += 1; // swallow the `\n` of a `\r\n` pair
      }
      final line = _buffer.substring(0, cr);
      _buffer = _buffer.substring(consumed);
      return line;
    }
    return null;
  }

  void _consumeField(String line) {
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        _eventName = value;
      case 'data':
        _dataLines.add(value);
      default:
        break; // `id` / `retry` / unknown — ignored
    }
  }

  /// Emits the accumulated frame as a [ChatEvent], or `null` when the frame
  /// is ignorable (post-terminal, unnamed, non-JSON, unknown event).
  ChatEvent? _dispatch() {
    final name = _eventName;
    _eventName = null;
    final data = _dataLines.join('\n');
    _dataLines.clear();
    if (_terminated || name == null || data.isEmpty) return null;

    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } on FormatException {
      return null; // tolerate garbage frames, keep the stream alive
    }

    switch (name) {
      case 'run_started':
        return RunStarted.fromJson(json);
      case 'sources':
        return SourcesEvent.fromJson(json);
      case 'answer_delta':
        return AnswerDelta.fromJson(json);
      case 'done':
        _terminated = true;
        return ChatDone.fromJson(json);
      case 'error':
        _terminated = true;
        return ChatErrorEvent.fromJson(json);
      default:
        return null; // unknown event (keep-alive, future events)
    }
  }
}
