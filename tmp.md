# 任务：创建 knowledge-base Flutter 前端

## 项目背景

为个人知识库产品创建跨平台 Flutter 前端，对接已有的 Python/FastAPI 后端。

- **后端仓库**：`../knowledge-base-server`（相对路径，与前端同级）
- **目标平台**：Web、Windows、Android（MVP 必须支持；iOS/macOS/Linux 暂不实现）
- **产品定位**：Markdown 知识管理 + 混合检索（BM25 + 向量）+ LLM 问答 Agent
- **用户模型**：单用户 MVP，暂无认证；后端已预留 `owner_id` 字段
  后端默认地址：`http://localhost:8000`  
  OpenAPI 文档：`http://localhost:8000/docs`

---

## 后端 API 契约（必须严格对齐）

所有 REST 错误响应统一格式：

```json
{
  "error": {
    "code": "not_found",
    "message": "Human-readable message",
    "details": {}
  }
}
```

常见 error code：`not_found` (404)、`validation_failed` (422)、`conflict` (409)、`chat_unavailable` (503)、`llm_provider_error` (502)、`rate_limited`
(429)

### 健康检查

- `GET /healthz` → `{ "status": "ok" }`

### 文档 CRUD — `/api/v1/documents`

| 方法                                                                                     | 路径                     | 说明                |
| ---------------------------------------------------------------------------------------- | ------------------------ | ------------------- |
| POST                                                                                     | `/api/v1/documents`      | 创建文档            |
| GET                                                                                      | `/api/v1/documents`      | 列表（keyset 分页） |
| GET                                                                                      | `/api/v1/documents/{id}` | 详情（含 content）  |
| PATCH                                                                                    | `/api/v1/documents/{id}` | 部分更新            |
| DELETE                                                                                   | `/api/v1/documents/{id}` | 软删除 (204)        |
| **DocumentCreate**：`{ "content": string (必填, min 1), "title": string                  | null }`                  |
| content 为完整 Markdown（含 YAML front matter）；title/tags 由后端从 front matter 解析。 |
| **DocumentUpdate**：`{ "content"?: string, "title"?: string }`，至少一个字段。           |
| **DocumentRead**（列表项）：                                                             |

```json
{
  "id": "uuid",
  "title": "string",
  "tags": ["string"],
  "index_status": "pending" | "done" | "failed",
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

**DocumentReadDetail**：DocumentRead + `"content": "string"`
**DocumentPage**：

```json
{
  "items": [DocumentRead],
  "next_cursor": "string | null"
}
```

列表查询参数：`cursor`（可选）、`limit`（1–100，默认 20）、`tag`（可选，按标签过滤）

### 搜索 — `GET /api/v1/search`

查询参数：`q`（必填）、`limit`（1–50，默认 10）、`tag`（可选）
**SearchResponse**：

```json
{
  "mode": "hybrid" | "bm25",
  "items": [
    {
      "document_id": "uuid",
      "document_title": "string",
      "document_tags": ["string"],
      "chunk_index": 0,
      "content": "string",
      "score": 0.0,
      "es_rank": 1,
      "vector_rank": null
    }
  ]
}
```

### 问答 Chat — `POST /api/v1/chat`（SSE 流式）

请求体：

```json
{ "question": "string (min 1)", "limit": 8 }
```

`limit` 范围 1–20，默认 8。
响应：`text/event-stream`，事件类型与 payload：

| event                                                                             | payload                                                                          |
| --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `run_started`                                                                     | `{ "run_id": "uuid", "mode": "hybrid" \| "bm25" }`                               |
| `sources`                                                                         | `{ "items": [SearchHit] }`（可多次，客户端 append）                              |
| `answer_delta`                                                                    | `{ "text": "string" }`                                                           |
| `done`                                                                            | `{ "run_id": "uuid", "outcome": "success", "tool_calls": 0, "latency_ms": 0.0 }` |
| `error`                                                                           | `{ "code": "string", "message": "string" }`（终端事件，流随后关闭）              |
| 正常顺序：`run_started` → 零或多个 `sources` → 一个或多个 `answer_delta` → `done` |
| 失败：终端 `error` 事件（HTTP 可能已是 200，错误在 SSE 内传递）                   |
| **注意**：单轮无状态问答，无会话历史 API。                                        |

---

## MVP 功能范围

### Phase 1（必须交付）

1. **项目脚手架**：Flutter 3.x，启用 web + windows + android
2. **配置**：可配置 API base URL（开发默认 `http://localhost:8000`）
3. **文档列表页**：keyset 分页、标签过滤、显示 index_status
4. **文档详情/编辑页**：Markdown 渲染 + 编辑（创建/更新/删除）
5. **搜索页**：输入 query，展示 SearchHit 列表，点击跳转文档
6. **问答页**：输入问题，SSE 流式展示答案 + 引用来源（sources）
7. **统一错误处理**：解析 `{ error: { code, message, details } }` 与 SSE error 事件
8. **响应式布局**：桌面（Windows/Web 宽屏）侧边栏导航；移动端（Android）底部导航

