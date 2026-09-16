# 气泡「AI 续写」写作代理流

## Goal

Add a third assistant-bubble menu entry 「AI 续写」 whose content layer hosts
the writing-agent workflow against the already-aligned operations API
(`lib/features/operations/`): instruction input → generate draft
(synchronous LLM, seconds-long wait) → draft review (Markdown) → apply with
confirmation (overwrites the document; 409 optimistic-concurrency handling)
→ resume on failed/interrupted → per-document operation history. Applying
must invalidate the document caches so the detail body refetches.

## Background / Evidence

- Server contract + lifecycle: `.trellis/tasks/archive/2026-09/09-16-operations-api-alignment/research-operations-contract.md`
  (authoritative). Key points: draft is synchronous JSON (`draft({documentId,
  instruction})`, running→completed/failed persisted, never auto-applies);
  resume only from interrupted/failed (409 otherwise); apply is the only
  publish path — idempotent replay, replaces document content/title/tags
  (front matter re-derived), `index_status → pending`, creates a revision,
  and bumps `document.updated_at` (stale base → 409 with
  `details.base_version`/`details.current_version`, zero writes). There is
  **no revert**: apply overwrites the document client-visibly permanently
  (revision rows are not exposed) → confirmation dialog mandatory.
- Bubble IA (current): menu layer + content layers (summary/associations)
  inside `AiAssistantFab`; layer keep-alive across dismiss; PopScope gate
  `layer == menu || !open`; providers per-document family with
  generation-counter guards; keep-alive provider watches at menu layer.
- Apply-response `document.updated_at` differs from the pre-apply document —
  after a successful apply the detail body and list are stale until
  invalidated.
- Draft content is raw markdown **with** YAML front matter (that is where
  title/tags derive at apply) — display must strip front matter and render
  via the shared `MarkdownContent` (type-safety/component spec: LLM prose
  always through the shared pipeline).

## Requirements

1. **Menu**: third entry 「AI 续写」 (icon + label + one-line description,
   same `_AiBubbleEntry` pattern) → content layer `writing`.
2. **State machine** (`operations_providers.dart`, per-document family,
   following the `OnDemandGenerationNotifier` guard idioms — synchronous
   in-flight no-op, generation counter dropping stale writes, failure keeps
   prior state visible): a `WritingState` holding `operation`
   (OperationReadDetail?), `phase` (idle/generating/review/applying),
   `errorMessage`, `history` (List<OperationReadDetail>?), with actions
   `generate({instruction})`, `resumeCurrent()`, `applyCurrent()`,
   `openOperation(OperationReadDetail)` (from history), `clearCurrent()`
   (back to idle). Providers stay alive while the surface is open (same
   keep-alive watch approach). Document switch resets (bubble already
   resets layer; the provider is per-document family so state is fresh).
3. **Writing layer UI** (in the bubble, same sizing/scroll/dead-end rules as
   the other content layers):
   - **Idle**: instruction input (optional, Chinese hint copy like
     「想让 AI 重点处理什么？可留空」), 生成草稿 button → `generate`.
     Generating: spinner + 「正在生成草稿… · 同步生成可能需要数秒」 (no
     progress events — plain spinner, do NOT hang the test pumps on it).
   - **Draft ready** (`state == completed`, draft non-null): draft title
     (draft.title or fallback), body rendered via `MarkdownContent(data:
     stripYamlFrontMatter(draft.content))`; actions: 应用到文档
     (confirmation dialog first — copy must state it will overwrite the
     document's content/title/tags and cannot be undone from the client),
     重新生成 (back to generate with the previous instruction prefilled),
     返回菜单.
   - **Failed / interrupted** operation: friendly copy (503
     `chat_unavailable` friendly text; 502 `llm_provider_error` →
     「生成失败：{message}」) + actions 恢复 (`resumeCurrent`, only when
     state ∈ {interrupted, failed}) and 重新生成.
   - **Applying**: actions disabled; success → applied confirmation view
     (「已应用到文档」 + a hint that re-indexing is running
     「文档将在后台重新索引」) with 返回菜单 / 查看文档 (close bubble);
     failure → error copy + retry (409 → 「文档已更新，草稿基于旧版本，
     请重新生成草稿」 with a 重新生成 action).
4. **Cache invalidation on apply success**: invalidate
   `documentDetailProvider(documentId)` and `documentsProvider` so the
   detail body refetches the applied content (the bubble stays usable;
   the markdown body behind it refetches).
5. **History**: secondary 「历史操作」 affordance in the writing layer →
   `operationsForDocument(documentId)` (spinner + error/retry); items show
   state + `updated_at` (formatted via existing format helpers); tapping a
   completed/interrupted item opens it (`openOperation`); refresh on
   returning from a successful apply/resume.
6. **Bubble contracts preserved**: layer keep-alive across dismiss (writing
   layer state + scroll survive; reopening continues), reset only via 返回
   / document switch, PopScope gate unchanged semantics, touch-web upgrade,
   height bound + internal scroll (the new layer is the tallest content —
   height regression tests must keep passing), zero LLM/operations calls on
   detail open or on merely opening the bubble (history loads only when the
   历史操作 affordance is opened, or at first entry into the writing layer —
   pick one, pin it in tests, and keep idle cheap).
7. **Tests** (stub repository extended with operations recording; widget
   level, `retry: noAutomaticRetry`):
   - Provider: generate/resume/apply lifecycle, stale-generation drop,
     apply success triggers the two invalidations, conflict keeps prior
     state + surfaces code.
   - Widget: menu entry → writing layer; idle generate flow (pending
     completer: spinner, no second call); draft render (markdown pipeline,
     front matter stripped); apply confirm dialog (cancel does nothing;
     confirm → applying → success view + detail refetch assertion);
     409 copy + 重新生成; failed op + 恢复; history list + tap-to-open;
     keep-alive across dismiss; PopScope unchanged.
   - All existing suites green (bubble/menu/layer changes must not regress
     summary/associations).

## Constraints

- Repository/DTO layer is done — extend only via providers/UI; fix defects
  there if discovered (with justification).
- Apply without the optional `expectedBaseDocumentVersion` (the server's
  base-version check already covers staleness; do not thread a second
  source of truth through the UI).
- No routing changes; AppSizes tokens; Chinese-first copy; const
  constructors; dumb widgets; `MarkdownContent` for draft body.
- Dead-end rule on every branch (409/failed/errors always offer a visible
  recovery).

## Acceptance Criteria

- [ ] Menu shows 「AI 续写」; entering the layer fires no calls until
      生成草稿/历史操作 is used.
- [ ] Generate → spinner (seconds hint) → draft review with markdown body
      (front matter stripped) + title; 重新生成 prefills instruction.
- [ ] Apply: confirm dialog → applying (disabled actions) → success view +
      `documentDetailProvider`/`documentsProvider` invalidated (detail
      refetches applied content); index-pending hint shown.
- [ ] 409 conflict → dedicated copy + 重新生成; failed/interrupted → 恢复
      works (resume → completed → review).
- [ ] History: list loads on demand, state + time rendered, tap opens the
      operation, refreshes after apply/resume.
- [ ] Layer keep-alive, PopScope, height bound, zero-calls-on-open all
      hold; `flutter analyze` clean; full `flutter test` green.
