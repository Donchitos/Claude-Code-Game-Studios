// Run with:
//   cd src && flutter test ../tests/integration/main-navigation-shell/root_redirect_test.dart
//
// Story 001 (Root Redirect & Session Guard, main-navigation-shell epic) —
// covers this story's own 6 acceptance criteria, one test function per AC
// (per its Test Evidence section), against the extended
// `redirectForSessionState`/`AppRoutes` shape (ADR-0014 Decision §1):
// `childSelected` now allows any `/child/*` location (default
// `AppRoutes.childPetRoom`) and `parentView` now allows any `/parent/*`
// location (default `AppRoutes.parentDashboard`) as two INDEPENDENT switch
// branches — replacing the old Auth & Account placeholder-era behavior where
// both states collapsed into a single `petRoom` check.
//
// Two layers of coverage, same shape as
// `tests/integration/auth_account/router_redirect_test.dart` (that file
// keeps its own coverage for the auth-flow cases this story doesn't change —
// unauthenticated/parentAuthed/register/pinEntry — so this file does not
// duplicate those, only the 6 ACs this story is directly responsible for):
//   1. Pure `redirectForSessionState` unit cases — fast, no widget pump.
//   2. A widget test driving the REAL GoRouter built by `routerProvider`
//      through MockFirebaseAuth's real `authStateChanges()` stream (the
//      established pattern from that file — overriding `authStateProvider`
//      directly with a synthetic stream was found to hang there).
//
// Real gotcha (riverpod 3.3.2, same as the existing auth_account test file):
// a one-time `container.read(routerProvider)` does NOT keep the chain live —
// `authStateProvider`'s underlying stream subscription gets paused. Tests
// below hold an explicit `container.listen(routerProvider, ...)`
// subscription open for their duration instead.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/login_screen.dart';

/// Minimal Firestore fake — only needed so `childProfilesProvider`
/// (transitively watched along the `parentAuthed` path) resolves without
/// touching a real backend; no test here asserts on Firestore content.
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

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  Map<String, dynamic>? data() => null;

  @override
  bool get exists => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Story 006 (Floating Chip Cluster) addition: `ChildShellScaffold` now
