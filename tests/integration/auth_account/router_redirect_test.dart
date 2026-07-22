// Run with:
//   cd src && flutter test ../tests/integration/auth_account/router_redirect_test.dart
//
// Two layers of coverage:
//   1. Pure `redirectForSessionState` unit cases — fast, no widget pump.
//   2. A widget test driving the REAL GoRouter built by `routerProvider`
//      through MockFirebaseAuth's real `authStateChanges()` stream (not a
//      synthetic overridden stream — overriding authStateProvider directly
//      with a custom stream was found to hang in Story 002's tests; using
//      MockFirebaseAuth + overriding only the `firebaseAuthProvider` DI seam
//      avoids that class of problem entirely) plus direct StateProvider
//      writes for activeChildProvider/parentOverrideProvider. Asserts on the
//      actually-rendered screen at each step (the real LoginScreen since
//      Story 010, placeholders for the rest until Story 011/012 land) —
//      proving an actual redirect happened, not just a provider-value change
//      (AC-3).
//
// Real gotcha found writing this test (riverpod 3.3.2): `container.read
// (routerProvider)` alone is NOT enough to keep the chain live. Riverpod
// pauses a StreamProvider's underlying subscription (here, authStateProvider
// wrapping MockFirebaseAuth.authStateChanges()) when nothing actively listens
// to it — a one-time `.read()` doesn't count, so sign-in events fired after
// that read were silently dropped and the router never redirected. In
// production this isn't an issue because `PetQuestApp`'s `ref.watch
// (routerProvider)` (a ConsumerWidget build) is a persistent listener for the
// widget's lifetime. Here we replicate that by explicitly holding a
// `container.listen(routerProvider, ...)` subscription open for the test's
// duration instead of a bare `.read()`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/child_profile_selection_screen.dart';
import 'package:pet_quest/ui/login_screen.dart';

/// Minimal Firestore fake — this test only needs `childProfilesProvider`
/// (watched by the now-real `ChildProfileSelectionScreen`, Story 011) to
/// resolve to an empty list without touching a real Firebase backend; it
/// never asserts on profile content, only that the correct screen renders.
class _EmptyQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async =>
      _EmptyQuerySnapshot();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollectionReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Regression fix (main-navigation-shell Story 002): once this test reaches
