import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/document.dart';
import 'documents_providers.dart';
import 'edit_draft_store.dart';

/// 新建 / 编辑文档页.
///
/// The editor edits the full Markdown source (YAML front matter included) —
/// `title` and `tags` are derived by the backend from the front matter, so
/// the optional title field is only an explicit override (type-safety /
/// database-guidelines spec).
///
/// Unsaved-work safety net (issue #5): a sticky dirty flag drives the AppBar
/// indicator and the PopScope back gate; while dirty, a ~1s debounce persists
/// the buffer into [EditDraftStore] (survives logout and app kills). On save
/// the PATCH carries the server `content_hash` as `expectedContentHash` so a
/// concurrent modification surfaces as 409 instead of silent overwrite.
class DocumentEditorPage extends ConsumerStatefulWidget {
  const DocumentEditorPage({super.key, this.documentId});

  /// Null → create mode.
  final String? documentId;

  bool get isCreate => documentId == null;

  @override
  ConsumerState<DocumentEditorPage> createState() =>
      _DocumentEditorPageState();
}

class _DocumentEditorPageState extends ConsumerState<DocumentEditorPage> {
  static const String _createTemplate =
      '---\ntitle: 新文档\ntags: []\ndescription: 文档描述\n\n';

  /// How long after the last keystroke the dirty buffer is persisted locally.
  static const Duration _draftDebounceDelay = Duration(seconds: 1);

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final EditDraftStore _draftStore = EditDraftStore();

  /// Document id (edit mode) or `"new"` (create mode).
  String get _scopeKey => widget.documentId ?? newDocumentDraftScopeKey;

  /// Server content the session started from (create mode: the template).
  /// The dirty check is a plain string compare against it — the client never
  /// computes hashes. Also persisted into the draft as the tier-2 restore
  /// key (see [EditDraft.baselineContent]).
  String _baselineContent = '';

  /// `content_hash` of [_baselineContent] as loaded from the detail endpoint.
  /// Null = unknown (old backend / pre-backfill row / create mode / already
  /// saved this session) → saves degrade to last-write-wins without the
  /// optimistic-concurrency guard.
  String? _baselineHash;

  /// Sticky once true: the listener skips the compare while dirty (typing
  /// back to the baseline is detected by the debounce tick, which flips the
  /// flag back and drops the persisted draft).
  bool _dirty = false;

  bool _loadingExisting = false;
  bool _saving = false;
  String? _loadErrorMessage;
  Timer? _draftDebounce;

