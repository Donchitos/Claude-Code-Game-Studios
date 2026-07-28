# Story 006: Activity priority decision loop

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 546/546 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-049`, `TR-villager-ai-behavior-050`, `TR-villager-ai-behavior-052`, `TR-villager-ai-behavior-066`, `TR-villager-ai-behavior-082`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (Villager AI Execution & Threading Strategy)
**ADR Decision Summary**: Plain explicit FSM with a strict, discrete priority order (Urgent need > Work > Idle/Wander) implemented directly as `match`/priority checks — not scored, not a tree.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Needs & Mood values are mocked at the "need is urgent" boundary per testing standards — these ACs do not wait for that GDD. Tick-driven; Deciding must be instantaneous (no visible pause).

**Control Manifest Rules (this layer)**:
- Required (Feature): AI is a plain explicit FSM — strict discrete priority (Urgent need > Work > Idle/Wander); tick-driven.
- Forbidden: continuous scoring / behavior-tree structure; job-vs-job re-selection against a held claim.
- Guardrail: Deciding runs inside the staggered budget (Story 005) — instantaneous per villager.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] Given an urgent need and an available job, deciding chooses the need (AC1).
- [ ] Given an available job and no urgent need, the job is chosen over wandering (AC2).
- [ ] Given no jobs and no urgent needs, the villager wanders — indefinitely, no error (AC3, delegates target to Story 019).
- [ ] Given a Working villager whose need becomes urgent, the `decision_interval` re-check completes the current tick's work, releases the claim, and pursues the need — graceful preemption (AC4).
- [ ] Given a Working villager with no urgent need, the `decision_interval` re-check keeps it Working with no state change and no job re-selection — the periodic re-check is a preemption check, never an implicit interruption; claims are sticky (AC41). No job-vs-job re-selection mid-travel.
- [ ] Given any activity ends, the next state is assigned before any further tick is processed — the tick counter does not increment between activity-end and state assignment within one `decide()` (AC5).
- [ ] Urgent need firing while already Traveling to satisfy that same need is a no-op (Edge Case 3b).

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

- Priority list is literally: 1) urgent need (level below urgency threshold — mocked value; MVP sleep only), 2) available construction job (queue non-empty; reachability discovered lazily at F2 selection, Story 010), 3) idle/wander.
- Re-evaluate on activity completion, on interruption, and every `decision_interval` ticks.
- Claim stickiness: periodic re-eval never re-runs job selection against a held claim — a claimed job is abandoned only via need-preemption, revocation, or pathing failure.
- Preemption is graceful: finish the current cell's in-progress tick, then release the claim.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 010: F2 job selection ranking.
- Story 018: sleep/home behaviour; Story 019: wander target selection.

---

## QA Test Cases

- **AC1/AC2/AC3**: priority ordering across the three tiers (need > work > wander), with a mocked urgent-need boundary.
- **AC4**: Given Working + need becomes urgent, When `decision_interval` fires, Then current tick's work completes, claim releases, need pursued.
- **AC41**: Given Working + no urgent need, When the re-check fires, Then no state change, no job re-selection (claim sticky).
- **AC5**: assert the tick counter does not increment between activity-end and state assignment in one decide().
- Edge cases: 3b no-op when already traveling to the same need.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/villager_ai/priority_decision_loop_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 005 (Deciding scheduler + eligibility triggers)
- Unlocks: 009, 011, 018, 019, 020, 021, 025
