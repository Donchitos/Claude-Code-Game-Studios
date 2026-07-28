// Run with:
//   cd src && flutter test ../tests/integration/pet_state_machine/mochi_component_triggered_state_test.dart
//
// flame_test's testWithFlameGame — plain test() under the hood, no isolate
// timing gotchas. Drives triggered-state timing/completion via repeated
// game.update(dt) ticks (frame-ticked, per ADR-0007 Decision §4), not real
// wall-clock delays — deterministic, no flaky sleeps.

import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';

/// Ticks [game] forward by [totalSeconds] using [step]-second increments —
/// mirrors real frame delivery (many small dt calls) rather than one huge
/// dt, since some effects/timers could behave differently under a single
/// oversized step.
///
/// Yields to the microtask queue after EVERY tick (not just once at the
/// end) — required because `TimerComponent.onLoad()` is `async` (per Flame
/// 1.37.0 source), so a newly-`add()`-ed `_TriggerTimer` stays in the
/// "loading/blocked" lifecycle state (per `Component.handleLifecycleEventAdd`)
/// until at least one microtask turn resolves its load. A tight synchronous
/// loop of `game.update(dt)` calls with no yields in between would spend
/// every tick while the timer is still blocked and never actually ticking.
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

/// Drains pending mount/load lifecycle events (via `FlameGame.ready()`)
/// WITHOUT advancing any simulated time — call this right after
/// `mochi.onTrigger(...)` and before `_advance()` starts counting the
/// "real" duration.
///
/// Root cause this works around: `onTrigger()` calls `add()` synchronously,
/// but the new child (an `Effect` or `_TriggerTimer`) only finishes
/// `handleLifecycleEventAdd`'s block→done transition after its `onLoad()`
/// resolves — `TimerComponent.onLoad()` is `async`, so this needs at least
/// one microtask turn. Without settling first, `_advance`'s very first
/// `game.update(dt)` call finds the child still blocked and "loses" that
/// tick's dt entirely (the child was never mounted to receive it) — a
/// ~1-tick (1/60s) timing deficit that made exact-boundary assertions like
/// `_advance(game, 3.0)` then `expect(..., isNull)` fail by one tick, while
/// tests with several ticks of built-in slack (e.g. this file's own
/// duration-table test, which checks `duration - 0.05` / `duration + 0.05`)
/// happened to absorb the deficit unnoticed. Found and fixed via a debug
/// reproduction: `game.ready()` mounts the pending child with zero elapsed
/// time, so every dt passed to `_advance` afterward is time the child is
/// actually live to receive.
Future<void> _settle(FlameGame game) => game.ready();

/// Small overshoot added when a test needs to assert a triggered state has
/// definitely completed by a given nominal duration. `_advance`'s dt-summed
/// total can fall a hair short of the exact nominal duration due to
/// ordinary floating-point accumulation across many small steps (e.g. 90
/// steps of `1/60` does not sum to bit-exact `1.5`) — this is a property of
/// summing floating-point steps, not a bug in the timer/effect completion
/// logic itself. `_TOLERANCE` overshoots by roughly one extra tick.
const double _tolerance = 0.02;

