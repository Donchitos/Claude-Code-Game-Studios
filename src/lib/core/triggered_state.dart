/// Triggered States (ADR-0007 Decision §1, §3) — transient, Flame-side-only
/// overrides of Mochi's Base Mood animation, never persisted, never mirrored
/// to Riverpod. Declared in THIS order deliberately — the opposite of
/// priority order (highest priority first would be `levelingUp` last here).
/// Never use `.index` for priority; see [triggeredStatePriority].
enum TriggeredState { levelingUp, excited, showingOff, pleased, bouncing }

/// Explicit priority map (ADR-0007 Decision §3: "Use this explicit map —
/// never `TriggeredState.index`"). Higher number = higher priority.
const Map<TriggeredState, int> _priority = {
  TriggeredState.levelingUp: 5,
  TriggeredState.excited: 4,
  TriggeredState.showingOff: 3,
  TriggeredState.pleased: 2,
  TriggeredState.bouncing: 1,
};

/// Priority for [state] — LEVELING_UP > EXCITED > SHOWING_OFF > PLEASED >
/// BOUNCING (ADR-0007 Decision §3).
int triggeredStatePriority(TriggeredState state) => _priority[state]!;

/// Duration in seconds for [state] (GDD `pet-state-machine.md` Formulas
/// table). Frame-ticked (`update(dt)`), never wall-clock — see ADR-0007
/// Decision §4 and Story 004.
const Map<TriggeredState, double> _duration = {
  TriggeredState.levelingUp: 3.0,
  TriggeredState.excited: 1.5,
  TriggeredState.showingOff: 2.0,
  TriggeredState.pleased: 2.0,
  TriggeredState.bouncing: 1.0,
};

/// Duration in seconds for [state] — see [_duration].
double triggeredStateDuration(TriggeredState state) => _duration[state]!;
