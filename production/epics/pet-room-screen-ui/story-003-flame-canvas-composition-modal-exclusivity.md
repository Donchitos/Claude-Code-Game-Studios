# Story 003: Flame Canvas Composition, Z-Order & Modal Mutual Exclusivity

> **Epic**: Pet Room Screen UI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 3-4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-24

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

- [x] **AC-CR1-1** (Core Rule 1): GIVEN `/child/pet-room` renders with 0 modals open, THEN exactly 3 layers exist in z-order: room background (lowest) → `MochiComponent` (middle) → Flutter overlay chrome (status row + level bar, highest) — no modal layer mounted.
- [x] **AC-CR1-2** (Core Rule 1): GIVEN any modal is open (context menu XOR Wardrobe, never both), THEN that modal renders above all other layers including overlay chrome.
- [x] **AC-CR2** (Core Rule 2): GIVEN app startup, WHEN Main Navigation Shell (#17) renders Tab 1 (default), THEN the active route is `/child/pet-room` and `GameWidget` contains exactly 1 `FlameGame` instance with `MochiComponent` + background component mounted in the component tree.
- [x] **AC-CR3** (Core Rule 3): GIVEN `/child/pet-room` mounts, THEN the screen only subscribes to `GameEventBus().stream` — no `.init()`/reset-shaped method call (regression check against double-init; calling the `GameEventBus()` factory constructor itself is always valid, including as the first call in the app).
- [x] **AC-EC3** (Edge Case 3): GIVEN the context menu is open, WHEN bé taps outside the menu, THEN it dismisses with no other action triggered by that same tap.

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

**Status**: [x] Created — 8 tests, all passing (`cd src && flutter test ../tests/integration/pet-room-screen-ui/composition_and_modal_exclusivity_test.dart`) — grew from 6 to 8 in the Post-Closure Fix below.

---

## Implementation Record

**Files created**:
- `src/lib/gameplay/room_background_component.dart` — `RoomBackgroundComponent` (`SpriteComponent`, `priority: 0`), a solid Cream Ivory (`#FFFDF0`, Art Bible Section 4 Primary Palette) fill sprite generated via `PictureRecorder`/`Canvas`/`Picture.toImage` (same technique as `MochiComponent._createPlaceholderSprite`, painting an actual fill color instead of leaving it transparent). Fixed logical size `Vector2(400, 800)` — no camera/viewport contract exists on `PetRoomGame` yet, documented as a future-work gap in the file's own doc comment.
- `tests/integration/pet-room-screen-ui/composition_and_modal_exclusivity_test.dart` — 6 tests covering AC-CR1-1, AC-CR1-2, AC-CR2, AC-CR3, AC-EC3 (+1 extra confidence check that tapping the menu itself doesn't self-dismiss).

**Files modified**:
- `src/lib/gameplay/pet_room_game.dart` — `onLoad()` now mounts `RoomBackgroundComponent` (priority 0) and `MochiComponent` (priority 1, set explicitly via its public `priority` setter since `MochiComponent`'s own constructor doesn't expose it) as direct `World` children; added `showModal(String)`/`dismissModal()` exactly per the story's/ADR-0017's code sample; added `mochi` (`@visibleForTesting` accessor); kicks off the interim real Mochi sprite load (`assets/sprites/mochi_baby_happy_idle.png`, via `Images(prefix: 'assets/sprites/').load(...)`) as an `unawaited` background future (NOT inside `MochiComponent.onLoad()` — see the file's own doc comment for the exact Flame 1.37 `_ImageAsset.future()` unhandled-error gotcha this avoids) so it never blocks `onLoad()`'s own resolution; adds `'chrome'` to `overlays` as the last step of `onLoad()`.
- `src/lib/ui/pet_room_screen.dart` — wired `overlayBuilderMap` (`'chrome'`, `'context_menu'`, `'wardrobe'`) into `GameWidget<PetRoomGame>`; minimal placeholder widgets for `'chrome'`/`'wardrobe'`; `'context_menu'`'s placeholder implements the real AC-EC3 dismiss-on-outside-tap mechanism (full-screen opaque `GestureDetector` scrim behind a small centered placeholder box, itself wrapped in its own opaque `GestureDetector` so a tap on the menu doesn't fall through to the scrim). Added 3 `@visibleForTesting` `Key` constants so the test file can assert on overlay presence without depending on private widget class names. `updateTickCount`/`update(dt)` untouched.

**Interim Mochi sprite — real-app verification**: confirmed via `tests/integration/pet-room-screen-ui/composition_and_modal_exclusivity_test.dart`'s `_reachChildPetRoom`-based AC-CR2 test, which pumps a full `MaterialApp.router` (real `AssetBundle`/`ServicesBinding` context, not the narrower `testWithGame` harness) through to `/child/pet-room` and asserts `MochiComponent` is mounted — this is the same asset-bundle context the real app has. The load path itself (`Images(...).load('mochi_baby_happy_idle.png')` → `mochi.sprite = Sprite(image)`) was exercised without triggering any unhandled-Future error during the full suite run (0 new failures, 0 new unhandled-error output). Not independently screenshot-verified in this session (no device/simulator available), but the asset is confirmed registered in `pubspec.yaml`'s `assets: - assets/sprites/` and present on disk at `assets/sprites/mochi_baby_happy_idle.png`.

**Gotcha encountered and fixed during implementation**: an initial version awaited the interim sprite load inline inside `PetRoomGame.onLoad()`. This regressed `tests/integration/main-navigation-shell/child_shell_test.dart`'s `test_AC5_sameFlameGameInstance_survives_offstage_branch_switch_and_keeps_ticking` — real asset I/O does not resolve within that test's bounded `tester.pump()` step budget, so `GameWidgetState.loaderFuture` (which gates `game.mount()`/ticker start on `onLoad()`'s own future) never completed in time, leaving `updateTickCount` stuck at 0. Fixed by firing the sprite load as an `unawaited` background future instead — `onLoad()` now resolves immediately after mounting the two Flame components, matching the original placeholder's same-microtask-turn contract AC-5 depends on, while the real sprite still swaps in moments later once the asset genuinely finishes loading.

**Code review**: self-review (per this session's process instruction — lean review mode, no nested flame-specialist/qa-tester agents spawned). Checked: ADR-0017's component tree/priority/overlay-key contract implemented exactly as specified; `showModal`/`dismissModal` match the ADR's code sample verbatim; no direct `overlays.add`/`.remove` on `'context_menu'`/`'wardrobe'` anywhere outside `pet_room_game.dart` (grepped project-wide, confirmed clean — Control Manifest forbidden-pattern check); AC-CR3 static scan confirmed no `.init()`/`.reset()`-shaped `GameEventBus` call at the screen layer (this screen doesn't call `GameEventBus` directly at all — subscription is entirely internal to `MochiComponent`, unchanged by this story); `MochiComponent`'s own tap/swipe/drag behavior left completely untouched, confirmed via the full pre-existing Pet Interaction/Pet State Machine regression suite staying green. One real regression found and fixed during self-review — see the Gotcha note above. `game.overlays.value` (as literally written in the story/ADR's QA Test Case prose) does not exist on the installed `flame-1.37.0` `OverlayManager`; corrected to the real API (`activeOverlays`) in the test file, documented inline there.

**Test results**: Full suite — baseline 563 passing / 1 pre-existing skip → final 569 passing / 1 pre-existing skip (net +6, all from this story's new test file). `flutter analyze` (project-wide, from `src/`): 0 issues in any file this story touched; 13 pre-existing `info`-level issues elsewhere (unrelated `prefer_initializing_formals` in Auth/PIN repositories), unchanged by this story.

**Known open design conflict (not resolved by this story, flagged for Story 007)**: `design/gdd/pet-room-screen-ui.md` Core Rule 4/5 describes tapping Mochi as opening a context menu (with "Vuốt ve" as a menu option that then triggers Pet Interaction's pet action) — but the actual shipped `MochiComponent` (ADR-0016) uses `DragCallbacks` only and fires `petInteracted` directly on tap/swipe, with no context menu involved. This story's own Out of Scope section correctly does not require wiring Mochi's tap to `showModal('context_menu')` — `showModal`/`dismissModal` only needed to work as standalone, directly-callable methods for this story's ACs, which they do. The contradiction between the GDD's context-menu-on-tap model and ADR-0016's direct-fire model is a real, unresolved product decision that must be settled before Story 007 (Context Menu & Wardrobe) can correctly wire the menu's trigger.

---

## Post-Closure Fix — 2026-07-24

A real user live-tested the running app after this story closed and found two visible rendering bugs neither this story's own test suite nor its self-review had caught — both diagnosed and fixed the same day, then independently code-reviewed (flame-specialist + flame-widget-specialist + qa-tester, three parallel reviews).

**Bug 1 — Mochi/background painted from screen-center, not top-left.** Flame 1.37's `CameraComponent`/`Viewfinder.anchor` defaults to `Anchor.center` (source-verified, `viewfinder.dart:81`) — world coordinate (0,0) maps to the viewport's CENTER, not its top-left corner. `RoomBackgroundComponent`/`MochiComponent` both default to `position: Vector2.zero()` with their own `Anchor.topLeft`, so combined with the camera's center-anchored world origin, both components painted starting from screen-center instead of the actual top-left, leaving most of the canvas black. Fix: `PetRoomGame.onLoad()` now sets `camera.viewfinder.anchor = Anchor.topLeft;` before mounting any components.

**Bug 2 — background still didn't fill the canvas after fixing Bug 1.** `RoomBackgroundComponent`'s constructor originally passed no explicit `size`, leaving `SpriteComponent._autoResize` at its implicit default (`true`, since `autoResize ?? size == null`) — when `onLoad()` assigned the 1×1px placeholder fill sprite, the `sprite` setter auto-resized `size` down to `Vector2(1, 1)`, silently undoing an `onGameResize` override that otherwise correctly synced `size` to the game's real canvas size on every resize. flame-specialist review additionally found this was a genuine race, not just a stale value: `Component.addAll(...)`'s returned future resolves once loading finishes, not once the component is fully mounted (`_mount()`, which is what actually calls `onGameResize`) — so relying on `onGameResize` alone to "self-correct" after the auto-shrink was never guaranteed to win the race. Fix: constructor now passes `size: Vector2.zero(), autoResize: false` explicitly, so the sprite assignment can never override the size `onGameResize` maintains.

**Code review (3 parallel specialists, both files' fixes)**:
- **flame-specialist** (`pet_room_game.dart`, `room_background_component.dart`): **APPROVED WITH SUGGESTIONS**, no required changes. Confirmed both fixes correct and idiomatic against installed `flame-1.37.0` source. 2 non-blocking suggestions: (1) `_loadInterimMochiSprite`'s throwaway `Images(prefix: ...)` instance bypasses the game's own `images` cache (`Flame.images`), meaning the loaded image is invisible to later `fromCache`/`clearCache` calls — not fixed here, flagged for whoever next touches that code path; (2) ADR-0017 never mentions `camera`/`viewfinder`/`anchor` at all — a genuine documentation gap (not a contradiction) recommended for a future ADR-0017 amendment, since `Anchor.topLeft` is now a load-bearing contract every future Pet Room component implicitly depends on. Also flagged (not a regression from this fix): `MochiComponent`'s `position` is still unset (`Vector2.zero()` default) — no story yet owns Mochi's actual room placement; likely overlaps the `'chrome'` status row visually. Not fixed here — out of scope.
- **flame-widget-specialist** (`xu_chip.dart`, `contextual_badge_chip.dart` — the unrelated XuChip/BadgeChip layout bug found during the same live-testing session, see below): **APPROVED WITH SUGGESTIONS**, no required changes to the fix itself. Found the existing touch-target test (`test_touchTarget_profileAndXuChip_meetMinimum48x48dp`) only asserted a lower bound (`>= 48`) and would not have caught the original "chip exploded to full screen height" bug; `ContextualBadgeChip` had zero layout-size test coverage at all.
- **qa-tester**: **BLOCKING** on the two Pet Room fixes — no regression test existed for either bug, violating this project's own `test-standards.md` rule ("every bug fix must have a regression test that would have caught the original bug"). Provided concrete assertion sketches for both.

**Regression tests added** (closing the qa-tester BLOCKING finding and the flame-widget-specialist suggestion):
- `tests/integration/pet-room-screen-ui/composition_and_modal_exclusivity_test.dart` — new group "Camera anchor & background resize regression": `test_onLoad_setsViewfinderAnchorToTopLeft_notTheFlameDefaultCenter` (direct regression check for Bug 1) and `test_roomBackground_fillsTheActualGameCanvasSize_notAFixedOrShrunkSize` (asserts `background.size == game.size`, not `Vector2(1,1)` or a stale hardcoded constant, then calls `game.onGameResize(...)` again to confirm the sync survives a later resize, not just the initial mount — closes Bug 2). Also corrected a stale comment in the pre-existing AC-EC3 test that had (accidentally, for the wrong reason) claimed a top-left tap lands near Mochi — true now, for the right reason, post-fix.
- `tests/integration/main-navigation-shell/chip_cluster_test.dart` — added an upper-bound assertion (`xuSize.height < 60`) to the existing touch-target test, plus a new `test_touchTarget_contextualBadgeChip_meetsMinimumAndDoesNotExplode` test (`ContextualBadgeChip` had none before).

**Unrelated bug found and fixed in the same live-testing session (XuChip/ContextualBadgeChip layout, Main Navigation Shell epic — Complete, not reopened, fixed as a documented cross-epic patch here since it was found during this session's Pet Room testing)**: `XuChip`/`ContextualBadgeChip` both wrapped content in a bare `Center(child: ...)`; under `FloatingChipCluster`'s Row (loose-but-finite max-height constraint from `Positioned.fill`), `Center`'s non-shrink-wrap default expanded to the full available height instead of the pill's actual content size. Fixed with `Center(widthFactor: 1, heightFactor: 1, child: ...)` in both files — shrink-wraps to content while still respecting the ≥48dp `ConstrainedBox` minimum via `BoxConstraints.constrain` clamping upward.

**Test results**: Full suite — baseline 569 passing / 1 pre-existing skip → final 572 passing / 1 pre-existing skip (net +3: 2 new Pet Room regression tests + 1 new ContextualBadgeChip touch-target test; the XuChip upper-bound check was added to an existing test, not a new one). `flutter analyze`: 0 issues in any file touched by this fix; 13 pre-existing unrelated `info`-level issues elsewhere, unchanged.

**No git commit made yet** — pending explicit user go-ahead per this project's established pattern.

---

## Dependencies

- Depends on: None
- Unlocks: Story 004 (Modal Defer — needs `showModal`/`dismissModal` call sites), Story 006 (Persistent Chrome — needs the `'chrome'` overlay key), Story 007 (Context Menu & Wardrobe — needs `'context_menu'`/`'wardrobe'` overlay keys)
