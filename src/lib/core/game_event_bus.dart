import 'dart:async';
import 'dart:developer' as developer;

import 'package:meta/meta.dart';

/// The full set of cross-boundary event types Flutter can push to Flame
/// (ADR-0004 Decision §2). Each type owns a distinct payload shape on
/// [GameEvent.data] — never share a payload type across two [GameEventType]
/// values (the historical `EXCITED`-as-`PetMood` `TypeError` bug this rule
/// exists to prevent).
enum GameEventType {
  petMoodChanged,
  seedReceived,
  itemEquipped,
  energyChanged,
  petLeveledUp,
  petInteracted,
  taskApproved,
}

/// A single typed event on the bridge. `data`'s actual runtime type is
/// determined entirely by `type` (see [GameEventType] doc) — every consumer
/// MUST check `type` before casting `data`, never cast blindly.
class GameEvent {
  const GameEvent(this.type, this.data);

  final GameEventType type;
  final dynamic data;
}

/// The single sanctioned Flutter→Flame communication channel (ADR-0004).
/// Pure Dart — imports neither `flutter` nor `flame` — a `StreamController`
/// singleton constructed once at app root and disposed only at app
/// termination, never per-screen.
///
/// Replays the most recently emitted event **per [GameEventType]** to any
/// newly-subscribing listener, immediately at subscribe time — not just on
/// app cold start. This is the corrected, bus-level version of ADR-0004 §5
/// (2026-07-13 Correction note): the original app-background-only replay
/// was found too narrow — any Flame component dynamically remounted (e.g.
/// by navigation recreating the widget hosting it) needs the same recovery,
/// since the underlying `ref.listen` adapter only re-fires on a *change*,
/// and a remounted subscriber sees no change if the provider's value was
/// already at its current state before the subscriber existed.
class GameEventBus {
  GameEventBus._();
  static final GameEventBus _instance = GameEventBus._();
  factory GameEventBus() => _instance;

  // No `sync: true` — listener callbacks are scheduled on the microtask
  // queue, not nested inside the emitting call stack. This is what makes
  // emitting from inside a Flame `TapCallbacks`/`DragCallbacks` handler
  // (ADR-0004 §3(b), the Flame→Bus→Flame adapter) reentrancy-safe.
  final _controller = StreamController<GameEvent>.broadcast();

  final Map<GameEventType, GameEvent> _lastEventByType = {};

  /// The event stream, replaying the last cached event per type to each new
  /// subscriber before forwarding live events. `Stream.multi` gives each
  /// listener its own independent replay-then-forward sequence without
  /// affecting other concurrent listeners or reintroducing a `sync: true`-like
  /// reentrancy hazard — the replay emission happens via the multi-stream's
  /// own controller, not synchronously inside the caller's `emit()` stack.
  /// `isBroadcast: true` doesn't change delivery behavior (multi-listener
  /// support already works without it) but correctly reports
  /// `stream.isBroadcast == true` — without it, any `.where()`/`.map()`
  /// derivation of this stream silently becomes single-subscription-only,
  /// a latent footgun for the first caller that listens to a derived stream
  /// twice (found in code review).
  late final Stream<GameEvent> stream = Stream<GameEvent>.multi(
    (controller) {
      for (final cached in _lastEventByType.values) {
        controller.add(cached);
      }
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    },
    isBroadcast: true,
  );

  /// Test-only seam for the emit-after-dispose warning — overridable so a
  /// test can assert the warning actually fires without needing to
  /// intercept `dart:developer` output (which isn't interceptable from a
  /// unit test). Defaults to the real `developer.log` call; production code
  /// never touches this. A test that overrides it MUST restore the default
  /// afterward (e.g. via `addTearDown`) since this is shared singleton state.
  static void Function(String message) logWarning = (message) =>
      developer.log(message, name: 'GameEventBus', level: 900);

  /// Synchronously returns the currently-cached last event for [type], or
  /// `null` if [type] has never been emitted. Read-only — does not
  /// subscribe, does not touch the replay cache, no side effects; it just
  /// exposes existing [_lastEventByType] state that already backs [stream]'s
  /// own replay.
  ///
  /// Exists so a consumer can distinguish, by object identity, "a live
  /// event I'm receiving right now" from "the replay of an already-known
  /// cached event delivered at subscribe time" — snapshot this at
  /// subscribe time, then compare each delivered event via `identical()`
  /// (added for Story 004 / Pet Interaction's AC-11: `MochiComponent` needs
  /// this to avoid replaying a stale `petInteracted` into a fresh PLEASED
  /// animation on remount, without changing this bus's own cache/replay
  /// semantics for any `GameEventType`, which stay exactly as ADR-0004 §5
  /// specifies). A microtask-ordering-based approach was tried first and
  /// found unreliable: `Stream.multi`'s replay of multiple cached types can
  /// interleave with an unrelated scheduled microtask in a way that isn't
  /// safely orderable — identity comparison has no such timing dependency.
  GameEvent? peekLastEvent(GameEventType type) => _lastEventByType[type];

  /// Pushes [event] to every current subscriber and updates the per-type
  /// replay cache. A silent no-op (does not throw) if the bus has already
  /// been [dispose]d — logs a warning instead, since `dispose()` should only
  /// ever happen at app termination and a post-dispose `emit()` indicates a
  /// bug elsewhere, not something callers should have to guard against.
  void emit(GameEvent event) {
    if (_controller.isClosed) {
      logWarning(
        'GameEventBus.emit() called after dispose() — event dropped: ${event.type}',
      );
      return;
    }
    _lastEventByType[event.type] = event;
    _controller.add(event);
  }

  /// Closes the underlying stream. App-termination only — never call this
  /// between screens or on any per-screen lifecycle; the bus is app-lifetime
  /// by design (ADR-0004 Decision §1).
  void dispose() {
    if (_controller.isClosed) return;
    _controller.close();
  }

  /// Test-only: clears the per-type replay cache. NOT for production use —
  /// the cache is meant to persist for the app's lifetime, same as the bus
  /// itself. Exists so tests can achieve true isolation via `setUp()`
  /// instead of relying on each test using a never-before-emitted
  /// [GameEventType] as an implicit invariant — that fragile pattern
  /// already caused real, self-caught test bugs more than once across this
  /// bus's own test suite before this method existed (found in code
  /// review).
  @visibleForTesting
  void resetForTesting() {
    _lastEventByType.clear();
  }
}
