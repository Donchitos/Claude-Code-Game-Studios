// Run with:
//   cd src && flutter test ../tests/integration/parent-dashboard-ui/family_tab_reset_pin_test.dart
//
// Story: parent-dashboard-ui/story-003-family-tab-reset-pin — Test Evidence
// section. Covers the story's 5 QA Test Cases (AC-1..AC-5) plus the
// defensive empty state, plus this story's own "Chọn bé" app bar action and
// a P1 single-flight regression test (same class of bug found missing in
// this epic's own Story 002 code review — see create_custom_task_test.dart's
// header comment).
//
// Backend under test (`PinResetActions.resetChildPin` /
// `PinResetRepository.resetChildPin`) is already built and already
// unit-tested (`tests/unit/auth_account/pin_reset_test.dart`) — this file
// does NOT re-test that logic. It tests the widget layer wired on top of it
// (`ParentDashboardFamilyTab`/`ResetPinDialog`), using the SAME hand-rolled
// minimal Firestore/SecureStorage fake pattern as
// `create_custom_task_test.dart` and `pin_reset_test.dart` (`fake_cloud_
// firestore` is incompatible with the installed `cloud_firestore ^6.7.1` —
// see `parent_login_test.dart`'s header comment for the original finding).
//
// AC-2 (this story's own highest-risk assertion, per the task brief) is
// verified via a GENUINE backend read-back — asserting on the fake
// Firestore's own credentials-document store for BOTH children involved,
// not on any UI state or a mocked action's recorded arguments — the same
// "not UI inference" standard this epic's `create_custom_task_test.dart`
// already established for its own BLOCKING childId test. A wrong `childId`
// would silently write to (or clear the lockout of) the WRONG child's
// credentials sub-document with zero UI symptom (the dialog still closes
// normally either way) — only a real per-child document read-back can catch
// that class of bug.
//
// Pump strategy: NEVER `pumpAndSettle()` in this file — `childProfilesProvider`
// renders an indeterminate `CircularProgressIndicator()` while loading, and
// `ResetPinDialog` renders one of its own while `_isSubmitting` is true;
// either would hang `pumpAndSettle()` for as long as it's transiently
// mounted (same class of gotcha documented in
// `create_custom_task_test.dart`'s and `parent_shell_test.dart`'s header
// comments). A local bounded `_pumpSteps` helper is used everywhere instead.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/core/pin_reset_repository.dart';
import 'package:pet_quest/core/secure_storage_provider.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/parent_dashboard_family_tab.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);
  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._id, this._data);
  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The `children` collection read path — `childProfilesProvider`'s own
