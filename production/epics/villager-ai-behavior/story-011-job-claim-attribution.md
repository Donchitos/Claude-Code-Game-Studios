# Story 011: Job claim/release pipeline with worker attribution

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 749/749 suite green, parent-verified)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-051`, `TR-villager-ai-behavior-052`, `TR-villager-ai-behavior-055`, `TR-villager-ai-behavior-081`, `TR-villager-ai-behavior-097`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary (worker attribution); ADR-0008 (stable-order contention)
**ADR Decision Summary**: Worker attribution — `on_job_claimed(project_id, villager_id)` records `worker_ids` on the project (read/display + save state, never a control channel). This GDD supplies the villager id on the claim record; the Building System owns the aggregate `worker_ids` field.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Same-tick claim contention resolves in stable villager processing order (deterministic). Atomic claim = exactly one winner; loser proceeds to its next F2 candidate.

**Control Manifest Rules (this layer)**:
- Required (Core): Worker attribution — `on_job_claimed(project_id, villager_id)` records `worker_ids` on the project; attribution is read/display + save state, never a control channel. Built cells mutate ONLY via worker-executed jobs.
- Forbidden: a villager holding more than one job; job-vs-job re-selection against a held claim (sticky); attribution used as a control channel.
- Guardrail: claim contention resolved deterministically by stable villager order.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] One job (one blueprint cell) per villager at a time; claiming locks the job — no other villager may claim it until released (Rule 4).
- [ ] Given a claimed job, another villager's claim attempt fails atomically and the loser selects its next candidate (AC8). Same-tick contention winner is the earlier villager in stable processing order (Edge Case 3).
- [ ] Given pathing to a claimed job fails, it is reported to the Building System, the claim is released, and the next candidate is tried (AC9, Rule 6).
- [ ] Given an unreachable job, a retry attempt occurs after `unreachable_retry_ticks` (AC10). Given every available job reports unreachable in a pass, the villager falls through to Wandering — never stuck in Deciding — and retries resume on cadence (AC11).
- [ ] Claims are sticky: a claimed job is abandoned only via need-preemption, revocation, or pathing failure (no argmin oscillation mid-travel).
- [ ] On a successful claim, the claiming villager's id is recorded on the claim record and retrievable for the Building System's project `worker_ids` aggregation (AC58, TR-097).
- [ ] Two villagers with simultaneous urgent sleep targeting the same unowned reachable bed: exactly one succeeds atomically (winner by stable order); the loser falls back per Rule 12 (AC43 — bed-claim contention shares this atomic mechanism).

---

## Implementation Notes

*Derived from ADR-0016/0008 Implementation Guidelines:*

- Claim locks the job; release returns it to the Building System's queue exactly as Rule 6's unreachable flow (a single release path reused by watchdog rescue and seal-prevention refusal later).
- `on_job_claimed(project_id, villager_id)` supplies the id; do not own the `worker_ids` aggregate (Building System owns it).
- Unreachable-report → Building System turns the ghost orange (its Edge Case 5); this GDD owns the `unreachable_retry_ticks` cadence.
- Reuse the same atomic-claim primitive for bed ownership contention (Story 018 consumes it).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 010: F2 candidate ranking that feeds the claim.
- Story 012: on-site work progress after claiming.
- Story 018: bed ownership semantics (reuses the atomic-claim primitive).

---

## QA Test Cases

- **AC8**: Given a claimed job, When another villager claims it, Then the second claim fails atomically and the loser selects its next candidate.
- **AC (Edge Case 3)**: Given two villagers racing the same job in one tick, Then the stable-order-earlier villager wins deterministically across runs.
- **AC9/AC10/AC11**: unreachable → report + release + next candidate; retry after `unreachable_retry_ticks`; all-unreachable → fall through to Wandering, retries on cadence.
- **AC58**: Given `claim_job` succeeds, When the claim record is inspected, Then the claiming villager's id is recorded and retrievable for `worker_ids` aggregation.
- Edge cases: sticky claim not re-selected on periodic re-eval; bed-claim contention (AC43) via the same primitive.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/villager_ai/job_claim_attribution_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 010 (F2 selection), 006 (priority loop / fall-through)
- Unlocks: 012, 015, 016, 018
