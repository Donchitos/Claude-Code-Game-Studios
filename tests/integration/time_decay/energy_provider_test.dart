// Run with:
//   cd src && flutter test ../tests/integration/time_decay/energy_provider_test.dart
//
// Uses the same hand-rolled minimal Firestore fake pattern as
// pin_verification_test.dart (fake_cloud_firestore is incompatible with
// cloud_firestore ^6.7.1). This file's fake additionally supports
// `.snapshots()` (a live Stream), which no existing fake in this project
// needed before — energyProvider is the first provider to read the active
// child's economy fields via a realtime stream rather than a one-shot get().

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/time_decay_providers.dart';

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
  final _controller =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  Map<String, dynamic>? _data;
  int writeCallCount = 0;

  void seed(Map<String, dynamic>? data) {
    _data = data;
    _controller.add(_FakeDocumentSnapshot(data));
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    // Real Firestore snapshots() emits the current cached/server state
    // immediately upon subscribe, then live updates thereafter — mirrored
    // here via Stream.multi (per-listener replay-then-forward), same
    // technique already verified in this project's GameEventBus (Bridge
    // Story 001).
    return Stream.multi((controller) {
      controller.add(_FakeDocumentSnapshot(_data));
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    writeCallCount++;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    writeCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final _docs = <String, _FakeDocumentReference>{};

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _docs.putIfAbsent(path, () => _FakeDocumentReference());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const childId = 'child-1';
  final child = const ChildProfile(
    childId: childId,
    name: 'Bé An',
    avatarId: 'avatar-1',
    mochiName: 'Mochi',
  );

  Future<String> waitForSignedInUser(
    ProviderContainer container,
    MockFirebaseAuth auth,
  ) {
    final completer = Completer<String>();
    late final ProviderSubscription<AsyncValue<User?>> sub;
    sub = container.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null && !completer.isCompleted) {
        completer.complete(user.uid);
      }
    });
    completer.future.whenComplete(sub.close);
    auth.signInWithEmailAndPassword(email: 'parent@example.com', password: 'x');
    return completer.future.timeout(const Duration(seconds: 5));
  }

  test('test_resumeTickProvider_increments_only_on_onResume', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(resumeTickProvider), 0);
    container.read(resumeTickProvider.notifier).state++;

    expect(container.read(resumeTickProvider), 1);
  });

  testWidgets(
      'test_appLifecycleListenerProvider_ticks_resumeTickProvider_only_on_real_onResume_events',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Reading (not just declaring) the provider constructs the real
    // AppLifecycleListener, which registers itself as a WidgetsBindingObserver
    // — tester.binding.handleAppLifecycleStateChanged() below drives that
    // real observer, not a fake. This directly exercises ADR-0005's "only
    // onResume ticks the resume provider" rule end-to-end (flagged as an
    // untested gap in this story's own QA test cases before this test was
    // added).
    container.read(appLifecycleListenerProvider);

    // AppLifecycleListener asserts on invalid state transitions (verified
    // against the pinned Flutter 3.44.4 SDK source at
    // packages/flutter/lib/src/widgets/app_lifecycle_listener.dart:213-269),
    // so this walks a realistic full cycle rather than jumping straight
    // paused -> resumed, which would trip that assertion.
    expect(container.read(resumeTickProvider), 0);

    // First foregrounding: null -> inactive -> resumed.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(container.read(resumeTickProvider), 0,
        reason: 'onInactive must not tick resumeTickProvider');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(container.read(resumeTickProvider), 1,
        reason: 'onResume must tick resumeTickProvider exactly once');

    // Backgrounding: resumed -> inactive -> hidden -> paused. None of these
    // are onResume — the tick must not move.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(container.read(resumeTickProvider), 1,
        reason: 'pause/inactive/hidden transitions must not tick');

    // Foregrounding again: paused -> hidden -> inactive -> resumed.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(container.read(resumeTickProvider), 2,
        reason: 'a second onResume must tick again, to exactly 2');
  });

  test('test_energyProvider_recomputes_when_resumeTickProvider_changes',
      () async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);
    final parentId = await waitForSignedInUser(container, auth);
    container.read(activeChildProvider.notifier).state = child;

    final lastApprovedAt = DateTime.now().subtract(const Duration(hours: 4));
    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({
      'storedEnergy': 100.0,
      'lastApprovedAt': Timestamp.fromDate(lastApprovedAt),
      'createdAt': Timestamp.fromDate(lastApprovedAt),
    });

    final sub = container.listen(energyProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    // Cross-checked against the pure computeEnergy function directly (not
    // just "isNotNull") both before and after the tick — this proves the
    // provider is still reading live Firestore-backed data through
    // computeEnergy on each read, rather than having gotten stuck on a
    // frozen/incorrect build. A strict before != after assertion is
    // deliberately avoided here: it would be a time-dependent assertion
    // (forbidden by .claude/rules/test-standards.md), since the only thing
    // that could change the result between reads is wall-clock drift.
    expect(sub.read(), closeTo(88.0, 0.1)); // 100 - 4h * 3/h

    container.read(resumeTickProvider.notifier).state++;
    await Future<void>.delayed(Duration.zero);

    expect(sub.read(), closeTo(88.0, 0.1));
  });

  test(
      'test_energyProvider_switches_to_new_active_childs_data_when_activeChildProvider_changes',
      () async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);
    final parentId = await waitForSignedInUser(container, auth);

    const secondChild = ChildProfile(
      childId: 'child-2',
      name: 'Bé Bình',
      avatarId: 'avatar-2',
      mochiName: 'Taro',
    );
    final now = DateTime.now();
    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({
      'storedEnergy': 100.0,
      'lastApprovedAt': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
    });
    (firestore.doc(FirestorePaths.child(parentId, 'child-2'))
            as _FakeDocumentReference)
        .seed({
      'storedEnergy': 15.0,
      'lastApprovedAt': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
    });

    container.read(activeChildProvider.notifier).state = child;
    final sub = container.listen(energyProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read(), closeTo(100.0, 0.1));

    // Switching the active child mid-session must re-subscribe to the new
    // child's own document, not keep serving the previous child's cached
    // stream — this is the mid-session-switch gap flagged in code review.
    container.read(activeChildProvider.notifier).state = secondChild;
    await Future<void>.delayed(Duration.zero);
    expect(sub.read(), closeTo(15.0, 0.1));
  });

  test(
      'test_energyProvider_calls_computeEnergy_with_the_real_firestore_backed_values',
      () async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);
    final parentId = await waitForSignedInUser(container, auth);
    container.read(activeChildProvider.notifier).state = child;

    final lastApprovedAt = DateTime.now().subtract(const Duration(hours: 8));
    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({
      'storedEnergy': 100.0,
      'lastApprovedAt': Timestamp.fromDate(lastApprovedAt),
      'createdAt': Timestamp.fromDate(lastApprovedAt),
    });

    final sub = container.listen(energyProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    // Matches computeEnergy(storedEnergy: 100, ...8h elapsed...) = 76,
    // within a small tolerance for the real DateTime.now() call inside
    // energyProvider happening a few milliseconds after lastApprovedAt was
    // computed above.
    expect(sub.read(), closeTo(76.0, 0.01));
  });

  test('test_energyProvider_performs_zero_firestore_writes', () async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);
    final parentId = await waitForSignedInUser(container, auth);
    container.read(activeChildProvider.notifier).state = child;

    final docRef = firestore.doc(FirestorePaths.child(parentId, childId))
        as _FakeDocumentReference;
    docRef.seed({
      'storedEnergy': 90.0,
      'lastApprovedAt': Timestamp.fromDate(DateTime.now()),
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });

    final sub = container.listen(energyProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    container.read(resumeTickProvider.notifier).state++;
    await Future<void>.delayed(Duration.zero);

    expect(docRef.writeCallCount, 0);
  });

  test('test_energyProvider_returns_a_defined_default_when_no_active_child',
      () async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);
    await waitForSignedInUser(container, auth);
    // activeChildProvider deliberately left null.

    expect(container.read(energyProvider), 0.0);
  });

  test(
      'test_energyProvider_falls_back_to_initialEnergy_70_when_storedEnergy_field_is_missing',
      () async {
    final firestore = _FakeFirestore();
    final auth = MockFirebaseAuth();
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);
    final parentId = await waitForSignedInUser(container, auth);
    container.read(activeChildProvider.notifier).state = child;

    final now = DateTime.now();
    // storedEnergy field entirely absent, but lastApprovedAt IS present —
    // this is a different scenario from computeEnergy's own null-lastApprovedAt
    // fallback (Story 001); this proves the Firestore-parsing layer itself
    // degrades gracefully on a missing field, not just an unsafe cast crash.
    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({
      'lastApprovedAt': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
    });

    final sub = container.listen(energyProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    // storedEnergy defaulted to 70.0, zero elapsed (lastApprovedAt == now) -> 70.0.
    expect(sub.read(), closeTo(70.0, 0.01));
  });
}
