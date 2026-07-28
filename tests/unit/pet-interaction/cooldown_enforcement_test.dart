// Run with:
//   cd src && flutter test ../tests/unit/pet-interaction/cooldown_enforcement_test.dart
//
// Story 003 (Per-Type Cooldown Enforcement). Tests the per-type cooldown
// mechanism (ADR-0016 "Pet Interaction Input Handling" Decision §2,
// TR-petinteraction-002) — two independent, nullable `DateTime?` fields
// (`_lastTapAt`/`_lastSwipeAt`), a lazy wall-clock comparison against an
// injected clock, NOT a `Timer`/`TimerComponent` of any kind. Every test
// here mounts Mochi in a non-SLEEPING Base Mood with no active Triggered
// State, so `evaluateInteractionGuard` (Story 002) always resolves to
// `InteractionGuardResult.emit` and this story's own cooldown check is
// what's actually under test — deliberately distinct scope from Story
// 001's classification suite (`gesture_classification_test.dart`) and
// Story 002's guard suite (`interaction_state_guards_test.dart`).
//
// Uses the same injected-clock technique as
// `gesture_classification_test.dart`'s
// `test_real_qualifying_distance_but_duration_over_300ms_via_injected_clock_is_tap`:
// a mutable `fakeNow` variable captured by the `now: () => fakeNow`
// constructor closure, advanced between calls so the SAME injected clock
// (Story 001's, reused per ADR-0016 Decision §2 — no second clock field)
// drives both gesture classification and cooldown comparison
// deterministically.
//
// Implements exactly the QA Test Cases the story file specifies (AC-3,
// AC-4, AC-5) — no additional scenarios invented, per the story's own
// "do not invent new test cases during implementation" instruction.
//
// Isolating cooldown from Story 002's PLEASED guard: every successful
// `petInteracted` emission makes `MochiComponent` itself (via
// `GameEventSubscriber`, ADR-0004) immediately trigger its own PLEASED
// Triggered State (2.0s, `triggered_state.dart`), which Story 002's guard
// (out of this story's scope — see story's Out of Scope note) then blocks
// ANY subsequent interaction attempt against until that 2.0s Flame-tick-
// driven animation completes, regardless of cooldown state. For the
// "succeeds" scenarios below (where a SECOND gesture must reach the
// cooldown check to prove it correctly allows the attempt through), the
// PLEASED window is drained first via `_advance` — Flame-tick-based, and
// therefore entirely independent of the wall-clock `fakeNow` axis the
// cooldown check itself reads from — so what's actually being proven is
// the cooldown comparison, not an accidental interaction with the
// unrelated guard. For the "blocked" scenarios, no drain is needed: the
// assertion is simply "no event", which holds whether cooldown or the
// (still-active) PLEASED guard is the proximate cause — either is a valid
// witness of "blocked".
//
// qa-tester code-review flagged (2026-07-23) an important CROSS-STORY
// observation from the drain technique above, which this comment
// preserves rather than papers over: in ordinary foregrounded gameplay,
// Flame-tick time and wall-clock time advance together (`update(dt)` is
// driven by real elapsed frame time), so the "succeeds" scenarios this
// file proves at the cooldown-check level (AC-3 @1000/1001ms, AC-5
// @200ms) would, on a single real timeline WITHOUT the artificial
// `_advance` drain, still be blocked by Story 002's type-agnostic 2.0s
// PLEASED guard — which every successful `petInteracted` emission
// triggers unconditionally, regardless of interaction type. That means
// the *cooldown* mechanism this story owns is correct and independently
// verified here exactly as ADR-0016 §Decision 2 requires ("trivially
// unit-testable without a real clock or a real Flame game loop" — the
// ADR's own Requirements section), but the *composed* real-gameplay
// behavior of Story 002 + Story 003 together effectively makes tap's
// 1.0s cooldown unreachable as the binding constraint (PLEASED's 2.0s
// always dominates first). This is a legitimate architecture/product
// question — not a defect in this story's own implementation, and not
// something this story is authorized to resolve by modifying Story 002's
// (already-Complete, out-of-this-story's-scope) guard — so it has been
// escalated as a follow-up task rather than silently fixed or hidden
// here. See the story file's Completion Notes → Deviations for the full
// writeup.

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/cooldown_policy.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/interaction_type.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';

