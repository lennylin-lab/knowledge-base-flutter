import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/agents_result.dart';
import '../../shared/models/document.dart';
import '../../shared/utils/markdown_front_matter.dart';
import '../../shared/widgets/expandable_tag_wrap.dart';
import '../../shared/widgets/format.dart';
import '../../shared/widgets/index_status_chip.dart';
import '../../shared/widgets/markdown_content.dart';
import 'documents_providers.dart';

/// 文档详情页: renders Markdown body (front matter stripped) with edit / delete.
///
/// A 404 (deleted elsewhere) toasts 文档不存在或已删除 and pops back to the
/// list (error-handling / database-guidelines spec).
class DocumentDetailPage extends ConsumerStatefulWidget {
  const DocumentDetailPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentDetailPage> createState() =>
      _DocumentDetailPageState();
}

class _DocumentDetailPageState extends ConsumerState<DocumentDetailPage> {
  /// True while this page's own delete flow is running. The notifier
  /// invalidates the detail provider right after the 204, so its refetch
  /// 404s while the page is still mounted — that error is the deletion we
  /// just triggered, not a "deleted elsewhere" surprise, and must not toast
  /// / pop a second time on top of the 已删除 flow.
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(documentDetailProvider(widget.documentId));

    ref.listen(documentDetailProvider(widget.documentId), (previous, next) {
      final error = next.error;
      if (error == null || _deleting) return;
      if (!toApiException(error).isNotFound) return;
      if (!mounted) return;
      _showToast(context, '文档不存在或已删除');
      if (context.canPop()) context.pop();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detailAsync.value?.title ?? '文档详情',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: '编辑',
            icon: const Icon(Icons.edit_outlined),
            onPressed: detailAsync.hasValue
                ? () => context.push('/documents/${widget.documentId}/edit')
                : null,
          ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline),
            onPressed: detailAsync.hasValue ? _confirmDelete : null,
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailErrorPane(
          isNotFound: toApiException(error).isNotFound,
          message: '加载失败：${toApiException(error).message}',
          onRetry: () =>
              ref.invalidate(documentDetailProvider(widget.documentId)),
        ),
        data: (document) => DocumentDetailBody(document: document),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final document = ref
        .read(documentDetailProvider(widget.documentId))
        .value;
    final confirmed = await showDeleteConfirmDialog(
      context,
      document?.title ?? '',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(documentsProvider.notifier)
          .deleteDocument(widget.documentId);
      if (!mounted) return;
      _showToast(context, '已删除');
      if (context.canPop()) context.pop();
    } catch (error) {
      if (!mounted) return;
      final api = toApiException(error);
      if (api.isNotFound) {
        // Deleted elsewhere in the meantime — same end state.
        ref
          ..invalidate(documentDetailProvider(widget.documentId))
          ..invalidate(documentsProvider);
        _showToast(context, '文档不存在或已删除');
        if (context.canPop()) context.pop();
        return;
      }
      _showToast(context, '删除失败：${api.message}');
    } finally {
      // Re-arm the "deleted elsewhere" listener (a failed delete must not
      // permanently suppress it).
      if (mounted) setState(() => _deleting = false);
    }
  }
}

/// 删除确认弹窗（全页详情与双栏右栏共用）；返回是否确认删除。
Future<bool> showDeleteConfirmDialog(BuildContext context, String title) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除文档'),
      content: Text('确定要删除「$title」吗？删除后将无法恢复。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

/// The detail content without page chrome — the full-page detail and the
/// two-pane detail pane (documents page wide layout) render the same body.
/// [titleTrailing] replaces the default index-status chip at the end of the
/// title row (the pane appends its edit/delete actions there).
class DocumentDetailBody extends StatelessWidget {
  const DocumentDetailBody({
    super.key,
    required this.document,
    this.titleTrailing,
  });

  final DocumentReadDetail document;

  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        sizes.pagePadH,
        sizes.space16,
        sizes.pagePadH,
        sizes.space48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  document.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: sizes.space8),
              if (titleTrailing != null)
                titleTrailing!
              else
                IndexStatusChip(
                  status: document.indexStatus,
                  onRetry: () => context.push('/documents/${document.id}/edit'),
                ),
            ],
          ),
          SizedBox(height: sizes.space8),
          if (document.tags.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: sizes.space4),
              child: ExpandableTagWrap(
                tags: document.tags,
                spacing: sizes.space8,
                runSpacing: sizes.space4,
              ),
            ),
          Divider(height: sizes.space32),
          MarkdownContent(data: stripYamlFrontMatter(document.content)),
          // On-demand AI sections (both detail surfaces share this body).
          // They render below the markdown and never block it: every branch
          // below is local to the section and driven by manual taps only —
          // opening the page fires no LLM calls (PRD: manual generation).
          Divider(height: sizes.space32),
          _SummarySection(documentId: document.id),
          Divider(height: sizes.space32),
          _AssociationsSection(documentId: document.id),
        ],
      ),
    );
  }
}

