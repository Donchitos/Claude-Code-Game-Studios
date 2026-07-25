import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:meta/meta.dart';

import '../core/cooldown_policy.dart';
import '../core/game_event_bus.dart';
import '../core/game_event_subscriber.dart';
import '../core/interaction_guard.dart';
import '../core/interaction_type.dart';
import '../core/pet_mood.dart';
import '../core/triggered_state.dart';
import 'hit_area_formula.dart';

/// Mochi's Flame-side representation (ADR-0007 Decision §1, §3, §5). Holds
/// the cached Base Mood (from [GameEventType.petMoodChanged], never read
/// directly from Riverpod — one-way Flutter→Flame flow, ADR-0004) and the
/// transient Triggered State, driven by a priority-ordered, non-interruptible
/// LEVELING_UP state machine.
class MochiComponent extends SpriteComponent
    with GameEventSubscriber, DragCallbacks {
  /// `SpriteComponent` (not `PositionComponent`, as an earlier Pet
  /// Interaction Story 002 draft used) — ADR-0016 Key Interfaces fixed this
  /// as the eventual target base class, and Pet Room Screen UI Story 001
  /// (ADR-0017 Decision → TR-petroom-003, Formula 2) is the story that
  /// performs the migration, since it is the first to need [size] to carry
  /// real padded-hit-area data and a [render] override that keeps the
  /// visual sprite unscaled. This migration is additive only — none of
  /// ADR-0007's mood/triggered-state machinery or Pet Interaction Story
  /// 002's drag/guard logic below is altered.
  ///
  /// ADR-0016 Decision §1 injected clock (mirrors ADR-0005's precedent) —
  /// defaults to real wall-clock `DateTime.now`, overridable by tests.
  /// [currentSpriteSize] seeds both the initial padded [size] (via
  /// [computeHitArea]) and the true unscaled size [render] paints at;
  /// 72dp (Baby, Art Bible Section 5.2) is a reasonable MVP default since
  /// pets start at the Baby evolution stage — the real per-stage swap on
  /// level-up is Pet Leveling #16's own future story, not this one.
  MochiComponent({
    DateTime Function()? now,
    double currentSpriteSize = 72.0,
  }) : _now = now ?? DateTime.now,
       _currentSpriteSize = currentSpriteSize,
       super(size: Vector2.all(computeHitArea(currentSpriteSize).hitBoxSize));

  final DateTime Function() _now;

  double _currentSpriteSize;

  /// The true, unscaled evolution-stage sprite size (dp) — Baby/Young/Grown
  /// = 72/112/152dp (Art Bible Section 5.2, pinned final 2026-07-14). This
  /// is NOT the same as [size] (inherited from `PositionComponent`): [size]
  /// is the padded tap/drag hit-test region (ADR-0016 Decision §3 —
  /// `PositionComponent.containsLocalPoint` hit-tests against it), while
  /// this is what [render] actually paints, unscaled and centered inside
  /// [size]. Do NOT assume `size` reflects what's painted on screen.
  @visibleForTesting
  double get currentSpriteSize => _currentSpriteSize;

  /// Recomputes the padded [size] via [computeHitArea] (GDD Formula 2 /
  /// ADR-0017 Decision → TR-petroom-003). Intended to be called only on an
  /// evolution-stage transition (a `petLeveledUp` event crossing a stage
  /// boundary) — never per-frame.
  @visibleForTesting
  set currentSpriteSize(double value) {
    _currentSpriteSize = value;
    size = Vector2.all(computeHitArea(value).hitBoxSize);
  }

  MoodState? _baseMood;
  TriggeredState? _current;
  TriggeredState? _queued;

  // ---------------------------------------------------------------------
  // Story 004 (No-Mutation & Background/Foreground Resilience, AC-11):
  // guards the ONE genuine gap found in ADR-0004 §5's per-type replay cache
  // when applied to `petInteracted` specifically — see [_petInteractedAtSubscribeTime].
  // ---------------------------------------------------------------------

  /// A snapshot, taken in [onMount] via [GameEventBus.peekLastEvent], of
  /// whatever `petInteracted` event the bus already had cached BEFORE this
  /// subscription started (`null` if none yet). Used to tell apart, by
  /// object identity, "a live `petInteracted` I'm receiving right now" from
  /// "the bus's replay of an already-known, already-consumed cached event"
  /// in [onGameEvent] below — see that case for the actual guard.
  ///
  /// A narrowly-scoped fix, not a general replay-cache change (which would
  /// be ADR-0004/`GameEventBus` territory, out of this story's domain, and
  /// would break `taskApproved`'s existing, intentional reliance on the
  /// same cache to survive a parent's approval landing while the child
  /// device was offline — ADR-0004's Verification Required note).
  /// `petInteracted` is different in kind: a same-device, purely ephemeral
  /// UI reaction (a tap/swipe) with no cross-device or offline-reconnect
  /// meaning at all. Before this guard, a genuinely fresh `MochiComponent`
  /// instance mounted after ANY prior interaction this app session would
  /// immediately replay-trigger a brand-new 2s PLEASED animation on mount —
  /// confirmed as a real, reproducible bug during this story's
  /// implementation, not a hypothetical.
  ///
  /// Deliberately identity-based, not a "settled since mount" timing flag —
  /// an earlier microtask-scheduling attempt at this same guard was found
  /// unreliable: when more than one `GameEventType` is cached (the normal
  /// case — `petMoodChanged` is essentially always cached too),
  /// `Stream.multi`'s per-type replay delivery interleaves with an
  /// unrelated scheduled microtask in a way that isn't safely orderable
  /// (verified via a throwaway spike during this story's implementation).
  /// Identity comparison has no such timing dependency: it is correct
  /// regardless of how many types are cached or in what order they replay.
  GameEvent? _petInteractedAtSubscribeTime;

  @override
  void onMount() {
    _petInteractedAtSubscribeTime =
        GameEventBus().peekLastEvent(GameEventType.petInteracted);
    super.onMount(); // GameEventSubscriber.onMount() subscribes synchronously.
  }

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

  // ---------------------------------------------------------------------
  // Pet Room Screen UI Story 001 (ADR-0017 Decision → TR-petroom-003,
  // Formula 2): [size] wiring (constructor/setter above) + the render split
  // that keeps the visible sprite unscaled while [size] carries the padded
  // hit-test region.
  // ---------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // `SpriteComponent.onMount()` asserts `sprite != null`. No real
    // per-evolution-stage sprite asset is wired yet — that belongs to Pet
    // Leveling #16's own future story (this story's Out of Scope note) —
    // so a fully transparent 1×1 placeholder is set here purely to satisfy
    // that base-class contract without depending on any asset-bundle I/O.
    // It carries no visual content and is not a stand-in for real art;
    // `??=` means a real sprite set before `onLoad()` (e.g. by a future
    // story, or by the real app assigning one post-construction — see Pet
    // Room Screen UI Story 003, which loads an interim real asset at the
    // `PetRoomGame` level rather than here, specifically to avoid this
    // widely-unit-tested `onLoad()` path depending on asset-bundle I/O that
    // most of this component's own test harnesses don't set up) is never
    // overwritten.
    sprite ??= await _createPlaceholderSprite();
  }

  static Future<Sprite> _createPlaceholderSprite() async {
    final recorder = PictureRecorder();
    Canvas(recorder); // records nothing — fully transparent
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    return Sprite(image);
  }

  /// Overrides (not the inherited `SpriteComponent.render`, which would
  /// stretch [sprite] to fill [size]) to paint it at its true, unscaled
  /// [currentSpriteSize], centered inside the padded [size] — ADR-0017's
  /// mechanism for satisfying GDD Core Rule 4 ("don't scale the sprite
  /// bigger than its pinned design size") while [size] still carries the
  /// ≥80×80dp hit-test region ADR-0016 requires. `offset` below is exactly
  /// Formula 2's own `padding` output, applied as a paint offset — not
  /// recomputed separately. Deliberately does NOT call
  /// `super.render()` — `SpriteComponent.render()`'s default body paints
  /// `sprite` stretched to fill `size` (the exact behavior ADR-0017
  /// Alternative 3 rejects); calling it first and then painting again on
  /// top would double-paint. The `must_call_super` lint is suppressed
  /// rather than satisfied, matching this file's existing precedent for
  /// `onDragCancel` above.
  @override
  // ignore: must_call_super
  void render(Canvas canvas) {
    final spriteSize = Vector2.all(_currentSpriteSize);
    final offset = (size - spriteSize) / 2;
    sprite?.render(canvas, position: offset, size: spriteSize);
  }

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
        // Story 004 AC-11: ignore a `petInteracted` that is exactly the
        // same object already cached before this subscription started
        // (the bus's stale replay, ADR-0004 §5) — see
        // [_petInteractedAtSubscribeTime] doc for why. A live event is
        // always a distinct `GameEvent` instance, so this never suppresses
        // a genuine post-mount interaction, only the one-time replay.
        if (!identical(event, _petInteractedAtSubscribeTime)) {
          onTrigger(TriggeredState.pleased);
        }
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
        add(_TriggerTimer(period: duration, onComplete: _onTriggerComplete));
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

  // ---------------------------------------------------------------------
  // Pet Interaction Story 002: SLEEPING peek & PLEASED-in-progress input
  // guards (GDD `pet-interaction.md` AC-8/AC-9; ADR-0004 §3(b); ADR-0016
  // Decision §1). These wrap the `DragCallbacks` handlers below — the
  // sanctioned Flame→Bus→Flame emit adapter, funneling ALL touches (tap or
  // swipe) through the drag gesture lifecycle per ADR-0016 §1 — with the
  // two preconditions this story owns, evaluated via the pure,
  // independently-unit-tested [evaluateInteractionGuard] so the guard
  // decision itself has no Flame dependency. Per ADR-0016's own Architecture
  // Diagram, these guards run BEFORE cooldown — Story 003's per-type
  // cooldown check now lives in [_handleClassifiedGesture] below, called
  // only from the `InteractionGuardResult.emit` branch of
  // [_handleInteractionAttempt].
  //
  // Story 001 (Gesture Classification & Event Emission) was Blocked when
  // this story started; ADR-0016 ("Pet Interaction Input Handling") landed
  // concurrently and was Accepted before this story finished, so the drag
  // capture/classification below is written directly against ADR-0016
  // Decision §1's ratified mechanism (`DragCallbacks` ONLY — never combined
  // with `TapCallbacks`, which ADR-0016 identifies as a genuine gesture-
  // arena correctness risk, not just a style choice — classify once in
  // `onDragEnd` via straight-line displacement + an injected wall-clock),
  // rather than an earlier, now-superseded scaffold that mixed in
  // `TapCallbacks` alongside `DragCallbacks`. `SpriteComponent`/hit-area
  // migration (ADR-0016 §3) is handled by Pet Room Screen UI's own story,
  // not here.
  // ---------------------------------------------------------------------

  /// `swipe_min_distance` (GDD Tuning Knobs, default 40dp; ADR-0016 §1).
  static const double _swipeMinDistanceDp = 40;

  /// `swipe_max_duration` (GDD Tuning Knobs, default 300ms; ADR-0016 §1).
  static const Duration _swipeMaxDuration = Duration(milliseconds: 300);

  /// `sleeping_peek_duration` (GDD Formulas, 500ms total: 30% eye-open,
  /// hold 0.3s, close 0.2s — the eye-open visual itself is a sprite/asset
  /// concern this story does not own, per its Out of Scope note; this
  /// timer only proves the 500ms window and exposes a test hook).
  static const Duration _sleepingPeekDuration = Duration(milliseconds: 500);

  /// `tap_cooldown` (GDD Tuning Knobs, default 1000ms, safe range
  /// 300-3000ms; ADR-0016 Decision §2 / Story 003, TR-petinteraction-002).
  static const Duration _tapCooldown = Duration(milliseconds: 1000);

  /// `swipe_cooldown` (GDD Tuning Knobs, default 2000ms, safe range
  /// 500-4000ms; ADR-0016 Decision §2 / Story 003, TR-petinteraction-002).
  static const Duration _swipeCooldown = Duration(milliseconds: 2000);

  /// Straight-line-displacement start position (ADR-0016 §1: `end - start`,
  /// not summed per-`onDragUpdate` path length). `Vector2`, matching Flame
  /// 1.37's actual `PositionEvent.canvasPosition` type — ADR-0016's
  /// illustrative code sample uses `Offset`, but the real Flame API (source-
  /// verified, `flame-1.37.0/lib/src/events/messages/position_event.dart`)
  /// returns `Vector2`; this is a faithful-to-the-real-API correction of
  /// the ADR's pseudocode, not a deviation from its decision.
  Vector2? _dragStartCanvasPosition;
  DateTime? _dragStartTime;

  /// Multi-touch guard (ADR-0016 §1, flame-specialist-flagged as
  /// mandatory) — `ImmediateMultiDragGestureRecognizer` accepts independent
  /// concurrent pointers; without this, a second touch would silently
  /// overwrite `_dragStartCanvasPosition`/`_dragStartTime` mid-gesture.
  /// MVP: ignore every pointer after the first.
  int? _activePointerId;

  _SleepingPeekTimer? _sleepingPeekTimer;

  /// Per-type cooldown state (Story 003, ADR-0016 Decision §2): two
  /// independent nullable `DateTime?` fields, one per [InteractionType],
  /// each updated only when that type's gesture is actually emitted. Both
  /// start `null` ("no cooldown active yet"). Deliberately NOT a `Timer`/
  /// `TimerComponent` of any kind — see this story's Engine Notes for why
  /// (a Flame `TimerComponent` would pause with the game loop on
  /// background, the opposite of the GDD's intent). Reuses the same
  /// injected [_now] clock Story 001 established above — no second clock.
  DateTime? _lastTapAt;
  DateTime? _lastSwipeAt;

  /// Test-only accessor — Story 003's cooldown timestamp for
  /// [InteractionType.tap]. `null` means no tap has been emitted yet (or
  /// the component was just constructed).
  @visibleForTesting
  DateTime? get lastTapAt => _lastTapAt;

  /// Test-only accessor — Story 003's cooldown timestamp for
  /// [InteractionType.swipe]. `null` means no swipe has been emitted yet.
  @visibleForTesting
  DateTime? get lastSwipeAt => _lastSwipeAt;

  /// Test-only accessor — `true` while the 500ms sleeping-peek visual
  /// window (AC-8) is active.
  @visibleForTesting
  bool get isSleepingPeekPlaying => _sleepingPeekTimer != null;

  /// Test-only accessor — incremented once per sleeping-peek activation.
  /// QA Test Case AC-8 requires asserting "the sleeping-peek visual trigger
  /// was invoked"; this is that assertable trigger (the actual eye-open
  /// sprite animation is out of this story's scope).
  @visibleForTesting
  int sleepingPeekTriggerCount = 0;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_activePointerId != null) return; // ignore a second concurrent pointer
    _activePointerId = event.pointerId;
    _dragStartCanvasPosition = event.canvasPosition;
    _dragStartTime = _now();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (event.pointerId != _activePointerId) return;
    final start = _dragStartCanvasPosition;
    final startTime = _dragStartTime;
    _activePointerId = null;
    _dragStartCanvasPosition = null;
    _dragStartTime = null;
    if (start == null || startTime == null) return;

    // DragEndEvent (source-verified, Flame 1.37) carries no position at
    // all — only `velocity`. Straight-line displacement is therefore
    // measured from onDragStart's start position to the LAST position
    // observed via onDragUpdate (tracked below), per ADR-0016 §1's
    // "end - start" contract — equivalent to using onDragEnd's own position
    // where one exists, since a real touch's final onDragUpdate position
    // and its release position coincide.
    final end = _dragLastCanvasPosition ?? start;
    _dragLastCanvasPosition = null;
    final distanceDp = end.distanceTo(start);
    final duration = _now().difference(startTime);
    _classifyAndHandleGesture(distanceDp, duration);
  }

  Vector2? _dragLastCanvasPosition;

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (event.pointerId != _activePointerId) return;
    _dragLastCanvasPosition = event.canvasEndPosition;
  }

  @override
  // ignore: must_call_super
  void onDragCancel(DragCancelEvent event) {
    // Deliberately does NOT call `super.onDragCancel` — matches ADR-0016
    // §1's own reference implementation exactly (flame-specialist-
    // validated). `DragCallbacks`' default `onDragCancel` body is
    // `onDragEnd(event.toDragEnd())`, an UNQUALIFIED call that resolves via
    // virtual dispatch to THIS component's `onDragEnd` override — so
    // calling super here would run the classification/emit path for what
    // must be a silently discarded gesture (OS-level cancel, e.g. app
    // switch mid-touch: "discard — no classification, no emit", ADR-0016
    // §1). The `must_call_super` lint is suppressed rather than satisfied,
    // because satisfying it literally would reintroduce the exact bug
    // ADR-0016 requires `onDragCancel` to avoid.
    if (event.pointerId != _activePointerId) return;
    _activePointerId = null;
    _dragStartCanvasPosition = null;
    _dragStartTime = null;
    _dragLastCanvasPosition = null;
  }

  /// ADR-0016 Decision §1's classification: `isSwipe = distance >= 40dp &&
  /// duration <= 300ms` — then feeds the result through the exact same
  /// guard-then-emit path regardless of tap or swipe.
  void _classifyAndHandleGesture(double distanceDp, Duration duration) {
    final isSwipe =
        distanceDp >= _swipeMinDistanceDp && duration <= _swipeMaxDuration;
    _handleInteractionAttempt(
      isSwipe ? InteractionType.swipe : InteractionType.tap,
    );
  }

  /// Test-only seam exercising the exact same guard-then-emit path as a
  /// completed [onDragStart]→[onDragEnd] gesture, without needing to
  /// construct raw Flame `DragStartEvent`/`DragUpdateEvent`/`DragEndEvent`
  /// objects (which require a mounted `Game` + Flutter gesture-detail
  /// types) in a test. `distanceDp: 0` classifies as a tap — this is how
  /// this story's own tests simulate "a tap" per ADR-0016 §1 (there is no
  /// separate tap code path anymore; a tap is just a near-zero-displacement
  /// drag). Proves the guards (AC-8/AC-9) are not accidentally tap-only,
  /// per this story's own QA Test Case edge notes for both ACs.
  @visibleForTesting
  void classifyAndHandleDragForTesting(double distanceDp, Duration duration) =>
      _classifyAndHandleGesture(distanceDp, duration);

  /// Convenience wrapper over [classifyAndHandleDragForTesting] for the
  /// tap case (zero displacement, zero duration).
  @visibleForTesting
  void simulateTapForTesting() =>
      classifyAndHandleDragForTesting(0, Duration.zero);

  /// The single entry point [_classifyAndHandleGesture] funnels through —
  /// evaluates Story 002's two guards, then Story 003's per-type cooldown
  /// (ADR-0016 Architecture Diagram: guards run first, cooldown second),
  /// before ever calling ADR-0004 §3(b)'s sanctioned direct
  /// `GameEventBus().emit(...)` call from within this `DragCallbacks`
  /// handler.
  void _handleInteractionAttempt(InteractionType type) {
    switch (evaluateInteractionGuard(
      baseMood: _baseMood,
      currentTriggeredState: _current,
    )) {
      case InteractionGuardResult.sleepingPeek:
        _triggerSleepingPeek();
      case InteractionGuardResult.ignored:
        break; // PLEASED mid-animation — dropped entirely, no side effect.
      case InteractionGuardResult.emit:
        _handleClassifiedGesture(type);
    }
  }

  /// Story 003 (Per-Type Cooldown Enforcement — ADR-0016 Decision §2,
  /// TR-petinteraction-002): a lazy, O(1) timestamp comparison evaluated
  /// only when a new gesture is classified — never a scheduled `Timer` or
  /// a frame-ticked poll. `switch` on [type] means each branch only ever
  /// reads/writes its own `_lastXAt` field, which is what makes the two
  /// cooldowns independent (AC-5) with no additional code: an active tap
  /// cooldown never gates a swipe attempt, and vice versa. The timestamp
  /// is updated ONLY when the gesture is actually emitted (ADR-0016
  /// Decision §2), not on every attempt — a blocked attempt leaves the
  /// existing cooldown window untouched.
  void _handleClassifiedGesture(InteractionType type) {
    final now = _now();
    switch (type) {
      case InteractionType.tap:
        if (!cooldownElapsed(_lastTapAt, _tapCooldown, now)) return;
        _lastTapAt = now;
      case InteractionType.swipe:
        if (!cooldownElapsed(_lastSwipeAt, _swipeCooldown, now)) return;
        _lastSwipeAt = now;
    }
    GameEventBus().emit(GameEvent(GameEventType.petInteracted, type));
  }

  void _triggerSleepingPeek() {
    sleepingPeekTriggerCount++;
    _sleepingPeekTimer?.removeFromParent();
    final timer = _SleepingPeekTimer(
      period: _sleepingPeekDuration.inMilliseconds / 1000,
      onComplete: () => _sleepingPeekTimer = null,
    );
    _sleepingPeekTimer = timer;
    add(timer);
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

/// A one-shot [TimerComponent] backing the SLEEPING-peek visual window
/// (Story 002, AC-8). Deliberately a DISTINCT type from [_TriggerTimer] —
/// [MochiComponent._clearEffects] sweeps `_TriggerTimer` instances only, so
/// a sleeping peek in progress is never accidentally cancelled by an
/// unrelated triggered-state transition (e.g. an EXCITED wake trigger
/// arriving mid-peek), and vice versa.
class _SleepingPeekTimer extends TimerComponent {
  _SleepingPeekTimer({required super.period, required VoidCallback onComplete})
    : super(onTick: onComplete, removeOnFinish: true);
}
