// Run with:
//   cd src && flutter test ../tests/unit/bridge/game_event_bus_test.dart
//
// Pure Dart — GameEventBus imports neither flutter nor flame (ADR-0004
// Decision §1), so this file needs no widget/Flame test harness at all,
// just plain `test()`.
//
// GameEventBus is a true singleton (`factory GameEventBus() => _instance`),
// so its replay cache persists across tests within this file unless reset.
// `resetForTesting()` (a @visibleForTesting seam, found needed in code
// review after this file's replay-cache pollution bug required an ad-hoc
// per-test-unique-type workaround) is called in setUp() below for real
// per-test isolation — tests no longer need to rely on "this is the first
// test to use this GameEventType" as an implicit invariant.
//
// The dispose() test lives in its own file (game_event_bus_dispose_test.dart)
// rather than here — Dart spawns each test FILE in its own isolate, so a
// singleton's one-way dispose() can't poison tests in a different file.
// Keeping it in this file would make every test after it depend on
// declaration order never changing (found in code review).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';

void main() {
  setUp(() => GameEventBus().resetForTesting());

  test('test_GameEventBus_factory_returns_the_same_singleton_instance', () {
    final a = GameEventBus();
    final b = GameEventBus();

    expect(identical(a, b), isTrue);
  });

  test('test_emit_delivers_to_multiple_simultaneous_subscribers', () async {
    final bus = GameEventBus();
    final received1 = <GameEvent>[];
    final received2 = <GameEvent>[];
    final sub1 = bus.stream.listen(received1.add);
    final sub2 = bus.stream.listen(received2.add);
    addTearDown(sub1.cancel);
    addTearDown(sub2.cancel);

    bus.emit(const GameEvent(GameEventType.energyChanged, 42.0));
    await Future<void>.delayed(Duration.zero);

    expect(received1, hasLength(1));
    expect(received1.single.data, 42.0);
    expect(received2, hasLength(1));
    expect(received2.single.data, 42.0);
  });

  test(
      'test_a_new_subscriber_immediately_receives_the_last_cached_event_of_that_type',
      () async {
    final bus = GameEventBus();
    bus.emit(const GameEvent(GameEventType.itemEquipped, 'sword-1'));
    await Future<void>.delayed(Duration.zero);

    final received = <GameEvent>[];
    final sub = bus.stream
        .where((e) => e.type == GameEventType.itemEquipped)
        .listen(received.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.data, 'sword-1');
  });

  test(
      'test_replay_cache_holds_only_the_most_recent_event_per_type_not_history',
      () async {
    final bus = GameEventBus();
    bus.emit(const GameEvent(GameEventType.petMoodChanged, 'moodA'));
    bus.emit(const GameEvent(GameEventType.petMoodChanged, 'moodB'));
    bus.emit(const GameEvent(GameEventType.petMoodChanged, 'moodC'));
    await Future<void>.delayed(Duration.zero);

    final received = <GameEvent>[];
    final sub = bus.stream
        .where((e) => e.type == GameEventType.petMoodChanged)
        .listen(received.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.data, 'moodC');
  });

  test(
      'test_a_type_with_no_prior_emission_delivers_nothing_extra_to_a_new_subscriber',
      () async {
    final bus = GameEventBus();
    final received = <GameEvent>[];
    final sub = bus.stream
        .where((e) => e.type == GameEventType.petLeveledUp)
        .listen(received.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);

    bus.emit(const GameEvent(GameEventType.petLeveledUp, 5));
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.data, 5);
  });

  test('test_replay_cache_is_per_type_not_global', () async {
    final bus = GameEventBus();
    bus.emit(const GameEvent(GameEventType.seedReceived, 'seed-batch-1'));
    bus.emit(const GameEvent(GameEventType.petInteracted, 'tap'));
    await Future<void>.delayed(Duration.zero);

    final received = <GameEvent>[];
    final sub = bus.stream
        .where((e) =>
            e.type == GameEventType.seedReceived ||
            e.type == GameEventType.petInteracted)
        .listen(received.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(2));
    expect(received.map((e) => e.type), containsAll([
      GameEventType.seedReceived,
      GameEventType.petInteracted,
    ]));
  });

  test('test_local_delivery_latency_is_well_under_a_documented_bound',
      () async {
    // The GDD states "<1ms local delivery" — asserting that literal figure
    // in an automated test is too tight to be CI-reliable (scheduler/GC
    // jitter routinely exceeds 1ms even for genuinely fast code), so this
    // test uses a looser, still-meaningful bound (5ms) as a regression
    // guard against a gross performance regression, not a precise
    // benchmark. Documented here rather than picked silently.
    final bus = GameEventBus();
    final completer = Completer<void>();
    final stopwatch = Stopwatch();
    final sub = bus.stream
        .where((e) => e.type == GameEventType.taskApproved)
        .listen((_) {
      stopwatch.stop();
      completer.complete();
    });
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    stopwatch.start();
    bus.emit(const GameEvent(GameEventType.taskApproved, null));
    await completer.future;

    expect(stopwatch.elapsedMilliseconds, lessThan(5));
  });

  test(
      'test_an_already_mounted_listener_receives_both_of_two_rapid_same_type_events_in_order',
      () async {
    // Distinct from the replay-cache tests above: this proves LIVE delivery
    // to a listener that was already subscribed BEFORE either event fired —
    // the replay cache only dedupes for a listener joining AFTER the fact,
    // it must never suppress events from an already-mounted subscriber.
    final bus = GameEventBus();
    final received = <GameEvent>[];
    final sub = bus.stream
        .where((e) => e.type == GameEventType.petMoodChanged)
        .listen(received.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);
    // Discard whatever the subscribe-time replay delivered (an earlier test
    // in this file already emitted petMoodChanged, so the singleton's cache
    // is non-empty here) — this test only cares about LIVE delivery after
    // subscribe, which the replay-cache tests above already cover.
    received.clear();

    bus.emit(const GameEvent(GameEventType.petMoodChanged, 'moodX'));
    bus.emit(const GameEvent(GameEventType.petMoodChanged, 'moodY'));
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(2));
    expect(received[0].data, 'moodX');
    expect(received[1].data, 'moodY');
  });

  test('test_emit_from_inside_a_listener_callback_does_not_deliver_reentrantly',
      () async {
    // Simulates the Flame TapCallbacks adapter (ADR-0004 §3(b)) emitting
    // from within an event-handling context. The class doc comment claims
    // this is reentrancy-safe because the forwarding subscription sits on a
    // non-`sync` broadcast controller — this test proves that claim rather
    // than just asserting it in a comment.
    final bus = GameEventBus();
    final order = <String>[];
    late final StreamSubscription<GameEvent> sub;
    sub = bus.stream
        .where((e) => e.type == GameEventType.petInteracted)
        .listen((event) {
      // An earlier test in this file already emitted petInteracted, so the
      // subscribe-time replay delivers that stale value first — ignore it,
      // only 'first'/'second' (this test's own live emits) matter here.
      if (event.data != 'first' && event.data != 'second') return;
      order.add('received:${event.data}');
      if (event.data == 'first') {
        // Re-entrant emit from inside the handler — must not be delivered
        // synchronously inside this same callback invocation.
        bus.emit(const GameEvent(GameEventType.petInteracted, 'second'));
        order.add('after-nested-emit');
      }
    });
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    bus.emit(const GameEvent(GameEventType.petInteracted, 'first'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // If delivery were reentrant/synchronous, "received:second" would
    // appear BEFORE "after-nested-emit". The non-sync broadcast controller
    // guarantees it's scheduled on the microtask queue instead.
    expect(order, ['received:first', 'after-nested-emit', 'received:second']);
  });

}
