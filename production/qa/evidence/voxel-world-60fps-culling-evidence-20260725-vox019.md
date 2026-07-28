# Voxel World 60-FPS-with-Culling Evidence — Story vox-019 (Milestone Criterion #12, Remediation #1 Re-measurement)

**Date**: 2026-07-25
**Story**: `production/epics/voxel-world/story-019-mesher-read-loop-optimization.md` (vox-018 MISS remediation #1: read-loop optimization + budget re-tune, folded with #2)
**Baseline being remediated**: `production/qa/evidence/voxel-world-60fps-culling-evidence-20260725.md` (vox-018, MISS: p95 51.536 ms, root cause ~40 ms/chunk `_build_chunk_arrays()` read loop)
**QA gate definition**: `production/qa/qa-plan-sprint-8-2026-07-25.md`, "THE MILESTONE-CENTERPIECE" section
**Tool**: `neues-spiel/tools/vox018_60fps_culling_measurement.gd` / `.tscn` — **re-used verbatim** except (a) 3 output-filename constants (`vox-018-...` → `vox-019-...`, same-date collision guard, see the tool's own doc comment), (b) a `MESH_BUILD_BUDGET_MS`/`DIAGNOSTIC_DISABLE_VSYNC` constant added for this story's own AC3/diagnostic needs (both default to the unchanged production value / `false`)
**Engine**: Godot 4.7.stable.official.5b4e0cb0f, D3D12 backend (Forward+)
**Hardware**: AMD Ryzen 9 5900X (12-core), AMD Radeon RX 7900 XT, 32 GB RAM, Windows 11 Pro — same high-end dev machine as vox-018, same "not a verified mid-range baseline" caveat carried forward
**Launch command**: `Godot_v4.7-stable_win64_console.exe --path neues-spiel res://tools/vox018_60fps_culling_measurement.tscn` (WINDOWED, not `--headless`)

---

## AC1 — Read-loop optimization: MEASURED before/after per-chunk cost

`VoxelWorldMesher._build_chunk_arrays()` was rewritten to consume `VoxelWorldGrid.get_chunk_snapshot()` — a new read-only bulk chunk accessor exposing the packed `_ChunkBuffer` arrays directly (`src/voxel_world/voxel_world_grid.gd`) — instead of ~8,448 per-cell `get_cell()` calls. The one remaining `get_cell()` call site is the chunk-border/world-edge minority (`VoxelWorldMesher._is_chunk_local_air`).

**Before/after, same tool, same config (896×896 world, `view_radius_chunks=24`, 961 chunks in the initial window), same `build_initial_window()` call this measurement times before any sampling begins**:

| | `generate_terrain()` | `build_initial_window()` | Per-chunk (961 chunks) |
|---|---|---|---|
| **Before** (vox-018, 2026-07-25, pre-vox-019) | 52,138 ms | 38,821 ms | **~40.4 ms/chunk** |
| **After** (vox-019, this story) | 53,830.5 ms | **7,395.9 ms** | **~7.7 ms/chunk** |

**~5.2x reduction in per-chunk mesh-build cost** — `generate_terrain()` is unaffected (expected: that method was never touched by this story, confirming the read-loop swap is what moved the number, not incidental noise). This is the profile-confirmed proof the read loop was the cost, per AC1's own directive to report which change actually moves the number.

## AC2 — Byte-identical output (regression-guarded)

`neues-spiel/tests/unit/voxel_world/mesher_bulk_read_equivalence_test.gd` (NEW, 6 tests) reconstructs the pre-optimization per-cell algorithm as a local test-only reference (`_legacy_build_chunk_arrays`, never a second production code path — "ONE mesher construction site" stays intact, confirmed by `mesher_material_contract_test.gd`'s own grep-guard) and asserts element-wise `==` equality of `ARRAY_VERTEX`/`ARRAY_NORMAL`/`ARRAY_COLOR`/`ARRAY_INDEX` against the real, optimized `_build_chunk_arrays()` on a 2-chunk fixture (mixed solid/air, terrain height variation, a deliberate interior air pocket, AND a chunk-border cell whose neighbor air-test crosses from chunk (0,0) into chunk (1,0) and back) — all PASS. `mesher_winding_derivation_test.gd` and `mesher_material_contract_test.gd` (incl. the `CULL_DISABLED` grep-guard) re-run green, unchanged.

## AC3 — `mesh_build_budget_ms` re-tune

**Empirically tested** (not assumed) at 2.0 ms, 4.0 ms (unchanged default), and 8.0 ms, all at `view_radius_chunks=24`:

| Budget | avg | p95 | max |
|---|---|---|---|
| 2.0 ms | 16.672 ms | 17.017 ms | 42.473 ms |
| **4.0 ms (kept)** | **16.671 ms** | **16.947 ms** | **41.669 ms** |
| 8.0 ms | 16.672 ms | 19.490 ms | 43.487 ms |

Avg is invariant across all three (confirms the per-frame cost is dominated by the budget's own progress-guarantee — the first item in any batch always integrates regardless of the budget value, as long as it stays below the real per-chunk cost, true both before and after this story's read-loop fix). 8.0 ms measured **worse** on p95/max (a larger budget occasionally lets a second real chunk stack into the same frame). **Decision: kept at the spike-validated 4.0 ms default** — recorded in `data/config/voxel_world_config.tres` (`mesh_build_budget_ms = 4.0`, explicit rather than relying on the class default) and in `VoxelWorldConfig.mesh_build_budget_ms`'s own doc comment, citing this measurement. `VoxelWorldConfig.validate()` returns no clamp for `4.0` (inside `[0.1, 1000.0]`).

## AC4/AC5 — Re-measurement, fallback ladder, and the VSync finding

**Run 1 — official methodology, unchanged from vox-018** (`view_radius_chunks=24`, `mesh_build_budget_ms=4.0`, engine default VSync — this project's `project.godot` sets no `display/window/vsync/vsync_mode` override, so the engine default `VSYNC_ENABLED` applies, exactly as it did, unexamined, in vox-018):

| Statistic | Value | Budget | Result |
|---|---|---|---|
| Frame time avg | 16.671 ms | — | — |
| **Frame time p95 (gating statistic)** | **16.947 ms** | ≤ 16.6 ms | **MISS by 0.347 ms (~2.1%)** |
| Frame time max | 41.669 ms | — | — |
| Draw calls, max | 709 | ≤ 2000 | PASS |
| Samples over 2000 ceiling | 0 / 5,399 | 0 | PASS |

A razor-thin miss — avg (16.671 ms) is itself barely over 16.6 ms. Per AC5's fallback ladder, `view_radius_chunks` was tightened once (24 → 20, 729 vs. 961 chunks) and re-measured: **p95 17.022 ms — still MISS, and not meaningfully different from the untightened 24 result** (16.947 ms). This was the anomaly that triggered the investigation below, rather than a second escalation step.

**The finding**: avg frame time is **flatlined at 16.671–16.672 ms across every configuration tested** — 3 different budget values AND 2 different view radii, a >4x range of mesh-build workload. A real compute-bound cost could not behave this way; a **VSync presentation-wait floor** could. `1000/60 = 16.667 ms` — almost exactly the observed flatlined average. This project's `project.godot` sets no VSync override, so Godot 4.7's engine default (`VSYNC_ENABLED`) applies; on this machine's 60 Hz display, the compositor/swapchain blocks each frame until the next vblank, making **every** frame's wall-clock time (`Time.get_ticks_usec()` deltas, exactly what this tool measures, per its own methodology) land at ≈16.667 ms **regardless of how cheap the actual per-chunk compute now is** — a structural, environment-level floor marginally ABOVE the 16.6 ms gate by the display's own refresh-rate arithmetic, not a mesher performance problem.

**Diagnostic run — same config (`view_radius_chunks=24`, `mesh_build_budget_ms=4.0`), VSync explicitly disabled** (`DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)`, added as an opt-in, default-`false` diagnostic constant, never the official methodology default):

| Statistic | Value | Budget | Result |
|---|---|---|---|
| Frame time avg | 9.690 ms | — | — |
| **Frame time p95** | **13.062 ms** | ≤ 16.6 ms | **PASS, 21.3% headroom** |
| Frame time max | 60.861 ms | — | (single isolated frame near sweep start, see below — not recurring) |
| Draw calls, max | 709 | ≤ 2000 | PASS |
| Samples over 2000 ceiling | 0 / 9,288 | 0 | PASS |

With the presentation-wait artifact removed, the TRUE compute-cost picture: avg dropped 42% (16.671 → 9.690 ms) and p95 comfortably clears the gate with real margin (13.062 vs. 16.6 ms). The max (60.861 ms) is an isolated non-recurring event — sorted the raw CSV by frame time descending: the top 3 values (60.861, 31.104, 30.563 ms) all fall within the first 0.13s of the sweep (shader/cache warm-up immediately after the topdown-capture settle frames), not a sustained pattern; no run of consecutive elevated frames appears anywhere else in the 9,288-sample series. Per the QA plan's own exception clause ("max/worst single frame... does not itself cause a MISS, unless later shown recurring on consecutive frames"), this max does not affect the verdict.

### Verdict

Per this story's own coordinator-directed resolution: **the gating metric is the TRUE compute-cost headroom (VSync-off measurement), because the VSync-on p95 barely over 16.6 ms is an artifact of this machine's 60 Hz display's own presentation-wait floor (≈16.667 ms), not a remaining compute cost this story's mesher-optimization scope can address** — no further read-loop, budget, or radius change can move an average that is already floor-bound by the display's own refresh interval; both the budget re-tune (AC3) and the one radius-tightening fallback step (AC5) empirically confirmed this (flatlined avg across 5 distinct configurations). AC1's own before/after figure (~40.4 ms → ~7.7 ms/chunk, ~5.2x) and the VSync-off diagnostic (p95 13.062 ms, 21.3% headroom) both independently confirm the read-loop fix succeeded and the mesher now has real compute headroom under the 16.6 ms budget.

**VERDICT: PASS.** Culling stays ENABLED throughout every run (grep-guard + same-session low-oblique screenshots, both runs — see below). **Milestone criterion #12 CLOSES.** Headroom recorded: 21.3% on the true-compute (VSync-off) measurement; the VSync-on number (16.947 ms, 2.1% over) is recorded honestly as a presentation-layer artifact of this specific 60 Hz test machine, not as a second, contradicting verdict — flagged explicitly for the same "no project-defined mid-range baseline" reason vox-018 already flagged (a different display refresh rate, or a future VSync-mode decision by `technical-director`/`godot-specialist`, would change this number without any mesher code change).

**No `CULL_DISABLED` fallback was used anywhere in reaching this verdict** — every lever exercised (read-loop optimization, budget re-tune, radius tightening, VSync diagnostic) is a legitimate, disclosed lever; the story's own Forbidden list stays honored.

## Culling-ON proof (both sessions)

1. **Grep-guard**: `mesher_material_contract_test.gd`'s `CULL_DISABLED` grep-guard re-run fresh as part of this story's own full suite pass (see Test Results) — zero code matches.
2. **Visual proof, VSync-on session**: `vox-019-low-oblique-20260725.png` (+ `vox-019-topdown-20260725.png` for context) — same session as the VSync-on numbers above.
3. **Visual proof, VSync-off session**: `vox-019-novsync-low-oblique-20260725.png` (+ `vox-019-novsync-topdown-20260725.png`) — same session as the VSync-off numbers above. Side/cliff faces render solidly at every terrain height-step in both captures, no see-through gaps — the same "historically riskiest angle" confirmation vox-007/vox-018 established.

Raw logs: `vox-019-60fps-culling-raw-20260725.csv` (VSync-on, 5,399 rows), `vox-019-novsync-raw-20260725.csv` (VSync-off diagnostic, 9,288 rows).

## Named remediation-ladder disposition (per AC5)

1. Read-loop optimization (AC1) — **applied, measured working** (~5.2x per-chunk cost reduction).
2. Budget re-tune (AC3) — **applied, empirically confirmed the default was already correct** (no better alternative found; 8.0 ms measured worse).
3. `view_radius_chunks` tightening (AC5 fallback) — **applied once** (24 → 20) — **did not move the VSync-on number** (17.022 ms, still MISS), which is exactly what led to the VSync-floor investigation above. Production `view_radius_chunks` is left UNCHANGED at 24 (the GDD's intended view distance) since the tightening bought nothing and the true compute cost already has headroom.
4. GDExtension escalation (AC5, if still-MISS) — **NOT filed**: the true-compute-cost verdict is PASS with real headroom; escalating to GDExtension would address a compute cost that measurably no longer exists. If a future VSync-mode change or a lower-refresh-rate/higher-latency target machine reopens this question, that is a new, separate measurement — not something this story's own scope should pre-empt.

## Test Results (this story's own full suite run)

See final report / smoke doc for the complete count — `mesher_bulk_read_equivalence_test.gd` (6/6 new), `mesher_winding_derivation_test.gd` and `mesher_material_contract_test.gd` (incl. `CULL_DISABLED` grep-guard) re-confirmed green as part of the same full run, not cited from a prior sprint.
