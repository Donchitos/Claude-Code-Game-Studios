// Run with:
//   cd src && flutter test ../tests/integration/auth_account/pin_entry_screen_test.dart
//
// UI story (Test Evidence gate: ADVISORY per coding-standards.md) — automated
// widget test in lieu of the manual-walkthrough evidence doc, matching this
// project's established pattern (see login_screen_test.dart,
// child_profile_selection_screen_test.dart).
//
// Reuses the same hand-rolled Firestore/SecureStorage fakes as
// pin_verification_test.dart (fake_cloud_firestore is incompatible with
// cloud_firestore ^6.7.1). `pinVerificationRepositoryProvider` is overridden
// directly (not just its `firebaseFirestoreProvider`/`secureStorageProvider`
// dependencies) so the repository's lockout clock can be injected and driven
// deterministically alongside PinEntryScreen's own injected `now` — the
// provider-level `pinVerificationRepositoryProvider` has no `now` override
// exposed via its dependencies, only via direct construction (same pattern
// pin_verification_test.dart uses for pure repository tests).
//
// Navigation (back button) is tested against a real minimal GoRouter, same
// approach as child_profile_selection_screen_test.dart.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/child_profile_repository.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/pin_crypto.dart';
import 'package:pet_quest/core/pin_verification_repository.dart';
import 'package:pet_quest/core/secure_storage_provider.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/ui/pin_entry_screen.dart';

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

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  Map<String, dynamic>? stored;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeDocumentSnapshot(stored);
  }

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

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> seeded = {};

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeQuerySnapshot(
      seeded.entries
          .map((e) => _FakeQueryDocumentSnapshot(e.key, e.value))
          .toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final _docs = <String, _FakeDocumentReference>{};
  final _collections = <String, _FakeCollectionReference>{};

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _docs.putIfAbsent(path, () => _FakeDocumentReference());
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collections.putIfAbsent(path, () => _FakeCollectionReference());
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
  const childId = 'child-1';
  const correctPin = '1234';

  Future<String> signInAndWait(WidgetTester tester, MockFirebaseAuth auth) async {
    await auth.signInWithEmailAndPassword(
      email: 'parent@example.com',
      password: 'irrelevant-for-this-test',
    );
    await tester.pumpAndSettle();
    return auth.currentUser!.uid;
  }

  // `hashPin` runs off-isolate via `Isolate.run` (ADR-0002 §2) — a bare
  // `await hashPin(...)` sitting directly in a `testWidgets` body (not
  // driven by a `tester.pump()` frame) never receives the isolate's
  // completion message and hangs forever. Confirmed by isolating it in a
  // throwaway debug test: the widget's OWN internal PBKDF2 call (triggered
  // via `tester.tap()` on the 4th digit) settles fine on its own — only a
  // raw top-level `await hashPin(...)` in test code needs `tester.runAsync`.
  Future<void> seedCredentials(
    WidgetTester tester,
    _FakeFirestore firestore,
    String parentId, {
    required String rawPin,
  }) async {
    final salt = generatePinSalt();
    final hash = await tester.runAsync(() => hashPin(rawPin, salt));
    (firestore.doc(FirestorePaths.childCredentials(parentId, childId))
            as _FakeDocumentReference)
        .stored = {'pinHash': hash!, 'pinSalt': encodePinSalt(salt)};
  }

  // Invalidates childProfilesProvider after seeding — it depends on
  // authStateProvider and does its one-shot Firestore fetch as soon as
  // sign-in resolves, which in these tests happens BEFORE this seed call.
  // Without invalidating, the provider stays cached at the empty list it
  // fetched pre-seed, and PinVerificationActions.verifyChildPin's
  // childProfilesProvider.future lookup finds no match — confirmed
  // empirically (a "correct PIN" test failed to set activeChildProvider
  // until this invalidation was added).
  void seedProfile(
    ProviderContainer container,
    _FakeFirestore firestore,
    String parentId, {
    String name = 'Bé An',
  }) {
    (firestore.collection(FirestorePaths.children(parentId))
            as _FakeCollectionReference)
        .seeded[childId] = {'name': name, 'avatarId': 'avatar-1', 'mochiName': 'Mochi'};
    container.invalidate(childProfilesProvider);
  }

  /// Pumps a minimal real GoRouter (for the back-button test) with
  /// PinEntryScreen reached via push, plus a ProviderContainer exposed for
  /// direct assertions on activeChildProvider.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required MockFirebaseAuth auth,
    required _FakeFirestore firestore,
    required _FakeSecureStorage secureStorage,
    DateTime Function() now = DateTime.now,
  }) async {
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(firestore),
        secureStorageProvider.overrideWithValue(secureStorage),
        pinVerificationRepositoryProvider.overrideWithValue(
          PinVerificationRepository(
            childProfileRepository: ChildProfileRepository(firestore: firestore),
            secureStorage: secureStorage,
            now: now,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/select-child',
      routes: [
        GoRoute(
          path: '/select-child',
          builder: (context, state) => const Scaffold(body: Text('Select Child')),
        ),
        GoRoute(
          path: '/pin-entry',
          builder: (context, state) => PinEntryScreen(childId: childId, now: now),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/pin-entry');
    await tester.pumpAndSettle();
    return container;
  }

  // The 4th tap triggers the widget's own real `hashPin` (Isolate.run) call
  // as an unawaited fire-and-forget Future from InkWell.onTap. Neither a
  // bare `pumpAndSettle()` NOR wrapping just the taps in `tester.runAsync`
  // reliably waits for that cross-isolate round-trip — confirmed
  // empirically twice: `activeChildProvider`/lockout state were observed
  // still unset immediately after entering a PIN, followed by an
  // `UnmountedRefException` firing AFTER the test had already torn down,
  // proving the isolate response arrived too late to be useful.
  //
  // A fixed real-time sleep (the first fix attempted here) removed the hang
  // but traded it for a flakiness risk flagged in code review: on a slower
  // CI machine, 100k-iteration PBKDF2 could exceed a fixed 1s bound. Instead,
  // poll for `pin_verifying_marker` (a test-only key the widget renders only
  // while its internal `_verifying` flag is true) to disappear — a real
  // completion signal, bounded by a generous timeout rather than guessed at.
  // Alternates real-time waiting (runAsync, lets the isolate progress) with
  // a frame pump OUTSIDE runAsync (flushes the resulting setState into the
  // widget tree) — pumping from inside runAsync's real zone is not the
  // supported pattern. Only needs to bridge the isolate gap: once the
  // marker clears, the rest of `_verify()` (shake/flash, digit-clear,
  // lockout refresh) is normal virtual-clock work that the caller's own
  // `pumpAndSettle()` handles correctly.
  Future<void> waitForVerifyToSettle(WidgetTester tester) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (find.byKey(const Key('pin_verifying_marker')).evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'pin_verifying_marker never cleared within 10s — verify() may be stuck',
        );
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final ch in pin.split('')) {
      await tester.tap(find.text(ch).first);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await waitForVerifyToSettle(tester);
    await tester.pumpAndSettle();
  }

  int dotFillCount(WidgetTester tester) {
    // Filled dots use lavenderSoft/mintBreeze fill; counting non-transparent
    // decorated circles via the BoxDecoration.color set on each dot.
    final containers = tester.widgetList<Container>(find.byType(Container));
    var count = 0;
    for (final c in containers) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration &&
          decoration.shape == BoxShape.circle &&
          decoration.color != null &&
          decoration.color != Colors.transparent) {
        count++;
      }
    }
    return count;
  }

  testWidgets('test_PinEntryScreen_renders_dot_display_and_numpad', (tester) async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(dotFillCount(tester), 0);
    // AC7: PIN entry must never go through a TextField/EditableText — the
    // whole point of the numpad-button design is that there is no
    // text-input surface for a crash reporter's default breadcrumb capture
    // to hook into. A regression that swaps in a TextField (e.g. for a
    // future screen-reader affordance) would silently violate AC7.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets(
      'test_PinEntryScreen_correct_pin_sets_activeChildProvider_to_matching_childId',
      (tester) async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    await tester.pumpAndSettle();

    await enterPin(tester, correctPin);

    final active = container.read(activeChildProvider);
    expect(active, isNotNull);
    expect(active!.childId, childId);
  });

  testWidgets(
      'test_PinEntryScreen_wrong_pin_first_attempt_resets_dots_without_lockout',
      (tester) async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    await tester.pumpAndSettle();

    await enterPin(tester, '9999');

    expect(find.textContaining('Thử lại sau'), findsNothing);
    expect(dotFillCount(tester), 0);
    // Numpad still usable — a second attempt with the correct PIN succeeds.
    await enterPin(tester, correctPin);
    expect(find.textContaining('Thử lại sau'), findsNothing);
  });

  testWidgets(
      'test_PinEntryScreen_wrong_pin_3_times_triggers_lockout_countdown',
      (tester) async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    var currentTime = DateTime(2026, 7, 16, 9);
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
      now: () => currentTime,
    );
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    await tester.pumpAndSettle();

    await enterPin(tester, '9999');
    await enterPin(tester, '9998');
    await enterPin(tester, '9997');

    expect(find.text('Thử lại sau 60s'), findsOneWidget);
    // Numpad is gone entirely while locked — no digit keys to tap.
    expect(find.text('1'), findsNothing);
  });

  testWidgets(
      'test_PinEntryScreen_lockout_expires_and_numpad_reactivates_automatically',
      (tester) async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    var currentTime = DateTime(2026, 7, 16, 9);
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
      now: () => currentTime,
    );
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    await tester.pumpAndSettle();

    await enterPin(tester, '9999');
    await enterPin(tester, '9998');
    await enterPin(tester, '9997');
    expect(find.textContaining('Thử lại sau'), findsOneWidget);

    currentTime = currentTime.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thử lại sau'), findsNothing);
    expect(find.text('1'), findsOneWidget); // numpad back, no tap needed
  });

  testWidgets(
      'test_PinEntryScreen_offline_sync_shows_message_not_wrong_pin_state',
      (tester) async {
    // No credentials sub-document seeded at all — the offline-first-sync
    // edge case (Story 004 AC4 / PinCredentialsUnavailable).
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await tester.pumpAndSettle();

    await enterPin(tester, correctPin);

    expect(find.textContaining('Cần kết nối mạng'), findsOneWidget);
    expect(find.textContaining('Thử lại sau'), findsNothing);
  });

  testWidgets(
      'test_PinEntryScreen_data_error_shows_generic_message_with_back_button',
      (tester) async {
    // Credentials exist and PIN is correct, but no matching profile in
    // childProfilesProvider — VerifiedChildProfileMissing data-integrity case.
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    final parentId = await signInAndWait(tester, auth);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    // Deliberately NOT seeding the profile list doc.
    await tester.pumpAndSettle();

    await enterPin(tester, correctPin);

    expect(find.text('Có lỗi xảy ra, vui lòng thử lại'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('Select Child'), findsOneWidget);
  });

  testWidgets('test_PinEntryScreen_numpad_keys_meet_minimum_tap_target',
      (tester) async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    await signInAndWait(tester, auth);
    await tester.pumpAndSettle();

    final size = tester.getSize(find.widgetWithText(InkWell, '5').first);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'test_PinEntryScreen_back_button_returns_to_selection_without_setting_anything',
      (tester) async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Select Child'), findsOneWidget);
    expect(container.read(activeChildProvider), isNull);
  });

  testWidgets(
      'test_PinEntryScreen_ignores_a_tap_that_arrives_while_still_verifying',
      (tester) async {
    // UX spec's "Verifying" state: numpad briefly disables while PBKDF2
    // computes. A tap that lands in that window must be a no-op, not a
    // corrupted buffer or a second concurrent verify() call.
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    await tester.pumpAndSettle();

    for (final ch in correctPin.split('')) {
      await tester.tap(find.text(ch).first);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byKey(const Key('pin_verifying_marker')), findsOneWidget);
    // A tap while the marker is still present — should be silently ignored.
    await tester.tap(find.text('1').first);
    await tester.pump(const Duration(milliseconds: 16));

    await waitForVerifyToSettle(tester);
    await tester.pumpAndSettle();

    final active = container.read(activeChildProvider);
    expect(active, isNotNull);
    expect(active!.childId, childId);
  });

  testWidgets(
      'test_PinEntryScreen_wrong_pin_reduced_motion_flashes_instead_of_shaking',
      (tester) async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = await pumpScreen(
      tester,
      auth: auth,
      firestore: firestore,
      secureStorage: _FakeSecureStorage(),
    );
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final parentId = await signInAndWait(tester, auth);
    seedProfile(container, firestore, parentId);
    await seedCredentials(tester, firestore, parentId, rawPin: correctPin);
    await tester.pumpAndSettle();

    await enterPin(tester, '9999');
    // The reduced-motion (flash) branch's own 300ms Future.delayed is
    // separate from the isolate wait enterPin() already handled — give it
    // an explicit extra settle window before asserting the post-flash state.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // The reduced-motion (flash) branch runs instead of the shake
    // AnimationController — no exception, and the dots still reset
    // normally afterwards.
    expect(tester.takeException(), isNull);
    expect(dotFillCount(tester), 0);
  });
}
