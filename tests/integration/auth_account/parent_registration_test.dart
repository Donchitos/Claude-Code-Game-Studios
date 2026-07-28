// Run with:
//   cd src && flutter test ../tests/integration/auth_account/parent_registration_test.dart
//
// Deliberately scoped to what tests/unit/auth_account/parent_registration_test.dart
// does NOT cover: real provider/DI wiring through authRepositoryProvider and
// authStateProvider, plus one deeper displayName-derivation edge case. The
// exhaustive per-error-code message matrix (email-already-in-use,
// weak-password, invalid-email, network-request-failed, unrecognized-code,
// no-write-on-failure) already lives in the unit test file against a plain
// AuthRepository instance — duplicating it here against a full
// ProviderContainer added maintenance overhead with no incremental coverage
// value (found in code review — flame-widget-specialist, 2026-07-16), so it
// was trimmed rather than kept as a second copy.
//
// Same hand-rolled Firestore fake + MockFirebaseAuth pattern as
// parent_login_test.dart (Story 001) — see that file's header comment for
// why fake_cloud_firestore isn't used. MockFirebaseAuth.createUserWithEmailAndPassword
// (confirmed in the installed firebase_auth_mocks 0.15.2 source) generates a
// random UUID uid and emits it through authStateChanges(), same as
// MockFirebaseAuth's sign-in path — so uid must be read back dynamically
// (never hardcoded) to know which families/{uid} path to check.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/providers/auth_providers.dart';

class _RecordedWrite {
  _RecordedWrite(this.path, this.data);
  final String path;
  final Map<String, dynamic> data;
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path, this._writes);
  final String path;
  final List<_RecordedWrite> _writes;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _writes.add(_RecordedWrite(path, data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final writes = <_RecordedWrite>[];

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _FakeDocumentReference(path, writes);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const email = 'quang.dao@example.com';
  const password = 'a-strong-password';

  // Same rationale as parent_login_test.dart's waitForSignedInUser: the
  // mock emits its own initial null synchronously, so `.future` alone would
  // return that stale value instead of waiting for the post-signUp emission.
  Future<User> waitForSignedInUser(ProviderContainer container) {
    final completer = Completer<User>();
    late final ProviderSubscription<AsyncValue<User?>> sub;
    sub = container.listen(authStateProvider, (previous, next) {
      final user = next.value;
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
      'signUp creates the Firebase Auth user then writes families/{uid} with '
      'exactly email/displayName/createdAt, displayName derived from the '
      'email local-part', () async {
    final auth = MockFirebaseAuth();
    final firestore = _FakeFirestore();
    final container = buildContainer(auth: auth, firestore: firestore);
    addTearDown(container.dispose);

    final userFuture = waitForSignedInUser(container);
    await container.read(authRepositoryProvider).signUp(email: email, password: password);
    final user = await userFuture;

    expect(firestore.writes, hasLength(1));
    final write = firestore.writes.single;
    expect(write.path, FirestorePaths.family(user.uid));
    expect(write.data.keys.toSet(), {'email', 'displayName', 'createdAt'});
    expect(write.data['email'], email);
    expect(write.data['displayName'], 'quang.dao'); // derived from local-part
    expect(write.data['createdAt'], isA<FieldValue>());
    expect(write.data.containsKey('fcmToken'), isFalse);
  });

  test(
      'signUp derives displayName correctly for an email with a "+" alias '
      '(local-part includes everything before @, not just the base name)',
      () async {
    final auth = MockFirebaseAuth();
    final firestore = _FakeFirestore();
    final container = buildContainer(auth: auth, firestore: firestore);
    addTearDown(container.dispose);

    final userFuture = waitForSignedInUser(container);
    await container.read(authRepositoryProvider).signUp(
          email: 'quang.dao+test@example.com',
          password: password,
        );
    await userFuture;

    expect(firestore.writes.single.data['displayName'], 'quang.dao+test');
  });
}
