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

## Domain-Specific Patterns

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
  configuration in one shared widget so detail page and chat answers render
  identically.
- **Empty / loading / error states:** every list-like surface must handle all
  three `AsyncValue` branches; error copy shows the backend `message` plus a
  Chinese fallback.

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
