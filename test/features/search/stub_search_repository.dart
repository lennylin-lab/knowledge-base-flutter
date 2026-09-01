import 'package:knowledge_base_flutter/features/search/search_repository.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

/// In-memory [SearchRepository] for widget tests: the handler decides the
/// response, every call is recorded. Not a `_test.dart` file so several
/// test suites can share it.
class StubSearchRepository implements SearchRepository {
  StubSearchRepository({this.searchHandler});

  Future<SearchResponse> Function(String q, int limit, String? tag)?
  searchHandler;

  final List<({String q, int limit, String? tag})> searchCalls = [];

  @override
  Future<SearchResponse> search({
    required String q,
    int limit = SearchRepository.defaultLimit,
    String? tag,
  }) async {
    searchCalls.add((q: q, limit: limit, tag: tag));
    final handler = searchHandler;
    if (handler == null) {
      throw StateError('SearchRepository.search called without a handler');
    }
    return handler(q, limit, tag);
  }
}

/// One fused chunk hit fixture; per-leg ranks nullable like the wire format.
SearchHit searchHit({
  required String documentId,
  String title = '知识库设计笔记',
  List<String> tags = const ['flutter'],
  int chunkIndex = 2,
  String content = '混合检索使用 BM25 与向量的 RRF 融合',
  double score = 0.03125,
  int? esRank = 1,
  int? vectorRank,
}) {
  return SearchHit(
    documentId: documentId,
    documentTitle: title,
    documentTags: tags,
    chunkIndex: chunkIndex,
    content: content,
    score: score,
    esRank: esRank,
    vectorRank: vectorRank,
  );
}

/// Search response fixture; defaults to hybrid mode with one hit.
SearchResponse searchResponse({
  List<SearchHit>? items,
  SearchMode mode = SearchMode.hybrid,
}) {
  return SearchResponse(
    mode: mode,
    items: items ?? [searchHit(documentId: 'a')],
  );
}
