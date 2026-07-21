import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/child_profile_selection_screen.dart';
import '../ui/login_screen.dart';
import '../ui/pin_entry_screen.dart';
import '../ui/register_screen.dart';
import 'auth_providers.dart';

/// Bridges [sessionStateProvider] (a plain Riverpod [Provider], not
/// [Listenable]) to go_router's `refreshListenable` — without it the value
/// updates but `redirect` never re-runs (ADR-0002 §5). `GoRouterRefreshStream`
/// is not used here: it was removed from the `go_router` package itself in
/// v5.0.0 and is not re-exported by `go_router ^17.3.0` (verified against the
/// installed package source) — `ref.listen` is the only of ADR-0002's two
/// options that still applies without hand-rolling a replacement class.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

/// Shared 200ms fade enter/exit transition — every auth-flow UX spec
/// (login-screen.md, child-profile-selection-screen.md, pin-entry-screen.md)
/// independently specifies the same "fade 200ms, reduced-motion → near-instant
/// cross-fade" transition for screen enter/exit, so it's implemented once
/// here rather than per-screen (found in Story 010 code review — code-review
/// 2026-07-16 — the UX spec's Transitions & Animations section was otherwise
/// silently unimplemented).
Page<void> fadeTransitionPage(BuildContext context, GoRouterState state, Widget child) {
  final reducedMotion = MediaQuery.of(context).disableAnimations;
  final duration =
      reducedMotion ? const Duration(milliseconds: 1) : const Duration(milliseconds: 200);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Route paths for the auth-account session states. `login`/`selectChild`
/// are real screens (Story 010/011); the rest remain placeholders until
/// Story 012 lands.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const selectChild = '/select-child';

  /// Reached via `context.push()` from [selectChild] (Story 011's profile
  /// card tap), NOT via the redirect system — it's a sub-navigation within
  /// `parentAuthed`, not its own session state. See
  /// [redirectForSessionState]'s `parentAuthed` case, which allows both this
  /// and [selectChild] as valid locations for that state.
  static const pinEntry = '/select-child/pin-entry';

  /// Child Shell default route (ADR-0014 Decision §1) — the `childSelected`
  /// redirect branch (see [redirectForSessionState]) allows any `/child/*`
  /// location and defaults here. Only a flat placeholder `GoRoute` exists for
  /// this path so far (main-navigation-shell Story 001) — Story 002 replaces
  /// it with the real `StatefulShellRoute` (Pet Room/Tasks/Shop tabs).
  static const childPetRoom = '/child/pet-room';
  static const childTasks = '/child/tasks';
  static const childTasksNew = '/child/tasks/new';
  static const childShop = '/child/shop';

  /// Parent Shell default route (ADR-0014 Decision §1) — the `parentView`
  /// redirect branch (see [redirectForSessionState]) allows any `/parent/*`
  /// location and defaults here. MOVED from the flat `/parent-dashboard`
  /// (pre-main-navigation-shell) to this branch-scoped path per ADR-0014's
  /// Migration Plan (main-navigation-shell Story 001). Only a flat
  /// placeholder `GoRoute` exists for this path so far — Story 003 replaces
  /// it with the real `StatefulShellRoute` (Dashboard/Gia đình tabs).
  static const parentDashboard = '/parent/dashboard';
  static const parentFamily = '/parent/family';

  static String pinEntryFor(String childId) =>
      '$pinEntry?childId=${Uri.encodeQueryComponent(childId)}';
}

/// The single app router. `redirect` reads only [sessionStateProvider] and
/// does not re-derive session state itself (control-manifest Foundation Layer
/// Rules, ADR-0002 §5).
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(sessionStateProvider, (_, _) => refreshNotifier.refresh());
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshNotifier,
    redirect: (context, state) =>
        redirectForSessionState(ref.read(sessionStateProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            fadeTransitionPage(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            fadeTransitionPage(context, state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.selectChild,
        pageBuilder: (context, state) =>
            fadeTransitionPage(context, state, const ChildProfileSelectionScreen()),
      ),
      GoRoute(
        path: AppRoutes.pinEntry,
        pageBuilder: (context, state) => fadeTransitionPage(
          context,
          state,
          PinEntryScreen(childId: state.uri.queryParameters['childId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.childPetRoom,
        pageBuilder: (context, state) =>
            fadeTransitionPage(context, state, const _PlaceholderScreen(title: 'Pet Room')),
      ),
      GoRoute(
        path: AppRoutes.parentDashboard,
        pageBuilder: (context, state) => fadeTransitionPage(
          context,
          state,
          const _PlaceholderScreen(title: 'Parent Dashboard'),
        ),
      ),
    ],
  );
});

/// Pure [SessionState] → route mapping, exposed for direct unit testing
/// alongside the integration test that exercises the real [GoRouter].
///
/// `childSelected` and `parentView` are independent branches (ADR-0014
/// Decision §1, main-navigation-shell Story 001) — `childSelected` allows any
/// `/child/*` location, defaulting to [AppRoutes.childPetRoom]; `parentView`
/// allows any `/parent/*` location, defaulting to [AppRoutes.parentDashboard].
/// This supersedes this function's original (pre-main-navigation-shell)
/// behavior, where both states collapsed into a single
/// `matchedLocation == petRoom` check and `parentView` deliberately never
/// forced a location change — that was Auth & Account's placeholder-era
/// design, where GDD Core Rule 5 was read as "Parent Dashboard overlays the
/// child route via `context.push()`". ADR-0014 replaces that overlay model
/// with real `context.go()` navigation into `/parent/*`, picked up
/// automatically by the `ref.listen` refresh bridge above (ADR-0014 Decision
/// §5) — no manual navigation-plus-guard duplication needed.
String? redirectForSessionState(SessionState sessionState, String matchedLocation) {
  switch (sessionState) {
    case SessionState.unauthenticated:
      // Both login and register are valid locations for this state —
      // register is a sibling entry point, not its own session state
      // (Story 013; same "two valid locations for one state" shape as
      // parentAuthed's selectChild/pinEntry pair below).
      return (matchedLocation == AppRoutes.login || matchedLocation == AppRoutes.register)
          ? null
          : AppRoutes.login;
    case SessionState.parentAuthed:
      // Both selectChild and pinEntry are valid locations for this state —
      // pinEntry is a sub-navigation reached by an explicit context.push(),
      // not a session-state transition of its own (found in Story 011 —
      // without this, the redirect would bounce every push back to
      // selectChild, breaking the profile-tap → PIN entry flow).
      return (matchedLocation == AppRoutes.selectChild ||
              matchedLocation == AppRoutes.pinEntry)
          ? null
          : AppRoutes.selectChild;
    case SessionState.childSelected:
      // Allows any /child/* location — Story 002's real StatefulShellRoute
      // branches (Pet Room/Tasks/Shop) will all live under this prefix, but
      // this story only wires the placeholder childPetRoom GoRoute against
      // it (main-navigation-shell Story 001).
      return matchedLocation.startsWith('/child/') ? null : AppRoutes.childPetRoom;
    case SessionState.parentView:
      // Allows any /parent/* location — Story 003's real StatefulShellRoute
      // branches (Dashboard/Gia đình) will all live under this prefix; this
      // story only wires the placeholder parentDashboard GoRoute against it.
      // Independent branch from childSelected above — verified separately
      // per this story's own "parentView redirect" acceptance criterion.
      return matchedLocation.startsWith('/parent/') ? null : AppRoutes.parentDashboard;
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}
