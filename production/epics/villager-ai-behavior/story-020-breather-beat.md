# Story 020: Breather beat (between-jobs rest)

> **Epic**: Villager AI & Behavior
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-057`, `TR-villager-ai-behavior-058`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (FSM Breather state)
**ADR Decision Summary**: After `jobs_before_break` consecutive completed jobs, the villager takes a Breather — a short non-productive beat before claiming another job. Work-claiming is suppressed for the duration; urgent needs still preempt normally. The Breather slots into Deciding between "job completed" and re-running priority tier 2 — it can only begin BETWEEN jobs, never mid-claim.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Duration runs on a dedicated ticks-since-entry counter, independent of `decision_interval`. Step-away target chosen by F4's selection with the just-finished cell as "requester" (reusing the deterministic rule; the target must be standable).

**Control Manifest Rules (this layer)**:
- Required (Feature): plain FSM state; step-away reuses F4's deterministic selection.
- Forbidden: beginning a Breather mid-claim; changing any need value (Breather is cosmetic-plus-pacing, no need effect).
- Guardrail: bounded by `breather_duration_ticks`.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] Given `jobs_before_break` consecutive completed jobs, when the last completes, the villager enters Breather (AC46a).
- [ ] Given an active Breather and available jobs, no job is claimed for the full `breather_duration_ticks` — claim suppression (AC46b).
- [ ] Given an active Breather and a mocked urgent need, the Breather is preempted normally — needs win (AC46c).
- [ ] Given a Breather with no preemption, when `breather_duration_ticks` elapse, the villager returns to Deciding and job-claiming resumes on the next Deciding pass (AC48).
- [ ] The step-away target uses F4's selection (just-finished cell as requester; target must be standable); environmental interruptions behave like Wandering's (walled-in → distress; sat-on block removed → stand in place, continue the Breather).
- [ ] The Breather can only begin BETWEEN jobs, never mid-claim; its duration runs on a dedicated ticks-since-entry counter, independent of `decision_interval`.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

- Slot the Breather check into Deciding between "job completed" and re-running priority tier 2.
- Suppress work-claiming for the duration; needs still decay and preempt.
- Reuse F4 (Story 013) for the step-away target with the just-finished cell as the requester.
- No need-value changes — this is pacing/flavor only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 013: the F4 selection reused for the step-away.
- Story 019: Wandering (a distinct idle state).

---

## QA Test Cases

- **AC46a**: `jobs_before_break` consecutive jobs → enter Breather on the last completion.
- **AC46b**: active Breather + available jobs → no claim for the full `breather_duration_ticks`.
- **AC46c**: active Breather + mocked urgent need → preempted normally.
- **AC48**: Breather elapses with no preemption → return to Deciding, claiming resumes next pass.
- Edge cases: cannot begin mid-claim; dedicated counter independent of `decision_interval`; sat-on block removed → stand in place, continue.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/villager_ai/breather_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 006 (priority loop), 012 (job-completion counter), 013 (F4 step-away)
- Unlocks: None
