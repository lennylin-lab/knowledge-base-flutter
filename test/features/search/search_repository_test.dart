import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/features/search/search_repository.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

/// One canned HTTP response drained from the adapter queue per request.
class _CannedResponse {
  const _CannedResponse(
    this.statusCode,
    this.body, {
    this.contentType = Headers.jsonContentType,
  });

  final int statusCode;
  final String body;
  final String contentType;
}

/// A request as seen on the wire (method / path / query / decoded body).
class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.path,
    required this.queryParameters,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> queryParameters;
  final Object? body;

  @override
  String toString() => '$method $path $queryParameters ${body ?? ''}';
}

/// Queue-based adapter: records every request and answers with the next
/// canned response — the same pattern as
/// test/features/documents/documents_repository_test.dart.
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
        Headers.contentTypeHeader: [next.contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Wire-shaped fixture aligned with the backend OpenAPI schema.
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

(SearchRepository, _RecordingAdapter) _makeRepo(
  List<_CannedResponse> responses,
) {
  final adapter = _RecordingAdapter(responses);
  final dio = Dio()..httpClientAdapter = adapter;
  final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
  return (SearchRepository(client), adapter);
}

void main() {
  group('search', () {
    test('sends q/limit/tag exactly and parses the hits', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(
          200,
          jsonEncode({'mode': 'hybrid', 'items': [searchHitJson]}),
        ),
      ]);

      final response = await repo.search(q: '混合检索', limit: 5, tag: 'flutter');

      expect(response.mode, SearchMode.hybrid);
      final hit = response.items.single;
      expect(hit.documentId, searchHitJson['document_id']);
      expect(hit.documentTitle, '知识库设计笔记');
      expect(hit.documentTags, ['flutter']);
      expect(hit.chunkIndex, 2);
      expect(hit.content, contains('RRF'));
      expect(hit.score, 0.03125);
      expect(hit.esRank, 1);
      expect(hit.vectorRank, isNull);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/v1/search');
      expect(request.queryParameters, {
        'q': '混合检索',
        'limit': 5,
        'tag': 'flutter',
      });
    });

    test('omits tag and uses the default limit of 10', () async {
      final (repo, adapter) = _makeRepo([
        const _CannedResponse(200, '{"mode": "bm25", "items": []}'),
      ]);

      final response = await repo.search(q: 'flutter');

      expect(response.mode, SearchMode.bm25);
      expect(response.items, isEmpty);
      expect(
        adapter.requests.single.queryParameters,
        {'q': 'flutter', 'limit': 10},
        reason: 'tag must be absent (not sent as null/empty)',
      );
    });

    test('clamps limit into the 1–50 API range', () async {
      final (repo, adapter) = _makeRepo([
        const _CannedResponse(200, '{"mode": "hybrid", "items": []}'),
        const _CannedResponse(200, '{"mode": "hybrid", "items": []}'),
      ]);

      await repo.search(q: 'flutter', limit: 0);
      await repo.search(q: 'flutter', limit: 500);

      expect(adapter.requests[0].queryParameters['limit'], 1);
      expect(adapter.requests[1].queryParameters['limit'], 50);
    });
  });

  group('error normalization', () {
    test('envelope error surfaces as ApiException with its code', () async {
      // The dev backend has no embedding provider configured and answers
      // 502 search_index_error — the client must surface the message.
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          502,
          '{"error": {"code": "search_index_error", "message": '
              '"Embedding provider is not configured", "details": {}}}',
        ),
      ]);

      await expectLater(
        repo.search(q: 'flutter'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'search_index_error')
              .having((e) => e.statusCode, 'statusCode', 502),
        ),
      );
    });

    test('non-envelope 500 body synthesizes server_error', () async {
      final (repo, _) = _makeRepo([
        const _CannedResponse(
          500,
          '<html>Internal Server Error</html>',
          contentType: 'text/html',
        ),
      ]);

      await expectLater(
        repo.search(q: 'flutter'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'server_error')
              .having((e) => e.message, 'message', '服务暂不可用，请稍后重试'),
        ),
      );
    });
  });
}
