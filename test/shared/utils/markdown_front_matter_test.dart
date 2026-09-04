import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/utils/markdown_front_matter.dart';

void main() {
  group('stripYamlFrontMatter', () {
    test('removes a standard front matter block', () {
      const input = '---\ntitle: 设计笔记\ntags: [flutter]\n---\n\n# 正文';
      expect(stripYamlFrontMatter(input), '# 正文');
    });

    test('returns content unchanged when there is no front matter', () {
      const input = '# 只有正文';
      expect(stripYamlFrontMatter(input), input);
    });

    test('returns content unchanged when the opening delimiter is not closed', () {
      const input = '---\ntitle: 新文档\ntags: []\n\n# 正文';
      expect(stripYamlFrontMatter(input), input);
    });

    test('returns empty string when content is only front matter', () {
      const input = '---\ntitle: 空文档\n---';
      expect(stripYamlFrontMatter(input), '');
    });
  });
}
