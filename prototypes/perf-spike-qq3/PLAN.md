# Performance Spike QQ3 — Plan

> **Status**: Planned (authored 2026-07-11, autonomous run — user delegated)
> **Gates**: ADR-0003 (Rendering), ADR-0007 (Pathfinding), ADR-0008 (AI Execution) — Proposed → Accepted
> **Executor**: prototyper agent (throwaway code, relaxed standards) — output lives here, never in `src/`
> **Hardware**: MUST run windowed on the target dev machine's real GPU (AMD, primary monitor Odyssey G61SD). Headless runs are invalid for rendering metrics.

## Why this spike

Three keystone ADRs are provisional on unmeasured claims. This spike either
confirms them at the design ceiling or triggers their named fallbacks BEFORE
Vertical Slice code lands on top of them. Cheap insurance (2026-07-10 review).

## World configuration

Two configs per scenario where world size matters:
- **C1 "GDD default"**: 64×(0–16)×64, `base_height` 4, `amplitude` 3 (~70k cell bound)
- **C2 "ADR ceiling"**: 100×32×100 (~320k cell bound) — the number all three ADRs cite

> Flagged discrepancy: the GDD Tuning Knobs default (64×64) and the ADR ceiling
> (100×32×100) are different framings. The spike validates against **C2**; C1
> exists to show headroom at the actual starting config. If C2 fails but C1
> passes comfortably, the resolution may be a documented world-size cap instead
> of an architecture flip — record this option in the report.

## Scenarios

### S1 — Rendering scale (gates ADR-0003)
Populate GridMap (`use_collision = false`, tier-0 3-material MeshLibrary) with a
procedurally built dense settlement (walls/floors/roofs pattern, ~30–50%
occupancy of the build layer) at C1 and C2.
**Measure**: draw calls, frame time (avg + p95), memory (static + after populate),
and **boot populate time** (batch `set_cell_item` — ADR-0003 flags it unmeasured).
Camera sweep: near zoom, far zoom, worst-case full-settlement view.

### S2 — 30-villager stress (gates ADR-0008, parts of 0007)
30 villager stand-ins (Area3D per ADR-0004) running the FSM loop with:
unreachable-job-dense queue + parallel construction write-storm, at **1x AND 3x
warp**, with `max_deciding_per_tick` staggering active.
**Measure**: frame time (avg/p95/worst), time in Deciding passes per tick,
queue latency (`queue_length / max_deciding_per_tick` empirical vs designed).
**Sub-case S2b**: synchronized mass-Deciding spike (all 30 enqueue in one tick —
Rule 10c stagger under test). **Sub-case S2c**: Breather step-away/bed-drift
pathing storm.

### S3 — AStar3D graph dynamics (gates ADR-0007)
Build the standable-cell graph at C2 (int64-packed ids, 21-bit axes; costs
1.0/1.4). Then: (a) incremental patch cost per Voxel World write during the S2
write-storm (points+connections add/remove), (b) raw shortest-path query
throughput while 30 villagers path concurrently across the map.
**Measure**: ms per patch, ms per query (avg/p95), graph build time, graph memory.

### S4 — Region flood-fill on merged structures (gates ADR-0007's BFS side)
One sprawling MERGED building footprint (Build Validation's worst case — scales
with connected footprint, NOT villager count). Run full-analysis BFS passes while
S2's write-storm mutates the structure.
**Measure**: ms per analysis pass vs footprint size (plot 4 sizes up to
"absurd": entire C2 build layer as one structure).

## Pass/fail thresholds (from committed budgets)

| Metric | PASS | Source |
|---|---|---|
| Frame time, every scenario, C2, 3x warp | p95 ≤ 16.6 ms | technical-preferences 60 FPS |
| Draw calls S1@C2 worst view | ≤ 2000 | technical-preferences |
| Memory total S1@C2 | ≤ 4 GB (expect ≪; record actual) | technical-preferences |
| Boot populate S1@C2 | ≤ 3 s to first frame `[assumption — "near-instant" TR-voxel-world-026 has no number; propose 3 s, user may tighten]` | ADR-0003 risk note |
| S3 patch cost during write-storm | patching absorbed within the frame budget alongside S2 (no dropped frames attributable to patching) | ADR-0007 |
| S4 BFS pass | does not exceed one frame budget at realistic footprints; document the footprint size where it does (accepted-risk boundary, TR-020 "unbounded, no caching") | ADR-0007 |

## Fallback map (on FAIL)

| Fails | Flip to | Source |
|---|---|---|
| S1 | ADR-0003 Alternative C (chunked/greedy mesher) — migration plan authored as part of QQ3 resolution | ADR-0003 |
| S2 | ADR-0008 Alternative D (`WorkerThreadPool` for Deciding) — costs thread-safety work on occupancy/AStar3D/Needs state | ADR-0008 |
| S3/S4 | **No named fallback in ADR-0007** — a FAIL re-opens the decision generically. GAP: before executing the spike, decide the candidate fallback (e.g. hierarchical regions / cached BFS) or accept re-opening. | ADR-0007 (flagged) |

## Methodology

- Godot 4.7 windowed (real GPU), `Performance.get_monitor()` per frame:
  TIME_PROCESS, RENDER_TOTAL_DRAW_CALLS_IN_FRAME, MEMORY_STATIC; custom
  `Time.get_ticks_usec()` around patch/query/BFS calls.
- Each scenario runs ≥ 60 s after a 5 s warmup; log CSV to `results/` here;
  auto-quit. One scenario per run (no cross-contamination).
- Determinism: fixed seed for terrain + villager placement; log the seed.
- Report: `REPORT.md` here — per-scenario table, PASS/FAIL per threshold,
  verdict per ADR (keeps Accepted-path / triggers fallback), and the C1-vs-C2
  headroom note.

## Explicitly out of scope

Wave-defense spatial contract (QQ1 — separate `/prototype wave-defense`),
Township prosperity definition (QQ2), any reusable production code.

## Open items before execution

1. ADR-0007 fallback gap (above) — needs a technical-director ruling.
2. Boot-populate threshold is `[assumption]` (3 s) — confirm or tighten.
3. Executor + schedule: ~1–2 focused sessions via the prototyper agent.
