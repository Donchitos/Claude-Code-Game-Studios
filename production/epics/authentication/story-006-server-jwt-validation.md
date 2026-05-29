# Story 006: Server-Side JWT Validation

> **Epic**: Authentication
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/authentication.md`
**Requirement**: `TR-auth-???`

**ADR Governing Implementation**: ADR-0004: Authentication Architecture
**ADR Decision Summary**: RS256 local validation using cached Supabase public key; adds ≤1ms per request; middleware on all HTTP routes and Socket.io connections; `userId` always extracted from JWT, never from request body.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: Supabase RS256 public key endpoint — confirm key URL hasn't changed post-May-2025 before implementing.

---

## Acceptance Criteria

- [ ] A request sent with a forged or expired JWT is rejected with 401 and does not execute the privileged operation
- [ ] The server never processes a `userId` from the request body — identity is always extracted from the validated JWT
- [ ] Unauthenticated Socket.io socket is disconnected within 5 seconds of connecting
- [ ] `socket.data.userId` is set from validated JWT; never from any client-supplied payload
- [ ] JWT validation adds ≤1ms overhead (benchmarked under load)

---

## Implementation Notes

- Implement `IJWTValidator` using `jsonwebtoken.verify()` with the Supabase RS256 public key
- Cache the public key in memory; refresh every 24h or on validation failure (re-fetch then retry once)
- Express middleware: apply to all `/v1/*` routes except `POST /v1/auth/register` and `POST /v1/auth/login`
- Socket.io middleware: validate `socket.handshake.auth.token`; set `socket.data.userId`; call `next()` on success; call `next(new Error('auth_error'))` on failure
- 5-second unauthenticated disconnect: attach a `setTimeout(socket.disconnect, 5000)` at connect; clear it in the auth middleware after successful validation
- Test: forged JWT (modified payload), expired JWT (`exp` in the past), missing JWT, valid JWT with wrong `iss`

---

## Out of Scope

- Session blacklist check (Redis revocation — deferred to a future hardening story)
- Real-time Transport JWT validation (covered in realtime-transport stories)

---

## QA Test Cases

- **AC-1**: Forged JWT rejected
  - Given: Request with a JWT whose payload has been modified (signature invalid)
  - When: Server middleware validates
  - Then: 401 returned; no handler function executes; no DB query made
  - Edge cases: Valid format but wrong signing key; valid JWT from different Supabase project

- **AC-2**: Expired JWT rejected
  - Given: Request with a JWT where `exp` is 1 second in the past
  - When: Server middleware validates
  - Then: 401 returned with reason `TOKEN_EXPIRED`; privileged operation not executed

- **AC-3**: `userId` from JWT, not body
  - Given: Request with valid JWT for user A; request body contains `{ userId: "user-B" }`
  - When: Handler processes the request
  - Then: Operation executes for user A (from JWT); user B's data not affected; no error

- **AC-4**: Unauthenticated socket disconnected at 5s
  - Given: Socket connects but never emits `authenticate`
  - When: 5 seconds elapse
  - Then: Socket receives disconnect event; server-side socket is removed; no memory leak

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/authentication/server-jwt-validation_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (JWT issuance from registration/login)
- Unlocks: All server-side epics (every story that calls a protected endpoint)