void main() {
  // qa-tester suggestion (2026-07-23, non-blocking): a pure-Dart group
  // against `cooldownElapsed` directly — no Flame, no PLEASED-drain
  // workaround needed — validating the boundary math in total isolation.
  // Mirrors Story 002's own `evaluateInteractionGuard (pure logic)` group
  // in `interaction_state_guards_test.dart`.
  group('cooldownElapsed (pure logic)', () {
    test('test_cooldownElapsed_null_lastAt_is_always_elapsed', () {
      // Arrange
      final now = DateTime(2026);

      // Act
      final result = cooldownElapsed(
        null,
        const Duration(milliseconds: 1000),
        now,
      );

      // Assert
      expect(result, isTrue);
    });

    test('test_cooldownElapsed_difference_less_than_cooldown_is_blocked', () {
      // Arrange
      final lastAt = DateTime(2026);
      final now = lastAt.add(const Duration(milliseconds: 999));

      // Act
      final result = cooldownElapsed(
        lastAt,
        const Duration(milliseconds: 1000),
        now,
      );

      // Assert
      expect(result, isFalse);
    });

    test(
      'test_cooldownElapsed_difference_exactly_equal_to_cooldown_is_elapsed_inclusive_boundary',
      () {
        // Arrange — ADR-0016 §2: boundary is inclusive; the block
        // condition is strictly `< cooldown`, so `== cooldown` elapses.
        final lastAt = DateTime(2026);
        final now = lastAt.add(const Duration(milliseconds: 1000));

        // Act
        final result = cooldownElapsed(
          lastAt,
          const Duration(milliseconds: 1000),
          now,
        );

        // Assert
        expect(result, isTrue);
      },
    );

    test(
      'test_cooldownElapsed_difference_greater_than_cooldown_is_elapsed',
      () {
        // Arrange
        final lastAt = DateTime(2026);
        final now = lastAt.add(const Duration(milliseconds: 1001));

        // Act
        final result = cooldownElapsed(
          lastAt,
          const Duration(milliseconds: 1000),
          now,
        );

        // Assert
        expect(result, isTrue);
      },
    );

    test(
      'test_cooldownElapsed_is_independent_per_cooldown_duration_argument',
      () {
        // Arrange — same lastAt/now (1500ms elapsed), different per-type
        // cooldown durations passed by the caller (tap 1000ms vs swipe
        // 2000ms) — proves the function itself has no type-specific
        // knowledge; independence (AC-5) is entirely a caller concern
        // (MochiComponent's switch, one call per field).
        final lastAt = DateTime(2026);
        final now = lastAt.add(const Duration(milliseconds: 1500));

        // Act
        final tapElapsed = cooldownElapsed(
          lastAt,
          const Duration(milliseconds: 1000),
          now,
        );
        final swipeElapsed = cooldownElapsed(
          lastAt,
          const Duration(milliseconds: 2000),
          now,
        );

        // Assert
        expect(tapElapsed, isTrue, reason: '1500ms >= 1000ms tap cooldown');
        expect(
          swipeElapsed,
          isFalse,
          reason: '1500ms < 2000ms swipe cooldown',
        );
      },
    );
  });

  group('Per-type cooldown enforcement (AC-3/AC-4/AC-5)', () {
    setUp(() => GameEventBus().resetForTesting());

    /// Mounts a HAPPY-mood Mochi (guards always resolve to `emit`) wired to
    /// [fakeNowRef]'s current value via a closure — matching
    /// `gesture_classification_test.dart`'s injected-clock pattern so the
    /// test can advance time between gesture attempts without a real
    /// clock or a real Flame game loop.
    Future<MochiComponent> mountHappyMochi(
      FlameGame game,
      DateTime Function() now,
    ) async {
      final mochi = MochiComponent(now: now);
      await game.ensureAdd(mochi);
      GameEventBus().emit(
        const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
      );
      await Future<void>.delayed(Duration.zero);
      return mochi;
    }

    testWithFlameGame(
      'test_AC3_second_tap_at_500ms_within_1000ms_tap_cooldown_is_blocked',
      (game) async {
        var fakeNow = DateTime(2026);
        final mochi = await mountHappyMochi(game, () => fakeNow);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        // First tap at t=0 — establishes the tap cooldown window.
        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);
        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          hasLength(1),
        );

        // Second tap at t=500ms — strictly within the 1000ms tap cooldown.
        fakeNow = fakeNow.add(const Duration(milliseconds: 500));
        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          hasLength(1),
          reason: 'the t=500ms tap must not emit a second GameEvent',
        );
      },
    );

    // qa-tester suggestion (2026-07-23, non-blocking): a blocked attempt
    // must leave the stored cooldown timestamp untouched — ADR-0016 §2's
    // own wording is explicit ("updated only when that type's gesture is
    // actually emitted"). Not itself one of the story's QA Test Cases,
    // but a load-bearing property of `_handleClassifiedGesture`'s branch
    // structure with otherwise zero coverage: a regression here (e.g. an
    // accidental `_lastTapAt = now;` placed before the early-return
    // instead of after it) would silently widen every subsequent
    // cooldown window from a blocked attempt's timestamp instead of the
    // original one, and none of the AC-3/AC-4/AC-5 tests above would
    // catch it.
    testWithFlameGame(
      'test_AC3_a_blocked_tap_attempt_does_not_reset_the_stored_cooldown_timestamp',
      (game) async {
        // Arrange. Subscribe BEFORE any interaction (matches every other
        // test in this file) — `GameEventBus` replays the last cached
        // event per type to a newly-subscribing listener (ADR-0004 §5),
        // so subscribing mid-test would spuriously inflate the count with
        // a replayed event rather than a genuinely new one.
        var fakeNow = DateTime(2026);
        final mochi = await mountHappyMochi(game, () => fakeNow);
        final originalTapAt = fakeNow;
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        // Act: first tap at t=0 establishes the window; drain PLEASED so
        // the later attempts reach the cooldown check, not the guard.
        await _emitThenDrainPleased(game, mochi.simulateTapForTesting);
        expect(mochi.lastTapAt, originalTapAt);

        // A blocked attempt at t=500ms (cooldown itself is now the sole
        // reason it's blocked, since PLEASED was already drained above).
        fakeNow = fakeNow.add(const Duration(milliseconds: 500));
        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);

        // Assert: the blocked attempt must NOT have moved the stored
        // timestamp forward to t=500ms, and must not have emitted.
        expect(mochi.lastTapAt, originalTapAt);
        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          hasLength(1),
        );

        // A third attempt at t=1000ms (measured from the ORIGINAL t=0,
        // not from the blocked t=500ms attempt) must succeed — proving
        // the timestamp genuinely never moved. If the blocked attempt
        // had incorrectly reset `_lastTapAt` to t=500ms, this would
        // still read as only 500ms elapsed and remain blocked.
        fakeNow = fakeNow.add(const Duration(milliseconds: 500));
        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(2));
        expect(mochi.lastTapAt, fakeNow);
      },
    );

    testWithFlameGame(
      'test_AC3_boundary_tap_at_exactly_1000ms_after_first_tap_succeeds',
      (game) async {
        var fakeNow = DateTime(2026);
        final mochi = await mountHappyMochi(game, () => fakeNow);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        await _emitThenDrainPleased(game, mochi.simulateTapForTesting); // t=0

        // Exactly 1000ms later — inclusive boundary (ADR-0016 §2: block
        // condition is strictly `< cooldown`; 1000ms == 1000ms is not
        // `< 1000ms`, so this succeeds).
        fakeNow = fakeNow.add(const Duration(milliseconds: 1000));
        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(2));
        expect(interacted.last.data, InteractionType.tap);
      },
    );

    testWithFlameGame(
      'test_AC3_tap_at_1001ms_after_first_tap_succeeds',
      (game) async {
        var fakeNow = DateTime(2026);
        final mochi = await mountHappyMochi(game, () => fakeNow);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        await _emitThenDrainPleased(game, mochi.simulateTapForTesting); // t=0

        fakeNow = fakeNow.add(const Duration(milliseconds: 1001));
        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(2));
        expect(interacted.last.data, InteractionType.tap);
      },
    );

    testWithFlameGame(
      'test_AC4_second_swipe_at_1500ms_within_2000ms_swipe_cooldown_is_blocked',
      (game) async {
        var fakeNow = DateTime(2026);
        final mochi = await mountHappyMochi(game, () => fakeNow);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        // First swipe at t=0 (55dp/250ms — qualifies as swipe per Story
        // 001's classification) — establishes the swipe cooldown window.
        mochi.classifyAndHandleDragForTesting(
          55,
          const Duration(milliseconds: 250),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          hasLength(1),
        );

        // Second swipe at t=1500ms — strictly within the 2000ms swipe
        // cooldown.
        fakeNow = fakeNow.add(const Duration(milliseconds: 1500));
        mochi.classifyAndHandleDragForTesting(
          55,
          const Duration(milliseconds: 250),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          hasLength(1),
          reason: 'the t=1500ms swipe must not emit a second GameEvent',
        );
      },
    );

    testWithFlameGame(
      'test_AC4_swipe_at_2001ms_after_first_swipe_succeeds',
      (game) async {
        var fakeNow = DateTime(2026);
        final mochi = await mountHappyMochi(game, () => fakeNow);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        await _emitThenDrainPleased(
          game,
          () => mochi.classifyAndHandleDragForTesting(
            55,
            const Duration(milliseconds: 250),
          ),
        ); // t=0

        fakeNow = fakeNow.add(const Duration(milliseconds: 2001));
        mochi.classifyAndHandleDragForTesting(
          55,
          const Duration(milliseconds: 250),
        );
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(2));
        expect(interacted.last.data, InteractionType.swipe);
      },
    );

    testWithFlameGame(
      'test_AC5_tap_cooldown_active_does_not_gate_an_independent_swipe_attempt',
      (game) async {
        var fakeNow = DateTime(2026);
        final mochi = await mountHappyMochi(game, () => fakeNow);
        final events = <GameEvent>[];
        final sub = GameEventBus().stream.listen(events.add);
        addTearDown(sub.cancel);

        // Tap at t=0 — tap cooldown now active until t=1000ms. Drain the
        // PLEASED window this tap triggers (Story 002, out of this
        // story's scope) so the swipe attempt below reaches Story 003's
        // cooldown check instead of being short-circuited by that guard.
        await _emitThenDrainPleased(game, mochi.simulateTapForTesting);
        expect(
          events.where((e) => e.type == GameEventType.petInteracted),
          hasLength(1),
        );

        // Swipe at t=200ms — well within the ACTIVE tap cooldown window,
        // but swipe's own cooldown was never triggered, so per-type
        // independence (AC-5) means it must still emit.
        fakeNow = fakeNow.add(const Duration(milliseconds: 200));
        mochi.classifyAndHandleDragForTesting(
          55,
          const Duration(milliseconds: 250),
        );
        await Future<void>.delayed(Duration.zero);

        final interacted = events.where(
          (e) => e.type == GameEventType.petInteracted,
        );
        expect(interacted, hasLength(2));
        expect(interacted.last.data, InteractionType.swipe);
      },
    );
  });
}

/// Ticks [game] forward by [totalSeconds] in small increments, yielding to
/// the microtask queue after every tick — mirrors
/// `interaction_state_guards_test.dart`'s own `_advance` helper (same
/// rationale: `TimerComponent.onLoad()` is `async`, so a tight synchronous
/// loop would spend ticks while a freshly-added timer is still blocked on
/// load). Used here only to drain the PLEASED Triggered State's 2.0s
/// window between two gesture attempts in a test — an axis entirely
/// separate from the wall-clock `fakeNow` this file advances for the
/// cooldown checks themselves.
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

/// Fires [attempt], waits for the emitted `petInteracted` event's own
/// subscriber round-trip to settle, then drains the 2.0s PLEASED window it
/// triggers — so the NEXT gesture attempt in a test reaches Story 003's
/// cooldown check instead of being short-circuited by Story 002's
/// still-active PLEASED guard (see file header comment).
Future<void> _emitThenDrainPleased(FlameGame game, void Function() attempt) async {
  attempt();
  await Future<void>.delayed(Duration.zero);
  await game.ready();
  await _advance(game, 2.1);
}
