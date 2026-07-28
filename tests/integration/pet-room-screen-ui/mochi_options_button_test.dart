// Run with:
//   cd src && flutter test ../tests/integration/pet-room-screen-ui/mochi_options_button_test.dart
//
// ADR-0018 (Mochi Options Button as the Context Menu Trigger). Resolves a
// real gap found during Pet Room Screen UI Story 007's code review:
// `game.showModal('context_menu')` had no production caller. This file
// covers ADR-0018's own Validation Criteria:
//   - tapping MochiOptionsButton opens the context menu (the button IS
//     now the sanctioned trigger).
//   - tapping Mochi's own sprite still triggers PLEASED, completely
//     unaffected by this change (ADR-0016's tap=PLEASED semantics are
//     explicitly NOT modified by ADR-0018 — this is the regression guard
//     proving that).
//
// Reuses the same full-router `_pumpPetRoomScreen`/fake-Firestore setup
// pattern established across this epic's other test files (private
// helpers can't be shared across files, per those files' own header
// comments).

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/pet_room_game.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/ui/mochi_options_button.dart';
import 'package:pet_quest/ui/pet_room_screen.dart';
import 'package:pet_quest/ui/pet_room_status_row.dart';

Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

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

void main() {
  // GameEventBus is a process-wide singleton with a per-type replay cache
  // (ADR-0004 §5) — without this reset, test_tapMochiOptionsButton_
  // opensContextMenu's showModal('context_menu') call caches a
  // modalVisibilityChanged=true event that a later test's freshly-mounted
  // MochiComponent would incorrectly replay on subscribe, gating its
  // PLEASED trigger into _pendingVisual instead of applying it (found via
  // this exact failure while writing this file — same class of bug this
  // epic's other test files already established this reset to prevent).
  setUp(() => GameEventBus().resetForTesting());

  testWidgets(
      'test_tapMochiOptionsButton_opensContextMenu',
      (tester) async {
      final game = await _pumpPetRoomScreen(tester);
      expect(game.overlays.activeOverlays.contains('context_menu'), isFalse);
      expect(find.byKey(MochiOptionsButton.buttonKey), findsOneWidget);

      await tester.tap(find.byKey(MochiOptionsButton.buttonKey));
      await tester.pump();

      expect(
        game.overlays.activeOverlays.contains('context_menu'),
        isTrue,
        reason: 'ADR-0018: MochiOptionsButton must be a real, working '
            "trigger for showModal('context_menu')",
      );
    });

  testWidgets('test_mochiOptionsButton_meetsMinimumTouchTarget', (tester) async {
    await _pumpPetRoomScreen(tester);

    final size = tester.getSize(find.byKey(MochiOptionsButton.buttonKey));
    expect(size.width, greaterThanOrEqualTo(48.0));
    expect(size.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets(
      'test_tapOnMochiSprite_stillTriggersPleased_unaffectedByADR0018',
      (tester) async {
    final game = await _pumpPetRoomScreen(tester);
    final mochi = game.mochi!;
    expect(mochi.currentTriggeredState, isNull);

    // ADR-0018's own regression guard: a tap on Mochi's actual sprite —
    // away from MochiOptionsButton's own bottom-right-corner position, so
    // this genuinely exercises Mochi's DragCallbacks-based tap handling
    // (ADR-0016), not the button sitting on top of it — must still trigger
    // PLEASED exactly as before this ADR. Same "compute from GameWidget's
    // top-left, don't hardcode" approach as this epic's other tests
    // (composition_and_modal_exclusivity_test.dart's AC-EC3).
    final gameWidgetTopLeft = tester.getTopLeft(find.byType(GameWidget<PetRoomGame>));
    await tester.tapAt(gameWidgetTopLeft + const Offset(10, 10));
    await tester.pump();

    expect(
      mochi.currentTriggeredState,
      TriggeredState.pleased,
      reason: 'ADR-0018 must not touch Mochi\'s own tap/swipe handling — '
          'tap-on-Mochi still triggers PLEASED exactly as ADR-0016 '
          'specifies, unchanged',
    );
    expect(game.overlays.activeOverlays.contains('context_menu'), isFalse);
  });

  testWidgets(
      'test_tapMochiOptionsButton_duringLevelingUp_doesNotOpenMenu_worksAgainAfter',
      (tester) async {
    // GDD Edge Case 5's intent, carried over from tap-on-Mochi to this
    // button by ADR-0018: the context menu must not open over Mochi's
    // non-interruptible LEVELING_UP celebration.
    final game = await _pumpPetRoomScreen(tester);
    final mochi = game.mochi!;
    mochi.onTrigger(TriggeredState.levelingUp);
    await tester.pump();
    expect(mochi.currentTriggeredState, TriggeredState.levelingUp);

    await tester.tap(find.byKey(MochiOptionsButton.buttonKey));
    await tester.pump();

    expect(
      game.overlays.activeOverlays.contains('context_menu'),
      isFalse,
      reason: 'the button must ignore taps while LEVELING_UP is playing',
    );

    // LEVELING_UP duration is 3.0s (triggered_state.dart) — pump past it.
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 200));
    expect(mochi.currentTriggeredState, isNull);

    await tester.tap(find.byKey(MochiOptionsButton.buttonKey));
    await tester.pump();

    expect(
      game.overlays.activeOverlays.contains('context_menu'),
      isTrue,
      reason: 'the button must work normally again once LEVELING_UP ends',
    );
  });

  testWidgets(
      'test_mochiOptionsButton_doesNotOverlapPetRoomStatusRow',
      (tester) async {
    await _pumpPetRoomScreen(tester);

    final buttonRect = tester.getRect(find.byKey(MochiOptionsButton.buttonKey));
    final rowRect = tester.getRect(find.byKey(PetRoomStatusRow.rowKey));

    expect(
      buttonRect.overlaps(rowRect),
      isFalse,
      reason: 'MochiOptionsButton and the status row are both anchored '
          "near the screen's top edge given Mochi's current unpositioned "
          '(0,0) default — flame-widget-specialist code review flagged '
          'this as a real, currently-unverified collision risk',
    );
  });

  testWidgets(
      'test_mochiOptionsButton_notHitTestable_whileWardrobeOpen',
      (tester) async {
    // qa-tester code review asked about "tap the button while a modal is
    // already open." Answer, found empirically while writing the intended
    // test: it's not a reachable scenario in the real UI at all, not just
    // one `showModal` already handles generically — 'chrome' (Story
    // 003/006) renders BEHIND any open modal, so Wardrobe's own full-
    // screen scrim physically intercepts the tap before it can reach the
    // button underneath. Confirmed empirically while writing this test:
    // the tap does NOT open context_menu (button's onTap never fires) —
    // instead it lands on the scrim and DISMISSES Wardrobe (the scrim's
    // own `onTap: dismissModal`), exactly as any other tap on empty
    // Wardrobe-scrim space would. This test documents that real, verified
    // outcome directly instead of a since-removed test that incorrectly
    // assumed the button stays independently tappable while a modal is
    // open.
    final game = await _pumpPetRoomScreen(tester);
    game.showModal('wardrobe');
    await tester.pump();

    // warnIfMissed: false — this tap is expected to land on Wardrobe's
    // scrim, not the button, which is the entire point being verified.
    await tester.tap(find.byKey(MochiOptionsButton.buttonKey), warnIfMissed: false);
    await tester.pump();

    expect(
      game.overlays.activeOverlays.contains('context_menu'),
      isFalse,
      reason: "the button's onTap must not have fired",
    );
    expect(
      game.overlays.activeOverlays.contains('wardrobe'),
      isFalse,
      reason: 'the tap lands on Wardrobe\'s own scrim instead, which '
          'dismisses it — the same outcome any tap on empty scrim space '
          'produces',
    );
  });
}
