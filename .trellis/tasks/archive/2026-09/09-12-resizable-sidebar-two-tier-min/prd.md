# 可拖拽侧边栏分隔条与两层缩小界限

## Goal

桌面/Web 大屏下，多栏布局中的侧边栏可通过拖拽分隔边界改变宽度：

- **增大**：严格上限，不可突破。
- **缩小**：宽松，两层递进界限——
  - **层一（responsiveMin）之前**：组件保持响应式，内容完整展示并填充；
  - **层一 ~ 层二之间**：组件不再响应式，内容可被截断；
  - **层二（absoluteMin）之后**：禁止再缩小（硬下限）。

## Background（已确认事实）

- "三栏" = 文档页的 系统导航(rail) / 列表 / 详情；"两栏" = 系统导航 / 列表（问答、搜索页均为 导航 / 内容 两栏）。（用户确认）
- 现有布局：全局 shell `NavigationRail + content`（`lib/app.dart:163-191`，断点 600/840）；文档页双栏 `SizedBox(width:340, 列表) + VerticalDivider + Expanded(详情)`（`lib/features/documents/documents_page.dart:70-134`，`_listPaneWidth=340`、`_twoPaneMinWidth=1100`）。
- 仓库无任何拖拽调宽机制、无布局第三方包；持久化仅有 `shared_preferences`（先例 `lib/core/config/app_config.dart`）。
- 布局宽度常量属 spec 豁免 `AppSizes` 的类别（`.trellis/spec/frontend/component-guidelines.md:51-70`）。

## Key Decisions（用户确认）

- D1：作用范围 = 系统导航栏 + 文档页列表栏均可拖拽（导航栏+列表栏均可拖）。
- D2：拖拽宽度跨会话持久化（记住宽度）。
- D3：各阈值取值由实现方按内容实测推荐、在 design.md 定值，随最终规划总结确认（推荐值见 design.md 表格）。

## Requirements

- R1：新建可复用受控拖拽分隔组件（drag handle + pane 容器），桌面/Web 大屏可用，悬停显示 resize 光标并有视觉反馈。
- R2：宽度严格 clamp 到 `[absoluteMin, max]`：增大不可超 max；缩小不可低于 absoluteMin。
- R3：两层缩小语义——`w >= responsiveMin` 时子组件响应式完整展示并填充；`absoluteMin <= w < responsiveMin` 时子组件按 responsiveMin 布局、视口截断内容。
- R4：系统导航 rail 与文档页列表栏接入该组件；handle 仅在对应多栏模式激活时渲染；问答/搜索页的 rail 同样可拖。
- R5：宽度按 paneId 持久化（shared_preferences，key `layout.pane_width.<paneId>`），拖拽结束时落盘；未拖拽过的用户布局像素级不变。

## Acceptance Criteria

- [ ] AC1：大屏下拖拽分隔条可改变 rail / 文档列表栏宽度，悬停显示 resize 光标。
- [ ] AC2：增大到 max 后无法继续变宽。
- [ ] AC3：缩至层一之前内容始终完整展示并填充；越过层一后内容截断但仍可继续缩小。
- [ ] AC4：到层二后无法继续缩小。
- [ ] AC5：重启应用后保持上次拖拽宽度；未拖拽过时布局与现状一致。
- [ ] AC6：窗口宽度不足以容纳当前宽度时以 `min(w, 可用)` 兜底，不溢出窗口。

## Out of Scope

- 移动端（<600）与单栏模式行为不变。
- 详情栏（`Expanded`）本次不做 handle；三栏新面板不在本次范围。
- 不引入布局专用第三方包。

## Open Questions

（无阻塞项）
