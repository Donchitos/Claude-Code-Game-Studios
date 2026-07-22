import 'package:flutter/material.dart';

/// Parent Shell's Dashboard tab (main-navigation-shell Story 003, ADR-0014
/// Decision §3) — a bare placeholder `Scaffold`, same shape as
/// `TaskManagementScreen`/`ShopScreen` from Story 002. Real content belongs
/// to Parent Dashboard UI (#21), an epic that is currently Blocked pending
/// this epic (this story's Out of Scope note) — that epic will edit this
/// file in place rather than swap out a placeholder-named widget, matching
/// how `PetRoomScreen` etc. were done in Story 002.
///
/// Named `ParentDashboardTasksTab` to match ADR-0014 Decision §3's own code
/// sample exactly (`parentShellRoute`'s branch builder), not an invented
/// placeholder name.
///
/// A `StatefulWidget` with a public (not `_`-prefixed) `State` class is used
/// deliberately, not the plain `StatelessWidget` shape of
/// `TaskManagementScreen`/`ShopScreen` — this story's AC-4 ("state
/// preservation across tabs") needs a real test seam proving no
/// rebuild/dispose occurs across a branch round-trip, the same spirit as
/// Story 002's `FlameGame`-instance-identity proof but with no Flame object
/// available here to observe instead. See [ParentDashboardTasksTabState].
///
/// Retains a visible `Text('Parent Dashboard')` marker (the `AppBar` title)
/// so two pre-existing test files
/// (`tests/integration/main-navigation-shell/root_redirect_test.dart`,
/// `tests/integration/auth_account/router_redirect_test.dart`) that assert
/// `find.text('Parent Dashboard')` to confirm the router reached this route
/// keep passing — this widget replaces the flat placeholder `GoRoute` they
/// previously relied on.
class ParentDashboardTasksTab extends StatefulWidget {
  const ParentDashboardTasksTab({super.key});

  @override
  State<ParentDashboardTasksTab> createState() =>
      ParentDashboardTasksTabState();
}

/// Public test seam (Story 003's own AC-4 design, see class doc comment
/// above) — must NOT be `_`-prefixed, since
/// `tests/integration/main-navigation-shell/parent_shell_test.dart` reaches
/// it via `tester.state<ParentDashboardTasksTabState>(...)`, which requires
/// the type to be visible outside this library.
class ParentDashboardTasksTabState extends State<ParentDashboardTasksTab> {
  /// Incremented exactly once, in [initState] — never touched again.
  /// `StatefulShellRoute.indexedStack` is supposed to keep this branch's
  /// widget subtree alive (never disposed) across a switch to the sibling
  /// "Gia đình" branch and back; if that guarantee were violated, a FRESH
  /// `State` would be constructed and this would read back `1` again from a
  /// zeroed field, not the same already-`1` value. The test asserts this
  /// value (and this exact `State` object's identity) survive a round-trip
  /// unchanged.
  int initCount = 0;

  @override
  void initState() {
    super.initState();
    initCount++;
  }

  @override
  Widget build(BuildContext context) {
    // Body text is deliberately distinct from the AppBar's 'Parent
    // Dashboard' title (not a duplicate `Text('Parent Dashboard')`) — two
    // pre-existing regression test files
    // (`root_redirect_test.dart`/`router_redirect_test.dart`) and this
    // story's own `parent_shell_test.dart` assert `find.text('Parent
    // Dashboard')` expecting exactly ONE match (the AppBar title); a
    // duplicate in the body would make that finder ambiguous.
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Dashboard')),
      body: const Center(child: Text('Nhiệm vụ (placeholder)')),
    );
  }
}
