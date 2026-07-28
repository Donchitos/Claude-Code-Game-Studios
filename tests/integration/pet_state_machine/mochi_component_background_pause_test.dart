// Run with:
//   cd src && flutter test ../tests/integration/pet_state_machine/mochi_component_background_pause_test.dart
//
// IMPORTANT — read before modifying this file:
//
// `FlameGame.pauseEngine()`/`resumeEngine()` only stop/start the REAL
// `GameRenderBox`'s `GameLoop` (verified against Flame 1.37.0 source,
// `game.dart:340-349` — `_gameRenderBox?.gameLoop?.stop()/.start()`), and
// `GameLoop` drives a real Flutter `Ticker` (`game_loop.dart:18`). Neither
// exists in `flame_test`'s headless `testWithFlameGame` harness — there is
// no real widget, so there is no real ticker to stop.
//
// Critically, `FlameGame.updateTree(dt)` (`flame_game.dart:181-189`) does
// NOT check `paused` at all — pausing is enforced entirely by the ticker
// scheduler choosing not to invoke `update()`, not by `update()` refusing to
// progress when called. This means directly calling `game.update(dt)` after
// `pauseEngine()` in a headless test WOULD still tick everything — testing
// that would prove nothing about real pause/resume behavior.
//
// This file therefore tests two things separately, matching what's actually
// verifiable and what actually matters:
//   1. `game.paused`/`lifecycleStateChange()` correctly reflects Flame's own
//      pause bookkeeping (fully real, no faking — same pattern Flame's own
//      `test/game/flame_game_test.dart:340-356` uses).
//   2. A triggered-state timer correctly resumes from exactly where it left
//      off across a pause/resume cycle, using a `_advanceRespectingPause`
//      helper that only calls `game.update(dt)` while `!game.paused` — this
//      accurately models the real ticker's gating behavior (verified above),
//      which is the ACTUAL mechanism `TimerComponent`'s "frame-ticked, pauses
//      with the loop" guarantee (ADR-0007 Decision §4) depends on.

import 'dart:io';

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';

/// Ticks [game] forward by [totalSeconds], but ONLY while `!game.paused` —
/// models the real Flutter `Ticker`'s gating behavior (see file header).
/// Calling this while paused advances zero simulated time, exactly like the
/// real ticker not firing.
Future<void> _advanceRespectingPause(
  FlameGame game,
  double totalSeconds, {
  double step = 1 / 60,
}) async {
  var remaining = totalSeconds;
  while (remaining > 0) {
    if (game.paused) {
      return; // The real ticker would not be calling update() right now.
    }
    final dt = remaining < step ? remaining : step;
    game.update(dt);
    await Future<void>.delayed(Duration.zero);
    remaining -= dt;
  }
}

Future<void> _settle(FlameGame game) => game.ready();

const double _tolerance = 0.02;

