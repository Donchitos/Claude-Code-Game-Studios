# Story 001: Connection Lifecycle & JWT Authentication

> **Epic**: Real-time Transport
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol; ADR-0004: Authentication Architecture
**ADR Decision Summary**: Socket.io v4 WebSocket-only; JWT auth middleware on connect; unauthenticated sockets disconnected after 5s; `socket.data.userId` set from validated JWT.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-RT-01**: Valid JWT → connection reaches IN_LOBBY state within 500ms; no `auth_error` emitted
- [x] **AC-RT-02**: Tampered/invalid JWT → `auth_error { reason: "TOKEN_INVALID" }` emitted; socket closed within 200ms
- [x] **AC-RT-03**: Expired JWT → `auth_error { reason: "TOKEN_EXPIRED" }` emitted; socket closed
- [x] Unauthenticated socket (no token in handshake) → `auth_error { reason: "TOKEN_MISSING" }` + disconnect within 5s
- [x] `socket.data.userId` correctly set from JWT `sub` claim after successful auth

---

## Implementation Notes

- Server: `io.use(async (socket, next) => { ... })` middleware using `IJWTValidator.validateToken()`
- Transport: `transports: ['websocket']` on both client (`socket.io-client`) and server — no polling
- 5s timeout: `const timeout = setTimeout(() => socket.disconnect(true), 5000)` set on connect; cleared by auth middleware on success
- Auth reason codes: `TOKEN_MISSING` (no auth.token), `TOKEN_INVALID` (bad signature), `TOKEN_EXPIRED` (exp in past), `SESSION_REVOKED` (Redis blacklist — deferred)
- `DUPLICATE_SESSION` (AC from GDD §3.2 Step 5) handled in Story 006

---

## QA Test Cases

- **AC-RT-01**: Valid JWT → IN_LOBBY
  - Given: Server running; valid non-expired JWT
  - When: `socket.connect({ auth: { token: jwt } })` called
  - Then: Socket emits `connect` event within 500ms; server has `socket.data.userId` set; no `auth_error`

- **AC-RT-02**: Invalid JWT → error + close
  - Given: JWT with modified payload (signature invalid)
  - When: Socket connects
  - Then: `auth_error { reason: 'TOKEN_INVALID' }` received within 200ms; socket closed

- **AC-RT-03**: Expired JWT → error + close
  - Given: JWT with `exp` 60 seconds in the past
  - When: Socket connects
  - Then: `auth_error { reason: 'TOKEN_EXPIRED' }` received; socket closed

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/realtime-transport/connection-lifecycle_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Authentication Story 006 (JWT validation middleware)
- Unlocks: Story 002 (room model)
