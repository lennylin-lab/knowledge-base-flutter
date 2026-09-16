import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/operation.dart';
import '../documents/documents_providers.dart';
import 'operations_repository.dart';

/// Operations repository wired to the app-wide API client (rebuilt when the
/// base URL changes); override this in tests (provider-guidelines spec).
final operationsRepositoryProvider = Provider<OperationsRepository>(
  (ref) => OperationsRepository(ref.watch(apiClientProvider)),
);

/// Phase of the 「AI 续写」 writing workflow (the AI bubble's writing layer):
/// - [idle] — instruction input, nothing in flight;
/// - [generating] — a draft/resume call is running (spinner);
/// - [review] — an operation is presented; which view renders is driven by
///   [WritingState.operation]'s state (draft review / recoverable failure /
///   applied confirmation);
/// - [applying] — the apply call is running (actions disabled).
enum WritingPhase { idle, generating, review, applying }

/// Immutable state of one document's writing workflow. [error] carries the
/// raw failed action's exception (OnDemandState idiom — features never
/// stringify in state; the UI maps it to Chinese copy, including the 409
/// dedicated conflict copy).
@immutable
class WritingState {
  const WritingState({
    this.operation,
    this.phase = WritingPhase.idle,
    this.error,
    this.history,
    this.historyLoading = false,
    this.historyError,
  });

  /// The operation the layer currently presents — the generated draft, the
  /// opened history item, or the applied result. Null only while idle.
  final OperationReadDetail? operation;

  final WritingPhase phase;

  /// Raw error of the last failed generate/resume/apply; null after any
  /// successful action and on [WritingNotifier.clearCurrent].
  final Object? error;

  /// The document's operation history (server sends newest first), loaded on
  /// demand by the 历史操作 affordance; null until the first load. Survives
  /// [WritingNotifier.clearCurrent] so a reopened section renders the cache.
  final List<OperationReadDetail>? history;

  /// True while a history fetch is in flight.
  final bool historyLoading;

  /// Raw error of the last failed history fetch; a retry clears it.
  final Object? historyError;

  /// A generate/resume/apply call is in flight — every workflow action
  /// no-ops in this window (synchronous in-flight guard).
  bool get isBusy =>
      phase == WritingPhase.generating || phase == WritingPhase.applying;
}

/// Writing-agent workflow for one document (「AI 续写」): instruction →
/// synchronous draft → review → apply, with resume for interrupted/failed
/// operations and an on-demand per-document history. Same guard idioms as
/// `OnDemandGenerationNotifier` (documents_providers.dart) — build() fetches
/// nothing (opening the bubble or the layer is a zero-call surface), an
/// action while busy is a synchronous no-op, a superseded generation never
/// writes state, and a failure keeps the prior view visible with the raw
/// error for the UI to map.
class WritingNotifier extends Notifier<WritingState> {
  WritingNotifier(this.documentId);

  final String documentId;

  /// Generation guard of the workflow actions (generate/resume/apply and
  /// [clearCurrent]'s reset) — a superseded action never writes state.
  int _generation = 0;

  /// Generation guard of the history fetch, deliberately INDEPENDENT of
  /// [_generation]: a 返回菜单 ([clearCurrent]) is a presentation reset while
  /// the history cache legitimately outlives it, so the workflow bump must
  /// not orphan an in-flight fetch — gating the fetch here would strand
  /// `historyLoading: true` in state and every later loadHistory/
  /// refreshHistory would no-op (permanent spinner). Only a provider
  /// rebuild supersedes a history fetch, and a rebuild also resets the
  /// whole state, so the flag can never strand.
  int _historyGeneration = 0;

  OperationsRepository get _repository =>
      ref.read(operationsRepositoryProvider);

  @override
  WritingState build() {
    _generation++;
    _historyGeneration++;
    return const WritingState();
  }

  /// 生成草稿 — runs the synchronous draft call. Also the landing action of
  /// 重新生成： the layer keeps the previous instruction in its field and
  /// sends it back through here. A tap while busy is a synchronous no-op.
  Future<void> generate({String? instruction}) async {
    if (state.isBusy) return;
    final generation = _generation;
    final previousPhase = state.phase;
    final operation = state.operation;
    state = _write(operation: operation, phase: WritingPhase.generating);
    try {
      final result = await _repository.draft(
        documentId: documentId,
        instruction: instruction,
      );
      if (_generation != generation) return;
      state = _write(operation: result, phase: WritingPhase.review);
    } catch (error) {
      if (_generation != generation) return;
      // Failure keeps the prior view (input, previous draft, or failure)
      // visible; the error renders as inline copy above working actions.
      state = _write(operation: operation, phase: previousPhase, error: error);
    }
  }

  /// 恢复 — resumes the current interrupted/failed operation. Only those two
  /// states are resumable (anything else 409s server-side), so the guard
  /// keeps a doomed call from firing.
  Future<void> resumeCurrent() async {
    final operation = state.operation;
    if (operation == null || state.isBusy) return;
    if (operation.state != OperationState.interrupted &&
        operation.state != OperationState.failed) {
      return;
    }
    final generation = _generation;
    state = _write(operation: operation, phase: WritingPhase.generating);
    try {
      final resumed = await _repository.resume(operation.id);
      if (_generation != generation) return;
      state = _write(operation: resumed, phase: WritingPhase.review);
      await refreshHistory();
    } catch (error) {
      if (_generation != generation) return;
      // Back to the recoverable failure view, error surfaced inline.
      state = _write(
        operation: operation,
        phase: WritingPhase.review,
        error: error,
      );
    }
  }

