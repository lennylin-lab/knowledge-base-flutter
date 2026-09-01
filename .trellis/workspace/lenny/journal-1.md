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
