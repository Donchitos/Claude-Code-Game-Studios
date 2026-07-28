# Story 025: Performance stress validation (30-villager)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 843/843 blocking suite green + 5/5 advisory perf suite, parent-verified; worst per-tick 3.02ms @30 villagers)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-041`, `TR-villager-ai-behavior-047`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (Villager AI Execution) — primary; ADR-0007 (AStar3D at scale)
**ADR Decision Summary**: The staggering design (per-tick budget) is what the 30-villager stress case measures. AC39 is an Advisory/Performance criterion gated at VS/Full-Vision milestones — not part of the Logic gate. The pre-VS spike (perf-spike-qq3) already PASSED at ADR-ceiling scale; this story validates the same envelope against production code.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: The stress case is a synthetic 30-villager scenario (unreachable-job-dense + parallel construction write-storm at 3x warp), plus synchronized mass-Deciding spikes (Rule 10c stagger under test), Breather step-away/bed-drift pathing costs, and Rule 10b's widened all-movement re-path filter scope. Watch-item: one Deciding pass measured avg 11 ms / p95 35 ms (GDScript stand-in).

**Control Manifest Rules (this layer)**:
- Required (Feature): frame budget must hold at 1x AND warp at the 20–30 population ceiling with `max_deciding_per_tick` staggering active.
- Forbidden: shipping without exercising the stress envelope (cheap insurance against a structural flaw surfacing after Alpha content lands).
- Guardrail: budget = 16.6 ms; property corpus ≤ 60 s CI (milestone quality gate).

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] Given the Vertical Slice population (~5) and the Full Vision ceiling (30), when simulating at 1x and 3x warp, the 16.6 ms frame budget is maintained — Advisory/Performance, enforced at those milestones, never a blocker for MVP Done (AC39).
- [ ] The stress harness exercises: unreachable-job-dense selection, a parallel construction write-storm, synchronized mass-Deciding spikes (stagger under test), Breather step-away + bed-drift pathing, and the widened all-movement re-path filter.
- [ ] The measured envelope (p95 frame time) is recorded against production code for comparison to the pre-VS spike baseline.

---

## Implementation Notes

*Derived from ADR-0008/0007 Implementation Guidelines:*

- Build the synthetic 30-villager stress scenario as a repeatable harness; run at 1x and 3x.
- Assert the staggering keeps per-tick Deciding cost bounded; record p95 frame time.
- This is Advisory — a FAIL informs the `max_deciding_per_tick` re-tune (Story 022) and the named threading escape hatch, not an MVP-blocking gate.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 022: the config re-tune the measurement informs.
- The pre-VS spike itself (already done — this validates against production code).

---

## QA Test Cases

- **AC39** (Advisory/Performance, milestone-gated): Given ~5 and 30 villagers at 1x and 3x, When the stress harness runs, Then p95 frame time ≤ 16.6 ms; record the envelope.
- Edge cases: unreachable-dense selection; write-storm at 3x; synchronized mass-Deciding; Breather/bed-drift pathing under load.

---

## Test Evidence

**Story Type**: Integration (Advisory/Performance)
**Required evidence**: `tests/performance/villager_ai/stress_30_villager_test.gd` + a recorded envelope in `production/qa/evidence/villager-ai-stress-evidence.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 005 (scheduler), 009 (travel/re-path), 012 (build cycle) — needs an integrated build
- Unlocks: informs 022 (re-tune)
- **ADVISORY**: milestone-gated performance criterion, not part of the Logic gate; not an MVP-Done blocker.
