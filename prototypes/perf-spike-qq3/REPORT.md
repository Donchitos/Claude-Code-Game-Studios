# Performance Spike QQ3 — Report

> **Date**: 2026-07-11 · **Hardware**: dev machine (AMD GPU, Windows 11, D3D12 backend, vsync on)
> **Engine**: Godot 4.7-stable · **Seed**: 1337 · **Raw data**: `results/*.csv`
> **Verdict: PASS on all three gated ADRs** (ADR-0008 with a tuning deliverable + watch-item)

## Measurement caveat

Frame times are vsync-locked at 16.667 ms — "p95 = 16.667" means "held 60 FPS",
headroom below that is not visible. All GDScript stand-in costs (Deciding pass,
BFS) are conservative upper bounds: production code can early-out and cache
where the stand-in brute-forces.

## S1 — Rendering scale (ADR-0003) — PASS

| Metric | C1 (64×16×64) | C2 (100×32×100) | Threshold |
|---|---|---|---|
| Cells committed | 19,664 | 87,280 | — |
| Populate time | 13 ms | 70 ms | ≤ 3000 ms ✅ |
| Frame p95 (worst view) | 16.667 ms | 16.667 ms | ≤ 16.6 ms ✅ |
| Draw calls max | 609 | **1,598** | ≤ 2000 ✅ |
| Memory static | 57 MB | 89 MB | ≤ 4 GB ✅ |

**Margin note**: 1,598 draw calls at C2 with only 36 houses leaves ~20% margin.
A denser settlement could cross 2,000 — first mitigation lever is
`GridMap.cell_octant_size` (default 8 → 16 quarters octant count), before any
Alternative-C migration talk. Not a blocker; recorded as a density watch-item.

## S2 — 30-villager stress at 1x/3x warp (ADR-0008) — PASS with deliverable

| Config | warp1 p95 | warp3 p95 | warp3 avg |
|---|---|---|---|
| `max_deciding_per_tick = 4` | 16.667 ms | **83.3 ms FAIL** | 30.5 ms |
| `max_deciding_per_tick = 1` | 16.667 ms | **16.667 ms PASS** | 16.9 ms |

