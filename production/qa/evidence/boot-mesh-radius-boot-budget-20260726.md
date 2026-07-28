# Boot-Scoped Mesh Radius — Boot Budget Evidence (Story vox-021, TD ruling Addendum D / D2)

**Date**: 2026-07-26
**Story**: `production/epics/voxel-world/story-021-boot-scoped-mesh-radius-and-view-radius-retune.md`
**Ruling**: `production/architecture-decisions-m02-preflight-2026-07-26.md`, Addendum D / D2
**QA gate**: this story's own AC-BOOT-BUDGET-3S / AC-EXTENT-EVIDENCE (Advisory)
**Tool**: `neues-spiel/tools/vox021_boot_budget_measurement.gd` / `.tscn` — a NEW tool, built per the
story's own instruction to reuse vox-018/vox-019's **methodology** verbatim (real production
classes, WINDOWED, self-quit, printed stats + raw log + PNG evidence, `Time.get_ticks_usec()`
deltas around real calls). It does **not** reuse vox-018's own tool file directly, because that
tool populates terrain via `VoxelWorldGrid.generate_terrain()` — a full-world eager precompute
that vox-018's own class doc comment already measured as severely super-linear above ~900×900
cells (did not complete in 200s+ at 1000×1000), and which `Valley.gd`'s own doc comment confirms
production boot never calls at all ("no `generate_terrain()` call anywhere in the boot chain").
This tool instead reuses `tools/vox016_residency_tuning_measurement.gd`'s own established
precedent — the real ADR-0015 residency tier (`update_residency` + `wait_for_async_residency_idle`,
bounded by the WINDOW, not world size) — which is why it can run at the shipped 2000×2000 config
directly, with no scaling caveat.
**Engine**: Godot 4.7.stable.official.5b4e0cb0f, D3D12 backend (Forward+)
**Hardware**: AMD Ryzen 9 5900X (12-core), AMD Radeon RX 7900 XT, 32 GB RAM, Windows 11 Pro — same
dev machine as vox-018/vox-019, same "not a verified mid-range baseline" caveat carried forward
**Launch command**: `C:/Users/Leo/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe --path F:/Neues_Spiel/neues-spiel res://tools/vox021_boot_budget_measurement.tscn`
(WINDOWED, not `--headless`)
**VSync**: explicitly **DISABLED** (`DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)`),
per this story's own mandated methodology. **Note, unlike vox-018/019's own FPS-sweep measurement**:
VSync governs per-frame PRESENTATION wait, not a synchronous, non-yielding method call — every
number below is a `Time.get_ticks_usec()` delta around a real synchronous call
(`update_residency`/`wait_for_async_residency_idle`/`build_initial_window`), never a per-frame
measurement, so VSync mode does not actually move these numbers. Disabled anyway for methodology
compliance, recorded honestly rather than silently assumed irrelevant.

---

## Honest phase-scope note (read this before the numbers)

The story's own AC-BOOT-BUDGET-3S names four phases: "residency page-in / nav-graph build /
initial mesh window / roster spawn." Verified against the CURRENT landed boot chain
(`src/scene_world_management/game_world.gd`, `src/scene_world_management/valley.gd`) before
measuring: `GameWorld`'s synchronous boot sequence (`_on_database_settled` →
`_setup_injected_tier` → `_build_initial_voxel_mesh_window` → `ACTIVE`) calls **neither**
`VillagerNavGraph.build()` **nor** `Valley.spawn_starting_roster()` — both are documented in
`valley.gd`'s own class doc comment as **deliberately deferred to a future world-generation
story**, since a fresh grid has no terrain at `_ready()` time. This story's own Out-of-Scope
section names `nav_region_size` as `scene-005`'s lever, not this one's.

**This measurement therefore covers the two phases that DO exist in the landed synchronous
boot chain and that this story's own knobs govern**: residency page-in (for the boot-radius
window) and the initial mesh window build (`boot_mesh_radius_chunks`). Nav-graph build and
roster spawn are recorded as **0 ms / not-yet-wired-into-boot**, named explicitly rather than
silently omitted or fabricated. If/when `scene-005` wires those phases into the synchronous boot
path, they become a `scene-005` measurement, not a re-opening of this one.

---

## Measured results

Two independent runs (the second re-run only to fix an evidence-screenshot camera setup bug —
see below; **both runs used the real, unmodified shipped config and the real production
classes**, no numbers were altered between them):

| Run | Residency page-in (625 chunks, `view_radius_chunks=12`) | Initial mesh window (289 chunks, `boot_mesh_radius_chunks=8`) | **Total boot** | Mesh-phase verdict (≤2500 ms) | Total verdict (≤3000 ms) |
|---|---|---|---|---|---|
| 1 | 112.5 ms | 2326.8 ms | **2439.4 ms** | PASS (173.2 ms / 6.9% headroom) | PASS (560.6 ms / 18.7% headroom) |
| 2 (final, screenshots attached) | 113.1 ms | 2405.3 ms | **2518.4 ms** | PASS (94.7 ms / 3.8% headroom) | PASS (481.6 ms / 16.1% headroom) |

**Verdict against the technical-director's ceiling (total ≤ 3.0 s, mesh phase ≤ 2.5 s): PASS on
both runs.**

