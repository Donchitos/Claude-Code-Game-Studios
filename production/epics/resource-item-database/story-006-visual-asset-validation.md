# Story 006: visual_asset resolution validation (typed Mesh, two failure shapes)

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-27 — 1467/1467 suite green 0 orphans, parent-verified)
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-023`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (Data Definition Immutability & Reference Format) — primary
**ADR Decision Summary**: `visual_asset` is a typed `Mesh` reference (`@export var visual_asset: Mesh`), never a path string. Boot validation must check the entry resource itself loaded successfully BEFORE checking the `visual_asset != null` field — distinct diagnostics, both terminal.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: A missing/broken `[ext_resource]` makes the entry `.tres` fail to load entirely — a different failure shape than a loaded `.tres` with a null `visual_asset`. Resource-null check ORDER matters (resource-load check first).

**Control Manifest Rules (this layer)**:
- Required: `visual_asset` is a typed `Mesh` reference, never a path string; boot validation does the resource-null check BEFORE the `visual_asset != null` check, with distinct diagnostics, both terminal (ADR-0006).

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] An entry whose `visual_asset` does not resolve halts boot naming the entry, distinguishing two failure shapes (GDD AC22): [TR-resource-item-database-023]
  - (a) the entry's backing `.tres` fails to load entirely (missing/broken `[ext_resource]`) → reported as "entry failed to load";
  - (b) the `.tres` loads but its `visual_asset` field is null → reported as "visual_asset unresolved".

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

- In the boot load/validation pipeline, check the entry resource loaded successfully FIRST (a null/failed load → "entry failed to load" diagnostic), THEN check `visual_asset != null` (→ "visual_asset unresolved"). The order prevents mislabeling a broken `.tres` as a null-field error.
- `visual_asset` is a typed `Mesh` — do not treat it as a path string or attempt a filesystem existence check.
- Both shapes are terminal (feed the same structured result / Failed state from Story 005).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004/005: the other schema/invariant checks and the terminal-halt machinery this feeds.
- Story 009: authoring the actual tier-0 / bed meshes (content).

---

## QA Test Cases

- **AC-1 (broken .tres)**: Given an entry `.tres` with a missing `[ext_resource]`; When booting; Then halt with the "entry failed to load" diagnostic naming the entry.
- **AC-2 (null visual_asset)**: Given an entry `.tres` that loads but has `visual_asset = null`; When booting; Then halt with the "visual_asset unresolved" diagnostic naming the entry.
- **AC-3 (order)**: Given a broken-load entry; When validated; Then it is reported as "entry failed to load", NOT "visual_asset unresolved".

---

## Test Evidence

**Story Type**: Config/Data (validation of a data reference; asserts on the structured result)
**Required evidence**: neues-spiel/`tests/unit/resource_item_database/visual_asset_validation_test.gd` (GdUnit4) — synthetic broken-load and null-field fixtures; asserts distinct structured-result diagnostics. Must pass. (Classified with the validation-logic suite; a smoke check against shipped data lands in Story 009.)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (validation pipeline + structured result must be DONE).
- Unlocks: None directly (feeds Story 009 content smoke).
