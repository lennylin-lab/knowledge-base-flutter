import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/features/chat/session_repository.dart';
import 'package:knowledge_base_flutter/shared/models/session.dart';

/// One canned HTTP response drained from the adapter queue per request.
class _CannedResponse {
  const _CannedResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

/// A request as seen on the wire (method / path / query).
class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.path,
    required this.queryParameters,
  });

  final String method;
  final String path;
  final Map<String, dynamic> queryParameters;

  @override
  String toString() => '$method $path $queryParameters';
}

/// Queue-based adapter: records every request and answers with the next
/// canned response — the same pattern as search_repository_test.dart.
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
    requests.add(
      _RecordedRequest(
        method: options.method,
        path: options.path,
        queryParameters: Map<String, dynamic>.from(options.queryParameters),
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

const sessionJson = {
  'id': '6f1a2b3c-0000-4000-8000-000000000001',
  'title': '检索方案',
  'created_at': '2026-09-13T08:00:00Z',
  'updated_at': '2026-09-13T09:30:00Z',
};

const messageJson = {
  'id': '6f1a2b3c-0000-4000-8000-0000000000aa',
  'role': 'user',
  'content': '知识库用什么检索？',
  'run_id': null,
  'created_at': '2026-09-13T08:00:05Z',
};

(SessionRepository, _RecordingAdapter) _makeRepo(
  List<_CannedResponse> responses,
) {
  final adapter = _RecordingAdapter(responses);
  final dio = Dio()..httpClientAdapter = adapter;
  final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
  return (SessionRepository(client), adapter);
}

void main() {
  group('listSessions', () {
    test('sends clamped limit and cursor; parses the page', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(
          200,
          jsonEncode({
            'items': [sessionJson],
            'next_cursor': 'next-cursor-1',
          }),
        ),
      ]);

      final page = await repo.listSessions(cursor: 'cursor-0', limit: 500);

      expect(page.items.single.title, '检索方案');
      expect(page.nextCursor, 'next-cursor-1');
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/v1/chat/sessions');
      expect(request.queryParameters['limit'], 100);
      expect(request.queryParameters['cursor'], 'cursor-0');
    });

    test('omits the cursor query param on page 1', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(200, jsonEncode({'items': [], 'next_cursor': null})),
      ]);

      final page = await repo.listSessions();

      expect(page, isA<SessionPage>());
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
      expect(adapter.requests.single.queryParameters.containsKey('cursor'),
          isFalse);
    });

    test('normalizes failures into ApiException', () async {
      final (repo, _) = _makeRepo([
        _CannedResponse(
          503,
          jsonEncode({
            'error': {'code': 'chat_unavailable', 'message': 'down'},
          }),
        ),
      ]);

      await expectLater(
        repo.listSessions(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'chat_unavailable'),
        ),
      );
    });
  });

  group('getSession', () {
    test('hits /{id} and parses messages chronologically', () async {
      final (repo, adapter) = _makeRepo([
        _CannedResponse(
          200,
          jsonEncode({
            ...sessionJson,
            'messages': [
              messageJson,
              {
                ...messageJson,
                'id': '6f1a2b3c-0000-4000-8000-0000000000ab',
                'role': 'assistant',
                'content': '使用混合检索',
                'run_id': '6f1a2b3c-0000-4000-8000-0000000000cc',
              },
            ],
          }),
        ),
      ]);

      final detail = await repo.getSession(sessionJson['id'] as String);

      expect(detail.title, '检索方案');
      expect(detail.messages, hasLength(2));
      expect(detail.messages.first.role, ChatMessageRole.user);
      expect(detail.messages.last.role, ChatMessageRole.assistant);
      expect(detail.messages.last.runId, '6f1a2b3c-0000-4000-8000-0000000000cc');
      expect(
        adapter.requests.single.path,
        '/api/v1/chat/sessions/${sessionJson['id']}',
      );
    });

    test('unknown session surfaces the 404 envelope code', () async {
      final (repo, _) = _makeRepo([
        _CannedResponse(
          404,
          jsonEncode({
            'error': {'code': 'session_not_found', 'message': 'no such session'},
          }),
        ),
      ]);

      await expectLater(
        repo.getSession('missing'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'session_not_found'),
        ),
      );
    });
  });

  group('deleteSession', () {
    test('sends DELETE to /{id} and accepts 204', () async {
      final (repo, adapter) = _makeRepo([_CannedResponse(204, '')]);

      await repo.deleteSession(sessionJson['id'] as String);

      final request = adapter.requests.single;
      expect(request.method, 'DELETE');
      expect(
        request.path,
        '/api/v1/chat/sessions/${sessionJson['id']}',
      );
    });
  });
}
