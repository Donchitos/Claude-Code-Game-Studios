# Story 003: Context panel & the RID-driven material/furniture palette

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (zone Z5, element E4, P9/P10/P15)
**Requirement**: `TR-building-ui-045`, `TR-building-ui-008`, `TR-building-ui-046`, `TR-building-ui-067`, `TR-building-ui-042`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (Data Definition Immutability & Reference Format) — the palette's data contract; ADR-0005 (Boot Gate) — when the palette may populate
**ADR Decision Summary**: Cross-system references to an item are **opaque `StringName` ids only** — never a held `ItemDefinition`/`ItemDefinitionResource` reference. `get_by_id(id) -> ItemDefinition` returns a fresh getter-only wrapper per call; `visual_asset` is a typed `Mesh`, never a path string. The RID is Autoload-tier, called by global singleton name directly (`ResourceItemDatabase.list_ids_by_tier(0)`), never injected. The palette may not populate before `GameWorld` reaches `ACTIVE`.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: `ResourceItemDatabase` carries **no `class_name`** by design (Godot 4.7 hard-errors when a `class_name` shadows an Autoload of the same name) — reach it exclusively via the registered Autoload global name. Landed query surface: `list_ids_by_category(category)`, `list_ids_by_material_family(family)`, `list_ids_by_tier(tier)`, `list_all_ids()`, `get_by_id(id)`.

**Control Manifest Rules (this layer)**:
- Required (Presentation): the palette shows **exactly** what the database offers — icon from `visual_asset`, tooltip from `display_name`, tier-0 rule for placement tools, `furniture_fixture` for the Furniture tool. The last selection **per tool** is remembered within the session.
- Forbidden: holding an `ItemDefinition`/`ItemDefinitionResource` reference across frames; a UI-side fallback for a broken entry; any palette content authored in the UI rather than queried.
- Guardrail: per-tool material memory is one of Rule 2's three sanctioned UI-local memories — session-scoped, never serialized, never read by another system.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 4/5 + Edge Cases 2/3, scoped to this story:*

- [ ] **AC4**: Given Wall armed → the panel shows palette + stepper; Roof armed → palette + 4 formation icons; Furniture armed → the furniture list (`bed` only); Block/Floor armed → palette; **Idle → no panel at all** (`TR-building-ui-045`).
- [ ] **AC5**: Given the mocked MVP dataset, When the palette renders, Then exactly the **tier-0** materials appear for placement tools and exactly `bed` for Furniture (`TR-building-ui-008`).
- [ ] Palette entries take their icon from the item's typed `visual_asset` `Mesh` and their tooltip from `display_name`; the UI holds only the `StringName` id (ADR-0006).
- [ ] **AC6**: Given a material selected for tool A, When switching to B and back, Then A's last selection is restored — session-scoped, per tool (`TR-building-ui-046`).
- [ ] Selecting a palette entry routes the id into Building System's selection call (`CommitPipeline.set_selected_item(id)`) and the highlighted entry mirrors `get_selected_item()` — never a UI-local latch.
- [ ] **AC (Edge Case 2, panel half)**: Given rapid tool switching, Then Z5 swaps content instantly with last-input-wins — no flicker of a stale panel, no orphaned selection highlight (`TR-building-ui-067`, hud.md E4 "instant swap").
- [ ] **AC (Edge Case 3)**: The palette can never show a broken entry — the item database fails at boot on a missing `visual_asset` (its own AC22), and the reserved `missing_item` is never palette-eligible. **No UI fallback path is implemented**; verify the absence, do not add a guard.
- [ ] An **empty** palette or furniture list renders an explicit empty state, never a broken or half-drawn panel (hud.md E4, `TR-resource-item-database-044`).
- [ ] Z5 never exceeds the toolbar's width envelope and stays docked directly above Z6 (hud.md Layout rules).
- [ ] **AC34**: Given a placement tool armed, When `palette_next`/`palette_prev` fire, Then the selection cycles through exactly the palette's entries, identically to clicking them (`TR-building-ui-059`).
- [ ] The panel populates only after the boot gate reports `ACTIVE`; a pre-boot render shows the empty state rather than querying a not-yet-ready database (ADR-0005).

---

## Implementation Notes

*Derived from ADR-0006's public query surface and the landed RID:*

- Build the placement palette from `ResourceItemDatabase.list_ids_by_tier(0)` intersected with the `building_material` category, and the furniture list from `list_ids_by_category(&"furniture_fixture")`. Do **not** hand-author either list.
- Call `get_by_id(id)` at render time for `display_name`/`visual_asset` and discard the wrapper — it is a fresh lightweight `RefCounted` per call by design (ADR-0006), so re-querying is the sanctioned pattern, not a cost to optimize around.
- The per-tool memory is a `Dictionary[StringName tool_id, StringName item_id]`. On tool arm, restore the remembered id by calling `set_selected_item()`; if the remembered id is no longer palette-eligible, fall back to the first entry.
- **Known Conflict 3 applies**: `WallTool`/`FloorTool`/`RoofTool`/`BlockTool` are `Node`s that exist in `src/building_system/` but are hosted in **no scene** and have no `Valley` getter, and `CommitPipeline` is hosted but its cell-set resolver is still the placeholder `_default_cell_set`. Resolve the hosting question (technical-director) before wiring; until then, drive the ACs against a mocked tool-selection surface.
- `mouse_filter` on the panel container must consume clicks so no world pick falls through (P2) — but must **not** be a naive whole-zone `STOP` that swallows an in-progress drag's release; that case is story 007's, resolved by ADR-0010 §3. Coordinate, don't duplicate.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the wall-height stepper and the roof-formation picker's *behavior* (this story only reserves and shows their slots per AC4).
- Story 007: hover suppression and drag-release routing.
- Story 009: ghost tinting from the selected material.
- Story 018: icon art, the grayscale pass, and tooltip localization checks.

---

## QA Test Cases

- **AC4**: Given each armed tool in turn (mocked), Then the panel's visible child set matches the Rule 4 table exactly; Given Idle, Then the panel is hidden.
- **AC5**: Given a mocked RID with tier-0 and tier-1 entries plus one `furniture_fixture`, When a placement tool arms, Then only tier-0 ids render; When Furniture arms, Then only `bed` renders.
- **AC6**: Given Wall→select `stone`, Floor→select `wood`, Wall again, Then the highlighted entry is `stone` and `set_selected_item(&"stone")` was called.
- **AC34**: Given 4 palette entries and index 0 selected, When `palette_next` fires 5 times, Then the selection is index 0 again — cycling, identical to clicking each in turn.
- **AC (Edge Case 2)**: Given a 20-event tool-switch spam sequence, Then after every event the panel's content matches the current tool and no stale child remains in the tree.
- **Empty state**: Given a mocked RID returning zero tier-0 ids, Then the explicit empty state renders and no error is pushed.
- **ADR-0006 guard**: Given the UI module source, When grepped, Then zero stored `ItemDefinition`/`ItemDefinitionResource` members.

---

## Test Evidence

**Story Type**: Integration (multi-system: RID + Building System + HUD) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/context_panel_palette_test.gd` — must exist and pass.
**Also**: `production/qa/evidence/building-ui-003-context-panel-walkthrough.md` (ADVISORY) — one screenshot per panel variant.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001, 002; **Known Conflict 3** (tool hosting) must be resolved first.
- Unlocks: 004, 009.
