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
///
/// Besides the scrolling content, the body hosts the unified floating AI
/// entry ([AiAssistantFab]) anchored bottom-right **within this body's own
/// bounds** — so the full page and the pane each get their own entry. It only
/// exists while detail data renders (loading / error panes replace the body),
/// and its collapsed form is just the small round button, so it neither
/// blocks body scrolling nor traps clicks elsewhere.
class DocumentDetailBody extends StatefulWidget {
  const DocumentDetailBody({
    super.key,
    required this.document,
    this.titleTrailing,
  });

  final DocumentReadDetail document;

  final Widget? titleTrailing;

  @override
  State<DocumentDetailBody> createState() => _DocumentDetailBodyState();
}

class _DocumentDetailBodyState extends State<DocumentDetailBody> {
  /// Section anchors the floating entry scrolls to. Held in State instead of
  /// being created per build: recreating a [GlobalKey] on every rebuild would
  /// tear down and rebuild the section subtree each time.
  final GlobalKey _summarySectionKey = GlobalKey();
  final GlobalKey _associationsSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
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
                        widget.document.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: sizes.space8),
                    if (widget.titleTrailing != null)
                      widget.titleTrailing!
                    else
                      IndexStatusChip(
                        status: widget.document.indexStatus,
                        onRetry: () => context
                            .push('/documents/${widget.document.id}/edit'),
                      ),
                  ],
                ),
                SizedBox(height: sizes.space8),
                if (widget.document.tags.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: sizes.space4),
                    child: ExpandableTagWrap(
                      tags: widget.document.tags,
                      spacing: sizes.space8,
                      runSpacing: sizes.space4,
                    ),
                  ),
                Divider(height: sizes.space32),
                MarkdownContent(
                  data: stripYamlFrontMatter(widget.document.content),
                ),
                // Display-only on-demand AI sections below the markdown
                // (both detail surfaces share this body). Generation is
                // triggered exclusively through the floating AI entry to the
                // right (plus inline 重试 / 重新生成); opening the page fires
                // no LLM calls (PRD: manual generation).
                Divider(height: sizes.space32),
                _SummarySection(
                  key: _summarySectionKey,
                  documentId: widget.document.id,
                ),
                Divider(height: sizes.space32),
                _AssociationsSection(
                  key: _associationsSectionKey,
                  documentId: widget.document.id,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: sizes.space16,
          bottom: sizes.space16,
          child: AiAssistantFab(
            documentId: widget.document.id,
            summarySectionKey: _summarySectionKey,
            associationsSectionKey: _associationsSectionKey,
          ),
        ),
      ],
    );
  }
}

/// 「AI 摘要」 section, display-only: generation is triggered from the
/// floating AI entry (bottom-right of the surface). Renders progress while
/// in flight, the result verbatim with a 「{model} · {latency}」 caption and
/// an inline 重新生成 affordance, and error copy that keeps any previous
/// result visible (generic errors get an in-place 重试; the always-visible
/// floating entry is the standing retry for the friendly chat_unavailable
/// copy — dead-end rule).
class _SummarySection extends ConsumerWidget {
  const _SummarySection({super.key, required this.documentId});

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
        ] else if (!state.isGenerating && state.error == null)
          // Idle: the generation entry lives in the always-visible floating
          // AI entry at the surface's bottom-right.
          const _IdleHintRow(),
      ],
    );
  }
}

/// 「相关文档」 section, display-only: generation is triggered from the
/// floating AI entry (bottom-right of the surface). Renders progress while
/// in flight, then the items (title / tags / reason); tapping an item pushes
/// that document's detail route. Generic errors keep an in-place 重试; the
/// always-visible floating entry covers the friendly chat_unavailable copy.
class _AssociationsSection extends ConsumerWidget {
  const _AssociationsSection({super.key, required this.documentId});

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
        else if (!state.isGenerating && state.error == null)
          // Idle: the generation entry lives in the floating AI entry.
          const _IdleHintRow(),
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

/// Idle-state hint of a display-only AI section: points at the floating AI
/// entry at the surface's bottom-right (the unified generation trigger).
class _IdleHintRow extends StatelessWidget {
  const _IdleHintRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '使用右下角悬浮入口生成',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Unified floating AI entry (收起/气泡双态), anchored bottom-right of a
/// detail surface by [DocumentDetailBody]. Collapsed: a small always-visible
/// round button (tooltip 「AI 助手」). Expanded: a bubble card listing the
/// two AI functions.
///
/// Summon/dismiss behavior (test-pinned, PRD):
/// - mouse hover opens the bubble (desktop/web);
/// - the pointer leaving the entry's area closes a hover-summoned bubble
///   again — a tap-opened one (touch path) stays until explicitly dismissed;
/// - tapping the round button opens it when closed; on a hover-opened
///   bubble the first tap upgrades it to tap-owned instead of closing (the
///   second tap closes), and a tap-owned bubble closes on tap;
/// - tapping outside the entry closes it;
/// - selecting a function closes it, scrolls that bottom section into view
///   and fires exactly one generation — first run and regenerate alike
///   (generate() no-ops while one is already in flight).
///
/// The hero tag is unique per instance: the full-page detail and the two-pane
/// pane can be mounted at once (deep-linked detail over a wide documents
/// page), and shared default tags collide during route hero flights.
class AiAssistantFab extends ConsumerStatefulWidget {
  const AiAssistantFab({
    super.key,
    required this.documentId,
    required this.summarySectionKey,
    required this.associationsSectionKey,
  });

