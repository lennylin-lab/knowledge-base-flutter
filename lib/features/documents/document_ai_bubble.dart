import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/agents_result.dart';
import '../../shared/models/agents_stream.dart';
import '../../shared/widgets/format.dart';
import 'documents_providers.dart';

/// Content layer of the floating AI bubble (task 09-15-ai-bubble-inline-
/// content): all AI content renders **inside the bubble** with two in-widget
/// layers (menu ↔ content) — there are no AI routes any more.

/// The two-layer in-widget navigation of the AI bubble: the default
/// 「AI 助手」 menu, or one function's content layer (opened by clicking the
/// matching menu entry; back returns to the menu). Closing the bubble always
/// resets to [menu].
enum AiBubbleLayer { menu, summary, associations }

/// Header copy of each layer — the menu title and the content-layer
/// function titles (also the menu entry labels).
extension AiBubbleLayerTitle on AiBubbleLayer {
  String get title => switch (this) {
    AiBubbleLayer.menu => 'AI 助手',
    AiBubbleLayer.summary => 'AI 摘要',
    AiBubbleLayer.associations => '相关文档',
  };
}

/// In-flight copy for the summary content layer, mapped from the latest
/// streamed progress: `map_pass` reads chunk by chunk, `reduce_pass`
/// condenses the notes, anything before/unknown keeps the generic hint.
String _summaryProgressLabel(SummaryProgress? progress) =>
    switch (progress?.phase) {
      'map_pass' when progress != null =>
        '正在阅读第 ${progress.passIndex}/${progress.passesTotal} 段',
      'reduce_pass' => '正在汇总要点',
      _ => '正在生成摘要…',
    };

/// The bubble's content body for one function layer: watches the matching
/// on-demand generation provider and renders every state — generating
/// (progress + hint), result, empty, error — with the dead-end rule intact
/// (errors carry an inline 重试， results a 重新生成). Content taller than the
/// bubble scrolls internally.
///
/// Navigation stays with the owner: opening a related document goes through
/// [onOpenDocument] (which also dismisses the bubble).
class AiBubbleContentLayer extends ConsumerWidget {
  const AiBubbleContentLayer({
    super.key,
    required this.documentId,
    required this.layer,
    required this.onOpenDocument,
  });

  final String documentId;

  /// Must be [AiBubbleLayer.summary] or [AiBubbleLayer.associations] — the
  /// menu layer never builds a content body.
  final AiBubbleLayer layer;

  final ValueChanged<String> onOpenDocument;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = context.sizes;
    final List<Widget> children;
    switch (layer) {
      case AiBubbleLayer.summary:
        children = _summaryContent(
          context,
          ref,
          ref.watch(documentSummaryProvider(documentId)),
        );
      case AiBubbleLayer.associations:
        children = _associationsContent(
          context,
          ref,
          ref.watch(documentAssociationsProvider(documentId)),
        );
      case AiBubbleLayer.menu:
        throw StateError('AiBubbleContentLayer requires a content layer');
    }
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

  List<Widget> _summaryContent(
    BuildContext context,
    WidgetRef ref,
    OnDemandState<SummaryResult> state,
  ) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final result = state.result;
    return [
      if (state.isGenerating) ...[
        // Live streamed progress line (map/reduce copy) once the first
        // summary_progress event arrived; the generic hint before that.
        _GenerationProgressRow(_summaryProgressLabel(state.progress)),
        SizedBox(height: sizes.space4),
        Text(
          '同步生成可能需要数秒',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: sizes.space8),
      ],
      if (state.error != null) ...[
        _GenerationErrorText(
          error: state.error!,
          onRetry: () =>
              ref.read(documentSummaryProvider(documentId).notifier).generate(),
        ),
        SizedBox(height: sizes.space8),
      ],
      if (result != null) ...[
        // Backend answer text renders verbatim — never translated or
        // trimmed (component-guidelines spec).
        Text(result.summary),
        SizedBox(height: sizes.space4),
        Text(
          '${result.model} · ${formatLatencyMs(result.latencyMs)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!state.isGenerating)
          TextButton.icon(
            onPressed: () => ref
                .read(documentSummaryProvider(documentId).notifier)
                .generate(),
            icon: const Icon(Icons.refresh),
            label: const Text('重新生成'),
          ),
      ],
    ];
  }

  List<Widget> _associationsContent(
    BuildContext context,
    WidgetRef ref,
    OnDemandState<AssociationsResult> state,
  ) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final result = state.result;
    return [
      if (state.isGenerating) ...[
        const _GenerationProgressRow('正在生成关联…'),
        SizedBox(height: sizes.space4),
        Text(
          '同步生成可能需要数秒',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: sizes.space8),
      ],
      if (state.error != null) ...[
        _GenerationErrorText(
          error: state.error!,
          onRetry: () => ref
              .read(documentAssociationsProvider(documentId).notifier)
              .generate(),
        ),
        SizedBox(height: sizes.space8),
      ],
      if (result != null && result.associations.isEmpty)
        Text(
          '未找到相关文档',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      else if (result != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in result.associations)
              _AssociationTile(item: item, onOpen: onOpenDocument),
          ],
        ),
    ];
  }
}

/// In-flight row: small spinner + progress copy.
class _GenerationProgressRow extends StatelessWidget {
  const _GenerationProgressRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Row(
      children: [
        SizedBox(
          width: sizes.spinnerSm,
          height: sizes.spinnerSm,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: sizes.space8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Generation error copy: `503 chat_unavailable` gets the friendly copy,
/// every other failure shows the backend message with a 生成失败 prefix
/// (quality-guidelines: backend message verbatim with a Chinese prefix).
/// **Both** carry an inline 重试： the bubble is the only AI surface, so
/// leaving the retry off would strand the user — dead-end rule holds
/// everywhere.
class _GenerationErrorText extends StatelessWidget {
  const _GenerationErrorText({required this.error, required this.onRetry});

  final Object error;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final isChatUnavailable = toApiException(error).code == 'chat_unavailable';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            isChatUnavailable
                ? 'AI 服务暂不可用，请稍后重试'
                : '生成失败：${toApiException(error).message}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        SizedBox(width: sizes.space8),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('重试'),
        ),
      ],
    );
  }
}

/// One related document: title + tags + the LLM reason; the whole tile
/// opens that document's detail via [onOpen] (the bubble owner closes
/// itself and pushes the route).
class _AssociationTile extends StatelessWidget {
  const _AssociationTile({required this.item, required this.onOpen});

  final AssociationItem item;

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return InkWell(
      onTap: () => onOpen(item.documentId),
      borderRadius: BorderRadius.circular(sizes.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.tags.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: sizes.space2),
                child: Wrap(
                  spacing: sizes.space8,
                  runSpacing: sizes.space2,
                  children: [
                    for (final tag in item.tags)
                      Text(
                        '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: sizes.space2),
              child: Text(
                item.reason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
