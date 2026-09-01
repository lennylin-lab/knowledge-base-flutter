# Design: MVP Phase 1

> 技术设计。目录/命名/禁用模式等已固化在 `.trellis/spec/frontend/*` 与
> `.trellis/spec/backend/*`（契约），此处只写本任务的边界、数据流与取舍。

## 1. 分层架构

```
┌─ Pages (features/*/*_page.dart, ConsumerWidget)
├─ Providers (features/*/<f>_providers.dart, Riverpod)
├─ Repositories (features/*/<f>_repository.dart)   ← 每端点一个方法
├─ core/network: ApiClient(dio) · SSEClient · ApiException
├─ shared/models: freezed DTO（唯一 JSON 边界）
└─ FastAPI backend (../knowledge-base-server)
```

依赖方向单向向下；features 之间互不 import，跨页跳转走 go_router 路由名。

## 2. 技术选型（锁定，遵循「最小依赖」）

| 用途 | 包 | 备注 |
|---|---|---|
| 状态 | flutter_riverpod | AsyncNotifier（列表/详情）+ Notifier（chat 流） |
| 路由 | go_router | StatefulShellRoute 做三页签 |
| HTTP | dio | 拦截器统一解码错误信封 |
| SSE | dio `ResponseType.stream`（原生）/ `package:web` fetch+reader（Web） | 见 §5 |
| DTO | freezed + json_serializable + build_runner | `fieldRename: FieldRename.snake` |
| Markdown 渲染 | flutter_markdown_plus | flutter_markdown 已停维护 |
| 本地配置 | shared_preferences | 持久化用户覆盖的 baseUrl |
| 时间格式化 | intl (DateFormat) | 仅展示层 |

不引入：riverpod_generator / custom_lint / bloc / quill（编辑用 TextField）。

## 3. 配置（core/config/app_config.dart）

- `AppConfig.defaultBaseUrl`：`kIsWeb || windows → http://localhost:8000`；
  `Platform.isAndroid → http://10.0.2.2:8000`（真机用户可覆盖）
- 启动时读 shared_preferences 的用户覆盖值，无则用默认；
  设置入口放问答/文档页 AppBar 的设置弹窗（MVP 简化，不做独立设置页）
- 经 `Provider<AppConfig>` 暴露；`apiClientProvider` 依赖它构造 dio

## 4. 错误处理（core/network/api_exception.dart）

- `ApiException(code, message, details, {statusCode})`
- dio interceptor（onError）：body 可解析出 `error.code` → ApiException；
  否则归一为 `network_error` / `server_error`；204/2xx 直接放行
- UI 呈现规则按 spec：中文前缀 + 后端 message 原样；429 提示稍后重试；
  404 详情页视为已删除并返回列表

## 5. SSE 客户端（core/network/sse_client.dart）—— 本任务最复杂件

**统一出口**：`Stream<ChatEvent> chatStream(ChatRequest req)`，
`ChatEvent` 为 sealed class：`RunStarted / Sources / AnswerDelta / ChatDone / ChatError`。

**双传输**：
- 原生（windows/android）：dio POST `ResponseType.stream`，读 byte stream →
  UTF-8 解码（注意多字节跨分片，用增量解码器）
- Web：dio(XHR) 不支持流式读取 → 条件编译 `kIsWeb` 走 `package:web` 的
  `fetch` + `response.body!.getReader()`，解析逻辑与原生共用同一 parser

**解析器**（纯函数、可单测）：输入任意切分的文本 chunk 序列，输出事件流。
- 事件分隔 `\n\n`，`event:` 行 + `data:` 行；data 为 JSON
- 半个事件留在缓冲区等下个 chunk；`data` 内换行按 SSE 规范拼接
- 状态机校验顺序：收到 `done`/`error` 后忽略后续事件直至流关闭

## 6. DTO（shared/models/）

按 spec type-safety.md 的映射表实现全部 10 个模型 + ApiErrorEnvelope。
`esRank` int、`vectorRank` int?、`nextCursor` String?、enum 解析带兜底。

## 7. 状态设计

| Provider | 类型 | 职责 |
|---|---|---|
| `appConfigProvider` | Provider | baseUrl |
| `documentsProvider` | AsyncNotifier | 列表 + next_cursor + loadNext/refresh |
| `documentDetailProvider(id)` | FutureProvider.family | 详情；编辑后 invalidate |
| `searchResultsProvider` | Notifier | query/tag → 结果 |
| `chatProvider` | Notifier<ChatState> | SSE 状态机（idle/running/streaming/done/error）+ sources 累积 |

Chat 详见 spec state-management.md 的状态机；`ref.onDispose` 取消订阅。

## 8. 路由与自适应 Shell

- go_router `StatefulShellRoute.indexedStack`：`/documents`、`/search`、`/chat`
- 子路由：`/documents/:id`（详情）、`/documents/new`、`/documents/:id/edit`
- Shell 组件按宽度切换：≥840 `NavigationRail`（含扩展模式），<600
  `NavigationBar`；600–840 用折叠 Rail；目的地固定三项：文档/搜索/问答
- 主题：Material 3，跟随系统深浅色，中文文案

## 9. 兼容性 / 风险 / 回滚

| 风险 | 缓解 |
|---|---|
| Web CORS（后端未配置） | README 给两条路：`flutter run -d chrome --web-browser-flag` 不行则 dev proxy（`--dart-define` + flutter run 代理）或后端加 CORSMiddleware（后端仓库流程） |
| Web SSE fetch 流式兼容 | Chrome/Edge 支持 ReadableStream；实现时留 dio 降级开关（dart-define）便于排查 |
| Android cleartext | `android:usesCleartextTraffic="true"`（debug）+ `network_security_config` 仅 debug 生效 |
| 契约漂移 | fixture JSON 与 `/docs` 核对后才改 DTO（spec backend/quality） |

**回滚**：每个实现阶段独立 commit（见 implement.md），出问题 `git revert`
单阶段提交即可，不影响已验收的前序阶段。

## 10. 测试策略

- 单元：sse parser（分片/多 sources/终端 error/乱序防御）、信封解码、
  DTO round-trip（fixtures 对齐后端 OpenAPI）
- Widget：app 启动 + 三页签切换冒烟
- 手工冒烟：按 implement.md 每阶段的验证步骤（后端本地起服务）
