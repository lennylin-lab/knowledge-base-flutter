import 'package:freezed_annotation/freezed_annotation.dart';

import 'search.dart';

part 'chat.freezed.dart';
part 'chat.g.dart';

/// One stateless chat turn: a question plus retrieval sizing.
///
/// [limit] is clamped to 1–20 (default 8) by the caller before sending —
/// out-of-range values are rejected server-side with 422.
@freezed
abstract class ChatRequest with _$ChatRequest {
  const factory ChatRequest({
    required String question,
    @Default(8) int limit,
  }) = _ChatRequest;

  factory ChatRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatRequestFromJson(json);
}

/// Everything `POST /api/v1/chat` can stream, in contract order.
///
/// The events are discriminated by the SSE `event:` line (not by a JSON
/// field). Order guarantee: `run_started` → `sources*` → `answer_delta*` →
/// `done`, or a terminal `error` at any point; the stream closes right after
/// a terminal event. `sources` may repeat — consumers append to the
/// accumulated list, and citation `[n]` indexes into that accumulation.
sealed class ChatEvent {
  const ChatEvent();
}

/// First event of every run; `mode` is the configured retrieval mode.
@freezed
abstract class RunStarted extends ChatEvent with _$RunStarted {
  const RunStarted._();

  const factory RunStarted({
    required String runId,
    @JsonKey(unknownEnumValue: SearchMode.bm25)
    required SearchMode mode,
  }) = _RunStarted;

  factory RunStarted.fromJson(Map<String, dynamic> json) =>
      _$RunStartedFromJson(json);
}

/// One retrieval batch, flushed as soon as the tool call returned.
@freezed
abstract class SourcesEvent extends ChatEvent with _$SourcesEvent {
  const SourcesEvent._();

  const factory SourcesEvent({
    @Default(<SearchHit>[]) List<SearchHit> items,
  }) = _SourcesEvent;

  factory SourcesEvent.fromJson(Map<String, dynamic> json) =>
      _$SourcesEventFromJson(json);
}

/// One streamed answer fragment; concatenate [text] verbatim — never
/// translate or trim answer text.
@freezed
abstract class AnswerDelta extends ChatEvent with _$AnswerDelta {
  const AnswerDelta._();

  const factory AnswerDelta({required String text}) = _AnswerDelta;

  factory AnswerDelta.fromJson(Map<String, dynamic> json) =>
      _$AnswerDeltaFromJson(json);
}

/// Terminal success event.
@freezed
abstract class ChatDone extends ChatEvent with _$ChatDone {
  const ChatDone._();

  const factory ChatDone({
    required String runId,
    @Default('success') String outcome,
    @Default(0) int toolCalls,
    @Default(0) double latencyMs,
  }) = _ChatDone;

  factory ChatDone.fromJson(Map<String, dynamic> json) =>
      _$ChatDoneFromJson(json);
}

/// Terminal failure event; the stream closes right after it.
///
/// Payload mirrors the REST error envelope's `{code, message}` pair — the
/// HTTP status may already be 200 when this arrives.
@freezed
abstract class ChatErrorEvent extends ChatEvent with _$ChatErrorEvent {
  const ChatErrorEvent._();

  const factory ChatErrorEvent({
    required String code,
    required String message,
  }) = _ChatErrorEvent;

  factory ChatErrorEvent.fromJson(Map<String, dynamic> json) =>
      _$ChatErrorEventFromJson(json);
}
