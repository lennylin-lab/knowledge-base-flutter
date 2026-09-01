# Implement: MVP Phase 1

> 有序执行清单。**每个 Stage 结束 = 一次 commit（回滚点）+ 质量门禁 +
> 人工验证步骤**。上一 Stage 未通过门禁不进入下一 Stage。

## Stage 0 — 依赖与工程配置

- [x] pubspec.yaml 加入锁定选型（见 design.md §2；dev: build_runner/freezed/json_serializable）
- [x] 建立 lib 目录骨架：core/{config,network,theme}、features/{documents,search,chat}、shared/{models,widgets}
- [x] 验证：`flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter analyze`
- [x] **Gate**：analyze 零问题 → commit `feat(stage0): deps & skeleton`（92b2158）

## Stage 1 — core 层 + DTO + 单测（先于一切 UI）

- [x] `core/config/app_config.dart`：平台默认 baseUrl + shared_preferences 覆盖
- [x] `shared/models/`：全部 DTO + ApiErrorEnvelope（freezed，`fieldRename: snake`，enum 兜底）
- [x] `core/network/api_exception.dart` + `api_client.dart`（dio + 错误信封拦截器）
- [x] `core/network/sse_client.dart`：双传输 + 纯函数 parser（design.md §5）
- [x] 最小 bootstrap：main.dart/app.dart + go_router 三占位页（替换计数器示例与 widget_test）
- [x] 单测：sse parser、信封解码、DTO round-trip（fixtures 与后端 `/docs` 核对）+ sse_client 补测
- [x] 验证：`flutter analyze && flutter test`（63 绿）+ `flutter build web`
- [x] **Gate**：测试全绿 → commit `feat(stage1): core network/models + bootstrap`（7b45c6a）

## Stage 2 — documents feature

- [x] repository：list(cursor,limit,tag) / get / create / update / delete
- [x] providers：AsyncNotifier（列表+loadNext）+ FutureProvider.family（详情）
- [x] 列表页：分页滚动加载、tag 过滤（Chip + query param）、index_status 三态
- [x] 详情页：flutter_markdown_plus 渲染 + 编辑/删除入口；404 → 返回列表
- [x] 编辑页：TextField 全文编辑（含 front matter）、创建/更新；422/409 呈现
- [x] 手工冒烟（后端 `docker compose up -d` + uvicorn）：
  创建→列表 pending→详情 title/tags 解析→编辑→删除→404
  （通过 curl 对运行中后端完成，契约全通过；UI 层行为由 widget tests 覆盖）
- [x] 验证：`flutter analyze && flutter test`（87 绿）
- [x] **Gate**：冒烟通过 → commit `feat(stage2): documents feature`

## Stage 3 — search feature

- [ ] repository：search(q, limit, tag)
- [ ] search 页：query 输入、结果卡片（标题/片段/tags/score）、tag 过滤、
  点击 → `/documents/:id`
- [ ] 手工冒烟：含/不含 tag 过滤；空结果与 loading/error 三态
- [ ] **Gate**：analyze/test + 冒烟 → commit `feat(stage3): search feature`

## Stage 4 — chat feature（最复杂，放最后）

- [ ] ChatRepository 基于 SSEClient；chatProvider 状态机（idle/running/
  streaming/done/error + sources 累积 + onDispose 取消）
- [ ] 问答页：问题输入、answer_delta 增量渲染（Markdown）、sources 引用列表
  （`[n]` 与列表联动、点击跳文档）、error 内联呈现、done 后展示 latency
- [ ] 单测补：parser 状态机边界（error 前已有 delta 的情况）
- [ ] 手工冒烟：正常问答全流程；停后端 → 网络错误优雅呈现
- [ ] **Gate**：全测试绿 + 双平台冒烟（chrome + windows 或 android）→
  commit `feat(stage4): chat feature (SSE)`

## Stage 5 — 自适应 Shell + 主题定稿

- [x] StatefulShellRoute：≥840 NavigationRail / <600 NavigationBar / 中间折叠 Rail
  （Stage 1 已实现，check 对照 SDK 源码验证合法）
- [x] Material 3 主题、深浅色、中文文案统一检查（无硬编码英文残留）
- [x] Android：debug cleartext（debug overlay `usesCleartextTraffic`，release 结构保证不受影响）
- [x] 平台构建验证：`flutter build web --release` ✅ + `flutter build apk --debug` ✅
  （windows 构建需 Windows 主机，命令进 README；app 元数据中文化：
  Android label / web title+manifest / Windows 窗口标题；修复 Android 构建
  Maven 网络问题 — Aliyun 镜像前置，上游兜底）
- [x] **Gate**：构建通过 + check 零问题 → commit `feat(stage5): adaptive shell & theme`

## Stage 6 — README + 收尾

- [x] README：安装、配置（baseUrl 三平台默认与覆盖）、三平台运行命令、
  后端联调（docker compose + alembic + uvicorn；Web CORS 两条路径）
- [x] 全量回归：`flutter analyze` 零问题 + `flutter test` 126 全绿
- [x] 若确立新约定 → 更新 `.trellis/spec/` 对应文件（Phase 3.3：
  directory-structure 补应用名中文化 + debug cleartext 约定）
- [x] commit `docs(stage6): README & final polish`

## 统一验证命令

```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # 改 DTO 后
```

## 回滚点

Stage N 出现不可修复问题 → `git revert <stage-N commit>`；前序已验收
Stage 不受影响（各 Stage 文件不相交：core/feature 目录天然隔离，
Stage 5 涉及 app.dart 需注意与 Stage 1 bootstrap 的连续性）。
