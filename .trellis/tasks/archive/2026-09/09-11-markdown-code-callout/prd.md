# Markdown 视图增强：代码高亮与 Callout

## Goal

对标 Obsidian 的阅读体验，增强共享 Markdown 渲染视图（文档详情页 + 聊天回答）。
MVP 范围（用户选定）：**代码块语法高亮** + **Callout 提示块（含折叠交互）**。
要求三端（web / Windows / Android）行为一致，优先复用现成依赖、少造轮子。

## Background（代码与生态证据）

- 渲染器为 `flutter_markdown_plus` 1.0.12（pubspec.yaml:42），共享组件
  `lib/shared/widgets/markdown_content.dart`；spec（component-guidelines.md）
  要求文档页与聊天页共用同一渲染配置。
- flutter_markdown_plus 扩展点齐全：`syntaxHighlighter`（`TextSpan format(String source)`）、
  `blockSyntaxes`（自定义 `md.BlockSyntax`）、`builders`（`MarkdownElementBuilder`，
  支持 `isBlockElement()`）、`extensionSet` → 无需更换渲染器，无需引入
  markdown_widget / gpt_markdown 整套替换。
- 底层解析包 `markdown` 7.3.1 将 fenced code 的 info string 写入
  `code.attributes['class'] = 'language-<lang>'`（fenced_code_block_syntax.dart:50）；
  而 `syntaxHighlighter.format(source)` 不传语言名 → 按语言高亮走
  `builders` 自定义 builder，从 attributes 读语言。
- 生态调研：语法高亮选 **`re_highlight`**（highlight.js 语法表的活跃维护 fork，
  纯 Dart、三端通用）；Callout **无现成 pub 包**（GitHub Alerts 原生支持仍在
  dart markdown 上游讨论 dart-lang/pub-dev#7278，未落地），按社区标准做法自建
  BlockSyntax + ElementBuilder；Obsidian 12 类型的颜色/图标映射有公开参考
  （obsidian.md/help/callouts、markdown-it-obsidian-callouts）。

## Requirements

- R1 代码高亮：fenced code block 按声明的语言着色（明暗两套配色跟随应用主题，
  对标 Obsidian 的主题自适应）；未声明或未知语言优雅回退为当前单色样式。
- R2 Callout：支持 Obsidian 语法 `> [!type] Title`、`> [!type]-`（默认收起）、
  `> [!type]+`（默认展开），覆盖 Obsidian 全部类型及别名，按类型渲染
  图标 + 彩色底/边框；无折叠标记时内容始终展开且头部不可点击折叠；
  普通 blockquote 渲染不受影响；支持 callout 内嵌标准 Markdown 内容。
- R3 三端一致：新增依赖仅限纯 Dart/Flutter 包，不引入 WebView。
- R4 改动收敛在共享渲染配置（`markdown_content.dart` 及其新增子文件），
  文档页与聊天页同时生效；为高亮与 Callout 补充 widget 测试。

## Acceptance Criteria

- [ ] AC1 含 dart/yaml/json/python 等声明语言的代码块渲染出多种着色 token；
  无语言、未知语言的代码块不报错并回退单色。
- [ ] AC2 `> [!note]`、`> [!warning]` 等渲染为图标 + 彩色提示块，标题正确，
  省略标题时使用类型默认标题；普通引用块外观与现状一致。
- [ ] AC3 `> [!note]-` 初始收起、`> [!note]+` 初始展开，点击头部可切换；
  无折叠标记的 callout 头部点击不折叠。
- [ ] AC4 明/暗主题下高亮与 callout 配色各自可读（跟随 `Theme.brightness`）。
- [ ] AC5 `flutter analyze` 零问题；`flutter test` 全绿（含新增 widget 测试）；
  pubspec 仅新增纯 Dart/Flutter 依赖。

## Out of Scope

- 数学公式（LaTeX）、Mermaid 图表（用户本轮未选；Mermaid 需 WebView，另立任务）。
- 任务列表、脚注、`==高亮==`、`[[wiki 链接]]` 等 Obsidian 其他特性（用户未补充）。
- 渲染器替换（markdown_widget / gpt_markdown / flutter_md）。
- 代码块工具栏（复制按钮、语言标签角标）等附加 UI。

## Technical Notes

- 代码高亮：`builders['code']` 自定义 builder 读 `language-<lang>`，用
  `re_highlight` 解析为 token 树映射成 `TextSpan`；明暗两套 token 配色表按
  `Theme.brightness` 选择。若验证发现 flutter_markdown_plus 对 fenced code
  不调用 `builders['code']`，回退方案为自定义 `pre` builder 或
  `syntaxHighlighter` + 语言传递补丁（在 design.md 验证步骤中确认）。
- Callout：自定义 `CalloutBlockSyntax`（优先级高于内置 BlockquoteSyntax，
  正则 `^> ?\[!(\w+)\]([+-])?\s*(.*)$`），剥离一层 `> ` 引导符后交回
  `parser.parseLines` 解析内嵌内容，产出 `callout` 元素（attributes：
  type/title/fold）；`builders['callout']` 渲染有状态折叠组件
  （图标 + 标题 + chevron，`AnimatedSize`/`CrossFade` 过渡）。
- 依赖增量：`re_highlight` 一个（实现时核对版本与 license）。
