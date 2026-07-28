# Story 002: SLEEPING Peek & PLEASED-Animation Input Guards

> **Epic**: Pet Interaction
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2-3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-interaction.md`
**Requirement**: `TR-petinteraction-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Flutter-Flame Event Bridge Architecture
**ADR Decision Summary**: ADR-0004 §3(b) sanctions the Flame→Bus→Flame emit adapter this story gates. The two guards this story implements (SLEEPING peek, PLEASED-in-progress ignore) are both about *withholding* the emit under specific Base Mood/Triggered State conditions — they do not introduce a new adapter or violate the one-way invariant, they simply add a precondition to the same emit call Story 001 implements.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM
**Engine Notes**: No new post-cutoff API surface beyond what Story 001 already uses (`TapCallbacks`/`DragCallbacks`). This story reads the current Base Mood / Triggered State from Pet State Machine (#6) — a read-only query, not a subscription; confirm the exact accessor with the #6 codebase at implementation time (this epic does not own that interface).

**Control Manifest Rules (this layer)**:
- Required: `GameEventBus` emit call sites must respect the one-way invariant (source: ADR-0004, Global Rules).
- Forbidden: `TapDetector`/`DragDetector` mixins (source: Forbidden APIs list, control-manifest.md).
- Guardrail: 16.6ms/frame budget — the Base Mood/Triggered State check happens synchronously inside the tap/drag callback; must not block a frame.

---

## Acceptance Criteria

*From GDD `design/gdd/pet-interaction.md`, scoped to this story:*

- [x] **AC-8**: GIVEN Mochi is in Base Mood SLEEPING, WHEN bé taps, THEN the sleeping-peek animation runs for 500ms AND no `GameEvent` is emitted onto `GameEventBus`.
- [x] **AC-9**: GIVEN Mochi is in Triggered State PLEASED (currently animating), WHEN bé taps, THEN input is ignored entirely — the animation is not interrupted, and no new `GameEvent` is emitted.

---

## Implementation Notes

*Derived from GDD Core Rules / Edge Cases and ADR-0004 §3(b):*

- Both guards short-circuit **before** the emit call Story 001 implements — this story wraps that call, it does not duplicate it. Structure the callback handler so the SLEEPING/PLEASED checks run first, and only fall through to Story 001's classify-and-emit logic when neither guard applies.
- SLEEPING peek: per GDD Edge Cases, this is visual-only (30% eye-open, hold 0.3s, close 0.2s = 500ms total per Formulas) — it deliberately produces no `GameEvent`, so Pet State Machine (#6) never observes it. Do not emit `petInteracted` and then have some downstream consumer ignore it — the correct implementation withholds the emit entirely, at the source.
- PLEASED-in-progress ignore: per GDD Edge Cases ("bé tap trong khi PLEASED animation đang chạy: ignore hoàn toàn — Mochi không interrupt animation giữa chừng"), this applies to input arriving *during* the 2000ms PLEASED window regardless of interaction type (tap or swipe) — both should be dropped identically, not just tap.
- Both checks require reading current Base Mood / Triggered State from Pet State Machine (#6). This is a synchronous read of #6's current state — confirm the exact query interface with #6's actual implementation (not invented here); this story epic does not own that state.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: the base classify-and-emit logic these guards wrap around.
- Story 003: cooldown timers — orthogonal to these two guards (a tap can be blocked by SLEEPING/PLEASED *or* by cooldown; this story only handles the former).
- Pet State Machine (#6): actually rendering the sleeping-peek visual or the PLEASED animation itself — this story only decides whether to emit, not how Mochi visually responds.

---

## QA Test Cases

*The developer implements against these — do not invent new test cases during implementation.*

- **AC-8**: GIVEN Mochi's Base Mood is `SLEEPING` — When: simulate `TapCallbacks.onTapUp` — Then: assert zero `GameEvent`s were added to `GameEventBus().stream` (listen for 1 frame, expect no emission), AND assert the sleeping-peek visual trigger was invoked. Edge cases: a swipe gesture while SLEEPING should behave identically (also silently no-op on the bus side) per the same Core Rule — verify this is not accidentally tap-only.
- **AC-9**: GIVEN Mochi's Triggered State is `PLEASED` (mid-animation, simulate via #6's test harness or a stub) — When: simulate a tap — Then: assert zero new `GameEvent`s emitted AND assert the PLEASED animation's running/elapsed state is unchanged (not reset, not extended). Edge cases: a swipe during PLEASED should also be ignored (per GDD, applies to "bé tap" as the general term for any interaction attempt in this edge case, not literally tap-only — confirm against #6's actual PLEASED-state exposure at implementation time).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pet-interaction/interaction_state_guards_test.dart` — must exist and pass

**Status**: [x] Created — 13/13 tests passing (`cd src && flutter test ../tests/unit/pet-interaction/interaction_state_guards_test.dart`)

---

## Dependencies

- Depends on: Story 001 (Gesture Classification & Event Emission) — this story wraps that story's emit call with preconditions
- Unlocks: Story 004 (No-Mutation & Background/Foreground Resilience)

---

## Completion Notes

**Completed**: 2026-07-23
**Criteria**: 2/2 passing (AC-8, AC-9 — both including their swipe-not-tap-only edge cases)

### Test-Criterion Traceability

| Criterion | Test | Status |
|-----------|------|--------|
| AC-8 (SLEEPING tap → peek, no emit) | `test_AC8_tap_while_sleeping_emits_no_GameEvent_and_triggers_the_peek` | COVERED |
| AC-8 edge (SLEEPING swipe → same, not tap-only) | `test_AC8_swipe_while_sleeping_is_also_a_silent_no_op_not_tap_only` | COVERED |
| AC-8 (500ms peek window) | `test_AC8_sleeping_peek_visual_window_lasts_500ms_then_clears` | COVERED |
| AC-8 (real `DragCallbacks` wiring, not just the test seam) | `test_AC8_a_real_zero_displacement_drag_gesture_while_sleeping_triggers_the_peek_not_an_emit` | COVERED |
| AC-9 (PLEASED tap → ignored, timer not reset) | `test_AC9_tap_during_PLEASED_emits_no_new_event_and_does_not_reset_the_timer` | COVERED |
| AC-9 edge (PLEASED swipe → same, not tap-only) | `test_AC9_swipe_during_PLEASED_is_also_ignored_not_tap_only` | COVERED |
| Guard decision logic (pure, no Flame) | 5 tests in `evaluateInteractionGuard (pure logic)` group | COVERED |

### Deviations (documented, non-blocking)

1. **ADR-0016 landed mid-implementation.** Story 001 was Blocked (no ADR for the swipe threshold mechanism) when this story started. `docs/architecture/adr-0016-pet-interaction-input-handling.md` was Accepted by a concurrent process partway through this story's implementation. Per this story's own delegated instructions, a minimal classify-and-emit scaffold was implemented ahead of Story 001's official implementation so these guards would have something real to wrap — it was rewritten mid-task to comply with ADR-0016 §1 exactly (`DragCallbacks`-only capture, classification in `onDragEnd` via straight-line displacement + injected wall-clock, mandatory `_activePointerId` multi-touch guard, mandatory `onDragCancel` no-emit handling) rather than an earlier draft that incorrectly mixed in `TapCallbacks` alongside `DragCallbacks` (a real gesture-arena correctness risk ADR-0016 identifies). **Flagged for Story 001's implementer**: this scaffold does not include per-type cooldown (ADR-0016 §2) or the `SpriteComponent`/hit-area migration (ADR-0016 §3) — those remain Story 001/003/005's own scope.
2. **`MochiComponent` retains `PositionComponent` as its base class**, not `SpriteComponent` per ADR-0016's Key Interfaces illustrative snippet — deliberate, to avoid regressing ADR-0007's 8 existing Base Mood/Triggered State tests. flame-specialist code review confirmed this is a reasonable scope call, to be resolved by whichever story first mounts a real Mochi sprite asset.
3. **QA Test Case text ("simulate `TapCallbacks.onTapUp`") is now stale** relative to ADR-0016 (no `TapCallbacks` exists on `MochiComponent` anymore). Implemented against the QA Test Case's *intent* instead: `simulateTapForTesting()`/`classifyAndHandleDragForTesting()` `@visibleForTesting` seams exercise the identical guard-then-emit path the real `onDragStart`/`onDragEnd` handlers use; a separate test group also constructs real `DragStartEvent`/`DragEndEvent`/`DragCancelEvent` objects to prove the production callbacks themselves are correctly wired, not just the seams.
4. **Non-blocking follow-ups from code review** (flame-specialist APPROVED, qa-tester TESTABLE — neither raised Required Changes):
   - No test exercises two genuinely concurrent real pointers on `MochiComponent`'s actual `DragCallbacks` handlers (only the single-pointer real-event path and the pointer-guard logic itself). ADR-0016's own Validation Criteria lists this as required — recommend Story 001's own test file (`tests/unit/pet-interaction/gesture_classification_test.dart`) pick this up, since Story 001 owns the fuller `DragCallbacks` implementation.
   - `mochi.isDragged` (inherited from the `DragCallbacks` mixin) can read `true` after an ignored second pointer's `onDragEnd` flips it to `false` mid-first-gesture — cosmetic only, `isDragged` is not read anywhere in this codebase today.
   - SLEEPING+PLEASED simultaneous state is proven only at the pure `evaluateInteractionGuard` level (`test_evaluateInteractionGuard_sleeping_wins_over_a_stale_pleased_state`), not through the full `MochiComponent` path — low risk (ADR-0007's own SLEEPING gate on `onTrigger` already prevents PLEASED from being set while SLEEPING in the normal flow), noted for awareness only.

**Test Evidence**: Logic — `tests/unit/pet-interaction/interaction_state_guards_test.dart`, 13/13 passing.
**Code Review**: Complete — flame-specialist: APPROVED (no Required Changes, 2 non-blocking suggestions). qa-tester: TESTABLE (no Required Changes, 2 non-blocking suggestions). Both incorporated above.
**Full regression suite**: 510/510 passing, 1 pre-existing skip (unrelated), `flutter analyze`: 0 issues in files touched by this story (13 pre-existing `info`-level lints elsewhere, unrelated to this story).
