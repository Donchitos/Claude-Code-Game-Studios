import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/router_provider.dart';
import 'parent_switch_mode_sheet.dart';

/// The `long_press_duration` tuning knob (GDD Tuning Knobs, range
/// 400-1000ms; listed as "Required" under this story's own Control Manifest
/// Rules) — how long [ParentOverrideTrigger] must be held before the
/// switch-mode sheet opens (AC-8).
const Duration kParentOverrideLongPressDuration = Duration(milliseconds: 600);

/// The long-press-to-Parent-Override gesture wrapper (Story 004's original
/// AC-8/9/13/14 logic — UNCHANGED here) — absorbed by main-navigation-shell
/// Story 006 (Floating Chip Cluster) into the real [ProfileChip]
/// (`profile_chip.dart`), per that story's own Implementation Note 1
/// ("Long-press gesture *detection* lives here ... wire this chip's
/// `onLongPress` callback to call into Story 004's exposed action, don't
/// duplicate logic").
///
/// Story 004 originally rendered its own placeholder circular icon directly;
/// Story 006 lifted this widget "wholesale" (same [triggerKey],
/// [kParentOverrideLongPressDuration] tuning knob, same tap-down/timer/tap-up
/// pattern — see the git history / that story's own doc comment for why a
/// bare `showParentSwitchModeSheet()` call with no UI trigger would have left
/// AC-8 untestable) and generalized it to wrap an arbitrary [child] — the
/// real chip's visual — instead of hardcoding its own icon/positioning. No
/// second trigger is mounted anywhere; [ProfileChip] is this widget's only
/// production caller now (`floating_chip_cluster.dart`).
class ParentOverrideTrigger extends StatefulWidget {
  const ParentOverrideTrigger({required this.child, super.key});

  static const triggerKey = Key('parentOverrideTrigger');

  final Widget child;

  @override
  State<ParentOverrideTrigger> createState() => _ParentOverrideTriggerState();
}

class _ParentOverrideTriggerState extends State<ParentOverrideTrigger> {
  Timer? _pressTimer;

  void _onTapDown(TapDownDetails details) {
    _pressTimer?.cancel();
    _pressTimer = Timer(kParentOverrideLongPressDuration, _fire);
  }

  void _cancelPressTimer() {
    _pressTimer?.cancel();
    _pressTimer = null;
  }

  void _fire() {
    _pressTimer = null;
    if (!mounted) return;
    showParentSwitchModeSheet(context, isSubScreen: _isOnSubScreen(context));
  }

  /// Compares the router's actual current leaf location against the child
  /// tab-root set — anything under `/child/*` that ISN'T a tab root (e.g.
  /// `/child/tasks/new`) is a sub-screen (Edge Case — GDD). Reads via
  /// `GoRouter.of(context).routerDelegate.currentConfiguration` (the same
  /// accessor this epic's own test files use), not `GoRouterState.of`
  /// — this widget's `context` is a sibling of `navigationShell`, not a
  /// descendant of whichever leaf route is actually active inside it, so
  /// `GoRouterState.of(context)` would resolve to the outer shell route's
  /// own match, not the true current leaf location.
  static bool _isOnSubScreen(BuildContext context) {
    // `.path`, not `.uri.toString()` — a tab-root URL carrying a query
    // string/fragment would otherwise fail the `tabRoots.contains` check
    // below even though it's still a tab root (none of the 3 child tab-root
    // routes carry one today, but this is a one-line robustness fix, found
    // in code review).
    final location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    const tabRoots = {
      AppRoutes.childPetRoom,
      AppRoutes.childTasks,
      AppRoutes.childShop,
    };
    return location.startsWith('/child/') && !tabRoots.contains(location);
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ParentOverrideTrigger.triggerKey,
      onTapDown: _onTapDown,
      onTapUp: (_) => _cancelPressTimer(),
      onTapCancel: _cancelPressTimer,
      child: widget.child,
    );
  }
}
