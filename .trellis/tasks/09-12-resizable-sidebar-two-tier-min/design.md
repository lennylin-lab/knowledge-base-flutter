# Design: 可拖拽侧边栏分隔条与两层缩小界限

## 架构与边界

### 1. 通用组件层（lib/shared/widgets/）

- **`SidebarResizer`（拖拽分隔条）**：8~12px 命中区 + 视觉指示线；`MouseRegion` 提供 `SystemMouseCursors.resizeLeftRight`；`GestureDetector`（pan 拖拽 + 双击恢复默认宽度可选）。仅桌面/Web 大屏启用（宽度 ≥600 / ≥840 场景由调用方决定）。
- **`ResizablePane`（容器）**：参数
  - `width`（当前值，由上层状态持有）、`onWidthChanged`
  - `responsiveMinWidth`（层一 a）、`absoluteMinWidth`（层二 b，b < a）、`maxWidth`（严格上限）
  - `child` + `side`（left/right，决定 handle 在左缘还是右缘）
  - **两层缩小语义**：拖拽 clamp 到 `[absoluteMinWidth, maxWidth]`（硬边界，层二后禁止再缩小；上限严格）。
    渲染：`w >= a` → child 获得宽度 `w`，内部保持响应式（完整展示并填充）；`b <= w < a` → child 固定按 `a` 布局，外层以 `w` 视口裁剪（`ClipRect`/`OverflowBox` 或 `SizedBox(width: w, child: OverflowBox(alignment: centerLeft, maxWidth: a))`），内容可截断。
- 组件不感知业务与持久化，纯受控组件。

### 2. 状态与持久化（lib/core/layout/ 或 lib/core/config/ 扩展）

- 新增 `layout_preferences_providers.dart`：
  - `LayoutWidths` 值对象（按 pane key 存 `double?`，null = 默认/自动）。
  - `Notifier<LayoutWidths>` + 异步写 `shared_preferences`（key 前缀 `layout.pane_width.<paneId>`，跟随 `app_config.base_url` 的命名模式 `lib/core/config/app_config.dart:23`）。
  - 首帧前在 `main()` 中 `load()` 并 override（跟随 `AppConfig.load()` 模式，`lib/main.dart:10-13`），拖拽结束（onPanEnd）时落盘，拖拽过程中仅内存更新。
- 测试 scope 须传 `retry: noAutomaticRetry`（spec 约定）。

### 3. 各布局落地（作用范围）

| Pane | 默认 | 层一 a（响应式下限） | 层二 b（硬下限） | 上限 max |
|---|---|---|---|---|
| 系统导航 rail（`lib/app.dart:163-191`） | 自动（现状：80 / extended 自动宽） | 176（extended 完整标签） | 88（仅图标） | 320 |
| 文档页列表栏（`documents_page.dart:30` `_listPaneWidth=340`） | 340 | 300 | 240 | 520 |
| 详情栏 | `Expanded` 吸收剩余宽度，不设 handle（若未来变为可调，复用 `ResizablePane`） |

- **rail 改造**：`NavigationRail` 无显式宽度参数 → 用 `ResizablePane` 包裹 `SizedBox(width: w)`，`extended` 由 `w` 推导：`w >= a` 时按 `w >= 840` 决定 extended（保持现有断点行为），`w < a` 时 extended=false 且标签被截断；未拖拽过（null）时完全保持现状。
- **两栏页（问答/搜索）**：rail handle 同样生效（rail 与内容之间）。**三栏文档页**：rail handle + 列表↔详情 handle；handle 仅在对应双/三栏模式激活（<600 或内容区 <1100 时列表 handle 不渲染）。
- 布局宽度常量属 spec 明确豁免 `AppSizes` 的类别（`.trellis/spec/frontend/component-guidelines.md:51-70`）。

## 数据流

用户拖拽 handle → `onWidthChanged(dx)` → `layoutWidthsProvider` 更新内存值（clamp）→ 重建 `ResizablePane` → onPanEnd 持久化。窗口宽度变化时：若窗口变窄导致 `w` 超过可用空间，`ResizablePane` 用 `min(w, 可用)` 兜底（不违反层二语义的窗口级保护）。

## 兼容与迁移

- 未拖拽过的用户布局像素级不变（null 宽度走默认路径）。
- 新 prefs key 缺失时回退默认值，无迁移需求。
- 移动端（<600）与单栏模式行为不变。

## 权衡

- 自实现 drag handle 而非引入 `multi_split_view`：需求高度定制（两层界限语义），自实现 ~100 行且无新依赖。
- 拖拽中不写盘、结束才落盘：避免 IO 抖动。

## 回滚

- 组件与 provider 均为新增文件；对 `app.dart` / `documents_page.dart` 的改动为包裹式，revert 单 commit 即可。
