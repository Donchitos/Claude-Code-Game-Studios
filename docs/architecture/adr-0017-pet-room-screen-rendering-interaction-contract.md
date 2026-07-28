# ADR-0017: Pet Room Screen Rendering & Interaction Contract

## Status
Accepted (2026-07-23 — Lean review mode: Producer/TD/QA-lead director gates skipped per `production/review-mode.txt`; flame-specialist-validated at authoring — see Consequences → Risks and Engine Compatibility for the validation summary. This ADR was drafted and finalized in the same session ADR-0016 "Pet Interaction Input Handling" landed concurrently; its Decision was revised mid-draft to align with ADR-0016's already-Accepted hit-area contract and `MochiComponent` base-class choice — see ADR Dependencies and Alternatives Considered.)

## Date
2026-07-23

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Rendering + Input composition (component tree/z-order, `GameWidget.overlayBuilderMap` modal management, `MochiComponent` sizing/render split) |
| **Knowledge Risk** | MEDIUM-HIGH (per `docs/engine-reference/flutter-flame/VERSION.md` — first GDD hosting a real `FlameGame` canvas with composed rendering; Impeller device profiling still outstanding per ADR-0001, unaffected by this ADR) |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `.claude/docs/technical-preferences.md`, ADR-0001, ADR-0004, ADR-0014, ADR-0016 (Pet Interaction Input Handling — Decision §3 in particular), flame-specialist validation (2026-07-23, source-verified against installed `flame-1.37.0` package), existing source: `src/lib/gameplay/pet_room_game.dart`, `src/lib/gameplay/mochi_component.dart`, `src/lib/ui/pet_room_screen.dart`, `src/lib/core/game_event_bus.dart`, `src/lib/core/game_event_subscriber.dart`, `src/lib/core/triggered_state.dart` |
| **Post-Cutoff APIs Used** | None new. This ADR deliberately does **not** add `TapCallbacks` to `MochiComponent` — ADR-0016 already ruled that out (gesture-arena conflict with `DragCallbacks`). It extends `MochiComponent`'s already-decided target base class (`SpriteComponent`, per ADR-0016's Key Interfaces) with a custom `render()` override and a `size` computed from this ADR's Formula 2 — both ordinary, stable Flame 1.37 component APIs. |
| **Verification Required** | (1) flame-specialist source-verified, this session: `PositionComponent.containsLocalPoint` (which `SpriteComponent` inherits) is a plain axis-aligned bounds check against `size`/`position`/`anchor` — confirms ADR-0016 Decision §3's hit-area contract is realizable exactly as described. (2) flame-specialist source-verified: component `priority` (lower paints first) is scoped to *direct siblings only*, not descendants/ancestors — `RoomBackgroundComponent` and `MochiComponent` must both be direct children of the same `World` for the priority-0/priority-1 ordering below to have any effect. (3) flame-specialist source-verified: `GameWidget`'s `OverlayManager.add`/`.remove` both trigger a rebuild of *every currently active* overlay's builder (not just the toggled one), though each overlay widget is `KeyedSubtree`-wrapped so state survives — a `build()`-cost note only, not a remount risk, acceptable for this screen's simple chrome. (4) Outstanding, unrelated to this ADR: ADR-0001's 3-physical-device Impeller profiling pass, still pending regardless of this ADR's decisions (composition here does not change `drawCalls_sceneFlame`). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Draw-Call Budget Scope — this ADR's composition keeps the same 5-component tally, does not reopen it), ADR-0004 (Flutter-Flame Event Bridge — this ADR's modal-defer mechanism adds one new `GameEventType`, following ADR-0004's existing one-way Flutter→Flame contract and its `GameEventSubscriber` machinery unchanged), ADR-0014 (Navigation Shell — this ADR's tab-return lifecycle rule ratifies and extends the `FlameGame`-survives-tab-switch guarantee ADR-0014 Story 002 already implemented), **ADR-0016 (Pet Interaction Input Handling — Accepted the same day, landed concurrently with this ADR's drafting)**: ADR-0016 Decision §3 already fixed the hit-area *contract* (`MochiComponent.size` is the hit-test surface, must be ≥80×80dp, decoupled from the rendered sprite) and already fixed `MochiComponent`'s target mixins (`DragCallbacks` only, explicitly **not** `TapCallbacks`) and target base class (`SpriteComponent`, per its Key Interfaces). This ADR does not re-decide any of that — it supplies the concrete `size` value (Formula 2) and the rendering mechanism that keeps the visual sprite unscaled while `size` is padded, which ADR-0016 explicitly left as "out of this ADR's scope" / "#18's Formula 2." |
| **Enables** | Pet Interaction epic's Story 005 (Hit-Area Minimum Enforcement) — this ADR's Formula 2 output (`computeHitArea(spriteSize).hitBoxSize` for 72/112/152dp) is the concrete per-stage `size` data ADR-0016 Decision §3 already said Story 005 is waiting on. `/create-stories pet-room-screen-ui` (now unblocked for all 5 TR-petroom requirements). |
| **Blocks** | None. |
| **Ordering Note** | This ADR does NOT define or own `hitBoxMin` (80dp) as a *requirement* — ADR-0016 already fixed that number as Pet Interaction's contract. This ADR treats 80dp as a fixed external input to Formula 2 and places the constant's one concrete Dart definition in this epic's source tree (`kTapHitboxMin`, `src/lib/gameplay/hit_area_formula.dart`) since this is the only code that computes a size value from it; ADR-0016 should be read as the source of the *requirement*, this ADR as the source of the *computation*. |

## Context

### Problem Statement

Pet Room Screen UI (#18) is the first GDD in this project to host an actual `FlameGame` canvas with live user input, composing six other systems onto one screen. Four of its five technical requirements (TR-petroom-001, -003, -004, -005) had no governing ADR — `TR-petroom-002` (draw-call budget, Formula 1) was the only one covered, by ADR-0001. Pet Interaction epic's Story 005 (Hit-Area Minimum Enforcement) was blocked specifically on this GDD's Formula 2 — the GDD states the padding math but nothing had ratified it as an implementable contract.

While this ADR was being drafted, ADR-0016 ("Pet Interaction Input Handling") landed and was Accepted, closing the gesture-classification/cooldown side of Pet Interaction and additionally fixing part of what this ADR was going to decide: the hit-area *contract* (`size`-based, ≥80×80dp) and `MochiComponent`'s mixins/base class. This ADR was revised during drafting to build on top of that decision rather than duplicate or contradict it — see Alternatives Considered for the specific point (Alternative 1 under TR-petroom-003) where an earlier draft of this ADR would have added `TapCallbacks`, which ADR-0016 had already ruled out for gesture-arena-conflict reasons.

What remains for this ADR: (1) the concrete widget/component tree and z-order that "GameWidget hosts exactly one FlameGame" and the GDD's 4-layer composition mean in Flutter/Flame terms; (2) Formula 2's concrete, unit-testable implementation and how it produces the `size` value ADR-0016's contract requires, while keeping the rendered sprite visually unscaled; (3) how a Flutter-side modal (Wardrobe — not a Flame component, per Pet Equipment #15) defers a Flame-side visual without adding a second reverse-direction bridge case; (4) an enforceable (not just descriptive) rule for "never call `FlameGame` init/reset on tab return."

### Constraints
- `TapDetector` is deprecated — `TapCallbacks`/`DragCallbacks` only where input mixins are used (`deprecated-apis.md`). This ADR adds neither mixin itself — ADR-0016 already settled `MochiComponent`'s input mixin as `DragCallbacks` only.
- The Flame-canvas draw-call budget is fixed at 5 (ADR-0001 / GDD Formula 1) — nothing here may add a 6th renderable Flame component.
- `GameEventBus` is one-way Flutter→Flame except the single sanctioned Flame→Bus→Flame reverse case (`petInteracted`, ADR-0004 §3b) — this ADR must not invent a second reverse-direction case.
- ADR-0016 Decision §3: no child component inside `MochiComponent`'s bounding box may register its own `TapCallbacks`/`DragCallbacks` — it would intercept pointer events before they reach the parent, silently breaking hit-area coverage.
- `StatefulShellRoute`'s `IndexedStack` never disposes an inactive branch (ADR-0014) — `PetRoomScreen`'s existing `_game` field (constructed once per `State`) must not be contradicted.
- Mochi's sprite sizes are pinned and final (Art Bible §5.2): Baby 72dp, Young 112dp, Grown 152dp.

### Requirements
- An unambiguous component tree, `priority` assignment, and overlay-key contract for the next Pet Room stories to implement against (TR-petroom-001).
- A concrete, unit-testable Formula 2 implementation that produces the exact `size` value ADR-0016's hit-area contract requires, without visually scaling the sprite beyond its pinned dimensions (TR-petroom-003).
- A defined mechanism for a Flutter-side modal to defer a Flame-side visual, reusing the existing one-way bridge (TR-petroom-004).
- An enforceable rule for what a future story must never do regarding `FlameGame` lifecycle on tab return (TR-petroom-005).

## Decision

### TR-petroom-001 — Screen composition z-order & single-`FlameGame` hosting

**Widget/component tree** (bottom → top), all mounted inside `PetRoomScreen`'s `Scaffold.body`:

```
Scaffold
└── GameWidget<PetRoomGame>(game: _game)         ← the ONLY GameWidget for this route
      ├── Flame World (direct children — priority governs paint order among siblings only,
      │     flame-specialist-confirmed; both MUST be direct children for this to apply)
      │     ├── RoomBackgroundComponent   (SpriteComponent, priority: 0)
      │     └── MochiComponent            (SpriteComponent, priority: 1, ADR-0016 base class)
      └── overlayBuilderMap (Flutter widgets stacked above the canvas — current-best-practices.md's
            sanctioned HUD/menu pattern):
            ├── 'chrome'        — status row (mood + energy) + level progress bar.
            │                     Added to `game.overlays` once, immediately after the game's
            │                     first `onLoad()` resolves; never removed for the screen's lifetime.
            ├── 'context_menu'  — tap-on-Mochi 3-option menu (modal)
            └── 'wardrobe'      — Wardrobe bottom sheet (modal)
```

- **Exactly one `FlameGame` instance**: unchanged from the existing `src/lib/ui/pet_room_screen.dart` pattern — `final PetRoomGame _game = PetRoomGame();` as a `State` field, constructed once, passed unchanged to `GameWidget<PetRoomGame>(game: _game)` on every `build()` (see TR-petroom-005). This ADR adds that `PetRoomGame.onLoad()` mounts exactly the two Flame components above and nothing else, keeping ADR-0001's `drawCalls_sceneFlame = 5` tally intact once a future Pet Equipment story adds its 3 slot components (as children of `MochiComponent` or as further `World` siblings at `priority: 2` — that exact placement is Pet Equipment's own ADR's decision, out of this ADR's scope; this ADR only notes the constraint those slot components inherit from ADR-0016: none of them may register their own `TapCallbacks`/`DragCallbacks`).
- **z-order between the two Flame components**: `RoomBackgroundComponent.priority = 0`, `MochiComponent.priority = 1` — an explicit, reviewable ordering rule (lower `priority` paints first/behind) rather than relying on child-add order, which is easy to accidentally reorder in a future edit. Both must be direct children of the same `World` (flame-specialist-confirmed: `priority` is scoped to direct siblings only).
- **Modal mutual exclusivity** (also serves GDD Core Rule 5 and Edge Case 3): a single helper pair on `PetRoomGame` is the ONLY sanctioned way any Pet Room code opens or closes `context_menu`/`wardrobe`:
  ```dart
  void showModal(String overlayKey) {
    assert(overlayKey == 'context_menu' || overlayKey == 'wardrobe');
    overlays.remove('context_menu');
    overlays.remove('wardrobe');
    overlays.add(overlayKey);
  }

  void dismissModal() {
    overlays.remove('context_menu');
    overlays.remove('wardrobe');
  }
  ```
  Calling `game.overlays.add`/`.remove` directly with either of those two keys from anywhere else is a forbidden pattern (registry candidate below) — it is what guarantees "at no point are both modals mounted" structurally, not by convention.

### TR-petroom-003 — Formula 2: Tap Hit-Area Padding (priority requirement)

Ratifies the GDD's formula exactly as specified, no change:

```
padding    = max(0, (hitBoxMin - spriteSize) / 2)
hitBoxSize = spriteSize + 2 × padding
```

**Concrete, unit-testable implementation** — `src/lib/gameplay/hit_area_formula.dart` (new file, pure Dart, no Flutter/Flame import — mirrors the existing `compute_energy.dart` pattern of engine-independent pure functions):

```dart
const double kTapHitboxMin = 80.0; // dp — requirement owned by ADR-0016 / Pet Interaction #14

class HitArea {
  const HitArea({required this.padding, required this.hitBoxSize});
  final double padding;
  final double hitBoxSize;
}

HitArea computeHitArea(double spriteSize, {double hitBoxMin = kTapHitboxMin}) {
  final padding = math.max(0.0, (hitBoxMin - spriteSize) / 2);
  return HitArea(padding: padding, hitBoxSize: spriteSize + 2 * padding);
}
```

This is the artifact Pet Interaction Story 005's AC-12 imports and asserts against: `mochiComponent.size.x >= 80 && size.y >= 80` for every evolution-stage `spriteSize` (per ADR-0016 Decision §3's own stated verification method) — concretely `computeHitArea(72).hitBoxSize == 80.0`, `computeHitArea(112).hitBoxSize == 112.0`, `computeHitArea(152).hitBoxSize == 152.0`, plus the property `hitBoxSize >= 80` for arbitrary `spriteSize >= 0`.

