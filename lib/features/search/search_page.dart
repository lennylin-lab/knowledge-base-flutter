import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/search.dart';
import '../../shared/widgets/horizontal_chip_bar.dart';
import '../../shared/widgets/theme_mode_menu.dart';
import 'search_providers.dart';
import '../../core/auth/auth_logout_button.dart';

/// 搜索页：混合检索（BM25 + 向量）结果列表，支持服务端标签过滤。
///
/// 提交关键词后展示 SearchHit 卡片（标题 / 片段 / 标签 / 得分与双路排名），
/// 点击跳转文档详情。渲染全部结果态：未搜索 / 加载中 / 失败（重试）/
/// 空结果 / 结果列表（component-guidelines spec）。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    // Restore the last submitted query on a fresh mount (tab switches keep
    // the branch alive via indexedStack, but the controller must survive
    // rebuilds of the route itself).
    _queryController = TextEditingController(
      text: ref.read(searchQueryProvider).query,
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(searchResultsProvider.notifier).search(_queryController.text);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    final results = ref.watch(searchResultsProvider);
    final selectedTag = ref.watch(searchQueryProvider).tag;
    final availableTags = _collectTags(results.value, selectedTag);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        actions: [const AuthLogoutButton(), const ThemeModeMenu()],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              sizes.pagePadH,
              sizes.space12,
              sizes.pagePadH,
              sizes.space4,
            ),
            child: TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '搜索知识库',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: '搜索',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _submit,
                ),
              ),
            ),
          ),
          if (availableTags.isNotEmpty)
            _TagFilterBar(
              tags: availableTags,
              selectedTag: selectedTag,
              onSelect: (tag) =>
                  ref.read(searchResultsProvider.notifier).setTag(tag),
            ),
          Expanded(child: _ResultsView(results: results)),
        ],
      ),
    );
  }

  /// Tag chips derived from the loaded hits (plus the active filter, which
  /// may come from hits no longer loaded). Filtering itself always goes to
  /// the server; this is only the affordance list.
  static List<String> _collectTags(SearchResponse? response, String? selected) {
    return <String>{
      ?selected,
      for (final hit in response?.items ?? const <SearchHit>[]) ...hit.documentTags,
    }.toList()
      ..sort();
  }
}

/// The four result states: pre-search hint, loading, error with retry, and
/// the results list (empty results render their own hint).
class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.results});

  final AsyncValue<SearchResponse?> results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorPane(
        message: '搜索失败：${toApiException(error).message}',
        onRetry: () => ref.read(searchResultsProvider.notifier).retry(),
      ),
      data: (response) {
        if (response == null) {
          return const _HintPane(
            icon: Icons.manage_search,
            title: '输入关键词开始搜索',
            subtitle: '支持 BM25 全文与向量语义混合检索',
          );
        }
        if (response.items.isEmpty) {
          return const _HintPane(
            icon: Icons.search_off,
            title: '无匹配结果',
            subtitle: '换个关键词或调整标签筛选试试',
          );
        }
        return _ResultsList(response: response);
      },
    );
  }
}

/// Result header (count + mode) above the hit cards.
class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.response});

  final SearchResponse response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final modeText = response.mode == SearchMode.hybrid ? '混合检索' : 'BM25 检索';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            sizes.pagePadH,
            sizes.space8,
            sizes.pagePadH,
            sizes.space4,
          ),
          child: Text(
            '共 ${response.items.length} 条结果 · $modeText',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: sizes.space16),
            itemCount: response.items.length,
            itemBuilder: (context, index) {
              final hit = response.items[index];
              return _SearchHitCard(
                hit: hit,
                onTap: () => context.push('/documents/${hit.documentId}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One fused chunk hit: title + fused score, snippet, tags, per-leg ranks.
class _SearchHitCard extends StatelessWidget {
  const _SearchHitCard({required this.hit, required this.onTap});

  final SearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    // Per-leg ranks are nullable on the wire: a leg that missed the chunk
    // contributes no rank (type-safety spec).
    final rankText = [
      if (hit.esRank != null) 'ES #${hit.esRank}',
      if (hit.vectorRank != null) '向量 #${hit.vectorRank}',
    ].join(' · ');
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: sizes.pagePadH,
        vertical: sizes.cardGapV,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(sizes.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      hit.documentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: sizes.space8),
                  Text(
                    '得分 ${hit.score.toStringAsFixed(3)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: sizes.space4),
              Text(
                hit.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (hit.documentTags.isNotEmpty) ...[
                SizedBox(height: sizes.space6),
                Wrap(
                  spacing: sizes.space8,
                  runSpacing: sizes.space4,
                  children: [
                    for (final tag in hit.documentTags)
                      Text(
                        '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
              if (rankText.isNotEmpty) ...[
                SizedBox(height: sizes.space6),
                Text(
                  rankText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal tag chips; 全部 clears the filter (documents-page pattern).
/// [HorizontalChipBar] carries the desktop / web scroll adaptations.
class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
    required this.tags,
    required this.selectedTag,
    required this.onSelect,
  });

  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return HorizontalChipBar(
      children: [
        Padding(
          padding: EdgeInsets.only(right: sizes.space8),
          child: FilterChip(
            label: const Text('全部'),
            selected: selectedTag == null,
            onSelected: (_) => onSelect(null),
          ),
        ),
        for (final tag in tags)
          Padding(
            padding: EdgeInsets.only(right: sizes.space8),
            child: FilterChip(
              label: Text(tag),
              selected: selectedTag == tag,
              onSelected: (_) => onSelect(tag),
            ),
          ),
      ],
    );
  }
}

/// Pre-search / empty-result hint.
class _HintPane extends StatelessWidget {
  const _HintPane({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
            Icon(icon, size: sizes.iconHero, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(height: sizes.space12),
            Text(title, style: theme.textTheme.titleMedium),
            SizedBox(height: sizes.space4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-area error state with a retry affordance.
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
