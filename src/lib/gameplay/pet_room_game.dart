import 'package:flame/game.dart';
import 'package:meta/meta.dart';

/// Minimal placeholder Pet Room [FlameGame] (main-navigation-shell Story 002,
/// ADR-0014 Decision §2). Deliberately has no `onLoad()` override and adds no
/// components — real Pet Room content (Mochi sprite, background, HUD) is Pet
/// Room Screen UI (#18), an epic that doesn't exist yet (this story's Out of
/// Scope note). [Game.onLoad] defaults to a synchronous no-op
/// (`FutureOr<void> onLoad() => null;`, `flame-1.37.0/lib/src/game/game.dart`)
/// so `game.load()`'s future resolves on the same microtask turn with no real
/// asset I/O — this keeps the widget test for AC-5 inside the ordinary
/// `flutter_test` fake-async zone (no `tester.runAsync` needed), verified
/// against flame-specialist's read of the installed `flame`/`flutter` source
/// during this story's implementation.
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

  @override
  void update(double dt) {
    super.update(dt);
    updateTickCount++;
  }
}
