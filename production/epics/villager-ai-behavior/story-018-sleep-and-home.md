# Story 018: Sleep & home — bed claim (move-in moment)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-27 — 1241/1241 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-061`, `TR-villager-ai-behavior-062`, `TR-villager-ai-behavior-063`, `TR-villager-ai-behavior-084`, `TR-villager-ai-behavior-085`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (FSM Sleeping state) — primary; ADR-0012 (serialize bed ownership, VS-tier)
**ADR Decision Summary**: Beds have owners (first-claim permanent, one bed = one owner). Claiming a bed IS the move-in moment. Sleep recovery is reported to Needs & Mood via `start_recovery`/`stop_recovery` with a source enum; Needs values are mocked at boundaries per testing standards.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Needs & Mood is a Milestone-02 system; its decay/recovery rates and thresholds are MOCKED here at the "need is urgent / wake threshold" boundary — these ACs do NOT wait for that GDD. Bed removal uses the Building System's furniture-revocation event (symmetric to job revocation).

**Control Manifest Rules (this layer)**:
- Required (Feature): bed ownership is villager-AI state; reuse the atomic-claim primitive (Story 011) for bed contention. Recovery reporting via discrete `start_recovery(need, source_enum)` / `stop_recovery(need, reason)` calls.
- Forbidden: interpolation-derived occupancy for bed reachability (read `current_cell`).
- Guardrail: one bed = one owner; ownership dissolves on removal.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [x] Given a first urgent sleep need and an unowned reachable bed, the villager claims that bed permanently — the move-in moment (AC22).
- [x] Given an owned reachable bed and urgent sleep, the villager sleeps in its own bed (AC23); given an owned reachable bed AND a closer unowned free bed, it goes to its OWNED bed — never the closer one (AC44).
- [x] Given no reachable bed and urgent sleep, the villager sleeps on the ground at its current cell and reports the correct ground source enum — `ground_no_bed_owned` if it owns no bed, `ground_bed_unreachable` if it owns one it cannot reach (AC24; rates mocked).
- [x] Given the sleep need restored above the wake threshold (mocked), the villager wakes and re-enters Deciding (AC25).
- [x] Given a bed removed while the villager sleeps in it, it wakes immediately and ownership dissolves (AC26, Edge Case 5, via the furniture-revocation event).
- [x] Given an owned but unoccupied bed removed, ownership dissolves and a new bed is claimed at the next urgent sleep (AC27, Edge Case 6).

---

## Implementation Notes

*Derived from ADR-0008/0012 Implementation Guidelines:*

- Bed claiming reuses the atomic-claim primitive (Story 011) so simultaneous same-bed contention resolves by stable order (AC43 lives in Story 011).
- Ground-sleep fallback reports the widened source enum; the ground_* distinction feeds the why-string, not the rates.
- Bed-removal-while-sleeping: on the furniture-revocation event, wake immediately, dissolve ownership, `stop_recovery` (credits zero recovery for the removal tick), re-enter Deciding.
- Mock Needs & Mood at the urgency/wake boundary; do not depend on the M02 GDD's real values.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: the atomic bed-claim contention primitive (AC43).
- Needs & Mood decay/recovery rates (Milestone-02 system — mocked here).

---

## QA Test Cases

- **AC22/AC23/AC44**: first urgent sleep + unowned reachable bed → permanent claim; owned reachable bed → own bed; owned + closer unowned → own bed preferred.
- **AC24**: no reachable bed → ground sleep at current cell with the correct `ground_no_bed_owned` / `ground_bed_unreachable` source enum (rates mocked).
- **AC25**: wake threshold reached (mocked) → wake + re-enter Deciding.
- **AC26/AC27**: bed removed while sleeping → wake immediately + ownership dissolves; owned unoccupied bed removed → ownership dissolves silently, re-claim at next urgent sleep.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/villager_ai/sleep_and_home_test.gd` — must exist and pass (mocked Needs & Mood + Building furniture-revocation).

**Status**: [x] Created, 10/10 passing (`neues-spiel/tests/integration/villager_ai/sleep_and_home_test.gd`)

---

## Dependencies

- Depends on: 006 (priority loop), 009 (travel to bed), 011 (atomic-claim primitive for bed contention)
- Unlocks: 024 (save/load serializes bed ownership)