**Component wiring — realizing ADR-0016's hit-area contract without violating GDD Core Rule 4 ("don't scale the sprite bigger than its pinned design size")**:

ADR-0016 Decision §3 already requires `MochiComponent.size` to be the padded hit-test surface (≥80×80dp) and already fixed `MochiComponent extends SpriteComponent with DragCallbacks` (Key Interfaces), leaving "the concrete padding/centering formula" explicitly to this ADR. A plain, un-overridden `SpriteComponent` paints its `sprite` stretched to fill `size` — if `size` were left at `hitBoxSize` with no further change, Mochi's art would visually scale up to fill the padded box, which is exactly what the GDD forbids for Baby Mochi (72dp pinned asset must not render at 80dp). This ADR closes that gap:

- `MochiComponent.size = Vector2.all(computeHitArea(currentSpriteSize).hitBoxSize)` — the padded value, recomputed only on evolution-stage transition (a `petLeveledUp` event crossing a stage boundary), never per-frame. This satisfies ADR-0016's hit-test contract directly, since `containsLocalPoint` (inherited from `PositionComponent`, flame-specialist-confirmed as a plain bounds check against `size`) now hit-tests the padded region.
- `MochiComponent.render(Canvas canvas)` is overridden (not the inherited `SpriteComponent.render`, which would stretch-to-fill) to paint the sprite at its true, unscaled `spriteSize`, centered inside the padded `size`:
  ```dart
  @override
  void render(Canvas canvas) {
    final offset = (size - Vector2.all(currentSpriteSize)) / 2; // == Vector2.all(padding)
    sprite?.render(canvas, position: offset, size: Vector2.all(currentSpriteSize));
  }
  ```
  Note `offset` is exactly the `padding` Formula 2 already computed — the render override doesn't recompute anything, it just applies the same `padding` value as a paint offset. This is the mechanism ADR-0016 itself suggested as an option ("scaling `size` up while keeping the rendered `Sprite` unscaled") and which this ADR now formalizes as the concrete contract.
