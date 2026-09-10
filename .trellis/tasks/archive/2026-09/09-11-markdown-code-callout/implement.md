# Implement: Markdown 代码高亮与 Callout

## Ordered Checklist

1. [ ] 依赖调研落钉：pub.dev 确认 `re_highlight` 最新版本、license、语言表覆盖
   （dart/yaml/json/python/ts/go/java/c++ 至少在列）；`flutter pub add re_highlight`。
2. [ ] 验证前置（design.md 约定）：写探针 widget 测试确认 fenced code 是否路由到
   `builders['code']`；不路由则切回退 A（`pre` builder），更新 design.md 结论。
3. [ ] R1 `code_highlight.dart`：语言解析 + re_highlight→TextSpan 映射 +
   明/暗两张色表 + 回退路径；接入 `markdown_content.dart`。
4. [ ] R1 测试：已知语言多 token 着色、无语言/未知语言回退单色、明暗两套取色。
5. [ ] R2 `callout.dart`：`CalloutBlockSyntax` + 类型/别名/图标/色表 +
   `_CalloutWidget` 折叠组件；接入 `markdown_content.dart`。
6. [ ] R2 测试：note/warning 渲染与默认标题、`-`/`+`/无标记三种折叠态、
   点击切换、普通 blockquote 不受影响、callout 内嵌 markdown、嵌套 callout。
7. [ ] Spec 沉淀：component-guidelines.md 的 markdown 条目补高亮与 callout 契约。
8. [ ] 全量门：`flutter analyze`（零问题）+ `flutter test`（全绿）；
   运行应用在文档详情页与聊天页目检两个特性 + 普通文档回归。

## Validation Commands

```bash
~/development/flutter/bin/flutter analyze
~/development/flutter/bin/flutter test
~/development/flutter/bin/flutter run -d windows   # 目检（或 -d chrome）
```

## Risky Files / Rollback

- 改动面：`lib/shared/widgets/markdown_content.dart`（唯一既有文件）、
  `lib/shared/widgets/markdown/{code_highlight,callout}.dart`（新增）、
  `test/`（新增）、`pubspec.yaml|lock`（+re_highlight）、spec 文档。
- 回滚点：`markdown_content.dart` 摘除两处 builder/blockSyntaxes 注册即恢复现状；
  独立 commit，revert 单提交即可。
- 注意：会话遗留脏文件 `analysis_options.yaml`、`pubspec.lock`（pub add 会追加
  re_highlight 条目）——提交时 `pubspec.lock` 只 re-stage 与 re_highlight 相关的
  hunk，或与用户确认后一并处理。

## Pre-start Checks

- [ ] implement.jsonl / check.jsonl 均含真实 spec 条目（非 _example）。
- [ ] prd.md 已过收敛（无 Open Questions 残留、无重复事实）。
- [ ] 用户已明确批准最终规划摘要。
