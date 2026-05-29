# Story 002: 401 Token Refresh & Session Expiry Handling

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

**ADR Governing Implementation**: ADR-0004: Authentication Architecture
**ADR Decision Summary**: 401 response triggers one `supabase.auth.refreshSession()` call; on success, original request replayed with new token; on failure, `AUTH_SESSION_EXPIRED` event emitted.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-04**: Mock returns 401 then 200; refresh succeeds → resolves with 200 payload; two HTTP calls; retry carries new token; `AUTH_SESSION_EXPIRED` not emitted
- [ ] **AC-05**: Mock always returns 401; refresh fails → rejects with `code "SESSION_EXPIRED"`; `AUTH_SESSION_EXPIRED` emitted exactly once
- [ ] Concurrent 401 responses share a single in-flight refresh (not N parallel refresh calls)
- [ ] The refresh replay does not count against `MAX_RETRY_ATTEMPTS`

---

## Implementation Notes

- Axios response interceptor: on `status === 401`, check `isRefreshing` flag
  - If not refreshing: set `isRefreshing = true`, call `supabase.auth.refreshSession()`
  - If already refreshing: queue this request; resolve when refresh completes
- On refresh success: update stored token; replay all queued requests with new token; `isRefreshing = false`
- On refresh failure: emit `AUTH_SESSION_EXPIRED` on the global event bus; reject all queued requests with `{ code: 'SESSION_EXPIRED' }`; `isRefreshing = false`
- The replay of the original request after refresh uses the new token from the interceptor — it must not re-enter the 401 handler (set a flag on the retried config to skip the 401 interceptor)

---

## Out of Scope

- Session Expired modal UI (owned by Authentication epic's logout/session-expired handling)
- Retry policy for 5xx errors (Story 003)

---

## QA Test Cases

- **AC-04**: 401 then refresh succeeds
  - Given: Server returns 401 on first call; refreshSession returns new token; server returns 200 on retry
  - When: `apiClient.get('/v1/player/profile')` called
  - Then: 2 HTTP calls total; second call carries `Authorization: Bearer <new_token>`; promise resolves with 200 data; `AUTH_SESSION_EXPIRED` event NOT emitted

- **AC-05**: Unrecoverable 401 (refresh fails)
  - Given: Server always returns 401; `supabase.auth.refreshSession()` rejects
  - When: `apiClient.get('/v1/player/profile')` called
  - Then: Rejects with `{ code: 'SESSION_EXPIRED' }`; `AUTH_SESSION_EXPIRED` emitted exactly once (not twice)
  - Edge cases: Refresh called while offline (network error during refresh)

- **AC-concurrent**: Multiple concurrent 401 responses
  - Given: 3 simultaneous requests all get 401
  - When: First 401 triggers refresh; other two wait
  - Then: `supabase.auth.refreshSession()` called exactly once; all 3 requests replayed on success

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/api-client/401-token-refresh_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (API Client base established)
- Unlocks: Story 003 (retry & backoff)
