# Story 001: Gesture Classification & Event Emission

> **Epic**: Pet Interaction
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3-4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-interaction.md`
**Requirement**: `TR-petinteraction-001`, `TR-petinteraction-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Flutter-Flame Event Bridge Architecture (primary — governs the emission contract) + ADR-0016: Pet Interaction Input Handling (governs the swipe-detection threshold mechanism, TR-petinteraction-003).
**ADR Decision Summary**: ADR-0004 §3(b) sanctions exactly one in-game path: a Flame component's `TapCallbacks`/`DragCallbacks` handler calling `GameEventBus().emit(GameEvent(petInteracted, ...))` directly (Flame→Bus→Flame, not Flame→Flutter). This is the only architecturally-approved way this story may emit `petInteracted`. ADR-0016 §Decision 1 additionally fixes: `MochiComponent` mixes in `DragCallbacks` ONLY (not `TapCallbacks` — combining both risks a gesture-arena conflict between `DragCallbacks`' `ImmediateMultiDragGestureRecognizer` and `TapCallbacks`' `MultiTapGestureRecognizer`); all touches (tap or swipe) are funneled through `onDragStart`/`onDragUpdate`/`onDragEnd`/`onDragCancel`; classification happens once, in `onDragEnd`, via straight-line displacement (`event.canvasEndPosition - startCanvasPosition`, not summed per-update path length) compared to 40dp, and elapsed duration (`_now().difference(startTime)`, an injected clock) compared to 300ms.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM
**Engine Notes**: Use the `DragCallbacks` mixin ONLY — do NOT also mix in `TapCallbacks` on `MochiComponent` (ADR-0016 §Decision 1: combining both risks a gesture-arena conflict, flame-specialist-confirmed). `TapDetector`/`DragDetector` are forbidden regardless (deprecated since Flame 1.21, per control manifest's Forbidden APIs list). `GameEventType.petInteracted` and its `InteractionType` payload already exist in ADR-0004's `Key Interfaces` (§ Decision, `petInteracted→InteractionType`) — no new enum member needed, only the `InteractionType.tap`/`InteractionType.swipe` values from this GDD.

**Control Manifest Rules (this layer)**:
- Required: `GameEventBus` emit call sites must respect the one-way invariant — never write back into Flutter/Riverpod from this component (source: ADR-0004, Global Rules).
- Required: implement `onDragStart` (record start `canvasPosition` + injected-clock timestamp, guarded by a single `_activePointerId` so a second concurrent touch is ignored), `onDragEnd` (classify + emit), AND `onDragCancel` (discard in-flight state with no emit, for OS-level cancellation e.g. app-switch mid-touch) — all three are mandatory per ADR-0016 §Decision 1, not just `onDragEnd` (source: ADR-0016).
- Forbidden: `TapDetector`/`DragDetector` mixins (source: Forbidden APIs list, control-manifest.md); combining `TapCallbacks` with `DragCallbacks` on the same component (source: ADR-0016, registry pattern `combining_tapcallbacks_and_dragcallbacks_same_component`).
- Guardrail: 16.6ms/frame budget — gesture classification runs on the input callback, not the render loop; must not block a frame.

---

## Acceptance Criteria

*From GDD `design/gdd/pet-interaction.md`, scoped to this story:*

- [x] **AC-1**: GIVEN Mochi is in any Base Mood (HAPPY/CONTENT/TIRED/SAD, not SLEEPING), WHEN bé taps the sprite, THEN `GameEvent(petInteracted, InteractionType.tap)` is emitted onto `GameEventBus` within 1 frame.
- [x] **AC-2**: GIVEN Mochi is in any Base Mood (not SLEEPING), WHEN bé swipes (≥40dp distance, ≤300ms duration) on the sprite, THEN `GameEvent(petInteracted, InteractionType.swipe)` is emitted.
- [x] **AC-6**: GIVEN drag distance < 40dp, WHEN bé releases, THEN treat as tap — emit `InteractionType.tap` (if not in cooldown).
- [x] **AC-7**: GIVEN drag distance ≥ 40dp but duration > 300ms, WHEN bé releases, THEN treat as tap — emit `InteractionType.tap`.

---

## Implementation Notes

*Derived from ADR-0004 Decision §3(b)/§5 and ADR-0016 Decision §1:*

- The Mochi Flame component mixes in `DragCallbacks` ONLY (not `TapCallbacks` — ADR-0016 §Decision 1) and, from within `onDragEnd`, calls `GameEventBus().emit(GameEvent(GameEventType.petInteracted, InteractionType.tap|swipe))` directly — this is ADR-0004's sanctioned "Flame→Bus→Flame" adapter (§3b), distinct from the more common `ref.listen`-in-widget adapter (§3a) used by every other event type in this codebase.
- `GameEventBus()` is constructed once at app root and is app-lifetime (ADR-0004 §1) — do not construct a new instance or attempt DI for it here; call the singleton factory directly, matching §3(b)'s literal pattern.
- The bus's `StreamController.broadcast()` is built **without `sync: true`** specifically so that emitting from within the `DragCallbacks` handler is reentrancy-safe (ADR-0004 §5, final paragraph) — no additional guard is needed against corrupting the emit that triggered it.
- **Classification mechanism (ADR-0016 §Decision 1)**: `onDragStart` records `startCanvasPosition = event.canvasPosition` and `startTime = _now()` (an injected `DateTime Function()` clock field, mirroring ADR-0005's `computeEnergy(..., now)` pattern — do NOT read `DateTime.now()` directly inline, inject it so tests can control time). Guard with a single `_activePointerId` field: if a drag is already active, ignore `onDragStart` for a second pointer (MVP is single-touch only). `onDragEnd` computes `distance = (event.canvasEndPosition - startCanvasPosition).length` (straight-line displacement, NOT summed per-`onDragUpdate` deltas — those overcount jitter) and `duration = _now().difference(startTime)`, then `isSwipe = distance >= 40 && duration <= const Duration(milliseconds: 300)`. `onDragCancel` MUST also be implemented to clear `startCanvasPosition`/`startTime`/`_activePointerId` with no emit — this handles OS-level pointer cancellation (e.g. the app being switched away mid-touch) and prevents stale state from corrupting the next gesture (flame-specialist-flagged risk, ADR-0016 Consequences → Risks).
- Distance/duration are measured against Flame canvas units, which are assumed 1:1 with logical pixels (dp) for Pet Room's viewport — ADR-0016 flags this as an open Verification Required item once Pet Room Screen UI (#18) defines its actual camera/viewport; if #18 introduces a scaled `FixedResolutionViewport` or camera zoom, the 40dp threshold must be converted through that scale factor, not applied to raw canvas units as-is.
- Do not implement a `TimerComponent`, `Timer`, or any other scheduled/polling mechanism for this story — classification is purely event-driven (evaluated once, on `onDragEnd`), no per-frame work.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: SLEEPING Base Mood peek behavior and PLEASED-animation-in-progress ignore guard (this story only implements classification+emit for the "normal" case).
- Story 003: cooldown enforcement (tap 1.0s / swipe 2.0s) — this story emits unconditionally once classification succeeds; cooldown gating wraps around this in Story 003.
- Story 005: the 80×80dp minimum hit-area contract (Pet Room Screen UI #18's responsibility to satisfy; this story only registers callbacks on whatever hit area the sprite component is given).

---

## QA Test Cases

*The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: GIVEN a Mochi component in Base Mood `HAPPY` — When: simulate a `DragCallbacks` sequence with near-zero net displacement (`onDragStart` then `onDragEnd` at effectively the same `canvasPosition`, any short duration) — Then: assert exactly one `GameEvent(petInteracted, InteractionType.tap)` was added to `GameEventBus().stream` (use a `StreamController` test listener with no artificial delay). Edge cases: repeat for `CONTENT`/`TIRED`/`SAD`; also assert `onDragCancel` mid-gesture emits nothing.
- **AC-2**: GIVEN a Mochi component in Base Mood `HAPPY` — When: simulate a `DragCallbacks` sequence with distance=55dp, duration=250ms — Then: assert `GameEvent(petInteracted, InteractionType.swipe)` emitted. Edge cases: distance exactly 40dp/duration exactly 300ms (boundary — should classify as swipe, inclusive per GDD's `>=`/`<=`); a second concurrent simulated pointer during an active drag is a no-op (multi-touch guard, ADR-0016 §Decision 1).
- **AC-6**: GIVEN a drag of distance=20dp (any duration) — When: released — Then: assert `InteractionType.tap` emitted, not `swipe`.
- **AC-7**: GIVEN a drag of distance=55dp, duration=450ms — When: released — Then: assert `InteractionType.tap` emitted (worked example from GDD Formulas section — vuốt chậm hơn 300ms treated as tap even though distance qualifies).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pet-interaction/gesture_classification_test.dart` — must exist and pass

**Status**: [x] Created — 13/13 tests passing (`cd src && flutter test ../tests/unit/pet-interaction/gesture_classification_test.dart`)

---

## Dependencies

- Depends on: None
- Unlocks: Story 002 (SLEEPING/PLEASED guards), Story 003 (cooldown), Story 004 (integration)

---

## Completion Notes

**Completed**: 2026-07-23
**Criteria**: 4/4 passing (AC-1, AC-2, AC-6, AC-7 — including all listed boundary/edge cases: inclusive 40dp/300ms boundary, sub-threshold distance, over-duration, and the second-concurrent-pointer no-op)

### Test-Criterion Traceability

| Criterion | Test | Status |
|-----------|------|--------|
| AC-1 (tap emission, HAPPY/CONTENT/TIRED/SAD) | `test_AC1_near_zero_displacement_in_{happy,content,tired,sad}_emits_exactly_one_tap` (4 tests) | COVERED |
| AC-1 (real `DragCallbacks` wiring, zero displacement) | `test_real_zero_displacement_drag_start_then_end_emits_tap` | COVERED |
| AC-2 (55dp/250ms → swipe) | `test_AC2_distance_55dp_duration_250ms_emits_swipe` | COVERED |
| AC-2 (inclusive 40dp/300ms boundary → swipe) | `test_AC2_boundary_distance_exactly_40dp_duration_exactly_300ms_is_inclusive_swipe` | COVERED |
| AC-2 (real `DragCallbacks` wiring, 55dp swipe via `onDragUpdate`) | `test_real_drag_with_55dp_displacement_via_onDragUpdate_emits_swipe` | COVERED |
| AC-2 (second concurrent real pointer is a no-op — multi-touch guard) | `test_real_second_concurrent_pointer_onDragStart_is_a_no_op_multi_touch_guard` | COVERED |
| AC-6 (20dp any duration → tap) | `test_AC6_distance_20dp_any_duration_is_tap_not_swipe` | COVERED |
| AC-7 (55dp/450ms → tap, worked example) | `test_AC7_distance_55dp_duration_450ms_is_tap_worked_example` | COVERED |
| AC-7 (real `DragCallbacks` wiring, injected-clock duration boundary) | `test_real_qualifying_distance_but_duration_over_300ms_via_injected_clock_is_tap` | COVERED |
| Real `onDragCancel` mid-gesture (no emit, no stale state) | `test_real_onDragCancel_mid_gesture_emits_nothing_and_leaves_no_stale_state` | COVERED |

### Deviations (documented, non-blocking)

1. **Pre-existing scaffold formally adopted, not rewritten.** `src/lib/gameplay/mochi_component.dart`'s `DragCallbacks` handling (`onDragStart`/`onDragUpdate`/`onDragEnd`/`onDragCancel`, the `_activePointerId` multi-touch guard, and the classify-then-emit path) was originally written ahead of schedule by Story 002's implementer as a scaffold to wrap Story 002's SLEEPING/PLEASED guards, since Story 001 was `Blocked` when that story started and ADR-0016 landed mid-implementation. I independently re-verified this scaffold from scratch against ADR-0016 §Decision 1 (not trusting Story 002's own self-description) — including source-reading the actual installed `flame-1.37.0` package to confirm two real deviations from the ADR's illustrative pseudocode are correct, not drift:
   - `DragEndEvent` carries no position field in the real Flame 1.37.0 API (only `pointerId`/`velocity` — source-verified against `flame-1.37.0/lib/src/events/messages/drag_end_event.dart`), so the code tracks the last `onDragUpdate` canvas position instead of reading a nonexistent `event.canvasEndPosition` in `onDragEnd`.
   - `DragCallbacks.onDragStart`/`onDragEnd`/`onDragCancel` are all `@mustCallSuper` in the real Flame source; `onDragCancel` deliberately does NOT call `super.onDragCancel` (with a documented `// ignore: must_call_super`) because the mixin's default implementation is `onDragCancel(e) => onDragEnd(e.toDragEnd())`, which would re-enter this component's own overridden `onDragEnd` via virtual dispatch and cause a spurious emit on what must be a silently discarded gesture.

   No code changes to `mochi_component.dart` were required — the existing implementation already satisfied ADR-0016 §Decision 1 and this story's AC-1/AC-2/AC-6/AC-7 exactly. Only the missing dedicated test file (this story's own Test Evidence requirement) was added.
2. **Cooldown (ADR-0016 §2) and the `SpriteComponent`/hit-area migration (ADR-0016 §3) were deliberately NOT implemented here**, despite Story 002's Completion Notes suggesting Story 001 "should replace/absorb it wholesale." This story's own `## Out of Scope` section is authoritative and explicitly assigns cooldown to Story 003 and the hit-area contract to Story 005 (gated on Pet Room Screen UI #18) — implementing either here would be scope creep beyond this story's own acceptance criteria.
3. **Test file scope is deliberately narrower than Story 002's.** This story's `tests/unit/pet-interaction/gesture_classification_test.dart` tests only the classify-and-emit mechanism (tap/swipe/boundary/multi-touch/cancel); it does not re-test the SLEEPING/PLEASED guards, which remain fully covered by Story 002's own `tests/unit/pet-interaction/interaction_state_guards_test.dart` (13/13 passing, unchanged).

**Test Evidence**: Logic — `tests/unit/pet-interaction/gesture_classification_test.dart`, 13/13 passing.
**Code Review**: Complete — flame-specialist: APPROVED WITH SUGGESTIONS (no Required Changes; 2 non-blocking suggestions — extracting a standalone pure `isSwipe()` function, and a test-naming convention note). qa-tester: initial verdict GAPS (one genuine regression-risk gap: the injected-clock duration boundary was only exercised via the classification-formula seam, never through the real `onDragStart`/`onDragEnd` wiring with a controlled clock) — closed by adding `test_real_qualifying_distance_but_duration_over_300ms_via_injected_clock_is_tap` before this story was marked Complete.
**Full regression suite**: 523/523 passing, 1 pre-existing skip (unrelated, same as Story 002's baseline). `flutter analyze`: 0 issues in files touched by this story (13 pre-existing `info`-level lints elsewhere, unrelated to this story, same baseline as Story 002's close).
