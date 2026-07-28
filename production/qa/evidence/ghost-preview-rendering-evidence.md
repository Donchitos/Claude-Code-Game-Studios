# Evidence: Story building-023 — Ghost Preview Rendering + Drag Re-rasterization + Degradation + State Tint

**Story**: `production/epics/building-system/story-023-ghost-preview-rendering.md`
**Date**: 2026-07-26
**Engine**: Godot 4.7.stable.official.5b4e0cb0f (local install, `C:/Users/Leo/Downloads/Godot_v4.7-stable_win64.exe/`)
**Evidence type**: Visual/Feel — ADVISORY (screenshots + automated logic tests). Lead sign-off is a separate pass, not part of this document.

**Implementation**: `neues-spiel/src/building_system/ghost_preview.gd`,
`neues-spiel/src/building_system/ghost_preview_config.gd`,
`neues-spiel/data/config/ghost_preview_config.tres`.

**Automated coverage**: `tests/unit/building_system/ghost_preview_test.gd` (29 tests)
+ one new regression test in `tests/unit/building_system/dda_placement_pick_test.gd`
(`test_input_release_cell_matches_locked_plane_after_a_mid_drag_cursor_move`). Full
suite: 1175 test cases, 0 errors, 0 failures, 0 orphans, exit 0
(`tests/run-tests.cmd`, 2026-07-26).

**Capture tool**: `tools/ghost_preview_evidence.gd` / `.tscn` (windowed, real GPU —
D3D12 / AMD Radeon RX 7900 XT), mirrors `tools/mesher_evidence.gd`'s established
pattern: real `VoxelWorldGrid`/`VoxelWorldMesher`/`ToolStateMachine`/`PlacementPick`/
`CommitPipeline`/`GhostPreview`, driven via `resolve_pick`'s explicit-ray parameter.

---

## AC1 — ghost follows the pick each frame [TR-building-system-026]

**Verify**: a ghost preview appears the instant a tool is armed with a valid pick, and
re-rasterizes as the cursor moves; hidden at Idle/Suspended.

**Automated**: `test_hidden_at_idle`, `test_hidden_while_armed_with_no_valid_pick_yet`,
`test_visible_once_a_valid_pick_resolves_while_armed`, `test_hidden_on_cancel`,
`test_hidden_on_suspended`, `test_shows_immediately_on_rearm_without_a_new_pick_changed_event`,
`test_recomputes_cells_when_pick_changes_during_hover`,
`test_dragging_uses_frozen_press_cell_and_live_release_cell`.

**Screenshot**: `building-023-ghost-preview-valid-blue-20260726-1.png` — a single
translucent blue box sits flush on the terrain surface at the picked cell.

**Pass condition met.**

---

## TR-093 — colorblind-safe blue (valid) / orange (invalid) axis

**Verify**: valid = cool blue translucent ghost, invalid = orange tint, never
red-green.

**Automated**: `test_valid_candidate_tints_state_blue`,
`test_invalid_candidate_tints_state_orange`,
`test_state_blue_and_state_orange_are_never_red_or_green`.

**Screenshots**: `building-023-ghost-preview-valid-blue-20260726-1.png` (State Blue
`#4A90C4` @ alpha 0.5, logged `(0.290, 0.565, 0.769, 0.5)`) and
`building-023-ghost-preview-invalid-orange-20260726-1.png` (nothing selected, State
Orange `#E1752E` @ alpha 0.5, logged `(0.882, 0.459, 0.180, 0.5)`) — same cell shape,
unmistakably different hue, neither red nor green.

**Pass condition met.**

---

## AC50 — degrades to an outline above `preview_degradation_threshold` [TR-building-system-035/039]

**Verify**: a drag whose pending cell count exceeds the threshold (128 default)
renders as an outline/bounding representation, never per-cell ghosts; the eventual
commit stays cell-exact (this story renders only — `CommitPipeline`'s own validity
gate and cell-set formulas are unchanged).

**Automated**: `test_stays_per_cell_at_exactly_the_threshold`,
`test_degrades_to_outline_above_the_threshold`,
`test_outline_never_lands_a_frame_budget_hitch_via_pool_growth`,
`test_compute_bounds_pure_function`, `test_wireframe_unit_cube_mesh_has_12_edges_24_vertices`.

