import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/router_provider.dart';
import 'app_colors.dart';
import 'parent_override_actions.dart';

/// Hosts the Parent Shell's [StatefulNavigationShell] as the `Scaffold.body`,
/// with a 2-destination bottom [NavigationBar] (Nhiệm vụ/Gia đình) driving
/// `goBranch` (main-navigation-shell Story 003, ADR-0014 Decision §3/§4).
///
/// Structurally mirrors [ChildShellScaffold] (`child_shell_scaffold.dart`) —
/// same `initState`/`didUpdateWidget` guarded post-frame sync of
/// [activeChildBranchIndexProvider] from `navigationShell.currentIndex`, and
/// the same synchronous `goBranch` + provider-write tap handler. This exact
/// sync was added to `ChildShellScaffold` during Story 002's code review
/// after a real bug was found there — `activeChildBranchIndexProvider`
/// staying stuck at its default value when a route lands on a non-default
/// branch WITHOUT a tap (e.g. a deep link or restored navigation state).
/// Reproduced here deliberately, not reinvented, to avoid reintroducing that
/// same bug in this shell.
///
/// Unlike [ChildShellScaffold], there is NO `Stack` overlay here — Parent
/// Shell has no floating chips (GDD Core Rule 5 / this story's
/// Implementation Note 2); the top zone stays reserved/empty for the FCM
/// banner Parent Dashboard UI will render later (not this story's concern).
/// `body: widget.navigationShell` is passed directly to [Scaffold], so no
/// `Stack` widget exists anywhere in this subtree — the structural proof
/// this story's "no floating chips" acceptance criterion tests against.
///
/// Visual tone is deliberately distinct from [ChildShellScaffold]'s default
/// `NavigationBar`: navy-toned and more subdued, 24dp icons / 12sp labels
/// (Implementation Note 4). Set via a [NavigationBarTheme] scoped to only
/// this widget's own `NavigationBar`, using [AppColors.parentNavy] (found in
/// code review to be a real, already-cited-elsewhere GDD value — not a
/// single-widget concern after all, see `app_colors.dart`'s own doc comment)
/// — this guarantees Child Shell and Parent Shell can never accidentally end
/// up sharing one `NavigationBar` widget config, while still keeping the
/// color itself centralized.
///
/// **Open accessibility question, flagged not silently resolved** (found in
/// code review): `design/ux/main-navigation-shell.md:232`'s 2026-07-13/14
/// contrast audit says text/icons on a Navy background must use Primary text
/// (`#3D2B1F`) — but that audit only tested Primary text against the 7
/// existing light/mid-tone Art Bible fills, none of which is this dark a
/// background. Primary text (itself dark brown) on dark Navy would almost
/// certainly fail contrast in the OPPOSITE direction the audit was guarding
/// against. This widget uses a light, high-contrast tone instead
/// (`Colors.white70`) as the safer choice pending a real
/// WCAG check of text-on-Navy specifically — not yet run. Do not copy the
/// literal "always Primary text" rule here without that audit.
///
/// **Back-press (Story 004, AC-13; ADR-0014 Decision §6's THIRD code
/// sample)**: every screen inside this shell is wrapped in the
/// override-exit `PopScope` — `canPop: false`, and
/// `onPopInvokedWithResult` calls
/// [endParentOverrideAndReturnToPetRoom] instead of letting the pop
/// proceed (which would otherwise exit the app, since this shell has no
/// screen below it on the Navigator stack). Deliberately unconditional,
/// not branched on `ref.watch(parentOverrideProvider)`: ADR-0014 Decision
/// §6 also documents a second, plain `PopScope(canPop: true)` shape for
/// "Parent Shell tab-root, NOT in override" — but that case is
/// structurally UNREACHABLE here. `redirectForSessionState` only ever
/// routes to `/parent/*` (where this shell lives) for
/// `SessionState.parentView`, and `sessionStateProvider`'s own derivation
/// (`auth_providers.dart`) defines `parentView` as `activeChild != null &&
/// parentOverrideProvider == true` — i.e. reaching this shell at all
/// already guarantees override is `true`. Branching on the provider here
/// would be dead code the redirect guard can never exercise; flagged
/// rather than added speculatively (found during this story's own
/// implementation, not guessed at ahead of time).
class ParentShellScaffold extends ConsumerStatefulWidget {
  const ParentShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ParentShellScaffold> createState() =>
      _ParentShellScaffoldState();
}

class _ParentShellScaffoldState extends ConsumerState<ParentShellScaffold> {
  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'Nhiệm vụ',
    ),
    NavigationDestination(
      icon: Icon(Icons.family_restroom_outlined),
      selectedIcon: Icon(Icons.family_restroom),
      label: 'Gia đình',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _syncActiveBranchIndexAfterBuild();
  }

  @override
  void didUpdateWidget(covariant ParentShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Covers any route arriving at a non-default branch WITHOUT going
    // through `_onDestinationSelected`'s tap handler — same rationale as
    // `ChildShellScaffold.didUpdateWidget` (main-navigation-shell Story 002
    // code review finding).
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _syncActiveBranchIndexAfterBuild();
    }
  }

  /// Deferred to a post-frame callback — see `ChildShellScaffold`'s own copy
  /// of this method for the full rationale (Riverpod disallows modifying
  /// provider state mid-build; the `!=` guard makes this idempotent with the
  /// tap handler's own synchronous write below).
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
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        endParentOverrideAndReturnToPetRoom(ref, context);
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.parentNavy,
            // No GDD-specified indicator shade exists yet — derived from the
            // base tone rather than inventing an undocumented hex.
            indicatorColor: Color.lerp(AppColors.parentNavy, Colors.white, 0.15),
            iconTheme: const WidgetStatePropertyAll(
              IconThemeData(size: 24, color: Colors.white70),
            ),
            labelTextStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          child: NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _destinations,
          ),
        ),
      ),
    );
  }

  /// `goBranch` and `activeChildBranchIndexProvider`'s write happen in the
  /// same synchronous handler, with no `await` between them (ADR-0014
  /// Decision §4's exact wiring pattern; same shape as
  /// `ChildShellScaffold._onDestinationSelected`).
  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    ref.read(activeChildBranchIndexProvider.notifier).state = index;
  }
}
