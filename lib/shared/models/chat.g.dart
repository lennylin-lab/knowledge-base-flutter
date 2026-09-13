// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatRequest _$ChatRequestFromJson(Map<String, dynamic> json) => _ChatRequest(
  question: json['question'] as String,
  limit: (json['limit'] as num?)?.toInt() ?? 8,
  sessionId: json['session_id'] as String?,
);

Map<String, dynamic> _$ChatRequestToJson(_ChatRequest instance) =>
    <String, dynamic>{
      'question': instance.question,
      'limit': instance.limit,
      'session_id': ?instance.sessionId,
    };

_RunStarted _$RunStartedFromJson(Map<String, dynamic> json) => _RunStarted(
  runId: json['run_id'] as String,
  mode: $enumDecode(
    _$SearchModeEnumMap,
    json['mode'],
    unknownValue: SearchMode.bm25,
  ),
  sessionId: json['session_id'] as String?,
);

Map<String, dynamic> _$RunStartedToJson(_RunStarted instance) =>
    <String, dynamic>{
      'run_id': instance.runId,
      'mode': _$SearchModeEnumMap[instance.mode]!,
      'session_id': instance.sessionId,
    };

const _$SearchModeEnumMap = {
  SearchMode.hybrid: 'hybrid',
  SearchMode.bm25: 'bm25',
};

_SourcesEvent _$SourcesEventFromJson(Map<String, dynamic> json) =>
    _SourcesEvent(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SearchHit>[],
    );

Map<String, dynamic> _$SourcesEventToJson(_SourcesEvent instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

_AnswerDelta _$AnswerDeltaFromJson(Map<String, dynamic> json) =>
    _AnswerDelta(text: json['text'] as String);

Map<String, dynamic> _$AnswerDeltaToJson(_AnswerDelta instance) =>
    <String, dynamic>{'text': instance.text};

_ChatDone _$ChatDoneFromJson(Map<String, dynamic> json) => _ChatDone(
  runId: json['run_id'] as String,
  outcome: json['outcome'] as String? ?? 'success',
  toolCalls: (json['tool_calls'] as num?)?.toInt() ?? 0,
  latencyMs: (json['latency_ms'] as num?)?.toDouble() ?? 0,
  sessionId: json['session_id'] as String?,
);

Map<String, dynamic> _$ChatDoneToJson(_ChatDone instance) => <String, dynamic>{
  'run_id': instance.runId,
  'outcome': instance.outcome,
  'tool_calls': instance.toolCalls,
  'latency_ms': instance.latencyMs,
  'session_id': instance.sessionId,
};

_ChatStatusEvent _$ChatStatusEventFromJson(Map<String, dynamic> json) =>
    _ChatStatusEvent(
      phase: $enumDecode(
        _$ChatStatusPhaseEnumMap,
        json['phase'],
        unknownValue: ChatStatusPhase.generating,
      ),
    );

Map<String, dynamic> _$ChatStatusEventToJson(_ChatStatusEvent instance) =>
    <String, dynamic>{'phase': _$ChatStatusPhaseEnumMap[instance.phase]!};

const _$ChatStatusPhaseEnumMap = {
  ChatStatusPhase.rewritingQuery: 'rewriting_query',
  ChatStatusPhase.generating: 'generating',
};

_QueryRewrittenEvent _$QueryRewrittenEventFromJson(Map<String, dynamic> json) =>
    _QueryRewrittenEvent(
      original: json['original'] as String,
      rewritten: json['rewritten'] as String,
      applied: json['applied'] as bool? ?? true,
      changed: json['changed'] as bool? ?? true,
    );

Map<String, dynamic> _$QueryRewrittenEventToJson(
  _QueryRewrittenEvent instance,
) => <String, dynamic>{
  'original': instance.original,
  'rewritten': instance.rewritten,
  'applied': instance.applied,
  'changed': instance.changed,
};

_ToolCallStartedEvent _$ToolCallStartedEventFromJson(
  Map<String, dynamic> json,
) => _ToolCallStartedEvent(
  callId: json['call_id'] as String,
  toolName: json['tool_name'] as String,
  args: json['args'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$ToolCallStartedEventToJson(
  _ToolCallStartedEvent instance,
) => <String, dynamic>{
  'call_id': instance.callId,
  'tool_name': instance.toolName,
  'args': instance.args,
};

_ToolCallFinishedEvent _$ToolCallFinishedEventFromJson(
  Map<String, dynamic> json,
) => _ToolCallFinishedEvent(
  callId: json['call_id'] as String,
  toolName: json['tool_name'] as String,
  status: $enumDecode(
    _$ChatToolStatusEnumMap,
    json['status'],
    unknownValue: ChatToolStatus.success,
  ),
  latencyMs: (json['latency_ms'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$ToolCallFinishedEventToJson(
  _ToolCallFinishedEvent instance,
) => <String, dynamic>{
  'call_id': instance.callId,
  'tool_name': instance.toolName,
  'status': _$ChatToolStatusEnumMap[instance.status]!,
  'latency_ms': instance.latencyMs,
};

const _$ChatToolStatusEnumMap = {
  ChatToolStatus.success: 'success',
  ChatToolStatus.failed: 'failed',
};

_ChatErrorEvent _$ChatErrorEventFromJson(Map<String, dynamic> json) =>
    _ChatErrorEvent(
      code: json['code'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$ChatErrorEventToJson(_ChatErrorEvent instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};
