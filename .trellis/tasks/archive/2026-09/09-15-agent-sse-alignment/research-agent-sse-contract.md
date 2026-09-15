# Research: Agent SSE contract (issue #1) + client SSE inventory

Verified 2026-09-15 against server source (`../knowledge-base-server`,
commit `a16d933`, file `src/app/schemas/agent_stream.py`) — matches issue #1.

## Wire contract (server-verified)

Both endpoints keep **POST + path**; success responds `text/event-stream`
(`EventSourceResponse`), no JSON body. Event discipline = same as chat
(`event:` + `data:` lines, `:` comment/heartbeat lines possible).

Order: `run_started → [summary_progress …] (summary only) → summary |
associations → done`; failure after HTTP 200: `… → error` (stream closes).

| event | data fields | notes |
|---|---|---|
| `run_started` | `run_id` str, `kind` "summary"\|"associations", `document_id` uuid | first event of every stream |
| `summary_progress` | `phase` "map_pass"\|"reduce_pass", `pass_index` 1-based int, `passes_total` int | summary only, informational; fixed grammar: map passes + one reduce (`pass_index == passes_total`); single-chunk docs still emit map(1/2)+reduce(2/2) |
| `summary` | `document_id`, `summary`, `model`, `latency_ms` | **flat — byte-identical fields to the old `SummaryResult` JSON** |
| `associations` | `document_id`, `associations[]`, `model`, `latency_ms` | **flat — identical to the old `AssociationsResult` JSON** |
| `done` | `run_id`, `outcome` "success", `latency_ms` | terminal success, stream closes |
| `error` | `code`, `message` | terminal failure; **same shape as chat's ErrorEvent** (one error dialect, e.g. `llm_provider_error`) |

- Cache hit: `run_started → result → done` (no progress events).
- Pre-stream HTTP errors unchanged (server "priming" validates the document
  before the first yield): 404 `not_found` (missing/soft-deleted), 401/403 —
  plain JSON error envelope, non-200. These happen **before** the stream
  starts, so the existing non-2xx envelope handling covers them.
- Backend reference: `src/app/api/v1/endpoints/documents.py`,
  `src/app/api/v1/endpoints/sse.py` (shared serializer),
  `.trellis/spec/backend/error-handling.md` (document-agent event table).

## Client SSE inventory (existing, reusable)

- `lib/core/network/sse_parser.dart`
  - `Utf8StreamDecoder` — chunk-boundary-safe UTF-8 decode; reusable as-is.
  - `SseChatParser` — pure incremental frame parser (blank-line frames,
    `\n`/`\r\n`/`\r`, multi-line `data`, comment skip, non-JSON frames
    ignored, post-terminal ignored) but **hardwired to ChatEvent types**.
- `lib/core/network/sse_client.dart` — `SseClient.chatStream`: opens via
  `ChatTransport.open(uri, jsonBody)`, normalizes transport failures into a
  terminal error event, unterminated stream → `network_error`.
- `ChatTransport` (native/web conditional imports): web streaming **must**
  go through it — the issue's bare `dio.post(ResponseType.stream)` sketch is
  IO-only and must not be used for web.
- Provider: `sseClientProvider` rebuilt on base-URL change.

## Design decisions for this task

1. **Extract shared framing**: pull the wire-frame rules out of
   `SseChatParser` into a generic frame parser (event name + raw data string
   per completed frame; JSON decode and event typing stay with the caller).
   `SseChatParser` is rebuilt on top of it — chat behavior must not change
   (its test suite is the regression net).
2. **Agent events model**: new DTOs (e.g. `lib/shared/models/agents_stream.dart`):
   `AgentRunStarted(runId, kind, documentId)`, `SummaryProgress(phase,
   passIndex, passesTotal)`; the result payloads reuse the existing
   `SummaryResult` / `AssociationsResult` DTOs (server subclasses them flat).
   `error` maps to thrown `ApiException(code, message)` — the UI's existing
   error rendering (friendly `chat_unavailable` copy, `llm_provider_error`
   message) keeps working unchanged.
3. **Repository API shape stays**: `Future<SummaryResult> summarize(id,
   {onProgress})` / `Future<AssociationsResult> listAssociations(id)` —
   internally consumes the stream; `onProgress(SummaryProgress)` feeds the
   UI. Terminal `error` event, premature stream end without a result, and
   transport failures all surface as thrown `ApiException`
   (`network_error` for silent drops, mirroring `SseClient`).
4. **Progress UX** (user-confirmed): bubble content layer's generating row
   shows live progress for summary — map_pass → 「正在阅读第 x/y 段」,
   reduce_pass → 「正在汇总要点」; associations keeps the generic spinner
   (no progress events on that stream). `run_started`/`done` are consumed
   for stream lifecycle (record run_id, close) but render nothing.
5. **OnDemandState** gains an optional progress field cleared on
   success/failure/generation start; the notifier's guards (in-flight no-op,
   generation-counter stale guard, failure-keeps-result) are unchanged.
