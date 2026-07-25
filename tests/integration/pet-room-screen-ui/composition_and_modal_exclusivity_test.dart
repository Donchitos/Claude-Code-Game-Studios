// Run with:
//   cd src && flutter test ../tests/integration/pet-room-screen-ui/composition_and_modal_exclusivity_test.dart
//
// Story 003 (Flame Canvas Composition, Z-Order & Modal Mutual Exclusivity),
// Pet Room Screen UI epic. ADR-0017 Decision → TR-petroom-001. Covers this
// story's own 5 QA Test Cases, one test function per AC:
//   - AC-CR1-1: 0-modal composition — exactly `RoomBackgroundComponent`
//     (priority 0) + `MochiComponent` (priority 1) as direct `World`
//     children, `'chrome'` overlay present, neither modal key active.
//   - AC-CR1-2: `showModal('context_menu')` then `showModal('wardrobe')`
//     never leaves both modal keys active simultaneously; the just-opened
//     modal's overlay widget is the one actually present in the tree.
//   - AC-CR2: Main Navigation Shell's default tab lands on `/child/pet-room`
//     with exactly one `GameWidget<PetRoomGame>`, `MochiComponent` +
//     `RoomBackgroundComponent` both present in `game.world.children` once
//     `onLoad()` resolves.
//   - AC-CR3: static/regression source scan — `pet_room_screen.dart` and
//     `pet_room_game.dart` never call an `.init()`/`.reset()`-shaped method
//     on `GameEventBus`.
//   - AC-EC3: context menu open, tap outside (including where Mochi is
//     rendered) dismisses it via `dismissModal()`, with no other action
//     (Mochi's own drag-classified interaction) firing from that same tap.
//
// API correction note: the story text/ADR-0017's own QA Test Case wording
// says `game.overlays.value` — the actually-installed `flame-1.37.0`
// `OverlayManager` (source-verified, `lib/src/game/overlay_manager.dart`)
// has no `value` getter; the real API is `activeOverlays`
// (`UnmodifiableListView<String>`) and `isActive(String)`. This file uses
// the real API — the same kind of faithful-to-the-real-API correction
// `MochiComponent`'s own doc comments already made for `Vector2` vs.
// `Offset` (Pet Interaction Story 001).

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';
import 'package:pet_quest/gameplay/pet_room_game.dart';
import 'package:pet_quest/gameplay/room_background_component.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/pet_room_screen.dart';

/// Pumps [steps] small, fixed-size frames instead of `pumpAndSettle()` —
/// `PetRoomScreen`'s `GameWidget` keeps a `Ticker` perpetually scheduled
/// once mounted (ADR-0014 Decision §2), which makes `pumpAndSettle()` loop
/// until it hits its internal iteration cap and throws. Same pattern as
/// `tests/integration/main-navigation-shell/child_shell_test.dart`'s
/// `_pumpSteps` helper (duplicated — private helpers can't be shared across
/// test files).
Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

/// Pumps a bare `PetRoomScreen` far enough for `PetRoomGame.onLoad()` to
/// have resolved, and returns the live [PetRoomGame] instance.
///
/// Wrapped in a `ProviderScope` with `firebaseAuthProvider` overridden to a
/// `MockFirebaseAuth()` (no signed-in user) — required since Pet Room
/// Screen UI Story 006 wired real chrome content
/// ([PetRoomStatusRow]) into the always-mounted `'chrome'` overlay, which
/// reads `petMoodProvider`/`petEnergyProvider` → ... → `authStateProvider`
/// → `firebaseAuthProvider` (defaults to `FirebaseAuth.instance`, which
/// throws `[core/no-app]` with no real Firebase app — confirmed via a real
/// failed test run during Story 006's implementation, not assumed). No
/// `firebaseFirestoreProvider` override is needed: with no signed-in user,
/// `activeChildProvider` stays `null`, so the energy doc stream short-
/// circuits to `Stream.value(null)` before ever touching Firestore
/// (`time_decay_providers.dart`'s own null-guard).
Future<PetRoomGame> _pumpPetRoomScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [firebaseAuthProvider.overrideWithValue(MockFirebaseAuth())],
      child: const MaterialApp(home: PetRoomScreen()),
    ),
  );
  await _pumpSteps(tester, 6);
  return tester
      .widget<GameWidget<PetRoomGame>>(find.byType(GameWidget<PetRoomGame>))
      .game!;
}

