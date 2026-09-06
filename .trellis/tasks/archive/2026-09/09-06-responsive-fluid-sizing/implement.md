# Implement: 响应式视口缩放尺寸体系

## Ordered Checklist

### A. Token 基建（可独立提交）

- [ ] A1 新建 `lib/core/theme/app_sizes.dart`：`AppSizes extends ThemeExtension<AppSizes>`
      （字段与基准值见 design.md）、`AppSizes.fromScale(scale)`、`scaleForWidth`
      （<600→1.0；600→1600 线性 1.0→1.2；≥1600 clamp；量化 0.01）、`lerp`、
      `AppSizesX on BuildContext` 扩展。
- [ ] A2 改 `lib/core/theme/app_theme.dart`：`light(scale)` / `dark(scale)`；
      `textTheme.apply(fontSizeFactor: scale)`；`iconTheme` 24×scale；
      `navigationRailTheme`/`navigationBarTheme` 的 iconTheme 缩放；
      `extensions: [AppSizes.fromScale(scale)]`。
- [ ] A3 改 `lib/app.dart`：`MaterialApp.router` 外包一层 LayoutBuilder（或等价机制），
      以 `constraints.maxWidth` 求 scale 传入 `AppTheme.light/dark`；路由表与
      `_AdaptiveShell` 逻辑不动。
- [ ] A4 新建 `test/core/theme/app_sizes_test.dart`：
      - `scaleForWidth` 单调性、600 以下 = 1.0、≥1600 = 1.2、中间点插值正确（含 800 测试 surface → ~1.04）；
      - `fromScale` 各 token = 基准 × scale；
      - `AppTheme.light(scale)` 的 `bodyMedium.fontSize == 14 * scale`、`extensions` 含 AppSizes；
      - `lerp` 两端与中点正确。

### B. 页面与共享组件替换（可独立提交）

硬编码 → token 映射（`sizes` 取自 `context.sizes`）：

- [ ] B1 `lib/features/documents/documents_page.dart`
      - 空态图标 48 → `iconHero`（:114）；空态间距 120/12/4 → `spacingXxl×?`：120 为空态留白，用 `spacingXxl` 的 4×或新增语义 token，实现时择一并保持基准渲染不变；
      - 卡片 margin 12/6 → `pagePadHCompact`/`cardGapVWide`（:158）；footer spinner 20 → `spinnerMd`（:251）；footer padding 8/12/16 → 对应 spacing token；
      - `_TagFilterBar` 高 56 → `chipBarHeight`、内边距 12/8、chip 间距 8 → spacing token（:294-310）；
      - `_ErrorPane` 图标 48 → `iconHero`、间距 24/12 → spacing token（:336-347）。
- [ ] B2 `lib/features/search/search_page.dart`
      - 输入框区 padding 16/12/4（:56）、结果头 padding 16/8/4（:147）、列表 bottom 16（:157）→ spacing token；
      - 卡片 margin 16/4（:190）→ `pagePadH`/`cardGapV`；卡片内 padding 12（:195）、行距 4/6/8 → spacing token；
      - `_TagFilterBar` 同 B1（:276-298）；`_HintPane`/`_ErrorPane` 图标 48、间距 24/12/4 → token（:325-360）。
- [ ] B3 `lib/features/chat/chat_page.dart`
      - `_IdleHint` 图标 48 → `iconHero`、间距 24/12/4 → token（:78-97）；
      - `_ProgressRow` spinner 16 → `spinnerSm`、间距 8/10 → token（:184-189）；
      - `_SourcesSection` divider 28、间距 2/8 → token（:214-223）；
      - `_SourceTile` 头像 radius 12 → `avatarRadius`、margin 4、padding 12、间距 12/2 → token（:242-275）；
      - `_InlineError` 图标 20 → `iconMd`、圆角 12 → `radiusMd`、间距 12/8/4 → token（:305-318）；
      - `_InputBar` padding 12/4/8、圆角 24 → `radiusLg`、间距 4 → token（:367-387）。
- [ ] B4 `lib/features/documents/document_detail_page.dart`
      - 正文 padding 16/48（:154）→ `pagePadH`/底部留白 token；标题行间距 8/4（:169-179）、divider 32 → token；
      - `_DetailErrorPane` 图标 48、间距 24/12 → token（:211-236）。
- [ ] B5 `lib/features/documents/document_editor_page.dart`
      - AppBar 保存中 spinner 16 → `spinnerSm`（:168）；表单 padding 16/12/4、16/4/16（:191,202）、错误 pane 间距 24/12（:236-241）→ token。
- [ ] B6 `lib/shared/widgets/index_status_chip.dart`
      - pending spinner 12 → `spinnerXs`、间距 6 → token（:36-41）；
      - failed 图标 14 → `iconXs`、间距 4/8/6、圆角 8 → `radiusSm`/spacing token（:58-72）。
- [ ] B7 `lib/shared/widgets/expandable_tag_wrap.dart`
      - `_TagToggleButton` 图标 18 → `iconSm`（:187）；调用侧（B4）传 `sizes.spacingSm` 为 spacing；组件参数与默认值不动。
- [ ] B8 全局检查：`grep -rnE "size: [0-9]|EdgeInsets\.(all|symmetric|only|fromLTRB)\(" lib/features lib/shared` 逐条确认要么是 token、要么是记录在案的例外（`_contentMaxWidth`、`_loadMoreThreshold` 等布局约束/滚动阈值非视觉尺寸）。

## Validation

```bash
flutter analyze        # 零错误
flutter test           # 全绿，含现有 8 个页面级 widget 测试
```

- 宽窄两态人工检查点（quality-guidelines checklist）：默认 800×600 测试 surface 覆盖 medium 档；如需目检，`flutter run -d chrome` 拖拽 500→1800px 观察连续性。

## Risky Files / Rollback Points

- `lib/app.dart`：根部包 LayoutBuilder 时不得触碰路由表（`buildRouter` 与测试深链相关）；A 段提交后跑一次全量测试再进 B 段。
- `AppTheme` 签名变更：唯一调用方 app.dart，若测试直接构造 ThemeData 需同步（勘查未见）。
- 两段提交：A（基建）→ 验证 → B（替换）→ 验证；任一段可独立 revert。

## Before task.py start

- [ ] prd.md / design.md / implement.md 就绪，最终规划摘要已经用户明确批准。