  /// Guards the programmatic controller writes (load / draft restore) so
  /// they never trip [_handleControllersChanged].
  bool _suppressDirtyTracking = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) {
      _baselineContent = _createTemplate;
      _contentController.text = _createTemplate;
      _restoreCreateDraft();
    } else {
      _loadingExisting = true;
      _loadExisting();
    }
    _contentController.addListener(_handleControllersChanged);
    _titleController.addListener(_handleControllersChanged);
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  /// Controller listeners fire synchronously on assignment; wrap programmatic
  /// writes (load / restore) so only real user input drives dirty state.
  void _setControllers({String? content, String? title}) {
    _suppressDirtyTracking = true;
    try {
      if (content != null) _contentController.text = content;
      if (title != null) _titleController.text = title;
    } finally {
      _suppressDirtyTracking = false;
    }
  }

  /// Called on every user edit. Sticky dirty: once dirty, further keystrokes
  /// only re-arm the debounce timer — the baseline compare runs until the
  /// first dirtying edit and again at the debounce tick (dirty 复原).
  void _handleControllersChanged() {
    if (_suppressDirtyTracking) return;
    if (!_dirty && _buffersDifferFromBaseline) {
      setState(() => _dirty = true);
    }
    if (_dirty && !_saving) {
      _draftDebounce?.cancel();
      _draftDebounce = Timer(_draftDebounceDelay, _onDraftDebounceTick);
    }
  }

  /// Whether the buffers differ from the current baseline. Early-exit string
  /// compare, no hashing — the client never computes content hashes (PRD).
  bool get _buffersDifferFromBaseline =>
      _contentController.text != _baselineContent ||
      _titleController.text.isNotEmpty;

  /// Debounce tick: edited back to the baseline → back to clean and drop the
  /// persisted draft; otherwise persist the current buffer.
  void _onDraftDebounceTick() {
    if (!_buffersDifferFromBaseline) {
      setState(() => _dirty = false);
      unawaited(_draftStore.clear(_scopeKey));
      return;
    }
    _writeDraft();
  }

  /// Persists the current buffers immediately (fire-and-forget — the draft
  /// store swallows storage failures).
  void _writeDraft() {
    unawaited(
      _draftStore.save(
        EditDraft(
          scopeKey: _scopeKey,
          content: _contentController.text,
          titleOverride: _titleController.text,
          baselineContentHash: _baselineHash,
          baselineContent: _baselineContent,
          savedAt: DateTime.now(),
        ),
      ),
    );
  }

  /// Create mode: a leftover draft under the fixed `"new"` scope restores
  /// unconditionally (no server baseline to conflict with).
  Future<void> _restoreCreateDraft() async {
    final draft = await _draftStore.load(newDocumentDraftScopeKey);
    if (!mounted || draft == null) return;
    if (draft.content == _baselineContent && draft.titleOverride.isEmpty) {
      return; // identical to the template — nothing to restore
    }
    _setControllers(content: draft.content, title: draft.titleOverride);
    setState(() => _dirty = true);
    _showToast('已恢复未保存的草稿');
  }

  Future<void> _loadExisting({bool discardDraft = false}) async {
    _draftDebounce?.cancel();
    setState(() {
      _loadingExisting = true;
      _loadErrorMessage = null;
    });
    try {
      final document = await ref
          .read(documentsRepositoryProvider)
          .get(widget.documentId!);
      if (!mounted) return;
      final draft = discardDraft ? null : await _draftStore.load(_scopeKey);
      if (!mounted) return;
      if (discardDraft) {
        // 409 「重新加载」: the draft is stale by definition — the server
        // content wins and the local safety net is dropped with it.
        unawaited(_draftStore.clear(_scopeKey));
      }
      setState(() => _loadingExisting = false);
      setState(() {
        _baselineContent = document.content;
        _baselineHash = document.contentHash;
        _dirty = false;
      });
      _setControllers(content: document.content, title: '');

      if (draft == null) return;
      // Three-tier restore decision (one-shot, off the typing hot path):
      // (1) same baseline hash — null == null counts as a match: both
      //     unknown → restore;
      // (2) hash inconclusive (e.g. nulled by an in-session save) but the
      //     draft's verbatim baseline content equals the loaded document →
      //     it was not modified elsewhere → restore;
      // (3) neither → the document changed since the draft started.
      final baselineUnchanged =
          draft.baselineContentHash == document.contentHash ||
          draft.baselineContent == document.content;
      if (baselineUnchanged) {
        _setControllers(content: draft.content, title: draft.titleOverride);
        setState(() => _dirty = true);
        _showToast('已恢复未保存的草稿');
      } else {
        await _resolveDraftConflict(draft);
      }
    } catch (error) {
      if (!mounted) return;
      final api = toApiException(error);
      setState(() => _loadingExisting = false);
      if (api.isNotFound) {
        _showToast('文档不存在或已删除');
        if (context.canPop()) context.pop();
        return;
      }
      setState(() => _loadErrorMessage = api.message);
    }
  }

  /// Neither restore tier matched (baseline hash and baseline content both
  /// differ from the freshly loaded document): the document changed since the
  /// draft was started. Let the user pick.
  Future<void> _resolveDraftConflict(EditDraft draft) async {
    final useDraft = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('检测到未保存的草稿'),
        content: const Text('文档已在别处修改，请选择使用哪个版本。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('用最新内容'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('用草稿'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (useDraft ?? false) {
      // Baseline stays the freshly loaded server content + its current hash,
      // so the next save guards against that state, not the stale one.
      _setControllers(content: draft.content, title: draft.titleOverride);
      setState(() => _dirty = true);
    } else {
      unawaited(_draftStore.clear(_scopeKey));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final content = _contentController.text;
    // Boundary validation (type-safety spec): `content` must be non-empty,
    // the server would reject with 422 otherwise.
    if (content.trim().isEmpty) {
      _showToast('正文不能为空');
      return;
    }
    final titleOverride = _titleController.text.trim();

    _draftDebounce?.cancel();
    setState(() => _saving = true);
    final notifier = ref.read(documentsProvider.notifier);
    try {
      if (widget.isCreate) {
        final created = await notifier.createDocument(
          DocumentCreate(
            content: content,
            title: titleOverride.isEmpty ? null : titleOverride,
          ),
        );
        if (!mounted) return;
        // The template-scope draft has become a real document — drop it so
        // the next "new document" session starts clean.
        unawaited(_draftStore.clear(newDocumentDraftScopeKey));
        _showToast('已创建');
        context.pushReplacement('/documents/${created.id}');
      } else {
        await notifier.updateDocument(
          widget.documentId!,
          DocumentUpdate(
            content: content,
            title: titleOverride.isEmpty ? null : titleOverride,
            // Optimistic-concurrency guard, only while the server hash is
            // known. Null (old backend / pre-backfill / already saved this
            // session) stays off the wire (includeIfNull: false).
            expectedContentHash: _baselineHash,
          ),
        );
        if (!mounted) return;
        setState(() {
          _saving = false;
          // The update response carries no new hash (and the client never
          // computes one): null the guard so the next save this session is a
          // plain last-write-wins PATCH instead of replaying the stale hash
          // (which the server would 409).
          _baselineHash = null;
          _baselineContent = content;
          _dirty = _buffersDifferFromBaseline;
        });
        unawaited(_draftStore.clear(_scopeKey));
        _showToast('已保存');
        if (context.canPop()) context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      final api = toApiException(error);
      if (api.isNotFound) {
        _showToast('文档不存在或已删除');
        if (context.canPop()) context.pop();
        return;
      }
      // Don't wait for the debounce: flush the buffer right now so it
      // survives an app kill / expired session — on a 409 the edit is still
      // wanted (just rejected), same as network / auth failures.
      if (_dirty) _writeDraft();
      if (api.code == 'conflict') {
        // Edit rejected before any mutation (concurrent modification): offer
        // a reload instead of silently overwriting (database-guidelines spec).
        _showConflictMessage(api.message);
        return;
      }
      _showToast('保存失败：${api.message}，未保存内容已保留，重新登录后可恢复');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showConflictMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('保存失败：$message'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '重新加载',
            onPressed: () => _loadExisting(discardDraft: true),
          ),
        ),
      );
  }

  /// Dirty back gate: [保存] saves in place (success pops via [_save]),
  /// [保留草稿退出] flushes the latest buffers first, [放弃] just leaves — the
  /// debounced draft is already on disk, so nothing is lost and no second
  /// confirmation is needed.
  Future<void> _confirmExit() async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('有未保存的更改'),
        content: const Text('退出前请选择如何处理。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: const Text('放弃'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('keep'),
            child: const Text('保留草稿退出'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'save':
        await _save();
      case 'keep':
        _writeDraft();
        if (context.canPop()) context.pop();
      case 'discard':
        if (context.canPop()) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isCreate ? '新建文档' : '编辑文档'),
          actions: [
            if (_dirty)
              Padding(
                padding: EdgeInsets.only(right: sizes.space8),
                child: Text(
                  '未保存',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_saving)
              Padding(
                padding: EdgeInsets.all(sizes.space16),
                child: SizedBox(
                  width: sizes.spinnerSm,
                  height: sizes.spinnerSm,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(onPressed: _save, child: const Text('保存')),
          ],
        ),
        body: _loadingExisting
            ? const Center(child: CircularProgressIndicator())
            : _loadErrorMessage != null
            ? _EditorLoadErrorPane(
                message: _loadErrorMessage!,
                onRetry: () => _loadExisting(),
              )
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sizes.pagePadH,
                      sizes.space12,
                      sizes.pagePadH,
                      sizes.space4,
                    ),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '标题（可选）',
                        hintText: '留空则由正文 front matter 解析',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        sizes.pagePadH,
                        sizes.space4,
                        sizes.pagePadH,
                        sizes.space16,
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          // Monospace 西文字体不含汉字；显式接回 CJK 回退链，
                          // 否则这里会重新出现首帧 tofu（不继承主题 fallback）。
                          fontFamilyFallback: [
                            'NotoSansSC',
                            'Noto Sans CJK SC',
                            'PingFang SC',
                            'Microsoft YaHei',
                          ],
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Markdown 正文（含 YAML front matter）',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EditorLoadErrorPane extends StatelessWidget {
  const _EditorLoadErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sizes.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败：$message', textAlign: TextAlign.center),
            SizedBox(height: sizes.space12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
