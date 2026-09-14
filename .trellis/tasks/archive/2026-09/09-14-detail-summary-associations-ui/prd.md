# 文档详情页摘要与关联 UI

## Goal

Add two on-demand AI sections to the shared document detail body:
「AI 摘要」(summary) and 「相关文档」(associations), driven by the existing
repository methods `summarize(id)` / `listAssociations(id)` (landed in task
`09-14-align-document-endpoints`). No repository/DTO/route changes.

## Background

- Endpoint contract evidence:
  `.trellis/tasks/archive/2026-09/09-14-align-document-endpoints/research-server-document-api.md`.
  Both endpoints are POST, no body, synchronous LLM calls, results **not
  persisted server-side**; `503 chat_unavailable` when the server lacks
  `CHAT_API_KEY`; latency can be seconds (`latency_ms` in the response).
  → Generation must be **manual** (explicit user action), show progress, and
  surface errors gently. Never auto-call on page open.
- `DocumentDetailBody` (in `lib/features/documents/document_detail_page.dart`)
  is rendered by both the full-page `DocumentDetailPage` and the two-pane
  `DocumentDetailPane` — placing the sections there covers both surfaces.
- Router already has `document-detail` (`/documents/:id`, `lib/app.dart`), so
  association items can navigate directly.

## Requirements

1. **State** (in `documents_providers.dart`, per provider-guidelines /
   state-management spec):
   - Per-document on-demand state for each of summary and associations
     (family-based Notifier holding last result + in-flight flag + error
     message, or the closest pattern the provider spec prescribes).
   - No fetch on provider build. `generate(id)` calls the repository;
     a second tap while in flight is a no-op; a new result replaces the old;
     on failure keep any previous result visible and expose the error message.
   - Guard against stale responses (result of a superseded generation must
     not overwrite newer state).
2. **UI** (sections inside `DocumentDetailBody`, below the markdown content):
   - 「AI 摘要」: no result yet → tonal button 生成摘要； in flight → progress
     indicator + hint copy (同步生成可能需要数秒)； result → summary text
     rendered **verbatim** (never translate/trim) + a secondary caption
     「{model} · {latency}」 + a 重新生成 action.
   - 「相关文档」: no result → 生成关联 button; in flight → progress; result →
     list of items showing title, tags, and the LLM reason; empty list →
     「未找到相关文档」； tapping an item pushes `/documents/{documentId}`.
   - Errors: `503 chat_unavailable` → friendly copy (e.g. 「AI 服务暂不可用，
     请稍后重试」)； other failures → 「生成失败：{backend message}」 + 重试
     (error copy shows backend `message` plus Chinese fallback per
     component-guidelines).
3. **Conventions** (binding specs): Chinese-first copy; all sizes from
   `context.sizes` tokens (no hardcoded `EdgeInsets`/`SizedBox` numbers);
   `const` constructors; dumb widgets that watch providers, never call
   repositories from `build()`; summary/association LLM text rendered
   verbatim.
4. **Tests** (widget tests with the stub repository; every test scope passes
   `retry: noAutomaticRetry`):
   - Opening detail makes **zero** summary/association calls; pressing the
     button triggers exactly one (stub records calls).
   - Loading state visible while in flight; summary result renders verbatim
     with model/latency caption; 重新生成 refetches.
   - Association items render title/reason; tapping pushes `/documents/{id}`;
     empty result shows the copy.
   - `503 chat_unavailable` renders the friendly copy; a generic error renders
     message + retry which succeeds on second attempt.
   - Existing detail-page and pane tests keep passing (both surfaces now show
     the sections).

## Constraints

- No changes to `DocumentsRepository`, DTOs, or routing.
- Sections must stay modest in the narrower two-pane layout.
- Do not block the detail body on these sections — the markdown content must
  render immediately as before.

## Acceptance Criteria

- [ ] Both detail surfaces show 「AI 摘要」 and 「相关文档」； opening a document
      triggers no LLM calls.
- [ ] Summary: 生成摘要 → loading → verbatim summary + 「{model} · {latency}」
      caption; 重新生成 works; failures keep the UI usable with error copy.
- [ ] Associations: 生成关联 → loading → items with title/tags/reason; tap
      navigates to that document's detail; empty result shows 「未找到相关文档」.
- [ ] `503 chat_unavailable` shows the friendly copy; generic errors show
      backend message + 重试.
- [ ] `flutter analyze` clean; `flutter test` green including new tests.
