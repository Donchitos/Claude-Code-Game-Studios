# Story 026: Roof tool — Flat formation (MVP) + formation picker seam

> **Epic**: Building System
> **Status: Complete — Flat MVP (2026-07-25 — 893/893 suite green, parent-verified; Gable/Hip/Shed deferred per sprint scope)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-046`, `TR-building-system-082`, `TR-building-system-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: A valid commit creates blueprint cells grouped into a project; the roof tool drags a footprint and generates the chosen formation's cell set. Flat is MVP-sufficient; Gable/Hip/Shed are VS-tier.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: No post-cutoff APIs. Only Flat is built in M01 — do NOT build Gable/Hip/Shed algorithms (VS-tier; the roof shape spec lands at Vertical Slice detail).

**Control Manifest Rules (this layer — Core):**
- Required: deterministic Flat-formation cell set over the footprint; blueprint cells only; a formation is chosen before the drag.
- Forbidden: never write grid blocks on commit; do not implement the non-Flat roof algorithms in M01 (named VS-tier reserve).
- Guardrail: roof cell count bounded by `max_cells_per_command`.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC15: GIVEN the roof tool with the Flat formation and a 3×4 footprint drag, WHEN committed, THEN exactly 20 blueprint cells are created one plane above the footprint's highest picked surface (F5 Flat — testable now). [TR-082]
- [ ] AC15b [PROVISIONAL — shape spec at VS]: GIVEN the roof tool with Gable/Hip/Shed and a footprint drag, WHEN committed, THEN a deterministic non-zero cell set matching that formation is created, with the preview shown pre-commit (F5). [TR-007]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 6 + F5, TR-046/082/007:*

- The player picks a formation (Flat/Gable/Hip/Shed) and drags a footprint; commit generates the formation's cell set over it.
- **Flat is specified and built now**: `flat_roof_cell_count = (|dx| + 1) × (|dz| + 1)` — one cell thick on the plane above the footprint's highest picked surface (identical shape to F2, offset up one plane).
- Gable/Hip/Shed: implement the formation-picker seam and a per-formation cell-set interface, but leave the actual Gable/Hip/Shed geometry as a VS-tier stub (mark AC15b PROVISIONAL — the shape algorithm is game-designer/art-director's roof shape spec). Do NOT build those three algorithms in M01.
- Emit the Flat cell set to the commit pipeline (Story 021) as blueprint cells.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Gable/Hip/Shed shape algorithms — VS-tier (roof shape spec).
- Building UI's roof-formation picker widget — building-ui epic (this story exposes the formation seam).
- Story 021/022/023: pipeline, validity, rendering.

---

## QA Test Cases

**AC15 — Flat formation cell count**
- Given: the roof tool, Flat formation, a 3×4 footprint drag.
- When: committed.
- Then: exactly 20 blueprint cells, one plane above the footprint's highest picked surface.
- Edge cases: a 1×1 footprint yields 1 cell; a footprint exceeding the cap is rejected (Story 022).

**AC15b — non-Flat (PROVISIONAL)**
- Given: Gable/Hip/Shed selected.
- When: committed.
- Then: (once the VS shape spec lands) a deterministic non-zero formation cell set with a pre-commit preview. Marked PROVISIONAL — not a blocking M01 test.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/roof_tool_test.gd` — Flat path must exist and pass; non-Flat PROVISIONAL.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 021 (commit pipeline), Story 020 (pick/plane), Story 022 (validity + cap).
- Unlocks: the roof verb (Flat MVP); Building UI formation picker.
