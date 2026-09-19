import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// Author of one stored chat message (backend `MessageRole`).
enum ChatMessageRole {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
}

/// Slim citation entry on a stored assistant message (backend `SourceRef`).
/// List position IS the citation number (`sources[0]` = `[1]`) — no index
/// field. Deliberately excludes `content`/`score` retrieval internals.
@freezed
abstract class SourceRef with _$SourceRef {
  const factory SourceRef({
    required String documentId,
    required String documentTitle,
    @Default(<String>[]) List<String> documentTags,
    @Default(0) int chunkIndex,
  }) = _SourceRef;

  factory SourceRef.fromJson(Map<String, dynamic> json) =>
      _$SourceRefFromJson(json);
}

/// One stored chat message, as returned inside a session detail
/// (backend `MessageRead`). [sources] is null for user / no-retrieval
/// messages — normalized to an empty list; history replay maps `[n]` to
/// `sources[n-1].documentId`.
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(unknownEnumValue: ChatMessageRole.user)
    required ChatMessageRole role,
    required String content,
    String? runId,
    required DateTime createdAt,
    @JsonKey(includeIfNull: false) @Default(<SourceRef>[]) List<SourceRef> sources,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

/// One page of the session-detail message history (backend `MessagePage`),
/// returned by `GET /sessions/{id}` when `limit`/`cursor` is given. Items
/// are chronological; the first page holds the NEWEST messages;
/// [nextCursor] points at strictly older messages and is null when
/// exhausted.
@freezed
abstract class MessagePage with _$MessagePage {
  const factory MessagePage({
    @Default(<ChatMessage>[]) List<ChatMessage> items,
    String? nextCursor,
  }) = _MessagePage;

  factory MessagePage.fromJson(Map<String, dynamic> json) =>
      _$MessagePageFromJson(json);
}

/// Chat session as returned in lists — messages excluded
/// (backend `SessionRead`).
@freezed
abstract class ChatSessionSummary with _$ChatSessionSummary {
  const factory ChatSessionSummary({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ChatSessionSummary;

  factory ChatSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionSummaryFromJson(json);
}

/// Single-session view: summary plus its messages in chronological order
/// (backend `SessionDetail`).
@freezed
abstract class SessionDetail with _$SessionDetail {
  const factory SessionDetail({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<ChatMessage>[]) List<ChatMessage> messages,
  }) = _SessionDetail;

  factory SessionDetail.fromJson(Map<String, dynamic> json) =>
      _$SessionDetailFromJson(json);
}

/// One page of the keyset-paginated session list (backend `SessionPage`).
/// A `null` [nextCursor] marks the end of the list.
@freezed
abstract class SessionPage with _$SessionPage {
  const factory SessionPage({
    @Default(<ChatSessionSummary>[]) List<ChatSessionSummary> items,
    String? nextCursor,
  }) = _SessionPage;

  factory SessionPage.fromJson(Map<String, dynamic> json) =>
      _$SessionPageFromJson(json);
}
