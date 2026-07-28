import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../gameplay/pet_room_game.dart';
import 'mochi_options_button.dart';
import 'pet_room_context_menu.dart';
import 'pet_room_status_row.dart';
import 'pet_room_wardrobe.dart';

/// Stable, story-owned [Key]s for the three overlay widgets —
/// exposed so `tests/integration/pet-room-screen-ui/
/// composition_and_modal_exclusivity_test.dart` can assert on which overlay
/// widget is (or isn't) present without depending on this file's private
/// widget class names.
@visibleForTesting
const kPetRoomChromeOverlayKey = Key('petRoomChromeOverlay');
@visibleForTesting
const kPetRoomContextMenuOverlayKey = Key('petRoomContextMenuOverlay');
@visibleForTesting
const kPetRoomWardrobeOverlayKey = Key('petRoomWardrobeOverlay');

/// Child Shell's Pet Room tab (main-navigation-shell Story 002, ADR-0014
/// Decision §2 — original placeholder; Pet Room Screen UI Story 003,
/// ADR-0017 Decision → TR-petroom-001 — real overlay composition). Hosts a
/// real [PetRoomGame] via [GameWidget] — not just a `Scaffold`+`Text`
/// placeholder — because AC-5 requires proving the SAME `FlameGame`/
/// `GameLoop` instance survives being switched offstage (Tasks/Shop
/// branches active) and back, with its `update(dt)` loop still incrementing
/// while offstage. A bare Scaffold placeholder cannot prove or disprove
/// that mechanism (Implementation Note 5).
///
/// [overlayBuilderMap] wires the three overlay keys ADR-0017's component
/// tree diagram specifies: `'chrome'` (added once, from inside
/// [PetRoomGame.onLoad] itself — see that method's doc comment for why —
/// never removed; real content since Story 006, [PetRoomStatusRow] — and,
/// since ADR-0018, also [MochiOptionsButton], the sole trigger for opening
/// the context menu, mounted alongside — not inside — the status row),
/// `'context_menu'` and `'wardrobe'` (modal, mutually exclusive via
/// [PetRoomGame.showModal]/[PetRoomGame.dismissModal] — never added/removed
/// directly from here; real content since Story 007, [PetRoomContextMenu]/
/// [PetRoomWardrobe]).
///
/// [_game] is a `State` field, constructed exactly once and never replaced
/// across rebuilds — [GameWidget]'s `game` argument therefore never changes
/// identity for as long as this branch's widget subtree stays mounted, which
/// `StatefulShellRoute.indexedStack` guarantees it does across sibling-branch
/// switches (Implementation Note 4: no `ValueKey` tied to branch index, no
/// `AutomaticKeepAliveClientMixin` workaround — `IndexedStack` already
/// handles preservation, adding either would risk silently breaking AC-5).
///
/// Retains a visible `Text('Pet Room')` marker (the `AppBar` title) so two
/// pre-existing test files
/// (`tests/integration/main-navigation-shell/root_redirect_test.dart`,
/// `tests/integration/auth_account/router_redirect_test.dart`) that assert
/// `find.text('Pet Room')` to confirm the router reached this route keep
/// passing. Both files DID need a small unrelated fix in this same
/// changeset (`pumpAndSettle()` → a bounded-step helper, since this
/// screen's `GameWidget` now keeps a `Ticker` perpetually scheduled — see
/// their own doc comments) — this marker only avoids also having to touch
/// their assertions.
class PetRoomScreen extends StatefulWidget {
  const PetRoomScreen({super.key});

  @override
  State<PetRoomScreen> createState() => _PetRoomScreenState();
}

class _PetRoomScreenState extends State<PetRoomScreen> {
  final PetRoomGame _game = PetRoomGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pet Room')),
      body: GameWidget<PetRoomGame>(
        game: _game,
        overlayBuilderMap: {
          'chrome': (context, game) => Stack(
            key: kPetRoomChromeOverlayKey,
            children: [
              const PetRoomStatusRow(),
              MochiOptionsButton(game: game),
            ],
          ),
          'context_menu': (context, game) => PetRoomContextMenu(
            key: kPetRoomContextMenuOverlayKey,
            game: game,
          ),
          'wardrobe': (context, game) => PetRoomWardrobe(
            key: kPetRoomWardrobeOverlayKey,
            game: game,
          ),
        },
      ),
    );
  }
}

