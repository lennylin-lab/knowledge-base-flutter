// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchHit _$SearchHitFromJson(Map<String, dynamic> json) => _SearchHit(
  documentId: json['document_id'] as String,
  documentTitle: json['document_title'] as String,
  documentTags: (json['document_tags'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  chunkIndex: (json['chunk_index'] as num).toInt(),
  content: json['content'] as String,
  score: (json['score'] as num).toDouble(),
  esRank: (json['es_rank'] as num?)?.toInt(),
  vectorRank: (json['vector_rank'] as num?)?.toInt(),
);

Map<String, dynamic> _$SearchHitToJson(_SearchHit instance) =>
    <String, dynamic>{
      'document_id': instance.documentId,
      'document_title': instance.documentTitle,
      'document_tags': instance.documentTags,
      'chunk_index': instance.chunkIndex,
      'content': instance.content,
      'score': instance.score,
      'es_rank': instance.esRank,
      'vector_rank': instance.vectorRank,
    };

_SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) =>
    _SearchResponse(
      mode: $enumDecode(
        _$SearchModeEnumMap,
        json['mode'],
        unknownValue: SearchMode.bm25,
      ),
      items: (json['items'] as List<dynamic>)
          .map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchResponseToJson(_SearchResponse instance) =>
    <String, dynamic>{
      'mode': _$SearchModeEnumMap[instance.mode]!,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$SearchModeEnumMap = {
  SearchMode.hybrid: 'hybrid',
  SearchMode.bm25: 'bm25',
};
