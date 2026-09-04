# knowledge-base-flutter

个人知识库的 Flutter 客户端（**Web / Windows / Android**），对接
[`knowledge-base-server`](../knowledge-base-server)（Python/FastAPI）。

功能：
- **文档管理** — Markdown 列表（keyset 分页 + 标签过滤）、详情渲染、
  全文编辑（YAML front matter 解析 title/tags）、软删除
- **混合检索** — BM25 + 向量，命中片段、得分与 ES/向量排名展示
- **问答 Agent** — SSE 流式答案（Markdown 渲染）+ 引用来源联动
  （答案中 `[n]` 对应下方来源序号，点击跳转文档）

> 单用户 MVP：无认证；后端已预留 `owner_id`。UI 中文优先。

---

## 环境要求

- Flutter 3.41+（stable 渠道）
- 后端服务：`../knowledge-base-server`（见「后端联调」）

## 安装与运行

```bash
flutter pub get
```

| 平台 | 命令 | 说明 |
|---|---|---|
| Web | `flutter run -d chrome` | 开发调试；`flutter build web --release` 产出 `build/web` |
| Windows | `flutter run -d windows` | 需 Windows 主机 + Visual Studio C++ 工具链；`flutter build windows` 产出 `build/windows` |
| Android | `flutter run -d <device>` | 模拟器/真机；`flutter build apk --debug` 产出 `app-debug.apk` |

> 当前仓库在 Linux 上开发验证：Web 与 Android 构建已通过；
> Windows 构建命令在 Windows 主机上执行。

## 配置（API base URL）

默认值按平台自动选择，无需配置：

| 平台 | 默认地址 |
|---|---|
| Web / Windows | `http://localhost:8000` |
| Android 模拟器 | `http://10.0.2.2:8000`（宿主机） |
| Android 真机 | 需在应用内设置中改为局域网 IP |

> 真机覆盖：应用内可修改 base URL（持久化于本地 shared_preferences）。
> 运行时可传入 `--dart-define=API_BASE_URL=http://192.168.x.x:8000` 覆盖默认。

### Android 开发期 HTTP

`android/app/src/debug/AndroidManifest.xml` 已配置
`android:usesCleartextTraffic="true"`（**仅 debug 构建**；release 不受影响）。

## 后端联调

启动后端（`knowledge-base-server` 目录内）：

```bash
docker compose up -d          # Elasticsearch + PostgreSQL
uv run alembic upgrade head   # 迁移
uv run uvicorn app.main:app --reload   # http://localhost:8000
```

联调验证：`curl http://localhost:8000/healthz` → `{"status":"ok"}`；
OpenAPI 文档：`http://localhost:8000/docs`。

### Web 端 CORS

后端已通过 `KB_CORS_ORIGINS` 配置 CORS（空列表 = 不启用，生产默认）。
本地开发在 `knowledge-base-server/.env` 中设置：

```bash
KB_CORS_ORIGINS=["*"]   # 允许任意来源（本地最省事）
# 或显式允许 Flutter dev server 来源，例如：
# KB_CORS_ORIGINS=["http://localhost:8080"]
```

配置后 Web 端可直接联调：

```bash
flutter run -d chrome   # 默认请求 http://localhost:8000
```

> 备选：若后端未开 CORS，仍可用 dev 代理（`--dart-define=API_BASE_URL=...`
> 指向代理地址）或 `--web-port` 固定端口后在 `KB_CORS_ORIGINS` 中显式列出。

## 测试

```bash
flutter analyze   # 零 error/warning
flutter test      # 126 个测试：SSE parser、错误信封、DTO round-trip、
                  # repository/providers/pages（文档/搜索/问答）
```

## 已知限制（MVP）

- 搜索与问答依赖后端索引流水线，而索引需要 LLM embedding 提供方：
  - 后端未配置 `OPENAI_API_KEY`（或本地 embedding）时，文档会停留在
    `index_status: pending/failed`，搜索/问答返回 502 `search_index_error`
    / `llm_provider_error`（前端已按错误信封优雅呈现）
  - 配置凭据后运行后端仓库的 `uv run python -m app.cli reindex` 补索引
- 问答为单轮无状态（无会话历史 API）；多 Agent / 多轮 / 认证 / 离线缓存
  属 Phase 2，不在本版
- iOS / macOS / Linux 平台目录未创建

## 项目结构

```
lib/
├── main.dart / app.dart      # 入口、go_router、自适应 Shell
├── core/
│   ├── config/               # AppConfig（平台感知 base URL）
│   ├── network/              # dio 客户端、错误信封、SSE 双传输客户端
│   └── theme/                # Material 3 主题（浅色/深色）
├── features/
│   ├── documents/            # 列表 / 详情 / 编辑器 + repository + providers
│   ├── search/               # 混合检索页
│   └── chat/                 # SSE 问答页（状态机）
└── shared/
    ├── models/               # freezed DTO（与后端 schema 一一对应）
    └── widgets/              # 状态徽章、Markdown 渲染、格式化
```

详细约定见 `.trellis/spec/`（目录结构、组件、状态管理、类型安全、质量门禁）。
