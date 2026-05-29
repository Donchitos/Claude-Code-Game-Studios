# Story 004: Token Refresh Lifecycle

> **Epic**: Authentication
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/authentication.md`
**Requirement**: `TR-auth-???`

**ADR Governing Implementation**: ADR-0004: Authentication Architecture
**ADR Decision Summary**: Supabase SDK handles background refresh automatically; server-side RS256 validation adds ≤1ms overhead; 401 response triggers one refresh attempt then retry.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] With `REFRESH_LEAD_SECONDS = 60`, a background refresh fires before the access token expires, with no UI interruption
- [x] If the device is taken offline during refresh, the session remains usable until the access token expires; once expired, Session Expired modal appears
- [x] A token-related 401 response triggers one refresh attempt and, if refresh succeeds, retries the original privileged request once
- [x] `REFRESH_LEAD_SECONDS` set to 0 → client falls back to 60s default; config error is logged
- [x] Concurrent 401 responses trigger exactly one refresh attempt (not N parallel refreshes)

---

## Implementation Notes

- Supabase JS SDK handles `REFRESH_LEAD_SECONDS` internally via its own session management; do NOT implement a custom refresh timer unless the SDK's behavior is insufficient
- Serialize concurrent refresh attempts: use a boolean flag (`isRefreshing`) + a Promise queue; if refresh is in flight, subsequent callers wait for it to resolve
- On 401 from API Client: call `supabase.auth.refreshSession()`; on success, replay original request once; on failure, emit `AUTH_SESSION_EXPIRED` event
- `REFRESH_LEAD_SECONDS` = 0 guard: validate in the auth config; if ≤ 0, log `CONFIG_ERROR: REFRESH_LEAD_SECONDS invalid, using default 60` and set to 60
- Session Expired modal: must block all navigation; show "Your session has expired — please log in again" with a single login CTA

---

## Out of Scope

- The 401 serialization logic lives in the API Client (Story api-client/story-002)
- Mid-match refresh scenario (active match continues; refresh fires in background — tested in Integration)

---

## QA Test Cases

- **AC-1**: Background refresh fires before expiry
  - Given: Access token with 65s remaining until expiry
  - When: 5 seconds elapse (`REFRESH_LEAD_SECONDS = 60`, so threshold = 5s from now)
  - Then: `supabase.auth.getSession()` returns a new non-expired token; no UI interruption; no login prompt
  - Edge cases: Refresh during active match; refresh while app is backgrounded

- **AC-2**: Offline during refresh — session usable until expiry
  - Given: Device goes offline; access token has 30s remaining
  - When: Refresh attempt fails (network error); access token expires after 30s
  - Then: Requests within 30s succeed with existing token; after 30s, Session Expired modal shows

- **AC-3**: 401 triggers one refresh then retry
  - Given: Server returns 401 on first request
  - When: Refresh succeeds; original request retried
  - Then: Exactly 2 HTTP calls; second call uses new token; response succeeds; `AUTH_SESSION_EXPIRED` not emitted

- **AC-4**: `REFRESH_LEAD_SECONDS = 0` fallback
  - Given: Config specifies `REFRESH_LEAD_SECONDS = 0`
  - When: Auth module initializes
  - Then: Effective value is 60; `CONFIG_ERROR` log entry contains `REFRESH_LEAD_SECONDS invalid`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/authentication/token-refresh_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (session persistence established)
- Unlocks: Story 005 (logout), Story 006 (server JWT validation)
