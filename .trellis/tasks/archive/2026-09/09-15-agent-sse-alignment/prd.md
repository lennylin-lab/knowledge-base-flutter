# 摘要/关联接口对接 SSE 事件流

## Goal

Align the client with issue #1 / server commit `a16d933`:
`POST /documents/{id}/summary` and `/associations` now answer
`text/event-stream` instead of a JSON body. Same paths, same result
payloads (flat, identical to the old bodies). Client switches to SSE
consumption: shared frame parsing, `ChatTransport`-based streaming,
`error` events → `ApiException`, live `summary_progress` in the bubble
(user-confirmed scope), while the result DTOs and the
`OnDemandGenerationNotifier` guards stay unchanged.

## Background / Evidence

- Server contract verified against `../knowledge-base-server`
  `src/app/schemas/agent_stream.py` + commit `a16d933` — full event table,
  order, cache-hit shape, pre-stream 404/401/403 (priming), heartbeat
  comments: see `research-agent-sse-contract.md` in this directory.
- Client has reusable SSE infra: `Utf8StreamDecoder` (chunk-safe),
  `SseChatParser` (framing, chat-typed), `ChatTransport` native/web split
  (**web streaming must go through it** — the issue's dio stream sketch is
  IO-only), `SseClient` error-normalization precedents.

## Design decisions

1. **Shared frame parser**: extract the SSE framing rules from
   `SseChatParser` into a generic frame parser (event name + raw data per
   frame; JSON decode/typing stay with callers). Rebuild `SseChatParser` on
   top — chat behavior must not change (its suite is the regression net).
   This follows the issue's "统一封装 SSE 解析器" so future chat/writing
   streams share one discipline.
2. **Agent stream DTOs** (`lib/shared/models/agents_stream.dart` or similar):
   `AgentRunStarted{runId, kind, documentId}`, `SummaryProgress{phase,
   passIndex, passesTotal}`; result payloads reuse existing `SummaryResult` /
   `AssociationsResult` DTOs untouched.
3. **Repository API shape unchanged**: `Future<SummaryResult> summarize(id,
   {void Function(SummaryProgress)? onProgress})`, same for
   `listAssociations`. Internally: open via `ChatTransport` (agent endpoint
   paths, POST, no body), parse frames, complete with the result event's
   payload. Failure surfaces — terminal `error` event → `ApiException(code,
   message)`; premature stream end without a result or transport drop →
   `ApiException(network_error)`; pre-stream non-2xx envelope → existing
   `ApiException` path (404 `not_found` etc. keep working).
4. **Progress consumption** (confirmed): `OnDemandState` gains an optional
   progress line cleared on success/failure/new generation; bubble content
   layer renders summary progress (map_pass → 「正在阅读第 x/y 段」,
   reduce_pass → 「正在汇总要点」); associations keeps the generic spinner
   hint. Notifier guards (in-flight no-op, stale generation counter,
   failure-keeps-result) unchanged.

## Requirements

1. Shared frame parser extraction as above; `SseChatParser` refactored onto
   it with zero chat behavior change.
2. Agent stream events model + parsing (`run_started`, `summary_progress`,
   `summary`, `associations`, `done`, `error`; unknown events and `:`-comment
   frames ignored; post-terminal frames ignored).
3. Repository methods consume the stream per Design decisions, incl.
   multi-line `data`, heartbeat lines, premature-end failure, and pre-stream
   envelope errors.
4. UI: progress line in the bubble content layer per Design decision 4;
   nothing else changes visually.
5. Tests:
   - Frame parser unit tests (extracted parser: frames, comments,
     multi-line data, split-chunk boundaries — plus existing chat parser
     tests passing unchanged).
   - Repository/agent-stream tests against a scripted byte-stream adapter:
     full happy path (progress order map 1..n + reduce, then result, done),
     cache-hit shape (no progress), error event → `ApiException(code)` with
     statusCode semantics preserved for UI copy (`chat_unavailable`,
     `llm_provider_error`), premature end → `network_error`, pre-stream 404
     envelope → `not_found`.
   - Notifier: progress line updates during generation and clears on
     terminal; guards unchanged (stale generation drops late progress).
   - Widget: bubble shows live progress copy for summary; associations
     spinner unchanged; result/error flows regress none.
   - Existing suites green (chat parser/provider/widget untouched
     behaviorally).
6. `flutter analyze` clean; full `flutter test` green.

## Constraints

- `SummaryResult` / `AssociationsResult` DTOs unchanged (server kept the
  payload shape).
- `OnDemandGenerationNotifier` guard semantics unchanged; only additive
  progress state.
- Web must stream through `ChatTransport` — no dio `ResponseType.stream`.
- AppSizes/Chinese-copy/const conventions where UI is touched.

## Acceptance Criteria

- [ ] Shared SSE frame parser extracted; chat tests pass unchanged.
- [ ] Both repository methods consume the agent SSE stream and return the
      same result types as before; error events map to `ApiException(code,
      message)`; premature end maps to `network_error`.
- [ ] Pre-stream 404 envelope still surfaces as `not_found`.
- [ ] Bubble shows live summary progress (map/reduce copy) and terminal
      states exactly as before; associations spinner unchanged.
- [ ] Notifier guards unchanged; late/stale progress cannot clobber newer
      state.
- [ ] `flutter analyze` clean; full `flutter test` green.
