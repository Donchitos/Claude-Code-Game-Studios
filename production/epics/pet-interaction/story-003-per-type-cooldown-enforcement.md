# Story 003: Per-Type Cooldown Enforcement

> **Epic**: Pet Interaction
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2-3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-interaction.md`
**Requirement**: `TR-petinteraction-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: Pet Interaction Input Handling (§Decision 2).
**ADR Decision Summary**: ADR-0016 §Decision 2 rejects both a scheduled `dart:async Timer(duration, callback)` AND a Flame `TimerComponent`/frame-ticked timer for cooldown. Instead: two independent nullable `DateTime?` fields, one per `InteractionType` (`_lastTapAt`, `_lastSwipeAt`), each updated only when that type's gesture is actually emitted. Before emitting, compare `injectedNow().difference(lastInteractionOfThisType)` against that type's cooldown duration (tap 1.0s / swipe 2.0s) — a lazy comparison evaluated only when a new gesture is classified, never a running/scheduled timer. The ADR explicitly verified (and partially corrected) the GDD's own Edge Cases claim — see Engine Notes below.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM (per epic's overall risk rating; this story's specific timer-correctness risk is resolved by ADR-0016 — see below)
**Engine Notes**: The GDD's Edge Cases text ("cooldown timer chạy khi app minimize... qua Dart's `Timer`") has been verified against actual Flutter/Dart behavior in ADR-0016 §Decision 2: a Flame `TimerComponent` would be actively WRONG (it pauses with the game loop on background — the opposite of the GDD's intent, and an already-registered forbidden pattern per ADR-0007). A plain `dart:async Timer` would functionally achieve the GDD's stated intent (its deadline is wall-clock-based and unaffected by isolate freezing) but is still rejected in favor of a stored-timestamp/lazy-comparison approach, because: it adds a scheduled-callback code path with no benefit over a lazy comparison; it does not survive an OS process kill any better than a stored timestamp would (both simply reset on cold restart, which is harmless); and it diverges from this codebase's established injected-`now`/pure-comparison pattern (ADR-0005, Time & Decay) for the identical class of problem. **Do not implement a `Timer` of any kind for this story** — implement the stored-`DateTime`/lazy-comparison mechanism per ADR-0016 §Decision 2.

**Control Manifest Rules (this layer)**:
- Guardrail: 16.6ms/frame budget — the cooldown check is a cheap timestamp comparison, not a per-frame poll; do not implement via a Flame `update(dt)` tick if a simpler event-driven check suffices.

---

## Acceptance Criteria

*From GDD `design/gdd/pet-interaction.md`, scoped to this story:*

- [x] **AC-3**: GIVEN bé just tapped Mochi, WHEN bé taps again within 1000ms, THEN no event is emitted (cooldown active).
- [x] **AC-4**: GIVEN bé just swiped Mochi, WHEN bé swipes again within 2000ms, THEN no event is emitted.
- [x] **AC-5**: GIVEN tap cooldown is active but swipe cooldown has expired, WHEN bé swipes, THEN `InteractionType.swipe` is emitted normally (per-type cooldowns are independent).

---

## Implementation Notes

*Derived from ADR-0016 §Decision 2:*

