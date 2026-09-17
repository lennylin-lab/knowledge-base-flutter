# Implement: Web 端中文字体子集化

## 步骤

1. [x] 确认字体源与工具（系统 Noto Sans CJK SC、fonttools 已装）
2. [ ] 写 `scripts/gen_cjk_subset.sh`：收集 `lib/**.dart` 汉字 + 标点 → pyftsubset → `assets/fonts/NotoSansSC-Subset.ttf`
3. [ ] 运行脚本生成字体，检查体积（<1MB）
4. [ ] pubspec.yaml 注册 `NotoSansSC` family 与 asset
5. [ ] 主题接线：`fontFamily` + `fontFamilyFallback`
6. [ ] README 记录再生成方法

## 验证命令

```bash
scripts/gen_cjk_subset.sh
flutter build web --release --wasm
ls -lh build/web/assets/fonts/
# 浏览器冷加载（清缓存）验证无 tofu；子集外字符（如生僻字）仍正常
flutter analyze
```

## 回滚点

任一步失败：`git checkout -- pubspec.yaml lib/ && rm assets/fonts/NotoSansSC-Subset.ttf`
