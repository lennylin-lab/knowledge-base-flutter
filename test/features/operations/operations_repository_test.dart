import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/features/operations/operations_repository.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:knowledge_base_flutter/shared/models/operation.dart';

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

  /// Fully encoded URL — pins the wire format (e.g. CJK query encoding).
  final String url;
  final Map<String, dynamic> queryParameters;
  final Object? body;

  @override
  String toString() => '$method $path $queryParameters ${body ?? ''}';
}

/// Queue-based adapter: records every request (reading the actual encoded
/// body stream) and answers with the next canned response — the same
/// pattern as test/features/documents/documents_repository_test.dart.
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

(OperationsRepository, _RecordingAdapter) _makeRepo(
  List<_CannedResponse> responses,
) {
  final adapter = _RecordingAdapter(responses);
  final dio = Dio()..httpClientAdapter = adapter;
  final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
  return (OperationsRepository(client), adapter);
}

/// Wire-shaped fixtures aligned with the backend `schemas/operation.py`.
const draftContentJson = <String, dynamic>{
  'content': '---\ntitle: AI 续写\n---\n\n这是续写的正文。',
  'title': null,
};

const operationReadJson = <String, dynamic>{
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

/// Apply response: the applied operation (with `result.revision_id`), the
/// revision it created, and the mutated document (indexing restarted).
final appliedOperationJson = {
  ...operationReadJson,
  'state': 'applied',
  'result': {'revision_id': '7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f'},
};

final applyResultJson = {
  'operation': appliedOperationJson,
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
};

void main() {
  group('createOperation', () {
    test(
      'posts the payload to /operations and parses the 201 detail',
      () async {
        final (repo, adapter) = _makeRepo([
          _CannedResponse(201, jsonEncode(operationReadJson)),
        ]);

        final operation = await repo.createOperation(
          const OperationCreate(
            documentId: '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
            baseDocumentVersion: '2026-08-31T12:30:00Z',
            draft: DraftContent(content: '---\ntitle: AI 续写\n---\n\n这是续写的正文。'),
            idempotencyKey: 'create-op-1',
          ),
        );

        expect(operation.state, OperationState.completed);
        expect(operation.draft?.content, startsWith('---'));
        expect(operation.baseDocumentVersion, '2026-08-31T12:30:00Z');

        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/api/v1/operations');
        expect(request.body, {
          'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
          'base_document_version': '2026-08-31T12:30:00Z',
          'draft': {
            'content': '---\ntitle: AI 续写\n---\n\n这是续写的正文。',
            'title': null,
          },
          'idempotency_key': 'create-op-1',
        });
      },
    );

    test('sends an explicit null idempotency_key when unset', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(201, jsonEncode(operationReadJson)),
      ]);

      await repo.createOperation(
        const OperationCreate(
          documentId: '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
          baseDocumentVersion: '2026-08-31T12:30:00Z',
          draft: DraftContent(content: '# 草稿'),
        ),
      );

      expect(adapter.requests.single.body, {
        'document_id': '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        'base_document_version': '2026-08-31T12:30:00Z',
        'draft': {'content': '# 草稿', 'title': null},
        'idempotency_key': null,
      });
    });
  });

  group('draft', () {
    const docId = '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01';

    test(
      'sends document_id/instruction as QUERY params with no body',
      () async {
        final (repo, adapter) = _makeRepo([
          _CannedResponse(200, jsonEncode(operationReadJson)),
        ]);

        await repo.draft(documentId: docId, instruction: '续写一章');

        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/api/v1/operations/draft');
        expect(request.queryParameters, {
          'document_id': docId,
          'instruction': '续写一章',
        });
        expect(
          request.body,
          isNull,
          reason:
              'the server takes document_id/instruction from the query only',
        );
      },
    );

    test('encodes a CJK instruction percent-encoded on the wire', () async {
      const instruction = '续写一章，主题是星际旅行';
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(operationReadJson)),
      ]);

      await repo.draft(documentId: docId, instruction: instruction);

      final request = adapter.requests.single;
      expect(
        request.url,
        '/api/v1/operations/draft'
        '?document_id=$docId&instruction=${Uri.encodeQueryComponent(instruction)}',
      );
    });

    test('omits instruction when null or empty', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(operationReadJson)),
        _CannedResponse(200, jsonEncode(operationReadJson)),
      ]);

      await repo.draft(documentId: docId);
      await repo.draft(documentId: docId, instruction: '');

      expect(adapter.requests[0].queryParameters, {'document_id': docId});
      expect(adapter.requests[0].url, isNot(contains('instruction')));
      expect(adapter.requests[1].queryParameters, {'document_id': docId});
      expect(adapter.requests[1].url, isNot(contains('instruction')));
    });

    test('503 chat_unavailable surfaces as ApiException (fires before '
        'validation)', () async {
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          503,
          '{"error": {"code": "chat_unavailable", '
          '"message": "LLM provider is not configured", "details": {}}}',
        ),
      ]);

      await expectLater(
        repo.draft(documentId: 'missing'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'chat_unavailable')
              .having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('502 llm_provider_error surfaces as ApiException', () async {
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          502,
          '{"error": {"code": "llm_provider_error", '
          '"message": "provider exploded", "details": {}}}',
        ),
      ]);

      await expectLater(
        repo.draft(documentId: '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'llm_provider_error',
          ),
        ),
      );
    });
  });

  group('operation', () {
    test('fetches /operations/{id} and parses the detail', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(operationReadJson)),
      ]);

      final operation = await repo.operation(
        'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d',
      );

      expect(operation.id, 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d');
      expect(operation.state, OperationState.completed);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(
        request.path,
        '/api/v1/operations/aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d',
      );
    });

    test('404 envelope surfaces as ApiException(not_found)', () async {
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          404,
          '{"error": {"code": "not_found", "message": "Operation x not '
          'found", "details": {}}}',
        ),
      ]);

      await expectLater(
        repo.operation('missing'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'not_found')
              .having((e) => e.isNotFound, 'isNotFound', true),
        ),
      );
    });
  });

  group('operationsForDocument', () {
    test(
      'fetches /operations/documents/{id} and returns a typed list',
      () async {
        final (repo, adapter) = _makeRepo([
          _CannedResponse(
            200,
            jsonEncode([
              operationReadJson,
              {
                ...operationReadJson,
                'state': 'failed',
                'error': {'error_class': 'LLMProviderError'},
              },
            ]),
          ),
        ]);

        final operations = await repo.operationsForDocument(
          '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        );

        expect(operations, isA<List<OperationReadDetail>>());
        expect(operations, hasLength(2));
        // Server sends newest first — the client preserves wire order.
        expect(operations[0].state, OperationState.completed);
        expect(operations[1].state, OperationState.failed);
        expect(operations[1].error, {'error_class': 'LLMProviderError'});

        final request = adapter.requests.single;
        expect(request.method, 'GET');
        expect(
          request.path,
          '/api/v1/operations/documents/0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01',
        );
        expect(request.queryParameters, isEmpty);
      },
    );
  });

  group('resume', () {
    const operationId = 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d';

    test('posts NO body when there is no draft amendment', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(operationReadJson)),
      ]);

      await repo.resume(operationId);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/v1/operations/$operationId/resume');
      expect(
        request.body,
        isNull,
        reason: 'server models default to null — send nothing when unset',
      );
    });

    test('posts {"draft": …} when the stored draft is amended', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(operationReadJson)),
      ]);

      await repo.resume(
        operationId,
        draft: const DraftContent(content: '修订后的草稿', title: '修订标题'),
      );

      expect(adapter.requests.single.body, {
        'draft': {'content': '修订后的草稿', 'title': '修订标题'},
      });
    });

    test('409 conflict surfaces with details.state intact', () async {
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          409,
          '{"error": {"code": "conflict", "message": "Operation is not '
          'resumable", "details": {"state": "running"}}}',
        ),
      ]);

      await expectLater(
        repo.resume(operationId),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'conflict')
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.details, 'details', {'state': 'running'}),
        ),
      );
    });
  });

  group('apply', () {
    const operationId = 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d';

    test(
      'posts NO body without an expected version and parses ApplyResult',
      () async {
        final (repo, adapter) = _makeRepo([
          _CannedResponse(200, jsonEncode(applyResultJson)),
        ]);

        final result = await repo.apply(operationId);

        expect(result.operation.state, OperationState.applied);
        expect(
          result.operation.revisionId,
          '7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f',
        );
        expect(result.revision.id, '7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f');
        expect(result.revision.tags, ['flutter', 'backend']);
        expect(result.document.indexStatus, IndexStatus.pending);

        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/api/v1/operations/$operationId/apply');
        expect(request.body, isNull);
      },
    );

    test('posts the expected base version verbatim when given', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode(applyResultJson)),
      ]);

      await repo.apply(
        operationId,
        expectedBaseDocumentVersion: '2026-08-31T12:30:00Z',
      );

      // Verbatim timestamp — the server compares exact equality for
      // optimistic concurrency; no reformatting.
      expect(adapter.requests.single.body, {
        'expected_base_document_version': '2026-08-31T12:30:00Z',
      });
    });

    test('409 conflict carries details.base_version/current_version', () async {
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          409,
          '{"error": {"code": "conflict", "message": "Document changed since '
          'the draft was created; re-draft or resume the operation", '
          '"details": {"base_version": "2026-08-31T12:30:00Z", '
          '"current_version": "2026-09-16T08:01:00Z"}}}',
        ),
      ]);

      await expectLater(
        repo.apply(
          operationId,
          expectedBaseDocumentVersion: '2026-08-31T12:30:00Z',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'conflict')
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.details, 'details', {
                'base_version': '2026-08-31T12:30:00Z',
                'current_version': '2026-09-16T08:01:00Z',
              }),
        ),
      );
    });
  });
}
