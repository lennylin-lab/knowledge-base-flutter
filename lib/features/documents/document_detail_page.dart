import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/document.dart';
import '../../shared/utils/markdown_front_matter.dart';
import '../../shared/widgets/expandable_tag_wrap.dart';
import '../../shared/widgets/index_status_chip.dart';
import '../../shared/widgets/markdown_content.dart';
import '../operations/operations_providers.dart';
import 'document_ai_bubble.dart';
import 'document_ai_writing_layer.dart';
import 'documents_providers.dart';

/// 文档详情页: renders Markdown body (front matter stripped) with edit / delete.
///
/// A 404 (deleted elsewhere) toasts 文档不存在或已删除 and pops back to the
/// list (error-handling / database-guidelines spec).
class DocumentDetailPage extends ConsumerStatefulWidget {
  const DocumentDetailPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends ConsumerState<DocumentDetailPage> {
  /// True while this page's own delete flow is running. The notifier
  /// invalidates the detail provider right after the 204, so its refetch
  /// 404s while the page is still mounted — that error is the deletion we
  /// just triggered, not a "deleted elsewhere" surprise, and must not toast
  /// / pop a second time on top of the 已删除 flow.
  bool _deleting = false;

  /// Two-layer navigation state of this page's AI bubble, owned here so the
  /// [PopScope] below can gate system/browser back on it: with the bubble's
  /// content layer open, back returns the bubble to its menu layer instead
  /// of leaving the detail page (PRD). The layer survives bubble dismissal
  /// (keep-alive, see [AiAssistantFab]) — only the 返回 affordance or a
  /// document switch resets it to [AiBubbleLayer.menu].
  final ValueNotifier<AiBubbleLayer> _aiBubbleLayer = ValueNotifier(
    AiBubbleLayer.menu,
  );

  /// Whether the AI bubble is currently expanded. The fab is the single
  /// writer (see [AiAssistantFab.openNav]); this page only reads it. It
  /// keeps the [PopScope] gate honest now that the layer outlives the
  /// bubble: only an *open* content layer consumes back — a closed bubble
  /// pops the page as usual, whatever layer it is parked on.
  final ValueNotifier<bool> _aiBubbleOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // canPop is read during build — rebuild whenever either gate input
    // changes (fab moves layers / bubble is summoned or dismissed).
    _aiBubbleLayer.addListener(_onAiBubbleLayerChanged);
    _aiBubbleOpen.addListener(_onAiBubbleOpenChanged);
  }

  void _onAiBubbleLayerChanged() {
    if (mounted) setState(() {});
  }

