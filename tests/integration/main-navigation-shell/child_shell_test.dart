// Run with:
//   cd src && flutter test ../tests/integration/main-navigation-shell/child_shell_test.dart
//
// Story 002 (Child Shell — 3-Tab StatefulShellRoute & Flame State
// Preservation, main-navigation-shell epic) — covers this story's own 6
// acceptance criteria, one test function per AC (per its Test Evidence
// section): AC-3 (nav bar rendering), AC-4 (tab switch <200ms), AC-5 (the
// critical one — Flame game-loop survival across an offstage round-trip),
// AC-12 (sub-screen back), touch-target/no-op re-tap, and
// `activeChildBranchIndexProvider` correctness.
//
// Reuses the exact container/pump setup pattern from
// `root_redirect_test.dart` in this same directory: `MockFirebaseAuth` + a
// minimal Firestore fake so `childProfilesProvider` resolves without
// touching a real backend, an explicit `container.listen(routerProvider,
// ...)` kept open for the test's duration (riverpod 3.3.2 gotcha — a
// one-time `container.read(routerProvider)` does NOT keep
// `authStateProvider`'s underlying stream subscription live), and driving
// `MockFirebaseAuth`'s real `authStateChanges()` stream + `activeChildProvider`
// to reach `SessionState.childSelected` -> `/child/pet-room`.
//
// A real gotcha specific to THIS file (not present in `root_redirect_test.dart`,
// which never reaches a route that mounts a `GameWidget`): once Pet Room's
// `GameWidget<PetRoomGame>` mounts, its `GameLoop` keeps a raw `Ticker`
// continuously re-scheduling frames for as long as the widget tree is
// mounted (by design — ADR-0014 Decision §2, this story's whole point). That
// means `SchedulerBinding.instance.hasScheduledFrame` never goes false again,
// so `tester.pumpAndSettle()` would loop until it hits its internal iteration
// cap and throw "pumpAndSettle timed out". Every test below therefore uses
// `pumpAndSettle()` only for the pre-child-selection part of the flow
// (login/select-child transitions, which have no active Ticker) and switches
// to the bounded `_pumpSteps` helper (mirroring
// `mochi_component_background_pause_real_ticker_test.dart`'s
// `_pumpRealTicker`, same underlying reason) for everything from the moment
// `activeChildProvider` is set onward.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/gameplay/pet_room_game.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';

/// Minimal Firestore fake — only needed so `childProfilesProvider`
/// (transitively watched along the `parentAuthed` path) resolves without
/// touching a real backend; no test here asserts on Firestore content.
/// Duplicated from `root_redirect_test.dart` (private classes can't be
/// shared across test files).
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
/// moment Pet Room mounts. A single no-data snapshot (never erroring, never
/// completing) is enough here — no test in this file asserts on xu/seed
/// content, and both providers already default a missing document to `0`
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
/// Room's `GameWidget` has mounted.
Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

/// Drives a fresh app through unauthenticated -> parentAuthed -> childSelected,
/// landing on `/child/pet-room` (the Child Shell's default route), and
/// returns the [ProviderContainer] backing it. Every caller becomes
/// responsible for using [_pumpSteps] (never `pumpAndSettle()`) from this
/// point onward, per this file's header comment.
Future<ProviderContainer> _reachChildPetRoom(WidgetTester tester) async {
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
  // /child/pet-room, mounting PetRoomScreen's GameWidget<PetRoomGame> and
  // starting its GameLoop's Ticker.
  await _pumpSteps(tester, 6);

  return container;
}

/// Reads the currently-mounted `GameWidget<PetRoomGame>`'s `game` — the test
/// seam for AC-5: a real engine-object reference read via the standard
/// widget-tree inspection API, not a UI-visible proxy (Implementation Note 5).
PetRoomGame _currentPetRoomGame(WidgetTester tester) =>
    tester.widget<GameWidget<PetRoomGame>>(find.byType(GameWidget<PetRoomGame>)).game!;

