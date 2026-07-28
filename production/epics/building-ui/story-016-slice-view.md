# Story 016: Slice View — horizontal render cutoff & the "Ebene" indicator

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (Layout Zones — the indicator joins the toolbar zone group; P15 stepper pattern)
**Requirement**: `TR-building-ui-085`, `TR-building-ui-065`, `TR-building-ui-037`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 (Chunked Voxel Rendering & Large-World Storage) — the render path the cutoff must act on; ADR-0015 — residency, which the cutoff must not disturb
**ADR Decision Summary**: World geometry is a chunked face-culled mesher over packed chunk storage with a streamed view window; ghost previews are pooled `MeshInstance3D`s. A **presentation-only** cutoff must therefore act on the render layer without touching the data layer, the residency budget, or the streamer's window logic — simulation is unaffected by design.

**Engine**: Godot 4.7-stable | **Risk**: **HIGH — mechanism undecided**
**Engine Notes**: **⚑ Known Conflict 6.** Neither `VoxelWorldMesher` nor `VoxelWorldMeshStreamer` exposes a cutoff/clip parameter today, and chunks are **whole-column** `MeshInstance3D`s keyed by `Vector2i` — so a horizontal Y cutoff is either (a) a clip-plane uniform on `VoxelWorldMesher.get_shared_material()`'s shared `ShaderMaterial`, or (b) a per-chunk re-mesh at the cutoff height. **(a) is strongly preferred** (no re-mesh cost, no residency interaction), but it is an architecture choice — technical-director + godot-shader-specialist must decide **before this story starts**. Cross-check `docs/engine-reference/godot/` — 4.7 changed HDR output and material handling.

**Control Manifest Rules (this layer)**:
- Required (Presentation): the cutoff is **presentation-only** — cells above the level are hidden from render (world geometry, ghosts, and characters); **simulation is unaffected**.
- Forbidden: any effect on the data layer, on `VoxelWorldGrid` residency/paging, or on the streamer's view window; the cutoff altering an existing Selection or an armed tool.
- Guardrail: a cell hidden by the cutoff cannot become a **NEW** hover target or Selection target — simply because it is not there to click. Anything **already** selected or armed is unaffected.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rule 20 + Edge Case 18, scoped to this story:*

- [ ] **AC64**: Given any slice level, When `slice_up` / `slice_down` / `slice_reset` fire, Then the render cutoff changes by **exactly one cell** / resets to show-all, and the "Ebene" HUD indicator reflects the new level **the same frame** (`TR-building-ui-085`).
- [ ] Cells above the current level are hidden from render across **all three** categories: world geometry, ghosts/markers, and characters. *(The character clause is currently vacuous — villagers have no visual body; assert the hook exists and is exercised by a mocked renderable.)*
- [ ] Simulation is provably unaffected: with a slice level active, villager ticking, construction job completion and Build Validation analysis all produce identical results to the un-sliced run.
- [ ] The "Ebene" indicator has **+/− buttons mirroring the keys** — the same interaction pattern as the wall-height stepper (Rule 6 / P15) — and shows the current level at all times.
- [ ] Slice View is available in **BOTH** World Navigation and Build Mode — it is a camera/visibility aid, not a build-exclusive tool (Rule 20).
- [ ] **AC65**: Given a slice level hiding the villager or project that is the current Selection, Then the Selection state is **unchanged** (still queryable, panel highlight still shows) even though no world-space outline renders — it is UI state, not render state (Edge Case 18, `TR-building-ui-085`).
- [ ] A cell hidden by the cutoff cannot become a new hover target (Rule 17) or a new Selection target (Rule 15); an already-armed tool and an already-active drag are unaffected.
- [ ] **AC (bounds)**: `slice_up` at the world's top height is a no-op; `slice_down` below the world floor clamps; `slice_reset` always returns to show-all from any level.
- [ ] **AC22 (partial)**: Given the InputMap at boot, Then `slice_up`, `slice_down`, `slice_reset` exist as registered actions (`TR-building-ui-065`). *(Verified present in `project.godot` and `CameraInput.OWNED_ACTIONS` as of 2026-07-26.)*
- [ ] The `PageUp` / `PageDown` / `Home` defaults are retained pending only a `/ux-design` collision check against every other binding (GDD Open Question 13) — the **actions** are the commitment, not the keys.

---

## Implementation Notes

*Derived from Rule 20 and the landed render path:*

- **Decide the mechanism before writing code** (Known Conflict 6). If (a) clip-plane uniform: add one `float` uniform to the shared voxel shader, set it from the UI, and give the ghost/marker materials the same uniform so all three categories cut at the same plane — one value, three consumers, mirroring this epic's general shape. If (b) per-chunk re-mesh: it must not perturb `VoxelWorldMeshStreamer`'s budgeted build/unload loop or ADR-0015's residency timing, which is exactly why (a) is preferred.
- Keep the slice level in the **Building UI module**, not in Voxel World — it is presentation state and must not become something the data layer branches on. Voxel World receives a value; it does not own one.
- The "cannot become a NEW hover/Selection target" clause falls out for free if the pick predicate treats `cell.y > slice_level` as non-solid; add it as an exemption alongside story 008's `set_pick_exempt` seam rather than as a second check.
- The "simulation unaffected" AC is best proven by a **differential** test: run N ticks with and without a slice level and assert identical villager cell sequences and identical `construction_completed` payloads.
- The indicator reuses story 004's stepper interaction code path — extract the shared "clamped stepper with +/− buttons and two actions" control rather than writing a second one.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: the hover highlight and build grid themselves.
- Story 010: Selection semantics (this story only asserts they are untouched).
- Any change to residency, paging, or the streamer's view-window logic (ADR-0015).
- The `/ux-design` binding collision check (GDD Open Question 13).

---

## QA Test Cases

- **AC64**: Given level = show-all, When `slice_down` fires 3 times, Then the level is `top − 3` and the indicator string matches after each press.
- **Bounds**: Given level at the world floor, When `slice_down` fires, Then the level is unchanged; Given any level, When `slice_reset` fires, Then show-all.
- **Three categories**: Given a slice level with a world cell, a ghost cell and a mocked renderable character all above it, Then all three report not-rendered.
- **Simulation-unaffected (differential)**: Given identical seeds, run 200 ticks with and without a slice level, Then the villager `current_cell` sequences and the `construction_completed` payload sequences are identical.
- **AC65**: Given a selected project entirely above the cutoff, Then `get_selection()` is unchanged, the card highlight is still set, and the outline renders nothing.
- **New-target block**: Given a pick ray that would resolve to a cell above the cutoff, Then the pick is a miss and no hover highlight renders; Given a drag already in progress on a now-hidden plane, Then the drag completes normally.
- **Availability**: Given WorldNav, Then `slice_up` still works; Given Build Mode, likewise.

---

## Test Evidence

**Story Type**: Integration — the level state machine, pick exemption and simulation-unaffected differential are **BLOCKING**; the rendered cutoff appearance is **ADVISORY**.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/slice_view_test.gd` and `neues-spiel/tests/integration/ui/slice_view_simulation_unaffected_test.gd` — must exist and pass.
**Required evidence (advisory)**: `production/qa/evidence/building-ui-016-slice-view-screenshots.md` — a roofed interior at three cutoff levels.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 008 (pick predicate seam), 010 (Selection); **Known Conflict 6** — the cutoff mechanism decision (technical-director + godot-shader-specialist) must land first.
- Unlocks: —
