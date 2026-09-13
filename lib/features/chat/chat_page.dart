import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_sizes.dart';
import '../../shared/models/chat.dart';
import '../../shared/models/search.dart';
import '../../shared/models/session.dart';
import '../../shared/widgets/markdown_content.dart';
import '../../shared/widgets/theme_mode_menu.dart';
import 'chat_providers.dart';

/// 问答页：多轮会话式流式问答。
///
/// 通过 [ChatNotifier] 订阅 `POST /api/v1/chat` 事件流：
/// `run_started → sources* → answer_delta* → done | error`。历史消息在上方
/// 按时间顺序渲染；当前一轮的增量以 Markdown 渲染（与文档详情页共用
/// MarkdownContent），引用来源按到达顺序编号展示，答案中的 `[n]` 对应第 n
/// 条来源，点击跳转文档详情（state-management / component-guidelines
/// spec）。AppBar 提供「新对话」与「历史会话」入口。
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _send() {
    if (ref.read(chatProvider).isRunning) return;
    final question = _inputController.text.trim();
    if (question.isEmpty) return;
    _inputController.clear();
    ref.read(chatProvider.notifier).ask(question);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    final notifier = ref.read(chatProvider.notifier);
    final sizes = context.sizes;

    final children = <Widget>[
      for (final message in state.history) _HistoryBubble(message: message),
      if (state.question.isNotEmpty) _RunView(state: state, onRetry: notifier.retry),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('问答'),
        actions: [
          IconButton(
            tooltip: '新对话',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: notifier.newSession,
          ),
          IconButton(
            tooltip: '历史会话',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/chat/sessions'),
          ),
          const ThemeModeMenu(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: children.isEmpty
                ? const _IdleHint()
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      sizes.pagePadH,
                      sizes.space12,
                      sizes.pagePadH,
                      sizes.space16,
                    ),
                    children: children,
                  ),
          ),
          _InputBar(
            controller: _inputController,
            running: state.isRunning,
            onSend: _send,
            onStop: notifier.cancel,
          ),
        ],
      ),
    );
  }
}

/// 历史消息气泡：用户消息右对齐容器，助手消息全宽 Markdown 渲染。
/// 历史助手消息不含来源（后端只存文本），引用编号不解析。
class _HistoryBubble extends StatelessWidget {
  const _HistoryBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    if (message.role == ChatMessageRole.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(bottom: sizes.space8, left: sizes.space24),
          padding: EdgeInsets.symmetric(
            horizontal: sizes.space12,
            vertical: sizes.space8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(sizes.radiusLg),
          ),
          child: Text(message.content, style: theme.textTheme.bodyMedium),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: sizes.space12),
      child: MarkdownContent(data: message.content),
    );
  }
}

/// 当前一轮运行视图：问题、流式答案（Markdown）、引用来源、终端错误
/// （内联错误 + 重试）。已渲染的增量与来源在错误后保留；`done` 后该轮
/// 已并入历史，这里不再重复渲染。
class _RunView extends StatelessWidget {
  const _RunView({required this.state, required this.onRetry});

  final ChatState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final progress = state.progressText();
    final children = <Widget>[
      Padding(
        padding: EdgeInsets.only(bottom: sizes.space8),
        child: Text(
          '问：${state.question}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      if (state.rewrite != null) _RewriteSection(rewrite: state.rewrite!),
      if (progress != null) _ProgressRow(text: progress),
      if (state.answer.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(top: sizes.space8),
          child: MarkdownContent(data: state.answer),
        ),
      if (state.sources.isNotEmpty) _SourcesSection(sources: state.sources),
      if (state.toolCallRows.isNotEmpty) _ToolCallsSection(rows: state.toolCallRows),
      if (state.phase == ChatPhase.error)
        _InlineError(
          message: '回答失败：${state.errorMessage}',
          onRetry: onRetry,
        ),
      if (state.phase == ChatPhase.done) ...[
        if (state.answer.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: sizes.space12),
            child: Text(
              '未生成回答内容',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: sizes.space12),
          child: Text(
            _doneSummary(state),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// 尚未提问时的引导态。
class _IdleHint extends StatelessWidget {
  const _IdleHint();

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
              Icons.chat_bubble_outline,
              size: sizes.iconHero,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: sizes.space12),
            Text('尚未提问', style: theme.textTheme.titleMedium),
            SizedBox(height: sizes.space4),
            Text(
              '输入问题，AI 将基于知识库检索结果给出带引用的回答',
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

/// 检索词改写披露：原始问题 → 改写后的检索词（可折叠，默认收起）。
/// 历史与持久化消息始终保留原始问题，这里只做透明化展示。
class _RewriteSection extends StatelessWidget {
  const _RewriteSection({required this.rewrite});

  final QueryRewrittenEvent rewrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: sizes.space8),
        initiallyExpanded: false,
        leading: Icon(
          Icons.edit_note,
          size: sizes.iconMd,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          '已改写检索词',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          rewrite.rewritten,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('原始问题：${rewrite.original}',
                      style: theme.textTheme.bodySmall),
                  SizedBox(height: sizes.space2),
                  Text('改写检索词：${rewrite.rewritten}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 运行中的进度行（等待首个事件 / 流式生成中）。
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.space8),
      child: Row(
        children: [
          SizedBox(
            width: sizes.spinnerSm,
            height: sizes.spinnerSm,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: sizes.space10),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 引用来源：答案中 `[n]` 对应列表第 n 项（1 起），点击跳转文档详情。
class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.sources});

  final List<SearchHit> sources;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: sizes.space28),
        Text('参考来源', style: theme.textTheme.titleSmall),
        SizedBox(height: sizes.space2),
        Text(
          '答案中的 [1][2] 对应下方来源序号',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: sizes.space8),
        for (final (index, source) in sources.indexed)
          _SourceTile(number: index + 1, source: source),
      ],
    );
  }
}

/// 一条来源：编号 + 标题 + 片段，点击跳转对应文档。
class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.number, required this.source});

