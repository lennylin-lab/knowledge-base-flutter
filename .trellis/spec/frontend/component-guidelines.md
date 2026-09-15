# Component (Widget) Guidelines

> How UI components are built in this project. (Flutter equivalent of component rules.)

---

## Overview

- UI is **Flutter widgets**, Chinese-first copy (界面文案默认中文). LLM answers
  render in whatever language the backend returns — never translate answer text.
- Widgets are **dumb**: they receive data via constructor params or `ref.watch`,
  and never call `dio` / repositories directly.
- Prefer `StatelessWidget`; use `ConsumerWidget` (Riverpod) when watching
  providers. `StatefulWidget` only for local animation/disposal needs.
- Always mark constructors `const` when possible (enables `flutter analyze`
  const lint and rebuild optimization).

---

## Widget Structure

Standard page/widget file layout:

```dart
class DocumentListPage extends ConsumerWidget {
  const DocumentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsProvider);
    return Scaffold(...); // body switches on AsyncValue guard/loading/error/data
  }
}

// Private helpers stay in the same file, below the public widget.
class _DocumentTile extends StatelessWidget { ... }
```

---

## Props Conventions

- Required data → required named constructor params; optional UI tweaks →
  nullable params with sensible defaults.
- Callbacks named `onXxx` (`onRetry`, `onTapDocument`); do not pass whole
  repositories or controllers into leaf widgets.
- Pass DTOs (`DocumentRead`) rather than raw `Map<String, dynamic>`.

---

## Adaptive Layout (required by MVP)

One codebase, two shells, decided by width via `LayoutBuilder` /
`MediaQuery` breakpoints (Material 3: compact < 600, medium 600–840, expanded ≥ 840):

- **Desktop (Windows / Web wide ≥ 840):** permanent `NavigationRail` or sidebar
  with destinations 文档 / 搜索 / 问答.
- **Mobile (Android, compact):** `NavigationBar` (bottom) with the same
  destinations.
- Content area stays identical across shells.

---

## Responsive Sizing (required)

One window-level scale factor ([`AppSizes.scaleForWidth`](../../../lib/core/theme/app_sizes.dart)):
1.0 below 600px, linear 1.0 → 1.4 across 600–1600, clamped (quantized to
0.01). Text and default icons scale through the theme; every other size —
spacing, explicit icon sizes, component metrics — must come from the
`AppSizes` tokens via `context.sizes`.

- **New UI must not introduce hardcoded sizes** (`size: N`, `EdgeInsets`,
  `SizedBox` magic numbers). Use `context.sizes.*`; a missing value means
  adding a token, not inlining a number.
- Exceptions (layout constraints, not visual sizes): reading-width caps
  (e.g. `_contentMaxWidth`), scroll thresholds, 48dp touch-target floors.

```dart
// Good
final sizes = context.sizes;
Padding(padding: EdgeInsets.all(sizes.space24), child: …)
Icon(Icons.cloud_off_outlined, size: sizes.iconHero)

// Bad — frozen at every window size
Padding(padding: const EdgeInsets.all(24), child: …)
Icon(Icons.cloud_off_outlined, size: 48)
```

> **Warning (Flutter 3.41 M3 typography)**: `ThemeData.textTheme` carries
> **no font sizes** — geometry merges at `Theme.of()` resolution time via
> `ThemeData.localize(typography.geometryThemeFor(category))`. Therefore
> `textTheme.apply(fontSizeFactor: …)` asserts (null fontSize) and scales
> nothing. The only working hook to scale all text is pre-scaled typography
> geometry: `Typography.material2021(englishLike/dense/tall: …2021.apply(fontSizeFactor: s))`
> (see `AppTheme._build`).

> **Warning (nav shells)**: `NavigationRail` / `NavigationBar` resolve icon
> size from their own theme data, not the global `iconTheme`. Shell icons
> must pass an explicit `Icon(…, size: sizes.iconLg)`.

**Related**: task `09-06-responsive-fluid-sizing` (design.md has the full
trade-off record).

---

## Domain-Specific Patterns

- **Horizontal scrollables (chip bars):** Flutter's default `dragDevices`
  exclude the mouse, and `MaterialScrollBehavior` auto-attaches scrollbars to
  **vertical** axes only — a raw horizontal `ListView` is effectively
  touch-only (the desktop/web defect in the tag filter bars). Use the shared
  [`HorizontalChipBar`](../../../lib/shared/widgets/horizontal_chip_bar.dart)
  (mouse drag + wheel + persistent desktop thumb, transient on touch) for any
  horizontal chip row instead of a bare `ListView`.
