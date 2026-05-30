# Story 001: Authenticated HTTP Requests & Header Injection

> **Epic**: API Client
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/api-client.md`
**Requirement**: `TR-api-???`

**ADR Governing Implementation**: ADR-0001: Client-Server Architecture; ADR-0004: Authentication Architecture
**ADR Decision Summary**: All HTTP calls flow through a single API Client module; JWT injected via Axios interceptor; base URL from `EXPO_PUBLIC_API_BASE_URL` env var.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-01**: `GET /v1/player/profile` with valid JWT and mock 200 → resolves with correct payload; `Authorization: Bearer <jwt>` header present
- [x] **AC-02**: `requiresAuth: false` endpoint → outbound request has NO `Authorization` header
- [x] **AC-03**: `requiresAuth: true` with no session → rejects with `code "AUTH_REQUIRED"`, zero HTTP calls made
- [x] **AC-14**: Base URL read from `EXPO_PUBLIC_API_BASE_URL`; all outbound URLs begin with that value
- [x] **AC-15**: Every outbound request carries `Content-Type: application/json`, `Accept: application/json`, and `X-App-Version: <non-empty>`
- [x] No screen or store makes a raw `fetch()` call — all HTTP goes through `apiClient`

---

## Implementation Notes

- Singleton `apiClient` instance created at app startup with `EXPO_PUBLIC_API_BASE_URL` as `baseURL`
- Axios request interceptor: calls `supabase.auth.getSession()` before each request; injects `Authorization: Bearer` header if session exists and endpoint `requiresAuth: true`
- If `requiresAuth: true` and no session: reject with `ApiError({ code: 'AUTH_REQUIRED', httpStatus: null })` — make zero HTTP calls
- Default headers set on the Axios instance: `Content-Type`, `Accept`, `X-App-Version` from Expo manifest
- Endpoint config: `src/api/endpoints.ts` with typed constants `{ path, method, requiresAuth }` for every route

---

## Out of Scope

- 401 token refresh flow (Story 002)
- Retry logic (Story 003)
- Offline queue (Story 004)

---

## QA Test Cases

- **AC-01**: Authenticated request succeeds
  - Given: Valid JWT; server mock returns 200 with `{ displayName: "Vex_King" }`
  - When: `apiClient.get('/v1/player/profile')` called
  - Then: Resolves with `{ data: { displayName: "Vex_King" }, httpStatus: 200 }`; `Authorization` header = `Bearer <jwt>`
  - Edge cases: JWT with special characters (valid base64)

- **AC-02**: Unauthenticated endpoint — no auth header
  - Given: `endpoint.requiresAuth = false`
  - When: `apiClient.post('/v1/auth/register', body)` called
  - Then: Outbound request has no `Authorization` header; `Content-Type: application/json` present

- **AC-03**: Auth required but no session → immediate rejection
  - Given: `supabase.auth.getSession()` returns null
  - When: `apiClient.get('/v1/player/profile')` called
  - Then: Rejects with `{ code: 'AUTH_REQUIRED' }`; Axios never makes HTTP call (0 intercepted requests)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/api-client/authenticated-requests_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (first story)
- Unlocks: Story 002 (401 refresh flow)