  final int number;
  final SearchHit source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Card(
      margin: EdgeInsets.symmetric(vertical: sizes.cardGapV),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/documents/${source.documentId}'),
        child: Padding(
          padding: EdgeInsets.all(sizes.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: sizes.avatarRadius,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  '$number',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: sizes.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.documentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: sizes.space2),
                    Text(
                      source.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 工具调用时间线：按到达顺序列出当前这轮的每次调用（工具名、检索词、
/// 状态、耗时），按 `call_id` 配对。默认收起，副标题汇总总数与失败数；
/// 失败行用错误色标记（非致命——运行仍可能正常完成）。
class _ToolCallsSection extends StatelessWidget {
  const _ToolCallsSection({required this.rows});

  final List<ChatToolCallView> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final failed = rows.where((r) => r.status == ChatToolStatus.failed).length;
    final subtitle = [
      '${rows.length} 次',
      if (failed > 0) '$failed 次失败',
    ].join(' · ');

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: sizes.space4),
        initiallyExpanded: false,
        leading: Icon(
          Icons.build_outlined,
          size: sizes.iconMd,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text('工具调用', style: theme.textTheme.titleSmall),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: failed > 0
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          for (final row in rows)
            ListTile(
              dense: true,
              leading: _ToolStatusIcon(status: row.status),
              title: Text(
                row.query == null || row.query!.isEmpty
                    ? row.toolName
                    : '${row.toolName}：${row.query}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              trailing: row.latencyMs != null
                  ? Text(
                      '${row.latencyMs!.round()} ms',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              iconColor:
                  row.status == ChatToolStatus.failed
                      ? theme.colorScheme.error
                      : null,
              textColor:
                  row.status == ChatToolStatus.failed
                      ? theme.colorScheme.error
                      : null,
            ),
        ],
      ),
    );
  }
}

/// 一次调用的状态标记：进行中转圈 / 成功对勾 / 失败叉。
class _ToolStatusIcon extends StatelessWidget {
  const _ToolStatusIcon({required this.status});

  final ChatToolStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    switch (status) {
      case null:
        return SizedBox(
          width: sizes.iconSm,
          height: sizes.iconSm,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      case ChatToolStatus.success:
        return Icon(
          Icons.check_circle_outline,
          size: sizes.iconSm,
          color: theme.colorScheme.primary,
        );
      case ChatToolStatus.failed:
        return Icon(
          Icons.error_outline,
          size: sizes.iconSm,
          color: theme.colorScheme.error,
        );
    }
  }
}

/// 终端错误：中文前缀 + 后端 message 原样，附重试入口
/// （error-handling spec）。已渲染的答案/来源保留在错误上方。
class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Container(
      margin: EdgeInsets.only(top: sizes.space12),
      padding: EdgeInsets.fromLTRB(
        sizes.space12,
        sizes.space4,
        sizes.space4,
        sizes.space4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: sizes.iconMd,
            color: theme.colorScheme.onErrorContainer,
          ),
          SizedBox(width: sizes.space8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 「回答完成 · 耗时 2.3s · 工具调用 2 次」— 只展示存在的信息。
String _doneSummary(ChatState state) {
  final parts = <String>['回答完成'];
  final latency = state.latencyMs;
  if (latency != null) {
    parts.add('耗时 ${(latency / 1000).toStringAsFixed(1)}s');
  }
  final tools = state.toolCalls;
  if (tools != null && tools > 0) {
    parts.add('工具调用 $tools 次');
  }
  return parts.join(' · ');
}

/// 底部输入栏：多行输入 + 发送（运行中禁用）+ 运行中的停止按钮。
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.running,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final bool running;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          sizes.pagePadHCompact,
          sizes.space4,
          sizes.pagePadHCompact,
          sizes.space8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: '输入问题，基于知识库回答',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sizes.radiusLg),
                  ),
                ),
              ),
            ),
            SizedBox(width: sizes.space4),
            if (running)
              IconButton(
                tooltip: '停止',
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: onStop,
              ),
            IconButton(
              tooltip: '发送',
              icon: const Icon(Icons.send),
              onPressed: running ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
