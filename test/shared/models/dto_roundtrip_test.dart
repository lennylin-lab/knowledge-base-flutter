import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/shared/models/agents_result.dart';
import 'package:knowledge_base_flutter/shared/models/agents_stream.dart';
import 'package:knowledge_base_flutter/shared/models/api_error.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:knowledge_base_flutter/shared/models/operation.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

/// Asserts `fromJson ∘ toJson` is the identity for [model].
void assertRoundTrip<T>(
  T model,
  Map<String, dynamic> Function(T) toJson,
  T Function(Map<String, dynamic>) fromJson,
) {
  expect(
    fromJson(toJson(model)),
    model,
    reason: '$T: fromJson(toJson(model)) must equal model',
  );
}

const documentReadJson = {
  'id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
  'title': '知识库设计笔记',
  'tags': ['flutter', 'backend'],
  'index_status': 'done',
  'created_at': '2026-08-31T10:00:00Z',
  'updated_at': '2026-08-31T12:30:00Z',
};

const searchHitJson = {
  'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
  'document_title': '知识库设计笔记',
  'document_tags': ['flutter'],
  'chunk_index': 2,
  'content': '混合检索使用 BM25 与向量的 RRF 融合',
  'score': 0.03125,
  'es_rank': 1,
  'vector_rank': null,
};

const draftContentJson = {
  'content': '---\ntitle: AI 续写\n---\n\n这是续写的正文。',
  'title': null,
};

const operationDetailJson = {
  'id': 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d',
  'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
  'base_document_version': '2026-08-31T12:30:00Z',
  'state': 'completed',
  'idempotency_key': 'create-op-1',
  'created_at': '2026-09-16T08:00:00Z',
  'updated_at': '2026-09-16T08:00:05Z',
  'draft': draftContentJson,
  'result': null,
  'error': null,
};

