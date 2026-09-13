# Chat API — Frontend Integration Guide

Base URL: `/api/v1`  
Protocol: REST + SSE (Server-Sent Events)  
Request content type: `application/json`  
Streaming response content type: `text/event-stream`

This document describes the knowledge-base-server chat and session endpoints for client integration (Flutter/web).

---

## 1. Overview

| Capability | Method | Path | Notes |
|------------|--------|------|-------|
| Ask a question (streaming answer) | `POST` | `/chat` | SSE stream — primary endpoint |
| List sessions | `GET` | `/chat/sessions` | Keyset pagination |
| Session detail | `GET` | `/chat/sessions/{session_id}` | Includes message history |
| Delete session | `DELETE` | `/chat/sessions/{session_id}` | Soft delete, returns 204 |

**Multi-turn flow**

1. First turn: `POST /chat` without `session_id` → read `session_id` from `run_started`.
2. Follow-up turns: send the same `session_id` in the request body.
3. History UI: `GET /chat/sessions/{id}` returns persisted messages. **Sources are not included** in session detail — accumulate them from SSE during each run.

---

## 2. Common conventions

### 2.1 Non-streaming errors (JSON envelope)

When the response is not an open SSE stream, errors use:

```json
{
  "error": {
    "code": "not_found",
    "message": "Chat session xxx not found",
    "details": {}
  }
}
```

| HTTP | `code` | When |
|------|--------|------|
| 404 | `not_found` | Session missing or soft-deleted |
| 422 | `validation_failed` | Invalid request body |
| 503 | `chat_unavailable` | Server has no `CHAT_API_KEY` configured |
| 429 | `rate_limited` | LLM rate limit (non-SSE paths) |
| 502 | `llm_provider_error` | LLM provider failure (non-SSE paths) |

Responses include an `x-request-id` header for support/debugging.

### 2.2 SSE wire format

Each event:

```
event: <event_name>
data: <JSON string>

```

Parse by splitting on blank lines (`\n\n`), reading `event:` and `data:` lines, then `JSON.parse(data)`.

**Important:** once SSE returns HTTP 200, failures are **not** expressed as a status-code change. The stream ends with a terminal `error` event.

---

## 3. Ask — `POST /api/v1/chat`

### 3.1 Request

```http
POST /api/v1/chat
Content-Type: application/json
Accept: text/event-stream
```

```typescript
interface ChatRequest {
  /** User question, min length 1 */
  question: string;
  /** Max chunks per retrieval call; default 8, range 1–20 */
  limit?: number;
  /** Continue an existing session; omit to start a new one */
  session_id?: string; // UUID
}
```

New session:

```json
{
  "question": "Redis 的分布式锁怎么实现？",
  "limit": 8
}
```

Follow-up:

```json
{
  "question": "那它的缺点呢？",
  "session_id": "01991a2b-3c4d-7e8f-9012-3456789abcde",
  "limit": 8
}
```

### 3.2 Success

- **Status:** `200`
- **Content-Type:** `text/event-stream`
- Use `fetch` + `ReadableStream` (POST cannot use native `EventSource`).

### 3.3 Failures before the stream starts

| Scenario | HTTP |
|----------|------|
| Unknown/deleted `session_id` | 404 JSON |
| Empty `question`, invalid `limit`, etc. | 422 JSON |
| Chat not configured on server | 503 JSON |

These fail **before** the first SSE event is sent.

---

## 4. SSE event types

Nine event names (including terminal events).

### 4.1 `run_started` — first event of every run

```typescript
interface RunStartedEvent {
  run_id: string;            // hex UUID for this run
  mode: "hybrid" | "bm25";   // retrieval mode actually wired
  session_id: string | null; // persisted session; null if stateless
}
```

- On a new conversation, **persist `session_id`** for follow-ups.
- `mode` is `"bm25"` when only a chat API key is configured; `"hybrid"` when embeddings are also configured.

### 4.2 `sources` — retrieval result batch

May appear **multiple times** per run (once per retrieval tool call, plus an optional carried batch on follow-ups).

```typescript
interface SourcesEvent {
  items: SearchHit[];
}

interface SearchHit {
  document_id: string;       // UUID
  document_title: string;
  document_tags: string[];
  chunk_index: number;
  content: string;
  score: number;             // RRF fused score
  es_rank: number | null;    // 1-based BM25 rank; null if leg missed
  vector_rank: number | null;
  es_score: number | null;
  vector_distance: number | null;
}
```

**Client guidance**

- **Append** every `sources` batch in arrival order for the current run.
- Citation numbers `[1]`, `[2]`, … in `answer_delta` refer to the **cumulative** list for that run.
- **Carry-forward:** on a follow-up, the **first** `sources` batch (immediately after `run_started`) may replay the previous run's hits. Fresh retrieval continues numbering after them.

### 4.3 `status` — phase progress (informational)

