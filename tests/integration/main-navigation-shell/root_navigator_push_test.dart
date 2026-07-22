// Run with:
//   cd src && flutter test ../tests/integration/main-navigation-shell/root_navigator_push_test.dart
//
// Story 005 (Child Back-Button Exit Dialog & Root-Navigator Push Contract,
// main-navigation-shell epic) — covers this story's own scope: AC-10 (the
// kid-styled "Thoát PetQuest?" exit-confirm dialog on Child Shell tab-root
// back-press), the "dialog only on tab roots, not sub-screens" acceptance
// criterion (AC-2's collision-avoidance case), the "Parent tab root, NOT in
// override — no dialog" acceptance criterion, and AC-3 (the root-navigator
// push contract for future non-dismissible ceremony overlays).
//
// Reuses the exact container/pump setup pattern from
// `child_shell_test.dart`/`parent_shell_test.dart`/`parent_override_test.dart`
// in this same directory: `MockFirebaseAuth` + a minimal Firestore fake so
// `childProfilesProvider` resolves without touching a real backend, an
// explicit `container.listen(routerProvider, ...)` kept open for the test's
// duration (riverpod 3.3.2 gotcha), and the bounded-step `_pumpSteps` helper
// instead of `pumpAndSettle()` from the moment `activeChildProvider` is set
// onward (Pet Room's `GameWidget` keeps a raw `Ticker` perpetually scheduled
// once mounted — see those files' own header comments for the full
// rationale).
//
// Back-press is simulated via `tester.binding.handlePopRoute()` — the same
// `@visibleForTesting` seam `parent_override_test.dart`'s own
// `test_AC13_backPressWhileInOverride_...` test already uses to reach a real
// `PopScope.onPopInvokedWithResult` (a plain `Navigator.maybePop(context)`
// call, by contrast, resolves against whichever Navigator `context` happens
// to be nearest to, which is NOT how a real system back-button press is
// dispatched through go_router's `GoRouterDelegate.popRoute()` — see
// `child_shell_scaffold.dart`'s own doc comment for the full trace against
// installed `go_router-17.3.0` source). This file empirically verifies —
// rather than just assumes from reading that source — that a single
// shell-level `PopScope` in `ChildShellScaffold` cannot collide with
// `NewTaskScreen`'s own `PopScope(canPop: true)` (Story 002,
// `new_task_screen.dart`), per this story's explicit instruction not to
// assume that interaction.
//
// Intentionally NOT tested (considered, not overlooked — found in code
// review): back-press arriving mid-branch-switch-transition. Child Shell's
// branches live in one `StatefulShellRoute.indexedStack` with no animated
// push/pop between them (an instant `IndexedStack` index swap, per Story
// 002), so there is no page-transition window for a pop to land in mid-flight
// the way there would be for a stacked route push — this edge case doesn't
// structurally exist for this router shape.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/child_shell_scaffold.dart';
import 'package:pet_quest/ui/exit_confirm_dialog.dart';
import 'package:pet_quest/ui/root_navigator_push.dart';

/// Minimal Firestore fake — only needed so `childProfilesProvider`
/// (transitively watched along the `parentAuthed` path) resolves without
/// touching a real backend; no test here asserts on Firestore content.
/// Duplicated from sibling files in this directory (private classes can't be
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

const _activeChild = ChildProfile(
  childId: 'child-1',
  name: 'Bé An',
  avatarId: 'avatar-1',
  mochiName: 'Mochi',
);

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
/// landing on `/child/pet-room` (the Child Shell's default route, a tab
/// root), and returns the [ProviderContainer] backing it. Every caller
/// becomes responsible for using [_pumpSteps] (never `pumpAndSettle()`) from
/// this point onward, per this file's header comment.
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

  container.read(activeChildProvider.notifier).state = _activeChild;
  // From here on: bounded steps only. This redirect lands on
  // /child/pet-room, mounting PetRoomScreen's GameWidget<PetRoomGame> and
  // starting its GameLoop's Ticker.
  await _pumpSteps(tester, 6);

  return container;
}

/// Drives a fresh app all the way through Parent Override into
/// `/parent/dashboard` — mirrors `parent_shell_test.dart`'s own
/// `_reachParentDashboard` helper (duplicated here rather than shared;
/// private test helpers can't cross file boundaries).
Future<ProviderContainer> _reachParentDashboard(WidgetTester tester) async {
  final container = await _reachChildPetRoom(tester);
  container.read(parentOverrideProvider.notifier).state = true;
  // Real top-level page transition (childShellRoute -> parentShellRoute,
  // siblings in the root Navigator) — needs more/longer bounded steps to
  // settle, same convention as `parent_shell_test.dart`/`parent_override_test.dart`.
  await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));
  return container;
}