  void _onAiBubbleOpenChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _aiBubbleLayer.removeListener(_onAiBubbleLayerChanged);
    _aiBubbleOpen.removeListener(_onAiBubbleOpenChanged);
    _aiBubbleLayer.dispose();
    _aiBubbleOpen.dispose();
    super.dispose();
  }

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

    return PopScope(
      // Only an open content layer blocks the pop — and the pop then means
      // "back to the menu layer", so the page stays. A closed bubble pops
      // the page even when it is parked on a content layer (keep-alive).
      canPop:
          _aiBubbleLayer.value == AiBubbleLayer.menu || !_aiBubbleOpen.value,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _aiBubbleLayer.value = AiBubbleLayer.menu;
      },
      child: Scaffold(
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
          data: (document) => DocumentDetailBody(
            document: document,
            aiBubbleLayer: _aiBubbleLayer,
            aiBubbleOpen: _aiBubbleOpen,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final document = ref.read(documentDetailProvider(widget.documentId)).value;
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
/// bounds** — so the full page and the pane each get their own entry. It
/// only exists while detail data renders (loading / error panes replace the
/// body), and its collapsed form is just the small round button, so it
/// neither blocks body scrolling nor traps clicks elsewhere. There is no AI
/// content in the body itself: all AI content lives inside the entry's
/// bubble, on its in-widget menu/content layers. [aiBubbleLayer] shares the
/// bubble's two-layer navigation with the owning surface (the full page's
/// PopScope back gate), [aiBubbleOpen] the expanded state — together they
/// gate system back (open content layer consumes it); the pane leaves both
/// null.
class DocumentDetailBody extends StatelessWidget {
  const DocumentDetailBody({
    super.key,
    required this.document,
    this.titleTrailing,
    this.aiBubbleLayer,
    this.aiBubbleOpen,
  });

  final DocumentReadDetail document;

  final Widget? titleTrailing;

  final ValueNotifier<AiBubbleLayer>? aiBubbleLayer;

  final ValueNotifier<bool>? aiBubbleOpen;

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
                        onRetry: () =>
                            context.push('/documents/${document.id}/edit'),
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
              ],
            ),
          ),
        ),
        // Bottom-right anchor, sized to leave room for the bubble above the
        // round button: the entry is hosted in a **bounded** region — a
        // plain `Positioned(right:, bottom:)` would hand the fab unbounded
        // constraints (RenderStack lets positioned children overflow), so
        // the bubble's max-height bound and internal scroll could never
        // engage. `Positioned.fill` + `Align` gives the fab the surface's
        // real constraints while keeping the bottom-right placement and the
        // 16px insets; the Align itself is transparent to hit testing, so
        // taps and scrolling outside the bubble/FAB reach the body below.
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: sizes.space16,
                bottom: sizes.space16,
              ),
              child: AiAssistantFab(
                documentId: document.id,
                layerNav: aiBubbleLayer,
                openNav: aiBubbleOpen,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Unified floating AI entry (收起/气泡双态), anchored bottom-right of a
/// detail surface by [DocumentDetailBody]. Collapsed: a small always-visible
/// round button (tooltip 「AI 助手」). Expanded: a bubble card with **two
/// in-widget layers** (PRD — there are no AI content pages):
/// - menu layer (default): the 「AI 助手」 header + one entry per function;
/// - content layer per function: a back affordance (arrow + function title)
///   returning to the menu, plus that function's generation content from
///   [AiBubbleContentLayer] (progress, verbatim result + 「{model} ·
///   {latency}」 + 重新生成， related-document list, empty copy, errors with
///   an inline 重试 — the dead-end rule holds on every branch).
///
/// Summon/dismiss behavior (test-pinned, PRD):
/// - mouse hover opens the bubble (desktop/web);
/// - the pointer leaving the entry's area closes a hover-summoned bubble
///   again — a tap-opened one (touch path) stays until explicitly dismissed;
/// - tapping the round button opens it when closed; on a hover-opened
///   bubble the first tap upgrades it to tap-owned instead of closing (the
///   second tap closes), and a tap-owned bubble closes on tap;
/// - tapping outside the entry closes it;
/// - every dismiss path keeps the current layer (and the content's scroll
///   position) alive for the next open: the card stays mounted behind
///   [Offstage] while closed, so the next summon continues presenting
///   exactly where the user was, with the cached result and no refetch.
///   Reset to the menu layer happens only via the 返回 affordance or a
///   document switch (a [documentId] change resets the layer and closes
///   the bubble).
///
/// Tapping a menu entry is explicit intent: the bubble switches to that
/// function's content layer and generates exactly once when uncached and
/// idle (from the tap callback — never in build; the notifier's own
/// isGenerating guard blocks double fires). A cached result shows as-is:
/// the on-demand providers are watched here even at the menu layer, so they
/// stay alive while the detail surface is open and re-entering a content
/// layer never re-bills. Re-opening a dismissed bubble never generates —
/// an in-flight generation keeps running (and keeps its live progress)
/// across the dismiss. Opening a detail surface still fires zero LLM
/// calls (the providers fetch nothing on build).
///
/// Sizing: the bubble stays [AppSizes.aiBubbleWidth] wide but grows taller
/// to host content; its height is bounded by [LayoutBuilder] — at most
/// [AppSizes.aiBubbleMaxHeightFraction] of the hosting surface's height and
/// never more than the space above the round button ([Flexible]) — so it
/// can never overflow the pane or page, with the content layer scrolling
/// internally.
///
/// The hero tag is unique per instance: the full-page detail and the two-pane
/// pane can be mounted at once (deep-linked detail over a wide documents
/// page), and shared default tags collide during route hero flights.
class AiAssistantFab extends ConsumerStatefulWidget {
  const AiAssistantFab({
    super.key,
    required this.documentId,
    this.layerNav,
    this.openNav,
  });

  final String documentId;

  /// Shared layer navigation (page-owned, so the detail page's PopScope can
  /// gate system back on it); when null the fab owns a private one (the
  /// two-pane pane needs no back gate).
  final ValueNotifier<AiBubbleLayer>? layerNav;

  /// Shared expanded state (page-owned, so the PopScope gate can tell an
  /// open content layer — back consumed — from a closed bubble parked on a
  /// content layer — page pops); when null the fab publishes nowhere (the
  /// pane needs no back gate). The fab is the single writer; the owner only
  /// reads it.
  final ValueNotifier<bool>? openNav;

  @override
  ConsumerState<AiAssistantFab> createState() => _AiAssistantFabState();
}

class _AiAssistantFabState extends ConsumerState<AiAssistantFab> {
  final Object _heroTag = UniqueKey();

  /// TapRegion group shared by the bubble and the writing layer's confirm
  /// dialog: taps on the dialog's buttons sit **inside** the group, so
  /// confirming 应用 does not register as a tap outside the entry (which
  /// would dismiss the bubble right when its applying/success/409 view
  /// becomes the relevant surface). The barrier still counts as outside.
  final Object _tapGroupId = Object();

  /// Single source of truth for the current layer; the fab repaints on its
  /// changes — including when the page's PopScope resets it to menu.
  late ValueNotifier<AiBubbleLayer> _layerNav;
  bool _ownsLayerNav = false;

  /// Mirrors [_open] onto the owner's shared notifier (write-only, see
  /// [AiAssistantFab.openNav]); null publishes nowhere.
  ValueNotifier<bool>? _openNav;

  bool _open = false;

  /// Whether the current expansion was summoned by hover (then the pointer
  /// leaving closes it again) or by tap (then only explicit dismissal does).
  bool _openedByHover = false;

  @override
  void initState() {
    super.initState();
    _attachLayerNav(widget.layerNav);
    _attachOpenNav(widget.openNav);
  }

  @override
  void didUpdateWidget(AiAssistantFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layerNav != widget.layerNav) {
      _layerNav.removeListener(_onLayerChanged);
      if (_ownsLayerNav) _layerNav.dispose();
      _attachLayerNav(widget.layerNav);
    }
    if (oldWidget.openNav != widget.openNav) {
      _attachOpenNav(widget.openNav);
    }
    if (oldWidget.documentId != widget.documentId) {
      // Document switch: the two-pane pane swaps documents in place while
      // this State survives. The presentation resets — bubble closed, menu
      // layer — so the next open starts fresh for the new document. Writing
      // the notifiers mid-build is safe here because the pane (the only
      // surface that can switch documents under a live fab) passes no
      // shared notifiers: their only listener is this State, a descendant
      // of the element currently building, which markNeedsBuild allows.
      if (_open) {
        _open = false;
        _openedByHover = false;
      }
      _openNav?.value = false;
      if (_layerNav.value != AiBubbleLayer.menu) {
        _layerNav.value = AiBubbleLayer.menu;
      }
    }
  }

  void _attachLayerNav(ValueNotifier<AiBubbleLayer>? external) {
    if (external != null) {
      _layerNav = external;
      _ownsLayerNav = false;
    } else {
      _layerNav = ValueNotifier(AiBubbleLayer.menu);
      _ownsLayerNav = true;
    }
    _layerNav.addListener(_onLayerChanged);
  }

  void _attachOpenNav(ValueNotifier<bool>? external) {
    _openNav = external;
    // Publish the current state; on first attach this is a no-op write
    // (false == false notifies nothing).
    _openNav?.value = _open;
  }

  void _onLayerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _layerNav.removeListener(_onLayerChanged);
    if (_ownsLayerNav) _layerNav.dispose();
    super.dispose();
  }

  void _openByHover() {
    if (_open) return;
    setState(() {
      _open = true;
      _openedByHover = true;
    });
    _openNav?.value = true;
  }

  void _openByTap() {
    if (_open) return;
    setState(() {
      _open = true;
      _openedByHover = false;
    });
    _openNav?.value = true;
  }

  void _close() {
    if (!_open) return;
    // Keep-alive (PRD): no layer reset here — the layer (and the content's
    // scroll position) survives every dismiss path for the next open; only
    // the 返回 affordance and a document switch reset to the menu layer.
    // TapRegion.onTapOutside funnels here too, and this early return keeps
    // the always-mounted card from producing spurious dismissals while
    // closed.
    setState(() {
      _open = false;
      _openedByHover = false;
    });
    _openNav?.value = false;
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

  /// Menu entry click = explicit intent: switch to the content layer and
  /// generate exactly once when uncached and idle (tap callback, never in
  /// build; the provider state keeps the single-call contract). 「AI 续写」
  /// needs no trigger here — its layer is a zero-call surface until the
  /// user presses 生成草稿 / opens the history affordance.
  void _selectLayer(AiBubbleLayer layer) {
    _layerNav.value = layer;
    if (layer == AiBubbleLayer.summary) {
      _generateOnceSummary();
    } else if (layer == AiBubbleLayer.associations) {
      _generateOnceAssociations();
    }
  }

  void _generateOnceSummary() {
    final provider = documentSummaryProvider(widget.documentId);
    final state = ref.read(provider);
    if (state.result != null || state.isGenerating) return;
    ref.read(provider.notifier).generate();
  }

  void _generateOnceAssociations() {
    final provider = documentAssociationsProvider(widget.documentId);
    final state = ref.read(provider);
    if (state.result != null || state.isGenerating) return;
    ref.read(provider.notifier).generate();
  }

  /// A related-document item was tapped: navigating to another document's
  /// detail closes the bubble — a plain dismissal, so the layer stays
  /// parked (reset to menu happens only via 返回 or a document switch).
  void _openDocument(String documentId) {
    _close();
    context.push('/documents/$documentId');
  }

  void _backToMenu() => _layerNav.value = AiBubbleLayer.menu;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    // Keep all three on-demand providers alive while the detail surface is
    // open (watched even at the menu layer, which renders no content):
    // layer switches then reuse the cache without re-billing. build() of
    // the notifiers fetches nothing, so this stays a zero-call surface.
    ref.watch(documentSummaryProvider(widget.documentId));
    ref.watch(documentAssociationsProvider(widget.documentId));
    ref.watch(writingProvider(widget.documentId));
    return TapRegion(
      groupId: _tapGroupId,
      onTapOutside: (_) => _close(),
      child: MouseRegion(
        onEnter: (_) => _openByHover(),
        onExit: (_) {
          // Only a hover-summoned bubble follows the pointer out; a
          // tap-opened one (touch path) stays until explicitly dismissed.
          if (_openedByHover) _close();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Keep-alive host: the card is **always mounted**; Offstage
                // hides it while closed — the subtree stays laid out (its
                // Element/State, and with it the content layer's scroll
                // offset, survive every dismiss) but is not painted, not
                // hit-testable, carries no semantics, and sizes to zero in
                // this Column, so the collapsed layout stays fab-only and
                // taps outside the round button pass through to the body.
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          constraints.maxHeight *
                          sizes.aiBubbleMaxHeightFraction,
                    ),
                    child: Offstage(
                      offstage: !_open,
                      // Two height bounds: at most the configured fraction
                      // of the hosting surface's height (ConstrainedBox),
                      // and never more than the space left above the round
                      // button (Flexible) — the bubble can never overflow
                      // the pane or page; overflow content scrolls inside
                      // the bubble.
                      child: _AiBubbleCard(
                        documentId: widget.documentId,
                        layer: _layerNav.value,
                        tapGroupId: _tapGroupId,
                        onDismiss: _close,
                        onBackToMenu: _backToMenu,
                        onSelectSummary: () =>
                            _selectLayer(AiBubbleLayer.summary),
                        onSelectAssociations: () =>
                            _selectLayer(AiBubbleLayer.associations),
                        onSelectWriting: () =>
                            _selectLayer(AiBubbleLayer.writing),
                        onOpenDocument: _openDocument,
                      ),
                    ),
                  ),
                ),
                // Only while open: the gap between bubble and round button
                // (the offstage card takes no room, so the collapsed state
                // still renders exactly the fab).
                if (_open) SizedBox(height: sizes.space12),
                FloatingActionButton(
                  heroTag: _heroTag,
                  tooltip: 'AI 助手',
                  onPressed: _toggle,
                  child: const Icon(Icons.auto_awesome),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The expanded bubble card. Menu layer: 「AI 助手」 header with a dismiss
/// affordance, then one entry per AI function. Content layer: the same
/// dismiss affordance plus a back row (arrow + the function title — back to
/// the menu layer), then that function's content ([AiBubbleContentLayer]).
class _AiBubbleCard extends StatelessWidget {
  const _AiBubbleCard({
    required this.documentId,
    required this.layer,
    required this.tapGroupId,
    required this.onDismiss,
    required this.onBackToMenu,
    required this.onSelectSummary,
    required this.onSelectAssociations,
    required this.onSelectWriting,
    required this.onOpenDocument,
  });

  final String documentId;
  final AiBubbleLayer layer;

  /// See [AiAssistantFab]'s TapRegion group: the writing layer's confirm
  /// dialog joins this group so its buttons do not dismiss the bubble.
  final Object tapGroupId;

  final VoidCallback onDismiss;
  final VoidCallback onBackToMenu;
  final VoidCallback onSelectSummary;
  final VoidCallback onSelectAssociations;
  final VoidCallback onSelectWriting;
  final ValueChanged<String> onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final inMenu = layer == AiBubbleLayer.menu;
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
                inMenu ? sizes.space16 : sizes.space4,
                sizes.space12,
                sizes.space4,
                sizes.space12,
              ),
              child: Row(
                children: [
                  if (inMenu) ...[
                    Icon(
                      Icons.auto_awesome,
                      size: sizes.iconSm,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: sizes.space8),
                  ] else
                    // Back affordance of the content layer: returns to the
                    // menu layer (system back mirrors it via PopScope).
                    IconButton(
                      tooltip: '返回',
                      icon: const Icon(Icons.arrow_back_outlined),
                      onPressed: onBackToMenu,
                    ),
                  Expanded(
                    child: Text(
                      layer.title,
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
            if (inMenu) ...[
              _AiBubbleEntry(
                icon: Icons.summarize_outlined,
                label: AiBubbleLayer.summary.title,
                description: '生成这篇文档的内容摘要',
                onTap: onSelectSummary,
              ),
              _AiBubbleEntry(
                icon: Icons.library_books_outlined,
                label: AiBubbleLayer.associations.title,
                description: '查找与本文相关的文档',
                onTap: onSelectAssociations,
              ),
              _AiBubbleEntry(
                icon: Icons.edit_note_outlined,
                label: AiBubbleLayer.writing.title,
                description: '按指示生成草稿，可应用到文档',
                onTap: onSelectWriting,
              ),
              SizedBox(height: sizes.space4),
            ] else if (layer == AiBubbleLayer.writing)
              Flexible(
                child: WritingContentLayer(
                  documentId: documentId,
                  tapGroupId: tapGroupId,
                  onDismiss: onDismiss,
                  onBackToMenu: onBackToMenu,
                ),
              )
            else
              Flexible(
                child: AiBubbleContentLayer(
                  documentId: documentId,
                  layer: layer,
                  onOpenDocument: onOpenDocument,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One selectable row of the bubble: leading icon, label and a one-line
/// description of what the function does, plus a trailing chevron marking
/// the navigation to that function's content page.
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
          vertical: sizes.space12,
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
            SizedBox(width: sizes.space8),
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
      await ref.read(documentsProvider.notifier).deleteDocument(documentId);
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
