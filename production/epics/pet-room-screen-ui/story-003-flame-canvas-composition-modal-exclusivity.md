# Story 003: Flame Canvas Composition, Z-Order & Modal Mutual Exclusivity

> **Epic**: Pet Room Screen UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 3-4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-room-screen-ui.md`
**Requirement**: `TR-petroom-001` (composition/hosting/mutual-exclusivity half — see Story 006/007 for the chrome and modal *content* this story's contract hosts)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Pet Room Screen Rendering & Interaction Contract (Decision → TR-petroom-001).
**ADR Decision Summary**: Defines the exact widget/component tree (bottom→top): `GameWidget<PetRoomGame>` hosting exactly one `FlameGame`, whose `World` has exactly two direct children — `RoomBackgroundComponent` (`priority: 0`) and `MochiComponent` (`priority: 1`, `SpriteComponent`/`DragCallbacks` per ADR-0016) — with `overlayBuilderMap` stacking `'chrome'` (always on), `'context_menu'`, and `'wardrobe'` (mutually exclusive) above the canvas. `PetRoomGame.showModal(overlayKey)`/`.dismissModal()` are the ONLY sanctioned mutation path for the two modal overlay keys — direct `game.overlays.add`/`.remove` calls on `'context_menu'`/`'wardrobe'` from anywhere else are forbidden.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM-HIGH
**Engine Notes**: `priority` orders paint among *direct siblings only* (flame-specialist source-verified) — `RoomBackgroundComponent` and `MochiComponent` must both be direct children of the same `World` for `priority: 0`/`priority: 1` to have any effect; do not nest one inside the other. `GameWidget.overlayBuilderMap`'s `OverlayManager.add`/`.remove` rebuilds *every* currently-active overlay's builder (not just the toggled one) — each overlay is `KeyedSubtree`-wrapped so state survives; this is a build-cost note, not a remount risk, and not a blocker for this story's scope (chrome is a status row + progress bar).

**Control Manifest Rules (this layer)**:
- Required: `drawCalls_sceneFlame` accounting stays consistent with Story 002's Formula 1 constants (background=1, Mochi base=1) — this story mounts the real components those constants describe (source: ADR-0001).
- Required: Overlay widgets use targeted `Consumer`/`Selector` (Riverpod `select`) rebuild scoping, not whole-subtree rebuilds on every tick (source: ADR-0001, Presentation Layer Rules).
- Forbidden: calling `game.overlays.add`/`.remove` directly with `'context_menu'`/`'wardrobe'` from anywhere other than `PetRoomGame.showModal`/`.dismissModal` (registry candidate, source: ADR-0017 Consequences → Risks).
- Forbidden: `TapDetector`/`DragDetector` (source: Forbidden APIs list, control-manifest.md) — unaffected by this story directly, but the component tree this story mounts must not reintroduce them.

---

## Acceptance Criteria

*From GDD `design/gdd/pet-room-screen-ui.md`, scoped to this story:*

- [ ] **AC-CR1-1** (Core Rule 1): GIVEN `/child/pet-room` renders with 0 modals open, THEN exactly 3 layers exist in z-order: room background (lowest) → `MochiComponent` (middle) → Flutter overlay chrome (status row + level bar, highest) — no modal layer mounted.
- [ ] **AC-CR1-2** (Core Rule 1): GIVEN any modal is open (context menu XOR Wardrobe, never both), THEN that modal renders above all other layers including overlay chrome.
- [ ] **AC-CR2** (Core Rule 2): GIVEN app startup, WHEN Main Navigation Shell (#17) renders Tab 1 (default), THEN the active route is `/child/pet-room` and `GameWidget` contains exactly 1 `FlameGame` instance with `MochiComponent` + background component mounted in the component tree.
- [ ] **AC-CR3** (Core Rule 3): GIVEN `/child/pet-room` mounts, THEN the screen only subscribes to `GameEventBus().stream` — no `.init()`/reset-shaped method call (regression check against double-init; calling the `GameEventBus()` factory constructor itself is always valid, including as the first call in the app).
- [ ] **AC-EC3** (Edge Case 3): GIVEN the context menu is open, WHEN bé taps outside the menu, THEN it dismisses with no other action triggered by that same tap.

---

## Implementation Notes

*Derived from ADR-0017 Decision → TR-petroom-001:*

- Widget/component tree (bottom → top), all inside `PetRoomScreen`'s `Scaffold.body`:
  ```
  Scaffold
  └── GameWidget<PetRoomGame>(game: _game)
        ├── Flame World (direct children only)
        │     ├── RoomBackgroundComponent   (SpriteComponent, priority: 0)
        │     └── MochiComponent            (SpriteComponent, priority: 1)
        └── overlayBuilderMap:
              ├── 'chrome'        — added once, right after game.onLoad() resolves; never removed
              ├── 'context_menu'  — modal
              └── 'wardrobe'      — modal
  ```
- `PetRoomGame.onLoad()` mounts exactly the two Flame components above and nothing else — keeps Story 002's `drawCalls_sceneFlame = 5` tally intact (a future Pet Equipment story adds the 3 slot components at `priority: 2` or as `MochiComponent` children — out of this story's scope, only the constraint is noted: none of those future slot components may register their own `TapCallbacks`/`DragCallbacks`).
- Modal mutual exclusivity — the ONLY sanctioned mutation path:
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
- `RoomBackgroundComponent` for this story is a minimal `SpriteComponent` placeholder (real Art Bible background asset is a separate content task, not this story's blocker) — the structural contract (mounted, `priority: 0`, direct `World` child) is what this story proves, not the final art.
- `'chrome'` overlay content (status row + level bar) and `'context_menu'`/`'wardrobe'` overlay *content* (the 3-option menu, the 3-slot sheet) are Story 006/007's scope — this story only proves the overlay keys exist, are mounted/dismissed correctly, and are mutually exclusive; a minimal placeholder widget (e.g. `SizedBox.shrink()` or a labeled `Container`) is acceptable for each overlay's builder at this story's scope, to be replaced by Story 006/007.
- AC-CR3's "no init/reset" check: this screen only ever calls `GameEventBus()` (the factory constructor) to obtain the singleton and `.stream.listen(...)` — never a separate `.init()`/reset method. Per the GDD's own implementation note, this is true even if this is technically the first `GameEventBus()` call in the whole app (lazy-init via factory constructor is not "double-init").

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001 (Formula 2): `MochiComponent`'s `size`/`render()` hit-area wiring — this story mounts `MochiComponent` but does not change its sizing contract.
- Story 002 (Formula 1): the draw-call constants — this story's real mounted tree should stay consistent with Story 002 but does not import its code.
- Story 004 (Modal Defer): the `modalVisibilityChanged` `GameEvent` and `MochiComponent`'s `_modalOpen`/`_pendingVisual` gating — this story only establishes `showModal`/`dismissModal` as call sites; Story 004 adds the event emission around those calls.
- Story 006 (Persistent Chrome): the real status row / level bar widget content inside the `'chrome'` overlay.
- Story 007 (Context Menu & Wardrobe): the real 3-option menu / 3-slot Wardrobe sheet content inside `'context_menu'`/`'wardrobe'`.

---

## QA Test Cases

*Concrete test cases (lean review mode — written directly into the story, no qa-lead gate spawned per `production/review-mode.txt`).*

- **AC-CR1-1**: Given `/child/pet-room` pumped with no modal opened — When: inspecting the widget/component tree — Then: assert `GameWidget<PetRoomGame>` is present, `RoomBackgroundComponent.priority < MochiComponent.priority`, both are direct `World` children, and neither `'context_menu'` nor `'wardrobe'` appear in `game.overlays.value`.
- **AC-CR1-2**: Given `showModal('context_menu')` then, separately, `showModal('wardrobe')` — When: `game.overlays.value` is inspected after each call — Then: assert it never contains both keys simultaneously, and the just-opened modal's overlay widget is the topmost in paint order.
- **AC-CR2**: Given a fresh app start — When: Main Navigation Shell renders its default tab — Then: assert route is `/child/pet-room` and exactly one `GameWidget<PetRoomGame>` exists in the tree, with `MochiComponent` + `RoomBackgroundComponent` both present in `game.world.children` after `onLoad()` resolves.
- **AC-CR3**: Given `/child/pet-room` mounts — When: scanning this screen's own source for `GameEventBus` calls — Then: assert only `GameEventBus()` (factory) + `.stream.listen(...)` appear; no `.init()`/`.reset()`-shaped call exists (static/regression check, not a runtime assertion).
- **AC-EC3**: Given the context menu is open (`showModal('context_menu')`) — When: a tap lands outside the menu's bounds (including on Mochi) — Then: assert `dismissModal()`-equivalent state is reached (`overlays.value` no longer contains `'context_menu'`) and no other handler (e.g. Mochi's own tap-to-open-menu) fires from that same tap.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pet-room-screen-ui/composition_and_modal_exclusivity_test.dart` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 004 (Modal Defer — needs `showModal`/`dismissModal` call sites), Story 006 (Persistent Chrome — needs the `'chrome'` overlay key), Story 007 (Context Menu & Wardrobe — needs `'context_menu'`/`'wardrobe'` overlay keys)
