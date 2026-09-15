import 'package:freezed_annotation/freezed_annotation.dart';

import 'agents_result.dart';

part 'agents_stream.freezed.dart';
part 'agents_stream.g.dart';

/// Events of the document-agent SSE streams served by
/// `POST /api/v1/documents/{id}/summary` and `/associations`
/// (backend `src/app/schemas/agent_stream.py`).
///
/// Event order: `run_started → [summary_progress …] (summary only) →
/// summary | associations → done`, or a terminal `error` at any point after
/// HTTP 200 (the stream closes right after a terminal event). A cache hit
/// skips the progress events entirely. Comments (`:` keep-alive frames) and
/// unknown event names carry no event and are ignored.
///
/// The result payloads reuse [SummaryResult] / [AssociationsResult]
/// unchanged — the server emits the exact fields of the old JSON bodies as
/// the `summary` / `associations` event data.
sealed class AgentStreamEvent {
  const AgentStreamEvent();
}

/// First event of every stream; [kind] is `"summary"` or `"associations"`
/// (kept as the raw wire string — informational, no branching client-side).
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
