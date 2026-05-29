# Story 006: Duplicate Socket Deduplication

> **Epic**: Real-time Transport
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol
**ADR Decision Summary**: One socket per userId; second connection evicts the first with `auth_error { reason: "DUPLICATE_SESSION" }`; if first socket was in a match, room membership transfers to new socket.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-RT-11**: Player has active socket in IN_LOBBY; same player opens second socket with same JWT → first socket receives `auth_error { reason: "DUPLICATE_SESSION" }` and disconnects; second socket proceeds to IN_LOBBY
- [ ] If first socket was in a match room, room membership transfers to new socket; `state_snapshot` emitted to new socket
- [ ] Race condition prevention: Redis lock on `userId` during auth middleware serializes concurrent auth attempts from same `userId`

---

## Implementation Notes

- Server: maintain `Map<userId, Socket>` (`activeUserSockets`)
- In auth middleware (after successful JWT validation): check `activeUserSockets.get(userId)`; if exists, emit `auth_error { reason: 'DUPLICATE_SESSION' }` to the OLD socket and disconnect it; update map to new socket
- Redis lock (optional at MVP): `SET lock:auth:{userId} 1 PX 3000 NX` to serialize concurrent auth from same userId; release after middleware completes
- Room transfer: if old socket was in a match room, call `newSocket.join(matchRoomId)`; emit `state_snapshot` to new socket

---

## QA Test Cases

- **AC-RT-11**: Duplicate socket eviction
  - Given: Socket A connected as userId `abc`; active in IN_LOBBY state
  - When: Socket B connects with same JWT (userId `abc`)
  - Then: Socket A receives `auth_error { reason: 'DUPLICATE_SESSION' }`; Socket A disconnected; Socket B in IN_LOBBY; `activeUserSockets.get('abc')` === Socket B

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/realtime-transport/duplicate-socket-dedup_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (connection lifecycle)
- Unlocks: Story 007 (prediction & reconciliation)
