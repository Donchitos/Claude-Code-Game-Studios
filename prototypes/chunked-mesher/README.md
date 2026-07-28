# Chunked Mesher Prototype

**Hypothesis being tested**: A chunked, face-culled voxel mesher with packed
chunk storage and view-window streaming makes a 2000×2000×32 world feasible
within all committed budgets (60 FPS, ≤2000 draw calls, ≤4 GB) — where the
accepted GridMap approach (ADR-0003) measurably fails (see
`../perf-spike-qq3/REPORT.md` world-scale addendum).

**How to run**:
```
Godot_v4.7-stable_win64_console.exe --path . -- --size=2000
```
First run needs `--headless --import` once. Results land in `results/`.

**Status**: concluded (2026-07-11) — **hypothesis CONFIRMED**

**Findings** (full world 2000×2000×32, unoptimized GDScript, no greedy meshing):
- Full-world packed data: **172 MB** (vs >16 GB naive — killed)
- 60 FPS locked in all views; draw calls max **1,293** (vs 65,835 naive at 1000²)
- Single-block edit → chunk rebuild: **1.1 ms avg** (build feel preserved)
- Streaming flight: 1,488 chunks meshed live at 1.1 ms each, p95 frame 16.7 ms
- Initial 48×48-chunk window build: 2.6 s (one-time, loading-screen material)
- Known rough edge: one 133 ms hitch during streaming (unload burst of
  `queue_free` — production staggers unloads)
- VRAM 155 MB; vsync-locked measurement (headroom not visible, budget met)

Consequence: ADR-0014 supersedes ADR-0003; game-concept world scale changed
to large-world (exploration + distant dungeons). Production mesher is a
rewrite per ADR-0014, never this code (prototype standards).
