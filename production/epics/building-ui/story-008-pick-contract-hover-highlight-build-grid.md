# Story 008: Pick-solid contract, always-on hover highlight & build grid

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (world-space overlays row, 10b cursor states) · `design/art/art-bible.md` §7.1 (build-grid color family)
**Requirement**: `TR-building-ui-078`, `TR-building-ui-079`, `TR-building-ui-037`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (Physics Backend & Picking Strategy) — the pick mechanism; ADR-0014 §4 — the ghost-anchoring `extra_solid` overlay hook
**ADR Decision Summary**: Building System's placement pick is a **zero-physics manual DDA grid-walk** — no collider of any kind is involved, so the pick is structurally incapable of hitting a villager. ADR-0014 §4's `extra_solid` predicate is the sanctioned hook for treating non-grid cells (blueprint ghosts) as solid during that walk; it is forwarded **unchanged** into `VoxelWorldGrid.raycast_cells`, and Building System's pick adds no second path.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Landed `PlacementPick` already exposes `set_extra_solid(Callable)`, `resolve_pick(origin, dir)`, `get_current_pick() -> RaycastHitResult`, `get_attach_cell()`, `get_replace_cell()`, and a single pooled `MeshInstance3D` picked-block highlight (`is_highlight_visible()`, `get_highlight_world_position()`). That highlight is visible **only while ToolArmed/Dragging** today — Rule 17 requires it always-on, including WorldNav. The build grid should reuse ADR-0014's established "pooled `MeshInstance3D` + `material_override` tint" precedent rather than introducing a new draw path.

**Control Manifest Rules (this layer)**:
- Required (Presentation): the hover highlight and the build grid reuse the **same pick-ray data** any active tool preview or Selection query already consumes — one source of truth, several presentation consumers.
- Forbidden: a second pick path or a second ray; state colors rendering on committed world geometry (overlay only); the build grid rendering in World Navigation.
- Guardrail: a ray that resolves nothing after the exemptions behaves **exactly** as the existing no-pick case — hidden ghost, no-op commit.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 16/17 + Edge Case 15, scoped to this story:*

- [ ] **AC50**: Given a Planned or Released (not yet Built) blueprint ghost cell, When the pick ray targets its face, Then it resolves **exactly as picking solid geometry would** — this is what lets a roof tool target a drafted wall run (`TR-building-ui-078`).
- [ ] **AC51** *(gated — see Known Conflict 5)*: Given a dig-order marker cell, When the pick ray targets it, Then the ray passes **through** to whatever lies behind/beneath it — the dig-order cell is never the resolved pick target (Rule 16 exemption).
- [ ] **AC52** *(gated — see Known Conflict 5)*: Given a water cell, When the pick ray targets its surface, Then it never resolves as a solid pick target regardless of any overlaid marker/ghost state.
- [ ] **AC (Edge Case 15)**: Given a dig-order marker with no geometry behind it, Then the ray resolves as a **miss** — identical to the existing no-pick case (hidden ghost, no-op) (`TR-building-ui-078`).
- [ ] **AC53**: Given any valid pick resolution in **ANY** mode (WorldNav or Build Mode, tool armed or not), Then the target cell renders its **wireframe outline + hit-face quad** the same frame (Rule 17, always-on, `TR-building-ui-079`).
- [ ] **AC54**: Given Build Mode, Then the **build grid** — cell-edge lines on the picked working plane around the cursor — renders at `build_grid_opacity`; Given WorldNav, Then the build grid does **not** render (`TR-building-ui-079`).
- [ ] The build grid uses the Valley-Ochre family per Art Bible §7.1, and `build_grid_opacity` comes from `BuildingUiConfig` (default 0.30, range 0.15–0.45) — never a literal (`TR-building-ui-037`).
- [ ] The hit-face quad reflects **which face** was hit, derived from `RaycastHitResult`'s entry-face normal — not an approximation from the cell center.
- [ ] The highlight and grid are suppressed whenever `is_hover_suppressing_world_pick()` is true (story 007) and whenever the HUD is Suspended.
- [ ] **AC (cursor state, hud.md 10b)**: on a pick **miss**, the ghost is hidden and the cursor reflects the miss state (`TR-building-system-086`); during rotate-drag, the grab/orbit cursor shows (`TR-camera-input-045`).
- [ ] The overlay never writes into any committed-block material — grep proves zero `material_override` assignment on a chunk `MeshInstance3D` from the UI module.

