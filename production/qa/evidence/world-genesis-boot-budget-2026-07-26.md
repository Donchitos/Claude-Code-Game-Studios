# World Genesis Boot Budget — Evidence (Story scene-005, AC-BOOT-BUDGET)

**Date**: 2026-07-26
**Story**: `production/epics/scene-world-management/story-005-world-genesis-boot-sequence.md`
**QA gate**: AC-BOOT-BUDGET (Advisory, measured, time-boxed)
**Tool**: `neues-spiel/tools/scene005_genesis_boot_budget_measurement.gd` / `.tscn` — reuses
vox-021's own measurement methodology verbatim (real production classes, WINDOWED, self-quit,
printed stats + raw log, `Time.get_ticks_usec()` deltas around real synchronous calls), extended
to cover the two phases vox-021's own tool explicitly could not measure (nav-graph build, roster
spawn — neither was reachable from `GameWorld`'s boot chain until this story wired them in).
**Engine**: Godot 4.7.stable.official.5b4e0cb0f, D3D12 backend (Forward+)
**Hardware**: AMD Ryzen 9 5900X (12-core), AMD Radeon RX 7900 XT, 32 GB RAM, Windows 11 Pro — same
dev machine as vox-018/vox-019/vox-021, same "not a verified mid-range baseline" caveat carried
forward.
**Launch command**: `Godot_v4.7-stable_win64_console.exe --path neues-spiel res://tools/scene005_genesis_boot_budget_measurement.tscn`
(WINDOWED, not `--headless`)
**VSync**: explicitly DISABLED (`DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)`).
Every timed number below is a `Time.get_ticks_usec()` delta around a real synchronous call, never a
per-frame measurement, so VSync mode does not move these numbers — disabled anyway for methodology
compliance, per vox-021's own precedent.

---

## Honest finding: the first measurement MISSED, and why

vox-021's own evidence (`boot-mesh-radius-boot-budget-20260726.md`) recorded nav-graph build and
roster spawn as "0 ms / not-yet-wired-into-boot" because neither `VillagerNavGraph.build()` nor
`Valley.spawn_starting_roster()` was reachable from `GameWorld`'s landed synchronous boot chain at
that time — both were deliberately deferred pending this exact story. That story's own Addendum D
text flagged the risk explicitly: *"reduce `VillagerAIConfig.nav_region_size` (a pure `.tres` data
change — 200×200×17 ≈ 680k predicate evaluations at the current default)"* is this story's own
named remediation lever #1, listed for exactly this situation.

**First measurement (shipped `nav_region_size = 200`, before this story's re-tune) — MISS:**

| Phase | Measured |
|---|---|
| Residency page-in (625 chunks, `view_radius_chunks=12`) | 103.5 ms |
| Nav-graph build (`nav_region_size=200`, 680,000 `is_standable` evaluations) | **6697.6 ms** |
| Initial mesh window (289 chunks, `boot_mesh_radius_chunks=8`) | 2280.4 ms |
| Roster spawn (`starting_villager_count=1`) | 0.4 ms |
| **TOTAL** | **9082.0 ms** |

Verdict: **MISS** — total (9082.0 ms) blows the 3.0 s ceiling by ~3×, driven almost entirely by the
nav-graph build phase alone (6697.6 ms), which nobody had measured against a live boot budget
before this story wired the call into the real chain.

**Remediation applied — named lever #1, exactly as the story's own Addendum D text prescribes:**
`VillagerAIConfig.nav_region_size` retuned **200 → 40** (a pure `.tres` data change,
`data/config/villager_ai_config.tres`; rationale doc comment in `villager_ai_config.gd`). Still
comfortably inside ADR-0007's own measured-safe range (20–200) — that range's upper bound was a
performance *ceiling* the ADR's own spike measured, never a floor; a 40×40 settlement core remains
generous at MVP/VS population scale (1–5 villagers). No second lever (tightening the boot drain's
own wall-clock ceiling) was needed.

---

## Re-measured results (after the lever, ONE re-measurement per the story's own instruction)

### 1. Real full boot (`game_world.tscn`, the exact production scene, unmodified boot code)

| Metric | Value |
|---|---|
| `boot_state` at settle | `ACTIVE` (2) |
| **Total boot-to-ACTIVE wall clock** | **2585.7 ms** |
| Resident chunks | 625 |
| Grid state | `GENERATED` |
| Villagers (default + genesis-spawned roster) | 2 |

**Verdict against the technical-director's ceiling (total ≤ 3.0 s): PASS — 414.3 ms / 13.8%
headroom.**

### 2. Phase breakdown (isolated primitives, same genesis order: residency → nav-graph → mesh
window → roster spawn)

| Phase | Measured (after re-tune) | Before re-tune |
|---|---|---|
| Residency page-in (625 chunks) | 108.7 ms | 103.5 ms |
| Nav-graph build (`nav_region_size=40`, 27,200 evaluations) | **266.6 ms** | 6697.6 ms |
| Initial mesh window (289 chunks) | 2189.2 ms | 2280.4 ms |
| Roster spawn (`starting_villager_count=1`) | 0.4 ms | 0.4 ms |
| **TOTAL** | **2564.9 ms** | 9082.0 ms |

**Verdict: total (2564.9 ms) ≤ 3000 ms — PASS (435.1 ms / 14.5% headroom). Mesh phase (2189.2 ms) ≤
2500 ms — PASS (310.8 ms / 12.4% headroom).**

Both the real-full-boot number (2585.7 ms) and the phase-breakdown total (2564.9 ms) agree within
~21 ms — the small delta is real per-call overhead the isolated-primitive tool cannot fully
reproduce (scene-tree child-count differences, one extra `MockResourceItemDatabase` node, etc.),
consistent with vox-021's own note that the arithmetic-only projection and the measured number
never match exactly.

**Carried finding, unchanged from vox-021, not remediated by this story (out of its own scope,
named there as an accepted risk)**: the mesh phase's own headroom against its 2500 ms sub-ceiling
remains thin (~12%) — a future change adding even modest per-chunk mesh overhead could tip this
specific sub-ceiling to MISS. Flagged again here for whoever next touches `VoxelWorldMesher.
build_chunk` or the mesh-streamer's per-item work; this story does not touch that code path.

---

## Test Results (this story's own full suite run)

Full regression suite (`tests/run-tests.cmd`): **1100 test cases, 0 errors, 0 failures, 0 flaky, 0
skipped, 0 orphans, exit 0.**

---

## Files

- `neues-spiel/tools/scene005_genesis_boot_budget_measurement.gd` / `.tscn` — the measurement tool
  (new).
- `neues-spiel/src/scene_world_management/game_world.gd` — `_run_world_genesis` /
  `_drive_boot_residency` (the boot-phase orchestration this measures).
- `neues-spiel/data/config/villager_ai_config.tres` — `nav_region_size` 200 → 40 (the applied
  lever).
- `production/qa/evidence/scene-005-boot-budget-raw.txt` — raw tool output (this run).
