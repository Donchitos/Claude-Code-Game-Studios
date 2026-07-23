// Run with:
//   cd src && flutter test ../tests/integration/pet-interaction/no_mutation_and_resilience_test.dart
//
// Story 004 (No-Mutation & Background/Foreground Resilience) — Test
// Evidence. Two acceptance criteria, implemented exactly against the
// story's own `## QA Test Cases` section:
//
// AC-10 (no-mutation): a fresh Riverpod `ProviderContainer` with known
// initial `energyLevel`/`xuBalance` values + a hand-rolled Firestore fake
// (this codebase's established pattern — `fake_cloud_firestore` is
// incompatible with the installed `cloud_firestore ^6.7.1`, see
// `tests/unit/currency_system/xu_balance_provider_test.dart`'s header) — a
// tap, a swipe, and a cooldown-blocked tap in sequence must produce
// byte-identical Riverpod state and ZERO Firestore write calls (a
// call-count assertion, not just a final-state comparison, per the story's
// own edge-case note). Per ADR-0016 §Decision 1-2, this is expected to be
// a *confirmation* of the existing architecture (`MochiComponent`'s entire
// mutable footprint is component-local `Offset?`/`DateTime?`/`int?`
// fields, no Riverpod/Firestore touch anywhere in the classify/cooldown
// path) — this file audited the actual current source (not just the ADR's
// claim) before writing these assertions.
//
// AC-11 (background/foreground resilience): per ADR-0004 §5, `GameEventBus`
// caches the last-emitted event **per `GameEventType`** (no per-type
// exception carved out anywhere in that ADR) and replays it to any
// newly-subscribing listener. Investigating this story's own claim ("a
// remounted component does NOT get a stale replay of a mid-animation
// petInteracted event") against the REAL `GameEventBus`/`MochiComponent`
// behavior (not assumed) found this was NOT actually true before this
// story's fix: a genuinely fresh `MochiComponent` instance mounted after
// ANY prior `petInteracted` emission this app session would immediately
// replay-trigger a brand-new PLEASED animation on mount, because a fresh
// instance's `_current` triggered-state field starts `null`, and
// `onTrigger`'s priority guard (`_current == null || priority(t) >
// priority(_current)`) does not block a first-ever trigger. This is a
// REAL, reproducible bug (confirmed via a throwaway spike before writing
// this file), not a hypothetical — see `mochi_component.dart`'s
// `_pastInitialReplaySettle` field/doc for the fix and its rationale for
// why it lives in `MochiComponent` (Pet Interaction/#6-embedded logic)
// rather than in `GameEventBus` itself (would be an ADR-0004/Bridge-epic
// change outside this story's domain, and would regress
// `tests/unit/bridge/game_event_bus_test.dart`'s existing, deliberate
// `test_replay_cache_is_per_type_not_global` coverage, which asserts
// `petInteracted` — like every other type — IS cached/replayed at the bus
// level; that bus-level behavior is left untouched and still correctly
// serves `taskApproved`'s own intentional cross-device offline-reconnect
// replay need, ADR-0004's Verification Required note).
//
// The story's own edge-case wording ("verify no petInteracted event is
// present in the bus's replay cache after this cycle") is written from the
// OUTCOME perspective (no observable PLEASED replay reaches a consuming
// component) rather than the bus's literal internal cache state — the two
// sub-tests below both prove: (a) the bus's raw stream still literally
// replays a cached `petInteracted` to any subscriber (documented, not
// hidden), and (b) `MochiComponent` specifically does not act on it during
// its initial replay-settle window, converging on the current Base Mood
// via the (unaffected) `petMoodChanged` replay path instead — the actual
// guarantee AC-11 needs.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/interaction_type.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/currency_providers.dart';
import 'package:pet_quest/providers/pet_state_providers.dart';
import 'package:pet_quest/providers/time_decay_providers.dart';