- **Tuning deliverable: `max_deciding_per_tick = 1`** (the ADR named this
  empirical value as the spike's job). The staggering mechanism itself works
  exactly as designed — the budget just has to be 1 at this per-pass cost.
- Includes the S2b synchronized mass-Deciding event (all 30 enqueue in one
  tick) in both phases: queue drains at 1/tick with no sustained degradation.
- **Watch-item**: a single Deciding pass costs avg 11 ms / p95 35 ms in the
  GDScript stand-in (15 candidates × 200-cell bounded BFS ≈ 560 µs per
  candidate check) — one pass alone can blow a frame (rare hitches, worst
  144 ms, <5% of frames). In-design mitigations before reaching ADR-0008's
  threading escape hatch: cheaper candidate pre-filter (Chebyshev only),
  smaller BFS bound, or slicing one pass across ticks. No architecture change
  needed now.

## S3 — AStar3D dynamics (ADR-0007) — PASS

| Metric | Value | Assessment |
|---|---|---|
| Graph build (11,281 points @ C2) | 278 ms | boot-time, one-off — fine |
| Incremental patch (write-storm, n=4800) | avg 0.46 ms, worst 1.0 ms | absorbed in-frame ✅ |
| Live path query (n=9600) | avg 63 µs | negligible ✅ |
| Cold query bench (200 long paths) | avg 0.46 ms, p95 1.9 ms | event-driven, fine ✅ |

35% of random bench pairs were unconnected (roof/floor islands in the
generated map) — an artifact of the synthetic world, and the live loop handles
empty paths by re-Deciding; no finding against the ADR.

## S4 — Build Validation BFS scaling (ADR-0007 accepted-risk) — PASS, boundary quantified

Linear at **~1.4 ms per 1,000 connected cells** (C2: 1k→1.3 ms, 5k→6.1 ms,
20k→24 ms, 60k→84 ms). The GDD's "unbounded, no caching" pass exceeds one
frame budget above **~12,000 connected build cells**. For MVP (houses of
~200 cells) this is orders of magnitude away; record ~12k as the boundary
that triggers the incremental/cached re-analysis conversation, per
build-validation-navigability.md TR-020's documented risk.

## ADR consequences applied

- **ADR-0003 → Accepted** (spike PASS; draw-call density watch-item noted)
- **ADR-0007 → Accepted** (patch/query costs absorbed; S4 boundary recorded)
- **ADR-0008 → Accepted** (stagger validated; `max_deciding_per_tick = 1`
  initial value; per-pass-cost watch-item with named in-design mitigations)
- **ADR-0009 / ADR-0013 → unblocked** (their hold was ADR-0007's provisional
  status)
- `architecture.md` QQ3 → resolved by this report.

## Addendum (2026-07-11, user request): world-scale staircase 500 → 1000 → 2000

Question: could the map be much bigger — 2000×2000? Measured with the same
naive GridMap + full-column + Dictionary architecture (S1 only):

| Size | Cells | Populate | Memory | Near view | Full view | Draw calls (full) |
|---|---|---|---|---|---|---|
| 100 (ADR ceiling) | 87k | 0.07 s | 89 MB | 60 FPS | 60 FPS | 1,598 ✅ |
| 500 | 2.2M | 1.9 s | 1.1 GB | 60 FPS | **~35 FPS** | 16,229 ❌ |
| 1000 | 8.9M | 8.1 s | 4.2 GB (static) | **~24 FPS** | **7.5 FPS** | 65,835 ❌ |
| 2000 | ~32M | ~30 s (terrain only) | **>16 GB RSS — killed** | n/a | n/a | n/a |

Scaling is linear in cells for memory (~500 B/cell all-in) and roughly linear
in draw calls for the full view — the budget breaks between 100 and 500,
memory breaks between 1000 and 2000 (hard, before rendering even starts).

**Conclusion**: 2000×2000 is architecturally out of reach for the *accepted*
MVP approach — and that approach was never designed for it (ADR-0003 scopes
to the bounded ~100×100 valley; this addendum does NOT invalidate the spike
PASS at design scale). Reaching 2000×2000 would be an open-world voxel
architecture: chunked/greedy meshing with hidden-face culling (ADR-0003
Alternative C, cuts rendered geometry ~10–50×), packed chunk storage instead
of `Dictionary` (~500 B/cell → ~2–4 B/cell), distance culling/LOD, and chunk
streaming. That is a game-concept-level scope change (new GDD constraint +
ADR-0003 supersede), not a tuning knob.

Instrumentation note: the 6 GB memory guard keyed on `Performance.MEMORY_STATIC`
did not fire at 2000 — MEMORY_STATIC (5.1 GB at kill time) excludes
RenderingServer/GridMap buffers (real RSS 16 GB). Future guards must read
process RSS (e.g. `OS.get_memory_info()`), not MEMORY_STATIC.

## C1-vs-C2 headroom

C2 (ADR ceiling) passes everything, so the GDD-default C1 world is not the
thing keeping us honest — no world-size cap needed. The flagged GDD/ADR scale
discrepancy stays a documentation note, not a constraint.

## Addendum 2 (2026-07-11, Pre-Production step 1): QQ5 region spike + un-vsync re-measure

**S5 — region-bounded nav graph on the 2000-world** (data-only, houses included):

| Region | Points | Build (boot) | Mem | Query avg/p95 | Patch avg |
|---|---|---|---|---|---|
| 100x100 | 11.2k | 0.26 s | 36 MB | 0.5 / 1.8 ms | 0.36 ms |
| 200x200 | 47k | 1.1 s | 73 MB | 2.6 / 9.2 ms | 0.37 ms |
| 300x300 | 106k | 2.5 s | 131 MB | 5.2 / **24 ms** | 0.37 ms |
| 400x400 | 188k | 4.7 s | 217 MB | 12 / **49 ms** | 0.38 ms |

Patch cost is FLAT (local op) — write-storms scale-free. Query cost scales with
path length (bench = random worst-case pairs). **QQ5 RESOLVED: settlement-core
nav region committed <= 200x200** (p95 9.2 ms fits one-per-tick staggering,
ADR-0008 mdpt=1); 300+ is frame-breaking per single query. Escape hatch past
200: hierarchical/regional graphs (future ADR).

**Un-vsync re-measure (chunked mesher @2000):** real frame cost avg 1.1-1.6 ms,
p95 1.7 ms (was vsync-masked at 16.7) — **~10x budget headroom**. TD condition
closed; greedy-meshing reserve confirmed unnecessary. Streaming p95 4.5 ms;
the known 141 ms unload-burst hitch remains a production-implementation note
(staggered unloads, ADR-0014 §3).
