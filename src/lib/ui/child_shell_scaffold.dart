import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/router_provider.dart';
import 'exit_confirm_dialog.dart';
import 'floating_chip_cluster.dart';

/// Hosts the Child Shell's [StatefulNavigationShell] as the `Scaffold.body`,
/// with a 3-destination bottom [NavigationBar] (Nhà/Nhiệm vụ/Shop) driving
/// `goBranch` (main-navigation-shell Story 002, ADR-0014 Decision §2/§4).
///
/// The Floating chip cluster ([FloatingChipCluster], Story 006) renders as a
/// `Stack` overlay above [navigationShell], not inside it (Implementation
/// Note 2). It absorbs Story 004's [ParentOverrideTrigger] placeholder
/// wholesale into the real Profile chip (`profile_chip.dart`) — no second
/// long-press trigger is mounted anywhere; see `parent_override_trigger.dart`
/// and `floating_chip_cluster.dart`'s own doc comments for the full
/// absorption story.
///
/// **Back-press / exit-confirm dialog (Story 005, ADR-0014 Decision §6's
/// FIRST code sample)**: `build()` wraps the whole `Scaffold` in a single
/// `PopScope(canPop: false, ...)` that shows [ExitConfirmDialog] (**P17**)
/// and, on confirmed [Thoát], calls `SystemNavigator.pop()`. Deliberately
/// ONE `PopScope` here — not one per tab-root screen (`PetRoomScreen`,
/// `TaskManagementScreen`, `ShopScreen`) and not a branch-index/canPop check
/// gating whether it fires — because of how `PopScope` + go_router's nested
/// `StatefulShellRoute` Navigators actually interact, verified against
/// installed `go_router-17.3.0`/Flutter 3.44.4 source (not assumed from
/// training data, which predates this API surface):
///
/// `PopScope` registers itself with `ModalRoute.of(context)` — the nearest
/// enclosing *Route*, not "whichever Navigator is currently active"
/// (`flutter/lib/src/widgets/pop_scope.dart`, `_PopScopeState.
/// didChangeDependencies`). `StatefulShellRoute.indexedStack` gives each
/// branch (Pet Room/Tasks/Shop) its OWN nested `Navigator`; this
/// `ChildShellScaffold` itself is the builder for ONE outer route in the
/// ROOT `Navigator`, sitting above all three nested branch Navigators — so a
/// `PopScope` wrapped around this class's own `Scaffold` registers with that
/// single outer route, never with any branch-specific one.
///
/// A real back-press resolves via `GoRouterDelegate.popRoute()`
/// (`go_router-17.3.0/lib/src/delegate.dart`), which tries
/// `NavigatorState.maybePop()` on the DEEPEST current Navigator first, only
/// falling through to shallower ones (ultimately the root, where this
/// `PopScope` lives) if the deeper one reports nothing to pop
/// (`Route.popDisposition == bubble`, `flutter/lib/src/widgets/
/// navigator.dart:382-390` — `isFirst ? bubble : pop`, i.e. "is this the
/// only/first page in ITS OWN Navigator's stack"). Concretely:
/// - On any tab root (`/child/pet-room`, `/child/tasks`, `/child/shop` — no
///   sub-route pushed), the active branch's own `Navigator` has exactly one
///   page, so its `maybePop()` bubbles, and the pop request falls through to
///   THIS shell-level `PopScope` — the exit dialog fires. This is true for
///   all 3 branches uniformly, with no per-branch special-casing needed.
/// - On `/child/tasks/new` (Story 002's sub-screen, `new_task_screen.dart`),
///   the Tasks branch's own `Navigator` has TWO pages; its topmost page is
///   `NewTaskScreen`, which carries its OWN `PopScope(canPop: true)`
///   (Implementation Note 6 there). That branch `Navigator`'s `maybePop()`
///   succeeds and pops immediately — the event is fully consumed at that
///   level and never reaches this shell-level `PopScope` at all. There is no
///   window where both dialogs could fire, and no manual
///   "is this a tab root" check (e.g. reading
///   `activeChildBranchIndexProvider` + a `Navigator.canPop` probe) is
///   needed to prevent it — the Route-scoped registration plus go_router's
///   deepest-first `_findCurrentNavigators()` fallback already implements
///   exactly that semantic structurally. Verified empirically, not just by
///   reading source, in `tests/integration/main-navigation-shell/
///   root_navigator_push_test.dart` via a real simulated system back-press
///   (`tester.binding.handlePopRoute()`), per this story's own instruction
///   not to assume the interaction without a test proving it.
///
/// This is a deliberate deviation from the story's Implementation Note 3,
/// which suggested keying off `activeChildBranchIndexProvider`'s value
/// paired with a manual canPop check on that branch's Navigator — that
/// signal is real but redundant here: this simpler, single-PopScope
/// placement already produces the exact same "tab-root only" behavior via
/// the framework's own route-scoped dispatch, with fewer moving parts and
/// no risk of the two signals (provider value vs. actual Navigator state)
/// ever disagreeing.
class ChildShellScaffold extends ConsumerStatefulWidget {
  const ChildShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ChildShellScaffold> createState() => _ChildShellScaffoldState();
}

class _ChildShellScaffoldState extends ConsumerState<ChildShellScaffold> {
  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Nhà'),
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'Nhiệm vụ',
    ),
    NavigationDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront),
      label: 'Shop',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _syncActiveBranchIndexAfterBuild();
  }

  @override
  void didUpdateWidget(covariant ChildShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Covers any route arriving at a non-default branch WITHOUT going
    // through `_onDestinationSelected`'s tap handler — a cold-start deep
    // link straight into `/child/tasks` or `/child/shop`, or restored
    // navigation state. Without this, `activeChildBranchIndexProvider`
    // (written ONLY by the tap handler below) would silently stay stuck at
    // its default 0 even though `navigationShell.currentIndex` is correctly
    // 1 or 2 — a real desync ADR-0014 Decision §4 does not surface on its
    // own, since `NavigationBar.selectedIndex` reads `currentIndex`
    // directly and looks correct regardless (found in code review, QA
    // testability pass).
    if (oldWidget.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      _syncActiveBranchIndexAfterBuild();
    }
  }

  /// Deferred to a post-frame callback (not written directly in
  /// `initState`/`didUpdateWidget`) since those run during the widget
  /// tree's build phase, and Riverpod disallows modifying provider state
  /// while the tree is building. The `!=` guard makes this idempotent with
  /// the tap handler's own synchronous write below — when a tap triggered
  /// the rebuild, this callback finds the value already correct and no-ops.
  void _syncActiveBranchIndexAfterBuild() {
    final index = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(activeChildBranchIndexProvider) != index) {
        ref.read(activeChildBranchIndexProvider.notifier).state = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => const ExitConfirmDialog(),
        );
        if (shouldExit ?? false) SystemNavigator.pop();
      },
      child: Scaffold(
        body: Stack(
          children: [widget.navigationShell, const FloatingChipCluster()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: _destinations,
        ),
      ),
    );
  }

  /// `goBranch` and `activeChildBranchIndexProvider`'s write happen in the
  /// same synchronous handler, with no `await` between them, so there is no
  /// window where one has updated and the other hasn't (ADR-0014 Decision
  /// §4's exact wiring pattern; this story's
  /// `activeChildBranchIndexProvider correctness` acceptance criterion).
  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    ref.read(activeChildBranchIndexProvider.notifier).state = index;
  }
}
