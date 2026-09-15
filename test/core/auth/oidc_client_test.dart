import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/auth/oidc_client.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';

/// Queue-based canned-response adapter (same pattern as the repository
/// tests): records requests, answers from the queue.
class _Canned {
  const _Canned(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(List<_Canned> responses) : _responses = List<_Canned>.of(responses);

  final List<_Canned> _responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

OidcClient _client(_Adapter adapter) =>
    OidcClient(dio: Dio()..httpClientAdapter = adapter);

const String _discoveryBody = '''
{
  "issuer": "http://localhost:8180/realms/kb",
  "authorization_endpoint": "http://localhost:8180/realms/kb/protocol/openid-connect/auth",
  "token_endpoint": "http://localhost:8180/realms/kb/protocol/openid-connect/token"
}
''';

final _issuer = Uri.parse('http://localhost:8180/realms/kb');

void main() {
  group('PKCE', () {
    test('verifier: 43 chars, base64url alphabet, no padding, unique', () {
      final client = OidcClient();
      final pattern = RegExp(r'^[A-Za-z0-9\-_]{43}$');
      final first = client.createVerifier();
      expect(pattern.hasMatch(first), isTrue, reason: first);
      expect(client.createVerifier(), isNot(first));
    });

    test('challenge is base64url(SHA256(verifier)) without padding', () {
      final client = OidcClient();
      final verifier = client.createVerifier();
      final expected =
          base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes)
              .replaceAll('=', '');
      expect(client.createChallenge(verifier), expected);
    });

    test('state tokens are unique', () {
      final client = OidcClient();
      expect(client.createState(), isNot(client.createState()));
    });
  });

  group('discover', () {
    test('fetches {issuer}/.well-known/openid-configuration and caches', () async {
      final adapter = _Adapter([const _Canned(200, _discoveryBody)]);
      final client = _client(adapter);

      final endpoints = await client.discover(_issuer);
      expect(
        endpoints.authorization,
        Uri.parse(
          'http://localhost:8180/realms/kb/protocol/openid-connect/auth',
        ),
      );
      expect(
        endpoints.token,
        Uri.parse(
          'http://localhost:8180/realms/kb/protocol/openid-connect/token',
        ),
      );

      // Second call is served from cache — no extra round trip.
      await client.discover(_issuer);
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.uri.path,
        '/realms/kb/.well-known/openid-configuration',
        reason: 'issuer has no trailing slash — path must be appended',
      );
    });

    test('unreachable discovery → network_error', () async {
      final adapter = _Adapter([
        const _Canned(503, 'nope'),
      ]);
      final client = _client(adapter);
      await expectLater(
        client.discover(_issuer),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'network_error'),
        ),
      );
    });
  });

  test('authorizeUrl carries PKCE + public-client params', () {
    final adapter = _Adapter([const _Canned(200, _discoveryBody)]);
    final client = _client(adapter);
    return client.discover(_issuer).then((endpoints) {
      final url = client.authorizeUrl(
        endpoints: endpoints,
        clientId: 'kb-web',
        redirectUri: 'http://localhost:8182/auth/callback',
        scopes: 'openid',
        state: 'ST-1',
        codeChallenge: 'CC-1',
      );
      expect(url.queryParameters['response_type'], 'code');
      expect(url.queryParameters['client_id'], 'kb-web');
      expect(
        url.queryParameters['redirect_uri'],
        'http://localhost:8182/auth/callback',
      );
      expect(url.queryParameters['scope'], 'openid');
      expect(url.queryParameters['state'], 'ST-1');
      expect(url.queryParameters['code_challenge'], 'CC-1');
      expect(url.queryParameters['code_challenge_method'], 'S256');
    });
  });

  group('exchangeCode', () {
    test('posts the form-urlencoded code+verifier, parses the token set', () async {
      final adapter = _Adapter([
        const _Canned(200, _discoveryBody),
        const _Canned(
          200,
          '{"access_token":"at-1","refresh_token":"rt-1","expires_in":300,'
          '"token_type":"Bearer"}',
        ),
      ]);
      final client = _client(adapter);
      final endpoints = await client.discover(_issuer);
      final response = await client.exchangeCode(
        endpoints: endpoints,
        clientId: 'kb-web',
        redirectUri: 'http://localhost:8182/auth/callback',
        code: 'CODE',
        verifier: 'VER',
      );
      expect(response.accessToken, 'at-1');
      expect(response.refreshToken, 'rt-1');
      expect(response.expiresIn, 300);

      final request = adapter.requests.last;
      expect(request.uri, endpoints.token);
      expect(
        request.headers['content-type'],
        contains('application/x-www-form-urlencoded'),
      );
      expect(request.data, isA<Map<String, dynamic>>());
      final body = request.data! as Map<String, dynamic>;
      expect(body['grant_type'], 'authorization_code');
      expect(body['code'], 'CODE');
      expect(body['code_verifier'], 'VER');
      expect(body['client_id'], 'kb-web');
      expect(
        body['redirect_uri'],
        'http://localhost:8182/auth/callback',
      );
    });

    test('OAuth error body → unauthorized ApiException with description',
        () async {
      final adapter = _Adapter([
        const _Canned(200, _discoveryBody),
        const _Canned(
          400,
          '{"error":"invalid_grant",'
          '"error_description":"Code not valid"}',
        ),
      ]);
      final client = _client(adapter);
      final endpoints = await client.discover(_issuer);
      await expectLater(
        client.exchangeCode(
          endpoints: endpoints,
          clientId: 'kb-web',
          redirectUri: 'http://localhost:8182/auth/callback',
          code: 'BAD',
          verifier: 'VER',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'unauthorized')
              .having((e) => e.message, 'message', contains('Code not valid')),
        ),
      );
    });
  });

  group('refresh', () {
    test('posts refresh_token grant and tolerates a missing rotated token',
        () async {
      final adapter = _Adapter([
        const _Canned(200, _discoveryBody),
        const _Canned(
          200,
          '{"access_token":"at-2","expires_in":300}',
        ),
      ]);
      final client = _client(adapter);
      final endpoints = await client.discover(_issuer);
      final response = await client.refresh(
        endpoints: endpoints,
        clientId: 'kb-web',
        refreshToken: 'rt-old',
      );
      expect(response.accessToken, 'at-2');
      expect(response.refreshToken, isNull,
          reason: 'caller keeps the previous refresh token');

      final body = adapter.requests.last.data! as Map<String, dynamic>;
      expect(body['grant_type'], 'refresh_token');
      expect(body['refresh_token'], 'rt-old');
      expect(body['client_id'], 'kb-web');
    });
  });
}
