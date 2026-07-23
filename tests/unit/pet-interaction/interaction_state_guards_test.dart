// Run with:
//   cd src && flutter test ../tests/unit/pet-interaction/interaction_state_guards_test.dart
//
// Story 002 (SLEEPING Peek & PLEASED-Animation Input Guards). Two halves:
// (1) a pure-Dart suite against `evaluateInteractionGuard` — no Flame, no
//     mounting, fully deterministic — the actual guard DECISION logic.
// (2) a `flame_test`-backed suite against the real `MochiComponent`
//     guard-then-emit path (`testWithFlameGame`, the same harness pattern
//     as `tests/integration/pet_state_machine/mochi_component_*_test.dart`),
//     proving the production handlers actually route through the same
//     guard and that no `GameEvent` reaches `GameEventBus().stream` when a
//     guard applies.
//
// Per ADR-0016 ("Pet Interaction Input Handling", Accepted concurrently
// with this story's implementation), `MochiComponent` mixes in
// `DragCallbacks` ONLY — there is no `TapCallbacks`/`onTapUp` anymore; a
// "tap" is a near-zero-displacement drag, classified once in `onDragEnd`.
// `simulateTapForTesting()`/`classifyAndHandleDragForTesting()` exercise
// that same classify-then-guard-then-emit path without needing to
// construct raw Flame gesture-event objects.

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/interaction_guard.dart';
import 'package:pet_quest/core/interaction_type.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';