- Two nullable `DateTime?` fields on the same component that hosts Story 001's classification logic: `_lastTapAt`, `_lastSwipeAt`. Neither is initialized (both start `null`, meaning "no cooldown active yet").
- Cooldown check happens in the same `_handleClassifiedGesture(InteractionType type)` method Story 001's `onDragEnd` calls into, BEFORE the `GameEventBus().emit(...)` call: `if (_lastXAt != null && now.difference(_lastXAt!) < cooldownDuration) return;` (early-return, no emit) — otherwise proceed to emit AND update `_lastXAt = now` in the same branch. Use `switch (type)` so each branch only ever touches its own field — this is what makes the two cooldowns independent (AC-5) without any extra code.
- **Boundary is inclusive of the cooldown duration itself**: the check is `difference < cooldownDuration` (strict less-than) → blocked; `difference >= cooldownDuration` → allowed. So a tap at exactly t=1000ms after a t=0 tap is NOT blocked (difference == 1000ms == cooldown, not `< 1000ms`) — it succeeds. This resolves the QA Test Cases' boundary question below.
- `now` is the same injected `DateTime Function()` clock Story 001 introduced on the component (constructor parameter, defaulting to `DateTime.now`) — do not call `DateTime.now()` directly inline; both stories' logic must read from the same single injected clock instance so tests can control time deterministically across both.
- GDD-stated values (Tuning Knobs section), unchanged by the ADR: `tap_cooldown` = 1000ms (safe range 300-3000ms), `swipe_cooldown` = 2000ms (safe range 500-4000ms).
- Cooldowns are per-type and independent — a tap cooldown does not gate a swipe attempt and vice versa (AC-5) — guaranteed structurally by the two-separate-fields design above, not by an extra independence check.
- Explicitly forbidden by ADR-0016: do not implement this via `Timer(cooldownDuration, callback)`, `Future.delayed`, or a Flame `TimerComponent`/`update(dt)` poll — see this story's Engine Notes above for why.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: the classification/emit logic this story's cooldown gates wrap around.
- Story 002: SLEEPING/PLEASED guards — orthogonal precondition, not a cooldown.

---

## QA Test Cases

*The developer implements against these — do not invent new test cases during implementation.*

