# 气泡收起保留层状态

## Goal

Collapsing the AI assistant bubble no longer resets it to the menu layer:
the current layer (menu / summary / associations) **and** the content scroll
position are cached across dismiss, so the next summon continues presenting
exactly where the user was ("继续呈现") — with the cached result, no
refetch. Reset to the menu layer happens only via the 返回 affordance or a
document switch. PopScope behavior is unchanged.

## Background

- Current state: every dismiss path (`_close`: outside tap, toggle,
  hover-open pointer exit, 收起) resets the layer to menu
  (`document_detail_page.dart` `AiAssistantFab`); the bubble card is
  unmounted on close, so scroll offsets are lost too.
- The result itself already persists in the per-document
  `OnDemandGenerationNotifier` while the surface is open (menu-layer watch
  keep-alive) — this task is purely about the **presentation layer state**.

## Requirements

1. **Layer + scroll keep-alive across dismiss**: keep the bubble card
   mounted while closed (e.g. wrap it in `Offstage` toggled by the open
   state — keeps Element/State and scroll offsets alive, stays out of
   layout and hit-testing) instead of conditionally building it. All
   dismiss paths preserve the current layer and scroll position; reopening
   (click, hover, tap) shows the same layer directly.
2. **Reset-to-menu triggers shrink to**: the 返回 affordance in the content
   layer, and a document switch (`documentId` change → layer = menu; also
   close the bubble if it was open). The menu layer itself is, of course,
   shown after returning to it.
3. **Unchanged**: generation semantics (entry click on the menu still
   generates once when uncached; re-entering a content layer with a cached
   result never refetches; in-flight generation re-open shows live
   progress), `PopScope` (system back at content layer → menu layer, page
   stays; menu/closed → unchanged), touch-web hover/tap upgrade, pane
   behavior, hero-tag safety, zero calls on detail open.
4. **Tests** (widget level, stub repo, `retry: noAutomaticRetry`): update
   the "close+reopen lands on menu" pins to the new contract; add —
   - content layer → dismiss (each path: toggle, outside tap, hover-exit)
     → reopen shows the same content layer with the cached result and zero
     new calls;
   - scroll position restored (scroll the summary, dismiss, reopen, offset
     preserved);
   - in-flight generation: dismiss + reopen shows live progress (no second
     call);
   - 返回 → menu; document switch → layer reset to menu;
   - PopScope system-back test still passes (content → menu; then reopen
     shows menu layer).
5. `flutter analyze` clean; full `flutter test` green.

## Constraints

- No repository/provider/state-machine changes; no route changes.
- The offstage-mounted card must not intercept hits or affect layout while
  closed (bubble must stay visually gone).
- AppSizes/Chinese-copy/const conventions as usual.

## Acceptance Criteria

- [ ] Dismiss (any path) then reopen returns to the same layer with cached
      content and scroll position; zero new generate calls.
- [ ] 返回 resets to menu; document switch resets to menu (and closes).
- [ ] Generation-in-flight reopen shows live progress without a second
      call; PopScope flows unchanged.
- [ ] `flutter analyze` clean; full `flutter test` green.
