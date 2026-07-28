// Run with:
//   cd src && flutter test ../tests/unit/currency_system/xu_balance_provider_test.dart
//
// Hand-rolled minimal Firestore fake supporting .doc().snapshots() (a live
// Stream), same Stream.multi()-based replay-then-forward technique already
// established by energy_provider_test.dart (Time & Decay Story 002) and
// GameEventBus (Bridge Story 001).

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
import 'package:pet_quest/providers/currency_providers.dart';

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

  void seedError(Object error) {
    _controller.addError(error);
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

  test('test_xuBalanceProvider_reads_via_doc_snapshots_not_collection_snapshots',
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
        .seed({'xuBalance': 42});

    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 42);
  });

  test('test_xuBalanceProvider_resolves_to_0_when_no_child_is_active', () async {
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

    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });

  test('test_xuBalanceProvider_resolves_to_0_when_no_parent_is_signed_in',
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

    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });

  test('test_xuBalanceProvider_defaults_to_0_when_the_xuBalance_field_is_missing',
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
        .seed({'name': 'Bé An'}); // no xuBalance field at all

    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });

  test('test_xuBalanceProvider_handles_xuBalance_stored_as_a_double', () async {
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
        .seed({'xuBalance': 42.0});

    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 42);
    expect(sub.read().value, isA<int>());
  });

  test('test_xuBalanceProvider_clamps_a_negative_stored_value_to_0', () async {
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
        .seed({'xuBalance': -15});

    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });

  test('test_xuBalanceProvider_is_not_autoDispose', () async {
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
    docRef.seed({'xuBalance': 10});

    final sub1 = container.listen(xuBalanceProvider, (_, __) {});
    await Future<void>.delayed(Duration.zero);
    sub1.close();
    // Give the provider a chance to tear down IF it were .autoDispose.
    await Future<void>.delayed(Duration.zero);

    final sub2 = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub2.close);
    await Future<void>.delayed(Duration.zero);

    // An .autoDispose provider would re-subscribe to the underlying stream
    // from scratch here; a session-lifetime provider keeps its original
    // subscription alive across the listener churn above.
    expect(docRef.subscribeCount, 1);
    expect(sub2.read().value, 10);
  });

  test(
      'test_two_rapid_document_updates_both_emit_through_the_providers_mapping_in_order',
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
    docRef.seed({'xuBalance': 20});

    final emitted = <int>[];
    final sub = container.listen(xuBalanceProvider, (_, next) {
      if (next.hasValue) emitted.add(next.value!);
    });
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    docRef.seed({'xuBalance': 40});
    await Future<void>.delayed(Duration.zero);
    docRef.seed({'xuBalance': 60});
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [20, 40, 60]);
  });

  test('test_uses_the_centralized_FirestorePaths_child_constant_no_inline_path_string',
      () {
    final source =
        File('lib/providers/currency_providers.dart').readAsStringSync();

    expect(source.contains("'families/"), isFalse);
    expect(source.contains('FirestorePaths.child'), isTrue);
  });

  test(
      'test_a_snapshots_stream_error_surfaces_as_AsyncError_without_crashing',
      () async {
    // ADR-0008 Decision §5: "never crash, never render a negative" — this
    // proves the "never crash" half specifically for a genuine query
    // failure (e.g. permission-denied), not just a missing/negative value.
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
    docRef.seed({'xuBalance': 10});

    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value, 10);

    docRef.seedError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().hasError, isTrue);
    expect(sub.read().error, isA<FirebaseException>());
  });

  test(
      'test_switching_the_active_child_rebuilds_the_provider_scoped_to_the_new_child',
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
    (firestore.doc(FirestorePaths.child(parentId, childId))
            as _FakeDocumentReference)
        .seed({'xuBalance': 10});
    (firestore.doc(FirestorePaths.child(parentId, 'child-2'))
            as _FakeDocumentReference)
        .seed({'xuBalance': 99});

    container.read(activeChildProvider.notifier).state = child;
    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value, 10);

    // Switching to a different active child (e.g. a sibling profile) must
    // re-subscribe to the NEW child's own document, not keep serving the
    // previous child's cached stream.
    container.read(activeChildProvider.notifier).state = secondChild;
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value, 99);
  });

  test('test_signing_out_mid_subscription_resolves_to_0', () async {
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
        .seed({'xuBalance': 10});

    final sub = container.listen(xuBalanceProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value, 10);

    await auth.signOut();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, 0);
  });
}