// ---------------------------------------------------------------------
// AC-CR2 fixtures — duplicated from `child_shell_test.dart` verbatim
// (that file's own header comment: "private classes can't be shared across
// test files"). Only AC-CR2 needs the full router/auth flow; the other 4
// ACs use the lighter-weight `_pumpPetRoomScreen` helper above.
// ---------------------------------------------------------------------

class _EmptyQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async =>
      _EmptyQuerySnapshot();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  Map<String, dynamic>? data() => null;

  @override
  bool get exists => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      Stream.value(_FakeDocumentSnapshot());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollectionReference();

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) => _FakeDocumentReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _reachChildPetRoom(WidgetTester tester) async {
  final mockAuth = MockFirebaseAuth();
  final container = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(mockAuth),
      firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
    ],
  );
  addTearDown(container.dispose);

  final routerSubscription = container.listen(routerProvider, (_, _) {});
  addTearDown(routerSubscription.close);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: routerSubscription.read()),
    ),
  );
  await tester.pumpAndSettle();

  await mockAuth.signInWithEmailAndPassword(
    email: 'parent@example.com',
    password: 'irrelevant-for-this-test',
  );
  await tester.pumpAndSettle();

  container.read(activeChildProvider.notifier).state = const ChildProfile(
    childId: 'child-1',
    name: 'Bé An',
    avatarId: 'avatar-1',
    mochiName: 'Mochi',
  );
  await _pumpSteps(tester, 6);

  return container;
}

