// Pure, deterministic tap hit-area padding calculation — GDD Formula 2
// (`design/gdd/pet-room-screen-ui.md`), ratified unchanged and made
// concrete by ADR-0017 Decision → TR-petroom-003. No Flutter, no Flame — a
// total, side-effect-free function of its input, mirroring
// `src/lib/core/compute_energy.dart`'s pattern of an engine-independent,
// fully unit-testable formula file.
//
// Guarantees [HitArea.hitBoxSize] is always `>= hitBoxMin` regardless of
// how small [spriteSize] is, without ever shrinking a sprite that's
// already larger than the minimum. `hitBoxMin` (80dp) is a *requirement*
// owned by ADR-0016 / Pet Interaction #14 (registry: `tap_hitbox_min`) —
// this file owns only the *computation*, per ADR-0017's Ordering Note.

import 'dart:math' as math;

/// `tap_hitbox_min` (registry constant, ADR-0016 / Pet Interaction #14) —
/// the minimum tap/drag hit-test region on any axis, in dp. This is the one
/// concrete Dart definition of that constant in the codebase (ADR-0017
/// Ordering Note): ADR-0016 owns the *requirement*, this file owns the
/// *computation* that consumes it.
const double kTapHitboxMin = 80.0;

/// Formula 2's output: the invisible padding added around a sprite smaller
/// than [kTapHitboxMin], and the resulting total hit-test region size.
class HitArea {
  const HitArea({required this.padding, required this.hitBoxSize});

  /// The invisible padding (dp) added symmetrically on every edge around
  /// the visible sprite. Always `>= 0` — never negative, never shrinks a
  /// sprite that's already at or above [kTapHitboxMin].
  final double padding;

  /// The final tap/drag hit-test region size (dp), assumed square — this
  /// is what `MochiComponent.size` is set to (ADR-0016 Decision §3 /
  /// ADR-0017 Decision → TR-petroom-003), NOT the visually rendered sprite
  /// size. Always `>= kTapHitboxMin` (or the caller-supplied `hitBoxMin`).
  final double hitBoxSize;
}

/// GDD Formula 2:
/// ```
/// padding    = max(0, (hitBoxMin - spriteSize) / 2)
/// hitBoxSize = spriteSize + 2 × padding
/// ```
///
/// [spriteSize] is the sprite's displayed size (dp) at the current
/// evolution stage, assumed square for hit-area purposes (GDD Formula 2's
/// own assumption). [hitBoxMin] defaults to [kTapHitboxMin] but is
/// overridable for testing/future tuning without touching the constant
/// itself.
HitArea computeHitArea(double spriteSize, {double hitBoxMin = kTapHitboxMin}) {
  final padding = math.max(0.0, (hitBoxMin - spriteSize) / 2);
  return HitArea(padding: padding, hitBoxSize: spriteSize + 2 * padding);
}