**Screenshot**: `building-023-ghost-preview-degraded-outline-20260726-1.png` — a
148-cell candidate set (threshold 128 + 20) renders as a single wireframe bounding box
spanning the whole footprint, zero per-cell ghosts (`per_cell_count=0`, logged).

**Pass condition met.**

---

## TR-069 — Planned vs UnderConstruction visually distinct

**Verify**: a persisted Planned blueprint cell reads as a static translucent ghost;
UnderConstruction reads distinctly (this story renders the distinct STATE only —
Story building-029's tick-driven progress fraction is out of scope here).

**Automated**: `test_persistent_ghost_created_at_planned_alpha_on_commit`,
`test_persistent_ghost_switches_to_under_construction_alpha`,
`test_persistent_ghost_pruned_once_built`.

**Screenshot**: `building-023-ghost-preview-planned-vs-under-construction-20260726-1.png`
— two committed cells side by side, left Planned (`draft_ghost_alpha=0.5`, logged),
right UnderConstruction (`queued_ghost_alpha=0.7`, logged) — the right box reads
visibly more solid/opaque than the left at a glance.

**Pass condition met** (subtle at this placeholder neutral-white/no-lighting-variation
scale — expected until real material art lands; the alpha-tier distinction itself is
the story's committed mechanism, per `design/gdd/building-system.md` Tuning Knobs, and
is unambiguous in the numeric log).

---

## Deviation flagged — deferred art-bible material-tint upgrade

`design/art/art-bible.md` §7.1 (2026-07-23, user-confirmed) commits the long-term
direction as material-tinted ghosts (valid = a tint of the actual material being
placed, invalid = State Orange). This story implements the State-Blue-valid /
State-Orange-invalid axis instead, matching `TR-building-system-093`'s currently
registered text verbatim, this story's own embedded Control Manifest excerpt, and
`PlacementPick`'s own pre-existing doc comment (which already named "Story 023" as
owning "the valid/invalid blue-orange ghost axis" before this story was implemented).
No color-resolution utility from a `CommitPipeline`-selected item id to a real
material color exists anywhere in this codebase yet (even the terrain mesher's own
block coloring is an explicitly-labeled `DEBUG_BLOCK_COLORS` placeholder pending a
future atlas story) — implementing true material tint now would mean inventing that
resolution machinery ahead of its own story. Flagged here, not silently decided:
`ghost_preview.gd`'s own class doc comment records the same rationale and names the
follow-on (extend tint resolution once RID color/texture resolution lands, without
restructuring the pooling/degradation mechanism).

---

## Bug found and fixed during this story — pre-existing Dragging release-cell offset

While building this story's live-preview re-rasterization test
(`test_dragging_uses_frozen_press_cell_and_live_release_cell`), a real per-frame pick
update mid-drag surfaced a pre-existing bug in `PlacementPick._input()` (Story
building-021, already landed): the release handler read `get_attach_cell()`, which
unconditionally adds a face-normal offset appropriate only for a fresh raycast hit —
but while Dragging, the locked-plane-derived pick's cell is ALREADY the attach-
equivalent surface cell (fixed `(0,1,0)` normal convention, not a real face normal),
so the offset was applied twice, silently shifting every REAL (frame-elapsed) drag's
release one cell too high. No pre-existing test caught this because every prior test
either exercised a same-frame click (no intervening pick update before release) or
supplied press/release cells directly into `CommitPipeline`, bypassing this code path
entirely. Fixed in `placement_pick.gd`'s `_input()` (reads `_current_pick.cell`
directly) and in this story's own `ghost_preview.gd` (same fix in the Dragging
branch). Regression test added:
`dda_placement_pick_test.gd::test_input_release_cell_matches_locked_plane_after_a_mid_drag_cursor_move`.
Full suite re-run green after the fix (1175 cases, 0 errors, 0 failures, 0 orphans).

---

## Sign-off

**Lead**: (awaiting review — evidence prepared for that pass, not yet countersigned)
