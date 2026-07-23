import 'pet_mood.dart';
import 'triggered_state.dart';

/// The outcome of evaluating Pet Interaction Story 002's two input guards
/// against Mochi's current Base Mood / Triggered State, for a single
/// tap-or-swipe attempt.
enum InteractionGuardResult {
  /// Neither guard applies — fall through to Story 001's classify-and-emit
  /// logic (`GameEventBus().emit(GameEvent(petInteracted, ...))`).
  emit,

  /// AC-8: Base Mood is SLEEPING — run the visual-only sleeping-peek
  /// reaction and withhold the emit entirely (GDD Edge Cases: "Pet State
  /// Machine không nhận" — #6 must never observe this attempt).
  sleepingPeek,

  /// AC-9: Triggered State is PLEASED (currently animating) — drop the
  /// input entirely. No visual change, no emit, the running PLEASED
  /// animation is not reset or extended.
  ignored,
}

/// Pure decision function for Story 002's two input guards (ADR-0004 §3(b):
/// these are preconditions wrapped *around* the sanctioned Flame→Bus→Flame
/// emit call, not a new adapter — see story's ADR Decision Summary). No
/// Flame/Flutter import — trivially unit-testable in isolation from
/// [MochiComponent]'s full lifecycle, and reused by it internally so the
/// production guard and the tested guard are the exact same code path.
///
/// Guard order matters and is deliberate: SLEEPING is checked first. If
/// Mochi's Base Mood were SLEEPING while, hypothetically, a stale PLEASED
/// Triggered State were still recorded (should not normally coexist per
/// ADR-0007's SLEEPING gate, but this function makes no assumption about
/// caller invariants), the SLEEPING peek still wins — the GDD's Edge Case
/// for SLEEPING is unconditional ("nếu Mochi đang SLEEPING và bé tap: chạy
/// sleeping_peek... không emit"), it does not carve out an exception for a
/// concurrently-playing Triggered State.
InteractionGuardResult evaluateInteractionGuard({
  required MoodState? baseMood,
  required TriggeredState? currentTriggeredState,
}) {
  if (baseMood == MoodState.sleeping) {
    return InteractionGuardResult.sleepingPeek;
  }
  if (currentTriggeredState == TriggeredState.pleased) {
    return InteractionGuardResult.ignored;
  }
  return InteractionGuardResult.emit;
}
