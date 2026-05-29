# Story 003: Input Handling & Server Application

> **Epic**: Real-time Transport
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol; ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: `BASIC_ATTACK` / `USE_ABILITY` events queued server-side; processed on next tick; inputs >3 ticks old discarded.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-RT-06**: Player emits `input_move { seq: 1, dx: 1.0, dy: 0.0 }` → next `state_delta` reflects position change consistent with rightward movement
- [ ] Inputs received after the tick boundary for their timestamp are processed in the next tick (late inputs do not cause tick budget overrun)
- [ ] Inputs older than 3 ticks (150ms) are discarded; server logs discarded inputs
- [ ] Client cannot inject game state via input events — only `BASIC_ATTACK`, `USE_ABILITY`, `input_move`, `input_ability` events accepted; others ignored

---

## Implementation Notes

- Per-player input queue: `Map<playerId, PlayerInput[]>` cleared at start of each tick
- Tick Phase 1: drain input queue; validate each input (ownership, bounds, staleness)
- Input stale check: `server.currentTick - input.tick > INPUT_STALE_THRESHOLD_TICKS (3)` → discard + log
- `socket.data.userId` is the authoritative `playerId` — never trust a `playerId` field in the event payload
- Unknown event types: Socket.io ignores unregistered event handlers; add explicit catch-all for unknown events to log + ignore

---

## QA Test Cases

- **AC-RT-06**: Input applied to next tick state
  - Given: Player at position (0, 0); standing still
  - When: `input_move { dx: 1.0, dy: 0.0, seq: 1, timestamp: now }` emitted
  - Then: Next `state_delta` shows player.x > 0 (moved rightward by at least `moveSpeed * 50ms`)

- **AC-stale**: Stale input discarded
  - Given: Server at tick 10; input arrives with `tick: 6` (4 ticks old > threshold 3)
  - When: Server processes input queue
  - Then: Input discarded; `STALE_INPUT_DISCARDED` log entry emitted; player position unchanged for that input

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/realtime-transport/input-handling_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (room model), Match Server epic
- Unlocks: Story 004 (RTT measurement)
