# 编辑草稿：dirty flag + 本地草稿 + 恢复流程

## Goal

编辑器未保存内容不再因 token 过期/登出丢失（knowledge-base-flutter#5）：dirty flag 驱动未保存指示与返回拦截，未保存内容 debounce 落盘 shared_preferences（登出不清除），重开编辑器按 `content_hash` 基线校验恢复，保存经 `expected_content_hash` 乐观并发（409 冲突分支）。

后端依赖 **knowledge-base-server#2 已实现**（本地 main 提交 `b62296b`，Closes #2，尚未推送/部署）。

## 后端契约（已核对实现，以此为准）

1. `GET /documents/{id}` 详情响应新增 `"content_hash": "str | null"`（仅 detail；列表响应没有。null = pre-backfill 未回填行，语义 "unknown，跳过校验"）。
2. `PATCH /documents/{id}` 请求体新增可选 `"expected_content_hash": "str"`：
   - 非 null 且库内 hash 非 null 且不匹配 → **409 `conflict`**，details 键为 `expected_content_hash` / `actual_content_hash`（注意：不是 issue 草稿里的 expected/current）；
   - 校验在任何 mutation 之前（写前拒绝，文档不被改动）；
   - 请求不带该字段 → 行为与现状完全一致；
   - 库内 hash 为 null → 跳过校验（永不因 unknown 报 409）。
3. **守卫不是变更**：只传 `expected_content_hash` 不传 content/title → 422 `validation_failed`（一字段规则不含守卫字段）。发送时必须至少带 content 或 title。
4. sha256 是服务端内部实现，**前端从不计算哈希**，只透传比对服务器产物。

## Requirements

### 1. DTO（lib/shared/models/document.dart + 重新 codegen）

- `DocumentReadDetail` 增加 `contentHash`（`String?`）。wire 全局 `field_rename: snake`（build.yaml）自动映射 `content_hash`；**JSON 侧必须容忍字段缺失**（后端未部署时旧服务端不返回该键）→ 保证缺键解码不炸（对照 type-safety spec 的防御性解析要求，如 `unknownEnumValue` 的处理方式）。
- `DocumentUpdate` 增加 `expectedContentHash`（`String?`，`@JsonKey(includeIfNull: false)` —— null 时整个键不出现在 wire 上）。
- 跑 build_runner，更新 dto_roundtrip_test。

### 2. EditDraft 本地仓库（新文件，建议 lib/features/documents/edit_draft_store.dart）

- 数据：`{scopeKey, content, titleOverride, baselineContentHash: String?, savedAt}`，scopeKey = 文档 id 或固定 `"new"`（新建模式）。
- 存储：`SharedPreferences`（模式对照 theme_preferences：直接 `getInstance()`，key 风格如 `documents.edit_draft.<scopeKey>`）。
- API：`load` / `save` / `clear`；content > 1MB 时跳过持久化（防 web localStorage 撑爆，仅内存态继续工作）。存储读写失败不得抛出中断编辑（吞掉并忽略——草稿是尽力而为的安全网）。
- 登出**不清除**（这正是 issue #5 场景的解法：重新登录后可恢复）。

### 3. 编辑器状态机（document_editor_page.dart）

**dirty 判定（无哈希热路径）**：

- 打开时记 `_baselineContent`（加载的原文）与 `_baselineHash`（detail 的 contentHash，可 null）。
- controller listener：已 dirty 则粘性跳过；未脏时做早退字符串比较 `content != _baselineContent || titleOverride != ''`。
- dirty 复原检查放 debounce tick：`buffer == baseline && titleOverride == ''` → 置回 clean 并清除已存草稿。

**debounce（≈1s，仅 dirty 时）**：把当前 buffer/title/`_baselineHash` 写入 EditDraft。保存失败的 catch 里立即补一次落盘（不等 debounce）。

**保存**：

- 编辑模式且 `_baselineHash != null` → `DocumentUpdate(expectedContentHash: _baselineHash, ...)`；`_baselineHash == null`（旧后端 / pre-backfill）→ 不带该字段。
- **保存成功后 `_baselineHash = null`**（更新响应 DocumentRead 不含新 hash，客户端不本地计算；置 null 使下次保存退化为 last-write-wins，重开编辑器自然拿到新 hash）——避免滞留旧 hash 导致下一次保存误 409。同时 `_baselineContent` 更新为已存内容、清本地草稿、dirty 置 clean。
- 409 conflict：沿用现有 `_showConflictMessage`（含「重新加载」分支）；重新加载需同步清本地草稿并重置基线。
- 其他失败（含 401）：toast 文案体现「未保存内容已保留，重新登录后可恢复」。

**恢复流程**（编辑器打开时查到本地草稿）：

- 编辑模式：`draft.baselineContentHash == detail.contentHash`（含两者均 null 视为可恢复）→ 恢复 controllers + toast「已恢复未保存的草稿」；不一致 → 对话框「文档已在别处修改，检测到未保存的草稿」[用草稿][用最新内容]，选草稿时以**服务器当前 hash** 为新 `_baselineHash`。
- 新建模式（scopeKey="new"）：存在即恢复 + toast。
- 恢复动作置 dirty = true（内容 != 基线）。

**UI**：

- AppBar 保存按钮旁 dirty 指示（小圆点或「未保存」文案，跟随 component-guidelines 的风格 token）。
- PopScope：dirty 时拦截系统/手势返回，弹对话框 [保存] [保留草稿退出] [放弃]；放弃直接退出不二次确认（草稿已在盘，数据不丢）。

### 4. 与现状的衔接

- 详情页 checkbox 写回（既有功能）是即时保存，不涉及草稿；401 toast 文案与编辑器保持一致口径即可。
- AI 续写的「草稿」（operations draft）与本期「编辑草稿」是不同概念，UI 文案用「未保存的更改 / 本地草稿」避免混淆。

## Acceptance Criteria

- [ ] 输入 → AppBar 出现未保存指示；约 1s 后本地草稿落盘；停止输入且内容回到基线 → dirty 复原、草稿清除。
- [ ] 编辑中途杀掉 app → 重开编辑器 → 草稿恢复（hash 匹配路径）。
- [ ] 保存请求携带 `expected_content_hash`（stub 断言 updateCalls payload）；保存成功后同会话再改再存，payload **不含**该字段。
- [ ] 服务端 409 → 现有冲突提示，文档未被前端覆盖；「重新加载」后草稿被清。
- [ ] 保存失败（网络/401）→ toast 含「已保留」文案，草稿在盘。
- [ ] PopScope：dirty 拦截，三个选项行为正确；clean 时直接返回。
- [ ] DTO roundtrip：contentHash 缺键解码不炸；expectedContentHash 为 null 时 wire 无该键。
- [ ] EditDraftStore：roundtrip、>1MB 跳过、clear；存储异常不抛出。
- [ ] `flutter analyze` 无告警、全量 `flutter test` 通过。

## 非目标

- 服务端草稿实体、编辑器自动保存（PATCH 版）、主动 token 刷新（后续可选项）。
- chat / AI 摘要视图的编辑草稿。
- 后端改动（已在 knowledge-base-server#2 完成，待推送部署）。
