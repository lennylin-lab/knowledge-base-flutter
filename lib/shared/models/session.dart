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

/// One stored chat message, as returned inside a session detail
/// (backend `MessageRead`). Messages carry no sources — historical
/// assistant turns render markdown only.
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(unknownEnumValue: ChatMessageRole.user)
    required ChatMessageRole role,
    required String content,
    String? runId,
    required DateTime createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
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
