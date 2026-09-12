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

_ChatErrorEvent _$ChatErrorEventFromJson(Map<String, dynamic> json) =>
    _ChatErrorEvent(
      code: json['code'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$ChatErrorEventToJson(_ChatErrorEvent instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};
