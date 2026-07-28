# Story 012: On-site work & full claim→build→report cycle

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 758/758 suite green, parent-verified — SPRINT 7 CROWN: closed job loop, milestone criterion #2 met; resolves building-030 AC21/AC36b)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-054`, `TR-villager-ai-behavior-029`, `TR-villager-ai-behavior-083`, `TR-villager-ai-behavior-094`, `TR-villager-ai-behavior-095`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0009 (tick-boundary occupancy)
**ADR Decision Summary**: Built cells mutate only via worker-executed jobs. Work progress accrues only while the villager is on-site; progress is tick-boundary credited. The full claim→travel→build→report cycle transitions the cell to Built via the Building System's write and removes the job from the queue.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: On-site = target cell or an orthogonally-adjacent cell (incl. directly above/below). First progress increment is credited at the next tick boundary, never partial. Uses real Building System components in the integration test (both GDDs Designed — no playtest-doc fallback).

**Control Manifest Rules (this layer)**:
- Required (Core): Built cells mutate ONLY via worker-executed jobs; the Planned→Built write is the Building System's, gated by seal-prevention (Story 016).
- Forbidden: crediting partial-tick work progress; work progress off-site.
- Guardrail: per-villager burst rule per Building F3.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] Given a villager not in the target or an orthogonally adjacent cell, no work progress accrues; given on-site, it accrues (AC12).
- [ ] Given arrival between two ticks, the first progress increment is credited at the next tick boundary, never partially (AC13).
- [ ] Given a real villager and one real queued blueprint cell, it claims → travels → accumulates ticks → the cell transitions to Built via the Building System's write, the job is removed from the queue, and the villager re-enters Deciding — the full claim→build→report cycle (AC40, closes Building AC21).
- [ ] Given a builder on-site with its target cell occupied and construction deferred, when the occupant vacates (F4, Story 013), the target cell becomes free and progress resumes on the next tick without re-claiming the job (AC40b).
- [ ] Given a job revoked mid-work (player undo/removal), the villager stops at the tick boundary, plays no failure reaction, and re-enters Deciding without error (AC33, Edge Case 4).

---

## Implementation Notes

*Derived from ADR-0016/0009 Implementation Guidelines:*

- On-site check reads discrete `current_cell`/body-column; work progress is applied via Building System F3 per tick while on-site.
- The Planned→Built write is issued by the Building System and must pass the seal-prevention gate (Story 016) — this story wires the cycle, Story 016 adds the gate.
- Job revocation clears claim bookkeeping via the revocation itself; the villager re-enters Deciding.
- Deferred-then-resumed: do not re-claim; resume progress once the target cell clears.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 013: the F4 vacate that frees a deferred cell.
- Story 016: the seal-prevention gate on the Planned→Built write.
- Story 018: dig on-site exclusion.

---

## QA Test Cases

- **AC12**: off-site → no progress; on-site (target or orthogonally adjacent incl. above/below) → progress accrues.
- **AC13**: arrival between ticks → first increment at next tick boundary, never partial.
- **AC40** (integration, real Building System): claim → travel → ticks → cell Built, job removed, villager re-enters Deciding.
- **AC40b**: occupied target deferred → occupant vacates → progress resumes next tick without re-claiming.
- **AC33**: job revoked mid-work → stop at tick boundary, re-enter Deciding, no error.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/villager_ai/build_job_cycle_test.gd` — must exist and pass (uses real Building System components).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 011 (claim/attribution), 009 (travel to site)
- Unlocks: 016, 018, 021, 025
