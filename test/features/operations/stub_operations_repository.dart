import 'package:knowledge_base_flutter/features/operations/operations_repository.dart';
import 'package:knowledge_base_flutter/shared/models/document.dart';
import 'package:knowledge_base_flutter/shared/models/operation.dart';

/// In-memory [OperationsRepository] for widget/provider tests: handlers
/// decide the responses, every call is recorded. Not a `_test.dart` file so
/// several test suites can share it (same pattern as the documents stub).
class StubOperationsRepository implements OperationsRepository {
  StubOperationsRepository({
    this.draftHandler,
    this.resumeHandler,
    this.applyHandler,
    this.operationHandler,
    this.operationsForDocumentHandler,
    this.createHandler,
  });

  Future<OperationDraftResult> Function({
    required String documentId,
    String? instruction,
  })?
  draftHandler;
  Future<OperationReadDetail> Function(String operationId)? resumeHandler;
  Future<ApplyResult> Function(String operationId)? applyHandler;
  Future<OperationReadDetail> Function(String operationId)? operationHandler;
  Future<List<OperationReadDetail>> Function(String documentId)?
  operationsForDocumentHandler;
  Future<OperationReadDetail> Function(OperationCreate payload)? createHandler;

  final List<({String documentId, String? instruction})> draftCalls = [];
  final List<String> resumeCalls = [];
  final List<String> applyCalls = [];
  final List<String> operationCalls = [];
  final List<String> operationsForDocumentCalls = [];
  final List<OperationCreate> createCalls = [];

  @override
  Future<OperationReadDetail> createOperation(OperationCreate payload) async {
    createCalls.add(payload);
    final handler = createHandler;
    if (handler == null) {
      throw StateError('OperationsRepository.create called without a handler');
    }
    return handler(payload);
  }

  @override
  Future<OperationDraftResult> draft({
    required String documentId,
    String? instruction,
  }) async {
    draftCalls.add((documentId: documentId, instruction: instruction));
    final handler = draftHandler;
    if (handler == null) {
      throw StateError('OperationsRepository.draft called without a handler');
    }
    return handler(documentId: documentId, instruction: instruction);
  }

  @override
  Future<OperationReadDetail> operation(String operationId) async {
    operationCalls.add(operationId);
    final handler = operationHandler;
    if (handler == null) {
      throw StateError(
        'OperationsRepository.operation called without a handler',
      );
    }
    return handler(operationId);
  }

  @override
  Future<List<OperationReadDetail>> operationsForDocument(
    String documentId,
  ) async {
    operationsForDocumentCalls.add(documentId);
    final handler = operationsForDocumentHandler;
    if (handler == null) {
      throw StateError(
        'OperationsRepository.operationsForDocument called without a handler',
      );
    }
    return handler(documentId);
  }

  @override
  Future<OperationReadDetail> resume(
    String operationId, {
    DraftContent? draft,
  }) async {
    resumeCalls.add(operationId);
    final handler = resumeHandler;
    if (handler == null) {
      throw StateError('OperationsRepository.resume called without a handler');
    }
    return handler(operationId);
  }

  @override
  Future<ApplyResult> apply(
    String operationId, {
    String? expectedBaseDocumentVersion,
  }) async {
    applyCalls.add(operationId);
    final handler = applyHandler;
    if (handler == null) {
      throw StateError('OperationsRepository.apply called without a handler');
    }
    return handler(operationId);
  }
}

/// Operation fixture; [state] and the optional draft/error/result are the
/// interesting axes for the writing workflow tests.
OperationReadDetail operationFixture({
  String id = 'op-1',
  String documentId = 'doc-1',
  OperationState state = OperationState.completed,
  DraftContent? draft,
  Map<String, dynamic>? error,
  Map<String, dynamic>? result,
  String updatedAt = '2026-09-16T08:00:05Z',
}) {
  return OperationReadDetail(
    id: id,
    documentId: documentId,
    baseDocumentVersion: '2026-08-31T12:30:00Z',
    state: state,
    createdAt: '2026-09-16T08:00:00Z',
    updatedAt: updatedAt,
    draft: draft,
    error: error,
    result: result,
  );
}

/// A completed operation carrying a draft with YAML front matter (that is
/// where title/tags derive at apply — the display strips it).
OperationReadDetail completedDraftOperation({
  String id = 'op-1',
  String content = '---\ntitle: 星际旅行草稿\n---\n\n续写正文第一段。\n\n续写正文第二段。',
  String? title = '星际旅行草稿',
}) {
  return operationFixture(
    id: id,
    state: OperationState.completed,
    draft: DraftContent(content: content, title: title),
  );
}

/// The streamed draft result for [id] — the lightweight shape
/// `OperationsRepository.draft` resolves to, with the same default draft as
/// [completedDraftOperation] so widget assertions hold for both paths.
OperationDraftResult completedDraftResult({
  String id = 'op-1',
  String content = '---\ntitle: 星际旅行草稿\n---\n\n续写正文第一段。\n\n续写正文第二段。',
  String? title = '星际旅行草稿',
}) {
  return OperationDraftResult(
    operationId: id,
    state: OperationState.completed,
    draft: DraftContent(content: content, title: title),
  );
}

/// The apply response for [operation]: applied operation + revision + the
/// mutated document (indexing restarted).
ApplyResult applyResultFor(OperationReadDetail operation) {
  final applied = operation.copyWith(
    state: OperationState.applied,
    result: {'revision_id': 'rev-1'},
  );
  return ApplyResult(
    operation: applied,
    revision: RevisionRead(
      id: 'rev-1',
      documentId: operation.documentId ?? 'doc-1',
      operationId: operation.id,
      title: '应用后的标题',
      tags: const ['flutter'],
      createdAt: '2026-09-16T08:01:00Z',
    ),
    document: DocumentInResult(
      id: operation.documentId ?? 'doc-1',
      title: '应用后的标题',
      tags: const ['flutter'],
      indexStatus: IndexStatus.pending,
      updatedAt: '2026-09-16T08:01:00Z',
    ),
  );
}