---

## Implementation Notes

*Derived from ADR-0004/ADR-0014 §4 and the landed `PlacementPick`:*

- **AC50 is the achievable half today.** Wire a real `extra_solid` predicate over `CommitPipeline.has_blueprint_cell(cell)` (and, once `building-003` lands, the project registry's reverse index). `PlacementPick`'s own doc says exactly this is "a future story's job once that data model exists" — the model now exists for Planned cells, so this story closes that gap.
- **AC51/AC52 are blocked, not deferred silently.** There is **no dig-order cell class** (`build_project.gd` records that `BlueprintCell.MicroState` "does not yet model" the dig Removed state) and **no water cell type** in the grid. Write the exemption as a predicate seam — a `set_pick_exempt(Callable)` the DDA consults after `extra_solid` — and mark the two ACs blocked on Known Conflict 5 rather than inventing a cell class here.
- Rule 17 requires the highlight in **WorldNav too**. Landed `PlacementPick._apply_process_state_for()` disables `_process` outside ToolArmed/Dragging, and `_update_highlight()` hides the mesh accordingly. Extending "always-on" means changing when the pick runs, not adding a second pick — coordinate the change with building-system rather than duplicating `resolve_pick` in the UI.
- Build the grid as a single pooled `MeshInstance3D` with a line mesh regenerated only when the working-plane cell changes, not every frame.
- The working plane for the grid is the **attach** cell's height (the surface a drag would build ON), matching `PlacementPick`'s own `_locked_plane_cell_y` convention — not the picked block's own height.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: ghost/marker **presentation** (tint, alpha, invalid override, inflated boxes). This story renders the *hover* affordance only.
- Story 007: the hover-suppression flag itself.
- Story 016: the Slice View cutoff's interaction with hover targets (its Edge Case 18).
- `building-023` (ghost preview rendering) — a Cluster 0 Building System story this epic consumes.
- Creating a dig-order cell class or a water cell type — Known Conflict 5, building-system.

---

## QA Test Cases

- **AC50**: Given a mocked blueprint cell at (5,3,5) and a ray that would otherwise pass through, When `resolve_pick` runs with the wired `extra_solid`, Then the hit cell is (5,3,5) with the correct entry-face normal.
- **AC51/AC52 (once unblocked)**: Given a dig-order marker at (5,3,5) and solid terrain at (5,2,5), Then the resolved hit is (5,2,5); Given a water cell with a ghost overlay, Then the resolve is a miss.
- **Edge Case 15**: Given a dig-order marker with air behind and beneath, Then `get_current_pick().is_hit` is false and the ghost is hidden.
- **AC53**: Given WorldNav with no tool armed and a valid pick, Then `is_highlight_visible()` is true and the hit-face quad's normal matches the pick's.
- **AC54**: Given Build Mode, Then the grid node is visible with alpha == `config.build_grid_opacity`; Given WorldNav, Then the grid node is not visible.
- **Suppression**: Given `is_hover_suppressing_world_pick()` true, Then neither highlight nor grid is visible and `update_pick()` was not called.
- **Grep**: Given the UI module, When grepped, Then zero `material_override` writes targeting chunk meshes.

---

## Test Evidence

**Story Type**: Integration — pick-resolution and visibility-predicate logic is **BLOCKING** (headlessly assertable as properties, per `PlacementPick`'s established precedent); the rendered appearance is **ADVISORY**.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/pick_contract_and_hover_highlight_test.gd` — must exist and pass.
**Required evidence (advisory)**: `production/qa/evidence/building-ui-008-hover-and-grid-screenshots.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 007; `building-023` (ghost preview — Cluster 0); **Known Conflict 5** blocks AC51/AC52.
- Unlocks: 009, 016.