- No `ShapeHitbox`/`TapCallbacks` is added anywhere on `MochiComponent` or its children — consistent with ADR-0016's decision; this ADR only supplies the `size` value and the render split, it does not touch gesture handling.

### TR-petroom-004 — Modal defer when Wardrobe is open or a competing `GameEvent` arrives

GDD Edge Case 4: while Wardrobe is open, an incoming `GameEvent` (e.g. `petLeveledUp`) must still update Pet State Machine's internal truth (independent of this ADR — Pet State Machine #6 is driven by its own Firestore/provider chain, not by `MochiComponent`), but the corresponding **Flame-side visual** (triggered-state animation) must not appear until the modal closes.

Because modal-open state lives in Flutter (`PetRoomGame.overlays`, TR-petroom-001) and the thing that must be gated (triggered-state visual playback) lives in Flame's `MochiComponent`, this requires a Flutter→Flame signal. Reusing the exact bridge pattern ADR-0004 already established, a new `GameEventType` is added:

```dart
enum GameEventType {
  petMoodChanged,
  seedReceived,
  itemEquipped,
  energyChanged,
  petLeveledUp,
  petInteracted,
  taskApproved,
  modalVisibilityChanged,   // NEW — payload: bool (true = a modal just opened, false = closed)
}
```

Emitted directly from the same call sites that call `PetRoomGame.showModal()`/`dismissModal()`: `GameEventBus().emit(GameEvent(GameEventType.modalVisibilityChanged, true))` immediately before `showModal(...)`, and `emit(GameEvent(..., false))` immediately after `dismissModal()`. Still one-way Flutter→Flame — no new reverse-direction case (the only one remains Pet Interaction's `petInteracted`, per ADR-0004 §3b / the registry's `flame_to_flutter_callback` forbidden pattern).