```typescript
interface StatusEvent {
  phase: "rewriting_query" | "generating";
}
```

| `phase` | Meaning | When |
|---------|---------|------|
| `rewriting_query` | Query rewrite LLM call starting | Follow-up with history and rewrite enabled |
| `generating` | Answer text about to stream | Once, before the first `answer_delta` |

Informational only — does not replace `done` / `error`.

### 4.4 `query_rewritten` — rewrite transparency

```typescript
interface QueryRewrittenEvent {
  original: string;
  rewritten: string;
  applied: true;
  changed: true;
}
```

Emitted **only** when rewrite ran and output **differs** from the original (byte-level).  
Not emitted on: first turn, no history, rewrite disabled, failure, empty output, unchanged text.

The persisted user message and session history always keep the **original** question.

### 4.5 `tool_call_started`

```typescript
interface ToolCallStartedEvent {
  call_id: string;
  tool_name: string;       // e.g. "search_knowledge", "mcp_*"
  args: Record<string, unknown>;
}
```

For `search_knowledge`, `args` includes:

```json
{ "query": "Redis 分布式锁的缺点", "limit": 8 }
```

### 4.6 `tool_call_finished`

```typescript
interface ToolCallFinishedEvent {
  call_id: string;
  tool_name: string;
  status: "success" | "failed";
  latency_ms: number;
}
```

`failed` covers MCP soft failures; the run may still end with `done`.

Honest per-tool order: `tool_call_started` → `sources` → `tool_call_finished`.

### 4.7 `answer_delta`

```typescript
interface AnswerDeltaEvent {
  text: string;
}
```

Concatenate fragments in order. Text may contain `[n]` citations referencing the run's cumulative `sources` list.

### 4.8 `done` — terminal success

```typescript
interface DoneEvent {
  run_id: string;
  outcome: "success";
  tool_calls: number;
  latency_ms: number;      // answer latency only (excludes post-answer summary maintenance)
  session_id: string | null;
}
```

### 4.9 `error` — terminal failure

```typescript
interface ErrorEvent {
  code: string;    // e.g. "llm_provider_error", "rate_limited", "internal_error"
  message: string;
}
```

After HTTP 200, stream failures are **only** signaled here.

---

## 5. Event ordering contracts

### 5.1 First turn (no rewrite, no carried sources)

```
run_started
→ tool_call_started
→ sources
→ tool_call_finished
→ status(generating)?     // optional, before first answer_delta
→ answer_delta*
→ done
```

Multiple retrievals repeat `[tool_call_started → sources → tool_call_finished]*`. Additional `sources` may appear between `answer_delta` chunks.

### 5.2 Follow-up with rewrite

```
run_started
→ sources*                // carried batch first when carry-forward is on
→ status(rewriting_query)?  // optional
→ query_rewritten?          // optional, only when changed
→ [tool_call_started → sources → tool_call_finished]*
→ status(generating)?       // optional
→ answer_delta*
→ done
```

### 5.3 Follow-up with sources carry-forward

```
run_started
→ sources                   // replay of previous run (first batch)
→ … rewrite / tool progress / answer …
→ done
```

**Hard rules**

1. Nothing between `run_started` and the carried `sources` batch.
2. `sources` still precede the `answer_delta` that cites them.
3. Each `tool_call_started` precedes its matching `tool_call_finished` (`call_id`).
4. `done` or `error` is terminal — no events after.

---

## 6. Session APIs

### 6.1 List — `GET /api/v1/chat/sessions`

Query parameters:

| Param | Type | Default | Notes |
|-------|------|---------|-------|
| `cursor` | string | — | From previous page `next_cursor` |
| `limit` | int | 20 | 1–100 |

Response:

```typescript
interface SessionPage {
  items: SessionRead[];
  next_cursor: string | null;
}

interface SessionRead {
  id: string;
  title: string;
  created_at: string;  // ISO 8601
  updated_at: string;
}
```

Sorted by `updated_at` descending (most recently active first).

### 6.2 Detail — `GET /api/v1/chat/sessions/{session_id}`

```typescript
interface SessionDetail extends SessionRead {
  messages: MessageRead[];
}

interface MessageRead {
  id: string;
  role: "user" | "assistant";
  content: string;
  run_id: string | null;  // assistant messages only; UUID string (SSE uses hex run_id)
  created_at: string;
}
```

**Note:** messages do **not** include `sources`. Cache `{ run_id → SearchHit[] }` from SSE if the UI needs citation panels for past turns.

### 6.3 Delete — `DELETE /api/v1/chat/sessions/{session_id}`

- Success: `204 No Content`
- Not found: `404`
- Deleted sessions cannot be continued

---

## 7. Integration examples

### 7.1 Event union (TypeScript)

