# 响应式视口缩放尺寸体系

## Goal

让应用的文字、图标、组件尺寸随视口（窗口）大小**连续平滑缩放**，取代当前"导航壳自适应、内容尺寸全部静态"的状态。用户从窄窗口拖宽到全屏时，能看到界面元素按比例渐进变大，而不仅是内容区变宽。

用户价值：桌面（Windows / Web 宽窗口）上界面更饱满、可读性更好；同一套代码在 Android 窄屏上保持现状不变。

## Background（已确认事实，来自代码勘查）

- 平台范围：web / windows / android（MVP，无 ios/macos/linux 目录）。
- 现有自适应只覆盖导航壳：`lib/app.dart:152-197` 按 600/840 断点切换 NavigationRail / NavigationBar；内容区尺寸完全静态。
- 主题层 `lib/core/theme/app_theme.dart` 只有配色（`ColorScheme.fromSeed`），**没有** textTheme 定制、没有间距/尺寸 token；无任何响应式第三方库（pubspec 无 screenutil 等）。
- 文字：页面统一走 `Theme.of(context).textTheme.*` 语义角色（titleMedium / bodySmall / labelSmall…），无直接 `fontSize` 硬编码 —— 这意味着**在主题层统一缩放文字即可全局生效**。
- 硬编码尺寸分布（需替换为缩放 token 的清单）：
  - 图标：空态/错误态大图标 `size: 48`（documents_page:114、documents_page:341、search_page:325、search_page:360、chat_page:83、document_detail_page:212、document_detail_page:229）；内联错误图标 `size: 20`（chat_page:315）；展开按钮图标 `size: 18`（expandable_tag_wrap.dart:187）；chip 图标 `size: 14`（index_status_chip.dart:62,72）。
  - 间距/边距：`EdgeInsets` 与 `SizedBox` 逐处硬编码（4/6/8/12/16/24/28/120 等），遍布 5 个页面 + 3 个共享组件。
  - 组件：标签筛选栏高度 `56`（documents_page:294、search_page:276）；迷你进度圈 12/16/20（index_status_chip.dart:36、chat_page.dart:184、document_editor_page.dart:168、documents_page.dart:251）；来源序号头像 `radius: 12`（chat_page.dart:252）；圆角 8/12/24；卡片 margin 4/6/12/16。
- 约束（component-guidelines spec，不可破坏）：
  - 触控目标 ≥ 48dp；
  - 必须尊重 `MediaQuery.textScalerOf`（用户系统字体缩放与我们的视口缩放需叠加生效）；
  - Material 3 断点 compact < 600 / medium 600–840 / expanded ≥ 840 是现有分类依据；
  - 宽/紧凑两种布局都要检查（quality-guidelines review checklist）。
- 质检门槛：`flutter analyze` 零错误、`flutter test` 全绿；现有 8 个页面级 widget 测试（documents/search/chat/detail/editor/tag_wrap/app）在改造后必须保持通过（Flutter 测试默认 surface 800×600，缩放曲线在该宽度下的取值影响测试稳定性）。
- `ExpandableTagWrap` 的换行预算算法以 `spacing` 为入参（expandable_tag_wrap.dart:7-52），token 化后传入 token 值即可，无结构性障碍。

## Requirements

1. 建立单一缩放因子 `scale`，由视口宽度连续插值并 clamp（用户已确认曲线）：
   - 视口 < 600px（compact）：`scale = 1.0`（Android 现状不缩放，触控目标不缩水）；
   - 600px → 1600px：从 1.0 平滑线性增长；
   - ≥ 1600px：clamp 在最大值 **1.2**。
2. 文字随 `scale` 缩放：在 `AppTheme` 构建时对 textTheme 统一 `apply(fontSizeFactor: scale)`，所有走语义角色的文字自动生效；与系统 `textScaler` 叠加。
3. 图标随 `scale` 缩放：默认 `iconTheme` 按 `scale` 缩放；代码中显式 `size:` 的图标改为使用尺寸 token。
4. 组件/间距随 `scale` 缩放：新增尺寸 token（间距、图标尺寸、组件度量如 chip 栏高、迷你进度圈、圆角、卡片边距），以 ThemeExtension 形式挂到 ThemeData，通过 `lerp` 支持连续插值；页面与共享组件的硬编码值替换为 token。
5. 共享访问方式统一：提供 `BuildContext` 扩展（如 `context.sizes`），禁止在页面里重新出现魔法数字。
6. 不缩放项：`documents_page._contentMaxWidth = 720` 是阅读宽度约束，保持固定；触控目标缩放后不得低于 48dp。
7. 缩放因子在应用根部计算（窗口级），整个应用共享同一因子；窗口 resize 时主题随之重建。

## Acceptance Criteria

- [ ] 在 Web/Windows 上拖拽窗口从 ~500px 到 ~1800px：标题、正文、图标、卡片内边距、标签栏高度呈连续渐进变化（无跳档），最终稳定在最大缩放档。
- [ ] 视口 < 600px 时渲染结果与改造前一致（scale = 1.0，Android 行为不变）。
- [ ] 代码中（`lib/` 下页面与共享组件）不再有本任务清单中的硬编码 `size:` / `EdgeInsets` / `SizedBox` 魔法数字；token 均经 `context.sizes` / 主题获取。
- [ ] `flutter analyze` 零错误；`flutter test` 全绿（含现有 8 个页面级 widget 测试）。
- [ ] 新增针对缩放机制的单元/widget 测试：同一 widget 在窄/宽 surface 下取到的 token 值不同且单调；600px 以下 token 等于基准值。
- [ ] 系统字体缩放（`textScaler`）与视口缩放叠加不冲突：textScaler 测试套件保持通过。

## Key Decisions（已确认）

- 缩放曲线：600px 以下 1.0，600→1600px 线性增长至 1.2 封顶（用户选定"适中 1.2"）。
- 连续平滑缩放（非断点分档）—— 用户选定。
- 技术路线：ThemeExtension 尺寸 token + textTheme/iconTheme 统一缩放，不引入第三方响应式库（详见 design.md Trade-offs）。

## Out of Scope

- 导航壳的断点结构（600/840 切换 rail/bar）保持现状，不重设计。
- `_contentMaxWidth` 阅读宽度、布局结构（行列排布方式）不变 —— 本任务只做"尺寸缩放"，不做"布局重排"。
- 不引入第三方响应式库（screenutil / responsive_framework）。
- Markdown 正文块间距（flutter_markdown_plus 内部 blockSpacing）的精细对齐可后置；文字大小经由 textTheme 自动跟随。