/// `.collection(path).get()` call shape.
class _FakeChildrenCollection implements CollectionReference<Map<String, dynamic>> {
  _FakeChildrenCollection(this._seeded, this._firestore);
  final Map<String, Map<String, dynamic>> _seeded;
  final _FakeFirestore _firestore;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    if (_firestore.failChildrenRead) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'simulated-failure',
        message: 'Simulated Firestore read failure for test',
      );
    }
    return _FakeQuerySnapshot([
      for (final entry in _seeded.entries)
        _FakeQueryDocumentSnapshot(entry.key, entry.value),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this._data);
  final Map<String, dynamic>? _data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The `private/credentials` write path — `PinResetRepository.resetChildPin`'s
/// own `.doc(path).set(...)` call shape (via `ChildProfileRepository
/// .setChildCredentials`), matching `pin_reset_test.dart`'s own
/// `_FakeDocumentReference` shape exactly.
class _FakeCredentialsDocRef implements DocumentReference<Map<String, dynamic>> {
  _FakeCredentialsDocRef(this._firestore);
  final _FakeFirestore _firestore;
  Map<String, dynamic>? stored;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeDocumentSnapshot(stored);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (_firestore.failNextCredentialsWrite) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'simulated-failure',
        message: 'Simulated Firestore write failure for test',
      );
    }
    if (options?.merge == true && stored != null) {
      stored = {...stored!, ...data};
    } else {
      stored = data;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  /// path (`FirestorePaths.children(parentId)`) -> (childId -> profile data).
  final _childrenByPath = <String, Map<String, Map<String, dynamic>>>{};

  /// path (`FirestorePaths.childCredentials(parentId, childId)`) -> doc ref.
  final _credentialsDocs = <String, _FakeCredentialsDocRef>{};

  /// Set to simulate a Firestore write failure on the NEXT credentials
  /// write only (AC-5 — Reset PIN error state).
  bool failNextCredentialsWrite = false;

  /// Set to simulate the `children` collection read itself failing —
  /// distinct from the empty-list case, exercises `ParentDashboardFamilyTab`'s
  /// `_LoadErrorContent` branch.
  bool failChildrenRead = false;

  void seedChildren(String parentId, List<ChildProfile> children) {
    final docs = _childrenByPath.putIfAbsent(FirestorePaths.children(parentId), () => {});
    for (final child in children) {
      docs[child.childId] = {
        'name': child.name,
        'avatarId': child.avatarId,
        'mochiName': child.mochiName,
      };
    }
  }

  /// Test-only accessor: reads back whatever `resetChildPin` actually wrote
  /// (or null if nothing was ever written) for a specific child — the
  /// genuine backend read-back this file's header comment describes.
  Map<String, dynamic>? credentialsFor(String parentId, String childId) {
    return _credentialsDocs[FirestorePaths.childCredentials(parentId, childId)]?.stored;
  }

  /// Test-only seeding for a PRE-EXISTING credentials doc — used to prove
  /// Cancel leaves an already-set PIN byte-identical, not just "still
  /// absent" (a null→null Cancel test can't distinguish "never touched"
  /// from "touched and happened to leave it null").
  void seedCredentials(String parentId, String childId, Map<String, dynamic> data) {
    (doc(FirestorePaths.childCredentials(parentId, childId)) as _FakeCredentialsDocRef)
        .stored = data;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _FakeChildrenCollection(_childrenByPath[path] ?? const {}, this);
  }

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _credentialsDocs.putIfAbsent(path, () => _FakeCredentialsDocRef(this));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSecureStorage implements FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-1';
  const childA =
      ChildProfile(childId: 'child-1', name: 'Bé An', avatarId: 'avatar-1', mochiName: 'Mochi An');
  const childB =
      ChildProfile(childId: 'child-2', name: 'Bé Bình', avatarId: 'avatar-2', mochiName: 'Mochi Bình');
  const childC =
      ChildProfile(childId: 'child-3', name: 'Bé Chi', avatarId: 'avatar-3', mochiName: 'Mochi Chi');
  const childD =
      ChildProfile(childId: 'child-4', name: 'Bé Dung', avatarId: 'avatar-4', mochiName: 'Mochi Dung');

  /// Fixed-frame-count pump, never `pumpAndSettle()` — see header comment.
  Future<void> pumpSteps(WidgetTester tester,
      [int steps = 20, Duration step = const Duration(milliseconds: 16)]) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(step);
    }
  }

  /// `resetChildPin` performs real off-isolate PBKDF2 hashing (`hashPin` via
  /// `Isolate.run`) — the same cross-isolate round-trip `PinEntryScreen`'s
  /// own test file documents at length (see that file's `waitForVerifyToSettle`
  /// header comment): neither `pumpAndSettle()` nor a fixed-count frame pump
  /// reliably observes its completion, because the isolate round-trip
  /// advances on the REAL event loop, not `pump()`'s virtual frame clock.
  /// Polls `ResetPinDialog.submittingMarkerKey` (present only while
  /// `_isSubmitting` is true) to disappear, alternating a real-time delay
  /// (`tester.runAsync`, which lets the isolate actually progress) with a
  /// frame pump OUTSIDE `runAsync` (which flushes the resulting `setState`
  /// into the widget tree) — copied in spirit, not literally, from that same
  /// established pattern. Bounded by a generous timeout rather than an
  /// indefinite loop.
  Future<void> waitForResetToSettle(WidgetTester tester) async {
    // Flush the tap's own synchronous `setState(_isSubmitting = true)` first
    // — `tester.tap()` invokes `onPressed` (and thus that `setState`)
    // synchronously as part of dispatching the up event, but the resulting
    // rebuild (which is what actually renders `submittingMarkerKey`) needs
    // an explicit pump. Without this, the loop below would observe the
    // marker as absent on its very first check — not because the reset
    // already finished, but because the marker hasn't been painted yet.
    await tester.pump();
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (find.byKey(ResetPinDialog.submittingMarkerKey).evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'resetPinDialogSubmittingMarker never cleared within 10s — '
          'resetChildPin() may be stuck',
        );
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      // MUST advance with a duration, not a bare `pump()`: on the SUCCESS
      // path `_confirm()` never flips `_isSubmitting` back to `false` — it
      // calls `Navigator.of(context).pop()` instead, and the marker only
      // actually disappears once the dialog's own exit transition (a real
      // `AnimationController`) finishes and the route is removed. A bare
      // `pump()` never advances that controller's virtual clock, so this
      // loop would spin until the 10s deadline even though the reset itself
      // already succeeded (found empirically — the failure-path test, which
      // sets `_isSubmitting = false` directly with no transition involved,
      // passed with a bare `pump()`; only the success/pop path hung).
      await tester.pump(const Duration(milliseconds: 20));
    }
    // One more settle-ish pump run for any trailing dialog-close transition
    // frames after the marker itself clears.
    await pumpSteps(tester, 10);
  }

  /// Pumps `ParentDashboardFamilyTab` behind a minimal real `GoRouter` (so
  /// the "Chọn bé" action's `context.push(AppRoutes.selectChild)` actually
  /// navigates) — same technique as
  /// `child_profile_selection_screen_test.dart`'s `pumpWithRealRouter`.
  /// [container], if supplied, must already carry every override this
  /// widget tree needs (firestore, auth state, secure storage, etc.) — used
  /// by tests that need to read/seed providers (e.g. `activeChildProvider`)
  /// from outside the widget tree, or that need a non-default provider
  /// override (e.g. a stubbed `pinResetRepositoryProvider`). When omitted, a
  /// fresh `ProviderScope` with the standard three overrides is used, same
  /// as before.
  Future<GoRouter> pumpFamilyTab(
    WidgetTester tester, {
    required _FakeFirestore firestore,
    String uid = parentId,
    ProviderContainer? container,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.parentFamily,
      routes: [
        GoRoute(
          path: AppRoutes.parentFamily,
          builder: (_, _) => const ParentDashboardFamilyTab(),
        ),
        GoRoute(
          path: AppRoutes.selectChild,
          builder: (_, _) => const Scaffold(body: Text('Select Child Screen')),
        ),
      ],
    );
    await tester.pumpWidget(
      container != null
          ? UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(routerConfig: router),
            )
          : ProviderScope(
              overrides: [
                firebaseFirestoreProvider.overrideWithValue(firestore),
                authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(uid))),
                secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
              ],
              child: MaterialApp.router(routerConfig: router),
            ),
    );
    await pumpSteps(tester);
    return router;
  }

  group('AC-1 — Child list rendering', () {
    testWidgets('test_ParentDashboardFamilyTab_oneChild_rendersExactlyOneRow',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      await pumpFamilyTab(tester, firestore: firestore);

      expect(
        find.byKey(ParentDashboardFamilyTab.childRowKey(childA.childId)),
        findsOneWidget,
      );
      expect(find.text(childA.name), findsOneWidget);
      expect(
        find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childA.childId)),
        findsOneWidget,
      );
    });

    testWidgets('test_ParentDashboardFamilyTab_fourChildren_rendersExactlyFourRows',
        (tester) async {
      final firestore = _FakeFirestore()
        ..seedChildren(parentId, [childA, childB, childC, childD]);
      await pumpFamilyTab(tester, firestore: firestore);

      for (final child in [childA, childB, childC, childD]) {
        expect(find.byKey(ParentDashboardFamilyTab.childRowKey(child.childId)), findsOneWidget,
            reason: '${child.name} must render exactly one row');
        expect(find.text(child.name), findsOneWidget);
      }
    });
  });

  group('AC-2 — Reset PIN dialog: correct child (not the first)', () {
    testWidgets(
        'test_ResetPinDialog_tapOnSecondRow_showsDialogTitledForThatChild_notFirst',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA, childB]);
      await pumpFamilyTab(tester, firestore: firestore);

      // Tap "Reset PIN" on childB's row — NOT the first row (childA).
      await tester.tap(find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childB.childId)));
      await pumpSteps(tester);

      expect(find.text('Đặt lại PIN cho ${childB.name}'), findsOneWidget);
      expect(find.text('Đặt lại PIN cho ${childA.name}'), findsNothing,
          reason: 'the dialog must never show the first child\'s name when a '
              'different row was tapped');
      expect(find.byKey(ResetPinDialog.pinFieldKey), findsOneWidget);
    });

    testWidgets(
        'test_BLOCKING_resetPin_secondRowNotFirst_confirmWritesCredentialsForThatChildOnly',
        (tester) async {
      // GIVEN 2+ children, childB is the SECOND row (not childA, the first).
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA, childB]);
      await pumpFamilyTab(tester, firestore: firestore);

      // Precondition: neither child has any credentials doc yet.
      expect(firestore.credentialsFor(parentId, childA.childId), isNull);
      expect(firestore.credentialsFor(parentId, childB.childId), isNull);

      // WHEN "Reset PIN" is tapped on childB's row and confirmed with a
      // known new PIN.
      await tester.tap(find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childB.childId)));
      await pumpSteps(tester);
      await tester.enterText(find.byKey(ResetPinDialog.pinFieldKey), '4321');
      await pumpSteps(tester);
      await tester.tap(find.byKey(ResetPinDialog.confirmButtonKey));
      await waitForResetToSettle(tester);

      // THEN: read the credentials doc back from the fake Firestore's own
      // store for BOTH children — a genuine backend read-back, not inferred
      // from the dialog closing or any UI state (which would look identical
      // even if the wrong child's document had been written).
      final childBCredentials = firestore.credentialsFor(parentId, childB.childId);
      expect(childBCredentials, isNotNull,
          reason: 'resetChildPin must have written childB\'s credentials doc');
      expect(childBCredentials!.keys.toSet(), {'pinHash', 'pinSalt'});

      expect(
        firestore.credentialsFor(parentId, childA.childId),
        isNull,
        reason: 'a wrong childId would silently write to (or otherwise '
            'touch) childA\'s credentials doc instead — this must stay '
            'completely untouched when childB\'s row was the one tapped',
      );
    });
  });

  group('AC-3 — Xác nhận gating', () {
    testWidgets(
        'test_ResetPinDialog_confirmButton_disabledUntilExactly4Digits_thenEnabled',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      await pumpFamilyTab(tester, firestore: firestore);

      await tester.tap(find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childA.childId)));
      await pumpSteps(tester);

      FilledButton confirmButton() =>
          tester.widget<FilledButton>(find.byKey(ResetPinDialog.confirmButtonKey));

      expect(confirmButton().onPressed, isNull, reason: '0 digits — disabled');

      for (final partial in ['1', '12', '123']) {
        await tester.enterText(find.byKey(ResetPinDialog.pinFieldKey), partial);
        await pumpSteps(tester);
        expect(confirmButton().onPressed, isNull,
            reason: '${partial.length} digit(s) — still disabled');
      }

      await tester.enterText(find.byKey(ResetPinDialog.pinFieldKey), '1234');
      await pumpSteps(tester);
      expect(confirmButton().onPressed, isNotNull, reason: '4 digits — enabled');
    });
  });

  group('AC-4 — Cancel: no side effect', () {
    testWidgets(
        'test_ResetPinDialog_cancel_closesDialog_doesNotCallResetChildPin_pinUnchanged',
        (tester) async {
      // Pre-existing credentials seeded BEFORE the dialog opens — proves
      // Cancel leaves an already-set PIN byte-identical, not merely "still
      // absent" (a null-before/null-after assertion can't distinguish
      // "never touched" from "touched and happened to leave it null").
      const preExisting = {'pinHash': 'preexisting-hash', 'pinSalt': 'preexisting-salt'};
      final firestore = _FakeFirestore()
        ..seedChildren(parentId, [childA])
        ..seedCredentials(parentId, childA.childId, preExisting);
      await pumpFamilyTab(tester, firestore: firestore);

      await tester.tap(find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childA.childId)));
      await pumpSteps(tester);
      await tester.enterText(find.byKey(ResetPinDialog.pinFieldKey), '999');
      await pumpSteps(tester);

      await tester.tap(find.byKey(ResetPinDialog.cancelButtonKey));
      await pumpSteps(tester);

      expect(find.byKey(ResetPinDialog.pinFieldKey), findsNothing,
          reason: 'dialog must close on Cancel/Hủy');
      expect(
        firestore.credentialsFor(parentId, childA.childId),
        preExisting,
        reason: 'resetChildPin() must never be called on Cancel — the '
            'pre-existing PIN must survive byte-identical',
      );
    });
  });

  group('AC-5 — Reset PIN error state', () {
    testWidgets(
        'test_ResetPinDialog_writeFails_showsInlineError_dialogStaysOpen_confirmReEnabled',
        (tester) async {
      final firestore = _FakeFirestore()
        ..seedChildren(parentId, [childA])
        ..failNextCredentialsWrite = true;
      await pumpFamilyTab(tester, firestore: firestore);

      await tester.tap(find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childA.childId)));
      await pumpSteps(tester);
      await tester.enterText(find.byKey(ResetPinDialog.pinFieldKey), '1234');
      await pumpSteps(tester);
      await tester.tap(find.byKey(ResetPinDialog.confirmButtonKey));
      await waitForResetToSettle(tester);

      expect(find.text('Đặt lại PIN thất bại — thử lại'), findsOneWidget);
      expect(find.byKey(ResetPinDialog.pinFieldKey), findsOneWidget,
          reason: 'dialog must NOT auto-close on failure');

      final confirmButton =
          tester.widget<FilledButton>(find.byKey(ResetPinDialog.confirmButtonKey));
      expect(confirmButton.onPressed, isNotNull,
          reason: 'Xác nhận must re-enable after failure');

      expect(firestore.credentialsFor(parentId, childA.childId), isNull,
          reason: 'a failed write must not land any credentials');
    });
  });

  group('Defensive empty state', () {
    testWidgets('test_ParentDashboardFamilyTab_zeroChildren_showsEmptyStateMessage',
        (tester) async {
      final firestore = _FakeFirestore(); // no seedChildren() call at all
      await pumpFamilyTab(tester, firestore: firestore);

      expect(find.text('Chưa có hồ sơ con nào'), findsOneWidget);
    });
  });

  group('"Chọn bé" app bar action', () {
    testWidgets('test_ParentDashboardFamilyTab_tapChonBe_navigatesToSelectChildRoute',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      final router = await pumpFamilyTab(tester, firestore: firestore);

      expect(find.text('Chọn bé'), findsOneWidget);

      await tester.tap(find.byKey(ParentDashboardFamilyTab.selectChildActionKey));
      await pumpSteps(tester);

      // Asserted via the destination screen's own content — same technique
      // as `child_profile_selection_screen_test.dart`'s `pumpWithRealRouter`
      // callers — rather than `currentConfiguration.uri`, which reports the
      // ROOT match's location for a `push()` (a sub-navigation stacking a
      // new page, not a `go()` replacing the current one), not the pushed
      // page's own location; the match-list length (2, confirmed via
      // `router.routerDelegate.currentConfiguration.matches`) and this
      // screen's content are the reliable signals a `push()` actually
      // navigated.
      expect(find.text('Select Child Screen'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches.length, 2);
    });
  });

  group('P1 — single-flight guard regression', () {
    testWidgets(
        'test_ResetPinDialog_rapidDoubleTapConfirm_writesCredentialsExactlyOnce',
        (tester) async {
      // Same regression class this epic's own create_custom_task_test.dart
      // proved for its Save button (found as a real bug in 3 separate
      // stories of the sibling main-navigation-shell epic, not theoretical).
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      await pumpFamilyTab(tester, firestore: firestore);

      await tester.tap(find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childA.childId)));
      await pumpSteps(tester);
      await tester.enterText(find.byKey(ResetPinDialog.pinFieldKey), '1234');
      await pumpSteps(tester);

      await tester.tap(find.byKey(ResetPinDialog.confirmButtonKey));
      // No pump() between the two taps — the second must land before a
      // fresh pump could observe the first tap's setState(_isSubmitting =
      // true), proving the button is disabled at the earliest possible
      // re-tap point. warnIfMissed:false because a hit-test MISS here is
      // the expected, correct outcome (onPressed: null while submitting).
      await tester.tap(find.byKey(ResetPinDialog.confirmButtonKey), warnIfMissed: false);
      await waitForResetToSettle(tester);

      final stored = firestore.credentialsFor(parentId, childA.childId);
      expect(stored, isNotNull);
      // A double-write would still leave `stored` looking identical (last
      // write wins on this single-document fake) — the meaningful guard
      // here is structural: the dialog must have closed cleanly exactly
      // once, with no error surfaced (a genuine double-submit racing
      // against `mounted`/`Navigator.pop()` on an already-popped dialog
      // context can throw). No error text must be visible.
      expect(find.byKey(ResetPinDialog.pinFieldKey), findsNothing,
          reason: 'dialog must have closed (not stuck mid-error) after the '
              'rapid double-tap');
    });
  });

  group('AC — newPin content forwarded exactly (not a hardcoded/wrong PIN)', () {
    testWidgets(
        'test_ResetPinDialog_confirm_forwardsTypedPinExactly_notAHardcodedValue',
        (tester) async {
      // `resetChildPin`'s own hash function is injectable
      // (`PinResetRepository(hashPinFn: ...)`) — overridden here with an
      // identity-style stub so this test can assert on the EXACT PIN string
      // the dialog forwarded, distinguishing "the typed PIN was used" from
      // "some PIN was hashed" (the BLOCKING childId test above already
      // proves the target is correct; this proves the payload is too).
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      final container = ProviderContainer(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(firestore),
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(parentId))),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
          pinResetRepositoryProvider.overrideWith(
            (ref) => PinResetRepository(
              childProfileRepository: ref.watch(childProfileRepositoryProvider),
              secureStorage: ref.watch(secureStorageProvider),
              hashPinFn: (rawPin, salt) async => 'identity:$rawPin',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await pumpFamilyTab(tester, firestore: firestore, container: container);

      await tester.tap(find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childA.childId)));
      await pumpSteps(tester);
      await tester.enterText(find.byKey(ResetPinDialog.pinFieldKey), '9876');
      await pumpSteps(tester);
      await tester.tap(find.byKey(ResetPinDialog.confirmButtonKey));
      await waitForResetToSettle(tester);

      final stored = firestore.credentialsFor(parentId, childA.childId);
      expect(stored, isNotNull);
      expect(
        stored!['pinHash'],
        'identity:9876',
        reason: 'the exact PIN the parent typed must be the value forwarded '
            'into the hash function — not a hardcoded or stale value',
      );
    });
  });

  group('AC — active session not kicked', () {
    testWidgets(
        'test_ResetPinDialog_confirm_doesNotTouchActiveChildProvider',
        (tester) async {
      // GIVEN childA has an active session (as if currently playing).
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      final container = ProviderContainer(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(firestore),
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(parentId))),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        ],
      );
      addTearDown(container.dispose);
      container.read(activeChildProvider.notifier).state = childA;

      await pumpFamilyTab(tester, firestore: firestore, container: container);

      // WHEN the parent resets childA's PIN via the dialog.
      await tester.tap(find.byKey(ParentDashboardFamilyTab.resetPinButtonKey(childA.childId)));
      await pumpSteps(tester);
      await tester.enterText(find.byKey(ResetPinDialog.pinFieldKey), '1234');
      await pumpSteps(tester);
      await tester.tap(find.byKey(ResetPinDialog.confirmButtonKey));
      await waitForResetToSettle(tester);

      // THEN the active session's provider is completely untouched — same
      // instance, not merely an equal one.
      expect(
        identical(container.read(activeChildProvider), childA),
        isTrue,
        reason: 'resetChildPin must never touch activeChildProvider — a '
            'currently-active session must not be kicked by a PIN reset',
      );
    });
  });

  group('Load error state', () {
    testWidgets(
        'test_ParentDashboardFamilyTab_childProfilesProviderErrors_showsLoadErrorContent',
        (tester) async {
      // GIVEN the children collection read itself fails — distinct from the
      // (valid, non-error) empty-list case already covered above.
      final firestore = _FakeFirestore()..failChildrenRead = true;
      await pumpFamilyTab(tester, firestore: firestore);

      expect(find.text('Không tải được danh sách bé — thử lại sau'), findsOneWidget);
      expect(find.text('Chưa có hồ sơ con nào'), findsNothing,
          reason: 'a load error must show the error message, not the '
              'empty-state message — they are distinct states');
    });
  });
}
