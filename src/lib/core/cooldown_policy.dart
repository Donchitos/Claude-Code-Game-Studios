/// Pure, injectable-clock cooldown check for Pet Interaction Story 003
/// (Per-Type Cooldown Enforcement — GDD `pet-interaction.md`
/// `TR-petinteraction-002`; ADR-0016 "Pet Interaction Input Handling"
/// Decision §2). No Flame/Flutter import — trivially unit-testable in
/// isolation, mirroring this codebase's established injected-`now`,
/// pure-comparison pattern (ADR-0005, Time & Decay) and Story 002's
/// `interaction_guard.dart` precedent of separating a pure decision
/// function from the Flame component that calls it.
///
/// [lastAt] is `null` when the given [InteractionType] (tap or swipe —
/// caller-scoped, this function is per-type-agnostic) has never fired yet,
/// which always counts as elapsed (no cooldown to wait out).
///
/// **Boundary is inclusive of [cooldown] itself** (ADR-0016 Decision §2):
/// the block condition is strictly `now.difference(lastAt) < cooldown`, so
/// a retry at exactly `now.difference(lastAt) == cooldown` is treated as
/// elapsed/allowed, not blocked. This function returns the inverse
/// (`true` = allowed) so callers read `if (!cooldownElapsed(...)) return;`
/// directly against ADR-0016's own `cooldownElapsed` Key Interfaces
/// signature.
bool cooldownElapsed(DateTime? lastAt, Duration cooldown, DateTime now) =>
    lastAt == null || now.difference(lastAt) >= cooldown;