- **`index_status` chip** (`pending` / `done` / `failed`):
  - `pending` → small progress indicator ("索引中")
  - `done` → neutral chip or nothing
  - `failed` → error chip with a retry affordance (re-save the document)
- **Citations in Chat answers:** the answer may contain `[1]`, `[2]` markers;
  number *N* maps to the Nth item of the accumulated `sources` list in arrival
  order. Render sources below the answer and make both the marker and list item
  navigate to `DocumentDetailPage`.
- **Markdown rendering:** use `flutter_markdown_plus`
  (**NOT `flutter_markdown` — that package is discontinued**). Keep the renderer
  configuration in one shared widget so detail page, chat answers, and the AI
  summary bubble render identically (LLM prose always goes through
  `MarkdownContent`, never a bare `Text`). The shared widget overrides the package's default block spacing
  (`pPadding` vertical 2 + `blockSpacing` 14) because the defaults
  (zero + 8) sit within ~2px of the body line gap and paragraphs visually
  merge; the two values stack (gap = prev padding + blockSpacing + next
  padding), so don't reset them to defaults.
- **Fenced code highlighting & Obsidian callouts** (both configured inside the
  shared `MarkdownContent`, in `lib/shared/widgets/markdown/`):
  - Code blocks go through a **`pre` builder** (`HighlightedCodeBlockBuilder`
    + `re_highlight`, GitHub Light/Dark token palettes selected by
    `Theme.brightness`, monochrome fallback for missing/unknown languages).
    Intercept `pre`, **not** `code`: inline code spans are also `code`
    elements, so a `code` builder (with `isBlockElement()`) lifts them out of
    paragraph flow.
  - Callouts (`> [!type]`, `> [!type]-` collapsed, `> [!type]+` expanded) are
    a custom `CalloutBlockSyntax` registered in `blockSyntaxes` (custom
    syntaxes run before the built-in blockquote syntax, so plain quotes are
    unaffected) + a `callout` builder. All Obsidian canonical types +
    aliases, Chinese default titles; the quoted body travels as raw markdown
    and is rendered by a nested `MarkdownContent` (the element-builder API
    cannot reach a block element's already-built children).
  - Widget layout hazard: block-builder results are placed inside a `Wrap`
    that passes **unbounded height**, so `Row(crossAxisAlignment: stretch)`
    inside a builder widget throws; size via `Stack`/`Positioned.fill` or
    intrinsic sizing instead.
  - `markdown` is declared as a direct dependency (BlockSyntax API surface).
- **Empty / loading / error states:** every list-like surface must handle all
  three `AsyncValue` branches; error copy shows the backend `message` plus a
  Chinese fallback. Error states must never strand the user: keep the primary
  trigger visible alongside the error so recovery is one tap (e.g. after a
  `chat_unavailable` failure the 生成 button stays available for an in-place
  retry — hiding it turns the friendly copy into a dead end).

---

## Accessibility

- Use semantic widgets (`Semantics`, tooltips on icon-only buttons).
- Touch targets ≥ 48dp; respect `MediaQuery.textScalerOf` (no fixed text
  heights).
- Contrast: stick to Material 3 color scheme roles, no hardcoded low-contrast
  colors.

---

## Common Mistakes

- Calling `dio` or a repository from inside `build()` — fetch through providers.
- Hardcoding `localhost:8000` inside a widget — always resolve via
  `AppConfig` (see directory-structure.md).
- Building a mobile-only layout first and bolting desktop on later — design the
  two shells from day one.
- Translating or trimming LLM answer text before rendering — show it verbatim.
- Dual-path (hover + tap) widgets on touch-web: browsers fire compatibility
  mouse events around a tap and `mouseenter` precedes `click`, so a
  hover-open → click-toggle pair cancels out and the **first tap appears
  dead**. When a tap lands on a hover-opened state, upgrade it to tap-owned
  (sticky) instead of toggling closed — see `AiAssistantFab._toggle`
  (`document_detail_page.dart`). Keep hover-dismiss scoped to hover-opened
  state only.
- A `Positioned` child of a `Stack` receives **unbounded** constraints from
  `RenderStack`, so `LayoutBuilder` / fraction-of-parent sizing inside it is
  a silent no-op (`∞ × fraction = ∞`) — a floating panel can grow far outside
  the surface without any exception thrown. Host such panels with
  `Positioned.fill` + `Align` (+ `Padding`) so real constraints flow in, and
  pin the bound with a layout regression test — see the AI bubble host in
  `DocumentDetailBody` (`document_detail_page.dart`).
