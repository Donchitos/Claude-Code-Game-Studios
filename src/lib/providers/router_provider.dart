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
  static const petRoom = '/pet-room';
  static const parentDashboard = '/parent-dashboard';

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
        path: AppRoutes.petRoom,
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
/// `parentView` does not force `AppRoutes.parentDashboard`: per GDD Core Rule
/// 5, the Parent Dashboard overlays the active child route rather than
/// replacing it — it is reached via an explicit `context.push()` from the
/// override UI (a later story), not by this redirect forcing a location
/// change. It DOES still require `matchedLocation == petRoom` — `parentView`
/// is only reachable from `childSelected`, so the child route must be the
/// thing underneath the overlay; if some future flow (deep link, restored
/// session) ever lands on `parentView` from elsewhere, this still lands the
/// child route first rather than silently leaving the mismatched location in
/// place (found in Story 003 code review — code-review 2026-07-15).
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
    case SessionState.parentView:
      return matchedLocation == AppRoutes.petRoom ? null : AppRoutes.petRoom;
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
