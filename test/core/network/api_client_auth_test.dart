import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/network/api_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';

class _Canned {
  const _Canned(this.statusCode, [this.body = '{}']);

  final int statusCode;
  final String body;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(List<_Canned> responses) : _responses = List<_Canned>.of(responses);

  final List<_Canned> _responses;
  final List<Map<String, dynamic>> headers = [];
  final List<Map<String, dynamic>> extras = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers.add(Map<String, dynamic>.of(options.headers));
    extras.add(Map<String, dynamic>.of(options.extra));
    if (_responses.isEmpty) {
      throw StateError('no canned response left for ${options.uri}');
    }
    final next = _responses.removeAt(0);
    return ResponseBody.fromBytes(
      utf8.encode(next.body),
      next.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _unauthorizedEnvelope = '''
{"error": {"code": "unauthorized", "message": "Not authenticated", "details": {}}}
''';

void main() {
  test('request carries the resolved Bearer token', () async {
    final adapter = _Adapter([const _Canned(200)]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:8000',
      dio: dio,
      tokenResolver: () async => 'tok-1',
    );
    await client.dio.get<Object?>('/api/v1/documents');
    expect(adapter.headers.single['Authorization'], 'Bearer tok-1');
  });

  test('no resolver (compat mode) → no Authorization header ever', () async {
    final adapter = _Adapter([const _Canned(200)]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(baseUrl: 'http://localhost:8000', dio: dio);
    await client.dio.get<Object?>('/api/v1/documents');
    expect(adapter.headers.single.containsKey('Authorization'), isFalse);
  });

  test('resolver returning null (unauthenticated) → no header', () async {
    final adapter = _Adapter([const _Canned(200)]);
    final dio = Dio()..httpClientAdapter = adapter;
    ApiClient(
      baseUrl: 'http://localhost:8000',
      dio: dio,
      tokenResolver: () async => null,
    );
    await dio.get<Object?>('/api/v1/documents');
    expect(adapter.headers.single.containsKey('Authorization'), isFalse);
  });

  test('401 triggers one forced refresh and the retry succeeds', () async {
    var tokenCalls = 0;
    var refreshCalls = 0;
    final adapter = _Adapter([
      const _Canned(401, _unauthorizedEnvelope),
      const _Canned(200, '{"items": []}'),
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:8000',
      dio: dio,
      tokenResolver: () async {
        tokenCalls++;
        return tokenCalls == 1 ? 'stale' : 'fresh';
      },
      refreshResolver: () async {
        refreshCalls++;
        return 'fresh';
      },
    );
    final response = await client.dio.get<Object?>('/api/v1/documents');
    expect(response.statusCode, 200);
    expect(refreshCalls, 1);
    expect(adapter.headers, hasLength(2));
    expect(adapter.headers[0]['Authorization'], 'Bearer stale');
    expect(adapter.headers[1]['Authorization'], 'Bearer fresh');
    // The retry is flagged so a second 401 cannot recurse.
    expect(adapter.extras[1]['kbAuthRetried'], isTrue);
  });

  test('refresh failure surfaces the original 401 envelope once', () async {
    final adapter = _Adapter([const _Canned(401, _unauthorizedEnvelope)]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:8000',
      dio: dio,
      tokenResolver: () async => 'stale',
      refreshResolver: () async => null,
    );
    await expectLater(
      client.dio.get<Object?>('/api/v1/documents'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<ApiException>()
              .having((a) => a.code, 'code', 'unauthorized'),
        ),
      ),
    );
    expect(adapter.headers, hasLength(1), reason: 'no retry attempted');
  });

  test('a second 401 after a retried refresh is terminal (no loop)', () async {
    var refreshCalls = 0;
    final adapter = _Adapter([
      const _Canned(401, _unauthorizedEnvelope),
      const _Canned(401, _unauthorizedEnvelope),
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:8000',
      dio: dio,
      tokenResolver: () async => 'stale',
      refreshResolver: () async {
        refreshCalls++;
        return 'fresh';
      },
    );
    await expectLater(
      client.dio.get<Object?>('/api/v1/documents'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 1, reason: 'exactly one refresh-and-retry');
    expect(adapter.headers, hasLength(2));
  });

  test('non-401 errors never hit the refresh path', () async {
    var refreshCalls = 0;
    final adapter = _Adapter([
      const _Canned(404, '{"error":{"code":"not_found","message":"x"}}'),
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:8000',
      dio: dio,
      tokenResolver: () async => 'tok',
      refreshResolver: () async {
        refreshCalls++;
        return 'fresh';
      },
    );
    await expectLater(
      client.dio.get<Object?>('/api/v1/documents/nope'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
  });
}