/// Registers a mock handler for `SystemChannels.platform` so
/// `SystemNavigator.pop()` (invoked, unawaited, from
/// `ChildShellScaffold`'s `PopScope.onPopInvokedWithResult` on confirmed
/// [Thoát]) resolves instead of throwing `MissingPluginException` in the
/// test environment. Returns the list of `'SystemNavigator.pop'` invocations
/// specifically — NOT every method call seen on this shared channel — since
/// `SystemChannels.platform` is also used for other, unrelated framework
/// concerns (e.g. `TextButton`/`FilledButton` tap feedback calls
/// `'SystemSound.play'` over this exact same channel, found empirically
/// while writing these tests); a raw unfiltered log would make "was
/// SystemNavigator.pop called" assertions fragile against any incidental
/// framework chatter unrelated to this story's own behavior.
List<String> _mockSystemNavigatorPop(WidgetTester tester) {
  final invoked = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') invoked.add(call.method);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return invoked;
}

/// Placeholder full-screen ceremony overlay — this story's Out of Scope note
/// explicitly excludes real ceremony content (Shop & Reward UI's future
/// epic); this exists only to exercise [pushNonDismissibleOverlay]'s
/// mechanism. Records taps via [onTap] so the AC-3 test can prove the pushed
/// overlay — not the `NavigationBar` underneath — actually receives pointer
/// events at the `NavigationBar`'s old screen position.
class _PlaceholderCeremonyOverlay extends StatelessWidget {
  const _PlaceholderCeremonyOverlay({required this.onTap});

  final VoidCallback onTap;

  static const overlayKey = Key('placeholderCeremonyOverlay');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: overlayKey,
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Opaque, not the GestureDetector default (`deferToChild`): the
        // child is a centered `Text` whose own hit-testable bounds are only
        // as big as the glyphs themselves, not the full screen — `opaque`
        // makes this GestureDetector's own full-size box (via
        // `SizedBox.expand`) the hit target, so ANY tap anywhere on screen
        // (including at the old NavigationBar's position, far from the
        // centered text) is captured. Found empirically: without this, the
        // AC-3 hit-test assertion below silently missed even though the
        // overlay was genuinely mounted and covering the screen.
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox.expand(
          child: Center(
            child: Text(
              'Placeholder Ceremony Overlay',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
      'test_AC3_rootNavigatorPush_pushedPlaceholderOverlay_coversBottomNavBar_hitTestUnreachable',
      (tester) async {
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);

    expect(find.byType(NavigationBar), findsOneWidget);
    // Captured BEFORE the push — the exact screen position the "Nhiệm vụ"
    // NavigationBar destination occupies.
    final tasksTabCenter = tester.getCenter(find.text('Nhiệm vụ'));
    final locationBefore = router.routerDelegate.currentConfiguration.uri.toString();

    var overlayTapCount = 0;
    final context = tester.element(find.byType(ChildShellScaffold));
    // Not awaited synchronously here (matches how a real caller would fire
    // this from a tap handler) — the push itself is what's under test, not
    // its eventual pop result.
    unawaited(
      pushNonDismissibleOverlay<void>(
        context,
        _PlaceholderCeremonyOverlay(onTap: () => overlayTapCount++),
      ),
    );
    // fullscreenDialog MaterialPageRoute's entrance transition needs real
    // frames to finish — same convention as other page-level transitions in
    // this test suite (parent_shell_test.dart's `_reachParentDashboard`).
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

    expect(
      find.byKey(_PlaceholderCeremonyOverlay.overlayKey),
      findsOneWidget,
      reason: 'the pushed overlay is actually on screen',
    );

    // Hit-test proof (not just visual/structural inspection, per this
    // story's AC-3 wording): tap at the exact screen position the "Nhiệm vụ"
    // destination occupied before the push. If the NavigationBar were still
    // reachable underneath, this would switch branches; a genuine
    // root-navigator push must intercept the tap instead.
    await tester.tapAt(tasksTabCenter);
    await _pumpSteps(tester, 2);

    expect(
      overlayTapCount,
      1,
      reason: 'a tap at the old NavigationBar position must be received by '
          'the pushed overlay, proving it physically covers that screen area',
    );
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      locationBefore,
      reason: 'the NavigationBar underneath must NOT have received the tap — '
          'the branch/route must be unchanged, proving it is untappable '
          'while the non-dismissible overlay is up',
    );
  });

