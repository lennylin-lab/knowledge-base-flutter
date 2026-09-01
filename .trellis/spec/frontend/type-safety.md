# Type Safety (DTO & Model Conventions)

> Type-safety patterns for the Dart/Flutter client.

---

## Overview

- All backend payloads are modeled as **freezed + json_serializable** DTOs in
  `lib/shared/models/`. Raw `Map<String, dynamic>` / `dynamic` JSON may only
  appear inside that folder (and the SSE parser).
- DTOs mirror the backend schemas in
  `../knowledge-base-server/src/app/schemas/` **exactly**: field names, enum
  values, and nullability must match the wire format 1:1.
- Code generation via `build_runner`; generated files are committed.

---

## Type Organization

| Backend schema | Dart DTO | Notes |
|---|---|---|
| `DocumentCreate` | `DocumentCreate` | `content` required (min 1), `title` nullable |
| `DocumentUpdate` | `DocumentUpdate` | both fields optional; ≥1 required server-side |
| `DocumentRead` | `DocumentRead` | list item; no `content` |
| `DocumentReadDetail` | `DocumentReadDetail` | extends read + `content` |
| `DocumentPage` | `DocumentPage` | `items` + `nextCursor` (nullable = end) |
| `SearchResponse` / `SearchHit` | same names | `vectorRank` nullable, `esRank` int |
| chat SSE payloads | `RunStarted`, `SourcesEvent`, `AnswerDelta`, `ChatDone`, `ChatErrorEvent` | |
| error envelope | `ApiErrorEnvelope` / `ApiError` | `code`, `message`, `details` map |

---

## JSON Mapping Rules

- Dart fields are `camelCase`; wire format is `snake_case` — annotate classes
  with `@JsonSerializable(fieldRename: FieldRename.snake)` instead of per-field
  `@JsonKey` (use `@JsonKey` only for irregular names like `es_rank` vs
  `vector_rank`, which are regular snake_case and covered by the rename).
- Wire enums are **strings**, never ints:
  - `index_status`: `pending` | `done` | `failed`
  - `mode`: `hybrid` | `bm25`
- Enum parsing must be defensive: unknown wire value → parse failure is NOT
  acceptable (backend may add values). Fall back to a sentinel (e.g. `failed`
  for status, `bm25` for mode) or keep the raw string.

### Validation

- There is no client-side validation library: validate at the boundary with
  plain assertions/regex before calling the repository (e.g. non-empty
  `content`, `limit` clamped to API ranges 1–100 / 1–50 / 1–20).
- Trust the server for domain validation (422 `validation_failed`) — the client
  shows the returned `message`.

---

## Common Patterns

- `factory Xxx.fromJson(Map<String, dynamic>)` comes from codegen; never hand-
  write JSON parsing.
- IDs are `String` (UUID) — never parse to int.
- Timestamps stay `String` (ISO8601) on DTOs; format for display in the UI
  layer via `DateFormat` (intl), never mutate the DTO.
- Sealed classes / pattern matching (`switch`) for SSE event types and
  `AsyncValue` guards.

---

## Forbidden Patterns

- `dynamic` for payload fields; `Map<String, dynamic>` passed to widgets.
- Renaming or re-shaping wire fields "because Dart style" without a mapping
  annotation — the DTO must round-trip.
- Hardcoding enum ordinals (`IndexStatus.values[2]`) — match on the wire name.
- `jsonEncode`-ing DTOs by hand for requests — use the generated `toJson`.
