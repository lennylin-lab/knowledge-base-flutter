# MVP Phase 1: core layer, documents, search, chat

> 需求来源：仓库根目录 `tmp.md`（项目简报）。本文件只写需求、约束与验收标准；
> 技术设计见 `design.md`，执行计划见 `implement.md`。

## Goal

交付可运行的 Flutter 客户端（Web / Windows / Android），对接
`../knowledge-base-server` 全部现有 API：文档 CRUD、混合检索、SSE 流式问答。

## Background

- 产品定位：Markdown 知识管理 + 混合检索（BM25 + 向量）+ LLM 问答 Agent
- 单用户 MVP，无认证；后端已预留 `owner_id`
- 后端默认 `http://localhost:8000`，OpenAPI: `/docs`
- REST 错误统一信封 `{ error: { code, message, details } }`；Chat 走 SSE，
  事件序 `run_started → sources* → answer_delta* → done | error`

## Requirements（范围内，MVP 必须交付）

1. **配置**：API base URL 可配置；开发默认值按平台区分
   （web/windows `http://localhost:8000`；Android 模拟器 `http://10.0.2.2:8000`）
2. **文档列表页**：keyset 分页（cursor/next_cursor）、标签过滤、
   展示 `index_status`（pending 加载态 / failed 重试提示）
3. **文档详情/编辑页**：Markdown 渲染 + 创建/更新/删除
   （创建/更新发送完整 Markdown 含 YAML front matter，title/tags 由后端解析）
4. **搜索页**：输入 query，展示 SearchHit 列表，点击跳转文档详情
5. **问答页**：输入问题，SSE 流式渲染答案 + 引用来源（sources）；
   答案中 `[n]` 对应 sources 累积列表第 n 项
6. **统一错误处理**：解析 REST 错误信封与 SSE error 终端事件，
   中文文案呈现，不向用户暴露原始 JSON/栈信息
7. **响应式布局**：桌面（Windows/Web 宽屏）侧边导航；移动端（Android）底部导航
8. **README**：安装、配置、三平台运行命令、后端联调说明

## Out of Scope（明确不做）

- iOS / macOS / Linux 平台目录
- 多 Agent、多轮对话/会话持久化、用户认证、离线缓存（Phase 2）
- 客户端直连数据库、客户端侧分页/标签过滤逻辑（一律走服务端）
- LLM 答案翻译或裁剪（原样渲染）

## Constraints

- 严格对齐后端契约：DTO 字段名、枚举值（`pending|done|failed`、
  `hybrid|bm25`）、nullable 语义 1:1；limit 范围
  documents 1–100 / search 1–50 / chat 1–20
- API 层与 UI 分离：Widget 不直接调用 dio；DTO 是唯一触碰原始 JSON 的层
- 单轮无状态问答：无会话历史 API，不做多轮
- UI 文案中文优先；遵循 `.trellis/spec/frontend/*` 已确立约定
- 最小依赖原则（见 design.md 技术选型，不再额外引入重型框架）

## Acceptance Criteria

- [ ] `flutter analyze` 无 error/warning；`flutter test` 全绿
- [ ] 单元测试覆盖：SSE parser（事件序、多 sources、终端 error、分片缓冲）、
      错误信封解码（404/409/422/429/502/503 + 非信封体）、DTO round-trip
- [ ] 三平台可启动并连上后端完成冒烟：创建→列表（pending→done）→详情→
      编辑→删除→404；搜索（含 tag 过滤）；问答流式 + 引用点击跳转
- [ ] Web 端 CORS 联调路径在 README 中有明确说明（代理或后端加 CORSMiddleware）
- [ ] AndroidManifest 已配置开发期 cleartext 许可
- [ ] README 含三平台运行命令与后端启动步骤
- [ ] `.trellis/spec/` 若实现中确立新约定，同步更新对应规范文件
