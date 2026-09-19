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

_AgentSummaryDeltaEvent _$AgentSummaryDeltaEventFromJson(
  Map<String, dynamic> json,
) => _AgentSummaryDeltaEvent(
  runId: json['run_id'] as String,
  text: json['text'] as String,
);

Map<String, dynamic> _$AgentSummaryDeltaEventToJson(
  _AgentSummaryDeltaEvent instance,
) => <String, dynamic>{'run_id': instance.runId, 'text': instance.text};

_AgentAssociationItemEvent _$AgentAssociationItemEventFromJson(
  Map<String, dynamic> json,
) => _AgentAssociationItemEvent(
  runId: json['run_id'] as String,
  position: (json['position'] as num).toInt(),
  documentId: json['document_id'] as String,
  title: json['title'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  reason: json['reason'] as String,
  signal: json['signal'] as String,
);

Map<String, dynamic> _$AgentAssociationItemEventToJson(
  _AgentAssociationItemEvent instance,
) => <String, dynamic>{
  'run_id': instance.runId,
  'position': instance.position,
  'document_id': instance.documentId,
  'title': instance.title,
  'tags': instance.tags,
  'reason': instance.reason,
  'signal': instance.signal,
};

_AgentDraftDeltaEvent _$AgentDraftDeltaEventFromJson(
  Map<String, dynamic> json,
) => _AgentDraftDeltaEvent(
  runId: json['run_id'] as String,
  delta: json['delta'] as String,
);

Map<String, dynamic> _$AgentDraftDeltaEventToJson(
  _AgentDraftDeltaEvent instance,
) => <String, dynamic>{'run_id': instance.runId, 'delta': instance.delta};

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
