// Run with:
//   cd src && flutter test ../tests/unit/seed_buffer/seed_count_provider_test.dart
//
// Story 002 of the Seed Buffer epic (ADR-0012 Decision §3). Mirrors
// xu_balance_provider_test.dart's (Currency System, ADR-0008) hand-rolled
// minimal Firestore fake supporting .doc().snapshots() (a live Stream),
// same Stream.multi()-based replay-then-forward technique.

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/seed_buffer_providers.dart';

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
  int subscribeCount = 0;

  void seed(Map<String, dynamic>? data) {
    _data = data;
    _controller.add(_FakeDocumentSnapshot(data));
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.multi((controller) {
      subscribeCount++;
      controller.add(_FakeDocumentSnapshot(_data));
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = sub.cancel;
    });
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

  // --- Test Evidence (1): positive value passes through unchanged ---
  test('test_seedCountProvider_positive_value_passes_through_unchanged',
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

    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({'seedCount': 3});

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 3);
  });

  // --- Test Evidence (2) / AC-4 (Clamp at zero) ---
  test('test_seedCountProvider_clamps_a_negative_stored_value_to_0', () async {
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

    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({'seedCount': -2});

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });

  // --- Test Evidence (3a): int-stored value casts correctly ---
  test('test_seedCountProvider_handles_seedCount_stored_as_an_int', () async {
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

    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({'seedCount': 7});

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 7);
    expect(sub.read().value, isA<int>());
  });

  // --- Test Evidence (3b): double-stored value casts correctly (num? cast) ---
  test('test_seedCountProvider_handles_seedCount_stored_as_a_double', () async {
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

    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({'seedCount': 7.0});

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 7);
    expect(sub.read().value, isA<int>());
  });

  // --- Test Evidence (4): null/absent field defaults to 0 ---
  test(
      'test_seedCountProvider_defaults_to_0_when_the_seedCount_field_is_missing',
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

    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({'name': 'Bé An'}); // no seedCount field at all

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });

  // --- Test Evidence (5a): null childId resolves to 0 ---
  test('test_seedCountProvider_resolves_to_0_when_no_child_is_active',
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

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });

  // --- Test Evidence (5b): null parentId resolves to 0 ---
  test('test_seedCountProvider_resolves_to_0_when_no_parent_is_signed_in',
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
    // Deliberately never sign in.
    container.read(activeChildProvider.notifier).state = child;

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });

  // --- Test Evidence (5c): Stream.value(0) resolves immediately rather than
  // hanging in perpetual `isLoading` — the exact defect a `Stream.empty()`
  // null-guard (ADR-0012 §3's own illustrative snippet) would produce, per
  // this story's explicit correction note. ---
  test(
      'test_seedCountProvider_does_not_hang_in_perpetual_loading_when_signed_out',
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
    // Deliberately never sign in and never select a child — both guard
    // conditions null at once.

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    // Two delays: one for `authStateProvider` itself to settle from its own
    // initial `AsyncLoading` to `AsyncData(null)`, a second for
    // `seedCountProvider`'s consequent rebuild to emit through
    // `Stream.value(0)` — matches the sibling
    // `test_xuBalanceProvider_resolves_to_0_when_no_parent_is_signed_in`
    // technique in `xu_balance_provider_test.dart`.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final result = sub.read();
    expect(result.isLoading, isFalse);
    expect(result.hasValue, isTrue);
    expect(result.value, 0);
  });

  // --- Test Evidence (6) / AC-6 (partial): a simulated post-3-decrement
  // state reads back the correct value. Decrements are seeded directly on
  // the fake document (NOT via a real approve flow — Parent Approval #11
  // does not exist yet) per the story's explicit scope note. ---
  test(
      'test_seedCountProvider_reads_back_correct_value_after_simulated_decrements',
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

    final docRef = firestore.doc(FirestorePaths.child(parentId, childId))
        as _FakeDocumentReference;
    // Starts at 5 pending (5 submits), then 3 approve/reject decrements are
    // simulated directly on the document, matching the write contract
    // ADR-0012 Decision §2 defines for Parent Approval's own batch
    // (`FieldValue.increment(-1)`, never absolute set) without depending on
    // that epic existing.
    docRef.seed({'seedCount': 5});

    final sub = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value, 5);

    docRef.seed({'seedCount': 4});
    await Future<void>.delayed(Duration.zero);
    docRef.seed({'seedCount': 3});
    await Future<void>.delayed(Duration.zero);
    docRef.seed({'seedCount': 2});
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 2);
  });

  // --- AC: reads via FirestorePaths.child(), not an inline path string ---
  test(
      'test_uses_the_centralized_FirestorePaths_child_constant_no_inline_path_string',
      () {
    final source =
        File('lib/providers/seed_buffer_providers.dart').readAsStringSync();

    expect(source.contains("'families/"), isFalse);
    expect(source.contains('FirestorePaths.child'), isTrue);
  });

  // --- AC: casts as `(x as num?)?.toInt() ?? 0`, never `as int?` ---
  test('test_seedCountProvider_casts_using_num_not_int', () {
    final source =
        File('lib/providers/seed_buffer_providers.dart').readAsStringSync();

    expect(
      source.contains("(doc.data()?['seedCount'] as num?)?.toInt() ?? 0"),
      isTrue,
    );
    expect(source.contains("as int?"), isFalse);
  });

  // --- AC: NOT .autoDispose ---
  test('test_seedCountProvider_is_not_autoDispose', () async {
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
    docRef.seed({'seedCount': 1});

    final sub1 = container.listen(seedCountProvider, (_, __) {});
    await Future<void>.delayed(Duration.zero);
    sub1.close();
    // Give the provider a chance to tear down IF it were .autoDispose.
    await Future<void>.delayed(Duration.zero);

    final sub2 = container.listen(seedCountProvider, (_, __) {});
    addTearDown(sub2.close);
    await Future<void>.delayed(Duration.zero);

    // An .autoDispose provider would re-subscribe to the underlying stream
    // from scratch here; a session-lifetime provider keeps its original
    // subscription alive across the listener churn above.
    expect(docRef.subscribeCount, 1);
    expect(sub2.read().value, 1);
  });
}