/// `/child/pet-room`, the real `PetRoomScreen` (`StatefulShellRoute`'s Child
/// Shell, ADR-0014 Decision §2) mounts a `GameWidget<PetRoomGame>` whose
/// `GameLoop` drives itself via a raw `Ticker` that keeps
/// `SchedulerBinding.hasScheduledFrame` perpetually true for as long as any
/// widget subtree containing it stays mounted (by design — this is
/// literally what proves AC-5). `tester.pumpAndSettle()` therefore never
/// settles from that point on and throws "pumpAndSettle timed out" — it did
/// not before Story 002, when `/child/pet-room` was still a bare
/// `_PlaceholderScreen` with no active Ticker. Every `pumpAndSettle()` call
/// below that occurs at-or-after the moment `activeChildProvider` is first
/// set is replaced with this bounded-step helper instead (same fix, and
/// same underlying reason, as
/// `tests/integration/pet_state_machine/mochi_component_background_pause_real_ticker_test.dart`'s
/// `_pumpRealTicker` helper). The two calls before that point (still at
/// /login or /select-child, no Ticker mounted yet) are untouched.
Future<void> _pumpBoundedSteps(
  WidgetTester tester, {
  int steps = 20,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

void main() {
  group('redirectForSessionState (pure logic)', () {
    test('test_redirectForSessionState_unauthenticated_routes_to_login', () {
      // '/some-arbitrary-route' stands in for "any non-login/register
      // location" — NOT a reference to the old flat '/pet-room' route, which
      // main-navigation-shell Story 001 removed (AppRoutes.petRoom no longer
      // exists; found as a stale literal in code review, 2026-07-19).
      expect(
        redirectForSessionState(SessionState.unauthenticated, '/some-arbitrary-route'),
        AppRoutes.login,
      );
    });

    test(
        'test_redirectForSessionState_unauthenticated_allows_register_as_a_'
        'valid_sibling_location_to_login', () {
      // Story 013: register is a sibling entry point for `unauthenticated`,
      // not its own session state — the redirect must not bounce it back to
      // /login (same "two valid locations for one state" shape as
      // parentAuthed's selectChild/pinEntry pair below). Only the `login`
      // branch of this OR condition was covered before this test.
      expect(
        redirectForSessionState(SessionState.unauthenticated, AppRoutes.register),
        isNull,
      );
    });

    test('test_redirectForSessionState_parentAuthed_routes_to_select_child',
        () {
      expect(
        redirectForSessionState(SessionState.parentAuthed, '/login'),
        AppRoutes.selectChild,
      );
    });

    test(
        'test_redirectForSessionState_parentAuthed_allows_pinEntry_as_a_valid_sub_navigation',
        () {
      // pinEntry is reached via context.push() from selectChild (Story 011's
      // profile-card tap), not a session-state transition — the redirect
      // must not bounce it back to selectChild (found in Story 011).
      expect(
        redirectForSessionState(SessionState.parentAuthed, AppRoutes.pinEntry),
        isNull,
      );
    });

    test(
        'test_redirectForSessionState_parentAuthed_still_redirects_unrelated_locations_to_select_child',
        () {
      expect(
        redirectForSessionState(SessionState.parentAuthed, AppRoutes.childPetRoom),
        AppRoutes.selectChild,
      );
    });

    test('test_redirectForSessionState_childSelected_routes_to_pet_room', () {
      expect(
        redirectForSessionState(SessionState.childSelected, '/select-child'),
        AppRoutes.childPetRoom,
      );
    });

    test(
        'test_redirectForSessionState_parentView_allows_parent_routes',
        () {
      // main-navigation-shell Story 001 (ADR-0014 Decision §1) supersedes
      // this file's original "Parent Dashboard overlays the child route, so
      // parentView never forces a location change" reading of GDD Core Rule
      // 5 — parentView now allows any /parent/* location, same shape as
      // childSelected's /child/* allowance.
      expect(
        redirectForSessionState(SessionState.parentView, AppRoutes.parentDashboard),
        isNull,
      );
    });

    test(
        'test_redirectForSessionState_already_at_target_location_returns_null',
        () {
      expect(
        redirectForSessionState(SessionState.childSelected, AppRoutes.childPetRoom),
        isNull,
      );
    });

    test(
        'test_redirectForSessionState_parentView_from_non_parent_location_lands_parent_dashboard',
        () {
      // Updated for main-navigation-shell Story 001 (ADR-0014 Decision §1):
      // parentView now defaults to AppRoutes.parentDashboard, not the child
      // route — superseding this file's original "still lands pet room"
      // regression case (Story 003 code review, code-review 2026-07-15),
      // which predates ADR-0014's overlay-model replacement.
      expect(
        redirectForSessionState(SessionState.parentView, '/login'),
        AppRoutes.parentDashboard,
      );
    });
  });

  group('GoRouter integration (real routerProvider)', () {
    testWidgets(
        'test_router_redirects_through_full_session_transition_sequence',
        (tester) async {
      final mockAuth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
        ],
      );
      addTearDown(container.dispose);

      // Keep routerProvider (and everything it depends on) actively listened
      // for the whole test — see header comment for why a bare `.read()`
      // isn't sufficient here.
      final routerSubscription = container.listen(routerProvider, (_, __) {});
      addTearDown(routerSubscription.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: routerSubscription.read(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. unauthenticated -> /login (real LoginScreen since Story 010)
      expect(find.byType(LoginScreen), findsOneWidget);

      // 2. sign in -> parentAuthed -> /select-child
      await mockAuth.signInWithEmailAndPassword(
        email: 'parent@example.com',
        password: 'irrelevant-for-this-test',
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChildProfileSelectionScreen), findsOneWidget);

      // 3. select a child -> childSelected -> /child/pet-room
      container.read(activeChildProvider.notifier).state = const ChildProfile(
        childId: 'child-1',
        name: 'Bé An',
        avatarId: 'avatar-1',
        mochiName: 'Mochi',
      );
      await _pumpBoundedSteps(tester);
      expect(find.text('Pet Room'), findsOneWidget);

      // 4. parent override -> parentView -> navigates to /parent/dashboard.
      //    Updated for main-navigation-shell Story 001 (ADR-0014 Decision
      //    §1): parentView now allows/defaults into /parent/* via a real
      //    context.go(), superseding this file's original "stays on Pet
      //    Room" overlay-model expectation.
      container.read(parentOverrideProvider.notifier).state = true;
      await _pumpBoundedSteps(tester);
      // Asserted via the route URI, not the old literal `Text('Parent
      // Dashboard')` marker — Parent Dashboard UI Story 001 gave this tab
      // its real "Nhiệm vụ" app bar title (design/ux/parent-dashboard-ui.md),
      // superseding that placeholder-era marker. The URI check proves the
      // same thing the marker was standing in for: routing genuinely reached
      // this route, not just that some screen rendered.
      expect(
        container.read(routerProvider).routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.parentDashboard,
      );
      expect(find.text('Pet Room'), findsNothing);

      // 5. override ends -> childSelected again -> back to /child/pet-room
      //    (childSelected doesn't allow /parent/*, so the redirect forces it
      //    back to the childPetRoom default — the child branch was never
      //    disposed, per ADR-0014 Decision §5, so no re-PIN is needed).
      container.read(parentOverrideProvider.notifier).state = false;
      await _pumpBoundedSteps(tester);
      expect(find.text('Pet Room'), findsOneWidget);
    });
  });
}