void main() {
  setUp(() => GameEventBus().resetForTesting());

  group('game.paused bookkeeping (real Flame mechanics, no faking)', () {
    testWithFlameGame(
      'test_pauseWhenBackgrounded_true_by_default_on_a_fresh_FlameGame',
      (game) async {
        expect(game.pauseWhenBackgrounded, isTrue);
      },
    );

    testWithFlameGame(
      'test_paused_detached_hidden_all_pause_the_engine',
      (game) async {
        for (final state in [
          AppLifecycleState.paused,
          AppLifecycleState.detached,
          AppLifecycleState.hidden,
        ]) {
          game.resumeEngine();
          expect(game.paused, isFalse);

          game.lifecycleStateChange(state);
          expect(game.paused, isTrue, reason: '$state should pause the engine');
        }
      },
    );

    testWithFlameGame(
      'test_inactive_alone_does_not_pause_the_engine',
      (game) async {
        // ADR-0007 Decision §4's explicit claim: a brief control-center
        // swipe or call banner (inactive) does NOT pause — only an actually
        // backgrounded state does. Verified directly against Flame 1.37.0
        // source (flame_game.dart:329-345): `inactive` is grouped with
        // `resumed` in the lifecycle switch, not with `paused`/`detached`/
        // `hidden`.
        expect(game.paused, isFalse);
        game.lifecycleStateChange(AppLifecycleState.inactive);
        expect(game.paused, isFalse);
      },
    );

    testWithFlameGame(
      'test_resumed_un_pauses_after_a_background_pause',
      (game) async {
        game.lifecycleStateChange(AppLifecycleState.paused);
        expect(game.paused, isTrue);

        game.lifecycleStateChange(AppLifecycleState.resumed);
        expect(game.paused, isFalse);
      },
    );
  });

  group('Triggered-state timer across a pause/resume cycle', () {
    testWithFlameGame(
      'test_a_triggered_state_timer_does_not_advance_while_paused',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        mochi.onTrigger(TriggeredState.excited); // 1.5s duration
        await _settle(game);
        await _advanceRespectingPause(game, 0.5); // 0.5s into 1.5s

        game.lifecycleStateChange(AppLifecycleState.paused);
        expect(game.paused, isTrue);

        // The real ticker would not call update() here — this helper
        // enforces exactly that. If it did progress, excited (1.5s total)
        // would complete by 0.5 + 2.0 = 2.5s; it must NOT.
        await _advanceRespectingPause(game, 2.0);

        expect(
          mochi.currentTriggeredState,
          TriggeredState.excited,
          reason: 'a paused game must not advance the triggered-state timer',
        );
      },
    );

    testWithFlameGame(
      'test_a_paused_triggered_state_timer_resumes_from_exactly_where_it_left_off',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        mochi.onTrigger(TriggeredState.excited); // 1.5s duration
        await _settle(game);
        await _advanceRespectingPause(game, 0.5); // 0.5s elapsed

        game.lifecycleStateChange(AppLifecycleState.paused);
        await _advanceRespectingPause(game, 10.0); // no-op while paused

        game.lifecycleStateChange(AppLifecycleState.resumed);
        expect(game.paused, isFalse);

        // Exactly the REMAINING 1.0s (not a fresh 1.5s — would mean it
        // restarted; not already complete — would mean it kept counting
        // through the pause).
        await _advanceRespectingPause(game, 1.0 - 0.1);
        expect(
          mochi.currentTriggeredState,
          TriggeredState.excited,
          reason: 'should still be playing just before the remaining time '
              'elapses',
        );

        await _advanceRespectingPause(game, 0.1 + _tolerance);
        expect(
          mochi.currentTriggeredState,
          isNull,
          reason: 'should complete after exactly the remaining 1.0s, no '
              'more and no less',
        );
      },
    );

    testWithFlameGame(
      'test_LEVELING_UP_timer_also_pauses_and_resumes_correctly',
      (game) async {
        // Covers the TimerComponent-driven mechanism too, not just the
        // Effect-driven one above — both must respect the same pause
        // behavior since both are frame-ticked via update(dt).
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        mochi.onTrigger(TriggeredState.levelingUp); // 3.0s duration
        await _settle(game);
        await _advanceRespectingPause(game, 1.0);

        game.lifecycleStateChange(AppLifecycleState.paused);
        await _advanceRespectingPause(game, 5.0); // no-op while paused
        expect(mochi.currentTriggeredState, TriggeredState.levelingUp);

        game.lifecycleStateChange(AppLifecycleState.resumed);
        await _advanceRespectingPause(game, 2.0 + _tolerance); // remaining
        expect(mochi.currentTriggeredState, isNull);
      },
    );
  });

  test(
      'test_every_FlameGame_subclass_in_the_codebase_respects_pauseWhenBackgrounded',
      () {
    // Standing constraint (ADR-0007 Risks): "nothing may set
    // pauseWhenBackgrounded=false on the shared FlameGame; any
    // lifecycleStateChange() override must call super." Originally this test
    // only asserted N/A (no FlameGame subclass existed anywhere in the
    // codebase). main-navigation-shell Story 002 added the first one
    // (`PetRoomGame`, `lib/gameplay/pet_room_game.dart`, a placeholder Pet
    // Room `FlameGame` for the Child Shell's AC-5 branch-preservation test) —
    // per this file's own prior self-documented instruction, this test now
    // actually scans source instead of asserting emptiness.
    final gameplayDir = Directory('lib/gameplay');
    final flameGameSubclassFiles = gameplayDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('extends FlameGame'))
        .toList();

    expect(
      flameGameSubclassFiles,
      isNotEmpty,
      reason: 'No FlameGame subclass found — if one was removed, revert this '
          'test to asserting isEmpty per its original N/A form.',
    );

    for (final file in flameGameSubclassFiles) {
      final source = file.readAsStringSync();
      expect(
        source.contains('pauseWhenBackgrounded = false') ||
            source.contains('pauseWhenBackgrounded=false'),
        isFalse,
        reason: '${file.path} sets pauseWhenBackgrounded=false — forbidden '
            'by ADR-0007 Risks, breaks background-pause behavior for every '
            'triggered-state timer.',
      );

      final overridesLifecycleChange =
          source.contains('lifecycleStateChange(');
      if (overridesLifecycleChange) {
        expect(
          source.contains('super.lifecycleStateChange('),
          isTrue,
          reason: '${file.path} overrides lifecycleStateChange() without '
              'calling super — forbidden by ADR-0007 Risks, breaks Flame\'s '
              'own pause bookkeeping.',
        );
      }
    }
  });
}