  final String documentId;

  /// [GlobalKey] of the 「AI 摘要」 section, scrolled into view on select.
  final GlobalKey summarySectionKey;

  /// [GlobalKey] of the 「相关文档」 section, scrolled into view on select.
  final GlobalKey associationsSectionKey;

  @override
  ConsumerState<AiAssistantFab> createState() => _AiAssistantFabState();
}

class _AiAssistantFabState extends ConsumerState<AiAssistantFab> {
  static const Duration _revealDuration = Duration(milliseconds: 300);

  final Object _heroTag = UniqueKey();

  bool _open = false;

  /// Whether the current expansion was summoned by hover (then the pointer
  /// leaving closes it again) or by tap (then only explicit dismissal does).
  bool _openedByHover = false;

  void _openByHover() {
    if (_open) return;
    setState(() {
      _open = true;
      _openedByHover = true;
    });
  }

  void _openByTap() {
    if (_open) return;
    setState(() {
      _open = true;
      _openedByHover = false;
    });
  }

  void _close() {
    if (!_open) return;
    setState(() {
      _open = false;
      _openedByHover = false;
    });
  }

  void _toggle() {
    if (_open && !_openedByHover) {
      _close();
      return;
    }
    if (_open) {
      // Touch-web compatibility: browsers fire compatibility mouse events
      // around a tap, and mouseenter precedes the click — so the first tap
      // lands on a bubble the hover already opened. Upgrade it to tap-owned
      // instead of closing, or the first tap could never open the entry on
      // touch devices (MVP target); a second tap then closes it.
      setState(() => _openedByHover = false);
      return;
    }
    _openByTap();
  }

  void _selectSummary() {
    _close();
    _revealSection(widget.summarySectionKey);
    ref.read(documentSummaryProvider(widget.documentId).notifier).generate();
  }

  void _selectAssociations() {
    _close();
    _revealSection(widget.associationsSectionKey);
    ref
        .read(documentAssociationsProvider(widget.documentId).notifier)
        .generate();
  }

  /// Scrolls the section with [sectionKey] into view (no-op when it is
  /// already visible or not mounted).
  void _revealSection(GlobalKey sectionKey) {
    final sectionContext = sectionKey.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: _revealDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return TapRegion(
      onTapOutside: (_) => _close(),
      child: MouseRegion(
        onEnter: (_) => _openByHover(),
        onExit: (_) {
          // Only a hover-summoned bubble follows the pointer out; a
          // tap-opened one (touch path) stays until explicitly dismissed.
          if (_openedByHover) _close();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_open) ...[
              _AiBubbleCard(
                onDismiss: _close,
                onSelectSummary: _selectSummary,
                onSelectAssociations: _selectAssociations,
              ),
              SizedBox(height: sizes.space12),
            ],
            FloatingActionButton(
              heroTag: _heroTag,
              tooltip: 'AI 助手',
              onPressed: _toggle,
              child: const Icon(Icons.auto_awesome),
            ),
          ],
        ),
      ),
    );
  }
}

/// The expanded bubble card: 「AI 助手」 header with a dismiss affordance,
/// then one entry per AI function (icon + label + one-line description).
class _AiBubbleCard extends StatelessWidget {
  const _AiBubbleCard({
    required this.onDismiss,
    required this.onSelectSummary,
    required this.onSelectAssociations,
  });

  final VoidCallback onDismiss;
  final VoidCallback onSelectSummary;
  final VoidCallback onSelectAssociations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      elevation: 6,
      child: SizedBox(
        width: sizes.aiBubbleWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                sizes.space16,
                sizes.space12,
                sizes.space4,
                sizes.space12,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: sizes.iconSm,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: sizes.space8),
                  Expanded(
                    child: Text(
                      'AI 助手',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '收起',
                    icon: const Icon(Icons.close_outlined),
                    onPressed: onDismiss,
                  ),
                ],
              ),
            ),
            _AiBubbleEntry(
              icon: Icons.summarize_outlined,
              label: 'AI 摘要',
              description: '生成这篇文档的内容摘要',
              onTap: onSelectSummary,
            ),
            _AiBubbleEntry(
              icon: Icons.library_books_outlined,
              label: '相关文档',
              description: '查找与本文相关的文档',
              onTap: onSelectAssociations,
            ),
            SizedBox(height: sizes.space4),
          ],
        ),
      ),
    );
  }
}

/// One selectable row of the bubble: leading icon, label and a one-line
/// description of what the function does.
class _AiBubbleEntry extends StatelessWidget {
  const _AiBubbleEntry({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sizes.space16,
          vertical: sizes.space10,
        ),
        child: Row(
          children: [
            Icon(icon, size: sizes.iconMd, color: theme.colorScheme.primary),
            SizedBox(width: sizes.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  SizedBox(height: sizes.space2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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
