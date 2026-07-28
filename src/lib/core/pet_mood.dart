/// Base Mood states (ADR-0007 Decision §2) — a pure lookup on the energy
/// float, owned here (delegated from Time & Decay's ADR-0005). Declared in
/// this specific order; unlike `TriggeredState` (Story 003), this order
/// carries no priority meaning — Base Mood has no priority concept at all.
enum MoodState { happy, content, tired, sad, sleeping }

/// Pure energy→mood lookup (ADR-0007 Decision §2 — the single authoritative
/// copy; Time & Decay's own table is reference-only). No Firestore, no
/// Flutter, no Flame — a total, side-effect-free function of its input.
/// Public (not `@visibleForTesting`) — genuinely consumed by
/// `petMoodProvider` in production, not test-only.
///
/// `energy <= 10` (not `== 10`) for SLEEPING: `computeEnergy`'s `minEnergy`
/// clamp guarantees energy is never below 10 in practice, but this is
/// defensively inclusive of the boundary rather than requiring an exact
/// double equality match.
MoodState moodForEnergy(double energy) {
  if (energy <= 10) return MoodState.sleeping;
  if (energy <= 19) return MoodState.sad;
  if (energy <= 49) return MoodState.tired;
  if (energy <= 79) return MoodState.content;
  return MoodState.happy;
}
