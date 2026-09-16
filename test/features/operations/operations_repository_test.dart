import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/agent_stream_client.dart';
import 'package:knowledge_base_flutter/core/network/api_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/network/chat_transport.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/features/operations/operations_providers.dart';
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

/// Scripted byte-stream transport for the draft SSE endpoint: `open`
/// records the request and hands out a controller-driven stream so each
/// test drives chunks, errors and end-of-stream explicitly (the same
/// pattern as test/features/documents/documents_repository_test.dart).
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

(OperationsRepository, _ScriptedTransport) _makeAgentRepo() {
  final dio = Dio();
  final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
  final transport = _ScriptedTransport();
  final repo = OperationsRepository(
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

  group('draft (agent SSE stream)', () {
    const docId = '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01';
    const operationId = 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d';

    test('posts document_id/instruction as QUERY params with no body and folds '
        'run_started → draft → done into the lightweight result', () async {
      final (repo, transport) = _makeAgentRepo();

      final future = repo.draft(documentId: docId, instruction: '续写一章');
      // Let open() resolve before driving the scripted stream.
      await Future<void>.delayed(Duration.zero);
      transport.addWire(
        sseFrame(
              'run_started',
              '{"run_id":"r-1","kind":"draft","document_id":"$docId"}',
            ) +
            sseFrame(
              'draft',
              '{"operation_id":"$operationId","state":"completed",'
                  '"content":"---\\ntitle: AI 续写\\n---\\n\\n这是续写的正文。",'
                  '"title":null}',
            ) +
            sseFrame(
              'done',
              '{"run_id":"r-1","outcome":"success","latency_ms":1250.0}',
            ),
      );
      transport.closeStream();

      final result = await future;
      expect(result.operationId, operationId);
      expect(result.state, OperationState.completed);
      expect(result.draft.content, '---\ntitle: AI 续写\n---\n\n这是续写的正文。');
      expect(result.draft.title, isNull);

      expect(
        transport.lastUri.toString(),
        'http://localhost:8000/api/v1/operations/draft'
        '?document_id=$docId&instruction=${Uri.encodeQueryComponent('续写一章')}',
      );
      expect(
        transport.lastBody,
        isNull,
        reason: 'the server takes document_id/instruction from the query only',
      );
    });

    test('maps a present draft title and the completed wire state', () async {
      final (repo, transport) = _makeAgentRepo();

      final future = repo.draft(documentId: docId);
      await Future<void>.delayed(Duration.zero);
      transport.addWire(
        sseFrame(
          'draft',
          '{"operation_id":"$operationId","state":"completed",'
              '"content":"正文","title":"显式标题"}',
        ),
      );
      transport.closeStream();

      final result = await future;
      expect(result.draft.title, '显式标题');
      expect(result.state, OperationState.completed);
    });

    test(
      'an unknown wire state still yields a reviewable (completed) draft',
      () async {
        final (repo, transport) = _makeAgentRepo();

        final future = repo.draft(documentId: docId);
        await Future<void>.delayed(Duration.zero);
        transport.addWire(
          sseFrame(
            'draft',
            '{"operation_id":"$operationId","state":"published",'
                '"content":"正文","title":null}',
          ),
        );
        transport.closeStream();

        final result = await future;
        // A received draft event always means "a draft arrived": the unknown
        // future state must not crash the parse nor disable the review/apply
        // view — it maps to completed (no invented sentinels).
        expect(result.state, OperationState.completed);
        expect(result.draft.content, '正文');
        expect(result.draft.title, isNull);
      },
    );

    test('omits instruction when null or empty', () async {
      Future<(OperationsRepository, _ScriptedTransport)> runOnce(
        String? instruction,
      ) async {
        final (repo, transport) = _makeAgentRepo();
        final future = repo.draft(documentId: docId, instruction: instruction);
        await Future<void>.delayed(Duration.zero);
        transport.addWire(
          sseFrame(
            'draft',
            '{"operation_id":"$operationId","state":"completed",'
                '"content":"正文","title":null}',
          ),
        );
        transport.closeStream();
        await future;
        return (repo, transport);
      }

      final (_, nullTransport) = await runOnce(null);
      expect(
        nullTransport.lastUri!.queryParameters.containsKey('instruction'),
        isFalse,
      );
      expect(nullTransport.lastUri!.queryParameters, {'document_id': docId});

      final (_, emptyTransport) = await runOnce('');
      expect(
        emptyTransport.lastUri!.queryParameters.containsKey('instruction'),
        isFalse,
      );
      expect(emptyTransport.lastUri!.queryParameters, {'document_id': docId});
    });

    test(
      'a mid-stream error event surfaces as ApiException(code, message)',
      () async {
        final (repo, transport) = _makeAgentRepo();

        final future = repo.draft(documentId: docId);
        await Future<void>.delayed(Duration.zero);
        transport.addWire(
          sseFrame(
                'run_started',
                '{"run_id":"r-1","kind":"draft","document_id":"$docId"}',
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

    test('a stream that ends without a result is a network_error', () async {
      final (repo, transport) = _makeAgentRepo();

      final future = repo.draft(documentId: docId);
      await Future<void>.delayed(Duration.zero);
      transport.addWire(
        sseFrame(
          'run_started',
          '{"run_id":"r-1","kind":"draft","document_id":"$docId"}',
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
      'pre-stream 404 envelope (missing document) keeps not_found',
      () async {
        final (repo, transport) = _makeAgentRepo();
        transport.openError = const ApiException(
          code: 'not_found',
          message: 'Document not found',
          statusCode: 404,
        );

        await expectLater(
          repo.draft(documentId: 'missing'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', 'not_found')
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.isNotFound, 'isNotFound', true),
          ),
        );
      },
    );

    test('pre-stream 503 chat_unavailable keeps the code and status', () async {
      final (repo, transport) = _makeAgentRepo();
      transport.openError = const ApiException(
        code: 'chat_unavailable',
        message: 'LLM provider is not configured',
        statusCode: 503,
      );

      await expectLater(
        repo.draft(documentId: docId),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'chat_unavailable')
              .having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('operationsRepositoryProvider wiring', () {
    const docId = '0b6df9a2-1cbd-4a0f-9b1a-3f8f7f1a2e01';
    const operationId = 'aa0b1c2d-3e4f-4a5b-8c9d-0e1f2a3b4c5d';

    test(
      'injects the auth-carrying agent stream client: the streamed draft '
      'request reaches the transport WITH the Authorization header',
      () async {
        final transport = _ScriptedTransport();
        final dio = Dio();
        final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
        final container = ProviderContainer(
          retry: noAutomaticRetry,
          overrides: [
            apiClientProvider.overrideWithValue(client),
            // What agentStreamClientProvider provides in the app (the auth
            // headers builder wired in core) — plus a scripted transport.
            agentStreamClientProvider.overrideWithValue(
              AgentStreamClient(
                baseUrl: client.baseUrl,
                transport: transport,
                headers: () async => {'Authorization': 'Bearer tok-3'},
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // If the provider stopped injecting agentStreamClientProvider, the
        // repository's fallback would open a REAL transport (headerless) and
        // this future would never fold from the scripted stream.
        final future = container
            .read(operationsRepositoryProvider)
            .draft(documentId: docId);
        await Future<void>.delayed(Duration.zero);
        transport.addWire(
          sseFrame(
            'draft',
            '{"operation_id":"$operationId","state":"completed",'
                '"content":"正文","title":null}',
          ),
        );
        transport.closeStream();

        final result = await future;
        expect(result.operationId, operationId);
        // The regression pin: the auth headers flow client → transport.
        expect(transport.lastHeaders, {'Authorization': 'Bearer tok-3'});
      },
    );
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
