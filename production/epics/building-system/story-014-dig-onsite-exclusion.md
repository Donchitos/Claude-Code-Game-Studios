# Story 014: Dig-job on-site exclusion

> **Epic**: Building System
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-122`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0009 (Deterministic Movement & Occupancy Ordering) — secondary
**ADR Decision Summary**: Occupancy/seal semantics read the discrete `current_cell`/body-column; the dig job amends the "on site" set so a villager may only stand on an orthogonal neighbour of the dug cell, never the cell itself (slice-validated anti-trap fix).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (Integration seam with Villager AI on-site eligibility; ADR-0016 knowledge risk LOW)
**Engine Notes**: On-site eligibility is evaluated against the discrete `current_cell` (ADR-0009), never `_visual_position`. The on-site set for a normal build job is defined by TR-building-system-056 (target cell or orthogonally adjacent).

**Control Manifest Rules (this layer — Core)**:
- Required: for a dig job the target cell itself is EXCLUDED from the on-site set — a villager may stand only on an orthogonal neighbour of the cell it is excavating; occupancy reads the discrete `current_cell`/body-column.
- Forbidden: never let a villager count as on-site while standing on the dig target (the unamended rule let a villager dig the block under its own feet and become trapped).
- Guardrail: the amendment is a set-membership check, O(1) per eligibility evaluation.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC72 [PROVISIONAL — Villager AI]: GIVEN a released dig cell, WHEN a villager's on-site eligibility is evaluated, THEN standing on the target cell itself never counts as on-site — only an orthogonal neighbor cell does (Rule 14m's amendment to TR-building-system-056, Edge Case 20). [TR-122]
- [ ] Edge 20: a dig job's target cell directly beneath a villager's current standing cell never counts as on-site — the villager must stand on an orthogonal neighbor. [TR-122]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Rule 14m on-site amendment, TR-122:*

- The standard "on site" set (TR-building-system-056) is the target cell OR an orthogonally adjacent cell (including directly below/above). For a **dig job specifically**, amend it: EXCLUDE the target cell itself from the on-site set — a villager may stand only on an orthogonal neighbour of the cell it is excavating, never on the cell itself.
- This exists because the unamended rule let a villager dig the block directly under its own feet and become trapped (slice-validated fix).
- Building System owns the on-site set definition for dig jobs; the actual on-site check and job-claim selection are Villager AI's — mark the villager-side selection PROVISIONAL, and unit-test the on-site set definition here (a pure predicate: `dig_on_site(target, standing_cell)` excludes `standing_cell == target`).
- Occupancy reads the discrete `current_cell`/body-column per ADR-0009.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 013: dig project creation + lifecycle (this story only amends on-site eligibility).
- Villager AI's job-claim selection that prefers a valid orthogonal neighbour — Villager AI's domain (integration).

---

## QA Test Cases

**AC72 / Edge 20 — dig on-site excludes the target cell**
- Given: a released dig cell and candidate standing cells.
- When: on-site eligibility is evaluated for the dig job.
- Then: `standing_cell == target` returns not-on-site; an orthogonal neighbour returns on-site.
- Edge cases: a villager standing directly on the dig target (target beneath its feet) is never on-site; diagonal-only neighbours are not orthogonal (per the orthogonal-only rule); the amendment applies ONLY to dig jobs — a normal build job still counts the target cell as on-site (TR-056 unchanged).

---

## Test Evidence

**Story Type**: Integration (on-site predicate unit-testable now; villager selection PROVISIONAL pending Villager AI)
**Required evidence**: `tests/integration/building_system/dig_onsite_exclusion_test.gd` (or a unit test of the on-site predicate).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 013 (dig projects). Coordinates with Villager AI on-site/claim logic.
- Unlocks: safe (non-self-trapping) mining execution.
