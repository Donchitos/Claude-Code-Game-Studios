# Story 008: Furniture footprint field + boot validation

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-27 — 1391/1391 suite green 0 orphans, agent-verified; AC31a documented as structurally unreachable)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-052`, `TR-resource-item-database-053`, `TR-resource-item-database-054`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (Data Definition Immutability & Reference Format, slice propagation) — primary
**ADR Decision Summary**: Multi-cell furniture adds a `footprint` field (Vector2i `width_cells` × `depth_cells`, both ≥ 1) to the definition; the two-type authoring/view split absorbs it structurally. `furniture_fixture` requires an explicit `footprint`; every other category must omit it (implicitly `(1,1)`). It is consumed immediately at MVP (the `bed` needs it now) — NOT an Alpha-deferred field.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `footprint` is a typed `Vector2i` `@export` on `ItemDefinitionResource`. No special engine risk; the field states only the fact of the span (Building System owns placement/collision/rotation; Art Bible §8.5 owns the single multi-cell model asset).

**Control Manifest Rules (this layer)**:
- Required: multi-cell furniture adds a `footprint` field (e.g. bed = 2 cells); the two-type split absorbs it structurally — added when the RID story lands (ADR-0006 slice propagation).
- Required: category↔footprint pairing enforced at boot — `furniture_fixture` requires an explicit `footprint` with both dims ≥ 1; every other category must omit it.

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] A `furniture_fixture` entry with a valid `footprint` (both dims ≥ 1) is accepted and `footprint` is queryable exactly as authored (GDD AC30). [TR-resource-item-database-052]
- [ ] A `furniture_fixture` entry missing `footprint` (31a) or with a non-positive dimension (31b) halts boot naming the entry AND the violated dimension — both sub-cases (GDD AC31). [TR-resource-item-database-054]
- [ ] A non-`furniture_fixture` entry (e.g. `building_material`) with an authored `footprint` halts boot naming the entry — category↔footprint pairing (GDD AC32). [TR-resource-item-database-053]

---

## Implementation Notes

*Derived from ADR-0006 (slice propagation) Implementation Guidelines:*

- Add `@export var footprint: Vector2i` to `ItemDefinitionResource` (Story 001 already reserved the slot structurally) and a getter on the `ItemDefinition` wrapper.
- Add two validation checks to the Story 004 pipeline: (a) `furniture_fixture` requires `footprint` present with both dims ≥ 1 — a missing field or a `≤ 0` dimension halts, naming the entry and the offending dimension; (b) any non-`furniture_fixture` entry with an authored `footprint` halts (pairing). Non-furniture entries are implicitly `(1,1)` and never carry the field.
- `footprint` is consumed at MVP (placement + ghost preview), so it cannot be silently defaulted — unlike the Alpha-deferred fields.
- The `bed = (1, 2)` content value is authored in Story 009 (content), not here — this story owns the field + validation.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- Story 001: the definition schema/wrapper the field attaches to.
- Story 004: the base validation pipeline these two checks extend.
- Story 009: authoring the `bed` entry's `(1,2)` value.
- Building System epic: how `footprint` is consumed for placement, collision, rotation, rendering (this GDD states only the fact of the span).

---

## QA Test Cases

- **AC-1 (valid footprint)**: Given a `furniture_fixture` with `footprint = (1,2)`; When booting; Then accepted and a query returns `(1,2)` exactly.
- **AC-2 (missing / non-positive)**: Given a `furniture_fixture` missing `footprint` (31a); When booting; Then halt naming the entry. Given `footprint = (0,2)` or `(1,-1)` (31b); When booting; Then halt naming the entry and the invalid dimension.
- **AC-3 (pairing)**: Given a `building_material` with an authored `footprint`; When booting; Then halt naming the entry.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/resource_item_database/footprint_validation_test.gd` (GdUnit4) — asserts on the structured result; synthetic fixtures; must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (schema/wrapper) + Story 004 (validation pipeline) — both DONE.
- Unlocks: Story 009 (bed content authoring uses this field + validation).
