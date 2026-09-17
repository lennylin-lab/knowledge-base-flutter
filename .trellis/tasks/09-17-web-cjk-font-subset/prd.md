# PRD: Web 端中文字体子集化消除 tofu 闪烁

## Goal

为 Flutter web 打包子集化的中文 Web 字体（Noto Sans SC 子集）并配置主题字体回退链，消除首次加载时中文显示为方框（tofu flash）的问题。

## 背景

Flutter web 首次加载时，回退链（Roboto → 系统字体）不含中文字形，系统 CJK 字体尚未激活，
Skia 渲染出 `.notdef` 方框（tofu），数百毫秒后 CJK 字体就绪才恢复正常。冷加载最明显。

## Requirements

- 打包一个子集化的中文 Web 字体，覆盖应用 UI 代码（`lib/`）中实际使用的全部汉字，消除 UI 文本的 tofu 闪烁。
- 主题显式配置 `fontFamilyFallback`（Noto Sans SC / PingFang SC / Microsoft YaHei 等），覆盖后端动态内容中子集外的字符。
- 字体文件需纳入构建资产，并提供可复现的再生成脚本（提交到仓库）。

## 约束

- 子集字体体积应控制在 ~1MB 以内（`lib/` 中约 428 个唯一汉字，预期远小于此）。
- 不引入运行时网络字体服务（google_fonts 等），保持自托管。
- 不改变现有 UI 视觉风格（Noto Sans 与原系统回退渲染接近）。

## Acceptance Criteria

- [ ] `flutter build web --release --wasm` 成功，`build/web/assets/fonts/` 包含子集字体。
- [ ] 清缓存冷加载（首次访问）时 UI 中文文本不出现方框闪烁。
- [ ] 子集外汉字（如动态内容）仍能通过 fontFamilyFallback 正常显示。
- [ ] 再生成脚本可重复执行；README 记录再生成方法。
