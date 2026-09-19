import 'package:freezed_annotation/freezed_annotation.dart';

import 'agents_result.dart';

part 'agents_stream.freezed.dart';
part 'agents_stream.g.dart';

/// Events of the document-agent SSE streams served by
/// `POST /api/v1/documents/{id}/summary`, `/associations`, and
/// `POST /api/v1/operations/draft`
/// (backend `src/app/schemas/agent_stream.py`).
///
/// Event order: for the summary stream,
/// `run_started → summary_progress(map) → [summary_delta …] →
/// summary_progress(reduce) → summary → done` when the document is a single
/// chunk, and `run_started → summary_progress(map) … →
/// summary_progress(reduce) → [summary_delta …] → summary → done` when it
/// spans multiple chunks (the deltas stream during the user-visible pass —
/// single pass, or reduce); `run_started → [association_item …] →
/// associations → done` for the associations stream, and
/// `run_started → [draft_delta …] → draft → done`
/// for the writing stream — or a terminal `error` at any point after
/// HTTP 200 (the stream closes right after a terminal event). A cache hit
/// skips the progress, delta and item events entirely (zero deltas/items is
/// a legal shape the UI must cope with). Comments (`:` keep-alive frames)
/// and unknown event names carry no event and are ignored.
///
/// The result payloads reuse [SummaryResult] / [AssociationsResult]
/// unchanged — the server emits the exact fields of the old JSON bodies as
/// the `summary` / `associations` event data; the `draft` event carries the
/// flat [AgentDraftEvent] payload.
sealed class AgentStreamEvent {
  const AgentStreamEvent();
}

/// First event of every stream; [kind] is `"summary"`, `"associations"`, or
/// `"draft"` (kept as the raw wire string — informational, no branching
/// client-side).
@freezed
abstract class AgentRunStarted extends AgentStreamEvent with _$AgentRunStarted {
  const AgentRunStarted._();

  const factory AgentRunStarted({
    required String runId,
    required String kind,
    required String documentId,
  }) = _AgentRunStarted;

  factory AgentRunStarted.fromJson(Map<String, dynamic> json) =>
      _$AgentRunStartedFromJson(json);
}

/// One `summary_progress` event (summary streams only, informational).
///
/// [phase] is `"map_pass"` or `"reduce_pass"` on the wire — kept as the raw
/// string because an unknown future phase has no safe enum fallback (the UI
/// keeps its generic hint instead). [passIndex] is 1-based; the reduce pass
/// carries `pass_index == passes_total`. Even single-chunk documents emit
/// map(1/2) + reduce(2/2).
@freezed
abstract class SummaryProgress extends AgentStreamEvent with _$SummaryProgress {
  const SummaryProgress._();

  const factory SummaryProgress({
    required String phase,
    required int passIndex,
    required int passesTotal,
  }) = _SummaryProgress;

  factory SummaryProgress.fromJson(Map<String, dynamic> json) =>
      _$SummaryProgressFromJson(json);
}

/// One `summary_delta` event (summary streams only, non-terminal): a
/// verbatim **plain text** fragment of the summary, forwarded in provider
/// order with no duplication or omission — the chunks' concatenation equals
/// the final [AgentSummaryEvent]'s `summary` field exactly. Unlike
/// [AgentDraftDeltaEvent] the text is displayable as-is (no partial-JSON
/// extraction). A cache hit emits none — zero deltas is a legal shape and
/// the authoritative result still settles atomically with the `summary`
/// event; on `error` the accumulated text is simply discarded.
@freezed
abstract class AgentSummaryDeltaEvent extends AgentStreamEvent
    with _$AgentSummaryDeltaEvent {
  const AgentSummaryDeltaEvent._();

  const factory AgentSummaryDeltaEvent({
    required String runId,
    required String text,
  }) = _AgentSummaryDeltaEvent;

  factory AgentSummaryDeltaEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentSummaryDeltaEventFromJson(json);
}

