import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/operation.dart';
import '../../shared/utils/markdown_front_matter.dart';
import '../../shared/widgets/format.dart';
import '../../shared/widgets/markdown_content.dart';
import '../operations/operations_providers.dart';
import 'document_ai_bubble.dart';

/// 「AI 续写」 content layer of the AI assistant bubble: hosts the
/// writing-agent workflow against the operations API — instruction input →
/// synchronous draft generation → draft review → apply with confirmation
/// (overwrites the document), plus resume for interrupted/failed operations
/// and an on-demand per-document history.
///
/// Views derive from [WritingState] (the per-document `writingProvider`):
/// - idle: instruction field (optional) + 生成草稿， inline error copy above
///   the still-working actions on failure (dead-end rule), and the 历史
///   操作 affordance whose first tap loads the list (a draft failure
///   auto-loads/refreshes it so the newest failed operation is reachable);
/// - generating: spinner + seconds hint (the draft stream emits no progress
///   events); resume reuses the same in-flight view;
/// - review + `completed` draft: draft title, body via the shared
///   [MarkdownContent] (front matter stripped), 应用到文档 (confirm dialog
///   first — apply overwrites and cannot be undone), 重新生成 (back to the
///   input, instruction prefilled), 返回菜单;
/// - review + `interrupted`/`failed`: recoverable-failure copy + 恢复；
/// - review + `applied`: 已应用到文档 confirmation with the background
///   re-index hint, 返回菜单 / 查看文档；
/// - applying: the draft view with every action disabled.
///
/// The instruction field is ephemeral widget state that lives on this
/// State — it survives the draft/applying/success views (which is what
/// makes 重新生成's prefill work) and bubble dismissal via the keep-alive
/// Offstage host. The 返回菜单 buttons are the layer's reset affordance
/// ([WritingNotifier.clearCurrent]); the card header's 返回 arrow only
/// switches layers and keeps the workflow state, like every other content
/// layer.
class WritingContentLayer extends ConsumerStatefulWidget {
  const WritingContentLayer({
    super.key,
    required this.documentId,
    required this.tapGroupId,
    required this.onDismiss,
    required this.onBackToMenu,
  });

  final String documentId;

  /// The bubble's TapRegion group (see [AiAssistantFab]): the apply confirm
  /// dialog joins it, so tapping 应用/取消 does not count as a tap outside
  /// the entry and dismiss the bubble behind the dialog.
  final Object tapGroupId;

  /// 查看文档 (apply success): closes the bubble so the refetched body —
  /// the applied content — is visible.
  final VoidCallback onDismiss;

  /// 返回菜单: switches the bubble back to its menu layer **after**
  /// [WritingNotifier.clearCurrent] reset the workflow to idle.
  final VoidCallback onBackToMenu;

  @override
  ConsumerState<WritingContentLayer> createState() =>
      _WritingContentLayerState();
}

class _WritingContentLayerState extends ConsumerState<WritingContentLayer> {
  /// Instruction draft — cleared only by the user (or an unmount); empty
  /// means "no instruction" and travels as null through [WritingNotifier].
  final TextEditingController _instruction = TextEditingController();

  /// Whether the 历史操作 section is expanded. The data lives in the
  /// provider (cached after the first load, refreshed after apply/resume);
  /// this is only the show/hide toggle.
  bool _historyVisible = false;

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  WritingNotifier get _notifier =>
      ref.read(writingProvider(widget.documentId).notifier);

  void _generate() => _notifier.generate(instruction: _instruction.text);

  /// 重新生成: back to the input — the field still holds the previous
  /// instruction, which is the prefill.
  void _regenerate() => _notifier.clearCurrent();

  /// 返回菜单 inside the layer: reset the workflow to idle first, then
  /// switch to the menu layer.
  void _backToMenu() {
    _notifier.clearCurrent();
    widget.onBackToMenu();
  }

  void _resume() => _notifier.resumeCurrent();

  /// 应用到文档: the mandatory confirmation dialog first — apply overwrites
  /// the document's content/title/tags and cannot be undone from the
  /// client. Only a confirmed dialog starts the apply.
  Future<void> _apply() async {
    final confirmed = await _showApplyConfirmDialog(
      context,
      groupId: widget.tapGroupId,
    );
    if (!confirmed || !mounted) return;
    await _notifier.applyCurrent();
  }