`MochiComponent` adds `modalVisibilityChanged` to `subscribedEventTypes` (via its existing `GameEventSubscriber` mixin — unchanged) and tracks a `bool _modalOpen` flag plus one pending-visual slot:

```dart
TriggeredState? _pendingVisual;

// inside onGameEvent's switch:
case GameEventType.modalVisibilityChanged:
  _modalOpen = event.data as bool;
  if (!_modalOpen && _pendingVisual != null) {
    final t = _pendingVisual!;
    _pendingVisual = null;
    onTrigger(t);   // plays normally through the existing ADR-0007 priority/queue logic
  }
```

`onTrigger` (ADR-0007's existing method) gains one new guard at its top: if `_modalOpen == true`, do not call `_play`/`_queueHighest` — instead keep only the highest-priority pending trigger (same `triggeredStatePriority` comparison `_queueHighest` already uses) in `_pendingVisual`, and return. This reuses `MochiComponent`'s existing priority-comparison logic rather than adding a second, parallel mechanism — `_pendingVisual` (modal-gating) and `_queued` (ADR-0007's existing LEVELING_UP-interrupt queue) are the same idea applied to two different gates and never need to interact directly, since being inside a non-interruptible LEVELING_UP animation and having a modal open are independent conditions checked at different points in the same method.

This mechanism is deliberately scoped to **any** open modal (context menu or Wardrobe), not just Wardrobe — the GDD names Wardrobe specifically because it is the realistic long-lived-modal case, but gating on "any modal open" is strictly safer (a context menu is normally dismissed in under a second, so this rarely engages for it) and costs nothing extra to implement uniformly.

### TR-petroom-005 — Never call `FlameGame` init/reset on tab return

Ratifies the existing implementation in `src/lib/ui/pet_room_screen.dart` (`_game` as a `State` field, constructed once, reused across every `build()`) as the permanent, binding pattern. Combined with ADR-0014's `StatefulShellRoute`/`IndexedStack` guarantee that the branch's `State` is never disposed on tab switch, this is already structurally correct and needs no code change — ADR-0016 Decision §2 already depends on this exact guarantee for its own cooldown-state persistence ("`MochiComponent` lives for the lifetime of Pet Room Screen's `FlameGame` instance"). What this ADR adds is two explicit, enforceable rules for every future Pet Room story:

1. **Forbidden**: constructing `PetRoomGame()` (or any `FlameGame` subclass for this screen) anywhere other than the `State`'s field declaration/`initState()` — never inline inside `build()`.
2. **Forbidden**: calling any lifecycle-reset-shaped method (a hypothetical `game.reset()`, manually re-invoking `onLoad()`, or removing-then-re-adding the full component tree) from any "on tab return" hook — including a future `activeChildBranchIndexProvider` listener, if one is ever added to this screen. Per the existing registry invariant (`docs/registry/architecture.yaml`, `activeChildBranchIndexProvider` entry, already citing TR-petroom-005): if Pet Room ever needs to know "am I the active tab," it reads that provider — it still must not use that signal to trigger any `FlameGame` init/reset call. The correct behavior on tab return is to do nothing; the game loop was never paused.

### Architecture Diagram

```
                    ┌───────────────────────────────────────────┐
                    │        PetRoomScreen (State, built once)   │
                    │        _game = PetRoomGame()  [singleton]  │
                    └───────────────────┬─────────────────────────┘
                                         │ GameWidget<PetRoomGame>(game: _game)
                    ┌────────────────────▼─────────────────────────┐
                    │                Flame World                    │
                    │  RoomBackgroundComponent   priority 0 (bottom) │
                    │  MochiComponent (SpriteComponent, ADR-0016)    │
                    │    priority 1                                  │
                    │    ├─ DragCallbacks (ADR-0016 — NOT TapCallbacks)│
                    │    ├─ size = computeHitArea(spriteSize).hitBoxSize
                    │    ├─ render(): sprite painted at true spriteSize,
                    │    │     centered (offset == padding)            │
                    │    └─ GameEventSubscriber (unchanged, ADR-0004)  │
                    └────────────────────┬─────────────────────────┘
                                         │ overlayBuilderMap
                    ┌────────────────────▼─────────────────────────┐
                    │  'chrome'  (always on, added once, never off) │
                    │  'context_menu' XOR 'wardrobe' (via showModal/│
                    │       dismissModal — mutually exclusive)      │
                    └─────────────────────────────────────────────┘

Flutter→Flame signal for TR-petroom-004 (one-way, reuses ADR-0004's bus):
  showModal()/dismissModal() call site
        │  emit(GameEvent(modalVisibilityChanged, bool))
        ▼
  GameEventBus (unchanged, ADR-0004)
        │
        ▼
  MochiComponent.onGameEvent → sets _modalOpen, gates onTrigger()/queues _pendingVisual
```

### Key Interfaces

```dart
// src/lib/gameplay/hit_area_formula.dart (NEW)
const double kTapHitboxMin = 80.0;
class HitArea { final double padding; final double hitBoxSize; const HitArea({required this.padding, required this.hitBoxSize}); }
HitArea computeHitArea(double spriteSize, {double hitBoxMin = kTapHitboxMin});

// src/lib/core/game_event_bus.dart (EXTENDED)
enum GameEventType { ..., modalVisibilityChanged }  // payload: bool

// src/lib/gameplay/pet_room_game.dart (EXTENDED)
class PetRoomGame extends FlameGame {
  void showModal(String overlayKey);   // 'context_menu' | 'wardrobe', mutually exclusive
  void dismissModal();
}

// src/lib/gameplay/mochi_component.dart (EXTENDED — base class/mixins per ADR-0016, unchanged here)
class MochiComponent extends SpriteComponent
    with GameEventSubscriber, DragCallbacks {
  // size == Vector2.all(computeHitArea(currentSpriteSize).hitBoxSize)   [this ADR]
  // render() overridden: sprite painted at currentSpriteSize, centered [this ADR]
  // new: _modalOpen (bool), _pendingVisual (TriggeredState?)           [this ADR]
}
```

## Alternatives Considered

### Alternative 1 (TR-petroom-003, superseded mid-draft): Add `TapCallbacks` to `MochiComponent`
- **Description**: An earlier draft of this ADR planned to add `TapCallbacks` to `MochiComponent` (in addition to whatever gesture handling Pet Interaction needed) and rely on its default hit-test for Formula 2.
- **Pros**: Would have been a self-contained decision, not dependent on a sibling ADR's timing.
- **Cons**: ADR-0016 (Pet Interaction Input Handling), Accepted the same day this ADR was drafted, explicitly rejected combining `TapCallbacks` with `DragCallbacks` on the same component — Flame's `DragCallbacks`-backed `ImmediateMultiDragGestureRecognizer` tends to win the gesture arena eagerly, starving or double-firing a sibling `TapCallbacks`' `MultiTapGestureRecognizer` (flame-specialist-confirmed, cited in ADR-0016 Decision §1). Adding `TapCallbacks` here would silently reintroduce the exact bug ADR-0016 just closed.
- **Rejection Reason**: Would contradict an Accepted sibling ADR's explicit, specialist-validated decision. This ADR instead builds on ADR-0016's `size`-based hit-test contract (see Decision, TR-petroom-003).

### Alternative 2 (TR-petroom-003 mechanism): Wrapper `PositionComponent` + child `SpriteComponent` for the visual
- **Description**: Keep `MochiComponent` as a bare `PositionComponent` (visual-free, hit-test-only), with a separate child `SpriteComponent` (no gesture mixins) rendering Mochi at its true size, centered.
- **Pros**: Cleanly separates "hit-test surface" from "visual," no render override needed.
- **Cons**: Directly contradicts ADR-0016's already-Accepted Key Interfaces, which fix `MochiComponent extends SpriteComponent with DragCallbacks` — changing the base class again here would relitigate an Accepted ADR, which is not this ADR's place. (The child-component approach itself is otherwise valid per ADR-0016's own no-gesture-mixin-on-children rule — a plain visual-only child would be fine — but the base-class question is already closed.)
- **Rejection Reason**: Contradicts an Accepted sibling ADR's stated interface. This ADR's render-override approach achieves the identical visual/hit-test split without touching the base class.

### Alternative 3 (TR-petroom-003 mechanism): Let the sprite scale up to fill the padded `size`
- **Description**: Don't override `render()` — accept the default `SpriteComponent` behavior of stretching the sprite to fill `size`, i.e. let Baby Mochi visually render at 80dp instead of its pinned 72dp.
- **Pros**: Zero extra code — the simplest possible implementation.
- **Cons**: Directly violates GDD Core Rule 4 ("không co giãn sprite lớn hơn thiết kế gốc, chỉ mở rộng vùng tap vô hình xung quanh") and the Art Bible's pinned 72/112/152dp values (Section 5.2, confirmed final 2026-07-14) — Baby Mochi would render 11% larger than its approved asset spec.
- **Rejection Reason**: Directly contradicts an explicit, non-negotiable GDD rule and a pinned Art Bible spec.

### Alternative 4 (TR-petroom-004 mechanism): Flame component reads a Riverpod provider directly
- **Description**: Instead of a new `GameEventType`, have `MochiComponent` read an `activeModalProvider`-style Riverpod state directly to decide whether to gate.
- **Pros**: Avoids adding a new event type.
- **Cons**: Would require the Flame layer to hold a `ProviderContainer`/`WidgetRef` reference, which nothing in this project's architecture does today — every existing Flame-side state read goes through `GameEventBus`, never a direct provider read (ADR-0004's one-way-bridge principle). A second access pattern for just this one case breaks the "one bridge, one direction, one mechanism" property that makes ADR-0004 easy to reason about project-wide.
- **Rejection Reason**: Violates the established single-bridge-mechanism principle for no compensating benefit; the event-based approach costs one new enum value and reuses 100% of the existing `GameEventSubscriber` machinery.

### Alternative 5 (TR-petroom-005 mechanism): Provider-driven game instance (e.g. `petRoomGameProvider`)
- **Description**: Move `PetRoomGame` construction into a Riverpod `Provider<PetRoomGame>` (matching the `router_provider` pattern registered for Navigation Shell), rather than a `State` field.
- **Pros**: Consistent with how the router singleton is held.
- **Cons**: The existing, already-implemented, already-tested placeholder (`src/lib/ui/pet_room_screen.dart`, ADR-0014 Story 002, AC-5) already uses the `State`-field pattern with a passing test proving the same instance survives tab switches. Switching to a provider would rewrite already-correct, already-verified code for no behavioral gain.
- **Rejection Reason**: Changing a working, tested pattern without a concrete problem it solves is unjustified churn. This ADR ratifies the existing pattern instead.

## Consequences

### Positive
- Pet Interaction Story 005 (Hit-Area Minimum Enforcement) is fully unblocked — `computeHitArea` is a concrete, importable, unit-testable function producing exactly the per-stage `size` data ADR-0016 Decision §3 said it was waiting on.
- All 5 TR-petroom requirements now have ADR coverage (4 from this ADR + TR-petroom-002 from ADR-0001) — `/create-stories pet-room-screen-ui` can produce Ready stories for composition, hit-area, modal-defer, and lifecycle work.
- No contradiction with ADR-0016 despite landing in the same session — this ADR builds directly on its hit-area contract and `MochiComponent` interface rather than re-deciding either.
- The modal-defer mechanism reuses 100% of the existing `GameEventBus`/`GameEventSubscriber` machinery — no new cross-boundary communication pattern, no new forbidden-pattern risk beyond "don't add a second reverse-direction case," which this ADR explicitly avoids.
- The hit-area formula lives in a pure-Dart file with no Flutter/Flame import, consistent with this project's existing pattern for testable formulas (`compute_energy.dart`).

### Negative
- `MochiComponent.size` now serves double duty (tap hit-test region via ADR-0016, not visual size) — a maintainer must read the doc comment to avoid assuming `size` reflects what's painted. Mitigated by a required doc-comment on that field (Validation Criteria).
- `MochiComponent.render()` is now a manual override instead of relying on `SpriteComponent`'s default paint path — a future maintainer adding visual effects (glow, tint) must remember to route them through the override, not assume `super.render()`'s default behavior applies.
- Two independent pending-trigger mechanisms now exist on `MochiComponent` (`_queued` for LEVELING_UP-interrupt, ADR-0007; `_pendingVisual` for modal-gating, this ADR) — reviewers must understand both to reason about triggered-state behavior fully, though they were designed to never need to interact directly.
- The `modalVisibilityChanged` event's `bool` payload is easy to misread as "is Pet Room screen itself visible" rather than "is a modal open within Pet Room" — mitigated by the enum member's name and a required doc comment.

### Risks
- **Risk**: `showModal()`/`dismissModal()` being the *only* sanctioned mutation path for `context_menu`/`wardrobe` overlay keys is enforced by convention/code review only — nothing in Flame prevents a future story from calling `game.overlays.add('wardrobe')` directly, bypassing mutual exclusivity. *Mitigation*: registered as a forbidden pattern (see registry candidates) so `/code-review` checks for direct `overlays.add`/`.remove` calls on these two keys outside `pet_room_game.dart`.
- **Risk**: A future story mounting a new Flame component near Mochi (e.g. Pet Equipment #15's slot sprites) copies the "override `render()`, pad `size`" pattern without realizing it's specific to Mochi's hit-area needs, when equipment slots have no tap-target requirement of their own. *Mitigation*: the Alternatives section states the decision criterion explicitly (component needs an invisible-padded tap surface distinct from its visual → this pattern; otherwise, plain default `SpriteComponent` rendering).
- **Risk (flame-specialist-flagged, carried from ADR-0016)**: if a future evolution-stage visual applies `PositionComponent.scale` to `MochiComponent` instead of swapping `size`/sprite per stage, the *effective* hit area becomes `size * scale`, silently invalidating Formula 2's output. *Mitigation*: not an active issue for MVP (stages are asset/size swaps per the GDD, not scale transforms); flagged here and in ADR-0016 for whoever implements Pet Leveling scale effects, if ever.
- **Risk**: `GameWidget`'s overlay rebuild behavior (every active overlay's builder re-runs on any single overlay toggle, flame-specialist-confirmed) could become a real cost if `'chrome'`'s status-row/level-bar widget tree grows heavy. *Mitigation*: not a concern at current scope (a status row + progress bar); flagged so a future story adding expensive chrome content applies Riverpod `.select`-scoped rebuilds internally, consistent with ADR-0001's existing "scoped rebuilds" discipline lever for Flutter-side cost.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| Pet Room Screen UI (#18) | TR-petroom-001 — Screen composition z-order; `GameWidget` hosts exactly one `FlameGame` | Defines the exact widget/component tree, `priority` values for the two Flame components, and the `overlayBuilderMap` key contract (`chrome`, `context_menu`, `wardrobe`) with a single mutual-exclusivity enforcement point (`showModal`/`dismissModal`) |
| Pet Room Screen UI (#18) | TR-petroom-003 — Formula 2, tap hit-area padding guarantees `hitBoxSize ≥ 80dp` | Ratifies the GDD's formula unchanged; adds the concrete `computeHitArea()` pure function and the `MochiComponent` sizing/render-override wiring that realizes ADR-0016's hit-area contract without visually scaling the pinned sprite art |
| Pet Room Screen UI (#18) | TR-petroom-004 — Modal defer when Wardrobe is open or a competing `GameEvent` arrives | Adds `GameEventType.modalVisibilityChanged` (one-way Flutter→Flame, reusing ADR-0004's bridge) and a `_modalOpen`/`_pendingVisual` gate on `MochiComponent.onTrigger` |
| Pet Room Screen UI (#18) | TR-petroom-005 — Never call `FlameGame` init/reset on tab return | Ratifies the existing `State`-field singleton pattern already implemented in `pet_room_screen.dart`; adds two explicit forbidden patterns for future stories |
| Pet Interaction (#14) | TR-petinteraction-004 (hit-area half — requirement and gesture-side contract owned by ADR-0016, not re-decided here) | This ADR's Formula 2 output is the concrete per-stage `size` data ADR-0016 Decision §3 already said Story 005 needs to complete its verification |

## Performance Implications
- **CPU/GPU**: No change to `drawCalls_sceneFlame` (still 5, per ADR-0001) — the padded hit box is a hit-test-only bounding box, not an additional renderable; `MochiComponent`'s render override still issues exactly one sprite paint call.
- **Memory**: Negligible — one new small value class (`HitArea`), one new enum member, one new `bool`/nullable-enum field pair on `MochiComponent`.
- **Load Time**: None.
- **Network**: N/A.

## Migration Plan
No migration in the rollback sense — this is new functionality layered onto the existing ADR-0014 Story 002 placeholder and consistent with ADR-0016's already-Accepted `MochiComponent` interface. Future stories under this epic:
1. Add `src/lib/gameplay/hit_area_formula.dart` (new file).
2. Extend `GameEventType` with `modalVisibilityChanged` in `src/lib/core/game_event_bus.dart`.
3. Extend `PetRoomGame` (`onLoad()` mounts background + Mochi; add `showModal`/`dismissModal`).
4. Extend `MochiComponent` per ADR-0016's base class/mixins (already decided) plus this ADR's `size` computation, `render()` override, and `_modalOpen`/`_pendingVisual` gating.
5. `PetRoomScreen`'s existing `_game` field and `GameWidget<PetRoomGame>(game: _game)` line require no change.
No existing public API is renamed or removed.

## Validation Criteria
- **Formula 2 (BLOCKING, `tests/unit/pet-room-screen-ui/`)**: unit tests on `computeHitArea` — exact-value assertions for `spriteSize` 56/72/96/112/152dp (±0.01dp tolerance per GDD AC), plus a property-based check that `hitBoxSize >= 80` holds for `spriteSize` sampled across `[0, 500]`.
- **Composition (TR-petroom-001)**: widget test asserting exactly one `GameWidget<PetRoomGame>` exists in `/child/pet-room`'s tree; a component-tree test (once `onLoad()` is implemented) confirming `RoomBackgroundComponent.priority < MochiComponent.priority` and both are direct `World` children; a test driving `showModal('context_menu')` then `showModal('wardrobe')` and asserting `overlays.value` never contains both keys simultaneously.
- **Modal defer (TR-petroom-004, BLOCKING, `tests/integration/pet-room-screen-ui/`)**: integration test — open `wardrobe` overlay, emit `petLeveledUp` via `GameEventBus`, assert `MochiComponent.currentTriggeredState` stays `null`; call `dismissModal()`, assert the LEVELING_UP animation now plays.
- **Lifecycle (TR-petroom-005)**: relies on and does not duplicate ADR-0014 Story 002's existing AC-5 test (same `PetRoomGame` instance + monotonically increasing `updateTickCount` across a branch switch away and back) — a code-review/lint check additionally confirms no `PetRoomGame(` constructor call exists outside `_PetRoomScreenState`'s field declaration.
- **Doc comment check**: `MochiComponent.size`'s doc comment must state it is the padded tap hit-test region (per ADR-0016), not the visual sprite size (regression check against Consequences → Negative).
- **Render-override check**: a golden/widget test confirms Baby Mochi (`spriteSize = 72`) renders at 72dp, not 80dp, despite `size == 80` — direct regression coverage for Alternative 3's rejection.

## Related Decisions
- ADR-0001: Draw-Call Budget Scope — this ADR's composition keeps the same 5-component tally.
- ADR-0004: Flutter-Flame Event Bridge Architecture — `modalVisibilityChanged` follows its one-way bridge contract exactly.
- ADR-0007: Pet State Machine Architecture — `MochiComponent`'s existing triggered-state priority/queue logic (`_queued`) is extended, not replaced, by `_pendingVisual`.
- ADR-0014: Navigation Shell & Route Guard Architecture — TR-petroom-005 ratifies its Story 002 placeholder pattern.
- **ADR-0016: Pet Interaction Input Handling** — this ADR's closest dependency: supplies the hit-area contract and `MochiComponent`'s base class/mixins this ADR builds on directly (see ADR Dependencies, Alternatives Considered).
- Related design document: `design/gdd/pet-room-screen-ui.md` (Core Rules 1-5, Formula 2, Edge Cases 1-5).
- Related epic: `production/epics/pet-interaction/story-005-hit-area-minimum-enforcement.md` (unblocked by this ADR's Formula 2 output).
