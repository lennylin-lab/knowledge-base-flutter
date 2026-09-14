# AI 助手两层路由（气泡入口→内容页）

## Goal

Remove the summary/associations display sections from the bottom of the
document detail body entirely; their content moves into the AI assistant
system behind **two route layers**:

- **Layer 1 (entry)**: the floating AI entry on `/documents/:id` — small
  always-visible button → bubble menu (kept, somewhat larger).
- **Layer 2 (content page)**: clicking a bubble item **navigates** to
  `/documents/:id/summary` or `/documents/:id/associations`, each rendering
  its content in a **large bubble-styled card**; back returns to the entry.

No repository/DTO/provider-state-machine changes.

## Background

- Current state (tasks 09-14-detail-summary-associations-ui,
  09-15-detail-ai-fab-bubble, both archived): `_SummarySection` /
  `_AssociationsSection` render display-only inside `DocumentDetailBody`;
  `AiAssistantFab` (hover/tap bubble, touch-web upgrade path) selects an item
  → close → `Scrollable.ensureVisible` → `generate(id)`.
- State: `OnDemandGenerationNotifier` family providers
  (`documentSummaryProvider(id)` / `documentAssociationsProvider(id)`) —
  `generate(id)` no-ops in flight, stale-guarded, failure keeps previous
  result. Unchanged.
- Routes live in `lib/app.dart` (`document-detail` = `/documents/:id` with
  child `edit`); new pages slot in as siblings of `edit` under `:id`.

## Requirements

1. **Detail body cleanup**: remove `_SummarySection` / `_AssociationsSection`
   and the section GlobalKeys/scroll plumbing from `DocumentDetailBody`
   (it can return to `StatelessWidget`). The floating entry and its bubble
   menu stay on both detail surfaces; the bubble menu may grow (larger
   entries now that items navigate) via AppSizes tokens.
2. **Bubble item behavior**: select → close bubble → `context.push` the
   corresponding route (`/documents/{id}/summary` or
   `/documents/{id}/associations`). Works from the full page and the
   two-pane pane (pane navigation covers the branch content area; back
   restores `/documents` with the pane selection preserved).
3. **Content pages** (new `DocumentSummaryPage` / `DocumentAssociationsPage`,
   one file is fine): AppBar (title 「AI 摘要」/「相关文档」, back button) +
   body rendering the generation content inside a **large bubble-styled
   card** (AI-assistant branding, clearly bigger than the entry menu bubble;
   AppSizes tokens, `aiBubbleWidth` may be extended or a new token added):
   - **On entry**: if no cached result and not in flight, **auto-generate**
     (post-frame callback, never in `build`) — clicking the bubble item is
     the explicit intent, so landing on the page must not require a second
     click. With a cached result, show it as-is (no auto-refetch).
   - States: generating (progress + hint copy) / result (summary verbatim +
     「{model} · {latency}」 caption + 重新生成； associations list with
     title/tags/reason, item tap → `/documents/{documentId}` detail, empty →
     「未找到相关文档」) / error (`chat_unavailable` friendly copy； other →
     「生成失败：{message}」 + inline 重试). Dead-end rule holds everywhere.
4. **Back returns to the entry**: AppBar back pops; when there is no stack
   (direct deep link to a content page), back falls back to
   `context.go('/documents/{id}')` so the invariant "back lands on the entry
   surface" always holds.
5. **Zero-call rules preserved**: opening the detail page fires zero LLM
   calls; only entering a content page may fire one (auto-generate, once,
   in-flight-guarded by the notifier). Deep-linking straight to a content
   page counts as explicit intent and may generate.
6. **Tests** (widget level, stub repo, `retry: noAutomaticRetry`):
   - Detail: zero calls on open; bottom sections gone; bubble item navigates
     to the correct route (page + pane coverage); fab/bubble behavior tests
     updated to the navigate-on-select contract.
   - Content page: entry auto-generates exactly once (stub records); cached
     result shows without refetch; 重新生成 refetches; associations item tap
     navigates to `/documents/{id}`; empty copy; `chat_unavailable` friendly
     copy; generic error + 重试 succeeds on second attempt.
   - Back: content page back returns to the detail entry surface; direct
     deep-link entry still backs out to the detail route.
   - Existing detail/documents tests updated; full suite green.

## Constraints

- No changes to `DocumentsRepository`, DTOs, or the
  `OnDemandGenerationNotifier` state machine.
- All sizes via AppSizes tokens; Chinese-first copy; const constructors;
  dumb widgets; touch-web hover/tap contract of the fab must keep working
  (upgrade path stays).
- The pane's create-FAB placement (list pane, from the previous task) must
  not regress.

## Acceptance Criteria

- [ ] Detail body has no AI sections at the bottom; floating entry + bubble
      menu remain on both surfaces; zero LLM calls on detail open.
- [ ] Bubble item click navigates to `/documents/{id}/summary` /
      `/documents/{id}/associations` (page + pane).
- [ ] Content pages render states in a large bubble-styled card; entry
      auto-generates exactly once when uncached; cached results show without
      refetch; 重新生成 works; associations item tap → document detail; empty
      copy; error flows per spec (dead-end rule holds).
- [ ] Back from a content page returns to the entry surface, including the
      direct deep-link case.
- [ ] `flutter analyze` clean; full `flutter test` suite green.
