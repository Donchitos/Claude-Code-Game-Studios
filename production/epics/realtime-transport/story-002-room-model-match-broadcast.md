# Story 002: Room Model & Match State Broadcast

> **Epic**: Real-time Transport
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol
**ADR Decision Summary**: Each match → one Socket.io room `match:{matchId}`; server joins sockets; `match_state` broadcast via `io.to(room).emit()` at 20Hz.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-RT-04**: 2 authenticated sockets assigned to a match → both members of `match:<matchId>` room; `state_delta` received by both and ONLY both
- [x] **AC-RT-05**: Tick loop runs for 1 second → exactly 20 `state_delta` events emitted (±1 for timing tolerance)
- [x] **AC-RT-15**: After `match_end` emitted + 10s elapsed → room `match:<matchId>` has zero members; no further events emitted
- [x] Server NEVER emits match state to individual sockets — only to `io.to(roomId).emit()`
- [x] Players cannot self-join rooms — only server can call `socket.join()`

---

## Implementation Notes

- Session Manager calls `socket.join(`match:${matchId}`)` when session enters `active` state
- Tick broadcast: `io.to(`match:${matchId}`).emit('match_state', snapshot)` every 50ms
- Room cleanup: after `match_end`, call `io.socketsLeave(`match:${matchId}`)` after 10-second grace delay
- Verify room membership: use `io.in(roomId).fetchSockets()` in tests to assert room contents
- Client cannot join: Socket.io v4 disallows `socket.join()` from client by default; confirm server is not re-exposing this

---

## QA Test Cases

- **AC-RT-04**: Room isolation
  - Given: Sockets A and B in room `match:abc`; Socket C authenticated but in different room
  - When: Server emits `state_delta` to `match:abc`
  - Then: Sockets A and B receive event; Socket C does not

- **AC-RT-05**: 20Hz broadcast rate
  - Given: Active match; 1 player in room
  - When: Server tick loop runs for exactly 1000ms
  - Then: Player socket receives 19, 20, or 21 `match_state` events (timing tolerance)

- **AC-RT-15**: Room cleanup after match_end
  - Given: Match ended; `match_end` emitted
  - When: 10.1 seconds elapse
  - Then: `io.in('match:abc').fetchSockets()` returns empty array; no further events emitted to room

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/realtime-transport/room-broadcast_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (connection lifecycle)
- Unlocks: Story 003 (input handling)
