import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../gameplay/pet_room_game.dart';
import 'pet_room_status_row.dart';

/// Stable, story-owned [Key]s for the three overlay placeholder widgets —
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
/// never removed; real content since Story 006, [PetRoomStatusRow]),
/// `'context_menu'` and `'wardrobe'` (modal, mutually exclusive via
/// [PetRoomGame.showModal]/[PetRoomGame.dismissModal] — never added/removed
/// directly from here; still minimal placeholders, real content is Story
/// 007's scope).
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
          'chrome': (context, game) =>
              const PetRoomStatusRow(key: kPetRoomChromeOverlayKey),
          'context_menu': (context, game) => _ContextMenuPlaceholder(
            key: kPetRoomContextMenuOverlayKey,
            game: game,
          ),
          'wardrobe': (context, game) =>
              const _WardrobePlaceholder(key: kPetRoomWardrobeOverlayKey),
        },
      ),
    );
  }
}

/// Minimal `'wardrobe'` overlay placeholder (the real 3-slot Wardrobe sheet
/// is Story 007's scope).
class _WardrobePlaceholder extends StatelessWidget {
  const _WardrobePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Minimal `'context_menu'` overlay placeholder (the real 3-option menu is
/// Story 007's scope) — but AC-EC3 ("tap outside the menu dismisses it, no
/// other action fires from that same tap") IS this story's own acceptance
/// criterion, so the dismiss-on-outside-tap mechanism must be real even
/// though the menu's visual content isn't. Standard Flutter pattern: a
/// full-screen, transparent `GestureDetector` scrim sits BEHIND a small
/// placeholder "menu" box in a `Stack` — the scrim intercepts every tap that
/// lands outside the menu's own bounds and calls
/// [PetRoomGame.dismissModal], while a tap that lands ON the menu box never
/// reaches the scrim (the menu box is opaque to hit-testing and sits above
/// the scrim in paint/hit-test order), so it does not dismiss itself.
class _ContextMenuPlaceholder extends StatelessWidget {
  const _ContextMenuPlaceholder({super.key, required this.game});

  final PetRoomGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: game.dismissModal,
          ),
        ),
        Center(
          // Wrapped in its own opaque GestureDetector (no-op onTap) so a
          // tap landing ON the placeholder menu box is consumed here and
          // never reaches the full-screen scrim behind it — a plain
          // `Container` alone does not participate in hit testing (no
          // `hitTestSelf`), so without this wrapper the tap would fall
          // through to the scrim and dismiss the menu even when tapping
          // the menu itself. Story 007's real menu content replaces this
          // box with actual tappable options, each of which will need the
          // same absorb-the-tap property individually.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              width: 160,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
