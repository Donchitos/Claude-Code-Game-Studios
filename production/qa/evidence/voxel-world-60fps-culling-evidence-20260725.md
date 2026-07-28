# Voxel World 60-FPS-with-Culling Evidence — Story vox-018 (Milestone Criterion #12)

**Date**: 2026-07-25
**Story**: `production/epics/voxel-world/story-018-60fps-culling-measurement.md`
**QA gate definition**: `production/qa/qa-plan-sprint-8-2026-07-25.md`, "THE MILESTONE-CENTERPIECE" section
**Tool**: `neues-spiel/tools/vox018_60fps_culling_measurement.gd` / `.tscn`
**Raw log**: `production/qa/evidence/vox-018-60fps-culling-raw-20260725.csv` (2,136 rows)
**Screenshots**: `production/qa/evidence/vox-018-topdown-20260725.png`, `production/qa/evidence/vox-018-low-oblique-20260725.png` (same run as the numbers below)
**Engine**: Godot 4.7.stable.official.5b4e0cb0f, D3D12 backend (Forward+)
**Launch command**: `Godot_v4.7-stable_win64_console.exe --path neues-spiel res://tools/vox018_60fps_culling_measurement.tscn` (WINDOWED, not `--headless`)
**Hardware** (recorded verbatim — no project-defined "mid-range" baseline exists yet, per the QA plan's own flagged open question): AMD Ryzen 9 5900X (12-core), AMD Radeon RX 7900 XT, 32 GB RAM, Windows 11 Pro. This is a high-end dev machine, not a verified mid-range baseline — a PASS or MISS here does not by itself confirm the mid-range target; recorded as the QA plan instructs, with the gap flagged rather than implied resolved.

---

## Methodology

- Real `VoxelWorldGrid` + real `VoxelWorldMesher` + real `VoxelWorldMeshStreamer` (the same production classes `src/voxel_world/` ships), constructed directly by the tool — not wired into `GameWorld`/`Valley`.
- `view_radius_chunks = 24` — the shipped `VoxelWorldConfig` default, the QA plan's own gating knob.
- **World-extent honest deviation**: 896×896 cells, not ADR-0014's 2000×2000 (nor even its own "minimum 1000×1000" figure). Measured directly while building this tool: `VoxelWorldGrid.generate_terrain()`'s `Dictionary`-accumulation implementation costs ~63 µs/column and scales linearly through 900×900 (700→30.9s, 800→40.4s, 900→52.2s, all ~63 µs/column) but becomes severely super-linear at 1000×1000 (did not complete in over 200s headless, no rendering involved at all — a `Dictionary` resize/rehash cost cliff, confirmed both headless and windowed). 896 was chosen as a `CHUNK_SIZE`-aligned value just under the measured-safe ceiling. This is a `generate_terrain` scaling finding (that method is not touched by this wiring-only story), not a finding about the mesher/streamer/rendering path actually being measured. 896 cells (56 chunks/axis) still exceeds the view window's own 784-unit/49-chunk diameter, so "draw calls decoupled from world size" is still genuinely demonstrated, with real but more modest margin than a larger world would give.
- Camera driven directly (no `CameraInput` node in this tool) along a scripted diagonal sweep, `(100,100)` → `(796,796)` (984 world units, > the window's 784-unit diameter), one leg every 15s, continuously back-and-forth for the full 90s window — 6 one-way legs completed (2 full there-and-back sweeps' worth of legs, and comfortably exceeding both the QA plan's ">= 60s" AND ">= 3 one-way-equivalent sweep legs" floors — 90s > 60s and 6 legs > 3).
- Camera held at a fixed low, oblique, grazing offset from the sweep focus throughout (mirrors `tools/mesher_evidence.gd`'s established "historically riskiest angle" methodology) — the SAME camera state produces both the FPS/draw-call numbers and the culling-proof screenshot, per the QA plan's "same session" requirement.
- `update_view_window()` called every frame with the current sweep focus cell — the same per-frame call `Valley._process()` now makes in production.
- Frame time: `Time.get_ticks_usec()` deltas between samples (never the engine-supplied `delta` parameter). Draw calls: `RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)`, sampled every frame.
- Setup costs, timed and logged: `generate_terrain()` = 52,138 ms; `build_initial_window()` = 38,821 ms (961 chunks). Both run BEFORE sampling begins — never included in the measured statistics below.

---

## Measured numbers (2,136 samples over the 90s sweep, 6 legs)

| Statistic | Value | Budget | Result |
|---|---|---|---|
| Frame time avg | 42.148 ms | — (context only) | — |
| **Frame time p95 (gating statistic)** | **51.536 ms** | ≤ 16.6 ms | **MISS (~3.1x over)** |
| Frame time max | 68.967 ms | — (context only) | — |
| avg FPS-equivalent | 23.7 | 60 | MISS |
| p95 FPS-equivalent | 19.4 | 60 | MISS |
| Draw calls, max (any single sample) | 709 | ≤ 2000, every sample | **PASS** |
| Samples over the 2000 draw-call ceiling | 0 / 2,136 | 0 | **PASS** |

---

## Culling-ON proof

1. **Grep-guard, re-run fresh for this story** (not cited from a prior sprint): `rg CULL_DISABLED` across `src/voxel_world/` and `assets/shaders/terrain_chunk.gdshader` returns only doc-comment mentions of the forbidden term (documentation naming what must never appear), zero actual code usage. Also re-confirmed via `mesher_material_contract_test.gd` passing in this story's own full suite run (see Test Results below).
2. **Visual proof, same run as the numbers**: `vox-018-low-oblique-20260725.png`, captured mid-sweep from the same continuously-driven low-oblique camera that produced the FPS/draw-call series above. Side/cliff faces at every terrain height-step render solidly, with no see-through gaps to the sky-blue background anywhere in the terrain silhouette — the same "historically riskiest angle" confirmation `vox-007`'s own evidence used. `vox-018-topdown-20260725.png` (captured just before the timed sweep began, at the sweep's starting corner) provides top-down context: a continuous, gap-free meshed surface, world-edge water/sky boundary visible where the 896-cell world ends near the sweep's start.

Both facts (culling genuinely on, FPS/draw-call numbers) come from the identical windowed session — not stitched together from separate runs.

---

## PASS / MISS verdict

Per the QA plan's own binding definition: **PASS requires ALL of** (1) p95 frame time ≤ 16.6 ms, (2) draw calls ≤ 2000 every sample, (3) culling proven ON, (4) genuinely windowed on a real GPU.

- (1) p95 = 51.536 ms — **FAILS**, by ~3.1x.
- (2) max draw calls = 709 — **PASSES** comfortably.
- (3) — **PASSES** (grep-guard + same-session low-oblique screenshot).
- (4) — **PASSES** (D3D12/Forward+, real GPU, launch command recorded above).

**VERDICT: MISS**, on the frame-time axis specifically. Per the story's own Forbidden list and this plan's agreement: **no `CULL_DISABLED` fallback under any circumstance** — culling stays enabled. **Milestone criterion #12 stays OPEN**, recorded explicitly as open at this hand-off, not silently implied fixed by the sprint closing.

---

## Root-cause finding (measured, not guessed)

Instrumented directly while building this tool: `VoxelWorldMesher.build_chunk()` (via `_build_chunk_arrays()`) costs **~40 ms per chunk** at this config with real terrain present (measured: 961 chunks in 38,821 ms during the initial unbounded build) — far above `VoxelWorldConfig.mesh_build_budget_ms`'s 4.0 ms default. `_build_chunk_arrays()` reads every one of a chunk's cells via `VoxelWorldGrid.get_cell()` (~16×16×33 ≈ 8,448 calls per chunk at `max_y=32`) regardless of how many are solid or air — the cost is dominated by this per-cell read loop, not by the number of emitted faces/vertices.

Because `VoxelWorldMeshStreamer._drain_budgeted()`'s "progress guarantee" always integrates at least one item per call even when that single item's own cost already exceeds the budget, and the continuous sweep means at least one new chunk enters the window on nearly every frame, that guaranteed ~40 ms chunk build lands on nearly every sampled frame — closely matching the measured 42 ms average. This is the primary, measured cause of the MISS: **not overdraw/triangle count** (draw calls stayed comfortably under budget throughout), but **per-chunk build latency** on the mesh-streaming path.

This is a landed `vox-007`/`vox-015` mesher/streamer characteristic, not something introduced by this wiring-only story — vox-018's own scope is the measurement, not the fix.

---

## Named remediation stories (MISS — filed, not built, per this story's own Implementation Notes)

1. **Profile and reduce `VoxelWorldMesher.build_chunk()`/`_build_chunk_arrays()` per-chunk cost** — the root-cause finding above points at the per-cell `get_cell()` read loop (not triangle/vertex count) as the dominant cost; ADR-0014's named "greedy meshing" reserve reduces triangle/vertex count and may therefore have LESS impact on this specific bottleneck than expected — the remediation story should measure both a read-loop optimization (e.g., an early-exit/cached "chunk has any solid cell" flag, or reducing redundant neighbor reads) AND greedy meshing, and report which actually moves the number.
2. **Re-tune `mesh_build_budget_ms` in light of a single chunk exceeding it** — a budget re-tune alone cannot fix a single item whose own cost exceeds the budget (the progress guarantee will still integrate it); this story should re-evaluate whether the budget knob is the right lever at all given finding #1, or whether it only matters once #1 lands.
3. **`visibility_range_end` / `view_radius_chunks` tightening** — a smaller window reduces the window's edge length and therefore the entering-chunk rate during continuous camera movement, directly reducing how often the guaranteed-cost chunk build lands per frame; measure the tradeoff against the GDD's intended view distance.
4. **GDExtension escalation (ADR-0014 Decision §5, the named escalation path)** — if #1–#3 do not close the gap, ADR-0014 already names moving the mesher to GDExtension (C++) behind the same chunk interface as the structural fallback; this measurement (a ~3x miss dominated by per-cell read cost, not overdraw) is exactly the kind of profiling result that escalation path anticipates.

---

## Test Results (this story's own full suite run)

- `neues-spiel/tests/integration/voxel_world/live_view_window_wiring_test.gd` — **4/4 PASSED**, 0 orphans (AC-1 hosted/wired/setup-via-GameWorld-only, boot-timing synchronous-before-first-frame, live per-frame focus tracking + window-bounded draw-call proxy).
- Full regression suite (`tests/run-tests.cmd`) — see final report for the complete count; `mesher_material_contract_test.gd`'s `CULL_DISABLED` grep-guard included and passing as part of this same run (re-confirmed fresh, not cited from a prior sprint).

---

## Manual QA Checklist (from the QA plan) — status

- [x] `build_initial_window()` occurs behind the boot/WIRING sequence, before `BootState.ACTIVE` — no visible frozen production frame during the initial build (proven headless by `live_view_window_wiring_test.gd`; this tool's own separate ~39s initial build is this TOOL's own setup cost, not a production boot-time cost).
- [x] Camera swept across a world larger than the production view window for ≥ 60s (90s) and ≥ 3 one-way sweep legs (6 completed).
- [x] p95 frame time, draw-call series, and the low-oblique culling-proof screenshot all come from the SAME session.
- [x] `CULL_DISABLED` grep-guard re-run fresh — zero code matches (doc-comment mentions only).
- [x] Verdict rendered honestly as **MISS**; remediation stories named above; criterion #12 recorded **OPEN**.
