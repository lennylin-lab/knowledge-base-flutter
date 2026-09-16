# operations API 层对齐

## Goal

Align the client API layer with the server's `/api/v1/operations` surface
(six synchronous JSON endpoints — verified NOT SSE). This task delivers the
**API client layer only**: DTOs, repository methods, contract tests. The UI
(assistant-bubble third entry 「AI 续写」 hosting the draft → review →
apply/resume flow) is a planned follow-up task, out of scope here
(user-confirmed split pattern: API layer first, UI separately).

## Background / Evidence

- Full server contract, lifecycle semantics, and error matrix verified
  against server HEAD: `research-operations-contract.md` in this directory.
- Draft is a **synchronous JSON** endpoint (`query` params, no body) — not
  part of the agent SSE family.
- Existing client conventions to follow: dio + `toApiException`
  (`documents_repository.dart`), freezed DTOs with global snake_case rename
  (`build.yaml`), timestamps stay `String` on DTOs, POSTs without payload
  send no body (agent-stream precedent), `stub_repository` call-recording
  test pattern.

## Requirements

1. **DTOs** (`lib/shared/models/operation.dart` + codegen, freezed):
   - `OperationState` enum: `running` | `completed` | `interrupted` |
     `failed` | `applied`, wire values lowercase; defensive parse per
     type-safety spec — unknown value → `failed` (documented choice: failed
     is the recoverable presentation closest to "not done"; never throw).
   - `DraftContent{content, title?}` (content required; server validates
     1..50_000 — client mirrors as a plain assertion at the call site, no
     validation library).
   - `OperationCreate{documentId, baseDocumentVersion, draft,
     idempotencyKey?}` — `baseDocumentVersion` is the document's
     `updated_at` **passed through verbatim** (String; no reformatting —
     the server compares it for optimistic concurrency).
   - `OperationReadDetail{id, documentId?, baseDocumentVersion?,
     state, idempotencyKey?, createdAt, updatedAt, draft?, result?,
     error?}` — `createdAt`/`updatedAt`/`baseDocumentVersion` stay String
     (ISO-8601, verbatim); `result`/`error` stay `Map<String, dynamic>?`
     (server sends free-form `{"revision_id"}` / `{"error_class"}` — keep
     raw per type-safety spec; `result.revision_id` may be surfaced via a
     small typed helper getter if convenient).
   - `OperationTransition{draft?}` — serialize `draft` only when set
     (no-body when absent).
   - `ApplyRequest{expectedBaseDocumentVersion?}` — same rule.
   - `RevisionRead{id, documentId, operationId?, title, tags, createdAt}`.
   - `ApplyResult{operation, revision, document}` with
     `DocumentInResult{id, title, tags, indexStatus, updatedAt}` reusing the
     existing `IndexStatus` enum (unknown → failed, same as document.dart).
2. **Repository** (`operations_repository.dart` in the documents feature or
   its own `operations` feature folder per directory-structure spec —
   operations are their own domain, a separate feature folder with
   `operations_providers.dart` (repository provider) is likely right):
   - `Future<OperationReadDetail> createOperation(OperationCreate payload)`
     → POST `/api/v1/operations`, expect 201.
   - `Future<OperationReadDetail> draft({required String documentId, String?
     instruction})` → POST `/api/v1/operations/draft` with **query params**
     `document_id` (required) and `instruction` (omit when null/empty), **no
     body**.
   - `Future<OperationReadDetail> operation(String operationId)` → GET.
   - `Future<List<OperationReadDetail>> operationsForDocument(String
     documentId)` → GET `/api/v1/operations/documents/{id}`.
   - `Future<OperationReadDetail> resume(String operationId, {DraftContent?
     draft})` → POST `.../resume`, no body when `draft == null`, else
     `{"draft": {...}}`.
   - `Future<ApplyResult> apply(String operationId, {String?
     expectedBaseDocumentVersion})` → POST `.../apply`, no body when null,
     else `{"expected_base_document_version": "..."}`.
   - Error handling identical to existing methods (`toApiException`), so
     409 `conflict` (with `details.state` / `details.base_version` /
     `details.current_version`), 404, 503, 502 all surface with codes
     intact.
3. **Contract tests** (`test/…/operations_repository_test.dart`, queue-based
   adapter pattern): method/path/query/body/status pinning for all six
   endpoints — 201 on create; idempotent-create replay is server-side (not
   client-testable beyond pinning the idempotency_key in the body); draft
   query encoding incl. CJK instruction + omitted when null; no-body POSTs
   for resume/apply and body shape when payloads present; list returns
   `List<OperationReadDetail>`; error mapping 409/404/503 → `ApiException`
   codes. DTO round-trips in `dto_roundtrip_test.dart`: every state value,
   unknown state → failed, unknown index_status → failed, nullability of
   draft/result/error, verbatim timestamp strings.

## Constraints

- No UI, provider state machines, or routing changes in this task.
- No SSE involvement — do not route operations through
  `AgentStreamClient`.
- Timestamps: `String` in, `String` out, verbatim (optimistic-concurrency
  sensitivity).
- Follow the directory-structure spec for placement; wire the repository
  provider on `apiClientProvider` like `documentsRepositoryProvider`.

## Acceptance Criteria

- [ ] All six endpoints callable via the repository with pinned method,
      path, query, body (or no-body), and expected status semantics.
- [ ] DTO set covers the full lifecycle (create → draft → resume → apply →
      ApplyResult) with defensive enum parsing; timestamps verbatim.
- [ ] 409/404/503 surface as `ApiException` with codes/details intact
      (details accessible for future UI copy).
- [ ] `flutter analyze` clean; `flutter test` green including new contract
      and round-trip tests; existing suites untouched.