/// renders `FloatingChipCluster`, which watches `xuBalanceProvider`/
/// `seedCountProvider` — both call `.doc(...)` on the injected Firestore.
/// This file's `_FakeFirestore` previously only supported `.collection(...)`
/// (for `childProfilesProvider`); without this, `.doc()` would fall through
/// to `noSuchMethod`/`Object.noSuchMethod`, throwing `NoSuchMethodError` the
/// moment Pet Room mounts en route to `childSelected`/`parentView` (this
/// file's own header comment). A single no-data snapshot (never erroring,
/// never completing) is enough here — no test in this file asserts on
/// xu/seed content, and both providers already default a missing document to
/// `0` (`currency_providers.dart`/`seed_buffer_providers.dart`).
class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      Stream.value(_FakeDocumentSnapshot());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollectionReference();

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) => _FakeDocumentReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Regression fix (main-navigation-shell Story 002): once a test reaches
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
/// `_pumpRealTicker` helper). Calls before that point (still at /login or
/// /select-child, no Ticker mounted yet) are untouched.
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
  group('redirectForSessionState (pure logic) — one test per AC', () {
    test('test_AC1_unauthenticated_redirects_to_login', () {
      expect(
        redirectForSessionState(SessionState.unauthenticated, AppRoutes.childPetRoom),
        AppRoutes.login,
      );
    });

    test(
        'test_AC1_unauthenticated_deep_linked_to_non_login_url_still_redirects_to_login',
        () {
      // QA edge case: app cold-started directly at a deep-linked non-login
      // URL while unauthenticated must still redirect to /login — same
      // assertion shape as above, but exercising a route the app has never
      // navigated to organically (a raw deep link), not just an arbitrary
      // other-state default.
      expect(
        redirectForSessionState(SessionState.unauthenticated, AppRoutes.parentDashboard),
        AppRoutes.login,
      );
    });

    test('test_AC2_parentAuthed_redirects_to_select_child', () {
      // Intentional AC-traceability duplicate (code review, 2026-07-19): this
      // exact case is unchanged by this story and its canonical coverage is
      // `test_redirectForSessionState_parentAuthed_routes_to_select_child` in
      // tests/integration/auth_account/router_redirect_test.dart. Kept here
      // too only because the story's own Test Evidence section requires one
      // test per AC in THIS file — update both if this behavior ever changes.
      expect(
        redirectForSessionState(SessionState.parentAuthed, AppRoutes.childPetRoom),
        AppRoutes.selectChild,
      );
    });

    test(
        'test_AC3_childSelected_defaults_to_child_pet_room_as_initial_route',
        () {
      // Intentional AC-traceability duplicate (code review, 2026-07-19):
      // canonical coverage is
      // `test_redirectForSessionState_childSelected_routes_to_pet_room` in
      // tests/integration/auth_account/router_redirect_test.dart — see note
      // on the AC-2 test above.
      expect(
        redirectForSessionState(SessionState.childSelected, AppRoutes.selectChild),
        AppRoutes.childPetRoom,
      );
    });

    test(
        'test_AC3_childSelected_allows_any_child_prefixed_location_without_redirect',
        () {
      // AC-3 is scoped to the initial-route default; this confirms the
      // /child/* allowance behind that default doesn't collapse to a single
      // hardcoded path (Story 002 wires the real /child/tasks, /child/shop
      // routes; this story's guard already accepts them).
      expect(
        redirectForSessionState(SessionState.childSelected, AppRoutes.childShop),
        isNull,
      );
    });

    test(
        'test_AC11_session_expire_while_at_child_shop_redirects_to_login',
        () {
      // Pure-logic form of AC-11: the real /child/shop GoRoute doesn't exist
      // yet (Story 002's scope) so this is exercised at the redirect-function
      // level, not the live GoRouter — matches this story's own Out of Scope
      // note. The router-integration test below exercises the equivalent
      // scenario against the one child route this story DOES wire
      // (childPetRoom), proving the redirect actually fires end-to-end, not
      // just that the pure function returns the right string.
      expect(
        redirectForSessionState(SessionState.unauthenticated, AppRoutes.childShop),
        AppRoutes.login,
      );
    });

    test(
        'test_coldStart_fresh_container_resolves_synchronously_to_a_real_state_no_crash',
        () {
      // Cold-start finding (Implementation Notes §5): sessionStateProvider is
      // a plain (non-async) Provider<SessionState> — ref.watch(authStateProvider)
      // .value on a still-AsyncLoading StreamProvider is `null` (not a thrown
      // error, not an unresolved future), so sessionStateProvider ALWAYS has
      // an immediate, synchronous value the instant it's first read; there is
      // no "hasn't emitted yet" state for redirectForSessionState to receive.
      // This test proves that directly: calling it against a location that
      // isn't valid for the default (unauthenticated) state resolves
      // immediately to a real route, never throws, never blocks.
      expect(
        () => redirectForSessionState(SessionState.unauthenticated, AppRoutes.childPetRoom),
        returnsNormally,
      );
      expect(
        redirectForSessionState(SessionState.unauthenticated, AppRoutes.childPetRoom),
        AppRoutes.login,
      );
    });

    test(
        'test_parentView_redirect_allows_parent_prefixed_locations_independently_of_childSelected',
        () {
      // The two branches must be independently correct — parentView must NOT
      // accept /child/* locations, and childSelected must NOT accept
      // /parent/* locations, even though both default-redirect from
      // unrelated locations.
      expect(
        redirectForSessionState(SessionState.parentView, AppRoutes.login),
        AppRoutes.parentDashboard,
      );
      expect(
        redirectForSessionState(SessionState.parentView, AppRoutes.parentFamily),
        isNull,
      );
      expect(
        redirectForSessionState(SessionState.parentView, AppRoutes.childPetRoom),
        AppRoutes.parentDashboard,
      );
      expect(
        redirectForSessionState(SessionState.childSelected, AppRoutes.parentDashboard),
        AppRoutes.childPetRoom,
      );
    });

    test(
        'test_childSelected_rejects_bare_child_path_with_no_trailing_slash',
        () {
      // Boundary case (code review, 2026-07-19): '/child' (no trailing
      // slash/sub-path) must NOT match the '/child/' prefix check — verifies
      // the guard requires a real sub-path, not just the bare segment.
      expect(
        redirectForSessionState(SessionState.childSelected, '/child'),
        AppRoutes.childPetRoom,
      );
    });

    test(
        'test_childSelected_rejects_colliding_prefix_child_dash_something',
        () {
      // Boundary case (code review, 2026-07-19): a hypothetical future route
      // like '/child-something-else' must NOT false-positive against the
      // '/child/' prefix check (the character after "child" is '-', not
      // '/') — proves the guard is genuinely prefix-based on the full
      // '/child/' string, not a loose substring match.
      expect(
        redirectForSessionState(SessionState.childSelected, '/child-something-else'),
        AppRoutes.childPetRoom,
      );
    });

    test(
        'test_parentView_rejects_bare_parent_path_and_colliding_prefix',
        () {
      // Symmetric boundary cases for the parentView branch (code review,
      // 2026-07-19) — same reasoning as the childSelected cases above.
      expect(
        redirectForSessionState(SessionState.parentView, '/parent'),
        AppRoutes.parentDashboard,
      );
      expect(
        redirectForSessionState(SessionState.parentView, '/parent-other'),
        AppRoutes.parentDashboard,
      );
    });
  });

  group('GoRouter integration (real routerProvider)', () {
    testWidgets(
        'test_AC1_coldStart_first_frame_shows_login_directly_no_intermediate_flash',
        (tester) async {
      // AC-1 + Cold-start AC together: a brand-new ProviderContainer (nobody
      // signed in yet, matching real app cold-start) must land on /login on
      // the very first pump — no separate blank/loading frame is needed
      // because redirectForSessionState resolves synchronously (see the pure
      // cold-start test above), and no other screen ever flashes first.
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
        ],
      );
      addTearDown(container.dispose);

      final routerSubscription = container.listen(routerProvider, (_, __) {});
      addTearDown(routerSubscription.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: routerSubscription.read()),
        ),
      );
      // A single pump (not pumpAndSettle) — proves the correct screen is
      // already resolved on the first frame, not just eventually after
      // further pumps/settling.
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Drain MockFirebaseAuth's own pending stream-emission timer before
      // teardown (unrelated to the assertion above, which already happened
      // against the first frame) — otherwise the test framework's
      // no-pending-timers invariant check fails.
      await tester.pumpAndSettle();
    });

    testWidgets(
        'test_AC11_session_expiry_at_child_pet_room_redirects_to_login_not_stuck',
        (tester) async {
      final mockAuth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
        ],
      );
      addTearDown(container.dispose);

      final routerSubscription = container.listen(routerProvider, (_, __) {});
      addTearDown(routerSubscription.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: routerSubscription.read()),
        ),
      );
      await tester.pumpAndSettle();

      // Reach childSelected -> /child/pet-room.
      await mockAuth.signInWithEmailAndPassword(
        email: 'parent@example.com',
        password: 'irrelevant-for-this-test',
      );
      container.read(activeChildProvider.notifier).state = const ChildProfile(
        childId: 'child-1',
        name: 'Bé An',
        avatarId: 'avatar-1',
        mochiName: 'Mochi',
      );
      await _pumpBoundedSteps(tester);
      expect(find.text('Pet Room'), findsOneWidget);

      // Session expires mid-session (signed out) — AC-11: must redirect to
      // /login, must not remain stuck on the child route.
      await mockAuth.signOut();
      await _pumpBoundedSteps(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Pet Room'), findsNothing);
    });

    testWidgets(
        'test_parentView_redirect_navigates_to_parent_dashboard_distinct_from_childSelected',
        (tester) async {
      final mockAuth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
        ],
      );
      addTearDown(container.dispose);

      final routerSubscription = container.listen(routerProvider, (_, __) {});
      addTearDown(routerSubscription.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: routerSubscription.read()),
        ),
      );
      await tester.pumpAndSettle();

      await mockAuth.signInWithEmailAndPassword(
        email: 'parent@example.com',
        password: 'irrelevant-for-this-test',
      );
      container.read(activeChildProvider.notifier).state = const ChildProfile(
        childId: 'child-1',
        name: 'Bé An',
        avatarId: 'avatar-1',
        mochiName: 'Mochi',
      );
      await _pumpBoundedSteps(tester);
      expect(find.text('Pet Room'), findsOneWidget);

      // parentView -> real navigation into /parent/dashboard (ADR-0014
      // Decision §5), a distinct code path from childSelected's /child/*
      // branch verified above.
      container.read(parentOverrideProvider.notifier).state = true;
      await _pumpBoundedSteps(tester);
      expect(find.text('Parent Dashboard'), findsOneWidget);
      expect(find.text('Pet Room'), findsNothing);
    });
  });
}
