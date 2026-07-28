# Story 002: F1 decay, per-need state machine & edge-triggered urgent signal

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-26 — 1130/1130 suite green 0 orphans, agent-verified; parent re-verifies with the concurrent building-023)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md`
**Requirement**: `TR-needs-mood-system-030`, `TR-needs-mood-system-032`, `TR-needs-mood-system-033`, `TR-needs-mood-system-037`, `TR-needs-mood-system-048`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (Villager AI Execution & Threading) — primary for the consumption contract; ADR-0002 (all thresholds are config knobs)
**ADR Decision Summary**: Villager AI is a tick-driven plain explicit FSM that **polls** at its `decision_interval`; therefore Needs & Mood's queryable per-need state is the source of truth and the edge-triggered events are latency hints only — a missed event must be harmless. Needs state is not thread-safe and is never touched from a `Thread`/`WorkerThreadPool`.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Pure GDScript value math — no engine surface. Godot signal connections are synchronous by default; an emitted `need_urgent` reaches a connected Villager AI inside the same call stack, which is why the event can be a pure optimization over polling. Float comparisons are cross-tick **crossings** (`<=`/`>=` between the previous and current value), never equality checks.

**DOC PREREQUISITE — BLOCKING, and NOT this story's edit** (TD ruling **NM-6**,
`production/architecture-decisions-m02-preflight-2026-07-26.md` — **PROVISIONAL,
pending user ratification**): `has_urgent_need(villager_id: int) -> bool` currently
appears in **no** document under `docs/` or `design/` — only in landed code
(`neues-spiel/src/villager_ai/villager_ai.gd:474`, duck-typed `needs_provider`,
nil-safe `_has_urgent_need()` at line 1303, exercised by
`tests/unit/villager_ai/priority_decision_loop_test.gd`). The ruling requires it be
added to **`docs/architecture/architecture.md`** — Needs & Mood's "Exposes" row and
the API Boundaries signature block, alongside `start_recovery`/`stop_recovery` —
**before this story starts**. Owner: technical-director. Two follow-ups are *not*
blocking: the GDD query-API section + a TR of its own (GDD owner; the registry has
no TR covering it today), and `CONTRACTS.md` **when the module lands**, not now
(adding a signature block for an unimplemented module would break that file's own
charter — the TD deliberately made no `CONTRACTS.md` edit).

**Control Manifest Rules (this layer)**:
- Required (Feature): tick-driven via Time & Tick's signal, never raw delta; consumers poll authoritative state and never trust an event alone.
- Required (Foundation): every threshold read from the config resource; never write a config field at runtime.
- Forbidden: `Thread`/`WorkerThreadPool` anywhere near needs state; a second event-emission path that can fire without a state change.
- Guardrail: the per-tick decay pass is O(villagers × active needs) with a population ceiling of 20–30 — no per-frame work, no allocation per tick.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] **AC1**: Given a need at 100 and no recovery, When 1 tick fires, Then the value decreases by exactly `decay_per_tick` (F1: `value ← max(0, value − decay_per_tick[need])`). [TR-needs-mood-system-030]
- [ ] **AC2**: Given a need below `decay_per_tick`, When a tick fires, Then the value clamps to exactly 0 and stays there. [TR-needs-mood-system-030]
- [ ] **AC3**: Given a need decaying across `urgency_threshold`, When the downward cross occurs, Then exactly one "need urgent" signal is emitted (edge-triggered). [TR-needs-mood-system-033]
- [ ] **AC4**: Given a need parked exactly at the threshold for many ticks, When ticks fire, Then no additional signals are emitted (Edge Case 4 — crossing, not equality). [TR-needs-mood-system-033]
- [ ] **AC5**: Given a need at 0 for many ticks, When ticks fire, Then no repeated urgent signals are emitted (Edge Case 2). [TR-needs-mood-system-033]
- [ ] **AC6**: Given a need at 0 for many ticks, When ticks fire, Then no signal, event, or state change beyond the sustained clamp occurs — "harms nothing" is literal (Core Rule 5, no death spiral). [TR-needs-mood-system-037]
- [ ] **AC7**: Given no recovery and default values, When decaying from 100, Then the urgent signal fires after exactly `ceil((100 − 25) / 0.07) = 1072` ticks — a **tick count**, never a wall-clock assertion. [TR-needs-mood-system-030]
- [ ] **AC12**: Given no recovery-activity report from Villager AI, When a need sits below `urgency_threshold` for many ticks, Then it never enters Recovering — recovery cannot self-trigger from value alone. [TR-needs-mood-system-048]
- [ ] A **queryable** per-need state (`Satisfied` / `Urgent` / `Recovering` + current value) is exposed and is the documented source of truth; `Satisfied → Urgent` on the downward cross, and Urgent keeps decaying until a recovery report arrives. [TR-needs-mood-system-032] [TR-needs-mood-system-048]
- [ ] The module exposes the landed Villager AI seam verbatim: `has_urgent_need(villager_id: int) -> bool`, plus `get_need_value(villager_id, need) -> float` and the per-need state query — an unknown villager id answers "no urgent need" without erroring. [TR-needs-mood-system-032]
- [ ] **NM-6 (canonized)**: `has_urgent_need(villager_id: int) -> bool` returns the **queryable Urgent state** and is a **required** part of this module's public query API — *in addition to* the GDD's documented query surface, not a replacement for it. It answers from state, never from a cached event.
- [ ] **NM-6 — it must be a PURE query**: no signal emission, no state mutation, and **no lazy-initialisation of a villager's need record as a side effect of being asked**. It is polled from the FSM's decision point every tick (ADR-0008). Asserted, not assumed.
- [ ] **NM-6 — nil-safety stays on the consumer side**: do **not** add a null-provider branch here. `VillagerAi._has_urgent_need()`'s existing guard is the correct and already-tested location.

---

## Implementation Notes

*Derived from ADR-0008/0002 Implementation Guidelines:*

- **State is truth, events are hints.** Emit `need_urgent(villager_id, need)` on the downward cross, but every query path must be answerable with zero events ever delivered — this is what makes Save/Load's state re-derivation (story 012) and a dropped connection harmless.
- Crossing detection compares the **pre-tick** value to the **post-tick** value against the threshold. A value that starts at or below the threshold and stays there produces no event, ever — that is AC4/AC5 in one rule.
- `has_urgent_need(villager_id) -> bool` exists because `neues-spiel/src/villager_ai/villager_ai.gd` already calls exactly that on its nil-safe, duck-typed `needs_provider` seam (`_has_urgent_need()`). Match the name and arity exactly or the landed FSM cannot be un-mocked in story 010. It answers from the queryable state (`Urgent`), never from a cached event.
- Recovering is entered **only** by story 003's `start_recovery` report. This story wires the state enum and proves the negative (AC12); the transition itself lands in 003.
- No per-tick allocation: iterate a preallocated per-villager need array/dictionary; the population ceiling is 20–30.
- Do not special-case 0: the clamp in F1 is the whole of "no death spiral" (AC6). No damage hook, no fail-state, no extra signal.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: `start_recovery`/`stop_recovery`, the source→rate table, F2, and the "need satisfied" event.
- Story 005: mood, `mean_active`, and band events.
- Story 008: burst ordering, pause, warp, and the full-cycle 1072/1212 anchor test.
- Story 009: whether 0.07 is still the right decay at `ticks_per_second = 4.0`.

---

## QA Test Cases

- **AC1**: Given `value = 100.0`, `decay_per_tick = 0.07`, When 1 tick fires, Then `value == 99.93` exactly (float-compare with the same arithmetic, not a re-derived literal).
- **AC2**: Given `value = 0.03` and `decay_per_tick = 0.07`, When a tick fires, Then `value == 0.0`; When 10 further ticks fire, Then `value == 0.0` still.
- **AC3**: Given `value = 25.04` decaying at 0.07, When ticks fire until the value crosses 25, Then exactly one `need_urgent` emission is observed and the state reads `Urgent`.
- **AC4**: Given `value` set to exactly 25.0 with decay temporarily 0, When 20 ticks fire, Then zero emissions.
- **AC5**: Given `value = 0.0`, When 50 ticks fire, Then zero emissions and state remains `Urgent`.
- **AC6**: Given `value = 0.0`, When 50 ticks fire, Then no state change, no mood-independent side effect, and no error is pushed.
- **AC7**: Given `value = 100.0` at defaults, When ticks are dispatched one at a time, Then the single `need_urgent` emission is observed on tick **1072** exactly (boundary: nothing on 1071, nothing again on 1073).
- **AC12**: Given `value = 10.0` and no recovery report, When 100 ticks fire, Then the state never reads `Recovering` and the value keeps decaying to the 0 clamp.
- **Seam**: Given a villager whose sleep need is Urgent, When `has_urgent_need(id)` is called, Then true; Given a Satisfied villager, Then false; Given an unknown id, Then false with no error.
- **Seam purity (NM-6)**: Given any villager id — known, unknown, or never spawned — When `has_urgent_need(id)` is called N times, Then zero signals are emitted, no need record is created or mutated, and the module's full state is byte-identical before and after.
- Edge cases: a need whose decay would carry it from above the threshold to below in a single tick still emits exactly once; two needs on one villager cross independently.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/needs_mood/decay_state_machine_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (config, schema, tick subscription)
- Unlocks: 003, 005, 006, 008
