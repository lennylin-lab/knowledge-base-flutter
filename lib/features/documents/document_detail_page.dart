import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/document.dart';
import '../../shared/utils/markdown_front_matter.dart';
import '../../shared/widgets/expandable_tag_wrap.dart';
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
        data: (document) => _DetailBody(document: document),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final document = ref
        .read(documentDetailProvider(widget.documentId))
        .value;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除文档'),
        content: Text('确定要删除「${document?.title ?? ''}」吗？删除后将无法恢复。'),
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
    if (confirmed != true || !mounted) return;

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

void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.document});

  final DocumentReadDetail document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
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
              const SizedBox(width: 8),
              IndexStatusChip(
                status: document.indexStatus,
                onRetry: () => context.push('/documents/${document.id}/edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (document.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ExpandableTagWrap(tags: document.tags),
            ),
          const Divider(height: 32),
          MarkdownContent(data: stripYamlFrontMatter(document.content)),
        ],
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
    if (isNotFound) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text('文档不存在或已删除'),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
