# Error Contract (Client Handling)

> The unified backend error format and how this client must handle it.
> Server-side internals: `../knowledge-base-server/src/app/core/exceptions.py`
> and that repo's spec.

---

## REST Error Envelope

Every non-2xx REST response body:

```json
{
  "error": {
    "code": "not_found",
    "message": "Human-readable message",
    "details": {}
  }
}
```

Decode in **one place** (dio interceptor / repository base) into
`ApiException(code, message, details)`. Features and widgets only ever see
`ApiException`.

Known codes (verified against backend `core/exceptions.py`):

| HTTP | `code` | Client behavior |
|---|---|---|
| 404 | `not_found` | document gone → leave screen, toast "文档不存在" |
| 409 | `conflict` | edit rejected → show message, offer reload |
| 422 | `validation_failed` | show message next to offending field if possible |
| 429 | `rate_limited` | toast + disable submit briefly, invite retry |
| 502 | `llm_provider_error` / `mcp_tool_failed` / `search_index_error` | "服务暂不可用，请稍后重试" |
| 503 | `chat_unavailable` | chat input disabled with hint |
| 500 | `internal_error` | generic toast |

Fallback: if the body is **not** an envelope (proxy/HTML error page, network
down), synthesize `ApiException('network_error', ...)` — never crash on parse.

---

## SSE Error Event (`POST /api/v1/chat`)

- The stream may open with **HTTP 200 and still fail**: the terminal `error`
  event carries `{ "code": "...", "message": "..." }` and the stream closes
  right after.
- Client: treat `error` as terminal — stop the spinner, keep already-rendered
  deltas/sources if any, show the error inline in the chat area.
- Transport-level failures (connection drop before `done`) surface as
  `network_error`.

Event order guarantee: `run_started → sources* → answer_delta* → done`, or
terminal `error` at any point.

---

## UI Presentation Rules

- User-facing error text is Chinese-first; show the backend `message`
  verbatim appended to a Chinese prefix ("加载失败：…"), since messages may be
  English.
- Never show raw JSON or `DioException.toString()` to the user.
- Log `code` + context (see logging-guidelines.md), not document content.
