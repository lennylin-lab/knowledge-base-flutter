import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/session.dart';
import '../../shared/widgets/app_refresh_indicator.dart';
import 'chat_providers.dart';
import 'session_providers.dart';

/// 历史会话页：最近更新的会话列表（keyset 分页）。
///
/// 点击进入对应会话（加载历史并继续对话）；删除需确认（软删除，服务端
/// 为准）；`next_cursor` 存在时列表尾部提供「加载更多」。
class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(sessionsProvider);
    final sizes = context.sizes;

    return Scaffold(
      appBar: AppBar(title: const Text('历史会话')),
      body: page.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorPane(
          message: toApiException(error).message,
          onRetry: () =>
              ref.read(sessionsProvider.notifier).refresh(),
        ),
        data: (data) {
          final items = data.items;
          if (items.isEmpty) {
            return AppRefreshIndicator(
              onRefresh: () =>
                  ref.read(sessionsProvider.notifier).refresh(),
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('暂无历史会话')),
                ],
              ),
            );
          }
          return AppRefreshIndicator(
            onRefresh: () => ref.read(sessionsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: sizes.space8),
              itemCount: items.length + (data.nextCursor != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return _LoadMoreTile(onTap: () =>
                      ref.read(sessionsProvider.notifier).loadMore());
                }
                return _SessionTile(summary: items[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

/// 一条会话：标题 + 相对时间，点击加载进问答页，尾部删除按钮需确认。
class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.summary});

  final ChatSessionSummary summary;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定删除「${summary.title}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionsProvider.notifier).remove(summary.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.forum_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        summary.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_relativeTime(summary.updatedAt)),
      onTap: () {
        ref.read(chatProvider.notifier).openSession(summary.id);
        context.go('/chat');
      },
      trailing: IconButton(
        tooltip: '删除',
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmDelete(context, ref),
      ),
    );
  }
}

/// 「加载更多」尾部；失败时显示错误与重试（由 provider 状态驱动重载）。
class _LoadMoreTile extends ConsumerWidget {
  const _LoadMoreTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionsProvider);
    return ListTile(
      title: Center(
        child: state.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : state.hasError
                ? const Text('加载失败，点击重试')
                : const Text('加载更多'),
      ),
      onTap: state.isLoading ? null : onTap,
    );
  }
}

/// 列表加载失败的错误面板 + 重试。
class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: sizes.iconHero,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: sizes.space8),
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: sizes.space8),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 相对时间文案（中文）：今天/昨天 + 时分，超过两天显示日期。
String _relativeTime(DateTime time) {
  final now = DateTime.now();
  final local = time.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(day).inDays;
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (diffDays == 0) return '今天 $hh:$mm';
  if (diffDays == 1) return '昨天 $hh:$mm';
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
