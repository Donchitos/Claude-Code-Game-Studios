# Story 009: Terrain dig-order removal write path (1..5 family eligibility)

> **Epic**: Voxel World / Grid Data
> **Status**: Ready
> **Layer**: Core (write path)
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-051`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 (Voxel World write path) — primary; ADR-0016 secondary; ADR-0015 (load-before-write for far-world dig targets) referenced
**ADR Decision Summary**: Only terrain-band/sand values (the 1..5 value family, EXCLUDING water and trunk/leaves) may be removed via a released dig order executed by a villager. Removal goes through the SAME batched write API as every other removal (no special dig-order API surface) and emits the standard change signal so consumers (Build Validation & Navigability) observe the `cells_removed` change.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Slice-validated second exception to terrain permanence (Core Rule 8). Eligibility is a value-family check, not an API branch.

**Control Manifest Rules (this layer)**:
- Required: dig removal routes through the single batched write path; emits the standard change signal; a far-world dig target pages in first (load-before-write, Story 014).
- Forbidden: removing water/trunk/leaves via a dig order; a special dig-order API surface.
- Guardrail: the same signal path Build Validation already listens on — no blind spot for room/shelter re-analysis.

---

## Acceptance Criteria

- [ ] A released dig order targeting a cell in the terrain-band/sand "1..5 family" makes the cell empty via the standard batched write API, and the standard change signal fires (observable as a `cells_removed`-class event) (AC22). [TR-voxel-world-051]
- [ ] A released dig order targeting a water, trunk, or leaves cell is NOT eligible for removal via a dig order (AC23). [TR-voxel-world-051]

---

## Implementation Notes

*Derived from ADR-0014 / ADR-0016:*

- Add an eligibility predicate: a cell is dig-removable iff its value ∈ the terrain-band/sand family (informally 1..5), explicitly EXCLUDING water and trunk/leaves values. Keep the family definition data-driven (config), not hardcoded literals.
- On an eligible released dig order, apply the removal through the batched write path (Story 003) so downstream consumers observe the standard change signal like any other removal. Villager AI triggers this via the Building System's order-execution path — Voxel World only owns the data exchange + signal.
- If the dig target cell is in a non-resident chunk, it must page in first (load-before-write, Story 014) — do not apply blind.

---

## Out of Scope

- Building System's dig-order lifecycle and villager execution (later epic).
- Build Validation & Navigability's room/shelter re-analysis (later epic) — this story only guarantees the signal fires.

---

## QA Test Cases

- **AC-1 (eligible removal + signal)**: [TR-voxel-world-051]
  - Given: a cell holding a terrain-band value (e.g. 3)
  - When: an eligible dig removal is applied
  - Then: the cell becomes empty via the batched write path; the standard change signal fires carrying the removed cell
  - Edge cases: removing the last cell of a column; a dig target already empty
- **AC-2 (ineligible values rejected)**: [TR-voxel-world-051]
  - Given: cells holding water, trunk, and leaves values
  - When: dig eligibility is evaluated
  - Then: each is reported ineligible; no removal occurs
  - Edge cases: a value at the exact family boundary (5 eligible; the first non-family value ineligible)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/voxel_world/terrain_dig_order_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (batched write); relies on Story 014 (load-before-write) when the dig target is non-resident
- Unlocks: Building System dig orders + Villager AI order execution (later epics)
