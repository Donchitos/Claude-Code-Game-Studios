# Story 016: Multi-cell furniture placement (footprint)

> **Epic**: Building System
> **Status: Complete (2026-07-27 — 1264/1264 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-124` (secondary: `TR-building-system-082`, `TR-building-system-048/050`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0006 (Data Definition Immutability & Reference Format) — secondary
**ADR Decision Summary**: Multi-cell furniture adds a `footprint` field to the item definition (bed = 2 cells); the two-type authoring/view split absorbs it structurally. Furniture occupies its footprint cells as ONE entity — each cell references the same occupant id, satisfying Voxel World's one-cell-one-occupant model.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW; ADR-0006 definition-field addition)
**Engine Notes**: `footprint` is authored on the `ItemDefinitionResource`, exposed via the getter-only `ItemDefinition` (no setters). Use typed `Array[Vector3i]` for offsets.

**Control Manifest Rules (this layer — Core / Foundation data-definition):**
- Required: footprint is a fixed list of cell offsets from the picked anchor; a commit is valid iff every offset cell independently satisfies support + availability; all footprint cells are written/read as ONE furniture entity (same occupant id); `furniture_cell_count` is per-item.
- Forbidden: no partial placement of a multi-cell item (Core Rule 8/9 apply to every footprint cell independently); never create N separate entities for one footprint.
- Guardrail: footprint validation is O(footprint size) per commit — trivially bounded.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC75: GIVEN the furniture tool with `bed` selected targeting an anchor cell whose 1×2 footprint is only partially supported or partially blocked, WHEN committed, THEN the entire commit is rejected — there is no partial placement of a multi-cell item (Rule 8, Edge Case 19). [TR-124]
- [ ] AC76: GIVEN a valid `bed` commit, WHEN it resolves, THEN exactly one furniture entity is created spanning both footprint cells, each cell referencing the same occupant id (F5, `furniture_cell_count = 2`). [TR-124]
- [ ] `furniture_cell_count = |footprint(item)|` — per-item, not always 1 (F5). [TR-124]

---

## Implementation Notes

*Derived from ADR-0016 + ADR-0006 (footprint field) + building-system Core Rule 8, F5, TR-124:*

- A furniture footprint is a fixed list of cell offsets from the picked anchor cell (authored on the item definition per ADR-0006's two-type split; MVP `bed` = 2 offsets → 1×2). Add the `footprint` field when consuming it here — coordinate with the RID definition story.
- A commit is valid iff **every** offset cell independently satisfies Core Rule 8's support requirement (the cell below occupied — ground or built floor; a blueprint floor supports a furniture blueprint but construction waits until the support is Built) AND Core Rule 9's availability check (in bounds, empty/replaceable, no existing blueprint/built occupant). No partial placement (Edge 19).
- All footprint cells are written/read as ONE furniture entity — Voxel World's "one cell = one occupant" is satisfied by every footprint cell referencing the same occupant id, not by N separate entities.
- `furniture_cell_count = |footprint(item)|` (per-item). This value feeds F3's build queue (each furniture cell is still a construction job, but the entity is atomic for placement).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 017: furniture demolition (atomic multi-cell teardown + revocation).
- The RID `furniture_fixture` palette/definition authoring (bed entry) — Resource & Item Database epic; this story consumes the `footprint` field.
- The generic furniture-tool pick/preview pipeline — pre-slice foundation (this story adds footprint multi-cell handling).

---

## QA Test Cases

**AC75 — no partial placement**
- Given: the furniture tool with `bed`, anchor whose 1×2 footprint has one cell unsupported OR one cell overlapping an existing blueprint/built cell.
- When: committed.
- Then: the ENTIRE commit is rejected (visible feedback), no cell placed.
- Edge cases: both cells supported + free → valid; one cell out of bounds → rejected; support-by-blueprint-floor is valid for the blueprint but construction waits for the floor to be Built.

**AC76 — one entity, shared occupant id**
- Given: a valid `bed` commit.
- When: resolved.
- Then: exactly one furniture entity spans both footprint cells; each cell references the same occupant id; `furniture_cell_count == 2`.
- Edge cases: a 1-cell item yields `furniture_cell_count == 1` (formula generalizes); querying either footprint cell resolves to the same entity.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/multi_cell_furniture_placement_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (cell/entity model). Coordinates with Resource & Item Database (`footprint` field, ADR-0006).
- Unlocks: Story 017 (furniture demolition atomicity).
