# Story 005: Worker attribution on job claim

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 766/766 suite green, parent-verified)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-109` (attribution half)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0007 (AI Pathfinding/job execution) — secondary
**ADR Decision Summary**: When a villager claims a project's job, the claim records the villager id; the project exposes `worker_ids` aggregating its builders. Attribution is read/display + save state, never a control channel.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (Integration seam with Villager AI; ADR-0016 knowledge risk LOW)
**Engine Notes**: Public surface `on_job_claimed(project_id: int, villager_id: int) -> void` per ADR-0016 Key Interfaces. Villager AI feeds this (villager-ai TR-097); the mechanic itself is Villager AI's, the recording contract is this system's.

**Control Manifest Rules (this layer — Core)**:
- Required: `on_job_claimed(project_id, villager_id)` records `worker_ids` on the project; attribution is read/display + save state, never a control channel.
- Forbidden: attribution must never gate or influence job scheduling, claiming, or lifecycle transitions (not a mechanical gate).
- Guardrail: `worker_ids` is a small per-project list — negligible against the frame budget.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC58 [PROVISIONAL — Villager AI]: GIVEN a villager claims a job on a BUILDING project's cell, WHEN the claim registers, THEN the villager's id is recorded on that cell and rolled up onto the project's worker-attribution record, queryable by Building UI (Rule 12/14f — the claim mechanic is Villager AI's, the recording contract is this system's). [TR-109]
- [ ] `worker_ids` is exposed as a queryable, display-only fact and is included in `serialize()` (contract shape only — full save flow is VS-tier). [TR-109]

---

## Implementation Notes

*Derived from ADR-0016 Decision §4 + building-system Rule 14f, TR-109:*

- Implement `on_job_claimed(project_id, villager_id)`: record the claiming villager against the cell and roll up onto the project's `worker_ids` (de-duplicated aggregate of builders).
- Attribution is display + save state only — it must never become a control channel (no scheduling/claiming/lifecycle behavior may branch on it).
- Recording contract is this system's; the claim mechanic (path → arrive → claim) is Villager AI's — test this story's half with a mocked claim call (mirrors AC20's mocked-job pattern), and mark the full claim→build→report cycle PROVISIONAL pending the Villager AI integration.
- On merge (Story 003), absorbed projects' worker records carry into the surviving project id.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- The villager claim/path/arrive mechanic — Villager AI's domain (integration verified once that GDD lands).
- Building UI's rendering of the worker list — building-ui's domain.
- Full save/load round-trip — VS-tier (this story only guarantees the `serialize()` contract shape).

---

## QA Test Cases

**AC58 — attribution recording (mocked claim)**
- Given: a BUILDING project with an eligible cell.
- When: `on_job_claimed(project_id, villager_id)` is invoked (mocked claim).
- Then: `villager_id` is recorded against the cell and appears in the project's `worker_ids` aggregate.
- Edge cases: the same villager claiming two cells appears once in the de-duplicated `worker_ids`; two villagers on distinct cells both appear; attribution never blocks a subsequent claim.

**Attribution is not a control channel**
- Given: a project with recorded `worker_ids`.
- When: job scheduling / claiming / lifecycle transitions run.
- Then: no behavior branches on `worker_ids` — clearing/altering it changes no scheduling outcome.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/building_system/worker_attribution_test.gd` (mocked-claim unit-level test acceptable now; full claim→build→report cycle is PROVISIONAL pending Villager AI).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (release + job eligibility).
- Unlocks: Building UI Projects Panel (worker display); feeds serialization contract.
