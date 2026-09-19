import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/utils/markdown_tasks.dart';

void main() {
  group('toggleTaskListItem', () {
    test('checks the first unchecked item', () {
      const source = '- [ ] 甲\n- [ ] 乙\n';
      expect(toggleTaskListItem(source, 0), '- [x] 甲\n- [ ] 乙\n');
    });

    test('unchecks a checked item (round trip)', () {
      const source = '- [x] 甲\n';
      expect(toggleTaskListItem(source, 0), '- [ ] 甲\n');
    });

    test('unchecking an uppercase [X] writes a plain [ ]', () {
      const source = '1. [X] 大写\n';
      expect(toggleTaskListItem(source, 0), '1. [ ] 大写\n');
    });

    test('index follows document order across items', () {
      const source = '- [ ] 一\n- [x] 二\n- [ ] 三\n';
      expect(toggleTaskListItem(source, 1), '- [ ] 一\n- [ ] 二\n- [ ] 三\n');
      expect(toggleTaskListItem(source, 2), '- [ ] 一\n- [x] 二\n- [x] 三\n');
    });

    test('nested list items keep their own index', () {
      const source = '- [ ] 父\n  - [ ] 子\n- [ ] 兄弟\n';
      expect(
        toggleTaskListItem(source, 1),
        '- [ ] 父\n  - [x] 子\n- [ ] 兄弟\n',
      );
    });

    test('indented continuation keeps the marker column', () {
      const source = '- [ ] 甲\n\n  段落说明\n';
      expect(toggleTaskListItem(source, 0), '- [x] 甲\n\n  段落说明\n');
    });

    test('skips fenced code blocks when counting', () {
      const source = '```text\n- [ ] 假任务\n```\n- [ ] 真任务\n';
      expect(toggleTaskListItem(source, 0), '```text\n- [ ] 假任务\n```\n- [x] 真任务\n');
    });

    test('skips callout bodies when counting', () {
      const source = '> [!note] 提示\n> - [ ] callout 任务\n\n- [ ] 正文任务\n';
      expect(
        toggleTaskListItem(source, 0),
        '> [!note] 提示\n> - [ ] callout 任务\n\n- [x] 正文任务\n',
      );
    });

    test('toggles quoted task lines via the quote layer', () {
      const source = '> - [ ] 引用任务\n';
      expect(toggleTaskListItem(source, 0), '> - [x] 引用任务\n');
    });

    test('skips front matter when counting', () {
      const source = '---\ntitle: 清单\n---\n\n- [ ] 正文任务\n';
      expect(
        toggleTaskListItem(source, 0),
        '---\ntitle: 清单\n---\n\n- [x] 正文任务\n',
      );
    });

    test('returns null when the index is out of range', () {
      const source = '- [ ] 唯一\n';
      expect(toggleTaskListItem(source, 1), isNull);
    });

    test('returns null without any task markers', () {
      expect(toggleTaskListItem('- 普通\n正文\n', 0), isNull);
    });
  });
}
