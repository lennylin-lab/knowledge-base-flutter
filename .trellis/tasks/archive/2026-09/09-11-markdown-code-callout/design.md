# Design: Markdown 代码高亮与 Callout

## Architecture & Boundaries

保持 `flutter_markdown_plus` 为唯一渲染器，`MarkdownContent` 仍是全应用唯一的
Markdown 配置入口（spec: component-guidelines）。新增两个自包含模块，均在
`lib/shared/widgets/markdown/` 下，只被 `markdown_content.dart` 引用：

```
lib/shared/widgets/markdown_content.dart        # 组装：styleSheet + builders
lib/shared/widgets/markdown/code_highlight.dart # R1: code builder + token 着色
lib/shared/widgets/markdown/callout.dart        # R2: syntax + builder + 折叠组件
```

不改动 document_detail_page / chat_page（它们已消费 MarkdownContent）。

## Data Flow

### R1 代码高亮

1. `markdown` 解析 fenced code → `Element('pre', [Element('code', …)])`，
   `code.attributes['class'] = 'language-<lang>'`（markdown 7.3.1 行为）。
2. `MarkdownContent` 传入 `builders: {'code': HighlightedCodeBuilder()}`。
3. Builder 在 `visitElementBefore` 读语言；`visitText` 用 `re_highlight`
   （`Highlight().parse(src, lang)`）得到 `Result` 节点树，映射为带颜色的
   `TextSpan` 树；未知/未声明语言 → 返回单色 span（回退）。
4. 配色：两张静态 token 色表（light ≈ GitHub Light、dark ≈ GitHub Dark），
   按 `Theme.of(context).brightness` 选择；背景沿用现有 `codeblockDecoration`。

**验证前置（实现第一步）**：flutter_markdown_plus 对 fenced code 是否路由到
`builders['code']`（builder.dart:349 的 `visitText` 路径）。若不路由：
回退 A = 拦截 `pre` builder（`isBlockElement()`，从 child code 元素取语言，
`visitElementAfterWithContext` 返回完整 RichText）；回退 B = `syntaxHighlighter`
+ wrapper 记录当前语言。三方案接口一致，选定后其余不动。

**验证结论（已实施）**：探针测试（`test/shared/widgets/markdown_code_highlight_test.dart`）
证实 `builders['code']` + `isBlockElement() => true` 的路由机制成立：`code`
进入 block 栈，`visitText` 收到源码原文，且 markdown 7.3.1 把 info string
写入 `code.attributes['class'] = 'language-<lang>'`。但实现选取了**回退 A
（拦截 `pre`）**：inline code span 也产出 `Element('code')`，走 `code`
builder 会把行内代码顶成独立 block，破坏段落流；而 `pre` 本就是内置 block
标签，只包裹块级代码，且语言仍可从 child `code` 元素的 class 读取，外层
`codeblockDecoration` 由包自身逻辑保留。`visitText` 返回完整可滚动
RichText（自持 ScrollController 的 StatefulWidget，保留横向滚动 + 桌面
滚动条），`visitElementAfterWithContext` 不覆盖默认装配。

### R2 Callout

1. `CalloutBlockSyntax.canParse` 匹配 `^> ?\[!(\w+)\]([+-])?( .*)?$`，
   注册进 `MarkdownBody(blockSyntaxes:)`（Document 将自定义 syntax 置于内置
   BlockquoteSyntax 之前，普通引用块走原路径不受影响）。
2. `parse` 剥离首行标记为 attributes（type 归一化到 12 个规范类型 + 别名表、
   title 默认值、fold ∈ {collapsed, expanded, none}），其余行剥离一层 `> `
   后 `parser.parseLines(childLines)` 作为 children —— 内嵌 Markdown、
   嵌套 callout 自然获得解析。
3. `builders['callout']` → `_CalloutWidget`（StatefulWidget）：头部行
   （类型图标 + 标题 + chevron）+ 内容列；fold=none 时内容恒展开且头部
   不响应点击；collapsed/expanded 有初始态并响应点击，`AnimatedSize` 过渡。
4. 类型映射：静态 `const` 表，12 规范类型 × (Material 图标, 主色, 默认标题)，
   中文默认标题与现有 UI 文案约定一致（spec: UI copy Chinese-first）。

## Contracts

- `MarkdownContent` 对外 API 不变（`data` / `selectable`）。
- Callout / 高亮不依赖 Theme 之外的任何全局状态；三端纯 Dart 渲染。
- 新依赖：`re_highlight`（纯 Dart）。实现时核对 pub.dev 最新版本与 license，
  记入 implement.jsonl 研究记录。

## Trade-offs

- 自建 Callout 解析 vs 等上游：dart markdown 原生 alerts 未落地（pub-dev#7278），
  自建 BlockSyntax ~60 行且不动内置 blockquote 路径，风险可控；上游落地后可切换。
- re_highlight vs syntax_highlight(TextMate)：TextMate 精度更高但重（grammar 资产、
  初始化成本），社区 markdown 渲染惯例是 highlight.js 系；选 re_highlight。
- Material 图标近似 Lucide 图标：不引入图标字体依赖；按类型语义选近似图标。

## Compatibility / Rollback

- 纯增量：删除两个 builder 注册即回退到现状；无数据/协议变更。
- 普通文档（无高亮语言标记、无 callout）渲染路径不变，回归风险集中在新增标签。