/// One `association_item` event (associations streams only, non-terminal):
/// a single **final-state** confirmed association, 1-based [position],
/// streamed in final-list order (the concatenation equals the final
/// [AgentAssociationsEvent]'s list exactly). Every payload field mirrors
/// [AssociationItem]; [item] rebuilds that shared DTO so the UI renders
/// streamed items through the existing tile with zero adaptation. Cache
/// hits and empty-candidate runs emit none; the final `associations` event
/// remains the authoritative settle that replaces the incremental list; on
/// `error` the accumulated items are simply discarded.
@freezed
abstract class AgentAssociationItemEvent extends AgentStreamEvent
    with _$AgentAssociationItemEvent {
  const AgentAssociationItemEvent._();

  const factory AgentAssociationItemEvent({
    required String runId,
    required int position,
    required String documentId,
    required String title,
    required List<String> tags,
    required String reason,
    required String signal,
  }) = _AgentAssociationItemEvent;

  factory AgentAssociationItemEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentAssociationItemEventFromJson(json);

  /// The payload as the shared [AssociationItem] result DTO — the exact
  /// shape the association tiles already consume.
  AssociationItem get item => AssociationItem(
    documentId: documentId,
    title: title,
    tags: tags,
    reason: reason,
    signal: signal,
  );
}

/// The `summary` event — the run's result payload ([SummaryResult] flat,
/// identical to the pre-SSE JSON body).
final class AgentSummaryEvent extends AgentStreamEvent {
  const AgentSummaryEvent(this.result);

  final SummaryResult result;
}

/// The `associations` event — the run's result payload ([AssociationsResult]
/// flat, identical to the pre-SSE JSON body).
final class AgentAssociationsEvent extends AgentStreamEvent {
  const AgentAssociationsEvent(this.result);

  final AssociationsResult result;
}

/// One `draft_delta` event of the writing-agent stream
/// (`POST /api/v1/operations/draft`): a verbatim raw fragment of the
/// model's structured-output tool-call arguments, forwarded in provider
/// order with no duplication or omission — the chunks' concatenation equals
/// the final argument JSON exactly.
///
/// [delta] is **opaque display-only raw text**: the client never parses or
/// validates it (no incremental JSON handling, no result derivation from
/// the concatenation). The authoritative result still arrives atomically
/// with the terminal [AgentDraftEvent]; on `error` the accumulated
/// fragments are simply discarded.
@freezed
abstract class AgentDraftDeltaEvent extends AgentStreamEvent
    with _$AgentDraftDeltaEvent {
  const AgentDraftDeltaEvent._();

  const factory AgentDraftDeltaEvent({
    required String runId,
    required String delta,
  }) = _AgentDraftDeltaEvent;

  factory AgentDraftDeltaEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentDraftDeltaEventFromJson(json);
}

/// The `draft` event of the writing-agent stream
/// (`POST /api/v1/operations/draft`): the finished operation's draft,
/// emitted **flat** (`operation_id` / `state` / `content` / `title`) — the
/// authoritative result that follows any number of [AgentDraftDeltaEvent]
/// process fragments. The server commits the terminal operation state
/// BEFORE emitting, so a client that stops reading never sees a draft for
/// unpersisted work.
///
/// [state] stays the raw wire string (the literal `"completed"` today): a
/// received draft event always means "a draft arrived" and is presented as
/// reviewable — an unknown future value must not crash the parse (no
/// invented sentinels; the repository maps it defensively).
@freezed
abstract class AgentDraftEvent extends AgentStreamEvent with _$AgentDraftEvent {
  const AgentDraftEvent._();

  const factory AgentDraftEvent({
    required String operationId,
    required String state,
    required String content,
    String? title,
  }) = _AgentDraftEvent;

  factory AgentDraftEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentDraftEventFromJson(json);
}

/// Terminal success (`done`: `run_id` / `outcome: "success"` /
/// `latency_ms` — informational only, the result already arrived with the
/// result event, so the payload is not modeled).
final class AgentDoneEvent extends AgentStreamEvent {
  const AgentDoneEvent();
}

/// Terminal failure (`error`) — same `{code, message}` shape as the chat
/// error event and the REST error envelope. Also carries normalized
/// transport-level failures (e.g. `network_error` on a dropped stream).
/// [statusCode] is absent on the wire (a post-200 `error` event has no HTTP
/// status); synthesized pre-stream failures set it from the envelope so
/// callers keep the old JSON path's status semantics.
@freezed
abstract class AgentErrorEvent extends AgentStreamEvent with _$AgentErrorEvent {
  const AgentErrorEvent._();

  const factory AgentErrorEvent({
    required String code,
    required String message,
    @JsonKey(includeIfNull: false) int? statusCode,
  }) = _AgentErrorEvent;

  factory AgentErrorEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentErrorEventFromJson(json);
}
