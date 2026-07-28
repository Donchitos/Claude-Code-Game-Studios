// Run with:
//   cd src && flutter test ../tests/integration/main-navigation-shell/parent_override_test.dart
//
// Story 004 (Parent Override — Switch To/From Parent Mode,
// main-navigation-shell epic) — covers this story's own 6 acceptance
// criteria/edge cases (per its Test Evidence section), plus regression
// coverage found during code review: AC-8 (long-press trigger, the <600ms
// threshold edge case, and a tight ±1ms boundary pinning the actually
// -configured duration — a looser 300ms/700ms-only test was proven by
// mutation testing to pass even if the tuning knob silently drifted), AC-9
// (correct password → override on, navigate, child session preserved),
// AC-13 (back-press exits override), AC-14 (override-exit callable action),
// wrong password, a rapid-double-tap-on-confirm regression test (the
// sheet's own single-flight guard, not covered by the provider-level auth
// tests), the sub-screen discard warning, and its tab-root contrast case.
//
// This is the first story where Story 001 (Root Redirect)'s bridge, Story
// 002 (Child Shell)'s Flame-state preservation, and Story 003 (Parent
// Shell)'s branch structure all become user-observable together — this
// file's `_reachChildPetRoom`/`_pumpSteps` helpers are copied from
// `child_shell_test.dart`/`parent_shell_test.dart` in this same directory
// (not reinvented) for exactly that reason: the same "Pet Room's GameWidget
// keeps a raw Ticker perpetually scheduled, so `pumpAndSettle()` hangs"
// gotcha documented in both those files' headers applies here too, from the
// moment `activeChildProvider` is set onward.
//
// Auth-layer coverage (correct/wrong password → `parentOverrideProvider`,
// `activeChildProvider` untouched by override, `.end()`'s direct
// `childSelected` landing) already exists and passes in
// `tests/integration/auth_account/parent_override_test.dart` (a DIFFERENT
// file from this one, despite the identical filename) — this file does not
// re-test that provider-level logic, only the widget/route-integration
// layer built on top of it (the sheet UI, the placeholder long-press
// trigger, the sub-screen warning, and the back-press/override-exit route
// wiring).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matcher/matcher.dart' show anything;
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/parent_override_actions.dart';
import 'package:pet_quest/ui/parent_override_trigger.dart';
import 'package:pet_quest/ui/parent_shell_scaffold.dart';
import 'package:pet_quest/ui/parent_switch_mode_sheet.dart';

/// Minimal Firestore fake — only needed so `childProfilesProvider`
/// (transitively watched along the `parentAuthed` path) resolves without
/// touching a real backend; no test here asserts on Firestore content.
/// Duplicated from `child_shell_test.dart`/`parent_shell_test.dart` (private
/// classes can't be shared across test files).
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

/// Parent Dashboard UI Story 004 (ADR-0015) addition — `ParentShellScaffold
/// .initState()` now reads `firebaseMessagingProvider.getNotificationSettings()`
/// once. The default `firebaseMessagingProvider` resolves `FirebaseMessaging
/// .instance`, which requires a live Firebase app and throws `[core/no-app]`
/// in this widget-test environment — this fake avoids that for every test in
/// this file, all of which transition into the Parent Shell via override.
/// `authorized` keeps `bannerStateProvider.displayKind` at `none` so no
/// incidental banner shows up during tests that aren't exercising Story
/// 004's own banner logic.
const _fakeNotificationSettings = NotificationSettings(
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.disabled,
  authorizationStatus: AuthorizationStatus.authorized,
  badge: AppleNotificationSetting.enabled,
  carPlay: AppleNotificationSetting.disabled,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.disabled,
  criticalAlert: AppleNotificationSetting.disabled,
  sound: AppleNotificationSetting.enabled,
  providesAppNotificationSettings: AppleNotificationSetting.disabled,
);

