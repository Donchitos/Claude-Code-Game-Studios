// Run with:
//   cd src && flutter test ../tests/integration/auth_account/parent_login_test.dart
//
// Dart's `package:` URI resolution is rooted at the invoking working
// directory's `.dart_tool/package_config.json`, not at this file's physical
// location — so this file can freely `import 'package:pet_quest/...'` while
// living in the repo's top-level tests/ directory instead of src/test/.
// Future auth_account stories' test files should follow the same pattern and
// invocation command.
//
// Uses a hand-rolled minimal Firestore fake instead of `fake_cloud_firestore`
// — as of writing, `fake_cloud_firestore ^4.1.1` (the latest resolvable
// version) does not compile against `cloud_firestore ^6.7.1`: its
// `MockWriteBatch.update` override doesn't match `WriteBatch`'s now-generic
// `update<T>` signature (a real upstream incompatibility, not a version
// constraint issue — verified by attempting the actual test run, not
// assumed). `AuthRepository` only calls `.doc(path).get()`/`.set()`, so a
// tiny fake covering just that surface is enough; revisit if a future
// `fake_cloud_firestore` release fixes the incompatibility.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:pet_quest/core/auth_repository.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/providers/auth_providers.dart';

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
  Map<String, dynamic>? _stored;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeDocumentSnapshot(_stored);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _stored = data;
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
  const parentId = 'parent-123';
  const email = 'parent@example.com';
  const password = 'correct-password';

  // `authStateProvider.future` resolves to whichever value first took the
  // provider out of AsyncLoading — MockFirebaseAuth emits an initial `null`
  // synchronously on construction, so `.future` alone would just return that
  // stale null instead of waiting for the later post-signIn emission. This
  // waits for the specific "a non-null user arrived" event instead.
  Future<User> waitForSignedInUser(ProviderContainer container) {
    final completer = Completer<User>();
    late final ProviderSubscription<AsyncValue<User?>> sub;
    sub = container.listen(authStateProvider, (previous, next) {
      final user = next.value; // riverpod 3.x: .value is the safe nullable accessor (ADR-0002 correction)
      if (user != null && !completer.isCompleted) {
        completer.complete(user);
      }
    });
    completer.future.whenComplete(sub.close);
    return completer.future.timeout(const Duration(seconds: 5));
  }

  ProviderContainer buildContainer({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) {
    return ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
  }

  test(
      'AC1: successful sign-in resolves authStateProvider and '
      'parentProfileProvider from the seeded family doc', () async {
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: parentId, email: email));
    final firestore = _FakeFirestore();
    await firestore.doc(FirestorePaths.family(parentId)).set({
      'email': email,
      'displayName': 'Parent Test',
      'fcmToken': null,
      'createdAt': Timestamp.now(),
    });

    final container = buildContainer(auth: auth, firestore: firestore);
    addTearDown(container.dispose);

    // Start waiting BEFORE signing in — authStateChanges() is a broadcast
    // stream with no replay, so subscribing after signIn() emits would miss
    // that event.
    final userFuture = waitForSignedInUser(container);
    await container.read(authRepositoryProvider).signIn(email: email, password: password);

    final user = await userFuture;
    expect(user.uid, parentId);

    final profile = await container.read(parentProfileProvider.future);
    expect(profile, isNotNull);
    expect(profile!.parentId, parentId);
    expect(profile.email, email);
  });

  test(
      'AC2: wrong password surfaces one generic AuthSignInFailure and never '
      'reveals whether the email exists', () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #signInWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

    final firestore = _FakeFirestore();
    final container = buildContainer(auth: auth, firestore: firestore);
    addTearDown(container.dispose);

    container.listen(authStateProvider, (_, _) {});

    final repo = container.read(authRepositoryProvider);
    await expectLater(
      () => repo.signIn(email: email, password: password),
      throwsA(isA<AuthSignInFailure>().having(
        (e) => e.message,
        'message',
        isNot(contains(email)), // never echoes the email back — proves it's generic
      )),
    );

    final user = await container.read(authStateProvider.future);
    expect(user, isNull);
  });

  test(
      'regression: AuthSignInFailure has the identical message for '
      'invalid-credential, user-not-found, and wrong-password codes '
      '(locks down the no-per-code-branching rule — proves the message '
      'itself never varies, not just the exception type — regardless of '
      'which code firebase_auth ^6.5.6 actually returns)', () async {
    final messages = <String>{};
    for (final code in ['invalid-credential', 'user-not-found', 'wrong-password']) {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(
        #signInWithEmailAndPassword,
        null,
        {#email: email, #password: password},
      )).on(auth).thenThrow(FirebaseAuthException(code: code));

      final repo = AuthRepository(auth: auth, firestore: _FakeFirestore());

      try {
        await repo.signIn(email: email, password: password);
        fail('code=$code should have thrown AuthSignInFailure');
      } on AuthSignInFailure catch (e) {
        messages.add(e.message);
      }
    }
    expect(messages, hasLength(1),
        reason: 'all 3 codes must produce the exact same message — '
            'got: $messages');
  });

  test(
      'AC3: successful sign-in with no families/{parentId} doc resolves '
      'parentProfileProvider to null, does not throw (first-time setup '
      'signal)', () async {
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: parentId, email: email));
    final firestore = _FakeFirestore(); // no seeded doc
    final container = buildContainer(auth: auth, firestore: firestore);
    addTearDown(container.dispose);

    final userFuture = waitForSignedInUser(container);
    await container.read(authRepositoryProvider).signIn(email: email, password: password);

    // Confirm sign-in actually propagated (not just coincidentally null
    // because authStateProvider was still AsyncLoading) before trusting the
    // "no doc" null result below.
    await userFuture;

    final profile = await container.read(parentProfileProvider.future);
    expect(profile, isNull);
  });
}