**Honest finding, stated plainly (not glossed over)**: the D2 ruling's own text projected
*"~2.2 s — PASS with headroom"* for the mesh phase. The MEASURED mesh-phase cost (2.33–2.41 s
across two runs) is close to, but consistently **above**, that 2.2 s projection, and the
**headroom against the 2.5 s ceiling is thin and variable across runs (3.8–6.9%, not the
comfortable margin "PASS with headroom" implies)**. The projection was arithmetic
(`289 chunks × 7.7 ms/chunk ≈ 2.226 s`, vox-019's own measured per-chunk figure); the measured
number includes real per-call overhead (window-membership computation, `MeshInstance3D`
allocation/assignment, `visibility_range_end` writes) on top of the pure per-chunk mesh-build
cost, which the arithmetic-only projection did not itself account for. **The total-boot ceiling
has comfortable headroom (16–19%); the mesh-phase ceiling specifically does not.** This is
recorded as a risk, not remediated by retuning: per the story's own control manifest, the boot
radius is not to be shrunk unless the measurement actually MISSES, and it did not miss on either
run. If a future change adds even modest per-chunk overhead (e.g. a slightly heavier material
setup, or a world-edge/clipping change), this specific margin could tip to MISS — flagged for
whoever next touches `VoxelWorldMesher.build_chunk` or the mesh-streamer's per-item work, and for
`scene-005` when it re-points its own boot-budget AC at this story's ceiling.

**No named lever was applied** (`boot_mesh_radius_chunks` 8 → 6) — that lever is reserved for an
actual MISS per the story's own AC text ("On MISS: ... apply ONE named lever ... re-measure
once"), and both runs PASS. Recorded here for completeness: if a future run misses, the lever is
`boot_mesh_radius_chunks = 6` (13×13 = 169 chunks, ≈ 1.3 s projected), already implemented in this
tool's own fallback path (`FALLBACK_BOOT_RADIUS`), untriggered on both runs.

**Culling stays ENABLED throughout** — the mesher's production `visibility_range_end`/CW-winding
path is untouched by this story (vox-007/vox-019 guards re-confirmed green in the full suite run,
see below); no `CULL_DISABLED` fallback exists or was used.

---

## AC-EXTENT-EVIDENCE — the halved visible extent, on a picture

**384 → 192 world units, a halving** (`view_radius_chunks` 24 → 12; `12 × 16 × 1.0 = 192.0`,
`VoxelWorldMeshStreamer.compute_visibility_range_end(12) == 192.0`, asserted by test).

Two screenshots from the SAME session as run 2's numbers above (window grown from the boot
window to the full steady-state `view_radius_chunks=12` window AFTER the timed measurement,
explicitly NOT part of the timed boot phase — see the tool's own `_run_measurement`/`_ready`
comments):

- `vox-021-boot-radius12-topdown-20260726.png` — top-down context shot. The visible terrain
  patch reads as a **rounded, roughly-circular silhouette against the sky**, not a square — this
  is `visibility_range_end`'s own RADIAL distance culling from the camera (192 units) cutting the
  corner chunks of the underlying 25×25 SQUARE chunk grid, the most literal possible picture of
  "192 units, measured from wherever the camera is." Camera height/FOV were tuned (180 units,
  FOV 100°) specifically to stay inside that same 192-unit budget while still framing the whole
  patch — a naive camera height (vox-018's own 260-unit topdown convention, sized for the OLD
  384-unit fade) would have been culled to nothing but sky, which is exactly what a first attempt
  at this screenshot produced and is the reason this tool's camera setup differs from vox-018's.
- `vox-021-boot-radius12-oblique-20260726.png` — a lower, oblique "settlement camera distance"
  vantage (offset ≈158 units from focus, inside the 192-unit budget). At this radius the visible
  patch reads less like a settlement vista and more like a single rounded hill filling the frame
  — an honest consequence of the extent now being small enough that a modestly-elevated oblique
  camera sits close to, rather than clearly outside, the terrain's own footprint. This is the
  visual argument Open Decision #1 (below) is asking the user to weigh: at 192 units, a
  close-in oblique camera angle no longer reads as "a wide view of a valley," which is the
  concrete, seen consequence of the number, not merely stated.

---

## Test Results (this story's own full suite run)

Full regression suite (`tests/run-tests.cmd`) — **1076 test cases, 0 errors, 1 failure, 0 flaky,
0 orphans**. The one failure (`tests/unit/build_validation/room_verdict_test.gd`,
`test_flanked_diagonal_flanker_a_blocked_is_sealed`) is in a file this story never touches,
authored by a different concurrently-active agent working in `src/build_validation/` per this
story's own handoff note — confirmed unrelated to any file this story modified
(`src/voxel_world/`, `data/config/`, `tools/`, and this story's own new/edited test files). This
story's own scope, re-verified in isolation (`res://tests/integration/voxel_world` +
`res://tests/unit/voxel_world`): **208 test cases, 0 errors, 0 failures, 0 flaky, 0 orphans,
exit 0**, including the new `boot_mesh_radius_test.gd` (13 test functions) and the two edited
pre-existing tests in `live_view_window_wiring_test.gd` whose boot-window assumptions this
story's own radius split required updating (named below).
