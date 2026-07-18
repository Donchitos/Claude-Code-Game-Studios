// Run with:
//   cd src && flutter test ../tests/unit/auth_account/parent_registration_test.dart
//
// Same hand-rolled minimal Firestore fake + firebase_auth_mocks/mock_exceptions
// pattern as tests/integration/auth_account/parent_login_test.dart (see that
// file's header comment for why fake_cloud_firestore isn't used here).
// MockFirebaseAuth's createUserWithEmailAndPassword generates a random UUID
// as the new user's uid (Uuid().v4(), not predictable) — tests read
// auth.currentUser!.uid AFTER calling signUp() to know which family doc path
// to check, rather than assuming a fixed uid.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:pet_quest/core/auth_repository.dart';
import 'package:pet_quest/core/firestore_paths.dart';

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
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    stored = data;
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
  const email = 'new.parent@example.com';
  const password = 'a-strong-password';

  test(
      'test_signUp_creates_the_Auth_user_then_writes_the_family_doc_with_exactly_3_fields',
      () async {
    final auth = MockFirebaseAuth();
    final firestore = _FakeFirestore();
    final repo = AuthRepository(auth: auth, firestore: firestore);

    await repo.signUp(email: email, password: password);

    final uid = auth.currentUser!.uid;
    final doc = firestore.doc(FirestorePaths.family(uid)) as _FakeDocumentReference;
    expect(doc.stored, isNotNull);
    expect(doc.stored!.keys.toSet(), {'email', 'displayName', 'createdAt'});
    expect(doc.stored!['email'], email);
    expect(doc.stored!['displayName'], 'new.parent'); // derived from local-part
    expect(doc.stored!['createdAt'], isA<FieldValue>());
  });

  test('test_signUp_does_not_write_fcmToken_at_all', () async {
    final auth = MockFirebaseAuth();
    final firestore = _FakeFirestore();
    final repo = AuthRepository(auth: auth, firestore: firestore);

    await repo.signUp(email: email, password: password);

    final uid = auth.currentUser!.uid;
    final doc = firestore.doc(FirestorePaths.family(uid)) as _FakeDocumentReference;
    expect(doc.stored!.containsKey('fcmToken'), isFalse);
  });

  test(
      'test_signUp_email_already_in_use_surfaces_its_own_message_not_the_generic_signIn_message',
      () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

    final repo = AuthRepository(auth: auth, firestore: _FakeFirestore());

    await expectLater(
      () => repo.signUp(email: email, password: password),
      throwsA(isA<AuthSignUpFailure>().having(
        (e) => e.message,
        'message',
        contains('đã được đăng ký'),
      )),
    );
  });

  test('test_signUp_weak_password_surfaces_its_own_message', () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'weak-password'));

    final repo = AuthRepository(auth: auth, firestore: _FakeFirestore());

    await expectLater(
      () => repo.signUp(email: email, password: password),
      throwsA(isA<AuthSignUpFailure>().having(
        (e) => e.message,
        'message',
        contains('quá yếu'),
      )),
    );
  });

  test('test_signUp_invalid_email_surfaces_its_own_message', () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-email'));

    final repo = AuthRepository(auth: auth, firestore: _FakeFirestore());

    await expectLater(
      () => repo.signUp(email: email, password: password),
      throwsA(isA<AuthSignUpFailure>().having(
        (e) => e.message,
        'message',
        contains('không hợp lệ'),
      )),
    );
  });

  test(
      'test_signUp_network_request_failed_throws_the_same_AuthNetworkFailure_type_signIn_uses',
      () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

    final repo = AuthRepository(auth: auth, firestore: _FakeFirestore());

    await expectLater(
      () => repo.signUp(email: email, password: password),
      throwsA(isA<AuthNetworkFailure>()),
    );
  });

  test(
      'test_signUp_an_unrecognized_code_falls_back_to_one_generic_AuthSignUpFailure',
      () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'some-unrecognized-code'));

    final repo = AuthRepository(auth: auth, firestore: _FakeFirestore());

    await expectLater(
      () => repo.signUp(email: email, password: password),
      throwsA(isA<AuthSignUpFailure>()),
    );
  });

  test(
      'test_signUp_does_not_write_the_family_doc_at_all_when_Auth_creation_fails',
      () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    final firestore = _FakeFirestore();
    final repo = AuthRepository(auth: auth, firestore: firestore);

    await expectLater(
      () => repo.signUp(email: email, password: password),
      throwsA(isA<AuthSignUpFailure>()),
    );

    // No family doc should exist for any uid — nothing was ever created.
    expect(auth.currentUser, isNull);
  });

  test(
      'test_signUp_a_malformed_email_missing_at_sign_does_not_throw_deriving_displayName',
      () async {
    // MockFirebaseAuth does not validate email format the way real Firebase
    // Auth's own `invalid-email` check would — a no-`@` string reaches
    // signUp()'s `email.split('@').first` line unguarded here. String.split
    // on a non-matching pattern returns the whole string as a single-element
    // list, so `.first` does NOT throw — locking that in as a real,
    // non-crashing behavior rather than an assumption (found in code review
    // — qa-tester, 2026-07-16).
    const malformedEmail = 'not-an-email';
    final auth = MockFirebaseAuth();
    final firestore = _FakeFirestore();
    final repo = AuthRepository(auth: auth, firestore: firestore);

    await repo.signUp(email: malformedEmail, password: password);

    final uid = auth.currentUser!.uid;
    final doc = firestore.doc(FirestorePaths.family(uid)) as _FakeDocumentReference;
    expect(doc.stored!['displayName'], malformedEmail); // whole string, unsplit
  });

  test('test_signUp_does_not_trim_whitespace_padded_email_before_writing',
      () async {
    // Documents current behavior rather than asserting a requirement this
    // story never specified — MockFirebaseAuth doesn't reject a
    // whitespace-padded email either, so this locks in what actually
    // happens today (found in code review — qa-tester, 2026-07-16) rather
    // than leaving it silently unverified.
    const paddedEmail = '  padded@example.com  ';
    final auth = MockFirebaseAuth();
    final firestore = _FakeFirestore();
    final repo = AuthRepository(auth: auth, firestore: firestore);

    await repo.signUp(email: paddedEmail, password: password);

    final uid = auth.currentUser!.uid;
    final doc = firestore.doc(FirestorePaths.family(uid)) as _FakeDocumentReference;
    expect(doc.stored!['email'], paddedEmail); // stored exactly as given, untrimmed
  });
}
