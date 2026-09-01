import 'package:freezed_annotation/freezed_annotation.dart';

part 'search.freezed.dart';
part 'search.g.dart';

/// Retrieval mode backing a search run (or a chat run's `run_started` event).
///
/// Wire values are the member names (`hybrid` / `bm25`); fields decode with
/// `@JsonKey(unknownEnumValue: SearchMode.bm25)` so an unknown wire value
/// never crashes parsing (type-safety spec).
enum SearchMode { hybrid, bm25 }

/// One fused chunk hit with its owning document's metadata.
///
/// `score` is the RRF fused score. The per-leg ranks are 1-based and `null`
/// when that leg did not return the chunk — both [esRank] and [vectorRank]
/// are nullable on the wire (backend `SearchHit` schema).
@freezed
abstract class SearchHit with _$SearchHit {
  const factory SearchHit({
    required String documentId,
    required String documentTitle,
    required List<String> documentTags,
    required int chunkIndex,
    required String content,
    required double score,
    int? esRank,
    int? vectorRank,
  }) = _SearchHit;

  factory SearchHit.fromJson(Map<String, dynamic> json) =>
      _$SearchHitFromJson(json);
}

/// Search result: what produced it ([mode]) and the top hits.
@freezed
abstract class SearchResponse with _$SearchResponse {
  const factory SearchResponse({
    @JsonKey(unknownEnumValue: SearchMode.bm25)
    required SearchMode mode,
    required List<SearchHit> items,
  }) = _SearchResponse;

  factory SearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseFromJson(json);
}