// ---------------------------------------------------------------------
// AC-10 fixtures: the same hand-rolled minimal Firestore fake pattern as
// `tests/unit/currency_system/xu_balance_provider_test.dart`
// (`Stream.multi()`-based replay-then-forward `.doc().snapshots()`),
// extended with write-call tracking (`set`/`update`/`delete`) — the thing
// this story's own AC-10 needs that the currency test didn't.
// ---------------------------------------------------------------------

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this._data);
  final Map<String, dynamic>? _data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final _controller =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  Map<String, dynamic>? _data;

  /// Every `set`/`update`/`delete` call ever made against this document —
  /// a call-count assertion, not just a final-state comparison (AC-10's own
  /// edge-case note: a write-then-revert pattern would otherwise hide a
  /// violation that a final-state-only check would miss).
  int writeCallCount = 0;

  void seed(Map<String, dynamic>? data) {
    _data = data;
    _controller.add(_FakeDocumentSnapshot(data));
  }

  Map<String, dynamic>? get rawDataForTesting => _data;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.multi((controller) {
      controller.add(_FakeDocumentSnapshot(_data));
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    writeCallCount++;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    writeCallCount++;
  }

  @override
  Future<void> delete() async {
    writeCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final _docs = <String, _FakeDocumentReference>{};

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _docs.putIfAbsent(path, () => _FakeDocumentReference());
  }

  /// Total write calls across every document this fake has ever vended —
  /// the bar AC-10 sets is "zero Firestore document writes anywhere", not
  /// "zero writes to one specific path".
  int get totalWriteCallCount =>
      _docs.values.fold(0, (sum, doc) => sum + doc.writeCallCount);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Ticks [game] forward by [totalSeconds] in [step]-second increments,
/// yielding to the microtask queue after every tick — same pattern as
/// `tests/integration/pet_state_machine/mochi_component_triggered_state_test.dart`'s
/// own `_advance` helper (required because `TimerComponent.onLoad()` is
/// `async`, so a freshly-`add()`-ed `_TriggerTimer` needs at least one
/// microtask turn before it starts actually receiving ticks).
///
/// Used here (AC-10) purely to let a PLEASED triggered-state clear via
/// simulated Flame time — NOT to advance the wall-clock cooldown
/// timestamps, which use the real injected `_now` (`DateTime.now` by
/// default) and are therefore unaffected by this. This is what makes it
/// possible to reach a genuinely cooldown-blocked (not
/// PLEASED-guard-blocked) third attempt: per this story's own briefing,
/// Story 002's PLEASED reaction (2.0s, frame-ticked) blocks ALL further
/// interaction attempts while playing, and Story 003's tap cooldown (1.0s,
/// wall-clock) is in real play often shorter than that window — so PLEASED
/// must be allowed to clear (via simulated game time) between attempts for
/// the cooldown check to be the thing that actually runs, while real wall
/// time barely advances (a handful of milliseconds of actual test
/// execution), keeping the tap's own 1.0s wall-clock cooldown still active.
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

Future<String> _waitForSignedInUser(
  ProviderContainer container,
  MockFirebaseAuth auth,
) {
  final completer = Completer<String>();
  late final ProviderSubscription<AsyncValue<User?>> sub;
  sub = container.listen(authStateProvider, (previous, next) {
    final user = next.value;
    if (user != null && !completer.isCompleted) {
      completer.complete(user.uid);
    }
  });
  completer.future.whenComplete(sub.close);
  auth.signInWithEmailAndPassword(email: 'parent@example.com', password: 'x');
  return completer.future.timeout(const Duration(seconds: 5));
}

void main() {
  const childId = 'child-1';
  const child = ChildProfile(
    childId: childId,
    name: 'Bé An',
    avatarId: 'avatar-1',
    mochiName: 'Mochi',
  );

  setUp(() => GameEventBus().resetForTesting());

  group('AC-10: no persistent-data mutation', () {
    testWithFlameGame(
      'test_AC10_tap_swipe_and_cooldown_blocked_tap_produce_zero_riverpod_or_firestore_mutation',
      (game) async {
        // --- Arrange: known initial energyLevel/xuBalance + Firestore fake.
        final firestore = _FakeFirestore();
        final auth = MockFirebaseAuth();
        final container = ProviderContainer(
          overrides: [
            firebaseAuthProvider.overrideWithValue(auth),
            firebaseFirestoreProvider.overrideWithValue(firestore),
            // Known, fixed energyLevel (85.0 -> HAPPY, same fixture value
            // this codebase's own MoodEventBridge tests already use) — a
            // plain Provider<double>, so overrideWithValue is exact and
            // avoids re-deriving through the full time-decay Firestore
            // chain, which is Time & Decay's own concern, not this story's.
            energyProvider.overrideWithValue(85.0),
          ],
        );
        addTearDown(container.dispose);
        final parentId = await _waitForSignedInUser(container, auth);
        container.read(activeChildProvider.notifier).state = child;

        final docRef = firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference;
        docRef.seed({'xuBalance': 250});

        final xuSub = container.listen(xuBalanceProvider, (_, __) {});
        addTearDown(xuSub.close);
        await Future<void>.delayed(Duration.zero);

        // --- Snapshot initial state (byte-identical comparison target).
        final initialEnergy = container.read(petEnergyProvider);
        final initialMood = container.read(petMoodProvider);
        final initialXu = xuSub.read().value;
        final initialRawDoc = Map<String, dynamic>.from(
          docRef.rawDataForTesting!,
        );
        expect(initialEnergy, 85.0); // sanity: fixture actually wired
        expect(initialMood, MoodState.happy);
        expect(initialXu, 250);
        expect(firestore.totalWriteCallCount, 0); // sanity: clean start

        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
        );
        final interactedEvents = <GameEvent>[];
        final busSub = GameEventBus().stream
            .where((e) => e.type == GameEventType.petInteracted)
            .listen(interactedEvents.add);
        addTearDown(busSub.cancel);

        final mochi = MochiComponent();
        await game.ensureAdd(mochi);
        await Future<void>.delayed(Duration.zero);

        // --- Act: tap, then swipe, then a cooldown-blocked tap.
        //
        // A tap/swipe also triggers PLEASED (Story 002), which blocks ALL
        // further interaction attempts (any type) for its own 2.0s — this
        // story's own briefing flags that PLEASED's block window
        // out-lasts Story 003's 1.0s tap cooldown in practice, a known,
        // separately-tracked cross-story issue this story does not fix.
        // `_advance` below lets PLEASED clear via simulated Flame time
        // between attempts (so each attempt actually reaches the cooldown
        // check, not just the PLEASED-ignore guard) while real wall-clock
        // time barely moves, keeping tap's own 1.0s wall-clock cooldown
        // genuinely active for the third attempt.
        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);
        expect(mochi.currentTriggeredState, TriggeredState.pleased);

        await _advance(game, 2.05); // let PLEASED (2.0s) clear
        expect(mochi.currentTriggeredState, isNull);

        mochi.classifyAndHandleDragForTesting(
          60,
          const Duration(milliseconds: 100),
        ); // 60dp/100ms -> swipe (>=40dp, <=300ms)
        await Future<void>.delayed(Duration.zero);
        expect(mochi.currentTriggeredState, TriggeredState.pleased);

        await _advance(game, 2.05); // let PLEASED (re-triggered) clear again
        expect(mochi.currentTriggeredState, isNull);

        final lastTapAtBeforeBlockedAttempt = mochi.lastTapAt;
        // Real wall-clock time elapsed since the first tap is only a
        // handful of milliseconds (the `_advance` calls above simulate
        // Flame time, they do not sleep) — well under tap's 1000ms
        // cooldown, so this attempt is now genuinely cooldown-blocked
        // (PLEASED has already cleared, per the assertion just above).
        mochi.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);

        // Sanity: prove the invariant isn't vacuously true — the first two
        // interactions genuinely emitted, and the third was genuinely
        // blocked (not silently a no-op for an unrelated reason).
        expect(
          interactedEvents.map((e) => e.data),
          [InteractionType.tap, InteractionType.swipe],
          reason: 'exactly tap then swipe should have emitted; the third '
              '(cooldown-blocked) tap must not have produced a third event',
        );
        expect(mochi.lastTapAt, lastTapAtBeforeBlockedAttempt,
            reason: 'a cooldown-blocked attempt must not update the stored '
                'timestamp');

        // --- Assert: byte-identical Riverpod state + zero Firestore writes.
        expect(container.read(petEnergyProvider), initialEnergy);
        expect(container.read(petMoodProvider), initialMood);
        expect(xuSub.read().value, initialXu);
        expect(docRef.rawDataForTesting, initialRawDoc);
        expect(
          firestore.totalWriteCallCount,
          0,
          reason: 'no interaction may ever call set()/update()/delete() on '
              'any Firestore document (GDD Core Rule 6 / TR-petinteraction-004)',
        );
      },
    );
  });

  group(
      'AC-11: background/foreground resilience (remount does not replay '
      'a stale petInteracted)', () {
    testWithFlameGame(
      'test_AC11_a_freshly_mounted_component_after_a_prior_interaction_does_not_replay_PLEASED',
      (game) async {
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
        );

        final mochiA = MochiComponent();
        await game.ensureAdd(mochiA);
        await Future<void>.delayed(Duration.zero);

        // Tap -> petInteracted -> PLEASED, mid-animation (2.0s duration).
        mochiA.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);
        expect(mochiA.currentTriggeredState, TriggeredState.pleased);

        await game.ensureRemove(mochiA);

        // Simulate the remount cycle (proxy for app background/foreground
        // or a screen rebuild) as a genuinely fresh component instance —
        // the real-world case ADR-0004 §5's correction note describes
        // ("a brand-new component instance subscribes fresh in onMount()"),
        // and the case this story's spike found actually reproduces the bug
        // (a same-instance onRemove()+onMount() cycle does NOT reproduce it:
        // `_current` is a plain field that survives being off-tree, and
        // `onTrigger`'s priority-equal guard already no-ops a same-state
        // re-trigger — verified during this story's own investigation).
        final mochiB = MochiComponent();
        await game.ensureAdd(mochiB);
        await Future<void>.delayed(Duration.zero);

        expect(
          mochiB.currentTriggeredState,
          isNull,
          reason: 'a freshly-mounted component must not replay a stale '
              'petInteracted from a previous instance\'s session and start '
              'a brand-new PLEASED animation',
        );
        expect(
          mochiB.baseMood,
          MoodState.happy,
          reason: 'it must instead immediately reflect the current Base '
              'Mood via the (unaffected) petMoodChanged replay path',
        );
      },
    );

    testWithFlameGame(
      'test_AC11_current_base_mood_reflects_a_change_that_happened_while_the_prior_instance_was_mounted',
      (game) async {
        // A stronger version of the above: the Base Mood itself changed
        // AFTER mochiA's tap (simulating energy decaying / mood changing
        // while the app was backgrounded) — the remounted component must
        // show the CURRENT mood, not whatever mochiA last cached.
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
        );

        final mochiA = MochiComponent();
        await game.ensureAdd(mochiA);
        await Future<void>.delayed(Duration.zero);

        mochiA.simulateTapForTesting();
        await Future<void>.delayed(Duration.zero);
        expect(mochiA.currentTriggeredState, TriggeredState.pleased);

        await game.ensureRemove(mochiA);

        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.tired),
        );

        final mochiB = MochiComponent();
        await game.ensureAdd(mochiB);
        await Future<void>.delayed(Duration.zero);

        expect(mochiB.currentTriggeredState, isNull);
        expect(mochiB.baseMood, MoodState.tired);
      },
    );

    test(
        'test_AC11_edge_case_the_bus_itself_still_literally_replays_petInteracted_'
        'but_MochiComponent_does_not_act_on_it_during_its_replay_settle_window',
        () async {
      // Documents the actual, verified `GameEventBus` behavior (rather than
      // assuming the story's "no petInteracted replay" framing describes the
      // bus's literal cache) — see this file's header comment. `GameEventBus`
      // caches per `GameEventType` with no exception (ADR-0004 §5), so a
      // bare, non-`MochiComponent` subscriber genuinely does still receive
      // the replayed `petInteracted`; the fix that makes AC-11 true lives in
      // `MochiComponent` (see the two tests above), not in the bus.
      GameEventBus()
          .emit(const GameEvent(GameEventType.petInteracted, InteractionType.tap));
      await Future<void>.delayed(Duration.zero);

      final received = <GameEvent>[];
      final sub = GameEventBus().stream
          .where((e) => e.type == GameEventType.petInteracted)
          .listen(received.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);

      expect(
        received,
        hasLength(1),
        reason: 'GameEventBus itself (ADR-0004 §5, Bridge-epic-owned) still '
            'replays petInteracted like every other GameEventType — this is '
            'intentional and unchanged (e.g. taskApproved relies on the '
            'same mechanism for its own offline-reconnect replay need); the '
            'AC-11 guarantee is enforced one layer up, by MochiComponent '
            'choosing not to act on it during its replay-settle window.',
      );
    });
  });
}
