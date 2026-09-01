import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';

/// Builds a `DioException.badResponse` the way dio itself would, carrying
/// [body] already decoded (Map for JSON responses) or raw (String).
DioException badResponse(int status, Object? body) => DioException(
      requestOptions: RequestOptions(path: '/api/v1/documents'),
      response: Response<Object?>(
        requestOptions: RequestOptions(path: '/api/v1/documents'),
        statusCode: status,
        data: body,
      ),
      type: DioExceptionType.badResponse,
    );

/// An adapter returning one canned body, bypassing the network.
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter(this.statusCode, this.body, this.contentType);

  final int statusCode;
  final String body;
  final String contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody(
      Stream.fromIterable([utf8.encode(body)]),
      statusCode,
      headers: {'content-type': [contentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Drives one request through [ApiClient]'s interceptor; returns the
/// `ApiException` attached to the rethrown `DioException` (or null on 2xx).
Future<Object?> requestViaClient(
  int statusCode,
  String body,
  String contentType,
) async {
  final dio = Dio()..httpClientAdapter = _CannedAdapter(statusCode, body, contentType);
  final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
  try {
    await client.dio.get<void>('/api/v1/documents');
    return null;
  } on DioException catch (e) {
    return e.error;
  }
}

void main() {
  group('envelope decoding (mapDioException)', () {
    test('404 not_found', () {
      final e = mapDioException(
        badResponse(
          404,
          {
            'error': {
              'code': 'not_found',
              'message': 'Document not found',
              'details': <String, dynamic>{},
            },
          },
        ),
      );
      expect(e.code, 'not_found');
      expect(e.message, 'Document not found');
      expect(e.statusCode, 404);
      expect(e.details, isEmpty);
    });

    test('409 conflict', () {
      final e = mapDioException(
        badResponse(
          409,
          {
            'error': {
              'code': 'conflict',
              'message': 'Document was modified concurrently',
              'details': {'document_id': 'abc'},
            },
          },
        ),
      );
      expect(e.code, 'conflict');
      expect(e.details, {'document_id': 'abc'});
      expect(e.statusCode, 409);
    });

    test('422 validation_failed keeps the details payload', () {
      final e = mapDioException(
        badResponse(
          422,
          {
            'error': {
              'code': 'validation_failed',
              'message': 'Request validation failed',
              'details': {
                'errors': [
                  {'loc': ['body', 'content'], 'msg': 'String should have at least 1 character'},
                ],
              },
            },
          },
        ),
      );
      expect(e.code, 'validation_failed');
      expect(e.statusCode, 422);
      expect(e.details?['errors'], isA<List<dynamic>>());
    });

    test('429 rate_limited', () {
      final e = mapDioException(
        badResponse(
          429,
          {'error': {'code': 'rate_limited', 'message': 'Too many requests', 'details': {}}},
        ),
      );
      expect(e.code, 'rate_limited');
      expect(e.statusCode, 429);
    });

    test('502 llm_provider_error', () {
      final e = mapDioException(
        badResponse(
          502,
          {'error': {'code': 'llm_provider_error', 'message': 'Upstream failed', 'details': {}}},
        ),
      );
      expect(e.code, 'llm_provider_error');
      expect(e.statusCode, 502);
    });

    test('503 chat_unavailable', () {
      final e = mapDioException(
        badResponse(
          503,
          {'error': {'code': 'chat_unavailable', 'message': 'No API key configured', 'details': {}}},
        ),
      );
      expect(e.code, 'chat_unavailable');
      expect(e.statusCode, 503);
    });

    test('envelope delivered as a JSON string body is decoded too', () {
      final e = mapDioException(
        badResponse(
          404,
          '{"error":{"code":"not_found","message":"Document not found","details":{}}}',
        ),
      );
      expect(e.code, 'not_found');
      expect(e.statusCode, 404);
    });
  });

  group('fallbacks (no usable envelope)', () {
    test('non-JSON 4xx body → network_error', () {
      final e = mapDioException(
        badResponse(400, '<html><body>Bad Request</body></html>'),
      );
      expect(e.code, 'network_error');
      expect(e.statusCode, 400);
    });

    test('non-JSON 5xx body → server_error', () {
      final e = mapDioException(
        badResponse(502, '<html><body>Bad Gateway</body></html>'),
      );
      expect(e.code, 'server_error');
      expect(e.statusCode, 502);
    });

    test('malformed JSON body → fallback, never a parse crash', () {
      final e = mapDioException(badResponse(500, '{"error": "not-the-envelope"}'));
      expect(e.code, 'server_error');
    });

    test('connection error without response → network_error', () {
      final e = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/documents'),
          type: DioExceptionType.connectionError,
          error: SocketException('refused'),
        ),
      );
      expect(e.code, 'network_error');
      expect(e.statusCode, isNull);
    });

    test('timeout without response → network_error', () {
      final e = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/documents'),
          type: DioExceptionType.receiveTimeout,
        ),
      );
      expect(e.code, 'network_error');
    });

    test('cancelled request → cancelled', () {
      final e = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/documents'),
          type: DioExceptionType.cancel,
        ),
      );
      expect(e.code, 'cancelled');
    });
  });

  group('toApiException unwrapping', () {
    test('passes ApiException through unchanged', () {
      const original = ApiException(code: 'not_found', message: 'x');
      expect(toApiException(original), same(original));
    });

    test('unwraps the ApiException attached by the interceptor', () {
      final wrapped = badResponse(
        404,
        {'error': {'code': 'not_found', 'message': 'gone', 'details': {}}},
      ).copyWith(error: ApiException(code: 'not_found', message: 'gone', statusCode: 404));
      expect(toApiException(wrapped).code, 'not_found');
    });
  });

  group('interceptor wiring (ApiClient.dio end-to-end)', () {
    test('404 envelope surfaces as ApiException on the DioException', () async {
      final error = await requestViaClient(
        404,
        '{"error":{"code":"not_found","message":"Document not found","details":{}}}',
        'application/json',
      );
      expect(error, isA<ApiException>());
      final api = error as ApiException;
      expect(api.code, 'not_found');
      expect(api.message, 'Document not found');
      expect(api.statusCode, 404);
    });

    test('HTML 502 body surfaces as server_error', () async {
      final error = await requestViaClient(
        502,
        '<html>Bad Gateway</html>',
        'text/html',
      );
      expect((error as ApiException).code, 'server_error');
    });

    test('2xx passes through untouched', () async {
      final result = await requestViaClient(
        200,
        '{"status":"ok"}',
        'application/json',
      );
      expect(result, isNull);
    });
  });
}
