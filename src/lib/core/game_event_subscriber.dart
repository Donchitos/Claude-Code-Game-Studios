import 'dart:async';

import 'package:flame/components.dart';
import 'package:meta/meta.dart';

import 'game_event_bus.dart';

/// Reusable Flame `Component` lifecycle mixin implementing ADR-0004 Decision
/// §4's subscribe/guard/cancel pattern exactly once, so every consuming
/// component (`MochiComponent`, `SeedBagComponent`, etc.) doesn't have to
/// hand-roll it. This mixin, not just its documentation, is this epic's
/// responsibility — ADR-0004's Ordering Note states this ADR owns the
/// subscriber lifecycle itself.
///
/// - Subscribes to [GameEventBus] in [onMount], never `onLoad()` — `isMounted`
///   stays `false` for the whole duration of `onLoad()`, so an `onLoad()`
///   subscription would silently and permanently drop any event that
///   arrives during the load→mount window (see ADR-0004 §4 for the full
///   rationale, source-verified against Flame 1.37).
/// - Every event is guarded by `isMounted` before [onGameEvent] is called.
/// - Cancels its subscription in [onRemove] — mandatory, or a removed
///   component's subscription leaks and can fire into a removed component.
///
/// Only events whose type is in [subscribedEventTypes] ever reach
/// [onGameEvent] — this enforces ADR-0004's "check `event.type` before
/// casting `event.data`" discipline structurally: a component only ever
/// sees events of types it explicitly opted into.
mixin GameEventSubscriber on Component {
  StreamSubscription<GameEvent>? _gameEventSubscription;

  /// Test-only visibility into whether the subscription is currently held —
  /// lets a test prove `onRemove` actually cancelled the subscription,
  /// rather than only proving the `isMounted` guard happens to suppress
  /// delivery (either alone would pass a test that merely checks "no event
  /// arrives after removal").
  @visibleForTesting
  bool get hasActiveGameEventSubscription => _gameEventSubscription != null;

  /// The event types this component reacts to. Override to declare which
  /// types this component cares about.
  Set<GameEventType> get subscribedEventTypes;

  /// Called for each event whose type is in [subscribedEventTypes], only
  /// while this component is mounted.
  void onGameEvent(GameEvent event);

  @override
  void onMount() {
    super.onMount();
    _gameEventSubscription = GameEventBus().stream.listen(_handleEvent);
  }

  void _handleEvent(GameEvent event) {
    if (!isMounted) return;
    if (!subscribedEventTypes.contains(event.type)) return;
    onGameEvent(event);
  }

  @override
  void onRemove() {
    _gameEventSubscription?.cancel();
    _gameEventSubscription = null;
    super.onRemove();
  }
}
