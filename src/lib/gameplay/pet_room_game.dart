import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:meta/meta.dart';

import '../core/game_event_bus.dart';
import 'mochi_component.dart';
import 'room_background_component.dart';

/// Pet Room's [FlameGame] (main-navigation-shell Story 002, ADR-0014
/// Decision §2 — placeholder origin; Pet Room Screen UI Story 003, ADR-0017
/// Decision → TR-petroom-001 — real composition). `onLoad()` mounts exactly
/// the two Flame components ADR-0017's component tree diagram specifies as
/// direct `World` children — [RoomBackgroundComponent] (`priority: 0`) and
/// [MochiComponent] (`priority: 1`) — and nothing else, keeping Story 002's
/// `drawCalls_sceneFlame = 5` tally intact (ADR-0001). [Game.onLoad] no
/// longer defaults to a synchronous no-op for this subclass now that real
/// components are mounted, but adding two in-memory components (no asset
/// I/O beyond the interim Mochi sprite load below, itself wrapped so its
/// failure never blocks mounting) keeps `game.load()`'s future resolving
/// promptly.
///
/// [updateTickCount] is a test-only instrumentation hook — NOT gameplay
/// state — that exists solely to give AC-5's test something to assert
/// against that is genuinely part of the live `GameLoop`/`FlameGame`
/// instance, not a UI-visible proxy (Implementation Note 5). It proves the
/// engine's `update(dt)` loop keeps running while this branch is offstage
/// (`Offstage(offstage: true, child: TickerMode(enabled: false, ...))`, per
/// `StatefulShellRoute.indexedStack`'s branch container) — Flame's
/// `GameLoop` drives itself via a raw `Ticker(_tick)` constructed directly,
/// bypassing `TickerProvider`/`TickerMode` entirely (ADR-0014 Decision §2),
/// so it is never muted by the `TickerMode(enabled: false)` wrapper above an
/// inactive branch.
class PetRoomGame extends FlameGame {
  /// Incremented on every `update(dt)` call, including while this branch's
  /// `GameWidget` is offstage. Read via the widget tree in tests
  /// (`tester.widget<GameWidget<PetRoomGame>>(...).game.updateTickCount`) —
  /// production code never reads this field.
  @visibleForTesting
  int updateTickCount = 0;

  /// The single [MochiComponent] mounted by [onLoad] — exposed so
  /// `PetRoomScreen`'s overlay builders and future stories (Story 004's
  /// `modalVisibilityChanged` emission, Story 007's context-menu content)
  /// can reach it without re-querying `world.children`. `null` until
  /// [onLoad] resolves.
  ///
  /// Not `@visibleForTesting` — this doc comment's own stated purpose
  /// (Story 007's `PetRoomContextMenu` reading Mochi's position/size for
  /// its speech-bubble anchor) is real production overlay-widget code, not
  /// test-only access; the annotation was left over from before that real
  /// consumer existed and tripped `invalid_use_of_visible_for_testing_member`
  /// once `pet_room_context_menu.dart` actually used it as intended.
  MochiComponent? mochi;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Flame 1.37's `CameraComponent`/`Viewfinder` defaults `anchor` to
    // `Anchor.center` (`flame-1.37.0/lib/src/camera/viewfinder.dart:81`) —
    // world coordinate (0,0) is mapped to the CENTER of the viewport, not
    // its top-left corner. `RoomBackgroundComponent`/`MochiComponent` both
    // default to `position: Vector2.zero()` with their own `Anchor.topLeft`
    // (each component's own top-left corner sits at its `position`) —
    // combined with the camera's center-anchored world origin, this placed
    // both components' top-left corner at screen-center, painting them only
    // in the bottom-right quadrant instead of filling the viewport from its
    // actual top-left corner (found via live user testing — a real visible
    // bug, not caught by any existing test, since none asserted on-screen
    // pixel position through a real `CameraComponent`). Re-anchoring the
    // viewfinder to `Anchor.topLeft` makes world (0,0) coincide with the
    // viewport's top-left corner, matching what both components' own
    // position/anchor already assume.
    camera.viewfinder.anchor = Anchor.topLeft;

    final background = RoomBackgroundComponent();
    final mochiComponent = MochiComponent()
      // `MochiComponent`'s own constructor (owned by the Pet Interaction
      // epic, ADR-0016) does not set `priority` — it defaults to 0, same as
      // `RoomBackgroundComponent`. ADR-0017 Decision → TR-petroom-001's
      // component tree diagram requires `MochiComponent priority: 1`
      // (painted above the background); `priority` has a public setter
      // (`Component.priority=`, flame-1.37.0 source-verified,
      // `component.dart:908`) precisely for cases like this — an existing
      // component whose own constructor doesn't expose the value this
      // story's composition contract needs.
      ..priority = 1;
    mochi = mochiComponent;
    await world.addAll([background, mochiComponent]);

