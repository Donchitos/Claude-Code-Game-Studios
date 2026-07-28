# Story 010: F2 job selection (nearest-reachable, bounded candidates)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 740/740 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-053`, `TR-villager-ai-behavior-076`, `TR-villager-ai-behavior-077`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding)
**ADR Decision Summary**: F2 selects `argmin(path_length_cells)` over available reachable jobs. Candidates are pre-filtered to the nearest `job_candidate_count` (default 5) by Chebyshev distance; only those are true-path checked; on failure the next round is tried up to `max_selection_candidates` (default 15). Worst-case pathfinds per pass are bounded at 15 per villager — never a full-queue pathfind.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: Uses AStar3D true-path checks (Story 007) for the reachability/length of each candidate. Determinism is a coding-standard requirement — same result every run.

**Control Manifest Rules (this layer)**:
- Required (Feature): `max_selection_candidates = 15` per-villager F2 budget; Chebyshev pre-filter rounds; never a full-queue pathfind.
- Forbidden: ranking gated on reachability (reachability is discovered lazily at selection time, never a gate on the ranking itself); non-deterministic tie-breaks.
- Guardrail: bounds worst-case pathfinds per pass at 15 per villager.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] Given multiple available jobs, selection returns the nearest-by-true-path among the straight-line-nearest `job_candidate_count` candidates; ties break by older commit, then by lexicographic cell coordinates (y, then x, then z) for same-command ties — deterministic every run (AC6).
- [ ] Given all `job_candidate_count` nearest candidates fail the true-path check, the next `job_candidate_count` are evaluated in turn, deterministically, up to `max_selection_candidates` — never a full-queue pathfind (AC7).
- [ ] If all candidates within the cap fail, the villager falls through the priority list for this pass (delegated to Story 006/011 handling); `unreachable_retry_ticks` governs later re-attempts.
- [ ] "Available" means queue-non-empty — reachability is discovered lazily at selection time, never a gate on the ranking itself.

---

## Implementation Notes

*Derived from ADR-0007 (Context/F2) Implementation Guidelines:*

- `chosen_job = argmin(path_length_cells)` over available reachable jobs; tie-break older commit → lexicographic (y,x,z) for same-command ties (all cells of one command share a commit timestamp; coordinates are a deterministic secondary key that exists for every cell).
- Pre-filter: nearest `job_candidate_count` by Chebyshev distance; true-path check only those; retry next round; hard cap `max_selection_candidates`.
- Return the chosen job (or "none reachable this pass") — claiming/attribution is Story 011.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: atomic claim, release, contention, attribution.
- Story 009: the travel to the selected job.

---

## QA Test Cases

- **AC6**: Given multiple jobs, When selecting, Then the true-path-nearest among the Chebyshev-nearest `job_candidate_count` is chosen; ties → older commit → lexicographic (y,x,z), deterministic across two runs.
- **AC7**: Given the first `job_candidate_count` candidates all fail reachability, When selecting, Then the next round is tried deterministically, never a full-queue pathfind; assert pathfind attempts ≤ `max_selection_candidates`.
- Edge cases: exactly `max_selection_candidates` candidates all fail → fall-through; queue-non-empty but all unreachable.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/villager_ai/job_selection_f2_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 007 (AStar3D true-path queries)
- Unlocks: 011
