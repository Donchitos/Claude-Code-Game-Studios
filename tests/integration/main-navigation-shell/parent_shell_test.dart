// Run with:
//   cd src && flutter test ../tests/integration/main-navigation-shell/parent_shell_test.dart
//
// Story 003 (Parent Shell — 2-Tab StatefulShellRoute, main-navigation-shell
// epic) — covers this story's own 6 acceptance criteria, one test function
// per AC (per its Test Evidence section): AC-1 (2-tab render, default
// route), AC-2 (tab switch <200ms), AC-3 (no floating chips), AC-4 (state
// preservation across tabs), AC-5 (`activeChildBranchIndexProvider`
// correctness, Parent Shell's own 0-1 index space, synced on both tap and
// initial/non-tap mount), and touch-target/no-op re-tap.
//
// Reuses the exact container/pump setup pattern from
// `child_shell_test.dart`/`root_redirect_test.dart` in this same directory:
// `MockFirebaseAuth` + a minimal Firestore fake so `childProfilesProvider`
// resolves without touching a real backend, an explicit
// `container.listen(routerProvider, ...)` kept open for the test's duration
// (riverpod 3.3.2 gotcha), and driving `MockFirebaseAuth`'s real
// `authStateChanges()` stream + `activeChildProvider` + `parentOverrideProvider`
// to reach `SessionState.parentView` -> `/parent/dashboard`.
//
// Reaching `parentView` requires going through `childSelected` FIRST
// (`sessionStateProvider`'s own derivation: `parentView` = `activeChild !=
// null && parentOverrideProvider == true` — see `auth_providers.dart`), which
// briefly mounts Pet Room's `GameWidget<PetRoomGame>` en route. That widget's
// `GameLoop` keeps a raw `Ticker` continuously re-scheduling frames for as
// long as it stays mounted (ADR-0014 Decision §2 — the same mechanism
// `child_shell_test.dart` exercises directly), which makes
// `tester.pumpAndSettle()` loop forever from that point on. Matching the
// established pattern already used for this exact transition in
// `root_redirect_test.dart`'s `test_parentView_redirect_navigates_to_parent_dashboard_distinct_from_childSelected`
// test, every pump from the moment `activeChildProvider` is set onward in
// this file uses the bounded-step `_pumpSteps` helper instead of
// `pumpAndSettle()` — including after `/parent/dashboard` is reached, since
// this file does not independently verify Pet Room's ticker stops cleanly
// once navigated away from (that cross-shell survival question is Story
// 004's scope, not this story's).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/parent_dashboard_tasks_tab.dart';

/// Minimal Firestore fake — only needed so `childProfilesProvider`
/// (transitively watched along the `parentAuthed` path) resolves without
/// touching a real backend; no test here asserts on Firestore content.
/// Duplicated from `child_shell_test.dart`/`root_redirect_test.dart`
/// (private classes can't be shared across test files).
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
/// moment Pet Room mounts en route to `parentView` (this file's own header
/// comment). A single no-data snapshot (never erroring, never completing) is
/// enough here — no test in this file asserts on xu/seed content, and both
/// providers already default a missing document to `0`
/// (`currency_providers.dart`/`seed_buffer_providers.dart`).
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

/// Pumps [steps] small, fixed-size frames instead of `pumpAndSettle()` — see
/// this file's header comment for why `pumpAndSettle()` is unsafe once Pet
/// Room's `GameWidget` has mounted en route to `parentView`.
Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

/// Drives a fresh app through unauthenticated -> parentAuthed -> childSelected
/// -> parentView, landing on `/parent/dashboard` (the Parent Shell's default
/// route), and returns the [ProviderContainer] backing it. Every caller
/// becomes responsible for using [_pumpSteps] (never `pumpAndSettle()`) from
/// this point onward, per this file's header comment.
Future<ProviderContainer> _reachParentDashboard(WidgetTester tester) async {
  final mockAuth = MockFirebaseAuth();
  final container = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(mockAuth),
      firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
    ],
  );
  addTearDown(container.dispose);

  final routerSubscription = container.listen(routerProvider, (_, _) {});
  addTearDown(routerSubscription.close);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: routerSubscription.read()),
    ),
  );
  // Safe: no GameWidget/Ticker exists yet at /login.
  await tester.pumpAndSettle();

  await mockAuth.signInWithEmailAndPassword(
    email: 'parent@example.com',
    password: 'irrelevant-for-this-test',
  );
  // Still safe: /select-child has no GameWidget/Ticker either.
  await tester.pumpAndSettle();

  container.read(activeChildProvider.notifier).state = const ChildProfile(
    childId: 'child-1',
    name: 'Bé An',
    avatarId: 'avatar-1',
    mochiName: 'Mochi',
  );
  // From here on: bounded steps only. This redirect lands on
  // /child/pet-room first (childSelected), mounting PetRoomScreen's
  // GameWidget<PetRoomGame> and starting its GameLoop's Ticker.
  await _pumpSteps(tester, 6);

  // parentOverrideProvider = true flips sessionState to parentView; the
  // redirect (via the ref.listen refresh bridge) then navigates to
  // /parent/dashboard, this story's real parentShellRoute. childShellRoute
  // and parentShellRoute are separate top-level routes in the same
  // Navigator, so this is a real page transition (Child Shell's page
  // animating out, Parent Shell's animating in) — both remain mounted
  // simultaneously (found empirically: two `NavigationBar`s coexist,
  // Child Shell's un-themed one and Parent Shell's `NavigationBarTheme`-
  // wrapped one) until the platform-default MaterialPage transition
  // finishes. More/longer steps than the child-only helpers in
  // `child_shell_test.dart` for that reason — mirrors the same "transition
  // needs real frames to finish removing the old page's Element" note on
  // `test_AC12_backPress_onNewTaskScreen_returnsToChildTasks_notPetRoom`
  // there.
  container.read(parentOverrideProvider.notifier).state = true;
  await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

  return container;
}

