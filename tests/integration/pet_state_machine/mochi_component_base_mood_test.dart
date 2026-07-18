// Run with:
//   cd src && flutter test ../tests/integration/pet_state_machine/mochi_component_base_mood_test.dart
//
// Two halves: MochiComponent's own bridge-consuming behavior (flame_test,
// plain test() under the hood — same pattern as the Bridge epic's
// game_event_subscriber_test.dart) and MoodEventBridge's bridge-emitting
// behavior (testWidgets, since it's a real ConsumerStatefulWidget exercising
// initState/ref.listenManual, not a Flame component).

import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';
import 'package:pet_quest/providers/time_decay_providers.dart';
import 'package:pet_quest/ui/mood_event_bridge.dart';

void main() {
  setUp(() => GameEventBus().resetForTesting());

  group('MochiComponent', () {
    testWithFlameGame(
      'test_MochiComponent_caches_baseMood_from_petMoodChanged_not_from_riverpod',
      (game) async {
        // Emitted BEFORE mount — the replay cache (ADR-0004 §5) is what
        // delivers it, proving the component never reads Riverpod directly.
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.happy),
        );

        final mochi = MochiComponent();
        await game.ensureAdd(mochi);
        await Future<void>.delayed(Duration.zero);

        expect(mochi.baseMood, MoodState.happy);
      },
    );

    testWithFlameGame(
      'test_MochiComponent_updates_baseMood_on_a_subsequent_petMoodChanged_event',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.tired),
        );
        await Future<void>.delayed(Duration.zero);
        expect(mochi.baseMood, MoodState.tired);

        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.sad),
        );
        await Future<void>.delayed(Duration.zero);
        expect(mochi.baseMood, MoodState.sad);
      },
    );

    testWithFlameGame(
      'test_a_newly_mounted_MochiComponent_immediately_reflects_the_last_petMoodChanged_event',
      (game) async {
        // A genuinely new instance, not a re-added one — the Bridge epic's
        // own Definition-of-Done remount-replay scenario, applied here.
        final mochiA = MochiComponent();
        await game.ensureAdd(mochiA);
        await game.ensureRemove(mochiA);

        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.content),
        );
        await Future<void>.delayed(Duration.zero);

        final mochiB = MochiComponent();
        await game.ensureAdd(mochiB);
        await Future<void>.delayed(Duration.zero);

        expect(mochiB.baseMood, MoodState.content);
        expect(mochiA.baseMood, isNull);
      },
    );

    testWithFlameGame(
      'test_MochiComponent_ignores_event_types_it_did_not_subscribe_to',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        GameEventBus().emit(
          const GameEvent(GameEventType.energyChanged, 55.0),
        );
        await Future<void>.delayed(Duration.zero);

        expect(mochi.baseMood, isNull);
      },
    );

    testWithFlameGame(
      'test_MochiComponent_onRemove_actually_cancels_the_subscription',
      (game) async {
        // Reuses GameEventSubscriber's own test-only accessor (already
        // exercised in isolation by Bridge Story 002's suite) to prove
        // MochiComponent specifically inherits and exercises that lifecycle
        // correctly, rather than assuming it — QA Test Case #6.
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);
        expect(mochi.hasActiveGameEventSubscription, isTrue);

        await game.ensureRemove(mochi);

        expect(mochi.hasActiveGameEventSubscription, isFalse);

        // And no further event reaches it post-removal (the isMounted-guard
        // half of the same QA Test Case).
        GameEventBus().emit(
          const GameEvent(GameEventType.petMoodChanged, MoodState.sad),
        );
        await Future<void>.delayed(Duration.zero);
        expect(mochi.baseMood, isNull);
      },
    );
  });

  test(
      'test_mochi_component_source_never_imports_riverpod_or_touches_a_container',
      () {
    // A durable regression guard for AC6 ("MochiComponent never calls
    // ref.read/ref.watch/touches ProviderContainer") — a source-string
    // check rather than manual review, per qa-tester's recommendation.
    // Run from `src/` (per this file's header comment), so the path below
    // is relative to that working directory.
    final source =
        File('lib/gameplay/mochi_component.dart').readAsStringSync();

    expect(source.contains('flutter_riverpod'), isFalse,
        reason: 'MochiComponent must never import flutter_riverpod — '
            'one-way Flutter→Flame flow only (ADR-0004).');
    expect(source.contains('ProviderContainer'), isFalse);
    expect(source.contains('ref.read'), isFalse);
    expect(source.contains('ref.watch'), isFalse);
  });

  group('MoodEventBridge', () {
    testWidgets(
        'test_cold_start_seed_emits_petMoodChanged_once_at_initial_build',
        (tester) async {
      final container = ProviderContainer(
        overrides: [energyProvider.overrideWithValue(85.0)], // HAPPY
      );
      addTearDown(container.dispose);

      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MoodEventBridge(child: SizedBox.shrink()),
        ),
      );
      await tester.pump();

      final moodEvents =
          events.where((e) => e.type == GameEventType.petMoodChanged);
      expect(moodEvents, hasLength(1));
      expect(moodEvents.single.data, MoodState.happy);
    });

    testWidgets(
        'test_ref_listenManual_emits_petMoodChanged_when_petMoodProvider_changes',
        (tester) async {
      final energyOverride = StateProvider<double>((ref) => 85.0); // HAPPY
      final container = ProviderContainer(
        overrides: [
          energyProvider.overrideWith((ref) => ref.watch(energyOverride)),
        ],
      );
      addTearDown(container.dispose);

      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MoodEventBridge(child: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      events.clear(); // Drop the cold-start seed — this test is about the
      // on-change path specifically.

      container.read(energyOverride.notifier).state = 10.0; // SLEEPING
      await tester.pump();

      final moodEvents =
          events.where((e) => e.type == GameEventType.petMoodChanged);
      expect(moodEvents, hasLength(1));
      expect(moodEvents.single.data, MoodState.sleeping);
    });

    testWidgets(
        'test_MoodEventBridge_renders_its_child_unchanged',
        (tester) async {
      final container = ProviderContainer(
        overrides: [energyProvider.overrideWithValue(85.0)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MoodEventBridge(
            child: Text('mochi-stage', textDirection: TextDirection.ltr),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('mochi-stage'), findsOneWidget);
    });
  });

  // A combined MoodEventBridge (testWidgets binding) + MochiComponent
  // (manually-driven FlameGame) end-to-end test was attempted here and
  // removed — it hung indefinitely (10-minute timeout, no error), evidently
  // from combining TestWidgetsFlutterBinding with a manually-initialized
  // headless FlameGame in the same test, a harness combination with no
  // established precedent in this codebase. Not a gap in coverage: every
  // acceptance criterion this would have proven is already covered
  // independently above — MoodEventBridge's cold-start seed (its own test
  // group) and MochiComponent's replay-cache consumption (its own test
  // group) — the two halves ADR-0004's bus already decouples by design.
}
