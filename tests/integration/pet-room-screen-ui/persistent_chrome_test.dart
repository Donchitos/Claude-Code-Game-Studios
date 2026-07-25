// Run with:
//   cd src && flutter test ../tests/integration/pet-room-screen-ui/persistent_chrome_test.dart
//
// Story 006 (Persistent Chrome — Mood/Energy Status Row & Level Progress
// Bar), Pet Room Screen UI epic. GDD Core Rule 7 / AC-CR7 only — AC-CR8
// (level progress bar) is explicitly NOT implemented in this story: it
// requires `petLevelProvider`/`levelProgressProvider` (Pet Leveling &
// Evolution #16), which does not exist anywhere in this codebase (confirmed
// via project-wide grep) — that system has a GDD but no epic yet. See this
// story's own file for the full scope-split explanation and the explicit
// user decision behind it.

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/gameplay/pet_room_game.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/pet_state_providers.dart';
import 'package:pet_quest/ui/pet_room_screen.dart';
import 'package:pet_quest/ui/pet_room_status_row.dart';

/// Pumps [steps] small, fixed-size frames instead of `pumpAndSettle()` —
/// `PetRoomScreen`'s `GameWidget` keeps a `Ticker` perpetually scheduled
/// once mounted. Duplicated from `composition_and_modal_exclusivity_test.
/// dart` — private helpers can't be shared across test files (that file's
/// own header comment).
Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

/// Pumps `PetRoomScreen` with [petMoodProvider]/[petEnergyProvider]
/// overridden directly to fixed test values — bypassing the real
/// `energyProvider`/Firestore chain entirely (this story's own scope is the
/// status row's rendering given a mood/energy value, not Pet State
/// Machine's own energy computation, which has its own dedicated test
/// suite under `tests/integration/time_decay/` and `tests/unit/
/// pet_state_machine/`). Still needs `firebaseAuthProvider` overridden —
/// `PetRoomScreen`'s `'chrome'` overlay is always-mounted and
/// unconditionally reads through the auth-gated provider chain even when
/// the leaf providers are overridden (Riverpod evaluates the whole
/// dependency graph it's asked to build, not just what a descendant
/// override happens to short-circuit at the very end).
Future<PetRoomGame> _pumpPetRoomScreen(
  WidgetTester tester, {
  required MoodState mood,
  required double energy,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
        petMoodProvider.overrideWithValue(mood),
        petEnergyProvider.overrideWithValue(energy),
      ],
      child: const MaterialApp(home: PetRoomScreen()),
    ),
  );
  await _pumpSteps(tester, 6);
  return tester
      .widget<GameWidget<PetRoomGame>>(find.byType(GameWidget<PetRoomGame>))
      .game!;
}

