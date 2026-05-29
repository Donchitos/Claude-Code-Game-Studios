# Story 003: Retry Policy with Exponential Backoff

> **Epic**: API Client
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/api-client.md`
**Requirement**: `TR-api-???`

**ADR Governing Implementation**: ADR-0001: Client-Server Architecture
**ADR Decision Summary**: Retry applies to TimeoutError, NetworkError, HTTP 5xx. Max 3 attempts after initial failure. Backoff: `min(500ms × 2^(n-1) + jitter, 8000ms)`.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-06**: Mock returns 500 × 3 then 200; `MAX_RETRY_ATTEMPTS = 3` → resolves; 4 HTTP calls; waits ≥500ms, ≥1000ms, ≥2000ms between attempts (±200ms jitter)
- [ ] **AC-07**: Mock always returns 500; `MAX_RETRY_ATTEMPTS = 3` → rejects `code "SERVER_ERROR"`, `httpStatus 500`; 4 HTTP calls total
- [ ] **AC-08**: Mock hangs; `REQUEST_TIMEOUT_MS = 1000`; `MAX_RETRY_ATTEMPTS = 0` → rejects `code "TIMEOUT"` within 1200ms; 1 HTTP call
- [ ] Non-retryable errors (4xx except 401/429, malformed response) → NOT retried; 1 HTTP call
- [ ] Each retry gets a fresh timeout window (not shared with original attempt)

---

## Implementation Notes

- Retry logic: Axios retry adapter or custom interceptor
- Retryable conditions: `status >= 500`, `error.code === 'ECONNABORTED'` (timeout), `error.code === 'ERR_NETWORK'`
- Non-retryable: `400`, `403`, `404`, `MalformedResponseError`, `AuthRequiredError`, `SessionExpiredError`
- Backoff formula: `Math.min(BASE_RETRY_DELAY_MS * Math.pow(BACKOFF_MULTIPLIER, attempt - 1) + Math.random() * JITTER_MAX_MS, MAX_RETRY_DELAY_MS)`
- Timeout: use `AbortController` with `setTimeout`; abort after `REQUEST_TIMEOUT_MS`; each attempt creates a new `AbortController`
- Config constants in `src/api/apiClientConfig.ts` with defaults from GDD Table 7

---

## Out of Scope

- 429 rate limit handling (covered in Story 005)
- Offline queue (Story 004)

---

## QA Test Cases

- **AC-06**: 500s then success
  - Given: Mock returns 500 on attempts 1-3; returns 200 on attempt 4
  - When: `apiClient.get('/v1/match/history')` called with `MAX_RETRY_ATTEMPTS=3`
  - Then: Resolves with 200 data; 4 total calls; delays between calls: ≥500ms, ≥1000ms, ≥2000ms (measured via timestamps)
  - Edge cases: Retry with body (POST idempotency — ensure body is re-sent on retry)

- **AC-07**: All retries exhausted
  - Given: Mock always returns 500
  - When: Called with `MAX_RETRY_ATTEMPTS=3`
  - Then: Rejects with `{ code: 'SERVER_ERROR', httpStatus: 500 }`; exactly 4 HTTP calls

- **AC-08**: Timeout with no retry
  - Given: Mock never responds; `REQUEST_TIMEOUT_MS=1000`; `MAX_RETRY_ATTEMPTS=0`
  - When: Called
  - Then: Rejects with `{ code: 'TIMEOUT' }` within 1200ms; exactly 1 HTTP call (AbortController fired)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/api-client/retry-backoff_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (API Client base)
- Unlocks: Story 004, Story 005
