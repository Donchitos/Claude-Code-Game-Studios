// Run with:
//   cd src && flutter test ../tests/integration/pet-room-screen-ui/modal_defer_triggered_visuals_test.dart
//
// Story 004 (Modal Defer for Wardrobe / Competing GameEvent), Pet Room
// Screen UI epic. ADR-0017 Decision → TR-petroom-004. Covers this story's 2
// QA Test Cases:
//   - AC-EC4-1: modal open + a GameEvent fires -> Base Mood/internal state
//     still updates immediately, but no triggered-state visual plays; the
//     highest-priority pending trigger is tracked instead.
//   - AC-EC4-2: modal closes -> the pending visual plays, reflecting
//     whatever state was updated while the modal was open.
// Plus a PetRoomGame-level integration check that showModal/dismissModal
// (Story 003) actually emit GameEventType.modalVisibilityChanged, since
// that wiring is this story's own scope, not Story 003's.
//
// `GameEventBus`'s underlying `StreamController.broadcast()` is built
// WITHOUT `sync: true` (ADR-0004 §5 — deliberate, for reentrancy safety), so
// every `.emit(...)` call below is followed by an `await` (a microtask
// flush for `testWithFlameGame` tests, `tester.pump()` for `testWidgets`
// ones) before asserting on the delivered effect — an unawaited emit would
// assert against pre-delivery state and silently pass for the wrong reason.

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';
import 'package:pet_quest/gameplay/pet_room_game.dart';
import 'package:pet_quest/ui/pet_room_screen.dart';

/// Flushes the microtask queue so a just-`emit`ted [GameEvent] (delivered
/// asynchronously — see file header) has actually reached its subscriber
/// before the next line asserts on the effect.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

/// Ticks [game] forward by [totalSeconds] using small increments, yielding
/// to the microtask queue every tick — required because
/// `TimerComponent.onLoad()` is `async` (Flame 1.37), so a newly-`add`ed
/// `_TriggerTimer` needs at least one microtask turn before it's actually
/// live to receive ticks. Duplicated from
/// `mochi_component_triggered_state_test.dart` — private helpers can't be
/// shared across test files (that file's own header comment).
Future<void> _advance(FlameGame game, double totalSeconds, {double step = 1 / 60}) async {
  var remaining = totalSeconds;
  while (remaining > 0) {
    final dt = remaining < step ? remaining : step;
    game.update(dt);
    await Future<void>.delayed(Duration.zero);
    remaining -= dt;
  }
}

/// Drains pending mount/load lifecycle events without advancing simulated
/// time — call right after `mochi.onTrigger(...)`/`add(mochi)` and before
/// `_advance()` starts counting. Same rationale/duplication as `_advance`.
Future<void> _settle(FlameGame game) => game.ready();

/// Overshoot added when asserting a triggered state has definitely
/// completed by its nominal duration — floating-point step summation can
/// fall a hair short of the exact value. Duplicated, same reason.
const double _tolerance = 0.05;

/// Pumps [steps] small, fixed-size frames instead of `pumpAndSettle()` —
/// `PetRoomScreen`'s `GameWidget` keeps a `Ticker` perpetually scheduled once
/// mounted (ADR-0014 Decision §2). Duplicated from
/// `composition_and_modal_exclusivity_test.dart` — private helpers can't be
/// shared across test files (that file's own header comment).
Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

/// `PetRoomGame` cannot be constructed via `testWithGame<PetRoomGame>` (bare
/// unit-test harness) — its `onLoad()` both adds the `'chrome'` overlay key
/// (which only exists if a real `overlayBuilderMap` registered it, which
/// only `GameWidget` does) and loads a real sprite asset (which needs a real
/// `ServicesBinding`/asset bundle) — confirmed via a real failed test run
/// during this story's implementation, not assumed. This mirrors
/// `composition_and_modal_exclusivity_test.dart`'s own `_pumpPetRoomScreen`
/// helper exactly (duplicated for the same "can't share private helpers"
/// reason).
Future<PetRoomGame> _pumpPetRoomScreen(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: PetRoomScreen()));
  await _pumpSteps(tester, 6);
  return tester
      .widget<GameWidget<PetRoomGame>>(find.byType(GameWidget<PetRoomGame>))
      .game!;
}

