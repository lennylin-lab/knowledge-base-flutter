# Research: Server document API contract (source of truth)

Evidence gathered on 2026-09-14 from `../knowledge-base-server`
(FastAPI + Pydantic v2). All routes mounted under hardcoded prefix
`/api/v1` (`src/app/main.py:60`). This is the authoritative reference for
aligning the Flutter client; the client repo has no document API docs of its
own (`docs/chat-api.md` covers chat only).

## Endpoints relevant to this task

File: `src/app/api/v1/endpoints/documents.py`

```python
@router.post("/{document_id}/summary", response_model=SummaryResult)   # line 63
async def summarize_document(document_id: UUID, service: SummarizeServiceDep) -> SummaryResult:
    """Compute an LLM summary of the document (synchronous, not persisted)."""

@router.post("/{document_id}/associations", response_model=AssociationsResult)  # line 69
async def associate_document(document_id: UUID, service: AssociationServiceDep) -> AssociationsResult:
    """Compute LLM-curated related documents (synchronous, not persisted)."""
```

Key contract facts:

- **Method**: POST both. **Full paths**: `/api/v1/documents/{document_id}/summary`
  and `/api/v1/documents/{document_id}/associations`.
- **No request body, no query parameters** — the handler signature takes only
  the path UUID and the service dependency.
- `document_id` must be a valid UUID; FastAPI rejects bad UUIDs with
  422 `validation_failed` before the handler runs.
- Success status is the FastAPI default **200**.
- Synchronous LLM call, result **not persisted**. When the server has no
  `CHAT_API_KEY` configured, both fail with **503 `chat_unavailable`**
  (error-code→status mapping in `src/app/core/exceptions.py:20-81`).
- Existing CRUD (list/get/create/update/delete) already matches the client and
  needs no change; noted here only as verified context.

## Response DTOs

File: `src/app/schemas/agents.py` — every field **required, none nullable**.

```python
class SummaryResult(BaseModel):
    document_id: UUID   # serialized as canonical hyphenated lowercase string
    summary: str
    model: str
    latency_ms: float

class AssociationItem(BaseModel):
    document_id: UUID
    title: str
    tags: list[str]
    reason: str         # LLM-written explanation
    signal: str         # free string, not an enum server-side

class AssociationsResult(BaseModel):
    document_id: UUID
    associations: list[AssociationItem]  # may be empty list
    model: str
    latency_ms: float
```

Example JSON the client must decode:

```json
{
  "document_id": "0198c7a1-7b2a-7c1e-9f3a-2f4b5c6d7e8f",
  "summary": "……",
  "model": "glm-4.7",
  "latency_ms": 1234.5
}
```

```json
{
  "document_id": "0198c7a1-7b2a-7c1e-9f3a-2f4b5c6d7e8f",
  "associations": [
    {
      "document_id": "0198c7a1-7b2a-7c1e-9f3a-111111111111",
      "title": "Related doc",
      "tags": ["flutter", "dart"],
      "reason": "Shares the Riverpod migration notes.",
      "signal": "tag_overlap"
    }
  ],
  "model": "glm-4.7",
  "latency_ms": 2345.0
}
```

## Error envelope (unchanged, already handled by client)

Every error, including validation failures, uses:

```json
{ "error": { "code": "<machine code>", "message": "<human message>", "details": {} } }
```

Codes most relevant here: 422 `validation_failed` (bad UUID), 404 `not_found`
(document missing, message `"Document {uuid} not found"`), 503
`chat_unavailable` (no `CHAT_API_KEY`), 502 `llm_provider_error`,
500 `internal_error`. Every response carries an `X-Request-ID` header.

## Client-side current state (verified)

- `lib/features/documents/documents_repository.dart` — `_basePath =
  '/api/v1/documents'`; five CRUD methods, each `try/catch → toApiException`.
  The two sub-endpoints are absent.
- `lib/shared/models/document.dart` — existing document DTOs (freezed,
  snake_case keys, `IndexStatus` enum with `unknownEnumValue: failed`).
- `test/features/documents/documents_repository_test.dart` — queue-based
  `HttpClientAdapter` contract tests pin method/path/body/parse/error mapping;
  new tests should follow this exact pattern.
- dio `validateStatus` is 200–299, so 201/204 handling already works; nothing
  to change for these 200-response endpoints.
