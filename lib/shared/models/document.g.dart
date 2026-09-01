// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentCreate _$DocumentCreateFromJson(Map<String, dynamic> json) =>
    _DocumentCreate(
      content: json['content'] as String,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$DocumentCreateToJson(_DocumentCreate instance) =>
    <String, dynamic>{'content': instance.content, 'title': instance.title};

_DocumentUpdate _$DocumentUpdateFromJson(Map<String, dynamic> json) =>
    _DocumentUpdate(
      content: json['content'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$DocumentUpdateToJson(_DocumentUpdate instance) =>
    <String, dynamic>{'content': instance.content, 'title': instance.title};

_DocumentRead _$DocumentReadFromJson(Map<String, dynamic> json) =>
    _DocumentRead(
      id: json['id'] as String,
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      indexStatus: $enumDecode(
        _$IndexStatusEnumMap,
        json['index_status'],
        unknownValue: IndexStatus.failed,
      ),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$DocumentReadToJson(_DocumentRead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'tags': instance.tags,
      'index_status': _$IndexStatusEnumMap[instance.indexStatus]!,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

const _$IndexStatusEnumMap = {
  IndexStatus.pending: 'pending',
  IndexStatus.done: 'done',
  IndexStatus.failed: 'failed',
};

_DocumentReadDetail _$DocumentReadDetailFromJson(Map<String, dynamic> json) =>
    _DocumentReadDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      indexStatus: $enumDecode(
        _$IndexStatusEnumMap,
        json['index_status'],
        unknownValue: IndexStatus.failed,
      ),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$DocumentReadDetailToJson(_DocumentReadDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'tags': instance.tags,
      'index_status': _$IndexStatusEnumMap[instance.indexStatus]!,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'content': instance.content,
    };

_DocumentPage _$DocumentPageFromJson(Map<String, dynamic> json) =>
    _DocumentPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => DocumentRead.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );

Map<String, dynamic> _$DocumentPageToJson(_DocumentPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
    };
