// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agents_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SummaryResult _$SummaryResultFromJson(Map<String, dynamic> json) =>
    _SummaryResult(
      documentId: json['document_id'] as String,
      summary: json['summary'] as String,
      model: json['model'] as String,
      latencyMs: (json['latency_ms'] as num).toDouble(),
    );

Map<String, dynamic> _$SummaryResultToJson(_SummaryResult instance) =>
    <String, dynamic>{
      'document_id': instance.documentId,
      'summary': instance.summary,
      'model': instance.model,
      'latency_ms': instance.latencyMs,
    };

_AssociationItem _$AssociationItemFromJson(Map<String, dynamic> json) =>
    _AssociationItem(
      documentId: json['document_id'] as String,
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      reason: json['reason'] as String,
      signal: json['signal'] as String,
    );

Map<String, dynamic> _$AssociationItemToJson(_AssociationItem instance) =>
    <String, dynamic>{
      'document_id': instance.documentId,
      'title': instance.title,
      'tags': instance.tags,
      'reason': instance.reason,
      'signal': instance.signal,
    };

_AssociationsResult _$AssociationsResultFromJson(Map<String, dynamic> json) =>
    _AssociationsResult(
      documentId: json['document_id'] as String,
      associations: (json['associations'] as List<dynamic>)
          .map((e) => AssociationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      model: json['model'] as String,
      latencyMs: (json['latency_ms'] as num).toDouble(),
    );

Map<String, dynamic> _$AssociationsResultToJson(_AssociationsResult instance) =>
    <String, dynamic>{
      'document_id': instance.documentId,
      'associations': instance.associations.map((e) => e.toJson()).toList(),
      'model': instance.model,
      'latency_ms': instance.latencyMs,
    };
