// Run with:
//   cd src && flutter test ../tests/unit/pet-interaction/gesture_classification_test.dart
//
// Story 001 (Gesture Classification & Event Emission). Tests the underlying
// classify-and-emit mechanism itself (ADR-0016 §Decision 1: DragCallbacks-
// only capture, classification once in `onDragEnd` via straight-line
// displacement vs 40dp + injected wall-clock vs 300ms) — NOT the
// SLEEPING/PLEASED guards, which Story 002's own
// `tests/unit/pet-interaction/interaction_state_guards_test.dart` already
// covers in full. Every test here mounts Mochi in a non-SLEEPING Base Mood
// with no active Triggered State, so `evaluateInteractionGuard` always
// resolves to `InteractionGuardResult.emit` and this story's own
// classify-then-emit path is what's actually under test — deliberately
// distinct scope from Story 002's guard-focused suite, per this story's own
// delegated instructions.
//
// Two halves, mirroring Story 002's test structure:
// (1) `classifyAndHandleDragForTesting(distanceDp, duration)` /
//     `simulateTapForTesting()` — the `@visibleForTesting` seam exercising
//     the classify-then-guard-then-emit path without constructing raw Flame
//     gesture-event objects. Covers the QA Test Cases' distance/duration
//     table for AC-1/AC-2/AC-6/AC-7, including the inclusive 40dp/300ms
//     boundary and the GDD's own worked examples.
// (2) Real `DragStartEvent`/`DragUpdateEvent`/`DragEndEvent`/
//     `DragCancelEvent` objects, proving the production `onDragStart`/
//     `onDragUpdate`/`onDragEnd`/`onDragCancel` overrides themselves are
//     correctly wired per ADR-0016 §Decision 1's Validation Criteria —
//     including two genuinely concurrent real pointers exercising the
//     multi-touch guard, which Story 002's Completion Notes explicitly
//     flagged as not yet covered anywhere and recommended for this story's
//     own test file ("Story 001 owns the fuller DragCallbacks
//     implementation").
//
// `DragEndEvent` carries no position field in the real Flame 1.37.0 API
// (only `pointerId`/`velocity` — source-verified against
// `flame-1.37.0/lib/src/events/messages/drag_end_event.dart`), so the
// production code tracks the last `onDragUpdate` canvas position instead of
// reading `event.canvasEndPosition` in `onDragEnd` (which does not exist on
// `DragEndEvent`) — the swipe-via-real-events test below exercises exactly
// that path.

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/interaction_type.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';