### Phase 2（可选，不在 MVP）

- 多 Agent（摘要、关联、写作辅助）
- 多轮对话 / 会话持久化
- 用户认证
- 离线缓存

---

## 技术选型建议

| 领域          | 推荐                                                            |
| ------------- | --------------------------------------------------------------- |
| 状态管理      | Riverpod 或 flutter_bloc（选一种并贯穿）                        |
| 路由          | go_router                                                       |
| HTTP          | dio                                                             |
| SSE           | 自定义 dio stream 解析，或 `eventsource` / `flutter_client_sse` |
| JSON 模型     | freezed + json_serializable                                     |
| Markdown 渲染 | flutter_markdown                                                |
| Markdown 编辑 | 先用 TextField；可选 flutter_quill                              |
| 本地配置      | shared_preferences 或 flutter_dotenv                            |
| 代码生成      | build_runner                                                    |

---

## 目录结构建议

knowledge-base-flutter/
├── lib/
│ ├── main.dart
│ ├── app.dart # MaterialApp + 路由 + 主题
│ ├── core/
│ │ ├── config/app_config.dart # baseUrl 等
│ │ ├── network/
│ │ │ ├── api_client.dart
│ │ │ ├── api_exception.dart # 统一 error envelope
│ │ │ └── sse_client.dart # Chat SSE 解析
│ │ └── theme/
│ ├── features/
│ │ ├── documents/ # list / detail / editor
│ │ ├── search/
│ │ └── chat/
│ └── shared/
│ ├── models/ # freezed DTO，与后端 schema 对齐
│ └── widgets/
├── test/
├── web/
├── windows/
├── android/
├── pubspec.yaml
└── README.md

---

## 跨平台注意事项

### Web

- 后端 **尚未配置 CORS**；Web 开发时需在后端添加 CORSMiddleware，或开发期用代理
- SSE 在 Web 上可用 `fetch` + stream，注意 CORS 预检

### Windows

- 默认 `localhost:8000` 可直接访问
- 适配宽屏：NavigationRail 或 Sidebar

### Android

- 模拟器访问宿主机：`http://10.0.2.2:8000`
- 真机：使用局域网 IP
- 需在 AndroidManifest 配置 cleartext（仅开发 HTTP）

### 共享

- 用 `Platform.isAndroid` / `kIsWeb` 等区分 base URL 默认值
- 一套 UI 代码，用 `LayoutBuilder` / `Breakpoint` 做 adaptive layout

---

## 开发流程

1. 创建项目：
   ```bash
   cd ../
   flutter create knowledge-base-flutter --platforms=web,windows,android
   cd knowledge-base-flutter
   ```
2. 后端联调前确保后端运行：
   ```bash
   cd ../knowledge-base-server
   docker compose up -d
   uv run alembic upgrade head
   uv run uvicorn app.main:app --reload
   ```
3. 实现顺序建议：
   - core/network + models
   - documents CRUD
   - search
   - chat SSE（最复杂，放最后）
   - adaptive shell + 主题
4. 质量要求：
   - `flutter analyze` 无 error
   - 核心 repository / SSE parser 有 unit test
   - README 含三平台运行命令

---

## 设计原则

1. **API 层与 UI 分离**：Repository 封装 HTTP/SSE，Widget 不直接调 dio
2. **DTO 与后端一一对应**：字段名、枚举值、nullable 保持一致
3. **SSE 状态机**：明确处理 run_started → sources* → answer_delta* → done | error
4. **index_status 展示**：pending 显示加载态，failed 显示重试提示
5. **引用来源**：Chat 答案中的 `[1]` 等编号对应 sources 列表顺序
6. **中文优先 UI**：界面文案默认中文，答案语言由 LLM 按问题语言回复（后端行为）
7. **最小依赖**：不引入过重框架，MVP 够用即可

---

## 交付物

- [ ] 可运行的 Flutter 项目（web / windows / android）
- [ ] 对接全部现有后端 API
- [ ] README：安装、配置、三平台运行、后端联调说明
- [ ] 基础 widget test 或 unit test（至少 SSE parser + error envelope）
      请先搭建项目脚手架与 core 层（config、api_client、models），再按 documents → search → chat 顺序实现各 feature。每完成一个 feature
      给出可运行的验证步骤。
