# ADR-0016: Pet Interaction Input Handling

## Status
Accepted (2026-07-23 — Lean review mode: Producer/TD/QA-lead director gates skipped per `production/review-mode.txt`; flame-specialist-validated at authoring, see Consequences → Risks for the validation summary)

## Date
2026-07-23

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Input |
| **Knowledge Risk** | MEDIUM — `TapDetector`/`DragDetector` deprecated since Flame 1.21 (this project's pinned 1.37 is well past that); `TapCallbacks`/`DragCallbacks` themselves are stable across 1.14→1.37 per `breaking-changes.md` (only a 1.34 addition of secondary-tap-button support, non-breaking). The gesture-arena interaction between `TapCallbacks`' `MultiTapGestureRecognizer` and `DragCallbacks`' `ImmediateMultiDragGestureRecognizer` is a long-standing Flame characteristic, not a post-cutoff change, but is easy to get wrong without engine-reference/specialist confirmation — hence MEDIUM, not LOW. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `current-best-practices.md`, `deprecated-apis.md`, `breaking-changes.md`; `docs/architecture/control-manifest.md` (Forbidden APIs); `docs/architecture/adr-0004-flutter-flame-event-bridge-architecture.md`; `docs/architecture/adr-0005-time-decay-calculation-strategy.md` (injected-`now` precedent); `design/gdd/pet-interaction.md`; flame-specialist validation (2026-07-23, see Consequences → Risks) |
| **Post-Cutoff APIs Used** | `DragCallbacks` mixin (stable since well before the 3.19/1.14 baseline, unaffected by 1.21–1.37 changes) — not itself post-cutoff, but this ADR explicitly rejects the now-deprecated `TapDetector`/`DragDetector` mixins in favor of it. No Flame API used here postdates the 1.37 pin. |
| **Verification Required** | (1) Confirm on a physical device that `ImmediateMultiDragGestureRecognizer`-backed `onDragStart`/`onDragEnd` fire reliably for a genuinely stationary touch-and-release (flame-specialist confirms this is Flame's documented behavior, but the project has a standing practice of physical-device verification for Input/gesture domains — see ADR-0001's 3-device validation requirement for a comparable precedent). (2) Once Pet Room Screen UI (#18, no epic yet) defines Pet Room's Flame viewport/camera setup, confirm that `event.canvasEndPosition`/`localPosition` units map 1:1 to logical pixels (dp) with no camera zoom scaling — if #18 introduces a `FixedResolutionViewport` or camera zoom, the 40dp/80dp thresholds in this ADR must be converted through that scale factor, not applied to raw canvas units. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0004 (Flutter-Flame Event Bridge Architecture) — this ADR's gesture-classification logic feeds directly into ADR-0004 §3(b)'s sanctioned `GameEventBus().emit(GameEvent(petInteracted, ...))` call; this ADR does not re-decide the emit mechanism, bus semantics, or subscriber lifecycle, all of which remain ADR-0004's. |
| **Enables** | Story 001 (Gesture Classification & Event Emission), Story 003 (Per-Type Cooldown Enforcement), Story 004 (No-Mutation & Background/Foreground Resilience), Story 005 (Hit-Area Minimum Enforcement) — all four currently `Blocked` pending this ADR. |
| **Blocks** | None (this ADR is itself the thing blocking the epic — see Enables). |
| **Ordering Note** | This ADR owns: (a) how drag distance/duration is measured and classified against the GDD's 40dp/300ms swipe thresholds, (b) how per-type cooldown state is stored and checked, (c) the hit-area contract between this system and Pet Room Screen UI (#18, not yet an epic). It does NOT own: the emit call itself or bus replay semantics (ADR-0004), the PLEASED/SLEEPING state-machine reaction to `petInteracted` (Pet State Machine ADR-0007), or the concrete padding/layout formula that produces Mochi's actual on-screen hit-area size (Pet Room Screen UI #18, whenever that epic exists — this ADR only fixes the *contract* #18 must satisfy). |

## Context

### Problem Statement

`design/gdd/pet-interaction.md` specifies three requirements with no governing architecture: TR-petinteraction-002 (per-type cooldown: tap 1.0s, swipe 2.0s), TR-petinteraction-003 (swipe thresholds: ≥40dp distance, ≤300ms duration), and TR-petinteraction-004 (no persistent-data mutation; ≥80×80dp hit area regardless of sprite size). The GDD states these as plain-language rules but does not specify: which Flame input mixin(s) to use, how to measure a drag's distance/duration against the thresholds, how cooldown state should be stored and checked (a scheduled `Timer` vs. a timestamp comparison — the GDD's own Edge Cases text asserts cooldown "continues counting through app minimize via Dart's `Timer`," a claim that needs verification, not blind implementation), and how the ≥80dp hit-area floor is technically enforced given Mochi's sprite visually shrinks/grows across evolution stages. Four stories (001, 003, 004, 005) are blocked on exactly this gap. This ADR closes it.

### Constraints
- Must use `TapCallbacks`/`DragCallbacks` — `TapDetector`/`DragDetector` are forbidden (deprecated since Flame 1.21, per control manifest's Forbidden APIs list).
- Must respect ADR-0004's one-way invariant and its two sanctioned emit adapters — this ADR's classification logic is what runs *inside* adapter (b)'s `TapCallbacks`/`DragCallbacks` handler, immediately before the `GameEventBus().emit(...)` call ADR-0004 already specifies.
- Must not mutate `energyLevel`, `xuBalance`, or any Firestore document (GDD Core Rule 6 / TR-petinteraction-004) — this system reads/writes no persistent state at all.
- Must not depend on Flame's frame-ticked game loop for correctness of cooldown timing across app-background/foreground transitions, since (per ADR-0004 Context) the OS may suspend the isolate entirely while backgrounded — any mechanism relying on "the loop kept running" silently breaks.
- 16.6ms/frame budget — gesture classification happens once per released touch, in the input callback, not the render loop; must be O(1), no per-frame polling (control manifest guardrail, Story 003).

### Requirements
- A single, unambiguous mechanism for classifying a completed gesture as `InteractionType.tap` or `InteractionType.swipe`.
- A cooldown mechanism per `InteractionType` that is correct (a) across app background/foreground and (b) trivially unit-testable without a real clock or a real Flame game loop.
- A defined, verifiable contract for what "hit area" means at the Flame-component level, independent of Mochi's rendered sprite size at any evolution stage.
- No dependency on a Pet Room Screen UI epic that does not yet exist — this ADR must produce a contract #18 can satisfy later, not block on #18 first.

## Decision

### 1. Gesture capture and classification — `DragCallbacks` only, classify in `onDragEnd`

`MochiComponent` mixes in **`DragCallbacks` only** — it does **not** also mix in `TapCallbacks`. All touches, whether they turn out to be a tap or a swipe, are funneled through the drag gesture lifecycle and classified once, on release.

**Why not both mixins**: `DragCallbacks` is backed by Flame's `ImmediateMultiDragGestureRecognizer`, which accepts a pointer immediately on touch-down (no pan-slop wait) — this is exactly what allows a stationary touch-and-release to still fire `onDragStart`/`onDragEnd` with near-zero distance, which is required for the "no movement = tap" case to be classifiable at all. But that same eager acceptance is what makes it unsafe to combine with `TapCallbacks`' `MultiTapGestureRecognizer` on the same component: the drag recognizer tends to claim the pointer in the gesture arena before the tap recognizer is fairly resolved, producing unreliable or double-fired taps (flame-specialist-confirmed, 2026-07-23 — a known Flame characteristic across 1.14–1.37, not something a version bump fixes). Funneling everything through `DragCallbacks` and classifying in `onDragEnd` sidesteps the arena conflict entirely.

```dart
class MochiComponent extends SpriteComponent with DragCallbacks {
  Offset? _dragStartCanvasPosition;
  DateTime? _dragStartTime;
  int? _activePointerId;                       // multi-touch guard, see below
  DateTime? _lastTapAt;
  DateTime? _lastSwipeAt;
  final DateTime Function() _now;               // injected clock — testability, mirrors ADR-0005

  MochiComponent({DateTime Function()? now}) : _now = now ?? DateTime.now;

  @override
  void onDragStart(DragStartEvent event) {
    if (_activePointerId != null) return;        // ignore a second concurrent pointer
    _activePointerId = event.pointerId;
    _dragStartCanvasPosition = event.canvasPosition;
    _dragStartTime = _now();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (event.pointerId != _activePointerId) return;
    final start = _dragStartCanvasPosition;
    final startTime = _dragStartTime;
    _activePointerId = null;
    _dragStartCanvasPosition = null;
    _dragStartTime = null;
    if (start == null || startTime == null) return;

    final distance = (event.canvasEndPosition - start).length; // straight-line displacement
    final duration = _now().difference(startTime);
    final isSwipe = distance >= 40 && duration <= const Duration(milliseconds: 300);
    _handleClassifiedGesture(isSwipe ? InteractionType.swipe : InteractionType.tap);
  }

  @override
  void onDragCancel(DragCancelEvent event) {       // OS-level cancel (e.g. app switch mid-touch)
    if (event.pointerId != _activePointerId) return;
    _activePointerId = null;
    _dragStartCanvasPosition = null;
    _dragStartTime = null;                          // discard — no classification, no emit
  }
}
```

- **Distance metric**: straight-line displacement (`end - start`), not summed per-`onDragUpdate` path length. Simpler, monotonic, avoids overcounting finger jitter during a slow drag.
- **Duration metric**: `_now().difference(startTime)`, sampled at `onDragStart` and `onDragEnd` — not a running Flame `Timer`/`TimerComponent`. A completed gesture is bounded in real time by construction (a touch cannot span an app backgrounding — the OS delivers a cancel, not a pause, to an in-flight gesture on backgrounding on both iOS and Android), so wall-clock `DateTime` sampling at the two gesture boundaries is sufficient and requires no lifecycle-pause handling.
- **`onDragCancel` is mandatory** (flame-specialist-flagged): without it, an OS-level pointer cancellation (app switched away mid-touch) would leave stale `_dragStart*` state that corrupts the next gesture's classification.
- **Multi-touch guard is mandatory** (flame-specialist-flagged): `ImmediateMultiDragGestureRecognizer` supports independent simultaneous pointers. Single-instance `_dragStartCanvasPosition`/`_dragStartTime` fields would be silently overwritten by a second concurrent touch. This ADR's decision: **ignore all pointers after the first** (`_activePointerId` guard above) rather than tracking multiple gestures — MVP scope is one child's one finger; multi-finger play is out of scope, matching the GDD's own "no direction/multi-touch nuance" simplicity.
- This directly satisfies GDD Edge Cases "drag distance < 40dp → tap" and "distance ≥ 40dp but duration > 300ms → tap" (both fall out of the same `isSwipe` boolean, no separate code path needed) and the GDD's own worked example (55dp/250ms → swipe; 55dp/450ms → tap).

### 2. Per-type cooldown — stored `DateTime` timestamps, wall-clock diff comparison, no `Timer`

Cooldown state is two nullable `DateTime?` fields (`_lastTapAt`, `_lastSwipeAt` — shown above), each updated only when that type's gesture is actually emitted. Before emitting, the classified gesture is checked against its own type's last-timestamp:

```dart
void _handleClassifiedGesture(InteractionType type) {
  // (Story 002's SLEEPING/PLEASED-in-progress guards run before this point — out of this ADR's scope)
  final now = _now();
  switch (type) {
    case InteractionType.tap:
      if (_lastTapAt != null && now.difference(_lastTapAt!) < const Duration(milliseconds: 1000)) return;
      _lastTapAt = now;
    case InteractionType.swipe:
      if (_lastSwipeAt != null && now.difference(_lastSwipeAt!) < const Duration(milliseconds: 2000)) return;
      _lastSwipeAt = now;
  }
  GameEventBus().emit(GameEvent(GameEventType.petInteracted, type));  // ADR-0004 §3(b) adapter
}
```

**Why not a scheduled `Timer(duration, callback)` or a Flame `TimerComponent`**: the GDD's Edge Cases section claims cooldown "continues counting through app minimize via Dart's `Timer`." This claim is **partially correct in effect but the wrong mechanism to build on**, and this ADR corrects it:

- A Flame `TimerComponent`/frame-ticked `Timer` is explicitly wrong — ADR-0007 already established (`wall_clock_timer_for_flame_triggered_state` in the architecture registry) that Flame's game loop pauses on background (`pauseWhenBackgrounded`), so a frame-ticked timer would *stop* counting while backgrounded, not continue — the opposite of the GDD's own intent.
- A `dart:async` `Timer(duration, callback)` (not Flame's) is wall-clock-scheduled and, in practice, its *deadline* is unaffected by the isolate being frozen (iOS/Android both freeze rather than slow the isolate when backgrounded) — when the app resumes, if the deadline already passed, the callback fires promptly rather than restarting from zero. So a plain Dart `Timer` would *functionally* achieve "cooldown continues elapsing while backgrounded," which is what the GDD wants. However, this ADR does **not** use one anyway, because: (a) if the OS fully **kills** the process rather than freezing it (common on Android under memory pressure, and after extended iOS background time), the `Timer` and all in-memory state — including `MochiComponent` itself — is gone on relaunch, so "the timer kept counting" is moot; the cooldown simply resets to inactive on cold start, which is harmless (worst case: the very next tap after a cold relaunch is never spuriously blocked); (b) a scheduled callback adds a second code path (the callback firing) with no functional benefit over a comparison evaluated lazily at the next gesture; (c) it does not match this project's own established pattern for exactly this class of problem — ADR-0005 (Time & Decay) already solved "does this correctly reflect real elapsed time across backgrounding" with a **pure, injected-`now` comparison function, no scheduled timer at all**, and the control manifest's own Story 003 guardrail already steers here ("a cheap timestamp comparison, not a per-frame poll").
- **Conclusion**: cooldown is evaluated lazily, only when a new gesture is classified, via `DateTime.now().difference(lastInteractionOfThisType)`. This is correct whether the app was backgrounded-and-resumed (elapsed wall-clock time is what `DateTime.now()` naturally reflects, no matter what happened to the isolate in between) or backgrounded-and-killed (state resets to "no cooldown active," a harmless, arguably-better outcome than a precisely-preserved but now-moot cooldown). The GDD's Edge Cases bullet should be read as describing the *effect* this ADR delivers, not literally "a scheduled `Timer` object exists and keeps ticking" — no such object exists in this design.
- Per-type independence (AC-5: tap cooldown active does not gate swipe) falls directly out of using two separate fields, checked only by their own `switch` branch — no shared state to accidentally cross-gate.
- Cooldown state naturally persists across ordinary tab navigation, since `MochiComponent` lives for the lifetime of Pet Room Screen's `FlameGame` instance (TR-petroom-005: tabs stay mounted via `StatefulShellRoute`, no re-init on tab return) — it only resets if the component is genuinely destroyed and recreated (cold app start), which is the same boundary condition ADR-0004 §5's replay mechanism already treats as "a new subscriber."

### 3. Hit-area contract — `size`-based hit test, decoupled from rendered sprite size

`MochiComponent`'s tap/drag registration area is Flame's **default hit test** — `PositionComponent.containsLocalPoint`, an axis-aligned box against the component's `size` (and `anchor`) — **not** a custom `RectangleHitbox`/`ShapeHitbox` (those exist for collision detection between components, which this system does not need; a simple rectangular pointer-registration area is sufficient for MVP).

The contract this ADR fixes, for Pet Room Screen UI (#18, not yet an epic) to satisfy whenever it is built:

- **`component.size` is the hit-test surface. It is not the same thing as the visually rendered sprite's dimensions.** Whoever positions `MochiComponent` (Pet Room Screen UI) MUST set `size` to at least `Vector2(80, 80)` (logical pixels/dp) regardless of Mochi's actual evolution-stage sprite size — even where the true rendered sprite is smaller, the component's `size` stays at the 80dp floor, with the sprite drawn centered within it (e.g. via `anchor = Anchor.center` and rendering the sprite at its natural size inside the larger hit box, or scaling `size` up while keeping the rendered `Sprite` unscaled — the concrete padding/centering formula is #18's Formula 2, out of this ADR's scope).
- **`scale` also affects the true hit rect** (flame-specialist-flagged) — if a future evolution-stage visual applies a `PositionComponent.scale` transform, the *effective* hit area is `size * scale`, not `size` alone. Whoever sets `size` must account for this if scale is ever non-1.0; for MVP, Mochi's evolution stages are implemented as size/asset swaps, not runtime `scale` transforms, so this is a documented risk, not an active issue.
- **No child component inside Mochi's bounding box may itself mix in `TapCallbacks`/`DragCallbacks`** (flame-specialist-flagged) — e.g. a future accessory/equipment overlay sprite (Pet Equipment #15) rendered as a child of `MochiComponent` must not register its own gesture callbacks, or it will intercept/shadow pointer events before they reach the parent, silently breaking hit-area coverage for whatever region that child occupies.
- **Verification method** (this is Story 005's job, AC-12): a unit/component test asserts `mochiComponent.size.x >= 80 && mochiComponent.size.y >= 80` for every evolution-stage `spriteSize` #18 defines — this is a pure geometric assertion against whatever value #18's Formula 2 produces, not a re-implementation of that formula. Story 005 remains blocked on #18 existing (as its own BLOCKED note already states) for the *test fixture data* (the concrete per-stage sizes), but is no longer blocked on the *architecture* — this ADR is what Story 005 was waiting on for TR-petinteraction-004's hit-area half.

### Architecture Diagram
```
[Touch down/up on Mochi sprite]
        │
        ▼
MochiComponent (DragCallbacks only — NOT TapCallbacks, arena-conflict avoidance)
  onDragStart:  record start canvasPosition + _now(), guard on pointerId (ignore 2nd pointer)
  onDragUpdate: (no-op — classification happens on release, not per-update)
  onDragCancel: discard start state, no emit (OS-level cancel, e.g. app-switch mid-touch)
  onDragEnd:    distance = |end - start|; duration = _now() - startTime
                isSwipe = distance>=40dp && duration<=300ms
                        │
                        ▼
                _handleClassifiedGesture(type)
                  Story 002's SLEEPING/PLEASED guards run first (out of this ADR's scope)
                  cooldown check: now - lastOfThisType >= cooldownDuration(type)?  else return
                        │ (per-type independent: tap 1.0s / swipe 2.0s, separate DateTime fields)
                        ▼
                GameEventBus().emit(GameEvent(petInteracted, type))   ← ADR-0004 §3(b), unchanged

Hit area: component.size (>=80x80dp, set by Pet Room Screen UI #18) — decoupled from rendered
          sprite's visual dimensions at any evolution stage. Default AABB hit test, no ShapeHitbox.
```

### Key Interfaces
```dart
class MochiComponent extends SpriteComponent with DragCallbacks {
  MochiComponent({DateTime Function()? now});
  // size: Vector2 — hit-test surface, must be >=80x80 (set by caller/#18), independent of sprite art size
}

// Pure, injectable-clock classification — trivially unit-testable without a real Flame game:
bool isSwipe(double distanceDp, Duration duration) =>
    distanceDp >= 40 && duration <= const Duration(milliseconds: 300);

bool cooldownElapsed(DateTime? lastAt, Duration cooldown, DateTime now) =>
    lastAt == null || now.difference(lastAt) >= cooldown;
```
No new `GameEventType` or payload shape is introduced — `petInteracted → InteractionType` is already defined by ADR-0004 §2/§Key Interfaces; this ADR only decides how `InteractionType.tap`/`.swipe` gets computed before that existing emit call.

## Alternatives Considered

### Alternative 1: `TapCallbacks` + `DragCallbacks` combined on the same component
- **Description**: Mix in both; use `TapCallbacks.onTapUp` for the tap case and `DragCallbacks.onDragStart/Update/End` for the swipe case, letting Flutter's gesture arena pick a winner per touch.
- **Pros**: Slightly more "declarative" — each interaction type maps to its own dedicated callback rather than one method branching on measured distance/duration.
- **Cons**: `DragCallbacks`' `ImmediateMultiDragGestureRecognizer` tends to win the gesture arena eagerly (accepts on pointer-down), which can starve or double-fire the sibling `TapCallbacks`' `MultiTapGestureRecognizer` on the same component (flame-specialist-confirmed, known Flame characteristic).
- **Rejection Reason**: Correctness risk in the exact case this system depends on most (reliable tap classification) — not worth it for a purely stylistic gain over classify-in-`onDragEnd`.

### Alternative 2: Scheduled `Timer`/`TimerComponent`-driven cooldown
- **Description**: On interaction, start a `Timer(cooldownDuration, () => _cooldownActive = false)` (or a Flame `TimerComponent`) and gate new interactions on a boolean flag it flips.
- **Pros**: Arguably more "self-documenting" — a `Timer` object visibly represents "a cooldown is running."
- **Cons**: A Flame `TimerComponent` pauses with the game loop on background — actively wrong (opposite of GDD intent), already-forbidden pattern per ADR-0007's registry entry. A plain Dart `Timer` avoids that specific bug but adds a second code path (the callback) for no functional gain over a lazy comparison, doesn't survive process kill any better than a timestamp would, and diverges from this codebase's established pattern (ADR-0005's injected-`now`, pure-comparison style) for solving the identical "does this reflect true elapsed wall-clock time" problem.
- **Rejection Reason**: No correctness or clarity benefit over the chosen timestamp-diff approach; actively wrong if implemented via Flame's frame-ticked timer variant.

### Alternative 3: Path-length (summed per-update delta) distance instead of straight-line displacement
- **Description**: Accumulate `event.localDelta.length` across every `onDragUpdate` call, compare the running total to 40dp instead of `(end - start).length`.
- **Pros**: More faithful to the literal finger path if the child traces a curved/wandering gesture.
- **Cons**: Overcounts jitter during a slow, held touch (many small back-and-forth deltas can sum past 40dp with near-zero net displacement, misclassifying a held tap as a swipe); more per-frame bookkeeping for no benefit the GDD's simple flick-gesture fantasy needs.
- **Rejection Reason**: Straight-line displacement is simpler, monotonic with actual gesture intent for a quick flick, and matches the GDD's worked example semantics without the jitter failure mode.

## Consequences

### Positive
- Tap and swipe classification is a single, pure, unit-testable code path (`isSwipe(distance, duration)`) with no Flame game instance required to test it.
- Cooldown correctness across app background/foreground requires no lifecycle-pause handling at all — a direct consequence of using wall-clock timestamps compared lazily, not a scheduled callback or frame-ticked timer.
- The hit-area contract is defined now, unblocking Story 005's architecture even though Pet Room Screen UI (#18) doesn't have an epic yet — Story 005 only remains blocked on #18's concrete per-stage size *data*, not on any missing decision here.
- Consistent with this codebase's existing injected-`now`, pure-function style (ADR-0005) rather than introducing a new pattern.

### Negative
- Two extra pieces of state to manage correctly per gesture (`_activePointerId` guard, `onDragCancel` handling) that a naive `DragCallbacks` implementation would likely omit — this is manual discipline, not compiler-enforced, similar to ADR-0004's `isMounted`/`cancel()` discipline.
- MVP explicitly ignores all pointers after the first — a genuine two-finger simultaneous touch on Mochi silently does nothing for the second finger (acceptable per GDD's scope: MVP has no multi-touch interaction design).
- The GDD's Edge Cases text ("cooldown continues counting via Dart's Timer") is now architecturally imprecise relative to this ADR's actual mechanism (no `Timer` object exists) — flagged for a future GDD wording pass, not corrected in this ADR (no renamed interface/signal, so this does not meet the GDD Sync Check bar for a mandatory joint edit; see Migration Plan).

### Risks
- **Flame's `ImmediateMultiDragGestureRecognizer` failing to fire for a genuinely stationary touch** (would silently drop all taps). *Mitigation*: flame-specialist-confirmed as Flame's documented, stable behavior across 1.14–1.37; still listed under Verification Required for a physical-device smoke check during Story 001 implementation, consistent with this project's standing practice (see ADR-0001) of not trusting Input/gesture-domain claims without device verification.
- **Multi-touch state corruption** if the `_activePointerId` guard is omitted by an implementer copying a simpler single-pointer example. *Mitigation*: Key Interfaces + code sample above show the guard explicitly; LP-CODE-REVIEW checklist item (same pattern as ADR-0004's `isMounted`/`cancel()` discipline).
- **Stale drag state after OS-level cancellation** (app-switch mid-touch) if `onDragCancel` is skipped. *Mitigation*: shown explicitly in the Decision code sample; flagged in both Alternatives-adjacent risk callouts above.
- **Camera/viewport scale mismatch** between raw Flame canvas units and dp, once Pet Room Screen UI (#18) defines its actual viewport. *Mitigation*: Verification Required entry above; Story 001/003 implementers must confirm Pet Room's viewport is unscaled (1:1) before trusting raw `canvasPosition` deltas as dp, or apply the inverse scale factor if not.
- **`scale`-transformed hit area** if a future system (Pet Equipment #15, Pet Leveling #16) applies `PositionComponent.scale` to `MochiComponent` instead of swapping `size`/sprite assets per evolution stage. *Mitigation*: documented in Decision §3; not an active issue for MVP (evolution stages are asset/size swaps, not scale transforms), but flagged for whoever implements Pet Leveling.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| pet-interaction.md | Swipe detection thresholds: ≥40dp distance, ≤300ms duration (TR-petinteraction-003) | Decision §1 — `DragCallbacks`-only capture, classify in `onDragEnd` via straight-line displacement + `_now()` diff |
| pet-interaction.md | Per-interaction-type cooldown: tap 1.0s, swipe 2.0s (TR-petinteraction-002) | Decision §2 — two independent stored `DateTime?` fields, lazy wall-clock comparison, no scheduled `Timer` |
| pet-interaction.md | No persistent-data mutation; minimum 80×80dp hit area regardless of visual sprite size (TR-petinteraction-004) | Decision §3 for the hit-area half (contract: `size`-based hit test decoupled from rendered sprite); the no-mutation half requires no new architecture — this system never touches Riverpod/Firestore by construction (all state is component-local `DateTime?`/`Offset?` fields), which Story 004's AC-10 verifies |
| pet-interaction.md | TapCallbacks/DragCallbacks on the Mochi sprite emit petInteracted directly (TR-petinteraction-001) | Not re-decided here — already covered by ADR-0004 §3(b); this ADR's `_handleClassifiedGesture` calls that exact sanctioned emit point unchanged |

## Performance Implications
- **CPU**: Negligible — classification is one subtraction + one comparison per released touch (not per frame); cooldown check is two `DateTime` comparisons per classified gesture. No polling, no per-`update(dt)` work.
- **Memory**: A handful of nullable primitive/`DateTime`/`Offset` fields per `MochiComponent` instance (one instance exists for the app session, per TR-petroom-005's no-reinit-on-tab-return rule).
- **Load Time**: None.
- **Network**: None — this system is fully local/offline, consistent with GDD Core Rule 6.

## Migration Plan
Greenfield — Stories 001/003/004/005 have not been implemented yet (all were `Blocked`). No existing code to migrate. One documentation follow-up, not required before this ADR can be Accepted: `design/gdd/pet-interaction.md`'s Edge Cases bullet "cooldown timer chạy khi app minimize... qua Dart's `Timer`" describes an effect this ADR still delivers (cooldown reflects true elapsed wall-clock time across backgrounding) via a different, more precise mechanism (stored timestamp + lazy comparison, no `Timer` object) — recommend a future GDD wording pass to say "via wall-clock timestamp comparison" instead of "via Dart's `Timer`," but this is a prose clarification, not a renamed interface/signal, so it does not block writing or Accepting this ADR (does not meet this project's GDD Sync Check bar, which is scoped to renamed signals/APIs/data types).

## Validation Criteria
- Unit: `isSwipe(distance, duration)` pure function — table-tested against the GDD's own worked examples (55dp/250ms → true; 55dp/450ms → false; 20dp/any → false; boundary 40dp/300ms exactly → true, inclusive per GDD's `>=`/`<=`).
- Unit: `cooldownElapsed(lastAt, cooldown, now)` — tap at t=0, retry at t=500ms → false; retry at t=1001ms → true; independent-type test (tap active, swipe's own cooldown never triggered → swipe proceeds).
- Component test: simulated `onDragStart`→`onDragEnd` with zero net displacement classifies as tap; simulated OS-level `onDragCancel` mid-gesture emits nothing and leaves no stale state for the next gesture.
- Component test: two concurrent simulated pointers — second pointer's `onDragStart` is a no-op while the first is active (multi-touch guard).
- Geometric test (Story 005, once #18 exists): `component.size.x >= 80 && component.size.y >= 80` for every evolution-stage size #18 defines.
- **Open (manual, physical-device, during Story 001 impl)**: confirm a genuinely stationary touch-and-release reliably fires `onDragStart`/`onDragEnd` on real Android + iOS hardware, not just in a widget-test harness.

## Related Decisions
- ADR-0004 (Flutter-Flame Event Bridge Architecture) — upstream; this ADR's classification feeds its §3(b) sanctioned emit adapter unchanged.
- ADR-0005 (Time & Decay Calculation Strategy) — precedent for the injected-`now`, pure-comparison, no-background-timer pattern reused in Decision §2.
- ADR-0007 (Pet State Machine Architecture) — downstream consumer of `petInteracted`; also the source of the `wall_clock_timer_for_flame_triggered_state` forbidden-pattern registry entry that ruled out a Flame `TimerComponent` for cooldown here.
- Pet Room Screen Rendering & Interaction Contract ADR (upcoming, #18, not yet an epic) — will supply the concrete per-evolution-stage `size` values that satisfy this ADR's hit-area contract (Decision §3).
- `design/gdd/pet-interaction.md` — the GDD this ADR implements; see Migration Plan for one recommended (non-blocking) wording clarification.
