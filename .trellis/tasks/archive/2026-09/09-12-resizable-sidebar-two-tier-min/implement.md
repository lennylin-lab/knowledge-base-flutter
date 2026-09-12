# Implement: 可拖拽侧边栏分隔条与两层缩小界限

## 执行清单（顺序）

1. **阅读 spec**（`trellis-before-dev`，frontend 层）：`.trellis/spec/frontend/component-guidelines.md`、`state-management.md`、`quality-guidelines.md`。
2. **通用组件**：`lib/shared/widgets/resizable_pane.dart`（`ResizablePane` + drag handle，含两层界限渲染逻辑、clamp、光标/视觉反馈）+ 单元/widget 测试（层一前后渲染分支、clamp 上/下限、窗口兜底）。
3. **持久化**：`lib/core/layout/layout_preferences_providers.dart`（`LayoutWidths` + `Notifier` + shared_preferences 读写，key `layout.pane_width.<paneId>`）；`main()` 首帧前加载 override；测试。
4. **rail 落地**：改 `lib/app.dart:163-191`，用 `ResizablePane` 包裹 rail（未拖拽时保持现状），handle 在 rail 右缘，`extended` 逻辑按 design 推导。
5. **文档页落地**：改 `lib/features/documents/documents_page.dart:70-134`，列表栏改用 `ResizablePane`（默认 340，a=300，b=240，max=520），详情栏保持 `Expanded`；仅双/三栏激活时渲染 handle。
6. **质量门**：`flutter analyze`、相关 `flutter test`；手动验证 AC1–AC5（桌面运行）。

## 验证命令

```bash
flutter analyze
flutter test test/shared/widgets/resizable_pane_test.dart test/core/layout/
```

## 风险文件与回滚点

- `lib/app.dart`（shell 布局，改动需小心 <600 回退路径）— 出问题 revert 包裹改动即可。
- `lib/features/documents/documents_page.dart`（双栏阈值逻辑）。

## start 前检查

- [ ] prd.md 收敛完成，无阻塞 open question
- [ ] design.md / implement.md 就绪
- [ ] implement.jsonl / check.jsonl 已含真实 spec 条目（本任务采用 inline 工作流则跳过 JSONL 门）
