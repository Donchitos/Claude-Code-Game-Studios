# Story 018: Live Valley view-window wiring + 60-FPS-with-culling measurement (milestone criterion #12)

> **Epic**: Voxel World / Grid Data
> **Status**: Not Started — milestone criterion #12's ONLY missing story (M01 review 2026-07-24, critical-path item 3)
> **Layer**: Presentation (mesher tier) + Integration (live Valley wiring)
> **Type**: Integration — with an Advisory-tier performance MEASUREMENT (real GPU, PNGs/log)
> **Estimate**: 2-3 days (+ unknown remediation risk — this is M01's one unretired unknown)
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-025` (rendering representation; draw calls decoupled from world size via the streamed view window)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*
**Milestone criterion**: **M01 #12 — "Performance: 60 FPS on the production window with culling RE-ENABLED"** (`production/milestones/milestone-01-foundation-core.md` Success Criteria + Quality Gates). The 60-FPS-with-culling target is an ADR-0014 / milestone / `technical-preferences` performance budget, not a dedicated TR — this story is the measurement that closes the criterion.

**ADR Governing Implementation**: ADR-0014 — primary (60 FPS on the production window, culling RE-ENABLED, draw calls decoupled via the streamed view window); ADR-0015 secondary (time-based per-frame streaming discipline the live loop inherits)
**ADR Decision Summary**: The chunked face-culled mesher renders the world through a *streamed view window*, so draw calls are bounded by the window (not world size) and stay within the ≤ 2000 budget. Faces wind CW with backface culling ENABLED (vox-007, TECH DEBT 1 retired). ADR-0014's performance gate is **60 FPS on the production window with culling re-enabled**; the slice held 60 FPS at 2× faces on `CULL_DISABLED`, so headroom is expected — but headroom expected is not headroom measured, and this criterion has never been measured on the live Valley loop.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: This is the **deferred integration** vox-015 explicitly scoped OUT (see `voxel_world_mesh_streamer.gd` class doc, `update_view_window` doc comment: *"Wiring this into Valley's live per-frame loop … is deliberately OUT of this story's scope … The 60 FPS-with-culling MEASUREMENT this story unlocks (milestone criterion #12) is explicitly a LATER story's job"* — this is that later story). vox-015 landed the streaming *machinery* (`VoxelWorldMeshStreamer` with `build_initial_window()` unbounded + `update_view_window()` budgeted) and proved it correct by its own tests; `VoxelWorldGrid.update_residency()` is likewise unwired in the live loop to date. Neither `villager-ai-025` (CPU/AI frame budget, PASS 3.02 ms) nor vox-015 (machinery) measured the *rendering/culling* 60-FPS target on the live Valley. **Headless GdUnit4 cannot render a viewport texture** — the measurement MUST run WINDOWED on a real GPU, using the standalone tool-scene precedent (`neues-spiel/tools/mesher_evidence.gd/.tscn`, `neues-spiel/tools/camera_sandbox.gd/.tscn`): a real `VoxelWorldGrid` + real `VoxelWorldMesher` + real `VoxelWorldMeshStreamer`, driven windowed, evidence written to `production/qa/evidence/`, NOT wired into the production boot chain.

**Control Manifest Rules (this layer)**:
- Required: `update_view_window()` called every frame from `Valley._process()` with the live `CameraInput` focus cell; `build_initial_window()` called once behind Scene/World Management's transition overlay; backface culling ENABLED (vox-007 material, unchanged); measurement on a real GPU over a production-scale window.
- Forbidden: reintroducing `CULL_DISABLED` to hit the number (that is the expired slice mitigation, not a fix); measuring headless and calling it a frame-rate result; silently accepting a miss (remediation stories, not silent acceptance).
- Guardrail: draw calls ≤ 2000; 60 FPS sustained on the mid-range PC target with culling ENABLED; no per-frame synchronous I/O or gen on the render thread (ADR-0015).

---

## Acceptance Criteria

- [ ] **Live wiring**: `VoxelWorldMeshStreamer` is a hosted child of `Valley`; `Valley._process(delta)` calls `update_view_window()` every frame with the current `CameraInput` focus cell, and `build_initial_window()` is called once at boot BEHIND Scene/World Management's transition overlay (not on a visible frozen frame). Streamer DI (`grid`, `mesher`) is code-wired in `Valley._wire_hosted_modules()`, mirroring the existing mesher/placement-pick precedent; `setup()` remains GameWorld-only (ADR-0005). [TR-voxel-world-025]
- [ ] **Draw calls bounded by the window**: with the streamer live, driving the camera across a world larger than the view window keeps meshed-chunk count and draw calls tracking the window, not world size; draw calls stay ≤ 2000. [TR-voxel-world-025]
- [ ] **Measurement captured (Advisory, real GPU)**: a windowed run over the production-scale view window with culling ENABLED captures FPS + frame-time (avg / p95 / max) + draw-call count, written to a dated evidence doc under `production/qa/evidence/` with at least one PNG and the raw log — methodology, hardware class, and engine build stated (mirroring `villager-ai-stress-evidence.md` / `chunked-mesher-cw-winding-culling-evidence.md`).
- [ ] **60-FPS verdict rendered honestly**: the evidence doc states PASS or MISS against ADR-0014's 60-FPS-with-culling target on the mid-range target. **If PASS**: criterion #12 closes, culling stays ENABLED, headroom recorded. **If MISS**: the doc records the shortfall and files named remediation stories (e.g. greedy meshing — ADR-0014's named optimization reserve — and/or `visibility_range_end` / budget re-tune), and criterion #12 stays OPEN pending them. No `CULL_DISABLED` fallback to manufacture the number.

---

## Implementation Notes

*Derived from ADR-0014 (60-FPS gate, culling enabled, window-bounded draw calls) / ADR-0015 (time-based streaming budget) / vox-015 (the machinery this wires):*

- **Wire the streamer into Valley (the deferred integration).** Add `VoxelWorldMeshStreamer` as a hosted child of `Valley` alongside `VoxelWorldGrid`/`VoxelWorldMesher` (structural hosting only — Valley never calls `setup()`; see `valley.gd` class doc). Code-assign `streamer.grid = _voxel_world` and `streamer.mesher = _voxel_world_mesher` inside `_wire_hosted_modules()` (the same code-wired cross-sibling precedent that method already sets), and append it to `get_injected_tier_modules()` in DI order so GameWorld's `_setup_injected_tier()` owns its `setup()`. Its config Resource is Inspector-wired on `Valley.tscn` mirroring the existing children.
- **Boot: `build_initial_window()` behind the transition overlay.** Call the UNBOUNDED initial build once during the boot/transition sequence, before the overlay lifts (ADR-0005/ADR-0015 boot-timing; vox-015 AC-3). The ~2.6 s initial build at 2000×2000×32 must not land on a visible frozen frame.
- **Live loop: `update_view_window()` every frame.** From `Valley._process(delta)`, read the current focus cell from the hosted `CameraInput` (its world-ray/focus API, `cam-006`) and pass it to the budgeted `update_view_window()`. The per-frame time budgets (`VoxelWorldConfig.mesh_build_budget_ms` / `mesh_unload_budget_ms`) bound builds and unloads separately, staggered — no burst (the prototype's single 133 ms hitch was an unload burst). This is a *wiring* change; add no new gameplay features.
- **Measurement tool (windowed, real GPU).** Build a standalone tool scene on the `mesher_evidence`/`camera_sandbox` precedent: real `VoxelWorldGrid` + real `VoxelWorldMesher` + real `VoxelWorldMeshStreamer`, a production-scale seeded extent, culling ENABLED, camera swept across the window; sample `Engine.get_frames_per_second()`, frame time via `Time.get_ticks_usec()` deltas (avg/p95/max), and draw calls via `RenderingServer.get_rendering_info(RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)` (verify the exact 4.7 enum against `docs/engine-reference/godot/` — rendering is the top flagged knowledge-gap domain). Run WINDOWED (`--path neues-spiel res://tools/…tscn`, NOT `--headless`). Capture PNGs + raw log to `production/qa/evidence/`. NOT in the boot chain.
- **Honest fallback.** If the number misses on the mid-range target: record it, keep culling ENABLED, and file the remediation as named stories — ADR-0014 names *greedy meshing* as the built-when-measurement-demands-it optimization reserve; `visibility_range_end` tightening and build/unload budget re-tune are the other levers. Criterion #12 stays OPEN until remediation lands and re-measures. Do NOT flip back to `CULL_DISABLED`.

---

## Out of Scope

- vox-015: the streaming machinery itself (build/unload budgets, `_sync_window`) — landed; this story only wires and measures it.
- vox-007: the chunk mesh geometry (CW winding, culling material) — landed.
- vox-010–014: the data residency tier. `VoxelWorldGrid.update_residency()` live-loop wiring is a separate seam; this story wires the *mesh* window. (If a shared per-frame focus-drive call site is the natural home for both, note it — but residency wiring/measurement is not a criterion-#12 deliverable.)
- Greedy meshing / any optimization remediation — filed as follow-up stories only IF the measurement misses (this story files them, does not build them).
- Multi-villager or world-generation changes — none; wiring only.

---

## QA Test Cases

- **AC-1 (live wiring — integration)**: [TR-voxel-world-025]
  - Setup: instantiate Valley (or GameWorld) headless; drive `_process` with a moving `CameraInput` focus
  - Verify: `update_view_window()` is invoked each frame with the focus cell; `build_initial_window()` invoked once at boot; streamer DI (`grid`/`mesher`) non-null; `setup()` reached only via GameWorld's injected-tier path
  - Pass condition: meshed-chunk membership tracks the focus as it moves; no exception; `setup()` not double-called
- **AC-2 (window-bounded draw calls — integration)**: [TR-voxel-world-025]
  - Setup: a world larger than the view window; sweep the focus across it
  - Verify: meshed-chunk count and draw calls track the window, not world size
  - Pass condition: distant chunks unload, entering chunks build; draw calls stay ≤ 2000
- **AC-3 (60-FPS measurement — Advisory, real GPU, WINDOWED)**:
  - Setup: the standalone windowed tool scene; production-scale seeded extent; culling ENABLED; camera swept across the window
  - Verify: FPS, frame-time avg/p95/max, and draw-call count sampled over the sweep; PNGs + raw log captured
  - Pass condition: evidence doc exists under `production/qa/evidence/` with methodology + hardware class + engine build; renders a PASS/MISS verdict vs the 60-FPS-with-culling target; on MISS, names remediation stories

---

## Test Evidence

**Story Type**: Integration (wiring — BLOCKING) + Performance measurement (Advisory)
**Required evidence**:
- Integration (BLOCKING): `tests/integration/voxel_world/live_view_window_wiring_test.gd` OR documented playtest — the Valley `_process` → `update_view_window` wiring + window-bounded draw-call assertion (AC-1/AC-2) — must exist and pass
- Performance (Advisory, non-blocking): a dated evidence doc under `production/qa/evidence/` (e.g. `voxel-world-60fps-culling-evidence.md`) with FPS / frame-time / draw-call numbers, ≥1 PNG, raw log, real-GPU hardware class, engine build, and the PASS/MISS verdict (mirrors `villager-ai-stress-evidence.md` — advisory, never joins the BLOCKING gate; recorded for the criterion-#12 close)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **vox-015** (mesh view-window streaming machinery — LANDED, S6), **scene-004** (GameWorld/Valley assembly + hosted mesher/camera — LANDED, S6), vox-007 (CW winding + culling material — LANDED), `cam-006` (camera focus/world-ray API — LANDED); consumes the live `CameraInput` focus point
- Unlocks: **milestone criterion #12** (60 FPS on the production window, culling RE-ENABLED) — its close on PASS, or its named remediation stories on MISS
- Related seam (not a dependency): `VoxelWorldGrid.update_residency()` live-loop wiring (vox-010–014) shares the per-frame camera-focus drive concept but governs data pages, not meshes
