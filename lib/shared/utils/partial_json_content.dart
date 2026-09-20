/// Lenient partial-JSON extractor for streamed draft arguments.
///
/// The 「AI 续写」 draft stream (`draft_delta` events) carries raw fragments
/// of the model's tool-call-argument JSON, verbatim and in order — their sum
/// equals the final argument JSON exactly. The accumulated concatenation is
/// the transport-level truth (`WritingState.partialContent`); this pure
/// function decodes, at **render time**, the in-progress value of the
/// top-level `content` string so the live view can render real markdown
/// (like chat answers) instead of JSON scaffolding.
///
/// Lenient by design — it walks the prefix with escape/string-state tracking
/// (never a substring search: a `"content"` decoy inside a string value must
/// not confuse the scan) and tolerates:
/// - input truncated at **any** boundary (mid-key, mid-escape, mid-`\uXXXX`,
///   trailing lone `\`);
/// - all JSON escapes (`\"`, `\\`, `\/`, `\b`, `\f`, `\n`, `\r`, `\t`,
///   `\uXXXX`, incl. split surrogate pairs);
/// - arbitrary key order (`title` may come before `content`), missing keys,
///   and nested objects/arrays carrying `content` decoys (only the
///   top-level key is extracted);
/// - a **phantom leading `{}` fragment**: the provider can deliver an empty
///   argument object before the real one (older servers forward its
///   serialization verbatim), so the top level may close without a capture
///   while input remains — the scanner resynchronizes on the next top-level
///   `{` and keeps scanning (this is display-only hardening; the
///   concatenation contract makes such fragments illegal on current wire);
/// - the content string already closed (the complete decode is returned —
///   still partial relative to the whole draft).
///
/// Returns null when no content text has been reached yet (key absent or the
/// value not a string) and on malformed input — it never throws. O(prefix)
/// per call with no allocation beyond the decoded string.
library;

const int _tab = 0x09;
const int _lf = 0x0A;
const int _cr = 0x0D;
const int _space = 0x20;
const int _quote = 0x22;
const int _comma = 0x2C;
const int _colon = 0x3A;
const int _lbracket = 0x5B;
const int _backslash = 0x5C;
const int _rbracket = 0x5D;
const int _lbrace = 0x7B;
const int _rbrace = 0x7D;

/// What the scanner expects outside a string, per the JSON grammar.
enum _Phase {
  /// A key string (objects) — or the container's closing brace.
  key,

  /// The `:` between a key and its value.
  colon,

  /// A value token (string / literal / nested container).
  value,

  /// A completed value — the next `,` or container close.
  afterValue,
}