  void _toggleHistory() {
    setState(() => _historyVisible = !_historyVisible);
    if (_historyVisible) _notifier.loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    final state = ref.watch(writingProvider(widget.documentId));
    final List<Widget> children = switch (state.phase) {
      WritingPhase.idle => _idleChildren(context, state),
      WritingPhase.generating => _generatingChildren(context),
      WritingPhase.review ||
      WritingPhase.applying => _operationChildren(context, state),
    };
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        sizes.space16,
        0,
        sizes.space16,
        sizes.space12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  List<Widget> _operationChildren(BuildContext context, WritingState state) {
    final current = state.current;
    // Defensive: a draft-less review renders the input instead.
    if (current == null) return _idleChildren(context, state);
    return switch (current.state) {
      OperationState.applied => _appliedChildren(context),
      OperationState.completed => _draftChildren(context, state, current),
      OperationState.interrupted ||
      OperationState.failed => _failedChildren(context, state),
      // A running operation (set externally server-side) renders as the
      // generic in-flight view; it is not an offered history target.
      OperationState.running => _generatingChildren(context),
    };
  }

  /// Idle: instruction input + 生成草稿， optional inline error copy (the
  /// button stays available for an in-place retry — no error dead-ends),
  /// and the on-demand 历史操作 affordance.
  List<Widget> _idleChildren(BuildContext context, WritingState state) {
    final sizes = context.sizes;
    return [
      TextField(
        controller: _instruction,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: '想让 AI 重点处理什么？可留空',
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sizes.radiusSm),
          ),
        ),
      ),
      SizedBox(height: sizes.space8),
      SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: _generate, child: const Text('生成草稿')),
      ),
      if (state.error != null) ...[
        SizedBox(height: sizes.space8),
        _WritingErrorText(error: state.error!),
      ],
      SizedBox(height: sizes.space4),
      TextButton.icon(
        onPressed: _toggleHistory,
        icon: const Icon(Icons.history),
        label: const Text('历史操作'),
      ),
      if (_historyVisible) ..._historyChildren(context, state),
    ];
  }

  /// Generating (and resume) in flight: plain spinner + seconds hint — the
  /// draft endpoint streams no progress events.
  List<Widget> _generatingChildren(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return [
      const GenerationProgressRow('正在生成草稿…'),
      SizedBox(height: sizes.space4),
      Text(
        '同步生成可能需要数秒',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  /// Draft review: title, markdown body (front matter stripped), apply with
  /// confirmation, 重新生成， 返回菜单 — all disabled while applying.
  List<Widget> _draftChildren(
    BuildContext context,
    WritingState state,
    CurrentDraft current,
  ) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final draft = current.draft;
    final applying = state.phase == WritingPhase.applying;
    return [
      Text(
        draft?.title ?? '未命名草稿',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      if (state.error != null) ...[
        SizedBox(height: sizes.space8),
        // Apply failures render here; a conflict gets the dedicated copy.
        _WritingErrorText(error: state.error!, dedicatedConflictCopy: true),
      ],
      SizedBox(height: sizes.space8),
      if (draft != null)
        MarkdownContent(data: stripYamlFrontMatter(draft.content))
      else
        Text(
          '草稿内容为空',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      SizedBox(height: sizes.space4),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: applying ? null : _apply,
          child: const Text('应用到文档'),
        ),
      ),
      Row(
        children: [
          TextButton.icon(
            onPressed: applying ? null : _regenerate,
            icon: const Icon(Icons.refresh),
            label: const Text('重新生成'),
          ),
          TextButton(
            onPressed: applying ? null : _backToMenu,
            child: const Text('返回菜单'),
          ),
        ],
      ),
    ];
  }

  /// Interrupted/failed operation: recoverable-failure copy + 恢复 (resume)
  /// + 重新生成 + 返回菜单 — no dead ends.
  List<Widget> _failedChildren(BuildContext context, WritingState state) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return [
      if (state.error != null)
        _WritingErrorText(error: state.error!)
      else
        Text(
          '该操作未能完成',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      SizedBox(height: sizes.space8),
      Row(
        children: [
          FilledButton.icon(
            onPressed: _resume,
            icon: const Icon(Icons.restore),
            label: const Text('恢复'),
          ),
          TextButton(onPressed: _regenerate, child: const Text('重新生成')),
          TextButton(onPressed: _backToMenu, child: const Text('返回菜单')),
        ],
      ),
      SizedBox(height: sizes.space2),
      Text(
        '恢复会基于已保存的草稿继续，无需重新生成。',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  /// Applied confirmation: 已应用到文档 + background re-index hint, with
  /// 返回菜单 (reset) / 查看文档 (close the bubble onto the refetched body).
  List<Widget> _appliedChildren(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return [
      Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: sizes.iconLg,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: sizes.space8),
          Text(
            '已应用到文档',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      SizedBox(height: sizes.space4),
      Text(
        '文档将在后台重新索引',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      SizedBox(height: sizes.space8),
      Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: _backToMenu,
              child: const Text('返回菜单'),
            ),
          ),
          SizedBox(width: sizes.space8),
          Expanded(
            child: FilledButton(
              onPressed: widget.onDismiss,
              child: const Text('查看文档'),
            ),
          ),
        ],
      ),
    ];
  }

  /// History section (only rendered while expanded): loading, error with an
  /// inline retry, empty copy, or the item list — state + updated_at, and
  /// completed/interrupted/failed items open in the layer.
  List<Widget> _historyChildren(BuildContext context, WritingState state) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    if (state.historyLoading) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: sizes.space8),
          child: const GenerationProgressRow('正在加载历史操作…'),
        ),
      ];
    }
    final error = state.historyError;
    if (error != null) {
      return [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '加载失败：${toApiException(error).message}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            SizedBox(width: sizes.space8),
            TextButton(
              onPressed: _toggleHistoryReloading,
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ];
    }
    final history = state.history;
    if (history == null) return const [];
    if (history.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: sizes.space8),
          child: Text(
            '暂无历史操作',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    return [
      Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.space4),
        child: Divider(height: sizes.space4),
      ),
      for (final operation in history)
        _HistoryTile(
          operation: operation,
          onOpen: _canOpen(operation)
              ? () => _notifier.openOperation(operation)
              : null,
        ),
    ];
  }

  /// Retry affordance of a failed load: `loadHistory` re-fetches while the
  /// last attempt is in the error state (cached successes skip the call).
  void _toggleHistoryReloading() => _notifier.loadHistory();

  /// Only finished-or-recoverable operations open in the layer — running
  /// and applied ones carry nothing to act on.
  bool _canOpen(OperationReadDetail operation) =>
      operation.state == OperationState.completed ||
      operation.state == OperationState.interrupted ||
      operation.state == OperationState.failed;
}

