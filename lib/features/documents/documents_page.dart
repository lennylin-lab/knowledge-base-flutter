import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/document.dart';
import '../../shared/widgets/index_status_chip.dart';
import 'documents_providers.dart';

/// 文档列表页: keyset-paginated (infinite scroll), server-side tag filter
/// and per-row `index_status` (三态). All loading / empty / error branches
/// of the list state render (component-guidelines spec).
class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  /// Start fetching the next page once the viewport comes this close to
  /// the end of the loaded items.
  static const double _loadMoreThreshold = 320;

  static const double _contentMaxWidth = 720;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(documentsProvider);
    final selectedTags = ref.watch(selectedTagsProvider);
    final availableTags = _collectTags(listState.value, selectedTags);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedTags.isEmpty ? '文档' : '文档 · ${selectedTags.join(' + ')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(documentsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新建文档',
        onPressed: () => context.push('/documents/new'),
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Column(
            children: [
              if (availableTags.isNotEmpty)
                _TagFilterBar(
                  tags: availableTags,
                  selectedTags: selectedTags,
                  onToggle: (tag) =>
                      ref.read(selectedTagsProvider.notifier).toggle(tag),
                  onClearAll: () =>
                      ref.read(selectedTagsProvider.notifier).clear(),
                ),
              Expanded(
                child: listState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorPane(
                    message: '加载失败：${toApiException(error).message}',
                    onRetry: () =>
                        ref.read(documentsProvider.notifier).refresh(),
                  ),
                  data: (state) => _DocumentsListView(state: state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tag chips derived from the loaded items (plus the active filters, which
  /// may come from items no longer loaded). Filtering itself always goes to
  /// the server; this is only the affordance list.
  static List<String> _collectTags(
    DocumentsListState? state,
    Set<String> selected,
  ) {
    return <String>{
      ...selected,
      for (final item in state?.items ?? const <DocumentRead>[]) ...item.tags,
    }.toList()..sort();
  }
}

/// Infinite-scrolling list with pull-to-refresh and a footer for the
/// load-more lifecycle (loading / failed-with-retry / end of list).
class _DocumentsListView extends ConsumerWidget {
  const _DocumentsListView({required this.state});

  final DocumentsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = context.sizes;
    if (state.items.isEmpty) {
      // Still pull-to-refresh-able when empty.
      return RefreshIndicator(
        onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: sizes.space120),
            Icon(
              Icons.description_outlined,
              size: sizes.iconHero,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: sizes.space12),
            Center(
              child: Text(
                ref.watch(selectedTagsProvider).isEmpty ? '暂无文档' : '所选标签下暂无文档',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: sizes.space4),
            Center(
              child: Text(
                '点击右下角按钮创建第一篇文档',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter <
            DocumentsPage._loadMoreThreshold) {
          // No-ops at end of list / while a fetch is already in flight.
          ref.read(documentsProvider.notifier).loadNext();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + 1, // + footer slot
          itemBuilder: (context, index) {
            if (index < state.items.length) {
              final document = state.items[index];
              return Card.outlined(
                // Margin doubles as the gap between neighbouring cards,
                // so each document reads as its own bordered block.
                margin: EdgeInsets.symmetric(
                  horizontal: sizes.pagePadHCompact,
                  vertical: sizes.cardGapVWide,
                ),
                child: _DocumentTile(
                  document: document,
                  onTap: () => context.push('/documents/${document.id}'),
                  // failed → re-save affordance deep-links to the editor.
                  onRetryIndex: () =>
                      context.push('/documents/${document.id}/edit'),
                ),
              );
            }
            return _ListFooter(state: state);
          },
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, this.onTap, this.onRetryIndex});

  final DocumentRead document;
  final VoidCallback? onTap;
  final VoidCallback? onRetryIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagsText = document.tags.map((tag) => '#$tag').join('  ');
    return ListTile(
      onTap: onTap,
      // 无行数上限：文本自然铺满卡片宽度、在边界处换行，不截断。
      title: Text(document.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tagsText.isNotEmpty)
            Text(
              tagsText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      trailing: document.indexStatus == IndexStatus.done
          ? null
          : IndexStatusChip(
              status: document.indexStatus,
              onRetry: onRetryIndex,
            ),
    );
  }
}

/// Footer slot: loading spinner while fetching the next page, a retry row
/// on failure, and an end-of-list hint.
class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.state});

  final DocumentsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    if (state.loadMoreError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.space8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '加载失败：${state.loadMoreError}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(documentsProvider.notifier).loadNext(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.space12),
        child: Center(
          child: SizedBox(
            width: sizes.spinnerMd,
            height: sizes.spinnerMd,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.space16),
        child: Center(
          child: Text(
            '没有更多了',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Horizontal tag chips with multi-select; 全部 clears the selection. The
/// server ANDs the selected tags (documents must carry every one of them).
class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
    required this.onClearAll,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return SizedBox(
      height: sizes.chipBarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: sizes.pagePadHCompact,
          vertical: sizes.space8,
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(right: sizes.space8),
            child: FilterChip(
              label: const Text('全部'),
              selected: selectedTags.isEmpty,
              showCheckmark: false,
              onSelected: (_) => onClearAll(),
            ),
          ),
          for (final tag in tags)
            Padding(
              padding: EdgeInsets.only(right: sizes.space8),
              child: FilterChip(
                label: Text(tag),
                selected: selectedTags.contains(tag),
                showCheckmark: false,
                onSelected: (_) => onToggle(tag),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-list error state with a retry affordance.
class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
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
