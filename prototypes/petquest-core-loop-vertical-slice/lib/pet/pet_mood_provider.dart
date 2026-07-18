// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does Base Mood as a pure Riverpod derivation
// (ADR-0007) correctly stay out of the Flame game loop?
// Date: 2026-07-13

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'energy_provider.dart';

enum PetMood { sleeping, sad, tired, content, happy }

/// Energy -> mood lookup, owned by Pet State Machine per ADR-0007
/// "Required Patterns": SLEEPING=10, SAD 11-19, TIRED 20-49, CONTENT 50-79,
/// HAPPY >=80.
PetMood moodForEnergy(double energy) {
  if (energy <= 10) return PetMood.sleeping;
  if (energy < 20) return PetMood.sad;
  if (energy < 50) return PetMood.tired;
  if (energy < 80) return PetMood.content;
  return PetMood.happy;
}

/// Pure Riverpod derivation from energyProvider (ADR-0007 "Required Patterns" -
/// never computed inside the Flame game loop).
final petMoodProvider = Provider<PetMood>((ref) {
  final energy = ref.watch(currentEnergyProvider);
  return moodForEnergy(energy);
});
