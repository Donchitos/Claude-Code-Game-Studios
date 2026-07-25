import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pet_mood.dart';
import '../providers/pet_state_providers.dart';
import 'app_colors.dart';

/// GDD Core Rule 7 states the energy range (10-100) but not an exact
/// fill-fraction formula. This story's own QA Test Cases section proposes
/// `(energy-10)/90` as the concrete mapping — used here verbatim, clamped
/// defensively in case a future Pet State Machine change ever produces an
/// out-of-range value. Public (not `@visibleForTesting`) — genuinely used
/// by [PetRoomStatusRow], not test-only.
double energyFillFraction(double energy) => ((energy - 10) / 90).clamp(0.0, 1.0);

/// Icon per Base Mood tier (GDD "Mochi status row": mood icon ~32dp, a
/// **backup cue** — Mochi's own body language on the Flame canvas is the
/// primary cue per Player Fantasy/Pillar 2; this exists only for
/// parity/colorblind-safety like every other icon+color pairing in the Art
/// Bible). Five visually-distinct Material icons, ordered by valence to
/// match [MoodState]'s own declaration order.
const Map<MoodState, IconData> _moodIcons = {
  MoodState.happy: Icons.sentiment_very_satisfied,
  MoodState.content: Icons.sentiment_satisfied,
  MoodState.tired: Icons.sentiment_neutral,
  MoodState.sad: Icons.sentiment_dissatisfied,
  MoodState.sleeping: Icons.bedtime,
};

/// Persistent Mochi status row (Story 006, Pet Room Screen UI epic — GDD
/// Core Rule 7 / AC-CR7): mood icon + energy bar, mounted via the
/// `'chrome'` overlay key (Story 003, ADR-0017). Lives inside
/// `GameWidget`'s own area (`Scaffold.body` in `pet_room_screen.dart`),
/// which already starts below the Child app bar — no manual offset is
/// needed to satisfy "not encroaching on Main Navigation Shell (#17)'s app
/// bar territory."
///
/// **Scope note**: the GDD/story also specify a level progress bar
/// (AC-CR8-1/AC-CR8-2) directly under this status row — NOT implemented
/// here. `petLevelProvider`/`levelProgressProvider` (Pet Leveling &
/// Evolution #16) do not exist anywhere in this codebase; that system has
/// a GDD but no epic yet (confirmed via project-wide grep before starting
/// this story). Rather than invent that future epic's own provider
/// interface here, AC-CR8 is left unimplemented and documented as Blocked
/// in this story's own file, pending `/create-epics pet-leveling-evolution`
/// — an explicit user decision, not an oversight.
///
/// Split into two small `ConsumerWidget`s ([_MoodIcon], [_EnergyBar]) each
/// scoped to exactly the provider it reads (control manifest's
/// rebuild-scoping rule) — a mood change does not rebuild the energy bar
/// and vice versa, even though both providers happen to derive from the
/// same underlying `energyProvider` today (`pet_state_providers.dart`).
class PetRoomStatusRow extends StatelessWidget {
  const PetRoomStatusRow({super.key});

  /// The whole pill — what `find.byKey` in tests targets for both presence
  /// and position (`tester.getTopLeft`, compared against the app bar's
  /// bottom edge for AC-CR7's "no overlap" assertion).
  static const rowKey = Key('petRoomStatusRow');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: DecoratedBox(
            key: rowKey,
            decoration: BoxDecoration(
              // Cream Ivory ~85% opacity, soft shadow, floating pill — Art
              // Bible / GDD Visual Requirements (advisory for this UI-type
              // story, followed at implementation time per its own note).
              color: AppColors.creamIvory.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MoodIcon(),
                  SizedBox(width: 12),
                  _EnergyBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scoped to [petMoodProvider] only — a mood change never rebuilds
/// [_EnergyBar] alongside it.
class _MoodIcon extends ConsumerWidget {
  const _MoodIcon();

  static const iconKey = Key('petRoomMoodIcon');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(petMoodProvider);
    return Icon(
      _moodIcons[mood],
      key: iconKey,
      size: 32,
      color: AppColors.primaryText,
    );
  }
}

/// Scoped to [petEnergyProvider] only — an energy change never rebuilds
/// [_MoodIcon] alongside it. Track ~10dp tall (GDD Visual Requirements),
/// fill via an explicit-width inner `Container` rather than
/// `FractionallySizedBox`. Either would render identically here — the
/// outer track `Container`'s own explicit `width`/`height` already impose
/// a tight `120x10` constraint that a `FractionallySizedBox` would size
/// its fraction against correctly. The explicit `width: trackWidth *
/// fraction` is used instead purely because it makes the fill's pixel
/// width directly assertable via `tester.getSize(find.byKey(fillKey))` in
/// `persistent_chrome_test.dart` without relying on layout internals.
class _EnergyBar extends ConsumerWidget {
  const _EnergyBar();

  static const barKey = Key('petRoomEnergyBar');
  static const fillKey = Key('petRoomEnergyBarFill');
  static const trackWidth = 120.0;
  static const _height = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energy = ref.watch(petEnergyProvider);
    final fraction = energyFillFraction(energy);
    return Container(
      key: barKey,
      width: trackWidth,
      height: _height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.creamIvory,
        borderRadius: BorderRadius.circular(_height / 2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          key: fillKey,
          width: trackWidth * fraction,
          height: _height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.mintBreeze, AppColors.peachGlow],
            ),
          ),
        ),
      ),
    );
  }
}
