# Story 019: Wandering & idle micro-behaviors (F3)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-27 — 1437/1437 suite green 0 orphans, parent-verified; unblocks presentation-001 Sub-B)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-078`, `TR-villager-ai-behavior-016`, `TR-villager-ai-behavior-059`, `TR-villager-ai-behavior-060`, `TR-villager-ai-behavior-067`, `TR-villager-ai-behavior-087`, `TR-villager-ai-behavior-089`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (FSM Wandering state) — primary; ADR-0007 (walkability/flood-fill)
**ADR Decision Summary**: Wander target = a uniformly chosen cell from a bounded flood-fill of standable, reachable cells within `wander_radius`, re-picked every `wander_interval`. Flood-fill guarantees reachability by construction (no island targets). The random source is injected (DI) — production uses live RNG, tests inject a fixed sequence for determinism.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Flood-fill calls the shared `is_standable` predicate (Story 002). Determinism via injected RNG — no global seeds.

**Control Manifest Rules (this layer)**:
- Required (Feature): flood-fill over shared predicates; injected RNG (DI per coding standards).
- Forbidden: unbounded goal-directed pathfind for bed-drift (drift is bounded by F3's set — never path outside it); a duplicate walkability rule; global RNG seeding.
- Guardrail: bounded flood-fill within `wander_radius`; aggregate cost included in the perf spike scope.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] Given no jobs and no urgent needs, the villager wanders indefinitely without error (AC3, Edge Case 12 — varied idling reads as "waiting for a home").
- [ ] Any wander target is reachable by construction — never an island cell (AC28, flood-fill).
- [ ] Wander targets over time all lie within `wander_radius` and world bounds; a cell exactly at `wander_radius` is included, one beyond is excluded — inclusive boundary, deterministic (AC29, AC45).
- [ ] Given an injected fixed-sequence random source, wandering runs twice from the same state produce identical paths (AC30, F3 determinism).
- [ ] Given a flood-fill returning only the current cell, the villager stays in place without error and re-attempts at the next `wander_interval` (AC31, Edge Case 8).
- [ ] Micro-behaviors vary among walk / pause-and-look / sit / drift-toward-owned-bed's-area; bed-drift target is the flood-fill cell nearest the bed WITHIN `wander_radius` (if the bed is beyond the radius, drift to the radius edge — never path outside F3's bounded set). Selection uses the same injected RNG.

---

## Implementation Notes

*Derived from ADR-0008/0007 (F3) Implementation Guidelines:*

- `wander_target` = uniform pick from the bounded flood-fill of standable reachable cells within `wander_radius`; re-pick every `wander_interval`.
- Bed-drift is bounded: nearest flood-fill cell to the bed within the radius, or the radius edge — never an uncounted goal-directed pathfind.
- Inject the RNG through the same interface F3 uses; tests supply a fixed sequence.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 020: the Breather beat (a distinct between-jobs rest, not wandering).
- Story 015/022: walled-in distress and watchdog scope.

---

## QA Test Cases

- **AC28/AC29/AC45**: targets reachable by construction; within `wander_radius` + bounds; inclusive boundary (at-radius included, one-beyond excluded).
- **AC30**: injected fixed-sequence RNG → identical wander paths across two runs.
- **AC31**: flood-fill returns only current cell → stay in place, no error, re-attempt next interval.
- Edge cases: bed-drift bounded to F3's set (bed beyond radius → drift to radius edge).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/villager_ai/wandering_f3_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 007 (graph/reachability), 006 (idle fall-through)
- Unlocks: None
