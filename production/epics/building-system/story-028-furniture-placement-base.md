# Story 028: Furniture placement base — single-cell support + palette query

> **Epic**: Building System
> **Status: Complete (2026-07-27 — 1241/1241 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-048`, `TR-building-system-074`, `TR-building-system-059`, `TR-building-system-050`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0006 (Data Definition Immutability & Reference Format) — secondary
**ADR Decision Summary**: Furniture is placed from the RID `furniture_fixture` category (MVP: `bed`); it requires support (the cell below occupied) and occupies its cells like blocks. Tier-0 materials + bed are free (no resource consumed).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Palette queried via the RID getter-only `ItemDefinition` (opaque string ids, no setters). No post-cutoff APIs.

**Control Manifest Rules (this layer — Core / Foundation data query):**
- Required: furniture entries queried from RID (`furniture_fixture`, tier-0 rule); furniture requires support (cell below occupied — ground or built floor); furniture occupies its cells one-occupant-per-cell.
- Forbidden: never resolve RID definitions internally beyond opaque ids; MVP placement consumes no resource (tier-0 free).
- Guardrail: support/availability checks are O(cells) per commit.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC16: GIVEN the furniture tool with `bed` selected, WHEN targeting a cell with empty support below, THEN the commit is invalid; WHEN targeting a supported cell, THEN it is valid (Core Rule 8). [TR-048]
- [ ] AC18: GIVEN the MVP data set, WHEN the palette is queried, THEN exactly the tier-0 materials and `bed` are offered (Core Rule 9). [TR-074]
- [ ] AC19: GIVEN any MVP commit or completed construction, WHEN it occurs, THEN no resource is consumed (Core Rule 14). [TR-059]
- [ ] AC49: GIVEN the furniture tool, WHEN a bed blueprint targets a cell supported by a *blueprint* floor cell, THEN the commit is valid but the bed's construction cannot start until the support cell is Built. [TR-050]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 8 + Rule 14, TR-048/074/059/050:*

- Query the palette from the Resource & Item Database: `building_material` + `furniture_fixture` (tier-0 rule); MVP furniture list = `bed` only.
- Support requirement: the cell(s) below the furniture must be occupied (ground or built floor). A blueprint floor cell counts as support for a furniture *blueprint* (you can plan a bed on a planned floor), but the furniture cell's construction may only start once its support cell is Built (feeds Story 029/030).
- Furniture occupies its cell(s) like blocks (one cell = one occupant).
- MVP cost rule: tier-0 materials and the MVP bed are free — no resource consumed by placement or construction.
- This story is SINGLE-cell furniture support/placement base. The multi-cell footprint (bed = 1×2, one entity spanning cells) is the slice story 016, which extends this.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 016: multi-cell footprint placement (one entity across cells).
- Story 017: furniture demolition.
- Story 022: the generic validity gate (this story supplies the furniture-support predicate).

---

## QA Test Cases

**AC16 — support requirement**
- Given: the furniture tool with `bed`.
- When: targeting a cell with empty support below vs a supported cell.
- Then: empty-support → invalid; supported → valid.

**AC18 — palette contents**
- Given: the MVP data set.
- When: the palette is queried.
- Then: exactly tier-0 materials + `bed` are offered.

**AC19 — no resource consumed**
- Given: any MVP furniture commit or completed construction.
- When: it occurs.
- Then: no resource is consumed.

**AC49 — blueprint-floor support defers construction**
- Given: a bed blueprint on a blueprint floor cell.
- When: committed.
- Then: valid, but the bed's construction cannot start until the support floor cell is Built.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/furniture_placement_base_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 021 (commit pipeline), Story 022 (validity gate), Resource & Item Database (palette).
- Unlocks: Story 016 (multi-cell footprint extends this), construction of furniture (Story 029).
