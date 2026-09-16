// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agents_stream.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentRunStarted _$AgentRunStartedFromJson(Map<String, dynamic> json) =>
    _AgentRunStarted(
      runId: json['run_id'] as String,
      kind: json['kind'] as String,
      documentId: json['document_id'] as String,
    );

Map<String, dynamic> _$AgentRunStartedToJson(_AgentRunStarted instance) =>
    <String, dynamic>{
      'run_id': instance.runId,
      'kind': instance.kind,
      'document_id': instance.documentId,
    };

_SummaryProgress _$SummaryProgressFromJson(Map<String, dynamic> json) =>
    _SummaryProgress(
      phase: json['phase'] as String,
      passIndex: (json['pass_index'] as num).toInt(),
      passesTotal: (json['passes_total'] as num).toInt(),
    );

Map<String, dynamic> _$SummaryProgressToJson(_SummaryProgress instance) =>
    <String, dynamic>{
      'phase': instance.phase,
      'pass_index': instance.passIndex,
      'passes_total': instance.passesTotal,
    };

_AgentDraftEvent _$AgentDraftEventFromJson(Map<String, dynamic> json) =>
    _AgentDraftEvent(
      operationId: json['operation_id'] as String,
      state: json['state'] as String,
      content: json['content'] as String,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$AgentDraftEventToJson(_AgentDraftEvent instance) =>
    <String, dynamic>{
      'operation_id': instance.operationId,
      'state': instance.state,
      'content': instance.content,
      'title': instance.title,
    };

_AgentErrorEvent _$AgentErrorEventFromJson(Map<String, dynamic> json) =>
    _AgentErrorEvent(
      code: json['code'] as String,
      message: json['message'] as String,
      statusCode: (json['status_code'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AgentErrorEventToJson(_AgentErrorEvent instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'status_code': ?instance.statusCode,
    };
