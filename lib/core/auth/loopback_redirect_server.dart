import 'dart:async';
import 'dart:io';

/// Loopback HTTP listener for the native OIDC round trip (RFC 8252 §7.6):
/// the system browser navigates to the redirect URI on `127.0.0.1` /
/// `localhost` and this server captures the query parameters, replies with
/// a small completion page, and hands the redirect URI to the caller.
///
/// The browser — not the app — talks to loopback, so Android's cleartext
/// policy is not involved. Loopback binds never trigger the Windows
/// firewall prompt.
class LoopbackRedirectServer {
  LoopbackRedirectServer._(this._server, this._path);

  static Future<LoopbackRedirectServer> bind(Uri redirectUri) async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      redirectUri.port,
    );
    return LoopbackRedirectServer._(server, redirectUri.path);
  }

  final HttpServer _server;
  final String _path;

  /// Resolves with the request URI of the first redirect (carrying `code`
  /// and `state`, or an OAuth `error` query parameter).
  ///
  /// Requests for anything but the redirect path (favicon pings) are
  /// answered 404 and skipped. Fails with [TimeoutException] after
  /// [timeout]; the caller must always [close] the server.
  Future<Uri> wait({Duration timeout = const Duration(minutes: 5)}) async {
    try {
      await for (final request in _server.timeout(timeout)) {
        if (request.uri.path != _path) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }
        request.response.headers.contentType = ContentType.html;
        request.response.write(
          '<!doctype html><html lang="zh"><meta charset="utf-8">'
          '<title>登录完成</title>'
          '<body style="font-family:system-ui;display:flex;align-items:center;'
          'justify-content:center;height:100vh;margin:0">'
          '<div style="text-align:center"><h2>登录完成</h2>'
          '<p>请返回知识库应用继续使用。</p></div></body></html>',
        );
        await request.response.close();
        return request.uri;
      }
      // The only way out of the loop besides a request is the server being
      // closed under us (cancel path).
      throw const ApiExceptionLoginCancelled();
    } on TimeoutException {
      rethrow;
    }
  }

  Future<void> close() => _server.close(force: true);
}

/// Marker for the listener dying before a redirect arrived (server closed,
/// e.g. sign-in torn down) — distinct from the browser timeout.
class ApiExceptionLoginCancelled implements Exception {
  const ApiExceptionLoginCancelled();
}
