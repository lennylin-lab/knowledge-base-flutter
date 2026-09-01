import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

/// The `error` object inside the unified REST error envelope.
@freezed
abstract class ApiError with _$ApiError {
  const ApiError._();

  const factory ApiError({
    required String code,
    required String message,
    @Default(<String, dynamic>{}) Map<String, dynamic> details,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}

/// Every non-2xx REST response body:
/// `{ "error": { "code": ..., "message": ..., "details": {...} } }`.
///
/// Decoding happens in one place (`core/network/api_client.dart`) into
/// [ApiException]; features and widgets only ever see the exception type.
@freezed
abstract class ApiErrorEnvelope with _$ApiErrorEnvelope {
  const ApiErrorEnvelope._();

  const factory ApiErrorEnvelope({required ApiError error}) =
      _ApiErrorEnvelope;

  factory ApiErrorEnvelope.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorEnvelopeFromJson(json);
}
