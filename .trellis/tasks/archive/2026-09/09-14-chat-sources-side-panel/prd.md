# Chat sources side panel

## Goal

Move the chat run view's sources section into a collapsible right-hand side
panel on wide layouts (resizable, persisted width) with an inline collapsible
fallback below the answer on narrow layouts.

## Design (documents-page two-pane pattern, component-guidelines spec)

- The layout decision is made on the **content area** width (the nav rail
  already took its share): `_sourcesPaneMinWidth = 840` (the shell's
  extended-breakpoint parity; sources panel is lighter than the documents
  master-detail which uses 1100).
- Wide + sources non-empty → `Row[Expanded(answer column), VerticalDivider,
  ResizablePane(sources panel)]`. The pane is on the right (draggable left
  edge → `PaneSide.left`), width persisted via `layoutWidthsProvider` pane id
  `chat.sources` (default 320, responsive min 280, absolute min 240, max 440).
- Panel visibility is page state (session-only, default open when sources
  exist) toggled by an AppBar icon button (`view_sidebar`, tooltip
  收起来源 / 展开来源) shown only while the panel can exist (wide + sources
  non-empty).
- Narrow (< 840) → sources render inline inside the run view as a collapsed
  -by-default `ExpansionTile`（参考来源）— same affordance as the tool-call
  timeline; no AppBar toggle.
- Sources still accumulate per run (existing semantics); history turns carry
  no sources — the panel reflects the current run's `state.sources` only.

## Requirements

1. `chat_page.dart` restructure: page body becomes breakpoint-driven; the
   run view loses its always-expanded inline `_SourcesSection` in favor of:
   - `_SourcesPanel` (pane content): header + citation hint + scrollable
     `_SourceTile` list, full pane height;
   - `_SourcesSection` (inline fallback): `ExpansionTile`, collapsed by
     default, tiles + hint as children.
2. Toggle semantics: wide + sources → toggle visible; hiding the panel hides
   sources entirely (no duplicate inline section); reopening restores. Panel
   state resets on navigation (session-only), not persisted.
3. Citations unchanged: answer `[n]` maps to the 1-based panel/inline list;
   tapping a tile still pushes `/documents/{id}`.
4. Tool-call timeline, rewrite disclosure, progress line, input bar, and all
   run/history semantics untouched.
5. AppSizes tokens for all spacing/icon sizes; pane dimensions are layout
   constraints (exempt from tokens, like the documents page constants).

## Acceptance Criteria

- [ ] Wide surface (≥ 840 content width) with sources: answer left, sources
      panel right with visible tiles; toggle hides/shows the panel; pane edge
      draggable (width persisted under `chat.sources`).
- [ ] Narrow surface (480×800, existing tests): sources render as a collapsed
      ExpansionTile; expanding reveals the tiles and the citation hint;
      citation tap still opens the document.
- [ ] No sources → neither panel nor toggle renders.
- [ ] `flutter analyze` clean; all tests pass (sources tests updated + new
      wide-layout test).
