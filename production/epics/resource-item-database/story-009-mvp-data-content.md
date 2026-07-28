# Story 009: MVP data content (tier-0 set + bed) + content smoke checks

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-27 — 1418/1418 suite green 0 orphans, parent-verified; three-condition green proven, AC29 palette legibility deferred as advisory)
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-031`, `TR-resource-item-database-032`, `TR-resource-item-database-052`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary (one `.tres` `ItemDefinitionResource` per entry); ADR-0006 — secondary (typed `Mesh` `visual_asset`, `footprint`)
**ADR Decision Summary**: One `.tres` `ItemDefinitionResource` file per entry. The MVP content set is exactly the three tier-0 building materials (`wood_block`, `stone_block`, `thatch_block`, one per material family) plus the `furniture_fixture` `bed` with `footprint = (1, 2)`.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Each entry is an authored `.tres` with a typed `Mesh` `visual_asset` (`[ext_resource]` binding). The tier-0 materials must match the Visual Direction Note colours (wood = warm brown, stone = cool grey, thatch = warm red-brown). The magenta `missing_item` placeholder material is an art asset to produce.

**Control Manifest Rules (this layer)**:
- Required: gameplay values are data-driven external `.tres`, never hardcoded (ADR-0002); every field is authored external data.
- Required: tier-0 set contains ≥ 1 entry per material family (boot-enforced by Story 005).

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] The MVP data set ships exactly `wood_block`, `stone_block`, `thatch_block` at tier 0 (one per family) + the `bed` `furniture_fixture`; querying all tier-0 building materials returns exactly those three (GDD AC14). [TR-resource-item-database-031]
- [ ] Querying by category `building_material` (13a) and `furniture_fixture` (13b) each returns exactly its own authored ids with no cross-category leakage; list-all returns every authored id once with `missing_item` never appearing (GDD AC13, AC16). [TR-resource-item-database-032]
- [ ] The `bed` entry's `footprint` returns exactly `(1, 2)` — the slice-validated, user-locked value (GDD AC33). [TR-resource-item-database-052]
- [ ] Each of the three tier-0 materials is identifiable in the Building UI material picker without reading a tooltip — screenshot + lead sign-off, per the Visual Direction Note material↔meaning language (GDD AC29, Advisory). *(Visual/Feel advisory — evidence only, non-blocking.)*

---

## Implementation Notes

*Derived from ADR-0002 / ADR-0006 Implementation Guidelines:*

- Author one `.tres` `ItemDefinitionResource` per entry: the three tier-0 materials (family `wood`/`stone`/`thatch`, tier 0, no `footprint`) and `bed` (`furniture_fixture`, family `none`, `footprint = (1,2)`, tier 0).
- Populate ALL required fields including the four Alpha-deferred ones (`stackable`, `max_stack_size`, `haulable`, `storage_category`) — boot validation enforces presence.
- Bind a typed `Mesh` `visual_asset` per entry; colours per the Visual Direction Note. Coordinate the magenta `missing_item` placeholder material with the art pipeline (used by Story 007).
- This is content, not code — the query/validation logic it exercises is already covered by Stories 003–008; this story proves the SHIPPED data is correct.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 003–008: the query + validation code this content runs against.
- Building System / Building UI epics: the palette/picker UI that renders these (AC29's picker is a Milestone 02 Presentation surface — the advisory screenshot uses the minimal interaction UI).
- Doors/windows and the ~6 VS furniture types (Vertical Slice, not MVP).

---

## QA Test Cases

*Config/Data — content smoke check against shipped data (`production/qa/smoke-*.md`).*

- **Smoke-1 (tier-0 set)**: list tier-0 building materials → exactly `wood_block`, `stone_block`, `thatch_block`.
- **Smoke-2 (category isolation)**: list `building_material` → the 3 materials only; list `furniture_fixture` → `bed` only; no cross-leakage; list-all → all 4, `missing_item` absent.
- **Smoke-3 (bed footprint)**: `get_by_id("bed").footprint` → `(1, 2)`.
- **Smoke-4 (all fields present)**: each entry has all 11 fields populated; boot reaches Ready (green validation path).
- **Manual (AC29, advisory)**: Setup — open the material picker with the shipped tier-0 set. Verify — each material is visually distinct per wood/stone/thatch colour language. Pass condition — a first-time viewer identifies each without its tooltip; screenshot + lead sign-off.

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`) covering Smoke-1..4. AC29 advisory: `production/qa/evidence/rid-tier0-palette-evidence.md` (screenshot + lead sign-off) — non-blocking.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (schema), Story 004 + Story 008 (validation incl. footprint), Story 005 (tier-0 coverage enforcement), Story 003 (lookup API), Story 007 (missing_item exclusion) — all DONE.
- Unlocks: None (closes the RID MVP content; Building System consumes it).