void main() {
  setUp(() => GameEventBus().resetForTesting());

  testWithFlameGame(
    'test_higher_priority_trigger_replaces_and_resets_the_timer',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.pleased); // priority 2
      await _settle(game);
      await _advance(game, 1.0); // 1.0s into pleased's 2.0s

      mochi.onTrigger(TriggeredState.showingOff); // priority 3, higher
      await _settle(game);
      expect(mochi.currentTriggeredState, TriggeredState.showingOff);

      // A fresh 2.0s showingOff timer, not pleased's remaining 1.0s.
      await _advance(game, 1.9);
      expect(mochi.currentTriggeredState, TriggeredState.showingOff);
      await _advance(game, 0.2);
      expect(mochi.currentTriggeredState, isNull);
    },
  );

  testWithFlameGame(
    'test_lower_or_equal_priority_trigger_is_ignored',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.excited); // priority 4
      await _settle(game);
      await _advance(game, 0.5);

      mochi.onTrigger(TriggeredState.bouncing); // priority 1, lower
      expect(mochi.currentTriggeredState, TriggeredState.excited);

      // excited's original 1.5s timer is unaffected by the ignored bounce.
      await _advance(game, 0.9);
      expect(mochi.currentTriggeredState, TriggeredState.excited);
      await _advance(game, 0.2);
      expect(mochi.currentTriggeredState, isNull);
    },
  );

  testWithFlameGame(
    'test_LEVELING_UP_is_non_interruptible_by_a_higher_priority_looking_trigger',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.levelingUp);
      await _settle(game);
      await _advance(game, 1.0);

      mochi.onTrigger(TriggeredState.excited); // normally priority 4
      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);
      expect(mochi.queuedTriggeredState, TriggeredState.excited);
    },
  );

  testWithFlameGame(
    'test_only_the_single_highest_priority_trigger_survives_the_queue',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.levelingUp);
      await _settle(game);
      await _advance(game, 0.5);

      mochi.onTrigger(TriggeredState.bouncing); // priority 1
      mochi.onTrigger(TriggeredState.showingOff); // priority 3 — highest
      mochi.onTrigger(TriggeredState.pleased); // priority 2

      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);
      expect(mochi.queuedTriggeredState, TriggeredState.showingOff);
    },
  );

  testWithFlameGame(
    'test_queued_trigger_replays_immediately_after_LEVELING_UP_completes',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.levelingUp);
      mochi.onTrigger(TriggeredState.excited); // queued (excited < levelingUp)
      await _settle(game);

      await _advance(game, 3.0); // levelingUp's full 3.0s

      expect(mochi.currentTriggeredState, TriggeredState.excited);
      expect(mochi.queuedTriggeredState, isNull);

      // excited's own fresh 1.5s timer, counted from the moment it started
      // playing (not from t=0).
      await _settle(game);
      await _advance(game, 1.4);
      expect(mochi.currentTriggeredState, TriggeredState.excited);
      await _advance(game, 0.2);
      expect(mochi.currentTriggeredState, isNull);
    },
  );

  testWithFlameGame(
    'test_no_queued_trigger_after_LEVELING_UP_returns_to_base_mood',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.levelingUp);
      await _settle(game);
      await _advance(game, 3.0);

      expect(mochi.currentTriggeredState, isNull);
      expect(mochi.queuedTriggeredState, isNull);
    },
  );

  testWithFlameGame(
    'test_SLEEPING_gate_rejects_ordinary_triggers',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(
        const GameEvent(GameEventType.petMoodChanged, MoodState.sleeping),
      );
      await Future<void>.delayed(Duration.zero);

      mochi.onTrigger(TriggeredState.pleased);

      expect(mochi.currentTriggeredState, isNull);
    },
  );

  testWithFlameGame(
    'test_SLEEPING_gate_still_accepts_EXCITED_and_LEVELING_UP',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(
        const GameEvent(GameEventType.petMoodChanged, MoodState.sleeping),
      );
      await Future<void>.delayed(Duration.zero);

      mochi.onTrigger(TriggeredState.excited);
      await _settle(game);
      expect(mochi.currentTriggeredState, TriggeredState.excited);

      await _advance(game, 1.5 + _tolerance);
      expect(mochi.currentTriggeredState, isNull);

      mochi.onTrigger(TriggeredState.levelingUp);
      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);
    },
  );

  testWithFlameGame(
    'test_rapid_same_type_retrigger_clears_the_prior_effect_before_the_next',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.excited);
      await _settle(game);
      await _advance(game, 0.1);
      expect(mochi.children.whereType<Effect>(), hasLength(1));

      // A second trigger — LEVELING_UP (priority 5), the only state with
      // priority genuinely higher than EXCITED's (4), so this is a real
      // replace, not the "ignored" case (SHOWING_OFF's priority 3 is LOWER
      // than EXCITED's — using it here would be silently ignored per the
      // priority rule, not a retrigger, which was this test's original,
      // incorrect assumption). Verifies only one Effect is ever attached at
      // a time (asserted after a subsequent tick, not synchronously, per
      // ADR-0007 Risks).
      mochi.onTrigger(TriggeredState.levelingUp);
      await _settle(game);
      await _advance(game, 0.1);

      expect(mochi.children.whereType<Effect>(), isEmpty);
      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);
    },
  );

  testWithFlameGame(
    'test_exact_triggered_state_durations_match_the_gdd_formulas_table',
    (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      for (final entry in {
        TriggeredState.levelingUp: 3.0,
        TriggeredState.excited: 1.5,
        TriggeredState.pleased: 2.0,
        TriggeredState.showingOff: 2.0,
        TriggeredState.bouncing: 1.0,
      }.entries) {
        mochi.onTrigger(entry.key);
        await _settle(game);
        expect(mochi.currentTriggeredState, entry.key);

        await _advance(game, entry.value - 0.05);
        expect(
          mochi.currentTriggeredState,
          entry.key,
          reason: '${entry.key} should still be playing just before its '
              '${entry.value}s duration elapses',
        );

        await _advance(game, 0.1);
        expect(
          mochi.currentTriggeredState,
          isNull,
          reason: '${entry.key} should have completed by ${entry.value}s',
        );
      }
    },
  );

  test('test_priority_comparisons_never_use_TriggeredState_index', () {
    // Static/source check: TriggeredState's declared order (levelingUp
    // first) is deliberately the OPPOSITE of priority order — .index would
    // invert it. Confirms the explicit priority map is used instead.
    expect(triggeredStatePriority(TriggeredState.levelingUp), 5);
    expect(triggeredStatePriority(TriggeredState.bouncing), 1);
    expect(TriggeredState.levelingUp.index, 0); // declared first...
    expect(triggeredStatePriority(TriggeredState.levelingUp),
        isNot(TriggeredState.levelingUp.index)); // ...but NOT priority 0.
  });

  test(
      'test_priority_and_state_machine_source_never_uses_dot_index_at_all',
      () {
    // A durable regression guard, stronger than the values-based check
    // above — a literal source-string sweep proving `.index` is never used
    // in actual CODE in either file (per qa-tester's recommendation), not
    // just proving the two happen to disagree for one enum value today.
    // Doc-comment lines are excluded — both files' own doc comments
    // correctly MENTION `.index` as the pattern to avoid, which would
    // otherwise false-positive this check.
    bool usesIndexInCode(String path) {
      final codeLines = File(path)
          .readAsLinesSync()
          .where((line) => !line.trim().startsWith('//'));
      return codeLines.any((line) => line.contains('.index'));
    }

    expect(usesIndexInCode('lib/core/triggered_state.dart'), isFalse);
    expect(usesIndexInCode('lib/gameplay/mochi_component.dart'), isFalse);
  });

  testWithFlameGame(
    'test_equal_priority_trigger_does_not_replace_or_reset_the_timer',
    (game) async {
      // "Lower-OR-EQUAL priority is ignored" (ADR-0007 Decision §3) — the
      // existing "lower priority ignored" test only covers the lower half;
      // this covers the equal half specifically: the same state retriggered
      // while it's already playing must not reset its own timer.
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.excited);
      await _settle(game);
      await _advance(game, 1.0); // 1.0s into excited's 1.5s

      mochi.onTrigger(TriggeredState.excited); // same state, same priority

      // If the timer had been reset, this would still be playing at 1.5s
      // total elapsed (0.5s remaining + a fresh 1.5s). Advancing only the
      // ORIGINAL remaining ~0.5s and observing completion proves no reset
      // occurred.
      await _advance(game, 0.5 + _tolerance);
      expect(mochi.currentTriggeredState, isNull);
    },
  );

  testWithFlameGame(
    'test_LEVELING_UP_retriggering_itself_while_already_current_queues_and_replays',
    (game) async {
      // GDD Core Rule 3: "mọi trigger khác đến trong lúc này bị queue và
      // replay sau khi LEVELING_UP kết thúc" — this literally includes a
      // second LEVELING_UP arriving mid-play (e.g. two rapid pet level-ups),
      // not just other trigger types. Documents this as deliberate, tested
      // behavior rather than an unspecified edge case.
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      mochi.onTrigger(TriggeredState.levelingUp);
      await _settle(game);
      await _advance(game, 1.0);

      mochi.onTrigger(TriggeredState.levelingUp); // a second level-up mid-play
      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);
      expect(mochi.queuedTriggeredState, TriggeredState.levelingUp);

      // The FIRST levelingUp completes at its own original 3.0s (2.0s more
      // from here) — not reset by the second trigger.
      await _advance(game, 2.0 + _tolerance);
      // ...then the queued second levelingUp starts playing its own full
      // fresh 3.0s (still current, nothing left queued).
      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);
      expect(mochi.queuedTriggeredState, isNull);
    },
  );

  testWithFlameGame(
    'test_each_trigger_event_type_maps_to_the_correct_TriggeredState_via_the_real_bus',
    (game) async {
      // Closes a real gap qa-tester found: every other test in this file
      // calls mochi.onTrigger() directly, never proving the actual
      // GameEventBus -> MochiComponent.onGameEvent -> onTrigger() mapping
      // (AC bullet 3) is correct end-to-end. A copy/paste bug swapping two
      // event-type cases would have passed every other test in this suite.
      const mapping = {
        GameEventType.taskApproved: TriggeredState.excited,
        GameEventType.petInteracted: TriggeredState.pleased,
        GameEventType.itemEquipped: TriggeredState.showingOff,
        GameEventType.seedReceived: TriggeredState.bouncing,
        GameEventType.petLeveledUp: TriggeredState.levelingUp,
      };

      for (final entry in mapping.entries) {
        GameEventBus().resetForTesting();
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        GameEventBus().emit(GameEvent(entry.key, null));
        await Future<void>.delayed(Duration.zero);

        expect(
          mochi.currentTriggeredState,
          entry.value,
          reason: '${entry.key} should trigger ${entry.value}',
        );

        await game.ensureRemove(mochi);
      }
    },
  );
}