void main() {
  setUp(() => GameEventBus().resetForTesting());

  group('AC-CR1-1: 0-modal composition', () {
    testWidgets(
        'test_zeroModals_exactlyBackgroundAndMochiMounted_priorityOrdered_chromeOn_noModalActive',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);

      expect(find.byType(GameWidget<PetRoomGame>), findsOneWidget);

      final backgrounds = game.world.children.whereType<RoomBackgroundComponent>();
      final mochis = game.world.children.whereType<MochiComponent>();
      expect(backgrounds.length, 1, reason: 'exactly one RoomBackgroundComponent');
      expect(mochis.length, 1, reason: 'exactly one MochiComponent');
      expect(
        backgrounds.single.priority,
        lessThan(mochis.single.priority),
        reason: 'background must paint behind Mochi (ADR-0017 priority contract)',
      );
      expect(backgrounds.single.priority, 0);
      expect(mochis.single.priority, 1);

      expect(
        game.overlays.activeOverlays.contains('context_menu'),
        isFalse,
        reason: 'no modal should be mounted with 0 modals open',
      );
      expect(game.overlays.activeOverlays.contains('wardrobe'), isFalse);
      expect(
        game.overlays.activeOverlays.contains('chrome'),
        isTrue,
        reason: "'chrome' is always-on, added once after onLoad() resolves",
      );
      expect(find.byKey(kPetRoomChromeOverlayKey), findsOneWidget);
      expect(find.byKey(kPetRoomContextMenuOverlayKey), findsNothing);
      expect(find.byKey(kPetRoomWardrobeOverlayKey), findsNothing);
    });
  });

  group('AC-CR1-2: modal mutual exclusivity', () {
    testWidgets(
        'test_showModal_contextMenu_thenWardrobe_neverBothActive_justOpenedIsThePresentWidget',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);

      game.showModal('context_menu');
      await tester.pump();

      expect(game.overlays.activeOverlays.contains('context_menu'), isTrue);
      expect(game.overlays.activeOverlays.contains('wardrobe'), isFalse);
      expect(find.byKey(kPetRoomContextMenuOverlayKey), findsOneWidget);
      expect(find.byKey(kPetRoomWardrobeOverlayKey), findsNothing);

      game.showModal('wardrobe');
      await tester.pump();

      expect(
        game.overlays.activeOverlays.contains('context_menu'),
        isFalse,
        reason: 'showModal must remove the previously-open modal key first',
      );
      expect(game.overlays.activeOverlays.contains('wardrobe'), isTrue);
      expect(
        find.byKey(kPetRoomContextMenuOverlayKey),
        findsNothing,
        reason: 'the previous modal widget must no longer be in the tree',
      );
      expect(
        find.byKey(kPetRoomWardrobeOverlayKey),
        findsOneWidget,
        reason: "the just-opened modal ('wardrobe') is the one actually present",
      );

      // Never both active at any point this test observed.
      expect(
        game.overlays.activeOverlays.contains('context_menu') &&
            game.overlays.activeOverlays.contains('wardrobe'),
        isFalse,
      );
    });
  });

  group('AC-CR2: Main Navigation Shell default tab reaches /child/pet-room', () {
    testWidgets(
        'test_freshAppStart_defaultTabIsChildPetRoom_oneGameWidget_mochiAndBackgroundMounted',
        (tester) async {
      final container = await _reachChildPetRoom(tester);
      final router = container.read(routerProvider);

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.childPetRoom,
      );
      expect(find.byType(GameWidget<PetRoomGame>), findsOneWidget);

      final game = tester
          .widget<GameWidget<PetRoomGame>>(find.byType(GameWidget<PetRoomGame>))
          .game!;
      // onLoad() has already had several frames to resolve via
      // _reachChildPetRoom's own _pumpSteps(6) — settle a few more to be
      // safe against the fire-and-forget interim-sprite future (Story 003's
      // own gotcha note in pet_room_game.dart) without ever calling
      // pumpAndSettle() (unsafe once the Ticker is running — see this
      // file's _pumpSteps doc).
      await _pumpSteps(tester, 3);

      expect(game.world.children.whereType<MochiComponent>().length, 1);
      expect(game.world.children.whereType<RoomBackgroundComponent>().length, 1);
    });
  });

  group('AC-CR3: no GameEventBus init/reset-shaped call at the screen layer', () {
    test(
        'test_petRoomScreen_and_petRoomGame_source_never_call_GameEventBus_init_or_reset',
        () {
      final screenSource =
          File('lib/ui/pet_room_screen.dart').readAsStringSync();
      final gameSource =
          File('lib/gameplay/pet_room_game.dart').readAsStringSync();

      for (final source in [screenSource, gameSource]) {
        expect(
          source.contains('GameEventBus().init(') ||
              source.contains('GameEventBus().reset(') ||
              source.contains('GameEventBus().resetForTesting('),
          isFalse,
          reason: 'only GameEventBus() (factory) + .stream.listen(...) are '
              'sanctioned at this layer — no init/reset-shaped call is '
              'allowed (AC-CR3 regression check)',
        );
      }
    });
  });

  group('Camera anchor & background resize regression (post-close live-testing fix)', () {
    // A real user live-tested the running app after Story 003 closed and
    // found two visible rendering bugs neither AC-CR1-1 nor AC-CR2 above
    // caught, because neither asserted on-screen geometry through a real
    // `CameraComponent`/canvas resize — only tree membership, `priority`
    // ordering, and overlay-key presence. Per `test-standards.md`'s "every
    // bug fix must have a regression test that would have caught the
    // original bug" rule (qa-tester code-review finding, this fix), this
    // group closes that gap.
    testWidgets(
        'test_onLoad_setsViewfinderAnchorToTopLeft_notTheFlameDefaultCenter',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);

      // Bug 1: Flame 1.37's `Viewfinder.anchor` defaults to `Anchor.center`
      // (`viewfinder.dart:81`) — world (0,0) would map to the viewport's
      // CENTER, not its top-left corner, painting both
      // `RoomBackgroundComponent` and `MochiComponent` (both positioned at
      // `Vector2.zero()` with their own `Anchor.topLeft`) starting from
      // screen-center instead of filling from the actual top-left. This is
      // the direct regression check for the fix's literal added line.
      expect(
        game.camera.viewfinder.anchor,
        Anchor.topLeft,
        reason: 'world (0,0) must map to the viewport top-left corner, not '
            "Flame's Anchor.center default, or Mochi/background paint from "
            'screen-center instead of filling the canvas',
      );
    });

    testWidgets(
        'test_roomBackground_fillsTheActualGameCanvasSize_notAFixedOrShrunkSize',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);
      final background =
          game.world.children.whereType<RoomBackgroundComponent>().single;

      // Bug 2: an earlier version left `SpriteComponent.autoResize` at its
      // implicit default (`true`, since no explicit `size` was passed) —
      // assigning the 1x1px placeholder fill sprite in `onLoad()` then
      // auto-shrunk `size` down to `Vector2(1, 1)`, silently undoing
      // whatever `onGameResize` had set. An even earlier version used a
      // hardcoded `Vector2(400, 800)` constant instead. Asserting equality
      // against the game's OWN reported size (not a literal constant)
      // catches both failure modes without hardcoding a viewport size this
      // test doesn't control.
      expect(
        background.size,
        game.size,
        reason: 'the background must fill whatever the real canvas size is '
            '— not shrink to the placeholder sprite\'s native 1x1px size, '
            'and not a stale hardcoded constant',
      );
      expect(background.size.x, greaterThan(1), reason: 'sanity: not shrunk to the 1x1px sprite');
      expect(background.size.y, greaterThan(1));

      // Confirms the `onGameResize` override — not just a one-time correct
      // value at initial mount — actually re-syncs `size` on a LATER
      // resize (e.g. device rotation), which the "hardcoded hit a
      // fixed-size regression" failure mode would not survive either.
      final resized = game.size.clone()
        ..x += 137
        ..y += 61;
      game.onGameResize(resized);
      expect(background.size, resized);
    });
  });

  group('AC-EC3: tap outside the open context menu dismisses it, no other action fires', () {
    testWidgets(
        'test_contextMenuOpen_tapOutsideIncludingOnMochi_dismisses_noMochiInteractionFires',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);
      game.showModal('context_menu');
      await tester.pump();
      expect(game.overlays.activeOverlays.contains('context_menu'), isTrue);

      final mochiLastTapBefore = game.mochi?.lastTapAt;
      final petInteractedBefore =
          GameEventBus().peekLastEvent(GameEventType.petInteracted);

      // Tap near the GameWidget's top-left corner — computed dynamically
      // (not a hardcoded screen coordinate) so this test doesn't depend on
      // the exact AppBar height/window size: guaranteed inside the
      // GameWidget's own bounds and far from the centered 160x120
      // placeholder menu box. Mochi is mounted at `Vector2.zero()`
      // (unpositioned default) — with `camera.viewfinder.anchor` now set to
      // `Anchor.topLeft` in `onLoad()` (a post-close live-testing fix; see
      // the "Camera anchor & background resize regression" group below),
      // world (0,0) genuinely maps to the canvas's visible top-left corner,
      // so this tap does land on/near Mochi's actual on-canvas position,
      // "including on Mochi" per the QA Test Case wording.
      final gameWidgetTopLeft = tester.getTopLeft(
        find.byType(GameWidget<PetRoomGame>),
      );
      await tester.tapAt(gameWidgetTopLeft + const Offset(10, 10));
      await tester.pump();

      expect(
        game.overlays.activeOverlays.contains('context_menu'),
        isFalse,
        reason: 'a tap outside the menu must dismiss it',
      );
      expect(find.byKey(kPetRoomContextMenuOverlayKey), findsNothing);

      // No other action fired from that same tap: Mochi's own
      // drag-classified interaction never ran (the full-screen scrim
      // consumed the gesture at the Flutter layer, so Flame's
      // DragCallbacks physically could not receive it), and no new
      // `petInteracted` event was emitted.
      expect(
        game.mochi?.lastTapAt,
        mochiLastTapBefore,
        reason: "Mochi's own tap handling must not have fired from this tap",
      );
      expect(
        identical(
          GameEventBus().peekLastEvent(GameEventType.petInteracted),
          petInteractedBefore,
        ),
        isTrue,
        reason: 'no petInteracted event should have been emitted by this tap',
      );
    });

    testWidgets(
        'test_contextMenuOpen_tapOnTheMenuItself_doesNotDismiss',
        (tester) async {
      // Not literally required by AC-EC3's own wording (which only tests
      // "outside"), but the scrim-behind-menu-box mechanism this story
      // implements to satisfy AC-EC3 would be trivially wrong the other
      // direction too if a tap ON the menu also dismissed it — cheap extra
      // confidence check for the same mechanism.
      final game = await _pumpPetRoomScreen(tester);
      game.showModal('context_menu');
      await tester.pump();

      await tester.tap(find.byKey(kPetRoomContextMenuOverlayKey));
      await tester.pump();

      expect(
        game.overlays.activeOverlays.contains('context_menu'),
        isTrue,
        reason: 'tapping the menu itself (its center, where the placeholder '
            'box is) must not dismiss it',
      );
    });
  });
}