void main() {
  group('evaluateInteractionGuard (pure logic)', () {
    test(
      'test_evaluateInteractionGuard_sleeping_base_mood_returns_sleepingPeek',
      () {
        final result = evaluateInteractionGuard(
          baseMood: MoodState.sleeping,
          currentTriggeredState: null,
        );

        expect(result, InteractionGuardResult.sleepingPeek);
      },
    );

    test(
      'test_evaluateInteractionGuard_pleased_triggered_state_returns_ignored',
      () {
        final result = evaluateInteractionGuard(
          baseMood: MoodState.happy,
          currentTriggeredState: TriggeredState.pleased,
        );

        expect(result, InteractionGuardResult.ignored);
      },
    );

    test(
      'test_evaluateInteractionGuard_non_sleeping_non_pleased_returns_emit',
      () {
        for (final mood in [
          MoodState.happy,
          MoodState.content,
          MoodState.tired,
          MoodState.sad,
        ]) {
          final result = evaluateInteractionGuard(
            baseMood: mood,
            currentTriggeredState: null,
          );
          expect(result, InteractionGuardResult.emit, reason: '$mood');
        }
      },
    );

    test(
      'test_evaluateInteractionGuard_other_triggered_states_do_not_trigger_the_pleased_guard',
      () {
        // AC-9 and this story's own title scope the guard to PLEASED
        // specifically (not "any triggered state currently playing") — a
        // narrower, literal reading of the acceptance criterion.
        for (final state in [
          TriggeredState.excited,
          TriggeredState.showingOff,
          TriggeredState.bouncing,
          TriggeredState.levelingUp,
        ]) {
          final result = evaluateInteractionGuard(
            baseMood: MoodState.happy,
            currentTriggeredState: state,
          );
          expect(result, InteractionGuardResult.emit, reason: '$state');
        }
      },
    );

    test(
      'test_evaluateInteractionGuard_sleeping_wins_over_a_stale_pleased_state',
      () {
        // Guard order: SLEEPING is checked first regardless of what
        // Triggered State happens to be recorded.
        final result = evaluateInteractionGuard(
          baseMood: MoodState.sleeping,
          currentTriggeredState: TriggeredState.pleased,
        );

        expect(result, InteractionGuardResult.sleepingPeek);
      },
    );
  });

  group('MochiComponent input guards (real DragCallbacks wiring)', () {
    setUp(() => GameEventBus().resetForTesting());

    Future<MochiComponent> mountSleepingMochi(FlameGame game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(
        const GameEvent(GameEventType.petMoodChanged, MoodState.sleeping),
      );
      await Future<void>.delayed(Duration.zero);
      expect(mochi.baseMood, MoodState.sleeping);
      return mochi;
    }

    testWithFlameGame(
      'test_AC8_tap_while_sleeping_emits_no_GameEvent_and_triggers_the_peek',
      (game) async {
        final mochi = await mountSleepingMochi(game);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          isEmpty,
        );
        expect(mochi.sleepingPeekTriggerCount, 1);
        expect(mochi.isSleepingPeekPlaying, isTrue);
      },
    );

    testWithFlameGame(
      'test_AC8_swipe_while_sleeping_is_also_a_silent_no_op_not_tap_only',
      (game) async {
        final mochi = await mountSleepingMochi(game);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        // distance=55dp/duration=250ms would classify as swipe once past
        // the guard — proves the guard applies identically regardless of
        // gesture classification, not just the zero-displacement tap case.
        mochi.classifyAndHandleDragForTesting(
          55,
          const Duration(milliseconds: 250),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          isEmpty,
        );
        expect(mochi.sleepingPeekTriggerCount, 1);
      },
    );

    testWithFlameGame(
      'test_AC8_sleeping_peek_visual_window_lasts_500ms_then_clears',
      (game) async {
        final mochi = await mountSleepingMochi(game);

        mochi.simulateTapForTesting();
        await game.ready();
        expect(mochi.isSleepingPeekPlaying, isTrue);

        // Just before 500ms — still playing.
        await _advance(game, 0.45);
        expect(mochi.isSleepingPeekPlaying, isTrue);

        // Past 500ms — cleared.
        await _advance(game, 0.15);
        expect(mochi.isSleepingPeekPlaying, isFalse);
      },
    );

    testWithFlameGame(
      'test_AC9_tap_during_PLEASED_emits_no_new_event_and_does_not_reset_the_timer',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);
        // HAPPY, not SLEEPING — isolates this test to the PLEASED guard
        // only, not the SLEEPING guard.
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
        );
        await Future<void>.delayed(Duration.zero);

        mochi.onTrigger(TriggeredState.pleased); // #6's own test harness.
        await game.ready();
        expect(mochi.currentTriggeredState, TriggeredState.pleased);

        await _advance(game, 1.0); // 1.0s into PLEASED's 2.0s.

        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          isEmpty,
        );
        // Not reset: the SAME PLEASED activation should complete at its
        // original 2.0s mark, not a fresh one from t=1.0.
        expect(mochi.currentTriggeredState, TriggeredState.pleased);
        await _advance(game, 0.9);
        expect(mochi.currentTriggeredState, TriggeredState.pleased);
        await _advance(game, 0.2);
        expect(mochi.currentTriggeredState, isNull);
      },
    );

    testWithFlameGame(
      'test_AC9_swipe_during_PLEASED_is_also_ignored_not_tap_only',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
        );
        await Future<void>.delayed(Duration.zero);

        mochi.onTrigger(TriggeredState.pleased);
        await game.ready();

        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.classifyAndHandleDragForTesting(
          55,
          const Duration(milliseconds: 250),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          isEmpty,
        );
        expect(mochi.currentTriggeredState, TriggeredState.pleased);
      },
    );

    testWithFlameGame(
      'test_control_tap_in_HAPPY_with_no_triggered_state_does_emit_petInteracted',
      (game) async {
        // Sanity/control case (not itself an AC-8/AC-9 scenario): proves
        // the guards don't over-fire and silently swallow every tap.
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
        );
        await Future<void>.delayed(Duration.zero);

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
  });

  group('MochiComponent guards via real Flame DragCallbacks events', () {
    // Constructs real `DragStartEvent`/`DragEndEvent`/`DragCancelEvent`
    // objects (not the `@visibleForTesting` seams above) to prove the
    // production `onDragStart`/`onDragEnd`/`onDragCancel` overrides
    // themselves — not just the guard logic they call into — are wired
    // correctly per ADR-0016 §1.
    setUp(() => GameEventBus().resetForTesting());

    testWithFlameGame(
      'test_AC8_a_real_zero_displacement_drag_gesture_while_sleeping_triggers_the_peek_not_an_emit',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.sleeping),
        );
        await Future<void>.delayed(Duration.zero);

        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        mochi.onDragStart(
          DragStartEvent(
            1,
            game,
            DragStartDetails(sourceTimeStamp: Duration.zero),
          ),
        );
        mochi.onDragEnd(DragEndEvent(1, DragEndDetails()));
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          isEmpty,
        );
        expect(mochi.sleepingPeekTriggerCount, 1);
      },
    );

    testWithFlameGame(
      'test_a_real_onDragCancel_mid_gesture_emits_nothing_even_outside_any_guard',
      (game) async {
        // Not itself an AC-8/AC-9 case — proves ADR-0016 §1's cancel
        // contract (discard, no classification, no emit) holds even in the
        // ordinary HAPPY/no-triggered-state case where a guard would
        // otherwise allow the emit through.
        final mochi = MochiComponent();
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
            DragStartDetails(sourceTimeStamp: Duration.zero),
          ),
        );
        mochi.onDragCancel(DragCancelEvent(1));
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          isEmpty,
        );

        // And the cancel didn't leave stale state corrupting the NEXT
        // gesture — a fresh drag still classifies and emits normally.
        mochi.onDragStart(
          DragStartEvent(
            2,
            game,
            DragStartDetails(sourceTimeStamp: Duration.zero),
          ),
        );
        mochi.onDragEnd(DragEndEvent(2, DragEndDetails()));
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          hasLength(1),
        );
      },
    );
  });
}

/// Ticks [game] forward by [totalSeconds] in small increments, yielding to
/// the microtask queue after every tick — mirrors
/// `tests/integration/pet_state_machine/mochi_component_triggered_state_test.dart`'s
/// `_advance` helper (same rationale: `TimerComponent.onLoad()` is `async`,
/// so a tight synchronous loop would spend ticks while a freshly-added
/// timer is still blocked on load).
Future<void> _advance(
  FlameGame game,
  double totalSeconds, {
  double step = 1 / 60,
}) async {
  var remaining = totalSeconds;
  while (remaining > 0) {
    final dt = remaining < step ? remaining : step;
    game.update(dt);
    await Future<void>.delayed(Duration.zero);
    remaining -= dt;
  }
}