void main() {
  testWidgets(
      'test_AC1_parentShellRenders2Tabs_and_defaultRouteIsParentDashboard',
      (tester) async {
    final container = await _reachParentDashboard(tester);
    final router = container.read(routerProvider);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentDashboard,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    // Updated for Parent Dashboard UI Story 001: `ParentDashboardTasksTab`'s
    // app bar title is now the real "Nhiệm vụ" (matching
    // design/ux/parent-dashboard-ui.md), which is the SAME string as this
    // NavigationBar destination's own label — so `find.text('Nhiệm vụ')` now
    // legitimately matches 2 widgets (the tab label + the app bar title) on
    // this tab, not 1. Scoped to the NavigationBar specifically to keep
    // asserting the tab-label part of the original intent unambiguously.
    expect(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('Nhiệm vụ')),
      findsOneWidget,
    );
    expect(find.text('Gia đình'), findsOneWidget);
    // The route URI (above) is what actually proves the router reached this
    // route — the old literal `Text('Parent Dashboard')` marker this
    // assertion used to check no longer exists (superseded by the tab's real
    // "Nhiệm vụ" title, see ParentDashboardTasksTab's own doc comment). Also
    // updated in the 2 sibling regression files that used the same marker
    // (root_redirect_test.dart, auth_account/router_redirect_test.dart).
    expect(find.text('Nhiệm vụ'), findsNWidgets(2),
        reason: 'app bar title + NavigationBar destination label both read '
            '"Nhiệm vụ" while on this tab');

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);
  });

  testWidgets(
      'test_AC2_tapGiaDinhTab_navigatesToParentFamily_within200ms_dashboardTabInactive',
      (tester) async {
    final container = await _reachParentDashboard(tester);
    final router = container.read(routerProvider);

    await tester.tap(find.text('Gia đình'));
    // parentShellRoute's branches use plain `builder:` (ADR-0014 Decision
    // §3's own code sample — no `pageBuilder`/`CustomTransitionPage`), so
    // the branch switch is an immediate IndexedStack index change, not an
    // animated page transition. A single 16ms frame is already well within
    // AC-2's 200ms budget.
    await _pumpSteps(tester, 1);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentFamily,
    );
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 1,
        reason: '"Nhiệm vụ" (index 0) must no longer be active');
  });

  testWidgets('test_AC2_rapidDoubleTapOnTargetTab_doesNotDoubleNavigate',
      (tester) async {
    // Same regression class as Story 002's own documented AC-4 edge case
    // (child_shell_test.dart's test_AC4_rapidDoubleTapOnTargetTab_...) —
    // this story's onDestinationSelected uses the identical
    // goBranch+provider-write pattern, so the same double-tap risk applies
    // here (found missing in code review).
    final container = await _reachParentDashboard(tester);
    final router = container.read(routerProvider);
    final depthBefore = router.routerDelegate.currentConfiguration.matches.length;

    await tester.tap(find.text('Gia đình'));
    await tester.tap(find.text('Gia đình'));
    await _pumpSteps(tester, 1);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentFamily,
    );
    expect(
      router.routerDelegate.currentConfiguration.matches.length,
      depthBefore,
      reason: 'a branch switch is a sibling swap, not a stack push — depth '
          'must stay the same after the double-tap, not grow, proving no '
          'stacked double-navigate occurred',
    );
  });

  testWidgets(
      'test_AC3_noFloatingChips_topZoneEmpty_onBothTabs',
      (tester) async {
    await _reachParentDashboard(tester);

    // ParentShellScaffold.build passes `body: widget.navigationShell`
    // directly to Scaffold — unlike ChildShellScaffold, which wraps it in
    // `Stack(children: [navigationShell])` reserved for its floating chip
    // cluster (see that class's doc comment). Asserting `find.byType(Stack)
    // findsNothing` globally is not viable: Flutter/Material's own internals
    // (NavigationDestination's selection-animation machinery, MaterialApp's
    // Overlay, etc.) legitimately use `Stack` widgets regardless of this
    // story's code, so that assertion would fail even with zero chips
    // (confirmed empirically — 17 unrelated `Stack`s present). Instead,
    // assert the STRUCTURAL fact this story's Implementation Note 2 actually
    // requires: `ParentShellScaffold`'s own `Scaffold.body` is the
    // `StatefulNavigationShell` itself, not wrapped in any overlay
    // container — the only insertion point a future chip cluster could have
    // used, and it's absent.
    final scaffold = tester.widget<Scaffold>(
      find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(Scaffold),
      ).first,
    );
    expect(
      scaffold.body,
      isA<StatefulNavigationShell>(),
      reason: 'Parent Shell has no floating chip cluster (GDD Core Rule 5) — '
          'Scaffold.body must be the navigationShell directly, not wrapped '
          'in a Stack/overlay container, on the Dashboard tab',
    );

    await tester.tap(find.text('Gia đình'));
    await _pumpSteps(tester, 1);

    final scaffoldAfter = tester.widget<Scaffold>(
      find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(Scaffold),
      ).first,
    );
    expect(
      scaffoldAfter.body,
      isA<StatefulNavigationShell>(),
      reason: 'same assertion on the Family tab — no chips on ANY Parent '
          'Shell tab, per this story\'s Implementation Note 2',
    );
  });

  testWidgets(
      'test_AC4_statePreservationAcrossTabs_dashboardStateSurvivesRoundTrip',
      (tester) async {
    await _reachParentDashboard(tester);

    final stateBefore = tester.state<ParentDashboardTasksTabState>(
      find.byType(ParentDashboardTasksTab),
    );
    expect(
      stateBefore.initCount,
      1,
      reason: 'initState runs exactly once on first mount',
    );

    // Switch away and back — StatefulShellRoute.indexedStack must keep the
    // Dashboard branch's widget subtree alive (never disposed) the whole
    // time, same convention as Child Shell's Pet Room branch (AC-5 there).
    await tester.tap(find.text('Gia đình'));
    await _pumpSteps(tester, 2);
    await tester.tap(find.text('Nhiệm vụ'));
    await _pumpSteps(tester, 2);

    final stateAfter = tester.state<ParentDashboardTasksTabState>(
      find.byType(ParentDashboardTasksTab),
    );
    expect(
      identical(stateBefore, stateAfter),
      isTrue,
      reason: 'the SAME State instance must be observed, not a new one, '
          'after a full round-trip through the Family tab — proves no '
          'rebuild/dispose occurred',
    );
    expect(
      stateAfter.initCount,
      1,
      reason: 'initCount must not have been incremented again — proves '
          'initState was not re-run',
    );
  });

  testWidgets(
      'test_AC5_activeChildBranchIndexProvider_onlyTakes0Or1_syncedOnTapAndOnNonTapNavigation',
      (tester) async {
    final container = await _reachParentDashboard(tester);
    final router = container.read(routerProvider);

    // Landed on the default branch (index 0) without any tap — initState's
    // own sync (or the shared default value) already agrees.
    expect(container.read(activeChildBranchIndexProvider), 0);

    // Tap-driven sync: goBranch(1, ...) and the provider write both happen
    // synchronously inside the same onDestinationSelected handler, with no
    // await between them (ADR-0014 Decision §4) — and tester.tap() fully
    // dispatches the tap callback before returning, so the new value is
    // already observable here with no pump() needed (mirrors Story 002's
    // own `test_activeChildBranchIndexProvider_updatesSynchronouslyWithGoBranch`).
    await tester.tap(find.text('Gia đình'));
    expect(
      container.read(activeChildBranchIndexProvider),
      1,
      reason: 'tap-driven sync: must update synchronously, in Parent '
          'Shell\'s own 0-1 index space',
    );
    await _pumpSteps(tester, 1);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentFamily,
    );

    // Non-tap-driven sync: navigate directly via router.go() (simulating a
    // deep link / restored navigation state landing on a non-default branch
    // WITHOUT going through the bottom-nav tap handler) — same regression
    // class Story 002's code review found and fixed via
    // ChildShellScaffold.didUpdateWidget; reproduced here for Parent Shell.
    // Force back to the default branch first so the subsequent go() is a
    // real transition, not a no-op.
    router.go(AppRoutes.parentDashboard);
    await _pumpSteps(tester, 2);
    expect(container.read(activeChildBranchIndexProvider), 0);

    router.go(AppRoutes.parentFamily);
    await _pumpSteps(tester, 2);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentFamily,
    );
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 1);
    expect(
      container.read(activeChildBranchIndexProvider),
      1,
      reason: 'activeChildBranchIndexProvider must reflect the branch '
          'actually reached via router.go(), not just nav-bar taps — proves '
          'ParentShellScaffold.didUpdateWidget\'s sync fires here too',
    );
  });

  testWidgets(
      'test_AC5_crossShellHandoff_staleChildShellIndexOverwrittenOnParentEntry',
      (tester) async {
    // AC-5's own criterion text exists specifically to guard against
    // confusing Parent Shell's 0-1 index space with Child Shell's 0-2 space
    // (activeChildBranchIndexProvider is SHARED between both shells per
    // ADR-0014 Decision §4). Drives the provider to a Child-Shell-only
    // value (2, via Shop) before transitioning into Parent Shell, and
    // proves ParentShellScaffold.initState's sync overwrites it rather than
    // leaving a stale cross-shell value visible — found missing in code
    // review (the test above only ever transitions while the provider is
    // still at its untouched default 0).
    final mockAuth = MockFirebaseAuth();
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
      ],
    );
    addTearDown(container.dispose);

    final routerSubscription = container.listen(routerProvider, (_, _) {});
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
    await tester.pumpAndSettle();

    container.read(activeChildProvider.notifier).state = const ChildProfile(
      childId: 'child-1',
      name: 'Bé An',
      avatarId: 'avatar-1',
      mochiName: 'Mochi',
    );
    // Lands on /child/pet-room (Child Shell), mounting Pet Room's GameWidget.
    await _pumpSteps(tester, 6);

    // Set the shared provider to a Child-Shell-only value (2 = Shop) via a
    // real tap, same as any child would do before a parent override.
    await tester.tap(find.text('Shop'));
    await _pumpSteps(tester, 2);
    expect(container.read(activeChildBranchIndexProvider), 2);

    // Transition into Parent Shell.
    container.read(parentOverrideProvider.notifier).state = true;
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      AppRoutes.parentDashboard,
    );
    expect(
      container.read(activeChildBranchIndexProvider),
      0,
      reason: 'entering Parent Shell must overwrite the stale '
          'Child-Shell-only value (2) with this shell\'s own current index '
          '(0) — not leave the cross-shell value in place',
    );
  });

  testWidgets(
      'test_touchTarget_meetsMinimum_and_reTapOnActiveTab_isNoOp_noStackedPush',
      (tester) async {
    final container = await _reachParentDashboard(tester);
    final router = container.read(routerProvider);

    // Touch target: each of the 2 destinations must be at least 48x48dp.
    final navBarSize = tester.getSize(find.byType(NavigationBar));
    expect(navBarSize.height, greaterThanOrEqualTo(48));
    expect(
      navBarSize.width / 2,
      greaterThanOrEqualTo(48),
      reason: '2 equally-sized destinations share the NavigationBar\'s width',
    );

    final stateBefore = tester.state<ParentDashboardTasksTabState>(
      find.byType(ParentDashboardTasksTab),
    );
    final locationBefore = router.routerDelegate.currentConfiguration.uri.toString();
    final depthBefore = router.routerDelegate.currentConfiguration.matches.length;

    // Re-tap the already-active "Nhiệm vụ" tab. Scoped to the NavigationBar
    // specifically (not a bare `find.text('Nhiệm vụ')`) since Parent
    // Dashboard UI Story 001 gave the tab's own app bar the same "Nhiệm vụ"
    // title as this NavigationBar destination's label — an unscoped finder
    // would now ambiguously match both and `tester.tap()` would throw.
    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('Nhiệm vụ')),
    );
    await _pumpSteps(tester, 2);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      locationBefore,
      reason: 're-tapping the active tab must not navigate anywhere new',
    );
    expect(
      router.routerDelegate.currentConfiguration.matches.length,
      depthBefore,
      reason: 're-tapping the active tab must not create a stacked navigation push',
    );
    // Strongest proof of "no-op": the SAME State instance, not torn down
    // and rebuilt, by the re-tap (same spirit as Story 002's identical
    // FlameGame-instance re-tap proof).
    final stateAfter = tester.state<ParentDashboardTasksTabState>(
      find.byType(ParentDashboardTasksTab),
    );
    expect(identical(stateAfter, stateBefore), isTrue);
    expect(stateAfter.initCount, 1);
  });
}
