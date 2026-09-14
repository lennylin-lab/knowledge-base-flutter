# 对齐服务端 document 端点（summary/associations）

## Goal

Align the Flutter client's document API layer with the server by adding the two
document sub-endpoints that exist server-side but are missing client-side:

- `POST /api/v1/documents/{document_id}/summary`
- `POST /api/v1/documents/{document_id}/associations`

Scope: **API client layer only** (DTOs + repository + contract tests). No UI,
provider, or routing changes. User confirmed this scope on 2026-09-14.

## Background

Client CRUD (`list/get/create/update/delete` in
`lib/features/documents/documents_repository.dart`) already matches the server
exactly (verified against `../knowledge-base-server/src/app/api/v1/endpoints/documents.py`).
The only gaps are the two synchronous LLM sub-endpoints, which are also absent
from this repo's API docs (`docs/chat-api.md` covers chat only). Server-side
contract evidence is captured in `research-server-document-api.md` in this
task directory.

## Requirements

1. Add DTOs matching the server schemas
   (`../knowledge-base-server/src/app/schemas/agents.py`), following existing
   freezed + json_serializable conventions:
   - `SummaryResult`: `document_id` (String), `summary` (String),
     `model` (String), `latency_ms` (double). All required, none nullable.
   - `AssociationsResult`: `document_id` (String),
     `associations: List<AssociationItem>`, `model` (String),
     `latency_ms` (double). All required, none nullable.
   - `AssociationItem`: `document_id` (String), `title` (String),
     `tags` (List&lt;String&gt;), `reason` (String), `signal` (String).
     All required, none nullable.
2. Extend `DocumentsRepository` with two methods:
   - `POST {_basePath}/{id}/summary` → parses `SummaryResult`
   - POST {_basePath}/{id}/associations` → parses `AssociationsResult`
   Both send **no request body and no query parameters** (the server takes
   none today). Error handling identical to existing methods
   (`toApiException`). Expected success status is 200.
3. Contract tests in `test/features/documents/documents_repository_test.dart`
   pinning method, full path, absent body, response parsing, and error mapping
   (at minimum 503 `chat_unavailable`, the documented failure mode when the
   server lacks `CHAT_API_KEY`).

## Constraints

- No changes to UI, providers, routing, or existing CRUD methods/DTOs.
- Do not invent a request body for either endpoint.
- DTO JSON keys are snake_case, matching the wire format exactly.
- Where the new DTOs live must follow `.trellis/spec/frontend/type-safety.md`
  and the existing `lib/shared/models/` layout.

## Acceptance Criteria

- [ ] `DocumentsRepository` exposes both sub-endpoint calls with correct
      method, path (`/api/v1/documents/{id}/summary|associations`), and no body.
- [ ] New DTOs decode a real-shaped server payload and round-trip
      (fromJson ∘ toJson) with snake_case keys; `latency_ms` maps to `double`.
- [ ] 503 response with envelope `{error:{code:"chat_unavailable",...}}`
      surfaces as `ApiException(code: 'chat_unavailable')` from both methods.
- [ ] `flutter analyze` clean and `flutter test` green, including the new
      contract tests.
