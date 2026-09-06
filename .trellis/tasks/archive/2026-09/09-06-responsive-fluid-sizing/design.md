# Design: 响应式视口缩放尺寸体系

## Architecture

三个部件，全部位于 `lib/core/theme/`，自上而下单向依赖：

1. **缩放函数** `AppSizes.scaleForWidth(double width) -> double`
   - `width < 600` → `1.0`（compact 基准，Android 不受影响）
   - `600 ≤ width < 1600` → `1.0 + (width - 600) / 1000 * 0.2` 线性增长
   - `width ≥ 1600` → clamp `1.2`
   - 输出按 0.01 量化（见 Trade-offs），600→1600 全程仅 ~20 个档位，避免拖拽窗口时逐像素重建 ThemeData。
2. **尺寸 token** `AppSizes extends ThemeExtension<AppSizes>`（`lib/core/theme/app_sizes.dart`）
   - 构造：`const AppSizes(scale)`，指标以 **getter** 形式给出（`base × scale`），结构上保证"全部指标派生自单一因子"不变量；`lerp`/`copyWith({scale})`/`==` 均以 scale 为轴（见 Trade-offs）。
   - token 分组（基准值 = 现有硬编码值逐一对应，scale 1.0 渲染与改造前一致）：
     - 间距 `space2/4/6/8/10/12/16/24/28/32/48/120`（数值即基准值，12 档对应现有代码用到的全部间距）
     - 图标 `iconXs=14 / iconSm=18 / iconMd=20 / iconLg=24 / iconHero=48`（iconLg 供导航壳显式使用，默认图标由 iconTheme 承担）
     - 组件 `chipBarHeight=56 / spinnerXs=12 / spinnerSm=16 / spinnerMd=20 / avatarRadius=12 / radiusSm=8 / radiusMd=12 / radiusLg=24 / cardGapV=4 / cardGapVWide=6 / pagePadH=16 / pagePadHCompact=12`
   - 便捷访问：`extension AppSizesX on BuildContext { AppSizes get sizes; }`（内部 `Theme.of(this).extension<AppSizes>()!`）。
3. **主题装配** `AppTheme.light(scale)` / `AppTheme.dark(scale)`（签名变更，唯一调用方 `app.dart`）
   - **文字缩放挂在 typography 几何层**（Flutter 3.41 实测约束）：M3 `ThemeData.textTheme` 本身**不含字号**（只有颜色/字族），字号几何在 `Theme.of()` 解析时经 `ThemeData.localize(typography.geometryThemeFor(category))` 合并进各角色。因此对裸 textTheme 做 `apply(fontSizeFactor:)` 会因 fontSize 为 null 触发断言、且缩放不到；唯一正确钩子是传入预缩放的 `Typography.material2021(englishLike/dense/tall 各 .apply(fontSizeFactor: scale))` —— textTheme 语义角色、`Material` 的 DefaultTextStyle、以及所有经 `Theme.of` 解析的组件默认文字全部跟随缩放，CJK 分类同样覆盖；
   - `iconTheme: IconThemeData(size: 24 × scale, color: colorScheme.onSurface)` —— 默认图标随缩放（IconButton、AppBar actions 等）；
   - `extensions: [AppSizes(scale)]`；
   - ThemeData 按 (brightness, 量化 scale) 缓存：一次窗口拖拽最多 ~20 次真实构建；
   - NavigationRail / NavigationBar 不读全局 iconTheme，其图标在 `app.dart` 壳内显式 `Icon(size: sizes.iconLg)`（theme 级 rail/bar 图标字段与 M3 内部默认的合并语义不可靠，显式 size 是确定性行为）。

**数据流**：窗口宽度 →（`app.dart` 根部 LayoutBuilder）scale → ThemeData{ typography 几何×s, iconTheme×s, AppSizes×s } → 页面经 `Theme.of`（文字自动）与 `context.sizes`（图标/组件/间距）消费。缩放因子是窗口级全局值，整个应用共用。

## Trade-offs（已决策）

- **单一均匀因子 vs 逐 token 曲线**：均匀因子心智模型简单、文字/图标/间距天然协调、测试直接；放弃的是"文字多缩一点、间距少缩一点"的精调能力。MVP 不需要。
- **窗口级 vs 内容区级缩放**：以根 LayoutBuilder 的窗口宽为准。若按 rail 右侧内容区宽算，跨过 840px 时 rail 展开会导致内容区变窄、文字反而变小。窗口级稳定可预期；代价是内容区实际尺寸比缩放因子略保守，接受。
- **量化到 0.01**：连续插值在视觉上连续（1 字号步进 ≤ 0.16px 不可感知），同时把 resize 期间的 ThemeData 重建从每像素降到 ~20 次。
- **不引入第三方库**（screenutil / responsive_framework）：需求是单一连续因子，ThemeExtension + typography 几何缩放即可，避免额外依赖与概念。
- **token 以 getter 派生、以 scale 为唯一状态轴**：28 个指标全部 `base × scale`，若允许逐字段 copyWith 会制造破坏不变量的非法状态；以 scale 为轴的 copyWith/lerp/== 让 token 集永远自洽，也把 ThemeExtension 样板代码从 ~150 行降到 ~30 行。放弃的是"给某个指标单独偏移"的能力——那是逐 token 曲线的需求，MVP 明确不做。
- **可访问性叠加**：系统 `textScaler` 在 paint 期作用于已缩放的 fontSize，两者自然相乘；scale ≥ 1.0 保证触控目标不会缩到 48dp 以下（spec 约束）。

## Compatibility / Migration

- `AppTheme.light()/dark()` 从无参变为必填 `scale`：内部 API，唯一调用方 `app.dart` 同步更新；widget 测试经 `App`/`MaterialApp` 间接使用，不直接调用 `AppTheme`。
- 文字零迁移：页面已全部走 `textTheme` 语义角色，主题层缩放自动生效。
- 图标/间距迁移：按 implement.md 的逐文件映射表替换硬编码为 token。
- `ExpandableTagWrap` 换行预算算法以 `spacing` 为入参，调用处传 `sizes.spacingSm` 即可；组件构造参数与默认值不动。
- `_contentMaxWidth=720`（阅读宽度约束）与导航壳断点结构不变。
- Markdown：文字经 textTheme 自动缩放；flutter_markdown_plus 内部 blockSpacing 的精细对齐不在本期。

## Rollback

纯前端单分支改动，无数据/接口/schema 涉入；revert 即回到静态尺寸。分两段提交（token 基建 + 页面替换）便于二分回滚。