void main() {
  group('DocumentCreate / DocumentUpdate', () {
    test('DocumentCreate round-trips with nullable title', () {
      const model = DocumentCreate(
        content: '---\ntitle: 笔记\n---\n\n正文',
        title: null,
      );
      assertRoundTrip(model, (m) => m.toJson(), DocumentCreate.fromJson);
      expect(model.toJson()['content'], '---\ntitle: 笔记\n---\n\n正文');
    });

    test('DocumentCreate parses the wire shape', () {
      final model = DocumentCreate.fromJson({
        'content': '# hello',
        'title': 'Hello',
      });
      expect(model.title, 'Hello');
    });

    test('DocumentUpdate round-trips both-optional fields', () {
      const model = DocumentUpdate(content: '# updated', title: null);
      assertRoundTrip(model, (m) => m.toJson(), DocumentUpdate.fromJson);

      final fromWire = DocumentUpdate.fromJson({'title': '仅改标题'});
      expect(fromWire.content, isNull);
      expect(fromWire.title, '仅改标题');
    });
  });

  group('DocumentRead / Detail / Page', () {
    test('DocumentRead round-trips and maps every index_status value', () {
      for (final status in ['pending', 'done', 'failed']) {
        final model = DocumentRead.fromJson({...documentReadJson, 'index_status': status});
        assertRoundTrip(model, (m) => m.toJson(), DocumentRead.fromJson);
        expect(model.indexStatus.name, status);
        expect(model.toJson()['index_status'], status);
      }
    });

    test('unknown index_status falls back to failed, never throws', () {
      final model = DocumentRead.fromJson({...documentReadJson, 'index_status': 'quarantined'});
      expect(model.indexStatus, IndexStatus.failed);
    });

    test('DocumentReadDetail adds content and projects back to DocumentRead',
        () {
      final model = DocumentReadDetail.fromJson({
        ...documentReadJson,
        'content': '---\ntitle: 知识库设计笔记\n---\n\n## 内容',
      });
      expect(model.content, startsWith('---'));
      assertRoundTrip(model, (m) => m.toJson(), DocumentReadDetail.fromJson);

      final projected = model.toDocumentRead();
      expect(projected, DocumentRead.fromJson(documentReadJson));
      expect(projected.toJson().containsKey('content'), isFalse);
    });

    test('DocumentPage round-trips with a cursor', () {
      final model = DocumentPage.fromJson({
        'items': [documentReadJson],
        'next_cursor': 'eyJvIjpbIjIwMjYtMDgtMzFUMTI6MzA6MDBaIiwiMGI2ZGY5YSJd',
      });
      expect(model.items, hasLength(1));
      expect(model.nextCursor, isNotNull);
      assertRoundTrip(model, (m) => m.toJson(), DocumentPage.fromJson);
    });

    test('DocumentPage with next_cursor null means end of list', () {
      final model = DocumentPage.fromJson({
        'items': [documentReadJson],
        'next_cursor': null,
      });
      expect(model.nextCursor, isNull);
      assertRoundTrip(model, (m) => m.toJson(), DocumentPage.fromJson);
    });

    test('DocumentPage.toJson encodes nested items', () {
      final model = DocumentPage.fromJson({
        'items': [documentReadJson],
        'next_cursor': null,
      });
      final encoded = jsonEncode(model.toJson());
      expect(encoded, contains('"index_status":"done"'));
      expect(encoded, contains('"next_cursor":null'));
    });
  });

  group('Search', () {
    test('SearchHit round-trips with nullable vector_rank', () {
      final model = SearchHit.fromJson(searchHitJson);
      expect(model.esRank, 1);
      expect(model.vectorRank, isNull);
      expect(model.score, 0.03125);
      assertRoundTrip(model, (m) => m.toJson(), SearchHit.fromJson);
    });

    test('SearchHit tolerates a null es_rank (both legs nullable)', () {
      final model = SearchHit.fromJson({...searchHitJson, 'es_rank': null});
      expect(model.esRank, isNull);
    });

    test('SearchResponse round-trips and maps mode', () {
      final model = SearchResponse.fromJson({
        'mode': 'hybrid',
        'items': [searchHitJson, {...searchHitJson, 'es_rank': null, 'vector_rank': 4}],
      });
      expect(model.mode, SearchMode.hybrid);
      expect(model.items, hasLength(2));
      expect(model.items.last.vectorRank, 4);
      assertRoundTrip(model, (m) => m.toJson(), SearchResponse.fromJson);
    });

    test('unknown mode falls back to bm25', () {
      final model = SearchResponse.fromJson({'mode': 'dense', 'items': <Object>[]});
      expect(model.mode, SearchMode.bm25);
    });
  });

  group('Chat', () {
    test('ChatRequest defaults limit to 8 and round-trips', () {
      const model = ChatRequest(question: '知识库用了什么检索方案？');
      expect(model.limit, 8);
      expect(jsonEncode(model.toJson()),
          '{"question":"知识库用了什么检索方案？","limit":8}');
      assertRoundTrip(model, (m) => m.toJson(), ChatRequest.fromJson);

      final clamped = ChatRequest.fromJson({'question': 'q', 'limit': 20});
      expect(clamped.limit, 20);
    });

    test('RunStarted round-trips', () {
      final model = RunStarted.fromJson({
        'run_id': '22222222-2222-2222-2222-222222222222',
        'mode': 'hybrid',
      });
      expect(model.runId, '22222222-2222-2222-2222-222222222222');
      expect(model.mode, SearchMode.hybrid);
      assertRoundTrip(model, (m) => m.toJson(), RunStarted.fromJson);
    });

    test('SourcesEvent round-trips its hit list', () {
      final model = SourcesEvent.fromJson({
        'items': [searchHitJson],
      });
      expect(model.items.single.documentId, searchHitJson['document_id']);
      assertRoundTrip(model, (m) => m.toJson(), SourcesEvent.fromJson);
    });

    test('AnswerDelta round-trips text verbatim', () {
      final model = AnswerDelta.fromJson({'text': '答案 [1] 片段'});
      assertRoundTrip(model, (m) => m.toJson(), AnswerDelta.fromJson);
      expect(model.text, '答案 [1] 片段');
    });

    test('ChatDone round-trips outcome/tool_calls/latency_ms', () {
      final model = ChatDone.fromJson({
        'run_id': 'r-1',
        'outcome': 'success',
        'tool_calls': 3,
        'latency_ms': 2107.25,
      });
      expect(model.latencyMs, 2107.25);
      assertRoundTrip(model, (m) => m.toJson(), ChatDone.fromJson);
    });

    test('ChatErrorEvent round-trips code/message', () {
      final model = ChatErrorEvent.fromJson({
        'code': 'chat_unavailable',
        'message': 'No provider API key',
      });
      assertRoundTrip(model, (m) => m.toJson(), ChatErrorEvent.fromJson);
    });

    test('SSE payload classes are ChatEvents (sealed hierarchy)', () {
      const List<ChatEvent> events = [
        RunStarted(runId: 'r', mode: SearchMode.bm25),
        SourcesEvent(),
        ChatStatusEvent(phase: ChatStatusPhase.rewritingQuery),
        QueryRewrittenEvent(original: 'o', rewritten: 'r'),
        ToolCallStartedEvent(callId: 'c1', toolName: 'search_knowledge'),
        ToolCallFinishedEvent(
          callId: 'c1',
          toolName: 'search_knowledge',
          status: ChatToolStatus.failed,
        ),
        AnswerDelta(text: 't'),
        ChatDone(runId: 'r'),
        ChatErrorEvent(code: 'network_error', message: 'x'),
      ];
      // Pattern matching on the sealed type must be exhaustive.
      final names = events.map((e) => switch (e) {
            RunStarted() => 'run_started',
            SourcesEvent() => 'sources',
            ChatStatusEvent() => 'status',
            QueryRewrittenEvent() => 'query_rewritten',
            ToolCallStartedEvent() => 'tool_call_started',
            ToolCallFinishedEvent() => 'tool_call_finished',
            AnswerDelta() => 'answer_delta',
            ChatDone() => 'done',
            ChatErrorEvent() => 'error',
          });
      expect(names, [
        'run_started',
        'sources',
        'status',
        'query_rewritten',
        'tool_call_started',
        'tool_call_finished',
        'answer_delta',
        'done',
        'error',
      ]);
    });
  });

  group('Agents results (summary / associations)', () {
    test('SummaryResult round-trips with snake_case keys and double latency',
        () {
      final model = SummaryResult.fromJson({
        'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        'summary': '这份文档记录了知识库的整体设计思路。',
        'model': 'glm-4.7',
        'latency_ms': 1234.5,
      });
      expect(model.documentId, '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01');
      expect(model.latencyMs, 1234.5);
      assertRoundTrip(model, (m) => m.toJson(), SummaryResult.fromJson);

      // Wire keys must stay snake_case (round-trip to the backend).
      final encoded = jsonEncode(model.toJson());
      expect(encoded, contains('"document_id"'));
      expect(encoded, contains('"latency_ms":1234.5'));
    });

    test('SummaryResult decodes an integral latency_ms (1234) as double', () {
      final model = SummaryResult.fromJson({
        'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        'summary': 's',
        'model': 'glm-4.7',
        'latency_ms': 1234,
      });
      expect(model.latencyMs, 1234.0);
      expect(model.latencyMs, isA<double>());
    });

    test('AssociationItem round-trips every field', () {
      final model = AssociationItem.fromJson({
        'document_id': '0198c7a1-7b2a-7c1e-9f3a-2f4b5c6d7e8f',
        'title': 'Riverpod 迁移笔记',
        'tags': ['flutter', 'dart'],
        'reason': '共享状态管理的迁移经验。',
        'signal': 'tag_overlap',
      });
      expect(model.tags, ['flutter', 'dart']);
      assertRoundTrip(model, (m) => m.toJson(), AssociationItem.fromJson);
    });

    test('AssociationsResult round-trips nested items and allows empty', () {
      final model = AssociationsResult.fromJson({
        'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        'associations': [
          {
            'document_id': '0198c7a1-7b2a-7c1e-9f3a-2f4b5c6d7e8f',
            'title': 'Riverpod 迁移笔记',
            'tags': ['flutter'],
            'reason': '共享状态管理的迁移经验。',
            'signal': 'tag_overlap',
          },
        ],
        'model': 'glm-4.7',
        'latency_ms': 2345.0,
      });
      expect(model.associations.single, isA<AssociationItem>());
      expect(model.associations.single.documentId,
          '0198c7a1-7b2a-7c1e-9f3a-2f4b5c6d7e8f');
      assertRoundTrip(model, (m) => m.toJson(), AssociationsResult.fromJson);

      final empty = AssociationsResult.fromJson({
        'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        'associations': <Map<String, dynamic>>[],
        'model': 'glm-4.7',
        'latency_ms': 1.0,
      });
      expect(empty.associations, isEmpty);
      assertRoundTrip(empty, (m) => m.toJson(), AssociationsResult.fromJson);
    });
  });

  group('Operations', () {
    test('DraftContent round-trips with nullable title', () {
      final model = DraftContent.fromJson(draftContentJson);
      expect(model.title, isNull);
      assertRoundTrip(model, (m) => m.toJson(), DraftContent.fromJson);

      final titled = DraftContent.fromJson({'content': '正文', 'title': '显式标题'});
      expect(titled.title, '显式标题');
      assertRoundTrip(titled, (m) => m.toJson(), DraftContent.fromJson);
    });

    test('OperationCreate round-trips with snake_case wire keys', () {
      const model = OperationCreate(
        documentId: '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        baseDocumentVersion: '2026-08-31T12:30:00Z',
        draft: DraftContent(content: '# 草稿'),
        idempotencyKey: 'key-1',
      );
      assertRoundTrip(model, (m) => m.toJson(), OperationCreate.fromJson);

      final encoded = jsonEncode(model.toJson());
      expect(encoded, contains('"document_id"'));
      expect(encoded, contains('"base_document_version"'));
      expect(encoded, contains('"idempotency_key":"key-1"'));
    });

    test('OperationReadDetail maps every state value and round-trips', () {
      for (final state in OperationState.values) {
        final model = OperationReadDetail.fromJson({
          ...operationDetailJson,
          'state': state.name,
        });
        assertRoundTrip(model, (m) => m.toJson(), OperationReadDetail.fromJson);
        expect(model.state, state);
        expect(model.toJson()['state'], state.name);
      }
    });

    test('unknown operation state falls back to failed, never throws', () {
      final model = OperationReadDetail.fromJson({
        ...operationDetailJson,
        'state': 'cancelled',
      });
      expect(model.state, OperationState.failed);
      // The fallback serializes back to the known wire value.
      expect(model.toJson()['state'], 'failed');
    });

    test('OperationReadDetail round-trips the full payload', () {
      final model = OperationReadDetail.fromJson({
        ...operationDetailJson,
        'state': 'failed',
        'error': {'error_class': 'LLMProviderError'},
      });
      expect(model.draft?.content, startsWith('---'));
      expect(model.error, {'error_class': 'LLMProviderError'});
      assertRoundTrip(model, (m) => m.toJson(), OperationReadDetail.fromJson);
    });

    test('OperationReadDetail tolerates every nullable field being null', () {
      final model = OperationReadDetail.fromJson({
        'id': 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d',
        'document_id': null,
        'base_document_version': null,
        'state': 'running',
        'idempotency_key': null,
        'created_at': '2026-09-16T08:00:00Z',
        'updated_at': '2026-09-16T08:00:00Z',
        'draft': null,
        'result': null,
        'error': null,
      });
      expect(model.draft, isNull);
      expect(model.result, isNull);
      expect(model.error, isNull);
      assertRoundTrip(model, (m) => m.toJson(), OperationReadDetail.fromJson);
    });

    test('timestamps pass through verbatim (optimistic-concurrency '
        'sensitivity)', () {
      // Deliberately not the plain `Z` form: the server compares base
      // versions with exact equality, so the client must never re-parse or
      // reformat.
      const timestamp = '2026-09-16T08:00:00.123456+00:00';
      final model = OperationReadDetail.fromJson({
        ...operationDetailJson,
        'base_document_version': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      expect(model.baseDocumentVersion, timestamp);
      expect(model.createdAt, timestamp);
      expect(model.updatedAt, timestamp);
      final encoded = model.toJson();
      expect(encoded['base_document_version'], timestamp);
      expect(encoded['created_at'], timestamp);
      expect(encoded['updated_at'], timestamp);
    });

    test('revisionId surfaces result.revision_id once applied', () {
      final applied = OperationReadDetail.fromJson({
        ...operationDetailJson,
        'state': 'applied',
        'result': {'revision_id': '7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f'},
      });
      expect(applied.revisionId, '7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f');

      final pending = OperationReadDetail.fromJson(operationDetailJson);
      expect(pending.revisionId, isNull);
    });

    test('OperationTransition omits draft when unset, emits it when set', () {
      const withoutDraft = OperationTransition();
      expect(withoutDraft.toJson(), isEmpty);
      assertRoundTrip(
        withoutDraft,
        (m) => m.toJson(),
        OperationTransition.fromJson,
      );

      const withDraft = OperationTransition(
        draft: DraftContent(content: '修订后的草稿', title: '修订标题'),
      );
      expect(withDraft.toJson(), {
        'draft': {'content': '修订后的草稿', 'title': '修订标题'},
      });
      assertRoundTrip(
        withDraft,
        (m) => m.toJson(),
        OperationTransition.fromJson,
      );
    });

    test('ApplyRequest omits expectedBaseDocumentVersion when unset, '
        'emits it verbatim when set', () {
      const without = ApplyRequest();
      expect(without.toJson(), isEmpty);
      assertRoundTrip(without, (m) => m.toJson(), ApplyRequest.fromJson);

      const withVersion = ApplyRequest(
        expectedBaseDocumentVersion: '2026-09-16T08:00:00.123456+00:00',
      );
      expect(withVersion.toJson(), {
        'expected_base_document_version': '2026-09-16T08:00:00.123456+00:00',
      });
      assertRoundTrip(withVersion, (m) => m.toJson(), ApplyRequest.fromJson);
    });

    test('RevisionRead round-trips with nullable operation_id', () {
      final model = RevisionRead.fromJson({
        'id': '7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f',
        'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        'operation_id': 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d',
        'title': '知识库设计笔记',
        'tags': ['flutter', 'backend'],
        'created_at': '2026-09-16T08:01:00Z',
      });
      assertRoundTrip(model, (m) => m.toJson(), RevisionRead.fromJson);

      final orphan = RevisionRead.fromJson({
        ...model.toJson(),
        'operation_id': null,
      });
      expect(orphan.operationId, isNull);
      assertRoundTrip(orphan, (m) => m.toJson(), RevisionRead.fromJson);
    });

    test('DocumentInResult maps every index_status; unknown → failed', () {
      for (final status in ['pending', 'done', 'failed']) {
        final model = DocumentInResult.fromJson({
          'id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
          'title': '知识库设计笔记',
          'tags': ['flutter'],
          'index_status': status,
          'updated_at': '2026-09-16T08:01:00Z',
        });
        assertRoundTrip(model, (m) => m.toJson(), DocumentInResult.fromJson);
        expect(model.indexStatus.name, status);
      }

      final unknown = DocumentInResult.fromJson({
        'id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        'title': '知识库设计笔记',
        'tags': ['flutter'],
        'index_status': 'archived',
        'updated_at': '2026-09-16T08:01:00Z',
      });
      expect(unknown.indexStatus, IndexStatus.failed);
    });

    test('ApplyResult round-trips the nested operation/revision/document', () {
      final model = ApplyResult.fromJson({
        'operation': {
          ...operationDetailJson,
          'state': 'applied',
          'result': {'revision_id': '7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f'},
        },
        'revision': {
          'id': '7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f',
          'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
          'operation_id': 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d',
          'title': '知识库设计笔记',
          'tags': ['flutter', 'backend'],
          'created_at': '2026-09-16T08:01:00Z',
        },
        'document': {
          'id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
          'title': '知识库设计笔记',
          'tags': ['flutter', 'backend'],
          'index_status': 'pending',
          'updated_at': '2026-09-16T08:01:00Z',
        },
      });
      expect(model.operation.state, OperationState.applied);
      expect(model.revision.title, '知识库设计笔记');
      expect(model.document.indexStatus, IndexStatus.pending);
      assertRoundTrip(model, (m) => m.toJson(), ApplyResult.fromJson);
    });
  });

  group('Agent stream events', () {
    test('AgentRunStarted round-trips snake_case wire keys', () {
      final model = AgentRunStarted.fromJson({
        'run_id': '11111111-1111-1111-1111-111111111111',
        'kind': 'summary',
        'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
      });
      expect(model.runId, '11111111-1111-1111-1111-111111111111');
      expect(model.kind, 'summary');
      assertRoundTrip(model, (m) => m.toJson(), AgentRunStarted.fromJson);
      final encoded = jsonEncode(model.toJson());
      expect(encoded, contains('"run_id"'));
      expect(encoded, contains('"document_id"'));
    });

    test('SummaryProgress round-trips 1-based pass counters', () {
      final model = SummaryProgress.fromJson({
        'phase': 'map_pass',
        'pass_index': 1,
        'passes_total': 2,
      });
      expect(model.phase, 'map_pass');
      expect(model.passIndex, 1);
      expect(model.passesTotal, 2);
      assertRoundTrip(model, (m) => m.toJson(), SummaryProgress.fromJson);
      expect(jsonEncode(model.toJson()), contains('"pass_index":1'));
    });

    test('AgentErrorEvent round-trips code/message and omits a null status',
        () {
      final model = AgentErrorEvent.fromJson({
        'code': 'llm_provider_error',
        'message': 'provider boom',
      });
      assertRoundTrip(model, (m) => m.toJson(), AgentErrorEvent.fromJson);
      // The synthesized pre-stream failure carries its HTTP status out of
      // band (includeIfNull: false keeps it off the wire shape).
      const withStatus = AgentErrorEvent(
        code: 'not_found',
        message: 'gone',
        statusCode: 404,
      );
      expect(withStatus.toJson()['status_code'], 404);
      expect(jsonEncode(model.toJson()), isNot(contains('status_code')));
    });

    test('agent events are a sealed hierarchy (exhaustive matching)', () {
      const List<AgentStreamEvent> events = [
        AgentRunStarted(runId: 'r', kind: 'summary', documentId: 'd'),
        SummaryProgress(phase: 'map_pass', passIndex: 1, passesTotal: 2),
        AgentSummaryEvent(
          SummaryResult(
            documentId: 'd',
            summary: 's',
            model: 'm',
            latencyMs: 1,
          ),
        ),
        AgentAssociationsEvent(
          AssociationsResult(
            documentId: 'd',
            associations: [],
            model: 'm',
            latencyMs: 1,
          ),
        ),
        AgentDoneEvent(),
        AgentErrorEvent(code: 'network_error', message: 'x'),
      ];
      final names = events.map((e) => switch (e) {
            AgentRunStarted() => 'run_started',
            SummaryProgress() => 'summary_progress',
            AgentSummaryEvent() => 'summary',
            AgentAssociationsEvent() => 'associations',
            AgentDoneEvent() => 'done',
            AgentErrorEvent() => 'error',
          });
      expect(names, [
        'run_started',
        'summary_progress',
        'summary',
        'associations',
        'done',
        'error',
      ]);
    });
  });

  group('Error envelope', () {
    test('ApiErrorEnvelope round-trips the error contract shape', () {
      final model = ApiErrorEnvelope.fromJson({
        'error': {
          'code': 'validation_failed',
          'message': 'Request validation failed',
          'details': {
            'errors': [
              {'loc': ['body', 'limit'], 'msg': 'ensure this value is less than or equal to 20'},
            ],
          },
        },
      });
      expect(model.error.code, 'validation_failed');
      expect(model.error.details['errors'], isA<List<dynamic>>());
      assertRoundTrip(model, (m) => m.toJson(), ApiErrorEnvelope.fromJson);
    });

    test('ApiError tolerates a missing details map', () {
      final model = ApiError.fromJson({
        'code': 'not_found',
        'message': 'gone',
      });
      expect(model.details, isEmpty);
    });
  });
}
