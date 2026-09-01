/// The unified error type features and widgets ever see (error-handling spec).
///
/// Carries the backend envelope's `code` / `message` / `details` plus the HTTP
/// [statusCode] when one exists. Synthesized codes (no envelope on the wire):
/// `network_error`, `server_error`, `cancelled`, `internal_error`.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  bool get isNetworkError => code == 'network_error';

  bool get isNotFound => code == 'not_found';

  @override
  String toString() => 'ApiException($statusCode $code: $message)';
}
