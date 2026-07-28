// PROTOTYPE - NOT FOR PRODUCTION
// Question: Flutter-Flame State Bridge — pet mood Riverpod state
// Date: 2026-06-26

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PetMood { neutral, happy, sad }

/// Pure state — knows nothing about Flame or GameEventBus.
/// The Flutter widget layer is responsible for bridging state changes to the bus.
class PetMoodNotifier extends StateNotifier<PetMood> {
  PetMoodNotifier() : super(PetMood.neutral);

  void approve() => state = PetMood.happy;
  void skipTask() => state = PetMood.sad;
  void reset() => state = PetMood.neutral;
}

final petMoodProvider =
    StateNotifierProvider<PetMoodNotifier, PetMood>(
  (ref) => PetMoodNotifier(),
);
