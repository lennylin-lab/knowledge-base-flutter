import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/features/documents/edit_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  EditDraft draft(
    String scopeKey, {
    String content = '# 正文',
    String titleOverride = '',
    String? baselineContentHash = 'hash-1',
    String? baselineContent,
  }) {
    return EditDraft(
      scopeKey: scopeKey,
      content: content,
      titleOverride: titleOverride,
      baselineContentHash: baselineContentHash,
      baselineContent: baselineContent,
      savedAt: DateTime.parse('2026-09-19T08:00:00.000'),
    );
  }

  group('EditDraftStore', () {
    test('save → load round-trips the draft', () async {
      final store = EditDraftStore();
      await store.save(
        draft(
          'doc-1',
          content: '---\ntitle: 草稿\n---\n\n未保存内容',
          titleOverride: '显式标题',
          baselineContentHash: 'abc123',
          baselineContent: '---\ntitle: 旧标题\n---\n\n旧正文',
        ),
      );

      final loaded = await store.load('doc-1');
      expect(loaded, isNotNull);
      expect(loaded!.content, '---\ntitle: 草稿\n---\n\n未保存内容');
      expect(loaded.titleOverride, '显式标题');
      expect(loaded.baselineContentHash, 'abc123');
      expect(loaded.baselineContent, '---\ntitle: 旧标题\n---\n\n旧正文');
      expect(loaded.savedAt, DateTime.parse('2026-09-19T08:00:00.000'));
    });

    test('persists under the documents.edit_draft.<scopeKey> key style', () async {
      final store = EditDraftStore();
      await store.save(draft('doc-1'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), contains('documents.edit_draft.doc-1'));
    });

    test('round-trips null baseline fields (unknown-baseline draft)', () async {
      final store = EditDraftStore();
      await store.save(draft('doc-1', baselineContentHash: null));

      final loaded = await store.load('doc-1');
      expect(loaded, isNotNull);
      expect(loaded!.baselineContentHash, isNull);
      expect(loaded.baselineContent, isNull);
    });

    test('old draft JSON without baselineContent decodes to null '
        '(conservative restore path)', () async {
      // Drafts persisted before baselineContent existed lack the key; the
      // decode must tolerate it and restore falls through to the conflict
      // dialog.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'documents.edit_draft.doc-1',
        jsonEncode(<String, dynamic>{
          'scopeKey': 'doc-1',
          'content': '# 正文',
          'titleOverride': '',
          'baselineContentHash': 'hash-1',
          'savedAt': '2026-09-19T08:00:00.000',
        }),
      );

      final loaded = await EditDraftStore().load('doc-1');
      expect(loaded, isNotNull);
      expect(loaded!.baselineContentHash, 'hash-1');
      expect(loaded.baselineContent, isNull);
    });

    test('load returns null when no draft exists', () async {
      final store = EditDraftStore();
      expect(await store.load('missing'), isNull);
    });

    test('clear removes the persisted draft', () async {
      final store = EditDraftStore();
      await store.save(draft('doc-1'));
      await store.clear('doc-1');

      expect(await store.load('doc-1'), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isNot(contains('documents.edit_draft.doc-1')));
    });

    test('skips persisting content beyond 1 MB (web localStorage guard)',
        () async {
      final store = EditDraftStore();
      final oversized = draft('doc-1', content: 'a' * (1024 * 1024 + 1));
      await store.save(oversized);

      expect(await store.load('doc-1'), isNull);
    });

    test('still persists content at exactly 1 MB when baseline is absent',
        () async {
      final store = EditDraftStore();
      final atLimit = draft('doc-1', content: 'a' * (1024 * 1024));
      await store.save(atLimit);

      expect(await store.load('doc-1'), atLimit);
    });

    test('size budget covers content + baselineContent together: at 1 MB '
        'total it persists', () async {
      final store = EditDraftStore();
      final half = 512 * 1024;
      final atLimit = draft(
        'doc-1',
        content: 'a' * half,
        baselineContent: 'b' * half,
      );
      await store.save(atLimit);

      expect(await store.load('doc-1'), atLimit);
    });

    test('size budget covers content + baselineContent together: beyond '
        '1 MB total it skips', () async {
      final store = EditDraftStore();
      final half = 512 * 1024;
      final overLimit = draft(
        'doc-1',
        content: 'a' * half,
        baselineContent: 'b' * (half + 1),
      );
      await store.save(overLimit);

      expect(await store.load('doc-1'), isNull);
    });

    test('storage failures never throw (best-effort safety net)', () async {
      final store = EditDraftStore(
        prefsLoader: () async => throw Exception('storage broken'),
      );

      // None of these may propagate — the editor keeps working in memory.
      await expectLater(store.save(draft('doc-1')), completes);
      await expectLater(store.load('doc-1'), completion(isNull));
      await expectLater(store.clear('doc-1'), completes);
    });

    test('undecodable persisted values load as null instead of throwing',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('documents.edit_draft.doc-1', 'not-json{');

      final store = EditDraftStore();
      expect(await store.load('doc-1'), isNull);
    });
  });
}