class _FakeFirebaseMessaging implements FirebaseMessaging {
  @override
  Future<NotificationSettings> getNotificationSettings() async => _fakeNotificationSettings;

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

/// Drives a fresh app through unauthenticated -> parentAuthed ->
/// childSelected, landing on `/child/pet-room`, using a SIGNED-IN
/// `MockFirebaseAuth` from the start (unlike the sibling files' helper,
/// which signs in via `signInWithEmailAndPassword` — this file needs a
/// stable, known `uid`/email up front so `AuthRepository.reauthenticate` has
/// a real `currentUser`/email to build an `EmailAuthProvider.credential`
/// from for the sheet's own confirm flow). Returns the [ProviderContainer]
/// backing it, and the [MockFirebaseAuth] used, for tests that need to mock
/// `reauthenticateWithCredential`'s outcome directly.
Future<(ProviderContainer, MockFirebaseAuth)> _reachChildPetRoom(
  WidgetTester tester, {
  String uid = 'parent-1',
}) async {
  final mockAuth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: uid, email: '$uid@example.com'),
  );
  final container = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(mockAuth),
      firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
      firebaseMessagingProvider.overrideWithValue(_FakeFirebaseMessaging()),
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
  // Safe: no GameWidget/Ticker exists yet at /select-child (this file starts
  // already signed in, so the app lands straight on /select-child rather
  // than /login).
  await tester.pumpAndSettle();

  container.read(activeChildProvider.notifier).state = _activeChild;
  // From here on: bounded steps only. This redirect lands on
  // /child/pet-room, mounting PetRoomScreen's GameWidget<PetRoomGame> and
  // starting its GameLoop's Ticker.
  await _pumpSteps(tester, 6);

  return (container, mockAuth);
}

/// Long-presses [ParentOverrideTrigger] for [holdDuration], releasing
/// afterward. A real `Timer` backs the trigger's own long-press detection
/// (`parent_override_trigger.dart`) — `flutter_test`'s `FakeAsync`-backed
/// clock means `tester.pump(duration)` genuinely elapses that Timer, no real
/// wall-clock wait needed (same mechanism `pin_entry_screen.dart`'s lockout
/// countdown `Timer.periodic` already relies on being testable this way).
Future<void> _pressTrigger(WidgetTester tester, {required Duration holdDuration}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(ParentOverrideTrigger.triggerKey)),
  );
  await tester.pump(holdDuration);
  await gesture.up();
  await tester.pump();
  // Lets the modal bottom sheet's own slide-up entrance transition finish
  // before any caller interacts with its content — without this, a
  // subsequent tap can land on the confirm button's PRE-transition
  // (off-screen, still-sliding-in) position and silently miss. Bounded
  // steps, not `pumpAndSettle()`: Pet Room's GameWidget/Ticker is still
  // mounted underneath the sheet at this point (same file-wide precaution).
  await _pumpSteps(tester, 10);
}

