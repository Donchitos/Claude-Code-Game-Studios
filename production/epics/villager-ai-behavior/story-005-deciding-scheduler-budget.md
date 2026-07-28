# Story 005: Deciding scheduler — FIFO queue + max_deciding_per_tick budget

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 538/538 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-013`, `TR-villager-ai-behavior-047`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (Villager AI Execution & Threading Strategy)
**ADR Decision Summary**: Deciding-pass staggering via a per-tick budget (`max_deciding_per_tick`, spike-tuned initial value 1) and a stable-order FIFO `Array[int]` queue. The budget caps how many NEW passes START per tick, never interrupts an in-progress pass. No threading for MVP/VS.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Tick-driven via Time & Tick's signal (base tick rate 4.0 ticks/sec — more Deciding passes fire per second than at earlier rates, but the per-tick budget still bounds them). Keep the queue an `Array[int]` (not `PackedInt32Array` — 4.7 changed packed-array element-assignment semantics). Zero `Thread`/`WorkerThreadPool` in Villager AI.

**Control Manifest Rules (this layer)**:
- Required (Feature): Deciding staggering — FIFO `Array[int]` queue + `max_deciding_per_tick` budget (config knob, spike-tuned initial 1); budget caps new passes STARTED per tick, never interrupts an in-progress pass; dequeue in stable villager order.
- Forbidden: `Thread`/`WorkerThreadPool` in Villager AI (grep-verifiable); a behavior tree / utility-AI addon.
- Guardrail: bounds worst-case per-tick Deciding cost to `max_deciding_per_tick` villagers' F2 selection regardless of how many become eligible simultaneously; frame budget must hold at 1x AND warp (spike: p95 16.7 ms at 3x with budget = 1).

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] When more villagers than `max_deciding_per_tick` become Deciding-eligible in one tick, only the budgeted count run a Deciding pass that tick; the rest remain queued in stable order and are processed FIFO on subsequent ticks.
- [ ] A villager already mid-Deciding-pass is never interrupted by the next tick's budget check — the budget caps passes STARTED, not pass duration.
- [ ] Villager order within the stagger follows the stable processing order (villager index) for determinism (Rule 10c / Edge Case 3 convention).
- [ ] Under a tick burst of `max_ticks_per_frame`, at most one decision re-evaluation occurs per processed tick, in order (AC36).
- [ ] Deciding is instantaneous within a tick — never a visible "stand and think" pause (AC5 supports; state assignment before any further tick).

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

- `var _deciding_queue: Array[int] = []`; enqueue maintains stable villager order.
- `_on_tick()`: `var budget := config.max_deciding_per_tick; while budget > 0 and not _deciding_queue.is_empty(): _run_deciding_pass(_deciding_queue.pop_front()); budget -= 1`.
- The pass body (F2 selection, priority list) is Story 006/010 — this story owns the queue + budget mechanics and the eligibility enqueue triggers (need-urgent, job-complete, `decision_interval` elapsed).
- Keep `max_deciding_per_tick` a config knob (ADR-0002); the production re-tune is Story 022.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: the priority-list logic inside a Deciding pass.
- Story 022: the production re-tune of `max_deciding_per_tick` (coordinated with time-tick).

---

## QA Test Cases

- **AC (budget)**: Given N > `max_deciding_per_tick` villagers enqueued in one tick, When the tick fires, Then exactly `max_deciding_per_tick` run a pass, the rest stay queued in stable order, and run on later ticks.
- **AC (no mid-pass interruption)**: Given a villager mid-pass, When the next tick's budget check runs, Then the in-progress pass is not interrupted.
- **AC36**: Given a burst of `max_ticks_per_frame` ticks, When processed, Then ≤ 1 decision re-evaluation per processed tick, in order.
- Edge cases: budget = 1 (spike default); empty queue; enqueue order preserved across ticks.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/villager_ai/deciding_scheduler_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (scaffold/config + FSM enum)
- Unlocks: 006, 022