  testWidgets('test_AC10_backPressOnPetRoomTabRoot_showsExitConfirmDialog',
      (tester) async {
    await _reachChildPetRoom(tester);
    _mockSystemNavigatorPop(tester);

    expect(find.text('Thoát PetQuest?'), findsNothing);

    await tester.binding.handlePopRoute();
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));

    expect(find.text('Thoát PetQuest?'), findsOneWidget);
    expect(find.byKey(ExitConfirmDialog.stayButtonKey), findsOneWidget);
    expect(find.byKey(ExitConfirmDialog.exitButtonKey), findsOneWidget);
  });

  testWidgets(
      'test_AC10_backPressOnEveryChildTabRoot_petRoomTasksShop_allShowExitDialog',
      (tester) async {
    // AC-10's own criterion text names all 3 tab roots explicitly
    // ("Pet Room/Tasks/Shop") — proves the single shell-level PopScope fires
    // uniformly across every branch, not just the default one.
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);
    _mockSystemNavigatorPop(tester);

    await tester.binding.handlePopRoute();
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));
    expect(find.text('Thoát PetQuest?'), findsOneWidget, reason: 'Pet Room tab root');
    await tester.tap(find.byKey(ExitConfirmDialog.stayButtonKey));
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));
    expect(find.text('Thoát PetQuest?'), findsNothing);

    await tester.tap(find.text('Nhiệm vụ'));
    await _pumpSteps(tester, 2);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasks,
    );
    await tester.binding.handlePopRoute();
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));
    expect(find.text('Thoát PetQuest?'), findsOneWidget, reason: 'Tasks tab root');
    await tester.tap(find.byKey(ExitConfirmDialog.stayButtonKey));
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));
    expect(find.text('Thoát PetQuest?'), findsNothing);

    await tester.tap(find.text('Shop'));
    await _pumpSteps(tester, 2);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childShop,
    );
    await tester.binding.handlePopRoute();
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));
    expect(find.text('Thoát PetQuest?'), findsOneWidget, reason: 'Shop tab root');
  });

  testWidgets(
      'test_AC10_oLaiButton_dismissesDialog_staysInApp_systemNavigatorPopNeverCalled',
      (tester) async {
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);
    final invoked = _mockSystemNavigatorPop(tester);

    await tester.binding.handlePopRoute();
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));
    expect(find.text('Thoát PetQuest?'), findsOneWidget);

    await tester.tap(find.byKey(ExitConfirmDialog.stayButtonKey));
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));

    expect(find.text('Thoát PetQuest?'), findsNothing);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childPetRoom,
      reason: 'staying must not navigate anywhere',
    );
    expect(
      invoked,
      isEmpty,
      reason: '[Ở lại] must never reach SystemNavigator.pop()',
    );
    // App did not exit — proven simply by the widget tree still being
    // pumpable/inspectable afterward (same precedent as
    // parent_override_test.dart's AC-13 test).
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('test_AC10_thoatButton_callsSystemNavigatorPop_exactlyOnce',
      (tester) async {
    await _reachChildPetRoom(tester);
    final invoked = _mockSystemNavigatorPop(tester);

    await tester.binding.handlePopRoute();
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));
    expect(find.text('Thoát PetQuest?'), findsOneWidget);

    await tester.tap(find.byKey(ExitConfirmDialog.exitButtonKey));
    // 10 steps @ 50ms (500ms) — AlertDialog's default show/dismiss
    // transition needs real frames to fully settle; 5 default-16ms steps
    // (80ms) was found empirically insufficient for the exit-dismiss case
    // (the dialog's Text widget was still present mid-animation).
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));

    expect(
      invoked,
      ['SystemNavigator.pop'],
      reason: '[Thoát] must call SystemNavigator.pop() exactly once',
    );
  });

  testWidgets(
      'test_AC10_backPressWhileDialogAlreadyOpen_doesNotStackSecondDialog',
      (tester) async {
    // exit_confirm_dialog.dart's own doc comment claims a second back-press
    // while the dialog is already open just closes the DialogRoute itself
    // (it becomes the topmost entry on the root Navigator, isFirst == false
    // there, so popDisposition == pop) rather than stacking a second exit
    // dialog or accidentally reaching SystemNavigator.pop() — asserted in a
    // comment, never verified by a test until now (found in code review's
    // QA testability pass, matching this story's own "verify, don't assume"
    // precedent already applied to the tab-root/sub-screen collision case).
    await _reachChildPetRoom(tester);
    final invoked = _mockSystemNavigatorPop(tester);

    await tester.binding.handlePopRoute();
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));
    expect(find.text('Thoát PetQuest?'), findsOneWidget);

    // Second back-press while the dialog is still showing.
    await tester.binding.handlePopRoute();
    await _pumpSteps(tester, 10, step: const Duration(milliseconds: 50));

    expect(
      find.text('Thoát PetQuest?'),
      findsNothing,
      reason: 'the second back-press closes the dialog itself (DialogRoute '
          'is topmost on the root Navigator), it does not stack a second '
          'dialog',
    );
    expect(
      invoked,
      isEmpty,
      reason: 'a back-press that only closes the dialog (resolving '
          'showDialog<bool> to null, treated as "stay" via ?? false) must '
          'never reach SystemNavigator.pop()',
    );
  });

  testWidgets(
      'test_AC2_backPressOnNewTaskScreen_doesNotShowExitDialog_returnsToChildTasksInstead',
      (tester) async {
    // This is the collision-avoidance case this story exists to prove is
    // safe: NewTaskScreen (`new_task_screen.dart`, Story 002) carries its
    // own PopScope(canPop: true) inside the Tasks branch's own nested
    // Navigator. A REAL simulated back-press (not a targeted
    // `Navigator.maybePop(context)` call, which would trivially only ever
    // exercise the nested Navigator by construction) must resolve to
    // NewTaskScreen's own handler and never fall through to
    // ChildShellScaffold's shell-level exit-confirm PopScope.
    final container = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);
    final invoked = _mockSystemNavigatorPop(tester);

    router.go(AppRoutes.childTasksNew);
    await _pumpSteps(tester, 2);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasksNew,
    );
    expect(find.text('New Task'), findsOneWidget);

    await tester.binding.handlePopRoute();
    // The pop's exit transition takes real frames to finish removing
    // NewTaskScreen's Element from the tree — found empirically to need
    // considerably more settle time than `child_shell_test.dart`'s own
    // AC-12 test (which pops via a direct `Navigator.maybePop(context)`
    // call, not the full `handlePopRoute()` -> `GoRouterDelegate.popRoute()`
    // -> `_findCurrentNavigators()` chain this test exercises): go_router's
    // own route match/state reconciliation (confirmed via debug output to
    // land on `/child/tasks` correctly well before the Element is actually
    // removed) completes first, then the platform page-transition's reverse
    // animation still has to run its course. 20 steps @ 50ms (1s) was
    // confirmed sufficient; the smaller default-16ms budget used elsewhere
    // in this file was not.
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasks,
      reason: 'back from /child/tasks/new must land on /child/tasks — Story '
          "002's own AC-12 behavior, unmodified by this story",
    );
    expect(find.text('New Task'), findsNothing);
    expect(
      find.text('Thoát PetQuest?'),
      findsNothing,
      reason: 'the exit-confirm dialog must NEVER appear for a sub-screen '
          'back-press — proves the two PopScopes did not collide',
    );
    expect(
      invoked,
      isEmpty,
      reason: 'no path here should ever reach SystemNavigator.pop()',
    );
  });

  testWidgets(
      'test_parentShell_backPress_neverShowsChildExitDialog_overrideExitHandlesItInstead',
      (tester) async {
    // AC "Parent tab root, NOT in override — no dialog": reaching Parent
    // Shell in this codebase always implies parentView (=override active,
    // per `parent_shell_scaffold.dart`'s own doc comment on why the
    // non-override case is structurally unreachable there) — this test
    // proves the kid-styled Child Shell dialog never leaks into Parent
    // Shell under the one reachable state, regardless. Parent Shell's own
    // override-exit PopScope (Story 004, untouched by this story) governs
    // back-press there instead — already covered end-to-end by
    // `parent_override_test.dart`'s own AC-13 test; this test only adds
    // this story's own explicit assertion from this story's own test file,
    // per its Test Evidence requirement.
    final container = await _reachParentDashboard(tester);
    final router = container.read(routerProvider);
    final invoked = _mockSystemNavigatorPop(tester);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentDashboard,
    );

    await tester.binding.handlePopRoute();
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

    expect(
      find.text('Thoát PetQuest?'),
      findsNothing,
      reason: "Story 005's kid-styled exit dialog must never render on "
          'Parent Shell',
    );
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childPetRoom,
      reason: "Parent Shell's own override-exit PopScope (Story 004) "
          'handled the back-press instead, returning to Pet Room',
    );
    expect(container.read(parentOverrideProvider), isFalse);
    expect(
      invoked,
      isEmpty,
      reason: 'Parent Shell back-press never calls SystemNavigator.pop() — '
          'it ends override and returns to the child session instead',
    );
  });
}
