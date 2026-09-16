// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DraftContent _$DraftContentFromJson(Map<String, dynamic> json) =>
    _DraftContent(
      content: json['content'] as String,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$DraftContentToJson(_DraftContent instance) =>
    <String, dynamic>{'content': instance.content, 'title': instance.title};

_OperationCreate _$OperationCreateFromJson(Map<String, dynamic> json) =>
    _OperationCreate(
      documentId: json['document_id'] as String,
      baseDocumentVersion: json['base_document_version'] as String,
      draft: DraftContent.fromJson(json['draft'] as Map<String, dynamic>),
      idempotencyKey: json['idempotency_key'] as String?,
    );

Map<String, dynamic> _$OperationCreateToJson(_OperationCreate instance) =>
    <String, dynamic>{
      'document_id': instance.documentId,
      'base_document_version': instance.baseDocumentVersion,
      'draft': instance.draft.toJson(),
      'idempotency_key': instance.idempotencyKey,
    };

_OperationReadDetail _$OperationReadDetailFromJson(Map<String, dynamic> json) =>
    _OperationReadDetail(
      id: json['id'] as String,
      documentId: json['document_id'] as String?,
      baseDocumentVersion: json['base_document_version'] as String?,
      state: $enumDecode(
        _$OperationStateEnumMap,
        json['state'],
        unknownValue: OperationState.failed,
      ),
      idempotencyKey: json['idempotency_key'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      draft: json['draft'] == null
          ? null
          : DraftContent.fromJson(json['draft'] as Map<String, dynamic>),
      result: json['result'] as Map<String, dynamic>?,
      error: json['error'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$OperationReadDetailToJson(
  _OperationReadDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'document_id': instance.documentId,
  'base_document_version': instance.baseDocumentVersion,
  'state': _$OperationStateEnumMap[instance.state]!,
  'idempotency_key': instance.idempotencyKey,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'draft': instance.draft?.toJson(),
  'result': instance.result,
  'error': instance.error,
};

const _$OperationStateEnumMap = {
  OperationState.running: 'running',
  OperationState.completed: 'completed',
  OperationState.interrupted: 'interrupted',
  OperationState.failed: 'failed',
  OperationState.applied: 'applied',
};

_OperationTransition _$OperationTransitionFromJson(Map<String, dynamic> json) =>
    _OperationTransition(
      draft: json['draft'] == null
          ? null
          : DraftContent.fromJson(json['draft'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OperationTransitionToJson(
  _OperationTransition instance,
) => <String, dynamic>{'draft': ?instance.draft?.toJson()};

_ApplyRequest _$ApplyRequestFromJson(Map<String, dynamic> json) =>
    _ApplyRequest(
      expectedBaseDocumentVersion:
          json['expected_base_document_version'] as String?,
    );

Map<String, dynamic> _$ApplyRequestToJson(_ApplyRequest instance) =>
    <String, dynamic>{
      'expected_base_document_version': ?instance.expectedBaseDocumentVersion,
    };

_RevisionRead _$RevisionReadFromJson(Map<String, dynamic> json) =>
    _RevisionRead(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      operationId: json['operation_id'] as String?,
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$RevisionReadToJson(_RevisionRead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'document_id': instance.documentId,
      'operation_id': instance.operationId,
      'title': instance.title,
      'tags': instance.tags,
      'created_at': instance.createdAt,
    };

_DocumentInResult _$DocumentInResultFromJson(Map<String, dynamic> json) =>
    _DocumentInResult(
      id: json['id'] as String,
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      indexStatus: $enumDecode(
        _$IndexStatusEnumMap,
        json['index_status'],
        unknownValue: IndexStatus.failed,
      ),
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$DocumentInResultToJson(_DocumentInResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'tags': instance.tags,
      'index_status': _$IndexStatusEnumMap[instance.indexStatus]!,
      'updated_at': instance.updatedAt,
    };

const _$IndexStatusEnumMap = {
  IndexStatus.pending: 'pending',
  IndexStatus.done: 'done',
  IndexStatus.failed: 'failed',
};

_ApplyResult _$ApplyResultFromJson(Map<String, dynamic> json) => _ApplyResult(
  operation: OperationReadDetail.fromJson(
    json['operation'] as Map<String, dynamic>,
  ),
  revision: RevisionRead.fromJson(json['revision'] as Map<String, dynamic>),
  document: DocumentInResult.fromJson(json['document'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ApplyResultToJson(_ApplyResult instance) =>
    <String, dynamic>{
      'operation': instance.operation.toJson(),
      'revision': instance.revision.toJson(),
      'document': instance.document.toJson(),
    };
