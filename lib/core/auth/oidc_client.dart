import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../network/api_exception.dart';

/// Endpoint set discovered from `{issuer}/.well-known/openid-configuration`.
class OidcEndpoints {
  const OidcEndpoints({required this.authorization, required this.token});

  final Uri authorization;
  final Uri token;
}

/// Token-endpoint response subset the client needs.
class OidcTokenResponse {
  const OidcTokenResponse({
    required this.accessToken,
    required this.expiresIn,
    this.refreshToken,
  });

  final String accessToken;

  /// Lifetime of [accessToken] in seconds (OIDC `expires_in`).
  final int expiresIn;
  final String? refreshToken;
}

/// Keycloak-compatible OIDC protocol client: discovery, PKCE, authorize-URL
/// construction, code exchange and refresh — plain HTTP only, so the whole
/// surface is unit-testable offline with a mocked dio adapter.
class OidcClient {
  OidcClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              // Token errors arrive as 400 with an OAuth error body.
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 300,
            ),
          );

  final Dio _dio;
  final _random = Random.secure();
  final _discoveryCache = <Uri, OidcEndpoints>{};

  /// Fetch (once per issuer) the authorization/token endpoints.
  Future<OidcEndpoints> discover(Uri issuer) async {
    final cached = _discoveryCache[issuer];
    if (cached != null) return cached;

    final Response<dynamic> response;
    try {
      response = await _dio.get<Object?>(_wellKnownUri(issuer).toString());
    } on DioException {
      throw const ApiException(
        code: 'network_error',
        message: '无法连接登录服务，请检查网络后重试',
      );
    }
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'internal_error',
        message: '登录服务配置异常，请检查 OIDC Issuer 设置',
      );
    }
    final authorization = Uri.tryParse(json['authorization_endpoint'] as String? ?? '');
    final token = Uri.tryParse(json['token_endpoint'] as String? ?? '');
    if (authorization == null || token == null) {
      throw const ApiException(
        code: 'internal_error',
        message: '登录服务配置异常，请检查 OIDC Issuer 设置',
      );
    }
    final endpoints = OidcEndpoints(authorization: authorization, token: token);
    _discoveryCache[issuer] = endpoints;
    return endpoints;
  }

  /// High-entropy PKCE code_verifier (RFC 7636 §4.1): 32 random bytes,
  /// base64url without padding → 43 characters from the allowed alphabet.
  String createVerifier() =>
      base64UrlEncode(_randomBytes(32)).replaceAll('=', '');

  /// S256 code_challenge (RFC 7636 §4.2): base64url(SHA256(verifier)).
  String createChallenge(String verifier) =>
      base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', '');

  /// Anti-CSRF state token for one authorization round trip.
  String createState() => base64UrlEncode(_randomBytes(16)).replaceAll('=', '');

  Uri authorizeUrl({
    required OidcEndpoints endpoints,
    required String clientId,
    required String redirectUri,
    required String scopes,
    required String state,
    required String codeChallenge,
  }) {
    return endpoints.authorization.replace(
      queryParameters: {
        ...endpoints.authorization.queryParameters,
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  /// Authorization-code + verifier → token set (public client: no secret).
  Future<OidcTokenResponse> exchangeCode({
    required OidcEndpoints endpoints,
    required String clientId,
    required String redirectUri,
    required String code,
    required String verifier,
  }) async {
    return _postToken(endpoints.token, {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': clientId,
      'code_verifier': verifier,
    });
  }

  /// Refresh-token grant; Keycloak may rotate the refresh token (absent
  /// field ⇒ keep the previous one).
  Future<OidcTokenResponse> refresh({
    required OidcEndpoints endpoints,
    required String clientId,
    required String refreshToken,
  }) async {
    return _postToken(endpoints.token, {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': clientId,
    });
  }

  Future<OidcTokenResponse> _postToken(
    Uri tokenEndpoint,
    Map<String, String> fields,
  ) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<Object?>(
        tokenEndpoint.toString(),
        data: fields,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['error'] is String) {
        // OAuth token error: { error, error_description? }.
        throw ApiException(
          code: 'unauthorized',
          message: '登录失败：${data['error_description'] ?? data['error']}',
          statusCode: e.response?.statusCode,
        );
      }
      throw const ApiException(
        code: 'network_error',
        message: '无法连接登录服务，请检查网络后重试',
      );
    }
    final json = response.data;
    final accessToken = json is Map<String, dynamic>
        ? json['access_token']
        : null;
    final expiresIn = json is Map<String, dynamic> ? json['expires_in'] : null;
    if (accessToken is! String ||
        accessToken.isEmpty ||
        expiresIn is! num) {
      throw const ApiException(
        code: 'internal_error',
        message: '登录服务返回异常，请重试',
      );
    }
    final refreshToken = json is Map<String, dynamic>
        ? json['refresh_token']
        : null;
    return OidcTokenResponse(
      accessToken: accessToken,
      expiresIn: expiresIn.toInt(),
      refreshToken: refreshToken is String && refreshToken.isNotEmpty
          ? refreshToken
          : null,
    );
  }

  List<int> _randomBytes(int count) =>
      List<int>.generate(count, (_) => _random.nextInt(256));

  /// `{issuer}/.well-known/openid-configuration` — appended to the issuer
  /// path (which has no trailing slash in practice, e.g. `…/realms/kb`).
  Uri _wellKnownUri(Uri issuer) {
    final path = issuer.path.endsWith('/') ? issuer.path : '${issuer.path}/';
    return issuer.replace(path: '$path.well-known/openid-configuration');
  }
}
