import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../gameplay/pet_room_game.dart';

/// Child Shell's Pet Room tab (main-navigation-shell Story 002, ADR-0014
/// Decision §2). Hosts a real [PetRoomGame] via [GameWidget] — not just a
/// `Scaffold`+`Text` placeholder — because AC-5 requires proving the SAME
/// `FlameGame`/`GameLoop` instance survives being switched offstage
/// (Tasks/Shop branches active) and back, with its `update(dt)` loop still
/// incrementing while offstage. A bare Scaffold placeholder cannot prove or
/// disprove that mechanism (Implementation Note 5).
///
/// Real Pet Room content (Mochi sprite, background, HUD) belongs to Pet Room
/// Screen UI (#18), an epic that doesn't exist yet — this screen is
/// explicitly a placeholder per this story's Out of Scope note.
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
      body: GameWidget<PetRoomGame>(game: _game),
    );
  }
}
