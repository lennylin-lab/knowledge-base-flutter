import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_sizes.dart';
import '../../shared/models/document.dart';
import 'documents_providers.dart';

/// 新建 / 编辑文档页.
///
/// The editor edits the full Markdown source (YAML front matter included) —
/// `title` and `tags` are derived by the backend from the front matter, so
/// the optional title field is only an explicit override (type-safety /
/// database-guidelines spec).
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
  static const String _createTemplate = '---\ntitle: 新文档\ntags: []\n\n';

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  bool _loadingExisting = false;
  bool _saving = false;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) {
      _contentController.text = _createTemplate;
    } else {
      _loadingExisting = true;
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() {
      _loadingExisting = true;
      _loadErrorMessage = null;
    });
    try {
      final document = await ref
          .read(documentsRepositoryProvider)
          .get(widget.documentId!);
      if (!mounted) return;
      setState(() => _loadingExisting = false);
      _contentController.text = document.content;
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
        _showToast('已创建');
        context.pushReplacement('/documents/${created.id}');
      } else {
        await notifier.updateDocument(
          widget.documentId!,
          DocumentUpdate(
            content: content,
            title: titleOverride.isEmpty ? null : titleOverride,
          ),
        );
        if (!mounted) return;
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
      if (api.code == 'conflict') {
        // Edit rejected (concurrent modification): offer a reload instead of
        // silently overwriting (database-guidelines spec).
        _showConflictMessage(api.message);
        return;
      }
      _showToast('保存失败：${api.message}');
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
            onPressed: _loadExisting,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreate ? '新建文档' : '编辑文档'),
        actions: [
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
            TextButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
        ],
      ),
      body: _loadingExisting
          ? const Center(child: CircularProgressIndicator())
          : _loadErrorMessage != null
              ? _EditorLoadErrorPane(
                  message: _loadErrorMessage!,
                  onRetry: _loadExisting,
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
