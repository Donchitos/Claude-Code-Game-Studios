# Build Validation & Navigability — Story build-validation-010: AC36 Reachability Property Corpus Runtime Evidence

**Date**: 2026-07-26
**Story**: `production/epics/build-validation-navigability/story-010-reachability-property-corpus.md`
**Test file**: `neues-spiel/tests/integration/build_validation/reachability_property_corpus_test.gd`
**Seed fixture**: `neues-spiel/tests/integration/build_validation/reachability_property_corpus_seeds.gd`
**Milestone**: M02 criterion #2 (this artifact is the recorded runtime that criterion requires)

## What was measured

`test_corpus_100_seeds_50_pairs_all_verdicts_agree` — cross-checks Build
Validation's independent BFS reachability trace
(`BuildValidationReachability.is_reachable`, added by this story) against
Villager AI's `AStar3D` shortest-path query (`VillagerNavGraph.find_path`)
over the checked-in 100-seed corpus, each seed generating a bounded
32x32x16 world (real `VoxelWorldGrid.generate_terrain` + a deterministic
wall/floor/roof solid-fill pass at 10-40% density) and sampling
(start, target) pairs from that world's standable cells.

## Result: 5,000/5,000 verdicts agree at the AC's literal spec — performance-only ceiling breach, cut-lever applied

| Configuration | Total verdicts | Elapsed (this machine) | vs. 60s ceiling | Disagreements found |
|---|---|---|---|---|
| 50 pairs/seed (AC36 literal spec — 5,000 verdicts) | 5,000 | **183.55 s** | 3.06x over | **0** |
| 10 pairs/seed (diagnostic) | 2,000 | 54.71 s | 91% of budget | 0 |
| 8 pairs/seed (diagnostic) | 1,600 | 50.89 s | 85% of budget | 0 |
| **5 pairs/seed — SHIPPED configuration** | **1,000** | **44.52 s** | **74% of budget** | **0** |

**No disagreement was found at any configuration** — every verdict Build
Validation's BFS trace and Villager AI's `AStar3D` pathfinder produced
across all four runs (9,600 total verdicts checked across the four
configurations above) agreed. The only failure observed during development
was the runtime-ceiling assertion at the 50-pairs/seed configuration (a pure
performance breach, not a correctness one — see Cut-Lever Policy below).

## Cut-Lever Policy applied (story's own Implementation Notes)

The story's own Implementation Notes require, on a ceiling breach: *"reduce
sampled pairs per seed before reducing seed count... re-measure once, then
escalate to technical-director."* Applied as follows:

1. Full spec (50 pairs/seed) measured **183.55 s** — 3x over budget.
2. Reduced to 10 pairs/seed: 54.71 s (91% of budget — too thin a margin for
   CI hardware variance).
3. Reduced to 8 pairs/seed: 50.89 s (85% of budget — still thin).
4. Reduced to 5 pairs/seed: **44.52 s (74% of budget)** — shipped.

**Seed count was never reduced** — all 100 checked-in seeds are exercised
every run (seed diversity is the divergence-finding power, per the policy's
own stated rationale; pair count is depth).

## Escalation to technical-director (recorded per policy, not silently absorbed)

The measurements above show the ceiling breach is **not primarily driven by
pair count** — reducing pairs 5x (50→10) only bought a ~3.35x speedup (not
5x), meaning a large, *fixed* per-seed cost dominates: building each 32x32x16
world (real terrain generation + the deterministic solid-fill pass), scanning
all ~16,384 cells for standability, and building one full `VillagerNavGraph`
over the entire region (an O(region size) cost, ADR-0007's own documented,
accepted cost model — not itself a defect). This fixed cost alone consumes
the large majority of the 60s budget at the AC's specified 32x32x16 world x
100 seeds, on this development machine.

**Consequence**: the shipped corpus runs at **5 pairs/seed (500 pairs, 1,000
verdicts)** rather than the AC's literal 50 pairs/seed (5,000 verdicts) — a
10x reduction in per-seed sampling depth, though full seed diversity (100
distinct checked-in seeds) is preserved. This is flagged here as requiring
technical-director attention per the story's own escalation clause. Options
if fuller AC36 fidelity (5,000 verdicts) is required going forward:
a faster/dedicated CI runner, a smaller per-seed world or seed count (both
AC-level changes, not this story's call to make unilaterally), or optimizing
the corpus's own world-generation/standable-scan fixture code specifically —
**never the production `BuildValidationReachability`/`VillagerNavGraph`
implementations under test**, since altering those to make the test faster
would risk masking the exact divergence this corpus exists to catch.

## Determinism (zero-flake policy, QA plan Content Requirement 3)

`test_corpus_two_consecutive_runs_produce_identical_verdict_sequences`
(3 representative seeds, run twice through the identical pipeline) passed —
byte-identical verdict sequences across both runs, confirming no
nondeterminism in world generation, `AStar3D` graph construction, or the BFS
trace.

## Full regression suite

`tests/run-tests.cmd` (headless GdUnit4, unit + integration): **1,198 test
cases, 0 errors, 0 failures, 0 flaky, 0 skipped, 0 orphans, exit code 0**,
total runtime 6 min 49 s. Includes all 7 tests in this story's own test file.

## Sign-off

Recorded by godot-gdscript-specialist during implementation of
build-validation-010, 2026-07-26. Runtime figures above are the actual
measured wall-clock from local headless runs (`Time.get_ticks_usec()` inside
the test, cross-checked against the GdUnit4 CLI's own reported per-test
duration) — not estimates.
