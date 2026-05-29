# Story 008: Missed Delta Dead-Reckoning & Match End Cleanup

> **Epic**: Real-time Transport
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol
**ADR Decision Summary**: Tick counter gap detection → dead-reckoning for 1-2 missed ticks; `state_resync_request` after 3+ consecutive missed ticks; room cleanup 10s after `match_end`.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-RT-14**: Client receives tick 38 and 40 (tick 39 missing) → dead-reckoning applied for the gap; client transitions smoothly to tick 40; no error thrown; no resync request for single missed tick
- [x] After 3+ consecutive missed ticks → client emits `state_resync_request { matchId, lastReceivedTick }`; server responds with full `state_snapshot`
- [x] **AC-RT-15**: `match_end` emitted → 10s later, room `match:{matchId}` has zero members; no further `match_state` events emitted

---

## Implementation Notes

- Dead-reckoning: when receiving tick N+2 without N+1, extrapolate: `position_N1 = position_N + velocity_N * 50ms` for missing tick
- Gap detection: compare `delta.tick` to `lastReceivedTick + 1`; if gap > 1: interpolate missing ticks with dead-reckoning
- Resync trigger: if `consecutiveMissedTicks >= 3`: `socket.emit('state_resync_request', { matchId, lastReceivedTick })`; server responds with `state_snapshot`
- Match end cleanup: server-side timer in Session Manager: `setTimeout(() => io.socketsLeave(roomId), 10_000)` after `match_end` emitted

---

## QA Test Cases

- **AC-RT-14**: Single missed delta — dead-reckoning
  - Given: Client received tick 38 (entity at x=100, vx=5); tick 39 missing; tick 40 arrives
  - When: Client processes tick 40
  - Then: Tick 39 position extrapolated as (125, 0) [100 + 5*50ms = 125]; tick 40 applied; no error; no resync request emitted
  - Edge cases: Entity stopped (vx=0) → dead-reckoned tick at same position (correct)

- **AC-RT-15**: Room cleanup
  - Given: Match ended; `match_end` emitted to all players
  - When: 10.1 seconds elapse
  - Then: `io.in('match:abc').fetchSockets()` returns `[]`; subsequent `state_delta` emit to room has 0 recipients (no-op)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/realtime-transport/missed-delta-recovery_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 007 (interpolation buffer), Story 002 (room model)
- Unlocks: Story 009 (serialization)