    // Interim real Mochi sprite (Story 003) — kicked off HERE, at the
    // `PetRoomGame` level, deliberately NOT inside
    // `MochiComponent.onLoad()`. Flame 1.37's `Images.load()` ->
    // `_ImageAsset.future()` internally registers a bare `.then(onSuccess)`
    // on the same underlying Future it returns via `retrieveAsync()`, with
    // no `onError` handler
    // (`flame-1.37.0/lib/src/cache/images.dart`, `_ImageAsset.future`) — if
    // that future rejects (e.g. no real `ServicesBinding`/asset bundle,
    // which is exactly the situation in every `flame_test`-based
    // `testWithGame` unit test that constructs `MochiComponent` directly, a
    // large fraction of the Pet Interaction epic's existing test suite),
    // the rejection surfaces as an UNHANDLED Future error that no try/catch
    // around the call site can suppress. Loading it here instead means only
    // real app runs and `testWidgets`-based integration tests (which pump a
    // full `MaterialApp`/`GameWidget` and therefore have a real asset
    // bundle) ever exercise this path; `MochiComponent`'s own narrower unit
    // tests never call `PetRoomGame.onLoad()` and are therefore unaffected.
    //
    // Deliberately NOT awaited here (`unawaited`, not `await`): real asset
    // I/O (`AssetBundle.load` + image decoding) does not resolve on the
    // same microtask turn the way the rest of `onLoad()` does, and
    // `GameWidgetState.loaderFuture` (flame-1.37.0 source-verified,
    // `game_widget.dart:207-215`) gates `game.mount()` — and therefore the
    // real `GameLoop`/`Ticker` ever starting — on `onLoad()`'s OWN future
    // resolving. Awaiting the sprite load inline here was tried first and
    // found to regress `child_shell_test.dart`'s AC-5 (the ticker never
    // started within the test's bounded pump-step budget, since real asset
    // I/O doesn't complete within a handful of 16ms `tester.pump()` frames)
    // — confirmed by reproducing the failure during this story's
    // implementation. Firing it in the background instead lets `onLoad()`
    // resolve immediately after the two components are added (matching the
    // original placeholder's same-microtask-turn contract that AC-5 —
    // and, transitively, Story 002/ADR-0014 — depends on), while the real
    // sprite still swaps in moments later once the asset genuinely
    // finishes loading (imperceptible in the real app; irrelevant to tests
    // that don't assert on the sprite's `image` identity).
    //
    // This is an INTERIM MVP visual only, not real mood-reactive art — Pet
    // Leveling #16 owns per-evolution-stage/per-mood sprite swapping as its
    // own future story (see `MochiComponent`'s own doc comments). On any
    // failure (missing asset bundle, decode error, etc.) `MochiComponent`'s
    // own transparent placeholder sprite (set inside its `onLoad()`) is left
    // in place untouched.
    unawaited(_loadInterimMochiSprite(mochiComponent));

    // 'chrome' — added once, right here (the literal last step of onLoad,
    // i.e. "immediately after the game's first onLoad() resolves" per
    // ADR-0017 Decision → TR-petroom-001's component tree diagram); never
    // removed for the screen's lifetime. Done inside `onLoad()` itself
    // rather than from `PetRoomScreen` (e.g. via `game.ready()` after the
    // widget mounts) because `GameWidget._initializeGame` registers every
    // `overlayBuilderMap` entry with `game.overlays` BEFORE calling
    // `game.load()` (flame-1.37.0 source-verified,
    // `game_widget.dart:186-201` vs. `loaderFuture` at line 207) — so the
    // `'chrome'` builder is already registered by the time this line runs,
    // and adding it here needs no cross-widget-boundary timing signal at
    // all.
    overlays.add('chrome');
  }

  /// See the `unawaited(...)` call site in [onLoad] for why this is a
  /// separate, deliberately-not-awaited method rather than inline code.
  static Future<void> _loadInterimMochiSprite(MochiComponent mochi) async {
    try {
      final image = await Images(
        prefix: 'assets/sprites/',
      ).load('mochi_baby_happy_idle.png');
      mochi.sprite = Sprite(image);
    } catch (_) {
      // Expected in any test harness without a real asset bundle — leave
      // MochiComponent's transparent placeholder in place.
    }
  }

  /// The ONLY sanctioned mutation path for the two modal overlay keys
  /// (ADR-0017 Decision → TR-petroom-001: "Calling `game.overlays.add`/
  /// `.remove` directly with either of those two keys from anywhere else is
  /// a forbidden pattern"). Enforces mutual exclusivity structurally: both
  /// keys are always removed before the requested one is added, so at no
  /// point can both `'context_menu'` and `'wardrobe'` be mounted
  /// simultaneously.
  ///
  /// Also the sole emission point for [GameEventType.modalVisibilityChanged]
  /// (Story 004, ADR-0017 Decision → TR-petroom-004) — since this method is
  /// already the only sanctioned way to open a modal (the forbidden-pattern
  /// rule above), emitting here covers every real modal open with no
  /// separate call-site discipline required, rather than the story's
  /// illustrative sample (which shows the emit as a step adjacent to the
  /// call site) risking a future caller forgetting it. `true` is emitted
  /// BEFORE mutating `overlays`, matching the story's own before/after
  /// ordering — `MochiComponent` should already know a modal is opening
  /// before any `GameEvent` arrives during it.
  void showModal(String overlayKey) {
    assert(overlayKey == 'context_menu' || overlayKey == 'wardrobe');
    GameEventBus().emit(GameEvent(GameEventType.modalVisibilityChanged, true));
    overlays.remove('context_menu');
    overlays.remove('wardrobe');
    overlays.add(overlayKey);
  }

  /// Dismisses whichever of the two modal overlay keys is currently mounted
  /// (a no-op for whichever one isn't). Also the sanctioned path — see
  /// [showModal].
  ///
  /// Emits [GameEventType.modalVisibilityChanged] (`false`) AFTER mutating
  /// `overlays` — matching the story's before/after ordering and
  /// [showModal]'s own reasoning above (the single sanctioned dismissal
  /// path, so this covers every real modal close with no separate call-site
  /// discipline).
  void dismissModal() {
    overlays.remove('context_menu');
    overlays.remove('wardrobe');
    GameEventBus().emit(GameEvent(GameEventType.modalVisibilityChanged, false));
  }

  @override
  void update(double dt) {
    super.update(dt);
    updateTickCount++;
  }
}