  /// 应用到文档 — the only publish path. Per PRD the optional
  /// `expectedBaseDocumentVersion` is deliberately NOT threaded through (the
  /// server's base-version check is the single staleness source): a stale
  /// base 409s with zero writes and the draft view stays visible.
  Future<void> applyCurrent() async {
    final operation = state.operation;
    if (operation == null || state.isBusy) return;
    final generation = _generation;
    state = _write(operation: operation, phase: WritingPhase.applying);
    try {
      final result = await _repository.apply(operation.id);
      // The document has been mutated server-side (content/title/tags
      // overwritten, index_status → pending, updated_at bumped): invalidate
      // BEFORE any early-return so the detail body and the documents list
      // refetch even when this result ends up superseded.
      ref
        ..invalidate(documentDetailProvider(documentId))
        ..invalidate(documentsProvider);
      if (_generation != generation) return;
      state = _write(operation: result.operation, phase: WritingPhase.review);
      await refreshHistory();
    } catch (error) {
      if (_generation != generation) return;
      // The draft stays reviewable (prior state kept); a 409 conflict maps
      // to the dedicated 重新生成 copy in the draft view.
      state = _write(
        operation: operation,
        phase: WritingPhase.review,
        error: error,
      );
    }
  }

  /// Opens a history item in the layer (list items are full
  /// [OperationReadDetail]s — no refetch): completed → draft review,
  /// interrupted/failed → the recoverable failure view with 恢复.
  void openOperation(OperationReadDetail operation) {
    if (state.isBusy) return;
    state = _write(operation: operation, phase: WritingPhase.review);
  }

  /// 返回菜单 / 重新生成 — back to the idle input. The generation bump drops
  /// any in-flight generate/resume write (a superseded result must not
  /// resurrect the view after the user backed out); the applying window is
  /// protected, because the cache invalidations depend on that result
  /// landing. History is kept — a reopened section renders the cache — and
  /// an in-flight history fetch is deliberately NOT cancelled by this bump
  /// (it owns its own generation): its terminal write lands with the fresh
  /// workflow fields, so the section's spinner can never strand.
  void clearCurrent() {
    if (state.phase == WritingPhase.applying) return;
    _generation++;
    state = _write(phase: WritingPhase.idle);
  }

  /// 历史操作 affordance: loads on the first open, cached afterwards —
  /// explicit refreshes happen after a successful apply/resume. A failed
  /// load retries; a tap while a fetch is in flight is a no-op.
  Future<void> loadHistory() async {
    if (state.historyLoading) return;
    if (state.history != null && state.historyError == null) return;
    await _fetchHistory();
  }

  /// Re-fetches the list after a successful apply/resume — a no-op while the
  /// list was never loaded (a never-opened history stays zero-call).
  Future<void> refreshHistory() async {
    if (state.history == null || state.historyLoading) return;
    await _fetchHistory();
  }

  /// History-only fetch, guarded by [_historyGeneration] (NOT the workflow
  /// generation — see the field docs). Every write re-reads the LIVE state
  /// for the workflow fields, so a generate/apply action completing
  /// mid-fetch is never reverted (and vice versa — a late history result
  /// never clobbers a newer phase, and a 返回菜单 mid-fetch cannot strand
  /// the loading flag: the fetch simply lands).
  Future<void> _fetchHistory() async {
    final historyGeneration = _historyGeneration;
    final start = state;
    state = WritingState(
      operation: start.operation,
      phase: start.phase,
      error: start.error,
      history: start.history,
      historyLoading: true,
    );
    try {
      final items = await _repository.operationsForDocument(documentId);
      if (_historyGeneration != historyGeneration) return;
      final live = state;
      state = WritingState(
        operation: live.operation,
        phase: live.phase,
        error: live.error,
        history: items,
      );
    } catch (error) {
      if (_historyGeneration != historyGeneration) return;
      final live = state;
      state = WritingState(
        operation: live.operation,
        phase: live.phase,
        error: live.error,
        history: live.history,
        historyError: error,
      );
    }
  }

  /// Replaces the workflow fields while preserving whatever history fields
  /// are live at write time — the workflow and the history fetch update
  /// disjoint slices of one state object and must not clobber each other.
  WritingState _write({
    OperationReadDetail? operation,
    required WritingPhase phase,
    Object? error,
  }) {
    final live = state;
    return WritingState(
      operation: operation,
      phase: phase,
      error: error,
      history: live.history,
      historyLoading: live.historyLoading,
      historyError: live.historyError,
    );
  }
}

/// Per-document writing workflow state (「AI 续写」 bubble layer). Stays
/// alive while the detail surface is open (watched at the bubble's menu
/// layer); a document switch gets a fresh element from the family.
final writingProvider =
    NotifierProvider.family<WritingNotifier, WritingState, String>(
      WritingNotifier.new,
    );
