# AI 气泡内聚（菜单/内容双层导航）

## Goal

Revert the routed content pages: **all AI content displays only inside the
bottom-right floating bubble**. The bubble gains **two-layer in-widget
navigation** — menu layer (入口) ↔ content layer (「AI 摘要」 or 「相关文档」
content) — with back returning to the menu layer. The bubble grows **taller**
(增高) to host content, with a max-height bound and internal scrolling.
Clean up the now-dead routes/pages/browser-title segments.

## Background

- Current state (task 09-15-ai-assistant-routes, archived): bubble items
  `context.push` `/documents/:id/summary` and `/documents/:id/associations`
  (pages in `lib/features/documents/document_ai_pages.dart`, routes in
  `lib/app.dart`, tab-title segments in
  `lib/core/browser/browser_tab_title.dart`, `buildRouter(initialLocation:)`
  param added for deep-link tests). User decision: no separate pages —
  navigation happens inside the floating component.
- State: `OnDemandGenerationNotifier` family providers — unchanged semantics
  (`generate()` no-ops in flight, stale-guarded, failure keeps result).
- The detail page has zero AI content at the bottom and zero LLM calls on
  open — both must hold.

## Requirements

1. **Remove routed pages**: delete the `summary`/`associations` child routes
   from `lib/app.dart`, remove/repurpose
   `lib/features/documents/document_ai_pages.dart`, drop the corresponding
   browser-tab-title segments, and revert the `buildRouter(initialLocation:)`
   test-only param if nothing else uses it. Remove now-unused tokens (e.g.
   `aiContentBubbleWidth`) rather than leaving dead code.
2. **In-bubble two-layer navigation** (inside `AiAssistantFab`):
   - **Menu layer** (default): current header + two entries, unchanged copy.
   - **Content layer**: opened by clicking an entry; its header carries a
     **back affordance** (arrow + the function title) that returns to the
     menu layer. Content states are the ones built for the removed pages:
     generating (progress + hint) / result (summary verbatim + 「{model} ·
     {latency}」 caption + 重新生成； associations title/tags/reason list,
     item tap → `/documents/{documentId}` — navigating to another document's
     detail closes the bubble / empty → 「未找到相关文档」) / errors
     (`chat_unavailable` friendly copy + inline 重试； other → 「生成失败：
     {message}」 + 重试). Dead-end rule holds on every branch.
   - Entry click = explicit intent: switch to the content layer **and**
     generate once when uncached and not in flight (post-frame/immediate
     outside `build`, single call). A cached result shows as-is; keep the
     provider alive while the detail surface is open (e.g. the fab also
     watches the providers at menu layer) so re-entering the content layer
     does not re-bill.
   - Closing the bubble (outside tap, toggle, hover-open pointer exit, 收起)
     resets to the menu layer for the next open.
3. **Bubble sizing**: taller than today (增高) to host content; width stays
   the existing token (bump the token value only if genuinely needed). The
   bubble's height is bounded by the available surface height
   (`LayoutBuilder` fraction or equivalent) with **internal scrolling** for
   content overflow — it must never overflow the pane or page bounds.
4. **System back**: with the content layer open, Android system back /
   browser back must first return to the menu layer instead of leaving the
   detail page (`PopScope` or equivalent on the detail page); at menu layer
   (or bubble closed) system back behaves as before.
5. **Preserved contracts**: hover/tap summon + dismiss and the touch-web
   upgrade path; zero LLM calls on detail open; pane create-FAB placement;
   hero-tag collision safety (page + pane simultaneously).
6. **Tests** (widget level, stub repo, `retry: noAutomaticRetry`):
   - Entry click → content layer shows (no route push) + exactly one
     generate call; cached result on re-entry without refetch; 重新生成.
   - Back affordance returns to the menu layer; closing and reopening the
     bubble lands on the menu layer.
   - PopScope: system back at content layer → menu layer (page stays);
     system back elsewhere → unchanged behavior.
   - Result/error/empty states inside the bubble; association item tap →
     that document's detail page.
   - Touch-web upgrade path still pinned; pane coverage updated (no route
     navigation anymore); existing fab tests updated.
   - `flutter analyze` clean; full suite green.

## Constraints

- No changes to `DocumentsRepository`, DTOs, or the
  `OnDemandGenerationNotifier` state machine.
- No separate pages/routes for AI content — the bubble is the only surface.
- AppSizes tokens only; Chinese-first copy; const constructors; dumb widgets.

## Acceptance Criteria

- [ ] No AI routes/pages/tab-title segments remain; `app.dart` has no
      summary/associations children under `:id`.
- [ ] Bubble opens on the menu layer; entry click switches to the content
      layer inside the bubble and fires exactly one generate when uncached.
- [ ] Back affordance returns to the menu layer; system back at content
      layer returns to menu (page stays); closing resets to menu layer.
- [ ] All content states render inside the taller, internally-scrollable,
      max-height-bounded bubble on both surfaces; association item tap
      navigates to that document's detail.
- [ ] Cached results show without refetch on re-entry; zero calls on detail
      open; dead-end rule holds.
- [ ] `flutter analyze` clean; full `flutter test` suite green.
