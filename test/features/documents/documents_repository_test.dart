import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/agent_stream_client.dart';
import 'package:knowledge_base_flutter/core/network/api_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/network/chat_transport.dart';
import 'package:knowledge_base_flutter/features/documents/documents_repository.dart';
import 'package:knowledge_base_flutter/shared/models/agents_stream.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

/// One canned HTTP response drained from the adapter queue per request.
class _CannedResponse {
  const _CannedResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

/// A request as seen on the wire (method / path / query / decoded body).
class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.path,
    required this.url,
    required this.queryParameters,
    required this.body,
  });

  final String method;
  final String path;

  /// Fully encoded URL — pins the wire format (e.g. repeated `tag=` keys).
  final String url;
  final Map<String, dynamic> queryParameters;
  final Object? body;

  @override
  String toString() => '$method $path $queryParameters ${body ?? ''}';
}

/// Queue-based adapter: records every request (reading the actual encoded
/// body stream) and answers with the next canned response — the same
/// pattern as test/core/network/api_error_test.dart, extended to capture
/// requests.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(List<_CannedResponse> responses)
    : _responses = List<_CannedResponse>.of(responses);

  final List<_CannedResponse> _responses;
  final List<_RecordedRequest> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in requestStream) {
        builder.add(chunk);
      }
      final text = utf8.decode(builder.takeBytes());
      if (text.isNotEmpty) body = jsonDecode(text);
    }
    requests.add(
      _RecordedRequest(
        method: options.method,
        path: options.path,
        url: options.uri.toString(),
        queryParameters: Map<String, dynamic>.from(options.queryParameters),
        body: body,
      ),
    );
    if (_responses.isEmpty) {
      throw StateError('no canned response left for ${options.uri}');
    }
    final next = _responses.removeAt(0);
    return ResponseBody(
      Stream.fromIterable([utf8.encode(next.body)]),
      next.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Wire-shaped fixtures aligned with the backend OpenAPI schema.
const documentReadJson = {
  'id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
  'title': '知识库设计笔记',
  'tags': ['flutter', 'backend'],
  'index_status': 'pending',
  'created_at': '2026-08-31T10:00:00Z',
  'updated_at': '2026-08-31T12:30:00Z',
};

// Non-const: the spread re-assigns `index_status`, which a const map
// literal rejects as duplicate keys.
final documentDetailJson = {
  ...documentReadJson,
  'index_status': 'done',
  'content': '---\ntitle: 知识库设计笔记\n---\n\n## 内容',
};

/// Wire-shaped fixtures for the LLM sub-endpoints (backend
/// `src/app/schemas/agents.py`): every field required, none nullable.
const summaryResultJson = {
  'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
  'summary': '这份文档记录了知识库的整体设计思路。',
  'model': 'glm-4.7',
  'latency_ms': 1234.5,
};

const associationsResultJson = {
  'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
  'associations': [
    {
      'document_id': '0198c7a1-7b2a-7c1e-9f3a-2f4b5c6d7e8f',
      'title': 'Riverpod 迁移笔记',
      'tags': ['flutter', 'dart'],
      'reason': '共享状态管理的迁移经验。',
      'signal': 'tag_overlap',
    },
  ],
  'model': 'glm-4.7',
  'latency_ms': 2345.0,
};

(DocumentsRepository, _RecordingAdapter) _makeRepo(
  List<_CannedResponse> responses,
) {
  final adapter = _RecordingAdapter(responses);
  final dio = Dio()..httpClientAdapter = adapter;
  final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
  return (DocumentsRepository(client), adapter);
}

/// Scripted byte-stream transport for the agent SSE endpoints: `open`
/// records the request and hands out a controller-driven stream so each
/// test drives chunks, errors and end-of-stream explicitly (the same
/// pattern as test/core/network/sse_client_test.dart).
class _ScriptedTransport implements ChatTransport {
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

  void addWire(String wire) =>
      _controller.add(Uint8List.fromList(utf8.encode(wire)));

  void closeStream() => _controller.close();
}

(DocumentsRepository, _ScriptedTransport) _makeAgentRepo() {
  final dio = Dio();
  final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
  final transport = _ScriptedTransport();
  final repo = DocumentsRepository(
    client,
    agentStream: AgentStreamClient(
      baseUrl: client.baseUrl,
      transport: transport,
    ),
  );
  return (repo, transport);
}

/// One SSE frame with `\r\n` line endings, as sse-starlette emits them.
String sseFrame(String event, String data) =>
    'event: $event\r\n'
    'data: $data\r\n'
    '\r\n';

void main() {
  group('list', () {
    test('sends cursor/limit/tag exactly and parses the page', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(
          200,
          jsonEncode({
            'items': [documentReadJson],
            'next_cursor': 'cursor-2',
          }),
        ),
      ]);

      final page = await repo.list(
        cursor: 'cursor-1',
        limit: 5,
        tags: ['flutter'],
      );

      expect(page.items, hasLength(1));
      expect(page.items.single.title, '知识库设计笔记');
      expect(page.items.single.indexStatus, IndexStatus.pending);
      expect(page.items.single.tags, ['flutter', 'backend']);
      expect(page.nextCursor, 'cursor-2');

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/v1/documents');
      expect(request.queryParameters, {
        'cursor': 'cursor-1',
        'limit': 5,
        'tag': ['flutter'],
      });
    });

    test('sends several tags as repeated tag params (backend ANDs them)', () async {
      final (repo, adapter) = _makeRepo([
        const _CannedResponse(200, '{"items": [], "next_cursor": null}'),
      ]);

      await repo.list(tags: ['flutter', 'dart']);

      final request = adapter.requests.single;
      expect(request.queryParameters, {
        'limit': 20,
        'tag': ['flutter', 'dart'],
      });
      // Wire format: one `tag=` key per selected tag (FastAPI list[str]).
      // baseUrl is merged later in the dio pipeline — uri stays path-only.
      expect(
        request.url,
        '/api/v1/documents?limit=20&tag=flutter&tag=dart',
      );
    });

    test('first page omits cursor and tag; default limit is 20', () async {
      final (repo, adapter) = _makeRepo([
        const _CannedResponse(200, '{"items": [], "next_cursor": null}'),
      ]);

      final page = await repo.list();

      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull); // end of list, not an error
      expect(
        adapter.requests.single.queryParameters,
        {'limit': 20},
        reason: 'cursor/tags must be absent (not sent as null/empty)',
      );
    });

    test('clamps limit into the 1–100 API range', () async {
      final (repo, adapter) = _makeRepo([
        const _CannedResponse(200, '{"items": [], "next_cursor": null}'),
        const _CannedResponse(200, '{"items": [], "next_cursor": null}'),
      ]);

      await repo.list(limit: 0);
      await repo.list(limit: 500);

      expect(adapter.requests[0].queryParameters['limit'], 1);
      expect(adapter.requests[1].queryParameters['limit'], 100);
    });
  });

  group('get', () {
    test('fetches /documents/{id} and parses the detail incl. content', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(documentDetailJson)),
      ]);

      final detail = await repo.get('0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01');

      expect(detail.content, startsWith('---'));
      expect(detail.indexStatus, IndexStatus.done);
      expect(detail.toDocumentRead().id, detail.id);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(
        request.path,
        '/api/v1/documents/0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
      );
    });
  });

  group('create', () {
    test('posts the full markdown payload and parses the created item', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(documentReadJson)),
      ]);

      final created = await repo.create(
        const DocumentCreate(content: '---\ntitle: 新笔记\n---\n\n正文'),
      );

      expect(created.id, documentReadJson['id']);
      expect(created.indexStatus, IndexStatus.pending);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/v1/documents');
      // Generated `toJson` keeps an explicit `title: null` — equivalent to
      // "unset" for the backend's Optional fields.
      expect(request.body, {
        'content': '---\ntitle: 新笔记\n---\n\n正文',
        'title': null,
      });
    });
  });

  group('update', () {
    test('patches with the minimal body (only content set)', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(documentReadJson)),
      ]);

      await repo.update(
        '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        const DocumentUpdate(content: '更新后的正文'),
      );

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(
        request.path,
        '/api/v1/documents/0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
      );
      expect(request.body, {
        'content': '更新后的正文',
        'title': null,
      });
    });

    test('sends the title override when given', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(documentReadJson)),
      ]);

      await repo.update(
        '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        const DocumentUpdate(title: '显式标题'),
      );

      expect(adapter.requests.single.body, {
        'content': null,
        'title': '显式标题',
      });
    });
  });

  group('delete', () {
    test('issues DELETE and accepts the 204 empty body', () async {
      final (repo, adapter) = _makeRepo([const _CannedResponse(204, '')]);

      await expectLater(
        repo.delete('0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01'),
        completes,
      );

      final request = adapter.requests.single;
      expect(request.method, 'DELETE');
      expect(
        request.path,
        '/api/v1/documents/0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
      );
      expect(request.body, isNull);
    });
  });

  group('summarize (agent SSE stream)', () {
    const docId = '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01';

    test(
      'posts no body to /documents/{id}/summary and folds the stream into '
      'SummaryResult, reporting progress in wire order',
      () async {
        final (repo, transport) = _makeAgentRepo();
        final progress = <SummaryProgress>[];

        final future = repo.summarize(docId, onProgress: progress.add);
        // Let open() resolve before driving the scripted stream.
        await Future<void>.delayed(Duration.zero);
        transport.addWire(
          sseFrame(
            'run_started',
            '{"run_id":"r-1","kind":"summary","document_id":"$docId"}',
          ) +
              sseFrame(
                'summary_progress',
                '{"phase":"map_pass","pass_index":1,"passes_total":2}',
              ) +
              sseFrame(
                'summary_progress',
                '{"phase":"map_pass","pass_index":2,"passes_total":2}',
              ) +
              sseFrame(
                'summary_progress',
                '{"phase":"reduce_pass","pass_index":2,"passes_total":2}',
              ) +
              sseFrame('summary', jsonEncode(summaryResultJson)) +
              sseFrame(
                'done',
                '{"run_id":"r-1","outcome":"success","latency_ms":1250.0}',
              ),
        );
        transport.closeStream();

        final result = await future;
        expect(result.documentId, summaryResultJson['document_id']);
        expect(result.summary, summaryResultJson['summary']);
        expect(result.model, 'glm-4.7');
        expect(result.latencyMs, 1234.5);

        expect(
          progress.map((p) => '${p.phase}:${p.passIndex}/${p.passesTotal}'),
          ['map_pass:1/2', 'map_pass:2/2', 'reduce_pass:2/2'],
        );

        expect(
          transport.lastUri.toString(),
          'http://localhost:8000/api/v1/documents/$docId/summary',
        );
        expect(
          transport.lastBody,
          isNull,
          reason: 'the server handler takes only the path UUID',
        );
      },
    );

    test(
      'a terminal error event surfaces as ApiException(code, message)',
      () async {
        final (repo, transport) = _makeAgentRepo();

        final future = repo.summarize(docId);
        await Future<void>.delayed(Duration.zero);
        transport.addWire(
          sseFrame(
            'run_started',
            '{"run_id":"r-1","kind":"summary","document_id":"$docId"}',
          ) +
              sseFrame(
                'error',
                '{"code":"llm_provider_error","message":"provider exploded"}',
              ),
        );
        transport.closeStream();

        await expectLater(
          future,
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', 'llm_provider_error')
                .having((e) => e.message, 'message', 'provider exploded'),
          ),
        );
      },
    );

    test('503 chat_unavailable surfaces as ApiException', () async {
      final (repo, transport) = _makeAgentRepo();

      final future = repo.summarize(docId);
      await Future<void>.delayed(Duration.zero);
      transport.addWire(
        sseFrame(
          'error',
          '{"code":"chat_unavailable",'
              '"message":"LLM provider is not configured"}',
        ),
      );
      transport.closeStream();

      await expectLater(
        future,
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'chat_unavailable'),
        ),
      );
    });

    test('a stream that ends without a result is a network_error', () async {
      final (repo, transport) = _makeAgentRepo();

      final future = repo.summarize(docId);
      await Future<void>.delayed(Duration.zero);
      transport.addWire(
        sseFrame(
          'run_started',
          '{"run_id":"r-1","kind":"summary","document_id":"$docId"}',
        ),
      );
      transport.closeStream();

      await expectLater(
        future,
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'network_error'),
        ),
      );
    });

    test(
      'pre-stream 404 envelope surfaces as ApiException(not_found)',
      () async {
        final (repo, transport) = _makeAgentRepo();
        transport.openError = const ApiException(
          code: 'not_found',
          message: 'Document not found',
          statusCode: 404,
        );

        await expectLater(
          repo.summarize(docId),
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', 'not_found')
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.isNotFound, 'isNotFound', true),
          ),
        );
      },
    );
  });

  group('listAssociations (agent SSE stream)', () {
    const docId = '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01';

    test(
      'posts no body to /documents/{id}/associations and folds the stream '
      'into AssociationsResult',
      () async {
        final (repo, transport) = _makeAgentRepo();

        final future = repo.listAssociations(docId);
        await Future<void>.delayed(Duration.zero);
        transport.addWire(
          sseFrame(
            'run_started',
            '{"run_id":"r-2","kind":"associations","document_id":"$docId"}',
          ) +
              sseFrame('associations', jsonEncode(associationsResultJson)) +
              sseFrame(
                'done',
                '{"run_id":"r-2","outcome":"success","latency_ms":2360.0}',
              ),
        );
        transport.closeStream();

        final result = await future;
        expect(result.documentId, associationsResultJson['document_id']);
        expect(result.model, 'glm-4.7');
        expect(result.latencyMs, 2345.0);
        expect(result.associations, hasLength(1));
        expect(
          result.associations.single.documentId,
          '0198c7a1-7b2a-7c1e-9f3a-2f4b5c6d7e8f',
        );
        expect(result.associations.single.title, 'Riverpod 迁移笔记');
        expect(result.associations.single.tags, ['flutter', 'dart']);
        expect(result.associations.single.reason, '共享状态管理的迁移经验。');
        expect(result.associations.single.signal, 'tag_overlap');

        expect(
          transport.lastUri.toString(),
          'http://localhost:8000/api/v1/documents/$docId/associations',
        );
        expect(
          transport.lastBody,
          isNull,
          reason: 'the server handler takes only the path UUID',
        );
      },
    );

    test('parses an empty associations list', () async {
      final (repo, transport) = _makeAgentRepo();

      final future = repo.listAssociations(docId);
      await Future<void>.delayed(Duration.zero);
      transport.addWire(
        sseFrame(
          'associations',
          '{"document_id":"$docId","associations":[],"model":"glm-4.7",'
              '"latency_ms":12.0}',
        ),
      );
      transport.closeStream();

      final result = await future;
      expect(result.associations, isEmpty);
    });

    test('503 chat_unavailable envelope surfaces as ApiException', () async {
      final (repo, transport) = _makeAgentRepo();
      transport.openError = const ApiException(
        code: 'chat_unavailable',
        message: 'LLM provider is not configured',
        statusCode: 503,
      );

      await expectLater(
        repo.listAssociations(docId),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'chat_unavailable')
              .having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('error normalization', () {
    test('422 envelope surfaces as ApiException(validation_failed)', () async {
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          422,
          '{"error": {"code": "validation_failed", "message": "Request validation failed", '
              '"details": {"errors": [{"loc": ["body", "content"], "msg": "String should have at least 1 character"}]}}}',
        ),
      ]);

      await expectLater(
        repo.create(const DocumentCreate(content: '')),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'validation_failed')
              .having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('404 envelope surfaces as ApiException(not_found)', () async {
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          404,
          '{"error": {"code": "not_found", "message": "Document x not found", "details": {}}}',
        ),
      ]);

      await expectLater(
        repo.get('missing'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'not_found')
              .having((e) => e.isNotFound, 'isNotFound', true),
        ),
      );
    });
  });
}
