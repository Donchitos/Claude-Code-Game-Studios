// Run with:
//   cd src && flutter test ../tests/integration/pet_state_machine/mochi_component_background_pause_real_ticker_test.dart
//
// A stronger, more direct companion to
// mochi_component_background_pause_test.dart's `_advanceRespectingPause`-based
// tests: this file drives triggered-state pause/resume through a REAL
// GameWidget -> GameRenderBox -> GameLoop -> Ticker pipeline (via flame_test's
// `FlameTester.testGameWidget`, which pumps a real `GameWidget` inside
// `tester.runAsync` — escaping the fake-async zone during setup so Flame's
// real `Ticker` genuinely starts), rather than a helper that only MODELS the
// ticker's gating behavior. Spun off as a follow-up per flame-specialist's
// suggestion during Story 004's code review (see that story's Completion
// Notes in `production/epics/pet-state-machine/story-004-...md`) — not
// required for the story's closure (already Complete), but strictly more
// direct evidence than the simulated-pause tests alone.

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';

final _tester = FlameTester(FlameGame.new);

/// Advances the real ticker by [duration], delivered as many small pumps
/// rather than one large `tester.pump(duration)` call.
///
/// A single large `tester.pump(duration)` does NOT reliably deliver that
/// much elapsed time to the `GameLoop`'s `Ticker` callback in this harness —
/// confirmed by direct instrumentation (temporary debug build, since
/// removed) that watched `MochiComponent`'s own `scale.x` climb correctly
/// under many small pumps but under-progress under one large pump. Small
/// per-tick pumps mirror how a real device actually drives the ticker (one
/// frame at a time) and is the proven-reliable pattern.
///
/// Also absorbs the real ticker's first-tick-after-restart artifact: both
/// the very first mount and every resume-from-pause report a near-zero `dt`
/// on their first callback (`GameLoop._previous` is reset to `Duration.zero`
/// on `stop()`, and the underlying Flutter `Ticker` restarts its own
/// elapsed-time reference on `start()`) — costing roughly one step's worth
/// of real progress. Callers should pass a target slightly past the exact
/// nominal boundary to comfortably clear both this artifact and ordinary
/// step-summation slack (mirrors `_tolerance` in the sibling simulated-pause
/// test file, which handles the analogous — but distinct — floating-point
/// dt-summation artifact for manually-summed dt values).
Future<void> _pumpRealTicker(
  WidgetTester tester,
  Duration total, {
  Duration step = const Duration(milliseconds: 50),
}) async {
  var remaining = total;
  while (remaining > Duration.zero) {
    final thisStep = remaining < step ? remaining : step;
    await tester.pump(thisStep);
    remaining -= thisStep;
  }
}

void main() {
  setUp(() => GameEventBus().resetForTesting());

  tearDown(() {
    // Restore the real lifecycle state so a paused state from one test
    // doesn't leak into the next test file run in the same process —
    // mirrors Flame's own bundled test suite's teardown for this exact API
    // (test/game/flame_game_test.dart:367-374).
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
  });

  _tester.testGameWidget(
    'test_an_Effect_driven_triggered_state_pauses_and_resumes_through_the_real_ticker',
    setUp: (game, tester) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      mochi.onTrigger(TriggeredState.excited); // 1.5s duration, ScaleEffect
      await game.ready();
    },
    verify: (game, tester) async {
      final mochi = game.children.whereType<MochiComponent>().single;

      // 0.5s of REAL frame-driven ticks through the actual GameLoop/Ticker
      // (not the modeled `_advanceRespectingPause` helper from the sibling
      // simulated-pause test file).
      await _pumpRealTicker(tester, const Duration(milliseconds: 500));
      expect(mochi.currentTriggeredState, TriggeredState.excited);

      // A real OS lifecycle event — genuinely stops the Ticker via
      // FlameGame.lifecycleStateChange -> pauseEngine ->
      // _gameRenderBox.gameLoop.stop().
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      expect(game.paused, isTrue);

      // Pumping more frames while paused must have NO effect — the real
      // ticker is genuinely stopped, so update(dt) is never invoked at all
      // while backgrounded (not merely "chose to ignore" a call).
      await _pumpRealTicker(tester, const Duration(seconds: 2));
      expect(
        mochi.currentTriggeredState,
        TriggeredState.excited,
        reason: 'the real ticker is stopped; no frames should have reached '
            'MochiComponent while backgrounded',
      );

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      expect(game.paused, isFalse);

      // The remaining 1.0s (1.5s duration - 0.5s already elapsed), plus a
      // small overshoot to clear the resume artifact and step slack (see
      // `_pumpRealTicker`'s doc comment).
      await _pumpRealTicker(tester, const Duration(milliseconds: 1200));
      expect(mochi.currentTriggeredState, isNull);
    },
  );

  _tester.testGameWidget(
    'test_a_TimerComponent_driven_triggered_state_pauses_and_resumes_through_the_real_ticker',
    setUp: (game, tester) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      mochi.onTrigger(TriggeredState.levelingUp); // 3.0s duration, TimerComponent
      await game.ready();
    },
    verify: (game, tester) async {
      final mochi = game.children.whereType<MochiComponent>().single;

      await _pumpRealTicker(tester, const Duration(milliseconds: 1000));
      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await _pumpRealTicker(tester, const Duration(seconds: 3));
      expect(
        mochi.currentTriggeredState,
        TriggeredState.levelingUp,
        reason: 'the real ticker is stopped; the TimerComponent-driven '
            'mechanism must pause exactly like the Effect-driven one',
      );

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      // The remaining 2.0s (3.0s duration - 1.0s already elapsed), plus a
      // small overshoot.
      await _pumpRealTicker(tester, const Duration(milliseconds: 2200));
      expect(mochi.currentTriggeredState, isNull);
    },
  );

  _tester.testGameWidget(
    'test_inactive_alone_does_not_pause_the_real_ticker',
    setUp: (game, tester) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      mochi.onTrigger(TriggeredState.excited); // 1.5s duration
      await game.ready();
    },
    verify: (game, tester) async {
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      expect(game.paused, isFalse);

      // Time keeps advancing normally through a mere `inactive` state — no
      // pause/resume cycle occurs here at all.
      await _pumpRealTicker(tester, const Duration(milliseconds: 1600));
      final mochi = game.children.whereType<MochiComponent>().single;
      expect(mochi.currentTriggeredState, isNull);
    },
  );
}
