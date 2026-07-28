# Story 004: Recovery interruption, mid-recovery re-rating & bed revocation

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-27 — 1250/1250 suite green 0 orphans, agent-verified; no production change needed, behavior proven to follow from story-003's design)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md`
**Requirement**: `TR-needs-mood-system-043`, `TR-needs-mood-system-058`, `TR-needs-mood-system-059`, `TR-needs-mood-system-060`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (the wake/report chain from Villager AI's FSM) — primary; ADR-0002 (rates stay config-driven through the re-rating)
**ADR Decision Summary**: Villager AI owns the wake behavior; this system only stops scoring. The revocation chain is explicit and non-circular: Building System emits its bed-revocation event to the owning villager → Villager AI wakes, dissolves ownership, and **itself** calls `stop_recovery` → this system stops. There is no direct Building → Needs signal.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Pure GDScript. Synchronous signal delivery is load-bearing: the revocation-driven `stop_recovery` must land before the same tick's F-pass, which is what makes "the removal tick credits zero recovery" literal rather than approximate.

**Control Manifest Rules (this layer)**:
- Required (Feature): the source enum is re-read every recovery tick — the stored source is a live value, not a start-time snapshot.
- Required (Feature): state transitions on interruption are decided purely by the **current value**, never by remembering how the recovery started.
- Forbidden: emitting a second "need urgent" event on a below-threshold interruption; restarting or resetting progress on a source change.
- Guardrail: re-rating costs one table lookup per recovering need per tick — no re-entry, no re-initialization.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] **AC30**: Given a need Recovering at the `bed_unsheltered` rate, When the reported source enum changes to `bed_sheltered` mid-recovery (a `shelter_status_changed` upgrade), Then from the **next tick** the full rate applies — no restart, no signal, no lost progress; **AND** the mirror downgrade applies the lower rate identically (Edge Case 11). [TR-needs-mood-system-043]
- [ ] **AC13**: Given a recovery interrupted between thresholds (e.g. value 60), When the interruption registers, Then the need re-enters `Satisfied`, decays normally, and re-triggers `Urgent` only at the next downward 25-cross (Edge Case 1, above-threshold branch). [TR-needs-mood-system-058]
- [ ] **AC31**: Given a recovery interrupted while the value is still at/below `urgency_threshold`, When `stop_recovery` lands, Then the need re-enters `Urgent` **by value**, **no second urgent event fires**, and the queryable state reads `Urgent` throughout (Edge Case 1, below-threshold branch). [TR-needs-mood-system-059]
- [ ] Bed removed mid-recovery (Edge Case 3): Given a villager Recovering from a bed source, When Villager AI calls `stop_recovery` in response to the Building System bed-revocation event, Then that tick credits **zero** recovery and the need lands in `Satisfied` or `Urgent` purely by its current value. This system performs no wake behavior and holds no bed reference. [TR-needs-mood-system-060]
- [ ] A source change carries **no** event of its own — consumers observe it only through the changed rate and the existing queryable state. [TR-needs-mood-system-043]

---

## Implementation Notes

*Derived from ADR-0008/0002 Implementation Guidelines:*

- Re-rating is a consequence of story 003's design, not a new mechanism: the recovery tick reads the *stored current* source each tick. This story adds the mutation path (`report_source_changed` / the source parameter being updated) and the tests that pin the semantics.
- "From the next tick" is literal: a source change landing during tick *N* (before the F-pass, per the intra-tick rule) takes effect on the pass it precedes only if it arrived before it — implement the change as a plain state write and let the ordering rule govern; do not add a one-tick delay.
- Exit state on `stop_recovery` is computed from the current value against `urgency_threshold` alone. Do not consult the pre-recovery state, and do not re-run cross detection — the below-threshold branch must **not** emit, because the original edge already fired and the state has read `Urgent` throughout.
- The `reason` argument of `stop_recovery` is diagnostic only (`&"woke"`, `&"revoked"`, `&"preempted"`). It must never change the arithmetic or the exit state — assert that in a test.
- This system never subscribes to `furniture_revoked` and never holds a bed id. If a future story tempts you to shortcut the chain, that is the circular punt the 2026-07-10 review explicitly closed.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the table, F2 arithmetic, and the satisfied cross.
- Story 007: the why-string that changes when the source changes.
- Villager AI: waking, bed-ownership dissolution, and re-entering Deciding (`villager-ai-018`).
- Build Validation: emitting `shelter_status_changed` (mocked here as a source-enum change).

---

## QA Test Cases

- **AC30 (upgrade)**: Given Recovering at `bed_unsheltered` with `value = 40.0`, When the source changes to `bed_sheltered` and one tick fires, Then the increment is `0.5 × 1.0`, the state is still `Recovering`, no signal was emitted, and the value retains all prior progress.
- **AC30 (downgrade)**: Given Recovering at `bed_sheltered`, When the source changes to `bed_unsheltered` and one tick fires, Then the increment is `0.5 × 0.7` with the same no-restart/no-signal guarantees.
- **AC13**: Given Recovering with `value = 60.0`, When `stop_recovery` lands, Then state reads `Satisfied`; When ticks fire, Then the value decays at F1; When it crosses 25 downward, Then exactly one `need_urgent` fires.
- **AC31**: Given Recovering with `value = 18.0` (at/below `urgency_threshold`), When `stop_recovery` lands, Then state reads `Urgent`, **zero** new `need_urgent` emissions are observed, and decay resumes.
- **Edge Case 3 (revocation)**: Given Recovering from `bed_sheltered`, When `stop_recovery(reason = &"revoked")` lands and the tick's F-pass then runs, Then the value is unchanged for that tick and the exit state matches the value rule.
- **Reason-independence**: Given identical values and timing, When `stop_recovery` is called with three different `reason` values, Then the resulting value and state are identical in all three runs.
- Edge cases: source changed twice within one tick — the last write before the F-pass wins; source changed on the same tick as the satisfied cross — the cross still fires exactly once; `stop_recovery` on the exact threshold value (25.0) resolves to `Urgent` (`<=` rule) with no emission.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/needs_mood/recovery_interruption_and_rerating_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003 (recovery API, table, F2)
- Unlocks: 010
