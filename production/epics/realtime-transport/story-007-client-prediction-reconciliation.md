# Story 007: Client-Side Prediction & Reconciliation

> **Epic**: Real-time Transport
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol; ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Client runs local simulation for immediate response; reconciles against server authoritative state; snap if error > 50cm threshold; re-simulate pending inputs.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-RT-12**: Match at 20Hz tick rate; opponent moving at constant velocity → opponent rendered visually smooth at 60fps with no stutter under <100ms RTT conditions [Manual QA]
- [ ] **AC-RT-13**: Client predicted position diverges from server authoritative by > `PREDICTION_CORRECTION_THRESHOLD` → client hard-snaps to authoritative position; re-simulates pending inputs with seq > delta tick; no inputs with seq ≤ delta tick remain in pending buffer
- [ ] State interpolation: alpha = `(renderTime - tick_A.timestamp) / (tick_B.timestamp - tick_A.timestamp)` clamped [0, 1]
- [ ] Interpolation buffer holds last 2 received authoritative ticks; renders interpolated position between them at 60fps

---

## Implementation Notes

- `MatchStateBuffer`: ring buffer of 2 `MatchSnapshot` slots; `push(snapshot)` overwrites oldest
- `getInterpolated(renderTime)`: lerp positions between tick_A and tick_B; clamp alpha [0, 1]
- HUD reads from buffer via `requestAnimationFrame` — NOT via React state (stays off the React render cycle)
- Pending inputs buffer: `{ seq, inputSnapshot, localStateAfterInput }[]`; cleared as server acks cover them
- Reconciliation: when `|predictedPos - serverPos| > PREDICTION_CORRECTION_THRESHOLD (50cm)`: snap + re-simulate
- Small error: smooth blend toward authoritative over 3 frames

---

## QA Test Cases

- **AC-RT-12** [Manual]: Visual smoothness
  - Setup: 2-player match on LAN (<5ms RTT); opponent moving at constant speed
  - Verify: Opponent rendered at 60fps; no visible jitter or teleporting
  - Pass condition: No visible position discontinuities in 30s of play

- **AC-RT-13**: Prediction snap + re-simulate
  - Given: Client predicts player at (100, 0); server authoritative state at tick 40 shows player at (51, 0) — delta of 49cm (just under threshold) and then at (155, 0) — delta of 55cm (over threshold)
  - When: `state_delta` for tick 40 arrives
  - Then: For 55cm case: position hard-snaps to (155, 0); pending inputs with seq > 40 re-simulated; pending inputs with seq ≤ 40 removed from buffer
  - Edge cases: Snap during ability animation; snap on the frame of a hit event

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/realtime-transport/prediction-reconciliation_test.ts` — must exist and pass. Plus manual evidence at `production/qa/evidence/realtime-transport-prediction-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (state_delta stream established), Story 003 (input handling)
- Unlocks: Story 008 (missed delta recovery)
