# 详情页 AI 悬浮入口（收起/气泡双态）

## Goal

Replace the inline trigger entries of the two AI sections at the bottom of the
document detail body with a **floating unified entry** anchored bottom-right of
each detail surface (full page + two-pane pane), styled after common "AI
assistant" floating widgets:

- **Collapsed (default)**: a small, always-visible round button — the entry
  must never fully disappear while a document is shown (不能全收起).
- **Expanded**: a large bubble card (双态 UI) summoned by **mouse hover or
  click**, listing the two functions: 「AI 摘要」 and 「相关文档」.
- Selecting an item closes the bubble, **scrolls the detail body to the
  corresponding bottom section**, and **triggers generation**.

Pure UI restructure: the two bottom sections stay where they are as
display-only surfaces; no repository/DTO/provider-state/route changes.

## Background

- Current state (task 09-14-detail-summary-associations-ui, archived):
  `_SummarySection` / `_AssociationsSection` render inside
  `DocumentDetailBody` with inline trigger buttons (生成摘要 / 生成关联),
  full page + pane both show them.
- State lives in `OnDemandGenerationNotifier` family providers
  (`generate(id)` no-ops in flight, stale-guarded, failure keeps result) —
  unchanged by this task; the bubble only becomes a different way to call it.
- Hover is a mouse-affordance (desktop/web); touch devices rely on tap — both
  paths must work.

## Requirements

1. **Floating entry** (per detail surface, bottom-right of that surface):
   - Collapsed: small circular FAB-like button (sparkle-style icon, tooltip),
     always visible while detail data is shown; hidden during detail
     loading/error panes. Must not block body scrolling or trap clicks when
     collapsed.
   - Expanded: large bubble card — header (e.g. 「AI 助手」) + two entries
     「AI 摘要」「相关文档」 (icon + label + one-line description each) +
     dismiss affordance.
   - Summon/dismiss: `MouseRegion` hover opens (desktop/web); tap toggles
     open/close (touch); tap-outside closes; selecting an item closes;
     hover-open closes when the pointer exits the widget area. Pick the
     simplest behavior set that satisfies these and pin it in tests.
2. **Bubble item behavior**: on select → close bubble →
   `Scrollable.ensureVisible` to that section (GlobalKey on the section) →
   `generate(id)` for the corresponding feature. Works identically as first
   trigger and as re-generate.
3. **Inline sections become display-only** (position below markdown unchanged):
   - Remove the inline 生成摘要/生成关联 trigger buttons — the bubble is the
     unified entry.
   - Idle state: section title + a subtle hint row (e.g. 「使用右下角悬浮入口
     生成」).
   - Generating / result (verbatim text + 「{model} · {latency}」 caption +
     重新生成) / error states unchanged — including the in-place 重试 for
     generic errors and the chat_unavailable friendly copy. The always-visible
     floating entry is the standing retry affordance for the friendly-copy
     case (dead-end rule, component-guidelines).
4. **Both surfaces**: full page and two-pane pane each get the floating entry
   within their own bounds; the pane version must stay inside the pane (not
   overlap the list pane or app chrome).
5. **Conventions** (binding specs): AppSizes tokens only; Chinese-first copy;
   const constructors; dumb widgets watching providers; no repository calls
   outside provider callbacks.
6. **Tests** (widget level, stub repo, `retry: noAutomaticRetry` everywhere):
   - Collapsed by default: floating button visible, bubble hidden, zero LLM
     calls on open.
   - Click opens the bubble; selecting an item closes it, fires exactly one
     generate call, and the section shows the generating state.
   - Hover opens the bubble; pointer exit dismisses it.
   - Item selection scrolls the section into view (assert section visibility
     in the viewport after selection).
   - Inline trigger buttons are gone; idle hint row renders; result and error
     flows (retry via floating entry / inline 重试) still work.
   - Existing AI-section and detail tests updated; page and pane both covered.

## Constraints

- No changes to `DocumentsRepository`, DTOs, routes, or the
  `OnDemandGenerationNotifier` state machine (generate() semantics unchanged).
- Error states must never strand the user (dead-end rule): a recovery path is
  always visible.
- The bubble must not obscure the markdown content when collapsed (it is just
  the small button).

## Acceptance Criteria

- [ ] Collapsed floating entry always visible bottom-right on both detail
      surfaces while data is shown; bubble hidden by default; zero calls on
      open.
- [ ] Hover opens the bubble (mouse); click toggles; outside-tap and item
      selection dismiss it.
- [ ] Selecting 「AI 摘要」/「相关文档」 closes the bubble, scrolls the
      section into view, and starts exactly one generation.
- [ ] Inline trigger buttons removed; idle hint, generating, result, and
      error states render in the sections; dead-end rule holds.
- [ ] `flutter analyze` clean; full `flutter test` suite green.
