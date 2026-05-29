# Story 005: Rate Limiting & Malformed Response Handling

> **Epic**: API Client
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/api-client.md`
**Requirement**: `TR-api-???`

**ADR Governing Implementation**: ADR-0001: Client-Server Architecture
**ADR Decision Summary**: 429 reads `Retry-After` header; waits then retries (counts against budget). `MalformedResponseError` on non-JSON 2xx — not retried.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-12**: Mock returns 429 with `Retry-After: 2` then 200 → resolves; 2 HTTP calls; wait ≥2000ms and ≤2500ms
- [ ] **AC-13**: Mock returns 200 with non-JSON body → rejects immediately with `code "MALFORMED_RESPONSE"`; exactly 1 HTTP call
- [ ] 429 without `Retry-After` header → waits `RATE_LIMIT_DEFAULT_WAIT_MS` (5000ms) then retries
- [ ] 429 retry counts against `MAX_RETRY_ATTEMPTS`; on exhaustion → `RateLimitError`

---

## Implementation Notes

- In Axios response interceptor: on `status === 429`, read `Retry-After` header (`parseInt(headers['retry-after']) * 1000`) or fallback to `RATE_LIMIT_DEFAULT_WAIT_MS`
- `await new Promise(resolve => setTimeout(resolve, waitMs))` then retry
- Retry counts: 429 retry shares the `MAX_RETRY_ATTEMPTS` budget with other retries
- Malformed response: in response handler, if `status 2xx` and `response.headers['content-type']` does not include `application/json`, throw `MalformedResponseError`; also catch `JSON.parse` throws on 2xx bodies
- On `MalformedResponseError`: emit `MALFORMED_RESPONSE` event on the global event bus (for Analytics); do NOT retry

---

## Out of Scope

- Analytics event consumption of `MALFORMED_RESPONSE` (Analytics epic)

---

## QA Test Cases

- **AC-12**: 429 with Retry-After respected
  - Given: Mock returns 429 with `Retry-After: 2`; then 200
  - When: `apiClient.post('/v1/matchmaking/queue', body)` called
  - Then: Resolves; 2 HTTP calls; time between calls ≥2000ms and ≤2500ms (±200ms jitter tolerance)
  - Edge cases: `Retry-After: 0` (treat as 1s minimum); `Retry-After` not a number (fallback to default)

- **AC-13**: Non-JSON 2xx not retried
  - Given: Mock returns 200 with `Content-Type: text/html; charset=utf-8`
  - When: Called
  - Then: Rejects immediately with `{ code: 'MALFORMED_RESPONSE' }`; exactly 1 HTTP call; `MALFORMED_RESPONSE` event emitted

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/api-client/rate-limiting-malformed_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (retry infrastructure)
- Unlocks: No remaining API Client stories