/// 「AI 摘要」 section: manual LLM summary generation (生成摘要 / 重新生成),
/// progress while in flight, the result verbatim with a 「{model} · {latency}」
/// caption, and error copy that keeps any previous result visible.
class _SummarySection extends ConsumerWidget {
  const _SummarySection({required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final state = ref.watch(documentSummaryProvider(documentId));
    final result = state.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiSectionHeader('AI 摘要'),
        SizedBox(height: sizes.space8),
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
                .read(documentSummaryProvider(documentId).notifier)
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
                  .read(documentSummaryProvider(documentId).notifier)
                  .generate(),
              icon: const Icon(Icons.refresh),
              label: const Text('重新生成'),
            ),
        ] else if (!state.isGenerating)
          // Also shown after a failure (alongside the error copy): the
          // friendly chat_unavailable copy invites a retry, so an in-place
          // affordance must exist even with no previous result.
          FilledButton.tonal(
            onPressed: () => ref
                .read(documentSummaryProvider(documentId).notifier)
                .generate(),
            child: const Text('生成摘要'),
          ),
      ],
    );
  }
}

/// 「相关文档」 section: manual LLM association lookup (生成关联), progress
/// while in flight, then the items (title / tags / reason); tapping an item
/// pushes that document's detail route.
class _AssociationsSection extends ConsumerWidget {
  const _AssociationsSection({required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final state = ref.watch(documentAssociationsProvider(documentId));
    final result = state.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiSectionHeader('相关文档'),
        SizedBox(height: sizes.space8),
        if (state.isGenerating) ...[
          const _GenerationProgressRow('正在生成关联…'),
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
                _AssociationTile(item: item),
            ],
          )
        else if (!state.isGenerating)
          // Same as the summary section: stays visible after a failure so
          // the friendly copy always has an in-place retry next to it.
          FilledButton.tonal(
            onPressed: () => ref
                .read(documentAssociationsProvider(documentId).notifier)
                .generate(),
            child: const Text('生成关联'),
          ),
      ],
    );
  }
}

/// Section title row shared by the two AI sections.
class _AiSectionHeader extends StatelessWidget {
  const _AiSectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
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

/// Generation error copy: `503 chat_unavailable` gets the friendly copy;
/// every other failure shows the backend message with a 生成失败 prefix plus
/// a 重试 affordance (quality-guidelines: backend message verbatim with a
/// Chinese prefix).
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
        if (!isChatUnavailable) ...[
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
      ],
    );
  }
}

/// One related document: title + tags + the LLM reason; the whole tile
/// pushes that document's detail (go_router name `document-detail`).
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

/// Detail error state. 404 renders the dedicated 已删除 copy (the listener
/// pops shortly after); other errors offer a retry.
class _DetailErrorPane extends StatelessWidget {
  const _DetailErrorPane({
    required this.isNotFound,
    required this.message,
    required this.onRetry,
  });

  final bool isNotFound;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    if (isNotFound) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: sizes.iconHero,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: sizes.space12),
            const Text('文档不存在或已删除'),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sizes.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: sizes.iconHero,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: sizes.space12),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: sizes.space12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

/// Two-pane right pane (documents page wide layout): the embedded detail for
/// the ephemeral selection. Deep links keep rendering the full page above —
/// this pane never participates in routing (PRD 方案 A). Deleting here, or
/// the document vanishing elsewhere (404), falls back to the placeholder.
class DocumentDetailPane extends ConsumerWidget {
  const DocumentDetailPane({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(documentDetailProvider(documentId));
    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        if (toApiException(error).isNotFound) {
          // Deleted elsewhere while selected — back to the placeholder on
          // the next frame (side effects stay out of the build pass).
          Future.microtask(
            () => ref.read(selectedDocumentIdProvider.notifier).clear(),
          );
          return const _DetailErrorPane(
            isNotFound: true,
            message: '文档不存在或已删除',
            onRetry: _noRetry,
          );
        }
        return _DetailErrorPane(
          isNotFound: false,
          message: '加载失败：${toApiException(error).message}',
          onRetry: () => ref.invalidate(documentDetailProvider(documentId)),
        );
      },
      data: (document) {
        return DocumentDetailBody(
          document: document,
          titleTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IndexStatusChip(
                status: document.indexStatus,
                onRetry: () => context.push('/documents/${document.id}/edit'),
              ),
              IconButton(
                tooltip: '编辑',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/documents/${document.id}/edit'),
              ),
              IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final document = ref.read(documentDetailProvider(documentId)).value;
    if (!context.mounted) return;
    final confirmed = await showDeleteConfirmDialog(
      context,
      document?.title ?? '',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(documentsProvider.notifier)
          .deleteDocument(documentId);
      if (!context.mounted) return;
      _showToast(context, '已删除');
      ref.read(selectedDocumentIdProvider.notifier).clear();
    } catch (error) {
      if (!context.mounted) return;
      final api = toApiException(error);
      if (api.isNotFound) {
        // Deleted elsewhere in the meantime — same end state.
        ref
          ..invalidate(documentDetailProvider(documentId))
          ..invalidate(documentsProvider);
        _showToast(context, '文档不存在或已删除');
        ref.read(selectedDocumentIdProvider.notifier).clear();
        return;
      }
      _showToast(context, '删除失败：${api.message}');
    }
  }
}

/// The pane's 404 branch offers no retry affordance.
void _noRetry() {}
