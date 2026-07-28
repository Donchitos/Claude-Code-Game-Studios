// Run with:
//   cd src && flutter test ../tests/integration/pet-room-screen-ui/context_menu_wardrobe_test.dart
//
// Story 007 (Tap-on-Mochi Context Menu & Wardrobe Bottom Sheet), Pet Room
// Screen UI epic. Covers this story's own QA Test Cases, one test function
// (or a small group) per AC:
//   - AC-CR5-1/5-2/5-3: context menu's 3 options — "Vuốt ve" triggers
//     PLEASED and closes immediately; "Đóng" closes with no other action;
//     "Thay đồ" closes the menu and opens Wardrobe, never both mounted.
//   - AC-CR6-1/6-2: Wardrobe shows exactly 3 slot tabs, grid filters by the
//     selected slot; "Đóng" or a tap outside dismisses it.
//   - AC-EC6-1/6-2: itemCatalogProvider loading → shimmer; AsyncError →
//     inline error + working retry.
//
// This story does NOT wire up what gesture calls `showModal('context_menu')`
// in the first place (see `pet_room_context_menu.dart`'s own doc comment for
// why) — every test below opens a modal directly via `game.showModal(...)`,
// matching the story's own QA Test Cases' "GIVEN the context menu is open"
// preconditions.

import 'dart:async';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` (riverpod 3.x) lives in `misc.dart`, not the main barrel export
// — same import this project's own pending_list_approve_reject_test.dart
// already established.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/models/item_model.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/pet_room_game.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/item_catalog_provider.dart';
import 'package:pet_quest/ui/pet_room_context_menu.dart';
import 'package:pet_quest/ui/pet_room_screen.dart';
import 'package:pet_quest/ui/pet_room_wardrobe.dart';

/// Pumps [steps] small, fixed-size frames instead of `pumpAndSettle()` —
/// `PetRoomScreen`'s `GameWidget` keeps a `Ticker` perpetually scheduled
/// once mounted. Duplicated from `composition_and_modal_exclusivity_test.
/// dart` — private helpers can't be shared across test files (that file's
/// own header comment).
Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

/// Same `ProviderScope`/`firebaseAuthProvider` pattern as the sibling test
/// files (Story 006's `_pumpPetRoomScreen`), plus an optional
/// `itemCatalogProvider` override for the AC-CR6/AC-EC6 groups below.
Future<PetRoomGame> _pumpPetRoomScreen(
  WidgetTester tester, {
  Override? itemCatalogOverride,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
        if (itemCatalogOverride != null) itemCatalogOverride,
      ],
      child: const MaterialApp(home: PetRoomScreen()),
    ),
  );
  await _pumpSteps(tester, 6);
  return tester
      .widget<GameWidget<PetRoomGame>>(find.byType(GameWidget<PetRoomGame>))
      .game!;
}

const _bodyOutfitItem = ItemModel(
  itemId: 'outfit-1',
  name: 'Áo hoa',
  description: 'd',
  category: 'mochi_outfit',
  slot: 'body_outfit',
  price: 10,
  source: 'shop',
  assetId: 'a',
  sortOrder: 1,
);
const _hatItem = ItemModel(
  itemId: 'hat-1',
  name: 'Nón lá',
  description: 'd',
  category: 'mochi_outfit',
  slot: 'hat',
  price: 20,
  source: 'shop',
  assetId: 'a',
  sortOrder: 2,
);
const _accessoryItem = ItemModel(
  itemId: 'acc-1',
  name: 'Vòng cổ',
  description: 'd',
  category: 'mochi_outfit',
  slot: 'accessory',
  price: 30,
  source: 'gacha',
  assetId: 'a',
  sortOrder: 3,
);
// A room_decoration item (slot: null) — must never appear in any slot's
// grid, proving the filter genuinely reads `slot`, not just `category`.
const _decorationItem = ItemModel(
  itemId: 'deco-1',
  name: 'Thảm trải sàn',
  description: 'd',
  category: 'room_decoration',
  slot: null,
  price: 15,
  source: 'shop',
  assetId: 'a',
  sortOrder: 4,
);

