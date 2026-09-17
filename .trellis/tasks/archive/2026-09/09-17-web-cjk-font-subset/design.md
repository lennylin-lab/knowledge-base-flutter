# Design: Web 端中文字体子集化

## 方案

1. **字体源**：本机 `NotoSansCJK-Regular.ttc` 的 SC 面（`/usr/share/fonts/noto-cjk/`）。
   用 `fonttools` `TTCollection` 抽取 SC face 后 `pyftsubset` 子集化。
2. **子集范围**：
   - `lib/` 下所有 `.dart` 文件中的唯一汉字（当前 428 个，脚本动态收集）；
   - ASCII 可打印字符；
   - 常用中文标点（，。！？：；「」『』（）《》……——·、）与全角空格。
3. **输出**：`assets/fonts/NotoSansSC-Subset.ttf`，pubspec 注册为 family `NotoSansSC`。
   （Flutter 对 woff2 的 pubspec 支持不稳，TTF 兼容性最好；子集后体积小，压缩差异可忽略。）
4. **主题接线**：`ThemeData(fontFamily: 'NotoSansSC', fontFamilyFallback: ['Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', 'Noto Sans CJK SC', 'sans-serif'])`。
   打包字体优先保证 UI 文本不闪；fallback 链兜底动态内容的子集外字符。
5. **再生成脚本**：`scripts/gen_cjk_subset.sh`（依赖 `pip install fonttools`），输出集与字符集确定性生成。

## 权衡

- 只打包 Regular 一个字重：bold 用伪粗（Flutter 默认合成），避免体积翻倍。
- 动态内容字符不在子集内时会走系统回退，仍可能有一次轻微闪烁，但 UI 骨架文本（导航、按钮、标签）不再出现 tofu——这正是用户可感知的主要问题。

## 回滚

删除 `assets/fonts/NotoSansSC-Subset.ttf`、pubspec fonts 段与主题 fontFamily 配置即回到现状。