void main() {
  testWidgets('test_AC3_navBarRendersThreeTabs_and_initialRouteIsChildPetRoom',
      (tester) async {
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childPetRoom,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Nhà'), findsOneWidget);
    expect(find.text('Nhiệm vụ'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    // Retained marker (AppBar title) — see PetRoomScreen's doc comment —
    // proves the router really reached this route, not just that the
    // NavigationBar rendered.
    expect(find.text('Pet Room'), findsOneWidget);

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);
  });

  testWidgets(
      'test_AC4_tapTasksTab_navigatesToChildTasks_within200ms_homeTabInactive',
      (tester) async {
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);

    await tester.tap(find.text('Nhiệm vụ'));
    // childShellRoute's branches use plain `builder:` (ADR-0014 Decision
    // §2's own code sample — no `pageBuilder`/`CustomTransitionPage`), so
    // the branch switch is an immediate IndexedStack index change, not an
    // animated page transition. A single 16ms frame is already well within
    // AC-4's 200ms budget.
    await _pumpSteps(tester, 1);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasks,
    );
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 1, reason: '"Nhà" (index 0) must no longer be active');
  });

  testWidgets(
      'test_AC5_sameFlameGameInstance_survives_offstage_branch_switch_and_keeps_ticking',
      (tester) async {
    await _reachChildPetRoom(tester);

    final game1 = _currentPetRoomGame(tester);
    await _pumpSteps(tester, 3);
    final tick0 = game1.updateTickCount;
    expect(
      tick0,
      greaterThan(0),
      reason: 'the GameLoop ticker should already be running while Pet Room is onstage',
    );

    // Switch away. StatefulShellRoute.indexedStack's branch container wraps
    // the now-inactive Pet Room branch in
    // Offstage(offstage: true, child: TickerMode(enabled: false, ...)) — but
    // Flame's GameLoop drives itself via a raw Ticker(_tick) constructed
    // directly, never through a TickerProvider, so TickerMode(enabled: false)
    // never gates it (ADR-0014 Decision §2; confirmed against installed
    // flame-1.37.0/go_router-17.3.0/Flutter 3.44.4 source during this
    // story's flame-specialist consultation).
    await tester.tap(find.text('Nhiệm vụ'));
    await _pumpSteps(tester, 3);

    // QA edge case: cycle through all 3 branches before returning to Pet
    // Room — the instance must still be the same one.
    await tester.tap(find.text('Shop'));
    await _pumpSteps(tester, 3);

    final tickWhileOffstage = game1.updateTickCount;
    expect(
      tickWhileOffstage,
      greaterThan(tick0),
      reason: 'update(dt) must keep incrementing while the Pet Room branch is '
          'offstage — this is AC-5\'s core claim, not just object survival',
    );

    // Switch back to Pet Room.
    await tester.tap(find.text('Nhà'));
    await _pumpSteps(tester, 2);

    final game2 = _currentPetRoomGame(tester);
    expect(
      identical(game1, game2),
      isTrue,
      reason: 'the SAME FlameGame instance must be observed, not a new one, '
          'after a full offstage round-trip through all 3 branches',
    );
    expect(
      game2.updateTickCount,
      greaterThanOrEqualTo(tickWhileOffstage),
      reason: 'the tick counter must not have been reset — proves no rebuild/dispose occurred',
    );
  });

  testWidgets('test_AC12_backPress_onNewTaskScreen_returnsToChildTasks_notPetRoom',
      (tester) async {
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);

    await tester.tap(find.text('Nhiệm vụ'));
    await _pumpSteps(tester, 1);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasks,
    );

    // Reached as a sub-navigation via push (same pattern as pinEntry's own
    // documented reach-via-push convention in AppRoutes), not a
    // session-state transition of its own.
    router.go(AppRoutes.childTasksNew);
    await _pumpSteps(tester, 2);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasksNew,
    );
    expect(find.text('New Task'), findsOneWidget);

    // Simulates back-press the way a real system back gesture/AppBar back
    // arrow actually triggers it: NewTaskScreen's default
    // `PopScope(canPop: true)` (Implementation Note 6, no custom
    // `onPopInvokedWithResult`) lets a plain `Navigator.maybePop` proceed,
    // which resolves against the NEAREST Navigator ancestor — the Tasks
    // branch's own branch-scoped Navigator (built by
    // `StatefulShellRoute.indexedStack` per branch), not the app's root
    // Navigator. `GoRouter.of(context).pop()` was tried first and did not
    // reproduce this (it operates on the router's top-level match state,
    // which does not represent this nested sub-route as a separate
    // top-level entry) — `Navigator.maybePop` is the mechanism that actually
    // matches real back-button behavior here.
    await Navigator.maybePop(tester.element(find.text('New Task')));
    // The pop's exit transition (default MaterialPage/CupertinoPage
    // platform transition — no custom pageBuilder was used for this nested
    // route) takes real frames to finish removing NewTaskScreen's Element
    // from the tree, even though go_router's own tracked location updates
    // as soon as the pop is processed. More steps than elsewhere in this
    // file for that reason.
    await _pumpSteps(tester, 20);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasks,
      reason: 'back from /child/tasks/new must land on /child/tasks, NOT /child/pet-room',
    );
    expect(find.text('New Task'), findsNothing);
  });

  testWidgets(
      'test_touchTarget_meetsMinimum_and_reTapOnActiveTab_isNoOp_noStackedPush',
      (tester) async {
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);

    // Touch target: each of the 3 destinations must be at least 48x48dp.
    final navBarSize = tester.getSize(find.byType(NavigationBar));
    expect(navBarSize.height, greaterThanOrEqualTo(48));
    expect(
      navBarSize.width / 3,
      greaterThanOrEqualTo(48),
      reason: '3 equally-sized destinations share the NavigationBar\'s width',
    );

    final gameBefore = _currentPetRoomGame(tester);
    final locationBefore = router.routerDelegate.currentConfiguration.uri.toString();
    final depthBefore = router.routerDelegate.currentConfiguration.matches.length;

    // Re-tap the already-active "Nhà" tab.
    await tester.tap(find.text('Nhà'));
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
    // Strongest proof of "no-op": the SAME FlameGame instance, not
    // torn down and rebuilt, by the re-tap.
    expect(identical(_currentPetRoomGame(tester), gameBefore), isTrue);
  });

  testWidgets(
      'test_activeChildBranchIndexProvider_updatesSynchronouslyWithGoBranch',
      (tester) async {
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);
    expect(container.read(activeChildBranchIndexProvider), 0);

    // `goBranch(1, ...)` and the `activeChildBranchIndexProvider` write both
    // happen synchronously inside the same `onDestinationSelected` handler,
    // with no `await` between them (ADR-0014 Decision §4) — and
    // `tester.tap()` fully dispatches the down+up gesture (including
    // invoking the resulting tap callback) before returning, so the
    // provider's new value is already observable here, with no `pump()`
    // needed in between — proving there is no window where one updated and
    // the other hadn't.
    await tester.tap(find.text('Nhiệm vụ'));
    expect(container.read(activeChildBranchIndexProvider), 1);

    await _pumpSteps(tester, 1);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasks,
    );
  });

  testWidgets('test_AC4_rapidDoubleTapOnTargetTab_doesNotDoubleNavigate',
      (tester) async {
    // Story's own documented AC-4 edge case ("rapid double-tap on the
    // target tab — must not double-navigate") — distinct from the
    // already-active-tab no-op test above: this taps a tab that is NOT yet
    // active, twice in a row, before either tap's goBranch/route-match has
    // had a chance to settle (found missing in code review's QA
    // testability pass).
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);
    final depthBefore = router.routerDelegate.currentConfiguration.matches.length;

    await tester.tap(find.text('Nhiệm vụ'));
    await tester.tap(find.text('Nhiệm vụ'));
    await _pumpSteps(tester, 1);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasks,
    );
    expect(
      router.routerDelegate.currentConfiguration.matches.length,
      depthBefore,
      reason: 'a branch switch (via goBranch) is a sibling swap, not a '
          'stack push — depth must stay the same after the double-tap, not '
          'grow, proving no stacked double-navigate occurred',
    );
  });

  testWidgets(
      'test_deepLinkDirectlyToNonDefaultBranch_rendersCorrectBranch_and_syncsProviderIndex',
      (tester) async {
    // ADR-0014 Risks: "the implementing story must test
    // deep-link-to-non-default-branch explicitly" — found missing in code
    // review's QA testability pass, which also flagged a real latent gap
    // this test exercises: activeChildBranchIndexProvider was previously
    // written ONLY by the bottom-nav tap handler, so a route landing on a
    // non-default branch WITHOUT a tap (cold-start deep link, restored
    // navigation state) would have left it silently stuck at its default 0
    // even though NavigationBar.selectedIndex (reading
    // navigationShell.currentIndex directly) looked correct regardless.
    // Fixed via ChildShellScaffold's initState/didUpdateWidget sync.
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

    final router = container.read(routerProvider);
    container.read(activeChildProvider.notifier).state = const ChildProfile(
      childId: 'child-1',
      name: 'Bé An',
      avatarId: 'avatar-1',
      mochiName: 'Mochi',
    );
    // Deep-link straight to the Shop branch (index 2) instead of letting
    // the redirect default to /child/pet-room (index 0) and tapping
    // through — simulates a cold-start deep link / restored nav state.
    router.go(AppRoutes.childShop);
    await _pumpSteps(tester, 6);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childShop,
    );
    expect(find.text('Shop'), findsWidgets);

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 2);
    expect(
      container.read(activeChildBranchIndexProvider),
      2,
      reason: 'activeChildBranchIndexProvider must reflect the branch '
          'actually reached via deep link, not just nav-bar taps',
    );
  });
}