void main() {
  // GameEventBus is a process-wide singleton with a per-type replay cache
  // (ADR-0004 §5) — same reset this epic's own composition_and_modal_
  // exclusivity_test.dart already established at file scope, needed here
  // too since several tests below snapshot/compare `peekLastEvent(
  // petInteracted)` before/after a tap.
  setUp(() => GameEventBus().resetForTesting());

  group('AC-CR5: context menu options', () {
    testWidgets(
        'test_vuotVe_triggersPleased_andClosesMenuImmediately',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);
      game.showModal('context_menu');
      await tester.pump();
      expect(game.overlays.activeOverlays.contains('context_menu'), isTrue);

      await tester.tap(find.byKey(PetRoomContextMenu.petButtonKey));
      await tester.pump();

      expect(
        game.mochi?.currentTriggeredState,
        TriggeredState.pleased,
        reason: 'AC-CR5-1: "Vuốt ve" must call the PLEASED trigger path',
      );
      expect(
        game.overlays.activeOverlays.contains('context_menu'),
        isFalse,
        reason: 'AC-CR5-1: the menu must close immediately, no delay',
      );
    });

    testWidgets(
        'test_dong_dismissesMenu_noOtherActionFires',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);
      game.showModal('context_menu');
      await tester.pump();
      final triggeredStateBefore = game.mochi?.currentTriggeredState;
      final petInteractedBefore =
          GameEventBus().peekLastEvent(GameEventType.petInteracted);

      await tester.tap(find.byKey(PetRoomContextMenu.closeButtonKey));
      await tester.pump();

      expect(game.overlays.activeOverlays.contains('context_menu'), isFalse);
      expect(game.overlays.activeOverlays.contains('wardrobe'), isFalse);
      expect(
        game.mochi?.currentTriggeredState,
        triggeredStateBefore,
        reason: 'AC-CR5-2: "Đóng" must not trigger PLEASED',
      );
      expect(
        identical(
          GameEventBus().peekLastEvent(GameEventType.petInteracted),
          petInteractedBefore,
        ),
        isTrue,
        reason: 'AC-CR5-2: "Đóng" must not emit a petInteracted event',
      );
    });

    testWidgets(
        'test_thayDo_closesMenuAndOpensWardrobe_neverBothMounted',
        (tester) async {
      final game = await _pumpPetRoomScreen(tester);
      game.showModal('context_menu');
      await tester.pump();

      await tester.tap(find.byKey(PetRoomContextMenu.changeOutfitButtonKey));
      await tester.pump();

      expect(
        game.overlays.activeOverlays.contains('context_menu'),
        isFalse,
        reason: 'AC-CR5-3: the menu must close',
      );
      expect(
        game.overlays.activeOverlays.contains('wardrobe'),
        isTrue,
        reason: 'AC-CR5-3: Wardrobe must open',
      );
      // showModal('wardrobe') itself removes 'context_menu' before adding
      // 'wardrobe' in the same synchronous call — no intermediate state
      // with both, or neither, keys active exists to observe.
    });
  });

  group('AC-CR6: Wardrobe slot tabs & item grid', () {
    Override catalogWith(List<ItemModel> items) =>
        itemCatalogProvider.overrideWith((ref) async => items);

    testWidgets(
        'test_wardrobeOpen_exactly3SlotTabs_gridShowsOnlySelectedSlotItems',
        (tester) async {
      final game = await _pumpPetRoomScreen(
        tester,
        itemCatalogOverride: catalogWith(
          const [_bodyOutfitItem, _hatItem, _accessoryItem, _decorationItem],
        ),
      );
      game.showModal('wardrobe');
      await _pumpSteps(tester, 6);

      expect(find.byKey(PetRoomWardrobe.slotTabKey('body_outfit')), findsOneWidget);
      expect(find.byKey(PetRoomWardrobe.slotTabKey('hat')), findsOneWidget);
      expect(find.byKey(PetRoomWardrobe.slotTabKey('accessory')), findsOneWidget);

      // Default-selected tab is body_outfit (first in display order).
      expect(find.text(_bodyOutfitItem.name), findsOneWidget);
      expect(find.text(_hatItem.name), findsNothing);
      expect(find.text(_accessoryItem.name), findsNothing);
      expect(
        find.text(_decorationItem.name),
        findsNothing,
        reason: 'a null-slot item must never appear in any slot tab\'s grid',
      );

      await tester.tap(find.byKey(PetRoomWardrobe.slotTabKey('hat')));
      await _pumpSteps(tester, 6);

      expect(find.text(_bodyOutfitItem.name), findsNothing);
      expect(find.text(_hatItem.name), findsOneWidget);
      expect(find.text(_accessoryItem.name), findsNothing);

      // qa-tester code review: the hat-tab check above alone leaves the
      // 3rd slot's own filter unproven — a slot/tab string typo isolated to
      // 'accessory' would go undetected without this.
      await tester.tap(find.byKey(PetRoomWardrobe.slotTabKey('accessory')));
      await _pumpSteps(tester, 6);

      expect(find.text(_bodyOutfitItem.name), findsNothing);
      expect(find.text(_hatItem.name), findsNothing);
      expect(find.text(_accessoryItem.name), findsOneWidget);
    });

    testWidgets(
        'test_dong_dismissesWardrobe',
        (tester) async {
      final game = await _pumpPetRoomScreen(
        tester,
        itemCatalogOverride: catalogWith(const [_bodyOutfitItem]),
      );
      game.showModal('wardrobe');
      await _pumpSteps(tester, 6);

      await tester.tap(find.byKey(PetRoomWardrobe.closeButtonKey));
      await tester.pump();

      expect(game.overlays.activeOverlays.contains('wardrobe'), isFalse);
    });

    testWidgets(
        'test_tapOutsideSheet_dismissesWardrobe',
        (tester) async {
      final game = await _pumpPetRoomScreen(
        tester,
        itemCatalogOverride: catalogWith(const [_bodyOutfitItem]),
      );
      game.showModal('wardrobe');
      await _pumpSteps(tester, 6);

      // Sheet is capped at ~62% of screen height, bottom-anchored — a tap
      // near the GameWidget's top-left corner lands above the sheet, on
      // the scrim, same "computed, not hardcoded" approach as
      // composition_and_modal_exclusivity_test.dart's own AC-EC3 test.
      final gameWidgetTopLeft = tester.getTopLeft(find.byType(GameWidget<PetRoomGame>));
      await tester.tapAt(gameWidgetTopLeft + const Offset(10, 10));
      await tester.pump();

      expect(game.overlays.activeOverlays.contains('wardrobe'), isFalse);
    });

    // qa-tester code review: the Wardrobe sheet uses the identical
    // scrim-behind-opaque-body construct as the context menu, and this
    // exact fall-through failure mode is a previously-real, live-tested
    // bug in this codebase for that construct (composition_and_modal_
    // exclusivity_test.dart's own header comment) — the "outside dismisses"
    // test above doesn't cover the other direction.
    testWidgets(
        'test_tapOnSheetBody_doesNotFallThroughToScrim',
        (tester) async {
      final game = await _pumpPetRoomScreen(
        tester,
        itemCatalogOverride: catalogWith(const [_bodyOutfitItem]),
      );
      game.showModal('wardrobe');
      await _pumpSteps(tester, 6);

      await tester.tap(find.text('Tủ đồ'));
      await tester.pump();

      expect(
        game.overlays.activeOverlays.contains('wardrobe'),
        isTrue,
        reason: 'tapping the sheet\'s own body (its header) must not dismiss it',
      );
    });
  });

  group('AC-EC6: itemCatalogProvider loading/error states', () {
    testWidgets(
        'test_wardrobeOpen_catalogLoading_showsShimmer_noCrash',
        (tester) async {
      final game = await _pumpPetRoomScreen(
        tester,
        // Never completes within this test's bounded pump budget — proves
        // the loading state, not the eventual data state.
        itemCatalogOverride: itemCatalogProvider.overrideWith(
          (ref) => Completer<List<ItemModel>>().future,
        ),
      );
      game.showModal('wardrobe');
      await _pumpSteps(tester, 4);

      expect(find.byKey(PetRoomWardrobe.shimmerKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'test_wardrobeOpen_catalogError_showsErrorAndRetry_retryReinvokesProvider_noCrash',
        (tester) async {
      var buildCount = 0;
      final game = await _pumpPetRoomScreen(
        tester,
        itemCatalogOverride: itemCatalogProvider.overrideWith((ref) async {
          buildCount++;
          throw Exception('simulated catalog failure');
        }),
      );
      game.showModal('wardrobe');
      await _pumpSteps(tester, 6);

      expect(find.byKey(PetRoomWardrobe.errorKey), findsOneWidget);
      expect(find.byKey(PetRoomWardrobe.retryButtonKey), findsOneWidget);
      final buildCountAfterOpen = buildCount;

      await tester.tap(find.byKey(PetRoomWardrobe.retryButtonKey));
      await _pumpSteps(tester, 6);

      expect(
        buildCount,
        greaterThan(buildCountAfterOpen),
        reason: 'AC-EC6-2: retry must re-invoke itemCatalogProvider',
      );
      expect(
        game.overlays.activeOverlays.contains('wardrobe'),
        isTrue,
        reason: 'retry must not close the sheet',
      );
      expect(find.byKey(PetRoomWardrobe.errorKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
