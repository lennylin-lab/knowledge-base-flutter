import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import 'api_exception.dart';

/// Decodes the unified error envelope
/// `{ "error": { "code", "message", "details" } }` from a response body.
///
/// Returns `null` when [body] does not carry a usable envelope (proxy/HTML
/// error page, network down, empty body) — callers must then synthesize a
/// fallback, never crash on parse.
ApiException? tryParseErrorEnvelope(Object? body) {
  Map<String, dynamic>? json;
  if (body is Map<String, dynamic>) {
    json = body;
  } else if (body is String && body.isNotEmpty) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } on FormatException {
      // Not JSON — fall through to the null return.
    }
  }
  if (json == null) return null;

  final error = json['error'];
  if (error is! Map<String, dynamic>) return null;
  final code = error['code'];
  final message = error['message'];
  if (code is! String || message is! String) return null;

  final details = error['details'];
  return ApiException(
    code: code,
    message: message,
    details: details is Map
        ? Map<String, dynamic>.from(details.cast<String, dynamic>())
        : const <String, dynamic>{},
  );
}

/// Normalizes any [DioException] into an [ApiException]:
/// - envelope present → its `code` / `message` / `details` (+ status code);
/// - non-envelope body with status ≥ 500 → `server_error`;
/// - anything else (unparseable body, connection/timeout failures) →
///   `network_error`.
ApiException mapDioException(DioException e) {
  final response = e.response;
  if (response != null) {
    final statusCode = response.statusCode;
    final parsed = tryParseErrorEnvelope(response.data);
    if (parsed != null) {
      return ApiException(
        code: parsed.code,
        message: parsed.message,
        details: parsed.details,
        statusCode: statusCode,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        code: 'server_error',
        message: '服务暂不可用，请稍后重试',
        statusCode: statusCode,
      );
    }
    return ApiException(
      code: 'network_error',
      message: '网络连接异常，请检查网络后重试',
      statusCode: statusCode,
    );
  }
  return switch (e.type) {
    DioExceptionType.cancel => const ApiException(
      code: 'cancelled',
      message: '请求已取消',
    ),
    _ => const ApiException(
      code: 'network_error',
      message: '网络连接异常，请检查网络后重试',
    ),
  };
}

/// Unwraps any thrown error into an [ApiException] — repositories use this
/// as the single catch-and-normalize step before letting the error propagate
/// into `AsyncValue`.
ApiException toApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return inner;
    return mapDioException(error);
  }
  return const ApiException(code: 'internal_error', message: '发生未知错误');
}

/// Resolves an access token lazily: normal requests use the cached-if-valid
/// token, the 401-retry path forces a refresh. Null ⇒ no Authorization
/// header (unauthenticated / compat mode).
typedef TokenResolver = Future<String?> Function();

/// The app's configured HTTP entry point: a [Dio] instance with sane
/// timeouts and interceptors that (a) attach the OIDC bearer token and
/// retry once after a forced refresh on 401, and (b) decode every error
/// into [ApiException] (attached to `DioException.error`) in one place.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    Dio? dio,
    TokenResolver? tokenResolver,
    TokenResolver? refreshResolver,
  }) : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 300,
            ),
          ) {
    // Auth first (on both sides), so a resolved 401 retry never reaches the
    // envelope mapper and envelope enrichment happens after auth decisions.
    if (tokenResolver != null) {
      this.dio.interceptors.add(_authInterceptor(tokenResolver, refreshResolver));
    }
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Keep the DioException shape (dio's public API throws those) but
          // attach the decoded envelope so `toApiException` can unwrap it.
          handler.next(error.copyWith(error: mapDioException(error)));
        },
      ),
    );
  }

  Interceptor _authInterceptor(
    TokenResolver tokenResolver,
    TokenResolver? refreshResolver,
  ) {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenResolver();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final requestOptions = error.requestOptions;
        final alreadyRetried = requestOptions.extra['kbAuthRetried'] == true;
        if (error.response?.statusCode != 401 ||
            alreadyRetried ||
            refreshResolver == null) {
          return handler.next(error);
        }
        final token = await refreshResolver();
        if (token == null) {
          // Refresh failed (session cleared) — surface the original 401.
          return handler.next(error);
        }
        try {
          requestOptions.extra['kbAuthRetried'] = true;
          requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await dio.fetch<dynamic>(requestOptions);
          handler.resolve(response);
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    );
  }

  final String baseUrl;
  final Dio dio;

  void close({bool force = false}) => dio.close(force: force);
}

/// App-wide API client; rebuilt (via `ref.watch`) whenever the configured
/// base URL changes.
///
/// The auth resolvers are only wired when OIDC is enabled (compat mode
/// keeps the client byte-for-byte headerless). They `ref.read` the auth
/// controller per request — the client must NOT rebuild on auth state
/// changes, so `ref.watch` stays away from the controller here.
final apiClientProvider = Provider<ApiClient>((ref) {
  final enabled = ref.watch(authEnabledProvider);
  final client = ApiClient(
    baseUrl: ref.watch(appConfigProvider).baseUrl,
    tokenResolver: enabled
        ? () async => ref
              .read(authControllerProvider.notifier)
              .getValidAccessToken()
        : null,
    refreshResolver: enabled
        ? () async =>
              ref.read(authControllerProvider.notifier).refreshAccessToken()
        : null,
  );
  ref.onDispose(() => client.close());
  return client;
});
