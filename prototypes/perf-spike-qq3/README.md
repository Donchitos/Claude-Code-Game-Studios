# Performance Spike QQ3

**Hypothesis being tested**: The three provisional architecture keystones hold
at design-ceiling scale — (1) GridMap rendering stays within 60 FPS / ≤2000
draw calls at the 100×32×100 world (ADR-0003), (2) an incrementally-patched
`AStar3D` graph absorbs write-storm patching and 30-villager query load within
the frame budget (ADR-0007), and (3) tick-staggered Deciding passes keep 30
villagers at 3x warp inside 16.6 ms without threading (ADR-0008).

**How to run**:
```
# single scenario (windowed, real GPU — use the _console exe for captured stdout)
Godot_v4.7-stable_win64_console.exe --path . -- --scenario=s1 --config=c2
# scenarios: s1 (rendering), s2 (villager stress + nav dynamics), s4 (BFS bench)
# configs:   c1 (GDD-default 64x16x64), c2 (ADR-ceiling 100x32x100)
# s2 extra:  --mdpt=N (max_deciding_per_tick override)
# full sequence:
powershell -File run_all.ps1
```
Results land as CSV in `results/`. First run needs `--import` once (class cache).

**Status**: concluded (2026-07-11)

**Findings**: see [REPORT.md](REPORT.md). Headline: S1/S3/S4 PASS;
S2 PASSES only with `max_deciding_per_tick = 1` at 3x warp — the knob value
is the spike's tuning deliverable; mdpt=4 blows the frame budget (p95 83 ms).
BFS full-pass cost is linear (~1.4 ms per 1000 cells) → the accepted-risk
boundary for Build Validation's unbounded pass sits at ~12k connected cells.

This is throwaway code (relaxed prototype standards). Production
implementations are rewritten from the ADRs, never migrated from here.