void main() {
  group('Gesture classification via test seam (AC-1/AC-2/AC-6/AC-7)', () {
    setUp(() => GameEventBus().resetForTesting());

    Future<MochiComponent> mountMochi(FlameGame game, MoodState mood) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(GameEvent(GameEventType.petMoodChanged, mood));
      await Future<void>.delayed(Duration.zero);
      expect(mochi.baseMood, mood);
      return mochi;
    }

    for (final mood in [
      MoodState.happy,
      MoodState.content,
      MoodState.tired,
      MoodState.sad,
    ]) {
      testWithFlameGame(
        'test_AC1_near_zero_displacement_in_${mood.name}_emits_exactly_one_tap',
        (game) async {
          final mochi = await mountMochi(game, mood);
          final events = <GameEvent>[];
          final sub = GameEventBus().stream.listen(events.add);
          addTearDown(sub.cancel);

          mochi.simulateTapForTesting();
          await Future<void>.delayed(Duration.zero);

          final interacted = events.where(
            (e) => e.type == GameEventType.petInteracted,
          );
          expect(interacted, hasLength(1));
          expect(interacted.single.data, InteractionType.tap);
        },
      );
    }

    testWithFlameGame(
      'test_AC2_distance_55dp_duration_250ms_emits_swipe',
      (game) async {
        final mochi = await mountMochi(game, MoodState.happy);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.classifyAndHandleDragForTesting(
          55,
          const Duration(milliseconds: 250),
        );
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(1));
        expect(interacted.single.data, InteractionType.swipe);
      },
    );

    testWithFlameGame(
      'test_AC2_boundary_distance_exactly_40dp_duration_exactly_300ms_is_inclusive_swipe',
      (game) async {
        final mochi = await mountMochi(game, MoodState.happy);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.classifyAndHandleDragForTesting(
          40,
          const Duration(milliseconds: 300),
        );
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(1));
        expect(interacted.single.data, InteractionType.swipe);
      },
    );

    testWithFlameGame('test_AC6_distance_20dp_any_duration_is_tap_not_swipe', (
      game,
    ) async {
      final mochi = await mountMochi(game, MoodState.happy);
      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      mochi.classifyAndHandleDragForTesting(
        20,
        const Duration(milliseconds: 150),
      );
      await Future<void>.delayed(Duration.zero);

      final interacted = events.where(
        (e) => e.type == GameEventType.petInteracted,
      );
      expect(interacted, hasLength(1));
      expect(interacted.single.data, InteractionType.tap);
    });

    testWithFlameGame(
      'test_AC7_distance_55dp_duration_450ms_is_tap_worked_example',
      (game) async {
        final mochi = await mountMochi(game, MoodState.happy);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.classifyAndHandleDragForTesting(
          55,
          const Duration(milliseconds: 450),
        );
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(1));
        expect(interacted.single.data, InteractionType.tap);
      },
    );
  });

  group('Real DragCallbacks wiring (ADR-0016 Validation Criteria)', () {
    setUp(() => GameEventBus().resetForTesting());

    Future<MochiComponent> mountHappyMochi(FlameGame game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(
        const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
      );
      await Future<void>.delayed(Duration.zero);
      return mochi;
    }

    testWithFlameGame(
      'test_real_zero_displacement_drag_start_then_end_emits_tap',
      (game) async {
        final mochi = await mountHappyMochi(game);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.onDragStart(
          DragStartEvent(
            1,
            game,
            DragStartDetails(
              globalPosition: Offset.zero,
              sourceTimeStamp: Duration.zero,
            ),
          ),
        );
        mochi.onDragEnd(DragEndEvent(1, DragEndDetails()));
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(1));
        expect(interacted.single.data, InteractionType.tap);
      },
    );

    testWithFlameGame(
      'test_real_drag_with_55dp_displacement_via_onDragUpdate_emits_swipe',
      (game) async {
        final mochi = await mountHappyMochi(game);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.onDragStart(
          DragStartEvent(
            1,
            game,
            DragStartDetails(
              globalPosition: Offset.zero,
              sourceTimeStamp: Duration.zero,
            ),
          ),
        );
        // Straight-line displacement of 55 logical px from the (0,0) start,
        // via `onDragUpdate`'s tracked `canvasEndPosition` — `DragEndEvent`
        // itself carries no position (source-verified), so this is the
        // production code's only source for the release position.
        mochi.onDragUpdate(
          DragUpdateEvent(
            1,
            game,
            DragUpdateDetails(
              globalPosition: Offset.zero,
              delta: const Offset(55, 0),
              sourceTimeStamp: const Duration(milliseconds: 100),
            ),
          ),
        );
        mochi.onDragEnd(DragEndEvent(1, DragEndDetails()));
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(1));
        expect(interacted.single.data, InteractionType.swipe);
      },
    );

    testWithFlameGame(
      'test_real_qualifying_distance_but_duration_over_300ms_via_injected_clock_is_tap',
      (game) async {
        // Code-review-flagged gap (Story 001 qa-tester pass): the seam-based
        // AC-7 test (`classifyAndHandleDragForTesting`) exercises the
        // classification *formula* directly and never touches `_now()` at
        // all, since `duration` is passed in as a raw parameter. This test
        // proves the production `onDragEnd`'s own `duration =
        // _now().difference(startTime)` computation is correctly wired to
        // the injected clock end-to-end — an accidentally reversed
        // `startTime.difference(_now())` would still satisfy `<= 300ms`
        // under `Duration` comparison (a negative duration), and no other
        // test in this suite would catch that regression.
        var fakeNow = DateTime(2026);
        final mochi = MochiComponent(now: () => fakeNow);
        await game.ensureAdd(mochi);
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
        );
        await Future<void>.delayed(Duration.zero);

        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.onDragStart(
          DragStartEvent(
            1,
            game,
            DragStartDetails(
              globalPosition: Offset.zero,
              sourceTimeStamp: Duration.zero,
            ),
          ),
        );
        // Qualifying distance (55dp >= 40dp threshold) — distance alone
        // must NOT be enough once duration is over budget.
        mochi.onDragUpdate(
          DragUpdateEvent(
            1,
            game,
            DragUpdateDetails(
              globalPosition: Offset.zero,
              delta: const Offset(55, 0),
              sourceTimeStamp: const Duration(milliseconds: 100),
            ),
          ),
        );
        // Advance the injected clock past the 300ms threshold BEFORE
        // onDragEnd samples `_now()` again.
        fakeNow = fakeNow.add(const Duration(milliseconds: 450));
        mochi.onDragEnd(DragEndEvent(1, DragEndDetails()));
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(1));
        expect(interacted.single.data, InteractionType.tap);
      },
    );

    testWithFlameGame(
      'test_real_onDragCancel_mid_gesture_emits_nothing_and_leaves_no_stale_state',
      (game) async {
        final mochi = await mountHappyMochi(game);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.onDragStart(
          DragStartEvent(
            1,
            game,
            DragStartDetails(
              globalPosition: Offset.zero,
              sourceTimeStamp: Duration.zero,
            ),
          ),
        );
        mochi.onDragCancel(DragCancelEvent(1));
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          isEmpty,
        );

        // The cancel must not leave stale start-state that corrupts the
        // NEXT gesture (ADR-0016 §1, flame-specialist-flagged risk) — a
        // fresh drag from a different pointer still classifies and emits
        // normally.
        mochi.onDragStart(
          DragStartEvent(
            2,
            game,
            DragStartDetails(
              globalPosition: Offset.zero,
              sourceTimeStamp: Duration.zero,
            ),
          ),
        );
        mochi.onDragEnd(DragEndEvent(2, DragEndDetails()));
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(1));
        expect(interacted.single.data, InteractionType.tap);
      },
    );

    testWithFlameGame(
      'test_real_second_concurrent_pointer_onDragStart_is_a_no_op_multi_touch_guard',
      (game) async {
        // ADR-0016 §1 Validation Criteria: "two concurrent simulated
        // pointers — second pointer's onDragStart is a no-op while the
        // first is active." Flagged in Story 002's Completion Notes as not
        // yet exercised against the real DragCallbacks handlers anywhere
        // ("recommend Story 001's own test file... pick this up") — this is
        // that coverage.
        final mochi = await mountHappyMochi(game);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        // Pointer 1 starts a drag and remains the active pointer.
        mochi.onDragStart(
          DragStartEvent(
            1,
            game,
            DragStartDetails(
              globalPosition: Offset.zero,
              sourceTimeStamp: Duration.zero,
            ),
          ),
        );

        // Pointer 2 touches down concurrently at a different position —
        // must be silently ignored, must not overwrite pointer 1's
        // in-flight start state.
        mochi.onDragStart(
          DragStartEvent(
            2,
            game,
            DragStartDetails(
              globalPosition: const Offset(200, 200),
              sourceTimeStamp: Duration.zero,
            ),
          ),
        );

        // Pointer 2 releases — not the active pointer, so this must be a
        // silent no-op: no emit, and no clearing of pointer 1's state.
        mochi.onDragEnd(DragEndEvent(2, DragEndDetails()));
        await Future<void>.delayed(Duration.zero);
        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          isEmpty,
        );

        // Pointer 1 releases normally afterward — its own near-zero-
        // displacement gesture still classifies and emits a tap, proving
        // pointer 2 never corrupted pointer 1's tracked start state.
        mochi.onDragEnd(DragEndEvent(1, DragEndDetails()));
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(1));
        expect(interacted.single.data, InteractionType.tap);
      },
    );
  });
}