void main() {
  group('energyFillFraction (pure logic)', () {
    test('test_energyFillFraction_atLowerBoundary10_isZero', () {
      expect(energyFillFraction(10), 0.0);
    });

    test('test_energyFillFraction_atUpperBoundary100_isOne', () {
      expect(energyFillFraction(100), 1.0);
    });

    test('test_energyFillFraction_midpoint55_isHalf', () {
      expect(energyFillFraction(55), closeTo(0.5, 0.001));
    });

    test('test_energyFillFraction_belowLowerBoundary_clampsToZero_notNegative', () {
      expect(energyFillFraction(0), 0.0);
      expect(energyFillFraction(-50), 0.0);
    });

    // qa-tester code-review finding (Story 006): the lower clamp (energy <
    // 10) was tested via a widget-pump test, but the UPPER clamp never
    // was — `energyProvider`'s own contract never produces a value above
    // 100 in practice, but this pure function's `.clamp(0.0, 1.0)` has two
    // directions and both must be proven, not just assumed symmetric.
    test('test_energyFillFraction_aboveUpperBoundary_clampsToOne_notOverflowing', () {
      expect(energyFillFraction(150), 1.0);
      expect(energyFillFraction(1000), 1.0);
    });
  });

  group('AC-CR7: mood icon + energy bar render correct values, positioned below the app bar', () {
    for (final mood in MoodState.values) {
      testWidgets(
          'test_moodTier_${mood.name}_rendersDistinctMoodIcon',
          (tester) async {
        await _pumpPetRoomScreen(tester, mood: mood, energy: 50);

        expect(
          find.byKey(PetRoomStatusRow.rowKey),
          findsOneWidget,
          reason: 'the status row itself must be present for every mood tier',
        );
        final icon = tester.widget<Icon>(find.byKey(const Key('petRoomMoodIcon')));
        expect(
          icon.icon,
          isNotNull,
          reason: 'every one of the 5 mood tiers must map to a real icon, never null',
        );
      });
    }

    testWidgets(
        'test_moodTiers_allFiveMapToDistinctIcons_noTwoTiersShareTheSameIcon',
        (tester) async {
      final iconsSeen = <IconData>{};
      for (final mood in MoodState.values) {
        await _pumpPetRoomScreen(tester, mood: mood, energy: 50);
        final icon = tester.widget<Icon>(find.byKey(const Key('petRoomMoodIcon')));
        iconsSeen.add(icon.icon!);
      }
      expect(
        iconsSeen,
        hasLength(MoodState.values.length),
        reason: 'colorblind-safety (GDD Visual Requirements) requires each '
            'mood tier to be visually distinguishable by icon shape alone, '
            'not just color',
      );
    });

    for (final energy in [10.0, 55.0, 100.0]) {
      testWidgets(
          'test_energyBoundary_${energy.toInt()}_fillFractionMatchesFormula',
          (tester) async {
        await _pumpPetRoomScreen(tester, mood: MoodState.content, energy: energy);

        final expectedFraction = energyFillFraction(energy);
        final fillSize = tester.getSize(find.byKey(const Key('petRoomEnergyBarFill')));
        expect(
          fillSize.width,
          closeTo(_EnergyBarConstants.trackWidth * expectedFraction, 0.5),
          reason: 'the fill container width must match energyFillFraction '
              '(energy-10)/90 clamped to [0,1] — this story\'s own QA Test '
              'Cases\' proposed mapping',
        );
      });
    }

    testWidgets(
        'test_energyBelow10_fillFractionClampsToZero_notNegative',
        (tester) async {
      // Defensive: energyProvider's own contract never produces a value
      // this low in practice (10 is Base Mood's own SLEEPING floor), but
      // the fill-fraction formula must not paint a negative-width
      // container if it ever did.
      await _pumpPetRoomScreen(tester, mood: MoodState.sleeping, energy: 0);

      final fillSize = tester.getSize(find.byKey(const Key('petRoomEnergyBarFill')));
      expect(fillSize.width, 0.0);
    });

    testWidgets(
        'test_statusRow_positionedBelowAppBar_noOverlapWithChildAppBarTerritory',
        (tester) async {
      await _pumpPetRoomScreen(tester, mood: MoodState.happy, energy: 90);

      final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      final statusRowTop = tester.getTopLeft(find.byKey(PetRoomStatusRow.rowKey)).dy;

      expect(
        statusRowTop,
        greaterThanOrEqualTo(appBarBottom),
        reason: 'AC-CR7: the status row must render directly under the '
            "Child app bar, never encroaching on Main Navigation Shell "
            "(#17)'s app bar territory",
      );
    });
  });
}

/// Mirrors `pet_room_status_row.dart`'s own private `_EnergyBar.trackWidth`
/// constant (120.0) — duplicated since it's a private implementation
/// constant, not part of the widget's public API surface. If a future
/// change to that file's track width breaks this test, that's the correct,
/// intended failure mode (this test is explicitly pinned to the current
/// visual spec value).
abstract final class _EnergyBarConstants {
  static const trackWidth = 120.0;
}
