// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => _ApiError(
  code: json['code'] as String,
  message: json['message'] as String,
  details:
      json['details'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$ApiErrorToJson(_ApiError instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'details': instance.details,
};

_ApiErrorEnvelope _$ApiErrorEnvelopeFromJson(Map<String, dynamic> json) =>
    _ApiErrorEnvelope(
      error: ApiError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ApiErrorEnvelopeToJson(_ApiErrorEnvelope instance) =>
    <String, dynamic>{'error': instance.error.toJson()};