void main() {
  group('AC-8: long-press trigger opens the switch-mode sheet', () {
    testWidgets(
        'test_AC8_longPressAtLeast600ms_opensSwitchModeSheet',
        (tester) async {
      await _reachChildPetRoom(tester);
      expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsNothing);

      await _pressTrigger(tester, holdDuration: const Duration(milliseconds: 700));

      expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsOneWidget);
    });

    testWidgets(
        'test_AC8_pressHeldUnder600ms_doesNotOpenSheet',
        (tester) async {
      // Verifies the actual 600ms threshold (`kParentOverrideLongPressDuration`
      // in `parent_override_trigger.dart`), not just "long press works" —
      // per this story's own QA edge case.
      await _reachChildPetRoom(tester);

      await _pressTrigger(tester, holdDuration: const Duration(milliseconds: 300));

      expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsNothing);
    });

    testWidgets(
        'test_AC8_pressHeldExactlyAtThreshold_pinsTheConfiguredDurationNotJustARange',
        (tester) async {
      // The 300ms/700ms tests above only prove the threshold lies somewhere
      // in (300ms, 700ms] — a silent drift of the tuning knob to e.g. 450ms
      // (still inside the GDD's 400-1000ms allowed range) would pass both
      // and go undetected (confirmed via mutation testing in code review).
      // This test pins the actually-configured `kParentOverrideLongPressDuration`
      // itself: 1ms under it must not open the sheet, 1ms over it must.
      await _reachChildPetRoom(tester);
      await _pressTrigger(
        tester,
        holdDuration: kParentOverrideLongPressDuration - const Duration(milliseconds: 1),
      );
      expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsNothing,
          reason: '1ms under the configured threshold must not open the sheet');

      await _pressTrigger(
        tester,
        holdDuration: kParentOverrideLongPressDuration + const Duration(milliseconds: 1),
      );
      expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsOneWidget,
          reason: '1ms over the configured threshold must open the sheet');
    });
  });

  testWidgets(
      'test_AC9_correctPassword_setsOverrideTrue_navigatesToParentDashboard_activeChildIdentical',
      (tester) async {
    final (container, _) = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);
    final activeChildBefore = container.read(activeChildProvider);
    expect(container.read(parentOverrideProvider), isFalse);

    await _pressTrigger(tester, holdDuration: const Duration(milliseconds: 700));
    await tester.enterText(
      find.byKey(ParentSwitchModeSheet.passwordFieldKey),
      'correct-horse-battery-staple',
    );
    await tester.tap(find.byKey(ParentSwitchModeSheet.confirmButtonKey));
    // Transitioning into Parent Shell is a real top-level page transition in
    // go_router's root Navigator (childShellRoute/parentShellRoute are
    // siblings there — see `parent_shell_test.dart`'s header comment) —
    // needs more/longer bounded steps to actually settle, same as that
    // file's own `_reachParentDashboard` helper.
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

    expect(container.read(parentOverrideProvider), isTrue);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentDashboard,
    );
    // The sheet closed itself (Implementation Note 3 — no context.go() call
    // inside the sheet; the redirect bridge alone drove this navigation).
    expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsNothing);
    // AC-9's core claim: child session not logged out. Byte-for-byte
    // identical, not just equal — proves activeChildProvider was never
    // rewritten, only read (Implementation Note 7).
    expect(identical(container.read(activeChildProvider), activeChildBefore), isTrue);
    expect(container.read(activeChildProvider)?.childId, 'child-1');
  });

  testWidgets(
      'test_AC13_backPressWhileInOverride_returnsToChildPetRoom_overrideFalse_noExitDialog',
      (tester) async {
    final (container, _) = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);

    container.read(parentOverrideProvider.notifier).state = true;
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentDashboard,
    );

    // Simulates a real Android/system back-button press — the mechanism
    // that actually reaches PopScope's onPopInvokedWithResult, exercised
    // via the framework's own `@visibleForTesting handlePopRoute()` seam
    // (`WidgetsBinding`), not `Navigator.maybePop` (which resolves against
    // the nearest Navigator's own back-stack depth and would not exercise
    // the "last-page-in-this-shell" case ParentShellScaffold's PopScope
    // exists for).
    await tester.binding.handlePopRoute();
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childPetRoom,
    );
    expect(container.read(parentOverrideProvider), isFalse);
    // No kid-styled "Thoát PetQuest?" exit-confirm dialog — that's the
    // Child-tab-root case (Story 005), a different PopScope shape entirely;
    // asserting its absence here proves ParentShellScaffold's PopScope did
    // NOT fall through to that behavior.
    expect(find.text('Thoát PetQuest?'), findsNothing);
    // App did not exit — proven simply by the widget tree still being
    // pumpable/inspectable afterward (a real app-exit would leave nothing
    // to assert against).
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets(
      'test_AC14_overrideExitActionInvoked_routesDirectlyToChildPetRoom_noSelectChildOrPin_noRePin',
      (tester) async {
    // Simulates the future Parent Dashboard "Xong"/"Quay lại" button
    // (Parent Dashboard UI epic #21, not yet built — Implementation Note 6)
    // by invoking the exact callable action it will call.
    final (container, _) = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);
    final activeChildBefore = container.read(activeChildProvider);

    container.read(parentOverrideProvider.notifier).state = true;
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.parentDashboard,
    );

    // Every intermediate SessionState this transition passes through — proof
    // "no intermediate /select-child or PIN route" means what it says, not
    // just "the final route happens to be right" (same precedent as
    // `tests/integration/auth_account/parent_override_test.dart`'s own
    // `test_endParentOverride_returns_directly_to_childSelected_no_intermediate_state`).
    final observedStates = <SessionState>[];
    container.listen(
      sessionStateProvider,
      (_, next) => observedStates.add(next),
      fireImmediately: false,
    );

    // Grabs a real WidgetRef off the mounted ParentShellScaffold (a
    // ConsumerStatefulWidget — `ConsumerState.ref` is public
    // flutter_riverpod API) rather than constructing one from scratch — the
    // same object ParentShellScaffold's own back-press PopScope handler
    // uses. Simulates the future Parent Dashboard "Xong"/"Quay lại" button
    // tap by invoking the exact callable action it will call
    // (Implementation Note 6), not a re-implementation of its logic.
    final consumerState =
        tester.state(find.byType(ParentShellScaffold)) as ConsumerState;
    final context = tester.element(find.byType(ParentShellScaffold));
    endParentOverrideAndReturnToPetRoom(consumerState.ref, context);
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childPetRoom,
      reason: 'must land directly on /child/pet-room',
    );
    expect(
      observedStates,
      [SessionState.childSelected],
      reason: 'exactly one transition, landing directly on childSelected — '
          'never passes through parentAuthed (which would mean a bounce '
          'through /select-child) or any PIN-entry-adjacent state',
    );
    expect(container.read(parentOverrideProvider), isFalse);
    expect(
      identical(container.read(activeChildProvider), activeChildBefore),
      isTrue,
      reason: 'session vẫn nguyên — no re-PIN, same ChildProfile instance',
    );
  });

  testWidgets(
      'test_rapidDoubleTapOnConfirm_onlyOneOverrideTransitionOccurs',
      (tester) async {
    // ParentSwitchModeSheet._confirm()'s own single-flight guard
    // (`_isSubmitting`) is new widget-layer code, not covered by the
    // provider-level tests in tests/integration/auth_account/parent_override_test.dart
    // — same "rapid double-tap on an interactive trigger" risk class found
    // in this epic's Story 002/003 code reviews. Taps confirm twice back to
    // back, with no pump in between, so the second tap lands while
    // `_isSubmitting` is already true (button disabled, `onPressed: null`).
    final container = await _reachChildPetRoom(tester).then((r) => r.$1);

    await _pressTrigger(tester, holdDuration: const Duration(milliseconds: 700));
    await tester.enterText(
      find.byKey(ParentSwitchModeSheet.passwordFieldKey),
      'correct-horse-battery-staple',
    );

    final overrideTransitions = <bool>[];
    container.listen(
      parentOverrideProvider,
      (_, next) => overrideTransitions.add(next),
      fireImmediately: false,
    );

    await tester.tap(find.byKey(ParentSwitchModeSheet.confirmButtonKey));
    // No pump() here — the second tap must land before the first's
    // setState(_isSubmitting = true) synchronous write has been observed by
    // a fresh pump, proving the button is already disabled at the earliest
    // possible re-tap point, not just "eventually". `warnIfMissed: false`
    // because a hit-test MISS on this second tap is the expected, correct
    // outcome — the button has `onPressed: null` while submitting, so it
    // can no longer receive pointer events at all; that's the guard working,
    // not a test bug.
    await tester.tap(
      find.byKey(ParentSwitchModeSheet.confirmButtonKey),
      warnIfMissed: false,
    );
    await _pumpSteps(tester, 20, step: const Duration(milliseconds: 50));

    expect(
      overrideTransitions,
      [true],
      reason: 'exactly one override transition — a second concurrent tap '
          'must not trigger a second attempt()/state flip',
    );
  });

  testWidgets(
      'test_wrongPassword_showsInlineError_sheetStaysOpen_noStateOrRouteChange',
      (tester) async {
    final (container, mockAuth) = await _reachChildPetRoom(tester, uid: 'parent-wrong');
    whenCalling(Invocation.method(#reauthenticateWithCredential, [anything]))
        .on(mockAuth.currentUser!)
        .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    final router = container.read(routerProvider);
    final locationBefore = router.routerDelegate.currentConfiguration.uri.toString();

    await _pressTrigger(tester, holdDuration: const Duration(milliseconds: 700));
    await tester.enterText(
      find.byKey(ParentSwitchModeSheet.passwordFieldKey),
      'wrong-password',
    );
    await tester.tap(find.byKey(ParentSwitchModeSheet.confirmButtonKey));
    await _pumpSteps(tester, 5);

    expect(find.text('Mật khẩu không đúng'), findsOneWidget);
    expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsOneWidget,
        reason: 'sheet must stay open');
    expect(container.read(parentOverrideProvider), isFalse);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      locationBefore,
      reason: 'no navigation on a failed attempt',
    );
  });

  testWidgets(
      'test_subScreenDiscardWarning_triggeredFromChildTasksNew_showsExtraWarningText',
      (tester) async {
    final (container, _) = await _reachChildPetRoom(tester);
    final router = container.read(routerProvider);
    router.go(AppRoutes.childTasksNew);
    await _pumpSteps(tester, 6);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.childTasksNew,
    );

    await _pressTrigger(tester, holdDuration: const Duration(milliseconds: 700));

    expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsOneWidget);
    expect(find.text('Dữ liệu chưa lưu sẽ bị mất'), findsOneWidget);
  });

  testWidgets(
      'test_normalTabRootTrigger_doesNotShowDiscardWarning',
      (tester) async {
    // Contrast case for the sub-screen test above — same sheet, from a
    // tab-root location, must NOT show the discard-warning copy.
    await _reachChildPetRoom(tester);

    await _pressTrigger(tester, holdDuration: const Duration(milliseconds: 700));

    expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsOneWidget);
    expect(find.text('Dữ liệu chưa lưu sẽ bị mất'), findsNothing);
  });
}