/// Decodes the in-progress top-level `content` string out of the accumulated
/// raw JSON [rawPrefix]. Null when nothing has been reached yet or the input
/// is malformed; never throws.
String? extractPartialContent(String rawPrefix) {
  final n = rawPrefix.length;

  // Open containers (true = object, false = array). Keys only matter at the
  // top level, but nested containers must be skipped with real depth and
  // string tracking so their braces/quotes stay invisible to the scan.
  final containers = <bool>[];
  var phase = _Phase.key;

  // True while the scanner sits BETWEEN top-level objects (before the first
  // one and after a phantom top-level close): only whitespace and a new
  // top-level `{` are legal there.
  var expectObject = true;

  var inString = false;
  var stringIsKey = false;
  var escaped = false; // a `\` was seen; the next char completes the escape.
  var unicodeLeft = 0; // hex digits still owed by a `\uXXXX` escape.
  var unicodeValue = 0;
  var keyBuffer = StringBuffer();
  var valueBuffer = StringBuffer();

  /// The key that closed last, at the top level, was `"content"`.
  var keyWasContent = false;

  /// The string being scanned is the top-level `content` value — decode it.
  var capture = false;

  /// Drops every per-object bit of scanner state after a top-level object
  /// closed without a capture and input remains — the next characters must
  /// open another top-level object ([expectObject]).
  void resyncAfterTopLevelClose() {
    expectObject = true;
    inString = false;
    stringIsKey = false;
    escaped = false;
    unicodeLeft = 0;
    keyWasContent = false;
    capture = false;
    keyBuffer = StringBuffer();
    valueBuffer = StringBuffer();
  }

  var i = 0;
  while (i < n) {
    final c = rawPrefix.codeUnitAt(i);

    if (inString) {
      if (unicodeLeft > 0) {
        final digit = _hexDigit(c);
        if (digit < 0) return null; // malformed: non-hex inside \uXXXX.
        unicodeValue = (unicodeValue << 4) | digit;
        unicodeLeft--;
        i++;
        if (unicodeLeft == 0) {
          if (stringIsKey) {
            keyBuffer.writeCharCode(unicodeValue);
          } else if (capture) {
            valueBuffer.writeCharCode(unicodeValue);
          }
        }
        continue;
      }
      if (escaped) {
        escaped = false;
        if (c == 0x75 /* u */ ) {
          unicodeLeft = 4;
          unicodeValue = 0;
          i++;
          continue;
        }
        final int decoded = switch (c) {
          _quote => _quote, // \"
          _backslash => _backslash, // \\
          0x2F => 0x2F, // \/
          0x62 => 0x08, // \b
          0x66 => 0x0C, // \f
          0x6E => _lf, // \n
          0x72 => _cr, // \r
          0x74 => _tab, // \t
          _ => -1, // malformed: invalid escape character.
        };
        if (decoded < 0) return null;
        if (stringIsKey) {
          keyBuffer.writeCharCode(decoded);
        } else if (capture) {
          valueBuffer.writeCharCode(decoded);
        }
        i++;
        continue;
      }
      if (c == _backslash) {
        escaped = true;
        i++;
        continue;
      }
      if (c == _quote) {
        // The string closes.
        inString = false;
        i++;
        if (stringIsKey) {
          stringIsKey = false;
          final key = keyBuffer.toString();
          keyBuffer = StringBuffer();
          keyWasContent = containers.length == 1 && key == 'content';
          phase = _Phase.colon;
        } else if (capture) {
          // The content string is fully closed — its decode is final, and
          // nothing later in the JSON can change it.
          return _finish(valueBuffer);
        } else {
          phase = _Phase.afterValue;
        }
        continue;
      }
      // Regular text.
      if (stringIsKey) {
        keyBuffer.writeCharCode(c);
      } else if (capture) {
        valueBuffer.writeCharCode(c);
      }
      i++;
      continue;
    }

    // Outside strings: whitespace between tokens.
    if (c == _space || c == _tab || c == _lf || c == _cr) {
      i++;
      continue;
    }

    // Between top-level objects: the next non-whitespace character must open
    // a fresh object (a phantom fragment was skipped, or this is the start).
    if (expectObject) {
      if (c != _lbrace) return null; // malformed: expected a top-level object.
      containers
        ..clear()
        ..add(true);
      phase = _Phase.key;
      expectObject = false;
      i++;
      continue;
    }

    switch (phase) {
      case _Phase.key:
        if (c == _quote) {
          inString = true;
          stringIsKey = true;
          escaped = false;
          unicodeLeft = 0;
          i++;
        } else if (c == _rbrace) {
          containers.removeLast();
          if (containers.isEmpty) {
            // Top-level object closed with no content captured — resync and
            // let the loop head demand the next top-level object.
            resyncAfterTopLevelClose();
            i++;
            continue;
          }
          phase = _Phase.afterValue;
          i++;
        } else {
          return null; // malformed: expected a key.
        }
      case _Phase.colon:
        if (c == _colon) {
          phase = _Phase.value;
          i++;
        } else {
          return null; // malformed: expected ':'.
        }
      case _Phase.value:
        if (c == _quote) {
          inString = true;
          stringIsKey = false;
          escaped = false;
          unicodeLeft = 0;
          capture = keyWasContent && containers.length == 1;
          if (capture) valueBuffer = StringBuffer();
          i++;
        } else if (c == _lbrace || c == _lbracket) {
          // Nested container — its keys/values are decoys; skip with depth.
          containers.add(c == _lbrace);
          phase = c == _lbrace ? _Phase.key : _Phase.value;
          i++;
        } else if (c == _rbrace || c == _rbracket) {
          // Empty container.
          containers.removeLast();
          if (containers.isEmpty) {
            resyncAfterTopLevelClose();
            i++;
            continue;
          }
          phase = _Phase.afterValue;
          i++;
        } else if (_isLiteralStart(c)) {
          // Number / true / false / null — skip to the delimiter. The
          // content value must be a string; literals yield no capture.
          i++;
          while (i < n) {
            final lc = rawPrefix.codeUnitAt(i);
            if (lc == _comma ||
                lc == _rbrace ||
                lc == _rbracket ||
                lc == _space ||
                lc == _tab ||
                lc == _lf ||
                lc == _cr) {
              break;
            }
            i++;
          }
          phase = _Phase.afterValue;
        } else {
          return null; // malformed value start.
        }
      case _Phase.afterValue:
        if (c == _comma) {
          phase = containers.last ? _Phase.key : _Phase.value;
          i++;
        } else if (c == _rbrace || c == _rbracket) {
          containers.removeLast();
          if (containers.isEmpty) {
            // Top-level object closed with no content captured — a phantom
            // fragment; resync for a possible next top-level object.
            resyncAfterTopLevelClose();
            i++;
            continue;
          }
          phase = _Phase.afterValue;
          i++;
        } else {
          return null; // malformed: expected ',' or a closing brace.
        }
    }
  }

  // Truncated input: only an open, captured content string yields text. A
  // dangling `\` or partial `\uXXXX` was never written, so the buffer
  // already excludes the incomplete tail escape.
  if (inString && !stringIsKey && capture) return _finish(valueBuffer);
  return null;
}

/// Returns the decoded [buffer] with a trailing lone high surrogate dropped
/// (the first half of a split `\uD83D\uDE00`-style pair is an incomplete
/// tail exactly like a partial `\uXXXX` — dropping it keeps the result a
/// strict prefix of the final text).
String _finish(StringBuffer buffer) {
  final s = buffer.toString();
  if (s.isEmpty) return s;
  final last = s.codeUnitAt(s.length - 1);
  if (last >= 0xD800 && last <= 0xDBFF) {
    return s.substring(0, s.length - 1);
  }
  return s;
}

int _hexDigit(int c) {
  if (c >= 0x30 && c <= 0x39) return c - 0x30; // 0-9
  if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10; // a-f
  if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10; // A-F
  return -1;
}

bool _isLiteralStart(int c) =>
    (c >= 0x30 && c <= 0x39) || // digits
    c == 0x2D || // -
    c == 0x74 || // t (true)
    c == 0x66 || // f (false)
    c == 0x6E; // n (null)
