import 'package:knowledge_base_flutter/features/documents/documents_repository.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';

/// In-memory [DocumentsRepository] for widget tests: handlers decide the
/// responses, every call is recorded. Not a `_test.dart` file so several
/// test suites can share it.
class StubDocumentsRepository implements DocumentsRepository {
  StubDocumentsRepository({
    this.listHandler,
    this.getHandler,
    this.createHandler,
    this.updateHandler,
    this.deleteHandler,
  });

  Future<DocumentPage> Function(String? cursor, int limit, String? tag)?
  listHandler;
  Future<DocumentReadDetail> Function(String id)? getHandler;
  Future<DocumentRead> Function(DocumentCreate payload)? createHandler;
  Future<DocumentRead> Function(String id, DocumentUpdate payload)?
  updateHandler;
  Future<void> Function(String id)? deleteHandler;

  final List<({String? cursor, int limit, String? tag})> listCalls = [];
  final List<String> getCalls = [];
  final List<DocumentCreate> createCalls = [];
  final List<({String id, DocumentUpdate payload})> updateCalls = [];
  final List<String> deleteCalls = [];

  @override
  Future<DocumentPage> list({
    String? cursor,
    int limit = DocumentsRepository.defaultLimit,
    String? tag,
  }) async {
    listCalls.add((cursor: cursor, limit: limit, tag: tag));
    final handler = listHandler;
    if (handler == null) {
      throw StateError('DocumentsRepository.list called without a handler');
    }
    return handler(cursor, limit, tag);
  }

  @override
  Future<DocumentReadDetail> get(String id) async {
    getCalls.add(id);
    final handler = getHandler;
    if (handler == null) {
      throw StateError('DocumentsRepository.get called without a handler');
    }
    return handler(id);
  }

  @override
  Future<DocumentRead> create(DocumentCreate payload) async {
    createCalls.add(payload);
    final handler = createHandler;
    if (handler == null) {
      throw StateError('DocumentsRepository.create called without a handler');
    }
    return handler(payload);
  }

  @override
  Future<DocumentRead> update(String id, DocumentUpdate payload) async {
    updateCalls.add((id: id, payload: payload));
    final handler = updateHandler;
    if (handler == null) {
      throw StateError('DocumentsRepository.update called without a handler');
    }
    return handler(id, payload);
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls.add(id);
    final handler = deleteHandler;
    if (handler == null) {
      throw StateError('DocumentsRepository.delete called without a handler');
    }
    return handler(id);
  }
}

/// List-item fixture; timestamps are fixed ISO strings.
DocumentRead documentRead({
  required String id,
  String? title,
  IndexStatus indexStatus = IndexStatus.done,
  List<String> tags = const [],
}) {
  return DocumentRead(
    id: id,
    title: title ?? '文档 $id',
    tags: tags,
    indexStatus: indexStatus,
    createdAt: '2026-08-30T08:00:00Z',
    updatedAt: '2026-08-31T08:00:00Z',
  );
}

/// Detail fixture projecting [base] plus a `content` field.
DocumentReadDetail documentReadDetail(
  DocumentRead base, {
  String content = '# 内容',
}) {
  return DocumentReadDetail(
    id: base.id,
    title: base.title,
    tags: base.tags,
    indexStatus: base.indexStatus,
    createdAt: base.createdAt,
    updatedAt: base.updatedAt,
    content: content,
  );
}
