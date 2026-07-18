// Run with:
//   cd src && flutter test ../tests/integration/bridge/game_event_subscriber_test.dart
//
// Uses flame_test's `testWithFlameGame`/`testWithGame` — plain `test()`
// under the hood (not `testWidgets`), so this file does not need the
// runAsync/isolate-timing workarounds the auth-account PIN entry test
// needed (that was specifically about Isolate.run inside a testWidgets tap
// handler; nothing here spawns a real isolate).
//
// GameEventBus is a true singleton shared across all tests in this file's
// isolate (same caveat as game_event_bus_test.dart) — setUp() below calls
// the @visibleForTesting resetForTesting() seam for real per-test
// isolation, added after this file's replay-cache pollution bug (a stale
// cached event from an earlier test was delivered to a later test's fresh
// subscription) needed an ad-hoc drain-then-clear workaround to fix.

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/game_event_subscriber.dart';

class _RecordingComponent extends Component with GameEventSubscriber {
  _RecordingComponent(this.subscribedEventTypes);

  @override
  final Set<GameEventType> subscribedEventTypes;

  final List<GameEvent> received = [];

  @override
  void onGameEvent(GameEvent event) => received.add(event);
}

void main() {
  setUp(() => GameEventBus().resetForTesting());

  testWithFlameGame(
    'test_mixin_subscribes_in_onMount_and_receives_events_after_mount',
    (game) async {
      final component =
          _RecordingComponent({GameEventType.petMoodChanged});
      await game.ensureAdd(component);

      GameEventBus().emit(const GameEvent(GameEventType.petMoodChanged, 'happy'));
      await Future<void>.delayed(Duration.zero);

      expect(component.received, hasLength(1));
      expect(component.received.single.data, 'happy');
    },
  );

  testWithFlameGame(
    'test_handler_ignores_events_of_a_type_it_did_not_subscribe_to',
    (game) async {
      final component =
          _RecordingComponent({GameEventType.petMoodChanged});
      await game.ensureAdd(component);

      GameEventBus().emit(const GameEvent(GameEventType.energyChanged, 55.0));
      await Future<void>.delayed(Duration.zero);

      expect(component.received, isEmpty);
    },
  );

  testWithFlameGame(
    'test_handler_no_ops_silently_after_the_component_is_removed',
    (game) async {
      final component =
          _RecordingComponent({GameEventType.itemEquipped});
      await game.ensureAdd(component);
      GameEventBus().emit(const GameEvent(GameEventType.itemEquipped, 'a'));
      await Future<void>.delayed(Duration.zero);
      expect(component.received, hasLength(1));

      await game.ensureRemove(component);

      expect(
        () => GameEventBus().emit(const GameEvent(GameEventType.itemEquipped, 'b')),
        returnsNormally,
      );
      await Future<void>.delayed(Duration.zero);

      // Unchanged from before removal — the second emit was not recorded.
      expect(component.received, hasLength(1));
    },
  );

  testWithFlameGame(
    'test_onRemove_actually_cancels_the_subscription_not_just_the_isMounted_guard',
    (game) async {
      final component =
          _RecordingComponent({GameEventType.seedReceived});
      await game.ensureAdd(component);
      expect(component.hasActiveGameEventSubscription, isTrue);

      await game.ensureRemove(component);

      expect(component.hasActiveGameEventSubscription, isFalse);
    },
  );

  testWithFlameGame(
    'test_two_rapid_same_type_events_are_both_reflected_in_order',
    (game) async {
      final component =
          _RecordingComponent({GameEventType.petInteracted});
      await game.ensureAdd(component);

      GameEventBus().emit(const GameEvent(GameEventType.petInteracted, 'tapA'));
      GameEventBus().emit(const GameEvent(GameEventType.petInteracted, 'tapB'));
      await Future<void>.delayed(Duration.zero);

      expect(component.received, hasLength(2));
      expect(component.received[0].data, 'tapA');
      expect(component.received[1].data, 'tapB');
    },
  );

  testWithFlameGame(
    'test_remount_replay_a_brand_new_component_instance_immediately_reflects_the_cached_event',
    (game) async {
      // The Definition of Done's explicit required scenario: the exact bug
      // class the vertical slice found — a screen (here, a component)
      // dynamically remounted must not silently show stale/default state.
      final componentA =
          _RecordingComponent({GameEventType.petLeveledUp});
      await game.ensureAdd(componentA);
      await game.ensureRemove(componentA);

      // Emitted while NO component of this type is mounted.
      GameEventBus().emit(const GameEvent(GameEventType.petLeveledUp, 7));
      await Future<void>.delayed(Duration.zero);

      // A genuinely NEW instance — not componentA re-added — matching the
      // real bug class (navigation recreating the widget/component).
      final componentB =
          _RecordingComponent({GameEventType.petLeveledUp});
      await game.ensureAdd(componentB);
      await Future<void>.delayed(Duration.zero);

      expect(componentB.received, hasLength(1));
      expect(componentB.received.single.data, 7);
      // componentA never saw this event — it was removed before the emit.
      expect(componentA.received, isEmpty);
    },
  );

  testWithFlameGame(
    'test_two_simultaneously_mounted_components_with_different_subscribed_types_do_not_cross_contaminate',
    (game) async {
      // The mixin exists specifically to be reused by multiple concurrent
      // components (MochiComponent, SeedBagComponent, EnergyBarComponent,
      // etc. per the epic) — this proves two components with DIFFERENT
      // subscribedEventTypes, mounted at the same time, each only ever see
      // their own type, never the other's.
      final moodComponent =
          _RecordingComponent({GameEventType.petMoodChanged});
      final energyComponent =
          _RecordingComponent({GameEventType.energyChanged});
      await game.ensureAddAll([moodComponent, energyComponent]);

      GameEventBus().emit(const GameEvent(GameEventType.petMoodChanged, 'sad'));
      GameEventBus().emit(const GameEvent(GameEventType.energyChanged, 30.0));
      await Future<void>.delayed(Duration.zero);

      expect(moodComponent.received, hasLength(1));
      expect(moodComponent.received.single.data, 'sad');
      expect(energyComponent.received, hasLength(1));
      expect(energyComponent.received.single.data, 30.0);
    },
  );
}