- **AC-3**: GIVEN Mochi just received a tap (t=0) — When: a second tap arrives at t=500ms — Then: assert no `GameEvent` emitted. Edge cases: a tap at exactly t=1000ms succeeds (ADR-0016 §Decision 2: boundary is inclusive — `difference < cooldown` is the block condition, and 1000ms is not `< 1000ms`); a tap at t=1001ms should also succeed.
- **AC-4**: GIVEN Mochi just received a swipe (t=0) — When: a second swipe arrives at t=1500ms — Then: assert no `GameEvent` emitted. Edge cases: swipe at t=2001ms should succeed.
- **AC-5**: GIVEN a tap at t=0 (tap cooldown now active until t=1000ms) — When: a swipe arrives at t=200ms — Then: assert `InteractionType.swipe` IS emitted (swipe's own cooldown was never triggered, so it is not active).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pet-interaction/cooldown_enforcement_test.dart` — must exist and pass

**Status**: [x] Created — 12/12 tests passing (`cd src && flutter test ../tests/unit/pet-interaction/cooldown_enforcement_test.dart`)

---

## Dependencies

- Depends on: Story 001 (Gesture Classification & Event Emission)
- Unlocks: Story 004 (No-Mutation & Background/Foreground Resilience)

---

## Completion Notes

**Completed**: 2026-07-23
**Criteria**: 3/3 passing (AC-3, AC-4, AC-5, including all QA Test Cases' stated boundary edge cases)

### Test-Criterion Traceability

| Criterion | Test | Status |
|-----------|------|--------|
| AC-3 (second tap within 1000ms → blocked) | `test_AC3_second_tap_at_500ms_within_1000ms_tap_cooldown_is_blocked` | COVERED |
| AC-3 (blocked attempt does not reset the timestamp) | `test_AC3_a_blocked_tap_attempt_does_not_reset_the_stored_cooldown_timestamp` | COVERED |
| AC-3 edge (boundary, exactly 1000ms → succeeds, inclusive) | `test_AC3_boundary_tap_at_exactly_1000ms_after_first_tap_succeeds` | COVERED |
| AC-3 edge (1001ms → succeeds) | `test_AC3_tap_at_1001ms_after_first_tap_succeeds` | COVERED |
| AC-4 (second swipe within 2000ms → blocked) | `test_AC4_second_swipe_at_1500ms_within_2000ms_swipe_cooldown_is_blocked` | COVERED |
| AC-4 edge (2001ms → succeeds) | `test_AC4_swipe_at_2001ms_after_first_swipe_succeeds` | COVERED |
| AC-5 (tap cooldown active does not gate an independent swipe) | `test_AC5_tap_cooldown_active_does_not_gate_an_independent_swipe_attempt` | COVERED |
| Cooldown decision logic (pure, no Flame) — boundary math, null-lastAt, per-duration independence | 5 tests in `cooldownElapsed (pure logic)` group | COVERED |

### Deviations (documented, non-blocking)

1. **Nested review agents (flame-specialist, qa-tester) did not return in time via passive wait; both were recovered by actively reconnecting to their agent IDs mid-task rather than idling on a notification.** This matches a known failure mode already flagged by prior agents in this pipeline. Final verdicts obtained (see Code Review below) — this is a process note, not a scope deviation.
2. **qa-tester's review surfaced a real cross-story architecture question, escalated rather than fixed here.** Story 002's PLEASED Triggered State (2.0s, type-agnostic — triggered on every successful `petInteracted`, tap or swipe) blocks any subsequent interaction attempt for its full 2.0s duration. Since this exceeds Story 003's 1.0s tap cooldown, on an ordinary single wall-clock gameplay timeline the tap-cooldown "succeeds at ≥1000ms" scenario (AC-3) and the "swipe succeeds while tap cooldown is active" scenario (AC-5, tested at t=200ms) are, in practice, still gated by the still-active PLEASED guard rather than becoming reachable purely because the tap cooldown itself has elapsed. This story's own cooldown mechanism is implemented correctly and verified in isolation exactly per ADR-0016 §Decision 2 (independently unit-tested via the new `cooldownElapsed (pure logic)` group, with no Flame/PLEASED involvement at all) — the composed real-gameplay interaction with Story 002's guard is a legitimate, separate architecture/product question that neither story is authorized to resolve unilaterally (Story 002 is explicitly out of this story's scope, and is already Complete). Flagged as a follow-up task for a design/architecture ruling (options: accept PLEASED's 2.0s as the de facto unified interaction cooldown; scope the PLEASED guard to the same interaction type only; or revisit tuning) rather than silently fixed or hidden. The test file's `_emitThenDrainPleased`/`_advance` helpers make this explicit in comments — they deliberately decouple Flame-tick time from the wall-clock `fakeNow` axis to isolate and prove the cooldown mechanism specifically, which is what ADR-0016's own Requirements section calls for ("trivially unit-testable without a real clock or a real Flame game loop").
3. **`cooldown_policy.dart` is a new pure-logic file**, not an addition to the existing `interaction_guard.dart` — kept as its own file (mirroring `interaction_guard.dart`'s own one-decision-per-file precedent) since it is a distinct decision (cooldown vs. mood/triggered-state guard) with its own signature, matching ADR-0016's own Key Interfaces snippet for `cooldownElapsed` verbatim.

**Test Evidence**: Logic — `tests/unit/pet-interaction/cooldown_enforcement_test.dart`, 12/12 passing.
**Code Review**: Complete — flame-specialist: **APPROVED** (no Required Changes; 2 non-blocking suggestions: AC checkboxes needed updating on story close — done above; an optional standalone `cooldownElapsed` pure-function test — added above). qa-tester: **INCOMPLETE → addressed** (1 Required Change, which was an escalation ask rather than a code defect — see Deviation 2 above and the spawned follow-up task; 2 suggestions — both implemented: the standalone `cooldownElapsed` pure-logic test group, and the blocked-attempt-does-not-reset-timestamp test).
**Full regression suite**: 559/559 passing, 1 pre-existing skip (unrelated), `flutter analyze`: 0 issues in files touched by this story (13 pre-existing `info`-level lints elsewhere, unrelated). (Baseline immediately before this story's changes, freshly re-verified: 534/534 passing, same 1 skip — full suite delta of +25 reflects both this story's own 12 new tests and concurrent, unrelated work landing in this shared repo during this session, e.g. `tests/unit/pet-room-screen-ui/`; isolated re-runs of this story's own test file confirm all 12 of its tests pass independent of that concurrent activity.)
