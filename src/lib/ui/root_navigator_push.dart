import 'package:flutter/material.dart';

/// Root-navigator push for non-dismissible full-screen overlays — ADR-0014
/// Decision §7 / `TR-navshell-004` (main-navigation-shell Story 005).
///
/// Pushes [overlay] on the ROOT `Navigator` (`rootNavigator: true`), not
/// whichever `Navigator` [context] would resolve to by default. This matters
/// because the bottom `NavigationBar` lives in `ChildShellScaffold`/
/// `ParentShellScaffold`'s own `Scaffold`, OUTSIDE every
/// `StatefulShellRoute` branch `Navigator` — a branch-scoped push (the
/// default `Navigator.of(context).push(...)` behavior from inside a branch
/// screen) would only cover that branch's own content area, leaving the
/// Scaffold — and its `NavigationBar` — visible and tappable underneath,
/// defeating "non-dismissible". Root-navigator push covers the entire
/// Scaffold, `NavigationBar` included.
///
/// `fullscreenDialog: true` on the underlying `MaterialPageRoute` selects the
/// platform-appropriate full-screen-modal transition (slide-up on iOS,
/// fade-through elsewhere) — a plain `MaterialPageRoute` default would use
/// the standard push transition instead, which reads as "another screen",
/// not "a modal overlay on top of everything", to a player.
///
/// No real consumer exists yet — Shop & Reward UI's ceremony overlays (e.g.
/// a future Chest Open) have no epic as of this story (Out of Scope note).
/// This function is the sanctioned mechanism future callers should reuse;
/// it's exercised here only via a placeholder widget in
/// `tests/integration/main-navigation-shell/root_navigator_push_test.dart`.
Future<T?> pushNonDismissibleOverlay<T>(BuildContext context, Widget overlay) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute<T>(builder: (_) => overlay, fullscreenDialog: true),
  );
}
