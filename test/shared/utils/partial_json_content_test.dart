import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/utils/partial_json_content.dart';

/// Unit tests for the lenient partial-JSON extractor that decodes the live
/// draft `content` out of the accumulated `draft_delta` concatenation.
///
/// Core discipline mirrors the SSE parser tests (byte-split-at-every-
/// position over a realistic streamed draft): at every accumulation point
/// the extractor returns null or a valid prefix of the final markdown —
/// never scaffolding, never a non-prefix.
void main() {
  // A realistic streamed draft: `title` arrives FIRST (arbitrary key order),
  // the content is markdown with headings, bold, CJK, a `\uXXXX`-escaped
  // CJK run, escaped quotes forming a `"content"` decoy inside the value,
  // and JSON-escaped newlines.
  const finalContent =
      '# 星际启航\n\n'
      '这是**加粗**的正文，包含 CJK 转义：你好 "content" 伪键，以及换行。\n\n'
      '- 列表项一\n'
      '- 列表项二';
  // The raw JSON fragment — Dart source needs `\\` for one JSON backslash.
  const titleFirstArgs =
      '{"title": "星际旅行草稿", "content": '
      '"# 星际启航\\n\\n'
      '这是**加粗**的正文，包含 CJK 转义：\\u4f60\\u597d \\"content\\" 伪键，以及换行。\\n\\n'
      '- 列表项一\\n'
      '- 列表项二"}';

  // Content first, `title: null` last — the other realistic key order.
  const contentFirstArgs = '{"content": "第一段\\n\\n第二段", "title": null}';
  const contentFirstContent = '第一段\n\n第二段';

  group('complete and truncated input at every byte', () {
    test('title-first draft split at every byte: extracted is always a valid '
        'prefix of the final markdown', () {
      var previousLength = 0;
      var sawContent = false;
      for (var end = 0; end <= titleFirstArgs.length; end++) {
        final extracted = extractPartialContent(
          titleFirstArgs.substring(0, end),
        );
        if (extracted != null && extracted.isNotEmpty) {
          sawContent = true;
          // Append-only decode: the live text never shrinks or rewrites.
          expect(
            extracted.length,
            greaterThanOrEqualTo(previousLength),
            reason: 'split at $end shrunk the extraction',
          );
          previousLength = extracted.length;
        }
        expect(
          extracted == null || finalContent.startsWith(extracted),
          isTrue,
          reason: 'split at $end produced a non-prefix: $extracted',
        );
        // Raw JSON scaffolding never leaks into the extraction.
        if (extracted != null) {
          expect(extracted.contains('{"'), isFalse, reason: 'split at $end');
          expect(
            extracted.contains('"content":'),
            isFalse,
            reason: 'split at $end',
          );
        }
      }
      expect(
        sawContent,
        isTrue,
        reason: 'the content must become visible before the stream ends',
      );
      expect(extractPartialContent(titleFirstArgs), finalContent);
    });

    test('content-first draft (title: null) split at every byte: same '
        'prefix guarantee', () {
      for (var end = 0; end <= contentFirstArgs.length; end++) {
        final extracted = extractPartialContent(
          contentFirstArgs.substring(0, end),
        );
        expect(
          extracted == null || contentFirstContent.startsWith(extracted),
          isTrue,
          reason: 'split at $end produced a non-prefix: $extracted',
        );
      }
      expect(extractPartialContent(contentFirstArgs), contentFirstContent);
    });

    test(
      'complete content with trailing arguments returns the full decode',
      () {
        expect(
          extractPartialContent('{"content": "完整内容", "title": "标题"}'),
          '完整内容',
        );
        expect(extractPartialContent('{"title": "t", "content": "正文"}'), '正文');
      },
    );
  });

  group('escapes', () {
    test('all simple JSON escapes decode', () {
      expect(
        extractPartialContent(r'{"content": "a\"b\\c\/d\be\ff\ng\rh\ti"}'),
        'a"b\\c/d\be\ff\ng\rh\ti',
      );
    });

    test('a \\uXXXX escape split mid-sequence drops the incomplete tail', () {
      expect(extractPartialContent(r'{"content": "A\u4f60B"}'), 'A你B');
      expect(extractPartialContent(r'{"content": "A\u4f60"}'), 'A你');
      // Truncation at EOF: the partial escape is the tail — dropped.
      expect(extractPartialContent(r'{"content": "A\u4f'), 'A');
      expect(extractPartialContent(r'{"content": "A\u'), 'A');
      expect(extractPartialContent(r'{"content": "A\u4f60'), 'A你');
      // The same boundaries inside a longer streamed prefix.
      expect(extractPartialContent(r'{"content": "前\u4f60 后\u4f'), '前你 后');
    });

    test('a trailing lone backslash is dropped, earlier text kept', () {
      // A trailing `\"` would be an ESCAPED quote (string still open); the
      // lone-`\` truncation is built without a raw string (one that ends in
      // a backslash is not writable in Dart).
      expect(extractPartialContent('{"content": "abc\\'), 'abc');
      expect(extractPartialContent(r'{"content": "abc\\'), 'abc\\');
    });

    test('split surrogate pairs decode whole or are held back', () {
      expect(extractPartialContent(r'{"content": "\ud83d\ude00"}'), '😀');
      expect(extractPartialContent(r'{"content": "\ud83d\ude00'), '😀');
      // Lone high surrogate (pair not arrived yet) → dropped, still a prefix.
      expect(extractPartialContent(r'{"content": "\ud83d"}'), '');
      expect(extractPartialContent(r'{"content": "\ud83d'), '');
    });

    test('escapes inside keys decode too', () {
      expect(extractPartialContent(r'{"cont\u0065nt": "值"}'), '值');
    });
  });

  group('decoys and key order', () {
    test(
      'a "content" decoy inside a string value does not derail the scan',
      () {
        expect(
          extractPartialContent(
            r'{"note": "引用 \"content\" 伪键的位置", "content": "real"}',
          ),
          'real',
        );
      },
    );

    test(
      'a nested object carrying a content key is skipped (top-level only)',
      () {
        expect(
          extractPartialContent(
            r'{"meta": {"content": "decoy"}, "tags": ["content"], "content": "real"}',
          ),
          'real',
        );
      },
    );

    test('missing content key yields null at every truncation', () {
      expect(extractPartialContent(''), isNull);
      expect(extractPartialContent('   '), isNull);
      expect(extractPartialContent('{}'), isNull);
      expect(extractPartialContent('{'), isNull);
      expect(extractPartialContent('{"title": "只有标题"}'), isNull);
      expect(extractPartialContent('{"title"'), isNull);
      expect(extractPartialContent('{"cont'), isNull);
      expect(extractPartialContent('{"content"'), isNull);
      expect(extractPartialContent('{"content":'), isNull);
      expect(extractPartialContent('{"content": '), isNull);
    });

    test('a non-string content value yields null', () {
      expect(extractPartialContent('{"content": null}'), isNull);
      expect(extractPartialContent('{"content": 123}'), isNull);
      expect(extractPartialContent('{"content": {"deep": true}}'), isNull);
    });

    test('whitespace between tokens is tolerated', () {
      expect(extractPartialContent(' { "content" : "宽松" '), '宽松');
    });
  });

  group('malformed input never throws and yields null', () {
    const malformed = [
      'not-json',
      'null',
      '123',
      '[1, 2]',
      '{)',
      r'{"content" "abc"}', // missing colon
      r'{"content": "a\x"}', // invalid escape character
      r'{"content": "\uZZZZ"}', // non-hex \u digits
      r'{"content": "A\u4f"}', // a quote terminating a partial \uXXXX escape
      '{"content": }',
      '{"content": tru3e,',
      '{"a": 1]]]]',
    ];
    for (final input in malformed) {
      test('malformed: $input', () {
        expect(() => extractPartialContent(input), returnsNormally);
        expect(extractPartialContent(input), isNull);
      });
    }
  });
}
