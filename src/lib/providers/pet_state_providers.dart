import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pet_mood.dart';
import 'time_decay_providers.dart';

/// Mochi's current Base Mood (ADR-0007 Decision §1-§2) — a pure derivation
/// from [energyProvider], no independent state. Owns the energy→mood lookup
/// (delegated from Time & Decay's ADR-0005). Never compute this inside the
/// Flame game loop (ADR-0007 Forbidden Approaches) — this provider is the
/// single source of truth.
final petMoodProvider = Provider<MoodState>((ref) {
  final energy = ref.watch(energyProvider);
  return moodForEnergy(energy);
});

/// Raw energy passthrough (0–100) for the energy bar (ADR-0007 Key
/// Interfaces) — kept as its own provider so the Base-Mood surface is
/// self-contained, rather than callers re-reading [energyProvider] directly.
final petEnergyProvider = Provider<double>((ref) => ref.watch(energyProvider));
