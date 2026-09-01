# Backend Map & Contract Source of Truth

> This repo is the Flutter client. "Backend" here means the sibling FastAPI
> service `../knowledge-base-server`. Server-side coding conventions live in
> **that repo's** `.trellis/spec/backend/` — do not duplicate them here. This
> file tells you where the API contract is defined so client code can be kept
> in sync.

---

## Backend Repository Layout (read-only reference)

```
knowledge-base-server/src/app/
├── main.py                  # FastAPI app assembly, health check
├── api/v1/endpoints/        # documents.py, search.py, chat.py  ← route truth
├── schemas/                 # document.py, search.py, chat.py   ← DTO truth
├── core/exceptions.py       # AppError hierarchy                ← error codes
├── services/                # document / search / chat orchestration
├── repositories/            # SQLAlchemy data access
├── rag/                     # chunker / indexer / retriever
├── llm/, agents/, mcp/      # LLM integration, QA agent, tools
└── search/                  # Elasticsearch queries
```

---

## Contract Sources (check in this order)

1. `src/app/schemas/*.py` — request/response field names, nullability, enums.
2. `src/app/api/v1/endpoints/*.py` — method, path, query params, status codes.
3. Live OpenAPI: `http://localhost:8000/docs` (Swagger) when the server runs.
4. This spec dir's `error-handling.md` and `database-guidelines.md` for the
   client-facing semantics already extracted here.

---

## Running the Backend (for manual verification)

```bash
cd ../knowledge-base-server
docker compose up -d
uv run alembic upgrade head
uv run uvicorn app.main:app --reload   # serves http://localhost:8000
```

Base URL defaults per platform:

| Platform | Default base URL |
|---|---|
| Web / Windows | `http://localhost:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| Android device | LAN IP (user-configurable) |

Web note: the backend does not yet send CORS headers — during development either
add `CORSMiddleware` server-side or run the app through a dev proxy.

---

## When the Backend Changes

Any change to `schemas/` or `endpoints/` in the server repo is a contract
change: update the affected DTOs in `lib/shared/models/`, the repository
methods, the tests' fixture JSON, and (if semantics changed) the corresponding
notes in this spec directory.
