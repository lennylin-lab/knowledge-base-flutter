// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  role: $enumDecode(
    _$ChatMessageRoleEnumMap,
    json['role'],
    unknownValue: ChatMessageRole.user,
  ),
  content: json['content'] as String,
  runId: json['run_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': _$ChatMessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'run_id': instance.runId,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ChatMessageRoleEnumMap = {
  ChatMessageRole.user: 'user',
  ChatMessageRole.assistant: 'assistant',
};

_ChatSessionSummary _$ChatSessionSummaryFromJson(Map<String, dynamic> json) =>
    _ChatSessionSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ChatSessionSummaryToJson(_ChatSessionSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

_SessionDetail _$SessionDetailFromJson(Map<String, dynamic> json) =>
    _SessionDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ChatMessage>[],
    );

Map<String, dynamic> _$SessionDetailToJson(_SessionDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
    };

_SessionPage _$SessionPageFromJson(Map<String, dynamic> json) => _SessionPage(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ChatSessionSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChatSessionSummary>[],
  nextCursor: json['next_cursor'] as String?,
);

Map<String, dynamic> _$SessionPageToJson(_SessionPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
    };