void main() {
  setUp(() => GameEventBus().resetForTesting());

  group('AC-EC4-1: modal open defers the visual, not the state update', () {
    testWithFlameGame(
        'test_modalOpen_petMoodChangedAndPetLeveledUp_stateUpdatesImmediately_noVisualPlays_pendingTracksLevelingUp',
        (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);

      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, true));
      await _flush();

      GameEventBus().emit(const GameEvent(GameEventType.petMoodChanged, MoodState.happy));
      GameEventBus().emit(const GameEvent(GameEventType.petLeveledUp, null));
      await _flush();

      expect(
        mochi.baseMood,
        MoodState.happy,
        reason: 'internal state (Base Mood) must update immediately, even '
            'while a modal is open — only the VISUAL is deferred',
      );
      expect(
        mochi.currentTriggeredState,
        isNull,
        reason: 'no triggered-state visual may play while a modal is open',
      );
      expect(
        mochi.pendingVisual,
        TriggeredState.levelingUp,
        reason: 'the deferred trigger must be tracked as pending',
      );
    });

    testWithFlameGame(
        'test_modalOpen_lowerPriorityTriggerAfterHigherPriorityPending_doesNotOverwritePending',
        (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, true));
      await _flush();

      GameEventBus().emit(const GameEvent(GameEventType.petLeveledUp, null)); // levelingUp
      await _flush();
      GameEventBus().emit(const GameEvent(GameEventType.seedReceived, null)); // bouncing (lower priority)
      await _flush();

      expect(
        mochi.pendingVisual,
        TriggeredState.levelingUp,
        reason: 'a lower-priority pending trigger must not overwrite an '
            'already-pending higher-priority one — same rule '
            "_queueHighest already enforces for ADR-0007's own queue",
      );
      expect(
        mochi.currentTriggeredState,
        isNull,
        reason: 'still nothing playing — the modal is still open',
      );
    });

    testWithFlameGame(
        'test_modalOpen_higherPriorityTriggerAfterLowerPriorityPending_overwritesPending',
        (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, true));
      await _flush();

      GameEventBus().emit(const GameEvent(GameEventType.seedReceived, null)); // bouncing
      await _flush();
      GameEventBus().emit(const GameEvent(GameEventType.petLeveledUp, null)); // levelingUp (higher priority)
      await _flush();

      expect(mochi.pendingVisual, TriggeredState.levelingUp);
    });
  });

  group('AC-EC4-2: modal close replays the pending visual', () {
    testWithFlameGame(
        'test_modalClose_deferredTriggerPlaysAndPendingSlotClears',
        (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, true));
      await _flush();
      GameEventBus().emit(const GameEvent(GameEventType.petLeveledUp, null));
      await _flush();
      expect(mochi.currentTriggeredState, isNull);
      expect(mochi.pendingVisual, TriggeredState.levelingUp);

      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, false));
      await _flush();

      expect(
        mochi.currentTriggeredState,
        TriggeredState.levelingUp,
        reason: 'the pending visual must play the moment the modal closes',
      );
      expect(
        mochi.pendingVisual,
        isNull,
        reason: 'the pending slot must be cleared once replayed',
      );
    });

    testWithFlameGame(
        'test_modalClose_withNothingPending_isNoOp_noSpuriousTrigger',
        (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, true));
      await _flush();
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, false));
      await _flush();

      expect(mochi.currentTriggeredState, isNull);
      expect(mochi.pendingVisual, isNull);
    });

    testWithFlameGame(
        'test_triggerAfterModalAlreadyClosed_isNotDeferred_normalOnTriggerApplies',
        (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, true));
      await _flush();
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, false));
      await _flush();

      GameEventBus().emit(const GameEvent(GameEventType.seedReceived, null));
      await _flush();

      expect(
        mochi.currentTriggeredState,
        TriggeredState.bouncing,
        reason: 'once the modal is closed, the defer guard must no longer apply',
      );
      expect(mochi.pendingVisual, isNull);
    });
  });

  group(
      'ADR-0007 _queued interaction (flame-specialist code-review finding — a real bug, not a hypothetical)',
      () {
    testWithFlameGame(
        'test_queuedTriggerDequeuingWhileModalStillOpen_doesNotPlay_becomesPendingInstead',
        (game) async {
      final mochi = MochiComponent();
      await game.ensureAdd(mochi);
      await _settle(game);

      // 1. LEVELING_UP starts playing (non-interruptible, 3.0s).
      mochi.onTrigger(TriggeredState.levelingUp);
      await _settle(game);
      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);

      // 2. A lower-priority trigger arrives while LEVELING_UP plays — per
      // ADR-0007, it queues into `_queued` (NOT `_pendingVisual` — the
      // modal isn't open yet).
      mochi.onTrigger(TriggeredState.excited);
      expect(mochi.queuedTriggeredState, TriggeredState.excited);

      // 3. A modal opens WHILE LEVELING_UP is still playing — per
      // `onTrigger`'s own modal guard, an already-playing state is not
      // interrupted.
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, true));
      await _flush();
      expect(mochi.currentTriggeredState, TriggeredState.levelingUp);

      // 4. LEVELING_UP's 3.0s timer completes WHILE the modal is STILL
      // open. Before the fix, `_onTriggerComplete` called `_play(excited)`
      // unconditionally here — a real triggered-state visual would start
      // playing on top of the still-open modal, violating AC-EC4-1.
      await _advance(game, triggeredStateDuration(TriggeredState.levelingUp) + _tolerance);

      expect(
        mochi.currentTriggeredState,
        isNull,
        reason: 'the dequeued EXCITED trigger must NOT play while the '
            'modal is still open — this is the exact bug flame-specialist '
            'found in code review (_onTriggerComplete bypassed the modal '
            'gate)',
      );
      expect(
        mochi.pendingVisual,
        TriggeredState.excited,
        reason: 'it must become pending instead, replayed once the modal closes',
      );
      expect(
        mochi.queuedTriggeredState,
        isNull,
        reason: '_queued must be cleared — the trigger moved to _pendingVisual, not left in both slots',
      );

      // 5. Closing the modal now plays it.
      GameEventBus().emit(const GameEvent(GameEventType.modalVisibilityChanged, false));
      await _flush();
      expect(mochi.currentTriggeredState, TriggeredState.excited);
      expect(mochi.pendingVisual, isNull);
    });
  });

  group(
      "PetRoomGame wiring: showModal/dismissModal emit modalVisibilityChanged (this story's own call-site scope, not Story 003's)",
      () {
    testWidgets(
        'test_showModal_emitsModalVisibilityChangedTrue_dismissModal_emitsFalse',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);
      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      game.showModal('context_menu');
      await tester.pump();
      expect(events, hasLength(1));
      expect(events.single.type, GameEventType.modalVisibilityChanged);
      expect(events.single.data, isTrue);

      game.dismissModal();
      await tester.pump();
      expect(events, hasLength(2));
      expect(events.last.type, GameEventType.modalVisibilityChanged);
      expect(events.last.data, isFalse);
    });

    testWidgets(
        'test_switchingModalDirectly_contextMenuToWardrobe_stillEmitsTrueAgain_notSkipped',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);
      final events = <bool>[];
      final sub = GameEventBus().stream.listen((e) {
        if (e.type == GameEventType.modalVisibilityChanged) {
          events.add(e.data as bool);
        }
      });
      addTearDown(sub.cancel);

      // showModal -> showModal (switching context_menu -> wardrobe
      // directly, per AC-CR1-2/Story 003) must still emit `true` again,
      // not skip it just because a modal was already open.
      game.showModal('context_menu');
      await tester.pump();
      game.showModal('wardrobe');
      await tester.pump();
      game.dismissModal();
      await tester.pump();

      expect(events, [true, true, false]);
    });
  });
}