/// The mandatory apply confirmation. Returns whether the user confirmed.
/// The dialog joins the bubble's TapRegion [groupId] — its buttons are
/// inside the entry's group, so confirming does not dismiss the bubble
/// behind the dialog (the scrim still does, which dismisses without
/// confirming).
Future<bool> _showApplyConfirmDialog(
  BuildContext context, {
  required Object groupId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => TapRegion(
      groupId: groupId,
      child: AlertDialog(
        title: const Text('应用到文档'),
        content: const Text('应用后将以草稿覆盖文档的内容、标题与标签，且无法从客户端撤销。确定应用吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('应用'),
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}

/// Inline workflow error copy. Apply failures get the dedicated 409 conflict
/// copy; `chat_unavailable` gets the friendly copy; everything else shows
/// the backend message verbatim with a 生成失败 prefix (quality-guidelines).
String _writingErrorText(Object error, {bool dedicatedConflictCopy = false}) {
  final api = toApiException(error);
  if (dedicatedConflictCopy && api.code == 'conflict') {
    return '文档已更新，草稿基于旧版本，请重新生成草稿';
  }
  if (api.code == 'chat_unavailable') {
    return 'AI 服务暂不可用，请稍后重试';
  }
  return '生成失败：${api.message}';
}

class _WritingErrorText extends StatelessWidget {
  const _WritingErrorText({
    required this.error,
    this.dedicatedConflictCopy = false,
  });

  final Object error;

  final bool dedicatedConflictCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      _writingErrorText(error, dedicatedConflictCopy: dedicatedConflictCopy),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}

/// One history row: state label + formatted updated_at; a trailing chevron
/// marks the tappable items (completed / interrupted / failed — opened in
/// the layer via [WritingNotifier.openOperation]).
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.operation, this.onOpen});

  final OperationReadDetail operation;

  final VoidCallback? onOpen;

  String get _stateLabel => switch (operation.state) {
    OperationState.running => '进行中',
    OperationState.completed => '已完成',
    OperationState.interrupted => '已中断',
    OperationState.failed => '失败',
    OperationState.applied => '已应用',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final failed =
        operation.state == OperationState.failed ||
        operation.state == OperationState.interrupted;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(sizes.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.space8),
        child: Row(
          children: [
            Text(
              _stateLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: failed
                    ? theme.colorScheme.error
                    : operation.state == OperationState.applied
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: sizes.space8),
            Expanded(
              child: Text(
                formatIsoTimestamp(operation.updatedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onOpen != null)
              Icon(
                Icons.chevron_right,
                size: sizes.iconSm,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
