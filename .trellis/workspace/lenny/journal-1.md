# Journal - lenny (Part 1)

> AI development session journal
> Started: 2026-09-01

---

## 2026-09-01 — mvp-phase1 Stage 0+1

- Stage 0+1（依赖骨架 + core/DTO/SSE/单测 + bootstrap）由 trellis-implement 完成；
  中途因账号 5 小时使用上限中断一次，transcript 丢失，剩余 10 个 analyze 问题由
  主会话外科手术式修复。
- **freezed 教训**（已验证两次重跑 codegen）：本版本 freezed 不会把用户在类体里
  声明的具体方法传递到 `implements` 风格的实现类 → 编译错误
  "Missing concrete implementation"。解法：投影/辅助方法放 extension。
- **package:web interop**：`JSObject.setProperty/getProperty` 在
  `dart:js_interop` 里不存在，必须 `import 'dart:js_interop_unsafe'`；
  `HeadersInit` 就是 `JSObject` 的 typedef；`JSPromise<JSString>.toDart` 得到
  JSString，还要再 `.toDart` 才是 String。
- build_runner 按内容哈希跳过未变文件，`touch` 无效；改内容才能强制重生成。
- 门禁：analyze 零问题；57 测试全绿。待 trellis-check 复核后按 Stage 边界提交。


## Session 1: 响应式视口缩放尺寸体系

**Date**: 2026-09-06
**Task**: 响应式视口缩放尺寸体系
**Branch**: `main`

### Summary

Built the viewport-fluid sizing system: AppSizes ThemeExtension tokens (spacing/icons/component metrics) + scaleForWidth (1.0 below 600px, linear 1.0→1.2 over 600–1600, 0.01 quantized) consumed via context.sizes; AppTheme scales typography geometry (M3 textTheme carries no sizes — scale via Typography.material2021 englishLike/dense/tall), iconTheme, and caches ThemeData per quantized scale; replaced ~35 hardcoded sizes across 5 pages + 3 shared widgets; 10 new tests, full suite 150 green. Conventions captured into component-guidelines/quality-guidelines specs.

### Git Commits

| Hash | Message |
|------|---------|
| `6c4bfc6` | (see git log) |
| `76abc02` | (see git log) |

### Status

[OK] **Completed**


## Session 2: Trellis 入职引导完成

**Date**: 2026-09-10
**Task**: Trellis 入职引导完成
**Branch**: `main`

### Summary

完成 00-join-lenny 入职任务：了解 Trellis 三阶段工作流、SessionStart 注入机制、项目 frontend spec 约定与归档节奏；任务已 finish + archive。

### Git Commits

(No commits - planning session)

### Status

[OK] **Completed**
