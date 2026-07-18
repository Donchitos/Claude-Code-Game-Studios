import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:meta/meta.dart';

import '../core/game_event_bus.dart';
import '../core/game_event_subscriber.dart';
import '../core/pet_mood.dart';
import '../core/triggered_state.dart';

/// Mochi's Flame-side representation (ADR-0007 Decision §1, §3, §5). Holds
/// the cached Base Mood (from [GameEventType.petMoodChanged], never read
/// directly from Riverpod — one-way Flutter→Flame flow, ADR-0004) and the
/// transient Triggered State, driven by a priority-ordered, non-interruptible
/// LEVELING_UP state machine.
class MochiComponent extends PositionComponent with GameEventSubscriber {
  MoodState? _baseMood;
  TriggeredState? _current;
  TriggeredState? _queued;

  /// Test-only accessor — proves the cache is populated from the bridge
  /// event, not by reading Riverpod (which this component never touches).
  @visibleForTesting
  MoodState? get baseMood => _baseMood;

  /// Test-only accessor — `null` means no triggered state is playing
  /// (Mochi is showing its Base Mood idle animation).
  @visibleForTesting
  TriggeredState? get currentTriggeredState => _current;

  /// Test-only accessor — the single highest-priority trigger queued while
  /// LEVELING_UP plays (ADR-0007 Decision §3). `null` if nothing is queued.
  @visibleForTesting
  TriggeredState? get queuedTriggeredState => _queued;

  @override
  Set<GameEventType> get subscribedEventTypes => {
        GameEventType.petMoodChanged,
        GameEventType.taskApproved,
        GameEventType.petInteracted,
        GameEventType.itemEquipped,
        GameEventType.seedReceived,
        GameEventType.petLeveledUp,
      };

  @override
  void onGameEvent(GameEvent event) {
    // Switch on type before casting data (ADR-0004 payload-per-type rule).
    // Trigger-type events map to onTrigger() per ADR-0007 Decision §5.
    switch (event.type) {
      case GameEventType.petMoodChanged:
        _baseMood = event.data as MoodState;
      case GameEventType.taskApproved:
        onTrigger(TriggeredState.excited);
      case GameEventType.petInteracted:
        onTrigger(TriggeredState.pleased);
      case GameEventType.itemEquipped:
        onTrigger(TriggeredState.showingOff);
      case GameEventType.seedReceived:
        onTrigger(TriggeredState.bouncing);
      case GameEventType.petLeveledUp:
        onTrigger(TriggeredState.levelingUp);
      default:
        break;
    }
  }

  /// Applies a triggered-state request (ADR-0007 Decision §3). Public (not
  /// private `_onTrigger`) and `@visibleForTesting`-documented so tests can
  /// drive the priority/queue machine directly without needing a real
  /// [GameEvent] round-trip through [GameEventBus] for every scenario.
  @visibleForTesting
  void onTrigger(TriggeredState t) {
    // LEVELING_UP is non-interruptible: everything else queues instead of
    // applying (ADR-0007 Decision §3).
    if (_current == TriggeredState.levelingUp) {
      _queueHighest(t);
      return;
    }
    // SLEEPING accepts only EXCITED (wake) and LEVELING_UP — all other
    // triggers are silently ignored (GDD Core Rule 3, ADR-0007 Decision §3).
    if (_baseMood == MoodState.sleeping &&
        t != TriggeredState.excited &&
        t != TriggeredState.levelingUp) {
      return;
    }
    if (_current == null ||
        triggeredStatePriority(t) > triggeredStatePriority(_current!)) {
      _play(t);
    }
    // Else: lower-or-equal priority than the current triggered state —
    // ignored entirely, no timer reset, no new effect.
  }

  void _queueHighest(TriggeredState t) {
    if (_queued == null ||
        triggeredStatePriority(t) > triggeredStatePriority(_queued!)) {
      _queued = t;
    }
  }

  void _play(TriggeredState t) {
    _clearEffects();
    _current = t;
    final duration = triggeredStateDuration(t);
    switch (t) {
      // "Prefer one clock per triggered state" (ADR-0007 Decision §4): for
      // the two triggered states whose visual is a Flame Effect, drive
      // completion off the Effect's own onComplete rather than a parallel
      // TimerComponent.
      case TriggeredState.excited:
        add(
          ScaleEffect.to(
            Vector2.all(1.3),
            EffectController(duration: duration),
            onComplete: _onTriggerComplete,
          ),
        );
      case TriggeredState.showingOff:
        add(
          RotateEffect.by(
            2 * math.pi,
            EffectController(duration: duration),
            onComplete: _onTriggerComplete,
          ),
        );
      // PLEASED/BOUNCING/LEVELING_UP have no natural Effect.onComplete hook
      // at this story's scope (their GDD animations — eyes-close-wiggle,
      // small-hop, glow-and-grow — are sprite/asset concerns for a future
      // epic) — a fresh TimerComponent per activation drives completion.
      case TriggeredState.pleased:
      case TriggeredState.bouncing:
      case TriggeredState.levelingUp:
        add(
          _TriggerTimer(period: duration, onComplete: _onTriggerComplete),
        );
    }
  }

  void _onTriggerComplete() {
    final next = _queued;
    _queued = null;
    if (next != null) {
      _play(next);
    } else {
      _current = null;
    }
  }

  /// Removes any currently-attached [Effect] or trigger-completion timer
  /// before the next triggered state's mechanism is added — required
  /// correctness (not polish) for transform-based effects, which apply
  /// incrementally and compound instead of overriding (ADR-0007 Risks).
  void _clearEffects() {
    for (final effect in children.whereType<Effect>().toList()) {
      effect.removeFromParent();
    }
    for (final timer in children.whereType<_TriggerTimer>().toList()) {
      timer.removeFromParent();
    }
  }
}

/// A one-shot [TimerComponent] identifying itself distinctly from any other
/// `TimerComponent` a future story might attach to [MochiComponent], so
/// [MochiComponent._clearEffects] can target exactly the trigger-completion
/// timer without accidentally sweeping up an unrelated one.
class _TriggerTimer extends TimerComponent {
  _TriggerTimer({required super.period, required VoidCallback onComplete})
      : super(onTick: onComplete, removeOnFinish: true);
}