```typescript
type ChatStreamEvent =
  | { event: "run_started"; data: RunStartedEvent }
  | { event: "sources"; data: SourcesEvent }
  | { event: "status"; data: StatusEvent }
  | { event: "query_rewritten"; data: QueryRewrittenEvent }
  | { event: "tool_call_started"; data: ToolCallStartedEvent }
  | { event: "tool_call_finished"; data: ToolCallFinishedEvent }
  | { event: "answer_delta"; data: AnswerDeltaEvent }
  | { event: "done"; data: DoneEvent }
  | { event: "error"; data: ErrorEvent };
```

### 7.2 Fetch streaming consumer

```typescript
async function chatStream(
  body: ChatRequest,
  onEvent: (name: string, data: unknown) => void,
): Promise<void> {
  const resp = await fetch("/api/v1/chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "text/event-stream",
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const err = await resp.json();
    throw new Error(`${err.error.code}: ${err.error.message}`);
  }

  const reader = resp.body!.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });

    let sep: number;
    while ((sep = buffer.indexOf("\n\n")) >= 0) {
      const block = buffer.slice(0, sep);
      buffer = buffer.slice(sep + 2);

      let eventName = "message";
      let dataStr = "";
      for (const line of block.split("\n")) {
        if (line.startsWith("event:")) eventName = line.slice(6).trim();
        if (line.startsWith("data:")) dataStr += line.slice(5).trim();
      }
      if (dataStr) onEvent(eventName, JSON.parse(dataStr));
    }
  }
}
```

### 7.3 Suggested run state

```typescript
interface RunState {
  runId: string | null;
  sessionId: string | null;
  phase: "idle" | "rewriting" | "searching" | "generating" | "done" | "error";
  sources: SearchHit[];
  answer: string;
  rewrite?: QueryRewrittenEvent;
  toolCalls: Map<string, ToolCallStartedEvent>;
}
```

### 7.4 Multi-turn usage

```typescript
let sessionId: string | undefined;

await chatStream({ question: "Redis 分布式锁？" }, (event, data) => {
  if (event === "run_started" && data.session_id) {
    sessionId = data.session_id;
  }
});

await chatStream(
  { question: "那它的缺点呢？", session_id: sessionId },
  (event, data) => { /* update UI */ },
);
```

---

## 8. Citations and sources panel

1. Maintain `sources: SearchHit[]` per run; append each `sources` batch in order.
2. On follow-up, the first batch may replay the previous run — numbering restarts at `[1]` **within this run**.
3. Fresh retrieval continues after carried hits (e.g. 2 carried → new hits start at `[3]`).
4. Tap `[n]` → `sources[n - 1]` (1-based).
5. Session detail API does not return sources; cache from SSE or rely on carried replay on the next turn.

---

## 9. UI progress hints

| Event | Suggested UI |
|-------|----------------|
| `status(rewriting_query)` | "Understanding your question…" |
| `query_rewritten` | Show rewritten retrieval query (collapsible) |
| `tool_call_started` (search) | "Searching: {args.query}" |
| `tool_call_finished` (failed) | Non-fatal tool warning |
| `status(generating)` | "Generating answer…" |
| `sources` | Update citations / sources panel |
| `answer_delta` | Stream into message bubble |

---

## 10. Full example (follow-up + rewrite + one retrieval)

```
event: run_started
data: {"run_id":"abc...","mode":"hybrid","session_id":"0199..."}

event: status
data: {"phase":"rewriting_query"}

event: query_rewritten
data: {"original":"那它的缺点呢？","rewritten":"Redis 分布式锁的缺点是什么？","applied":true,"changed":true}

event: tool_call_started
data: {"call_id":"call_1","tool_name":"search_knowledge","args":{"query":"Redis 分布式锁的缺点是什么？","limit":8}}

event: sources
data: {"items":[{...SearchHit...}]}

event: tool_call_finished
data: {"call_id":"call_1","tool_name":"search_knowledge","status":"success","latency_ms":142.5}

event: status
data: {"phase":"generating"}

event: answer_delta
data: {"text":"Redis 分布式锁的主要缺点包括 "}

event: answer_delta
data: {"text":"单点故障风险 [1]。"}

event: done
data: {"run_id":"abc...","outcome":"success","tool_calls":1,"latency_ms":2340.1,"session_id":"0199..."}
```

---

## 11. Compatibility notes

- **Backward compatible:** ignore unknown `event` types; clients that skip progress events still work.
- **Sources carry-forward:** enabled by default on the server; follow-ups may emit an extra leading `sources` batch.
- **Query rewrite:** enabled by default; no rewrite events on the first turn.
- **Auth:** no Bearer/API-key request header today; availability depends on server-side `CHAT_API_KEY`.

---

## 12. Server source of truth

Wire contract implemented in:

- `knowledge-base-server/src/app/schemas/chat.py` — payload models
- `knowledge-base-server/src/app/api/v1/endpoints/chat.py` — SSE event names
- `knowledge-base-server/.trellis/spec/backend/error-handling.md` — error taxonomy and SSE table

When in doubt, re-read those files after a server upgrade.
