# 对接文档 description 字段

## Goal

Adopt the backend's front-matter-derived `description` column (server
migration 0012, `knowledge-base-server#8` contract): `DocumentRead`,
`DocumentReadDetail`, and `DocumentInResult` gain a non-nullable
`description` string (missing key on old backends → `""`, never a decode
crash); the detail header shows the blurb below the tags, and list cards
optionally show it as a subtitle.

## Background

- The backend derives a one-line `description` from the document front
  matter, following the same policy as `title` / `tags` (front matter is the
  source of truth; there is no dedicated write field).
- Wire schemas `DocumentRead`, `DocumentReadDetail`, and `DocumentInResult`
  expose it as a non-empty string; responses from a pre-0012 backend simply
  omit the key.

## Requirements

1. **DTOs** (`lib/shared/models/document.dart`,
   `lib/shared/models/operation.dart`): `DocumentRead`, `DocumentReadDetail`,
   and `DocumentInResult` carry `required String description`; the JSON key is
   optional on the wire and falls back to `""` when absent (a null value
   normalizes the same way through the generated `as String? ?? ''`).
2. **Projection**: `DocumentReadDetail.toDocumentRead()` carries
   `description` through unchanged (detail → list reuse).
3. **Detail header** (`document_detail_page.dart`): when non-empty, render
   `description` between the tags row and the body divider; when empty it
   takes no height.
4. **List card** (`documents_page.dart`): when non-empty, render
   `description` as a subtitle capped at two lines with ellipsis; when empty
   it renders nothing.
5. **Editing stays front-matter-driven** (same policy as title/tags): no
   dedicated description input; the create-mode template seeds
   `description: 文档描述` after `title` / `tags`.
6. **Tests**: DTO round-trip covers present / missing / null `description`;
   detail-page and list-page widget tests cover the non-empty and empty
   display states.

## Acceptance Criteria

- [x] All three DTOs decode a present `description` verbatim and decode an
  absent (or null) key to `""` without throwing.
- [x] `DocumentReadDetail.toDocumentRead()` preserves `description`.
- [x] Detail page renders the blurb between tags and the body divider when
  non-empty; empty renders nothing.
- [x] List cards render a two-line ellipsized subtitle when non-empty; empty
  renders nothing.
- [x] Create-mode front-matter template contains `description: 文档描述`.
- [x] `flutter test` green (578 tests, 2026-11-25); `flutter analyze` reports
  no errors or warnings — only 53 pre-existing info-level
  `deprecated_member_use` diagnostics introduced by the newer installed
  Flutter SDK deprecating `package:flutter/material.dart` repo-wide, unrelated
  to this task's files.

## Notes

- Implementation landed in `36e11a1` (DTOs + detail/list rendering + tests)
  and `3d1aa45` (create-mode template placeholder). This task's remaining
  work was bookkeeping: complete the PRD, run the quality gate, record the
  DTO mapping in the type-safety spec, and archive the task.
- `description` intentionally has no client-side input: editing the front
  matter is the only write path, matching `title` / `tags`.
