import 'package:flutter/material.dart';

/// 文档列表页（Stage 2 实现：keyset 分页、标签过滤、index_status 三态）。
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文档')),
      body: const Center(child: Text('文档功能开发中')),
    );
  }
}
