# Story 010: AC36 reachability property corpus (milestone criterion #2)

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-26 — 1198/1198 suite green 0 orphans, parent-verified; corpus shipped at 5 pairs/seed per its own Cut-Lever Policy, escalated to TD)
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-063`, `TR-build-validation-navigability-008`, `TR-build-validation-navigability-010`, `TR-build-validation-navigability-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding, Navigation & Room Analysis)
**ADR Decision Summary**: The two systems deliberately run **two different traversal algorithms over one shared rule set** — Villager AI's `AStar3D` shortest-path graph and Build Validation's own BFS. ADR-0007 names this as its accepted cost: *"two separate traversal implementations to maintain… though they share the predicates, which is the part that actually needed to be shared."* This corpus is the guard that the two do not silently diverge.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: `AStarGrid3D` does not exist in 4.7 — Villager AI's side is the manually-built `AStar3D` graph with deterministic bit-packed point IDs. The corpus must drive both real implementations, not a re-derivation of either. `VoxelWorldGrid` exposes a pure static terrain twin (`_pure_terrain_height` / `_pure_terrain_noise`) so seeded worlds are reproducible without a live grid.

**Control Manifest Rules (this layer)**:
- Required: both systems call the same `is_standable`/`is_step_legal`; Build Validation runs its own BFS and never touches the `AStar3D` instance.
- Forbidden: making the corpus pass by having one side call the other (that would delete the very divergence this test exists to detect); non-deterministic fixtures (no live RNG, no time-dependent assertions).
- Guardrail: **total corpus runtime ≤ 60 s in CI** — a hard milestone quality gate, not a soft target.

**Risk ownership**: this is M02 risk **R3** — *"the riskiest single test artifact in the MVP."*
Owner: technical-director. Sequenced early in Cluster A deliberately: a late
failure here means one of two **already-shipped** implementations is wrong.

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [x] **AC36 [Integration — property test]**: **GIVEN** the checked-in property-test corpus — a fixed list of **100 seeds** committed to `tests/integration/build-validation/`, each seed generating a bounded **32×32×16** world (documented generator: procedural terrain per Voxel World's formula + random wall/floor/roof placement at **10–40% solid-fill density**) and **50 sampled (start, target) pairs** drawn from that world's standable cells — **WHEN** this system's reachability verdict and Villager AI's pathfinder evaluate every pair, **THEN** all **5,000 verdicts agree**; any disagreement fails the test **naming the seed and pair**; total corpus runtime **≤ 60 s in CI**. [TR-063]
  **Implemented with the Cut-Lever Policy applied** (see `production/qa/evidence/build-validation-010-reachability-corpus-runtime-20260726.md`): the full 50-pairs/seed spec measured 183.55s (3x over the 60s ceiling; 5,000/5,000 verdicts agreed, zero disagreements — a pure performance breach). Per the story's own Implementation Notes, pairs were reduced (never seed count) to **5 pairs/seed (500 pairs, 1,000 verdicts)**, measuring 44.52s (74% of budget) — **escalated to technical-director** in the evidence doc, since the ceiling breach is dominated by fixed per-seed setup cost (world gen + standable scan + one full `VillagerNavGraph` build), not pair count, so full 5,000-verdict fidelity may need a faster CI runner or an AC-level change to land safely.
- [ ] The corpus guards **algorithmic divergence between the two independent implementations of the movement rules**, complementing AC24's constants-only check — the two sides must remain two implementations, never one calling the other. [TR-008]
- [ ] Generation parameters (seed list, world dimensions, fill density, pair count) are **test fixtures, not gameplay values** — they live with the test, never in a gameplay config resource.
- [ ] The corpus is deterministic: the same checked-in seed list produces the same 5,000 verdicts on every run, on every machine — no live RNG, no wall-clock dependence, no execution-order dependence.
- [ ] The measured CI runtime is **recorded as evidence**, not merely asserted — milestone criterion #2 requires a recorded runtime figure in `production/qa/evidence/`.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- Both sides must be the **real** implementations: Build Validation's BFS trace (story 004) and Villager AI's `AStar3D` path query. "Reachable" is the agreement axis — a path exists vs. the trace connects. Do not compare path *costs*; the systems answer different questions and only connectivity is contracted.
- Use `VoxelWorldGrid._pure_terrain_height` / `_pure_terrain_noise` for the terrain half so world generation is reproducible from a seed without booting residency I/O. A 32×32×16 world must fit inside the configured world bounds — set the test config explicitly rather than relying on production defaults.
- Sample (start, target) pairs only from cells that pass `is_standable`, per the AC wording ("drawn from that world's standable cells").
- Failure messages must name **the seed and the pair** — a corpus failure that only says "5000 verdicts, 1 mismatch" is unactionable across 100 seeds.
- **Time-box the performance work.** Per the milestone Cut-Lever Policy: if the 60 s ceiling is exceeded twice, **reduce sampled pairs per seed before reducing seed count** (seed diversity is the divergence-finding power; pair count is depth), then escalate to technical-director. Do not silently relax the ceiling and do not skip or disable the test.
- Costs cluster in `AStar3D` graph construction per world. Build the graph once per seed, run all 50 pairs against it, then discard — do not rebuild per pair.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the trace implementation itself.
- Story 002: AC24's constants-only verbatim-consumption check (this corpus complements it, does not replace it).
- The pre-VS performance spike for region-size cost (GDD Open Question 5b/5c) — a different measurement with a different owner.

---

## QA Test Cases

- **AC36 happy path**: Given the checked-in 100-seed corpus, When both implementations evaluate all 5,000 pairs, Then agreement is 100% and runtime ≤ 60 s.
- **Failure reporting**: Given an injected disagreement (a deliberately mutated predicate in a test double), When the corpus runs, Then it fails naming the exact seed and (start, target) pair.
- **Determinism**: Given two consecutive runs of the same corpus, When compared, Then the verdict sets are identical.
- **Fixture integrity**: Given the seed list file, When inspected, Then it contains exactly 100 seeds and is checked in (not generated at test time).
- **Runtime evidence**: Given a CI run, When it completes, Then the measured total runtime is captured to `production/qa/evidence/`.
- Edge cases: a seed producing a world with fewer than 50 standable cells (sampling must degrade deterministically, documented, not crash); a fully-solid or fully-empty seed at the density extremes.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `neues-spiel/tests/integration/build_validation/reachability_property_corpus_test.gd` — must exist and pass, with recorded runtime in `production/qa/evidence/`.

**Status**: [x] Created and passing — 7 tests, 0 failures, 0 orphans; runtime recorded in `production/qa/evidence/build-validation-010-reachability-corpus-runtime-20260726.md` (44.52s at the shipped 5-pairs/seed configuration; see that doc for the Cut-Lever Policy applied and the technical-director escalation).

---

## Dependencies

- Depends on: 004 (the reachability trace), 002 (candidate/standability predicate). Villager AI stories 002/007 are already Complete.
- Unlocks: milestone criterion #2. Runnable in parallel with 005–009.

