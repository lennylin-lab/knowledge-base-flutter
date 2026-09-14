import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/agents_result.dart';
import '../../shared/widgets/format.dart';
import 'documents_providers.dart';

/// Layer-2 content pages of the AI assistant system (task
/// 09-15-ai-assistant-routes): the floating entry's bubble items navigate
/// here instead of generating in place, and each page renders its generation
/// content inside a large bubble-styled card (clearly bigger than the entry
/// menu bubble — AppSizes tokens).
///
/// Landing on a page is explicit intent (the bubble tap), so an uncached,
/// idle state auto-generates exactly once on entry (post-frame callback,
/// never in `build`); a cached result shows as-is with no auto-refetch.
/// Back always lands on the entry surface: the AppBar back pops, and a
/// direct deep link without a stack falls back to `/documents/{id}`.

/// 「AI 摘要」 content page: renders the on-demand LLM summary of one
/// document (verbatim, with a 「{model} · {latency}」 caption and 重新生成).
class DocumentSummaryPage extends ConsumerStatefulWidget {
  const DocumentSummaryPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentSummaryPage> createState() =>
      _DocumentSummaryPageState();
}

class _DocumentSummaryPageState extends ConsumerState<DocumentSummaryPage> {
  @override
  void initState() {
    super.initState();
    // Auto-generate once per entry — after the first frame (never in
    // build), re-reading the state so an in-flight generation is skipped.
    // The notifier's own isGenerating guard makes a double fire impossible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(documentSummaryProvider(widget.documentId));
      if (state.result != null || state.isGenerating) return;
      ref.read(documentSummaryProvider(widget.documentId).notifier).generate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentSummaryProvider(widget.documentId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 摘要'),
        leading: BackButton(
          onPressed: () => _backToEntry(context, widget.documentId),
        ),
      ),
      body: _AiContentPageBody(
        children: _summaryContent(context, state),
      ),
    );
  }

  List<Widget> _summaryContent(
    BuildContext context,
    OnDemandState<SummaryResult> state,
  ) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final result = state.result;
    return [
      if (state.isGenerating) ...[
        const _GenerationProgressRow('正在生成摘要…'),
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
              .read(documentSummaryProvider(widget.documentId).notifier)
              .generate(),
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
                .read(documentSummaryProvider(widget.documentId).notifier)
                .generate(),
            icon: const Icon(Icons.refresh),
            label: const Text('重新生成'),
          ),
      ],
    ];
  }
}

/// 「相关文档」 content page: renders the LLM-curated related documents
/// (title / tags / reason); tapping an item pushes that document's detail.
class DocumentAssociationsPage extends ConsumerStatefulWidget {
  const DocumentAssociationsPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentAssociationsPage> createState() =>
      _DocumentAssociationsPageState();
}

class _DocumentAssociationsPageState
    extends ConsumerState<DocumentAssociationsPage> {
  @override
  void initState() {
    super.initState();
    // Same exactly-once entry contract as [DocumentSummaryPage].
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(
        documentAssociationsProvider(widget.documentId),
      );
      if (state.result != null || state.isGenerating) return;
      ref
          .read(documentAssociationsProvider(widget.documentId).notifier)
          .generate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentAssociationsProvider(widget.documentId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('相关文档'),
        leading: BackButton(
          onPressed: () => _backToEntry(context, widget.documentId),
        ),
      ),
      body: _AiContentPageBody(
        children: _associationsContent(context, state),
      ),
    );
  }

  List<Widget> _associationsContent(
    BuildContext context,
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
              .read(documentAssociationsProvider(widget.documentId).notifier)
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
              _AssociationTile(item: item),
          ],
        ),
    ];
  }
}

/// AppBar back for the content pages: pops the pushed page; a direct deep
/// link that mounted the page without a stack falls back to the detail
/// entry route so "back lands on the entry surface" always holds (PRD).
void _backToEntry(BuildContext context, String documentId) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/documents/$documentId');
  }
}

/// Shared body layout of the content pages: the large bubble-styled card,
/// centered and width-capped ([AppSizes.aiContentBubbleWidth]).
class _AiContentPageBody extends StatelessWidget {
  const _AiContentPageBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(sizes.space24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: sizes.aiContentBubbleWidth,
            ),
            child: _AiContentCard(children: children),
          ),
        ),
      ),
    );
  }
}

/// The large bubble-styled card: 「AI 助手」 branding header, then the
/// generation content. Same visual language as the entry menu bubble, but
/// scaled up (radiusLg vs radiusMd, generous padding).
class _AiContentCard extends StatelessWidget {
  const _AiContentCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(sizes.radiusLg),
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.all(sizes.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: sizes.iconLg,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: sizes.space8),
                Text(
                  'AI 助手',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: sizes.space16),
            ...children,
          ],
        ),
      ),
    );
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
/// On the content pages **both** carry an inline 重试: this surface has no
/// floating AI entry (the standing retry of the detail body), so leaving
/// the retry off would strand the user — dead-end rule holds everywhere.
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
/// pushes that document's detail route.
class _AssociationTile extends StatelessWidget {
  const _AssociationTile({required this.item});

  final AssociationItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return InkWell(
      onTap: () => context.push('/documents/${item.documentId}'),
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
