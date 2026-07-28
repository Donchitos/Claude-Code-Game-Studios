# Story 013: Nudge-aside vacate (F4 target selection)

> **Epic**: Villager AI & Behavior
> **Status**: Complete (2026-07-27 — 1488/1488 suite green, 0 orphans, parent-verified on a clean single run)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-056`, `TR-villager-ai-behavior-079`, `TR-villager-ai-behavior-034`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (Deterministic Movement & Occupancy Ordering)
**ADR Decision Summary**: F4 targeting reads the discrete `current_cell`; the occupant steps AWAY from the requester (never toward). Deterministic — the same situation always produces the same step. The vacate is a normal walking step (never a teleport); the builder's target cell stays deferred until it clears.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: F4 axis convention pinned: N = −z, E = +x, S = +z, W = −x; tie-break by fixed N/E/S/W scan order for determinism.

**Control Manifest Rules (this layer)**:
- Required (Core): F4 nudge-aside targeting reads `current_cell` (never `_visual_position`); deterministic.
- Forbidden: teleporting the occupant; stepping the occupant toward the requester; nudging another villager off a claimed job; interrupting a Working/Sleeping occupant.
- Guardrail: pure deterministic selection over adjacent standable cells.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] `vacate_target = argmin(height_difference), then argMAX(Chebyshev distance to requester)` over standable cells orthogonally adjacent to the occupant; tie-break by fixed N/E/S/W scan order.
- [ ] Given an idle occupant in a builder's target cell, the vacate request steps it to the F4 target; given a Working/Sleeping occupant, it is NOT interrupted and the cell stays deferred (AC34).
- [ ] Given an occupant with at least one strictly-farther and one strictly-closer standable adjacent cell relative to the requester, the chosen cell strictly INCREASES Chebyshev distance to the requester — never decreases (AC50, guards the corrected inversion).
- [ ] Given a vacate-target tie on height difference and distance, the fixed N/E/S/W scan order breaks it identically every run (AC35).
- [ ] A builder requesting a vacate on a cell occupied by a villager mid-work on its own claimed job → deferred; the occupant's claim is never revoked (AC42). If no adjacent standable cell exists, the vacate fails and the builder's cell stays deferred.
- [ ] The vacate is a normal walking step at `move_speed` (F1 interpolation) — no timing promise tied to tick length (AC34 step semantics).

---

## Implementation Notes

*Derived from ADR-0009 (F4) Implementation Guidelines:*

- Direction: the occupant steps away from the requesting builder (the diametrically opposite cell uniquely wins in standard orthogonal geometry).
- Only idle/wandering occupants vacate within the step; mid-activity (Working/Sleeping) occupants are never interrupted — the builder's cell stays deferred until free.
- Never nudge another builder off a claimed job.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: the deferred-then-resumed construction progress after the cell clears.

---

## QA Test Cases

- **AC34**: idle occupant → steps to F4 target within one tick; Working/Sleeping occupant → not interrupted, cell deferred.
- **AC50**: Given a closer and a farther standable adjacent cell, When vacating, Then the chosen cell strictly increases Chebyshev distance to the requester.
- **AC35**: Given a full tie on height + distance, Then N/E/S/W scan order breaks it identically across two runs.
- **AC42**: builder requests vacate on a mid-work occupant's claimed cell → deferred, occupant's claim never revoked.
- Edge cases: no adjacent standable cell → vacate fails, cell deferred.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/villager_ai/nudge_aside_f4_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 004 (discrete current_cell), 006 (occupant state awareness)
- Unlocks: 012 (deferred-resume relies on the vacate)
