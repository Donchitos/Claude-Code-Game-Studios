// Run with:
//   cd src && flutter test ../tests/unit/auth_account/pin_verification_test.dart
//
// Uses the same hand-rolled minimal Firestore fake pattern as
// child_profile_data_test.dart (fake_cloud_firestore is incompatible with
// cloud_firestore ^6.7.1 — see parent_login_test.dart's header comment).
// `_FakeSecureStorage` is a small in-memory `Map<String, String>` fake for
// `flutter_secure_storage` (no plugin package exists for it, same as
// firebase_messaging in fcm_token_refresh_test.dart).
//
// PBKDF2 hashes are computed for real via `hashPin` (100k iterations, off an
// isolate) rather than hardcoded expected-hash strings — this both proves
// the actual crypto round-trips correctly and avoids maintaining a brittle
// hardcoded vector. Lockout-expiry timing uses `PinVerificationRepository`'s
// injectable `now` clock (mirrors ADR-0005's `computeEnergy` rule) instead of
// real sleeps — test-standards.md forbids time-dependent, non-deterministic
// assertions, and a real 60s sleep would also just be slow.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/child_profile_repository.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/core/pin_crypto.dart';
import 'package:pet_quest/core/pin_verification_repository.dart';
import 'package:pet_quest/core/secure_storage_provider.dart';
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
  const parentId = 'parent-1';
  const childId = 'child-1';
  const correctPin = '1234';

  Future<ChildProfileRepository> seedCredentials(
    _FakeFirestore firestore, {
    required String rawPin,
  }) async {
    final salt = generatePinSalt();
    final hash = await hashPin(rawPin, salt);
    (firestore.doc(FirestorePaths.childCredentials(parentId, childId))
            as _FakeDocumentReference)
        .stored = {'pinHash': hash, 'pinSalt': encodePinSalt(salt)};
    return ChildProfileRepository(firestore: firestore);
  }

  group('pin_crypto helpers', () {
    test('test_hashPin_is_deterministic_for_the_same_pin_and_salt', () async {
      final salt = generatePinSalt();
      final first = await hashPin('1234', salt);
      final second = await hashPin('1234', salt);

      expect(first, second);
    });

    test('test_hashPin_differs_for_different_pins_with_the_same_salt',
        () async {
      final salt = generatePinSalt();
      final hashA = await hashPin('1234', salt);
      final hashB = await hashPin('5678', salt);

      expect(hashA, isNot(hashB));
    });

    test('test_generatePinSalt_produces_16_bytes', () {
      expect(generatePinSalt().length, 16);
    });

    test('test_generatePinSalt_produces_different_salts_each_call', () {
      final saltA = generatePinSalt();
      final saltB = generatePinSalt();

      expect(saltA, isNot(saltB));
    });

    test('test_encodePinSalt_decodePinSalt_round_trips', () {
      final salt = generatePinSalt();

      expect(decodePinSalt(encodePinSalt(salt)), salt);
    });
  });

  group('PinVerificationRepository.verify', () {
    test('test_verify_returns_true_for_the_correct_pin', () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );

      final result = await repo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: correctPin,
      );

      expect(result, isTrue);
    });

    test('test_verify_returns_false_for_a_wrong_pin', () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );

      final result = await repo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: '9999',
      );

      expect(result, isFalse);
    });

    test(
        'test_verify_resets_failCount_after_correct_pin_following_prior_failures',
        () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
      );

      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w1');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w2');
      expect(await storage.read(key: 'pin_fail_$childId'), '2');

      final result = await repo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: correctPin,
      );

      expect(result, isTrue);
      expect(await storage.read(key: 'pin_fail_$childId'), isNull);
      expect(await storage.read(key: 'pin_lock_$childId'), isNull);
    });

    test('test_verify_locks_out_after_3_consecutive_failures', () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      final now = DateTime(2026, 7, 15, 12);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
        now: () => now,
      );

      final r1 = await repo.verify(parentId: parentId, childId: childId, rawPin: 'w1');
      final r2 = await repo.verify(parentId: parentId, childId: childId, rawPin: 'w2');
      final r3 = await repo.verify(parentId: parentId, childId: childId, rawPin: 'w3');

      expect([r1, r2, r3], [false, false, false]);
      final lockUntilRaw = await storage.read(key: 'pin_lock_$childId');
      expect(lockUntilRaw, isNotNull);
      expect(
        int.parse(lockUntilRaw!),
        now.add(const Duration(seconds: 60)).millisecondsSinceEpoch,
      );
    });

    test(
        'test_verify_rejects_a_4th_attempt_without_fetching_credentials_while_locked',
        () async {
      // No credentials seeded for this childId at all — if the lockout
      // short-circuit didn't work, verify() would throw
      // PinCredentialsUnavailable instead of returning false, proving the
      // credentials fetch (and therefore PBKDF2) never ran while locked.
      final firestore = _FakeFirestore();
      final storage = _FakeSecureStorage();
      final now = DateTime(2026, 7, 15, 12);
      await storage.write(
        key: 'pin_lock_$childId',
        value: now.add(const Duration(seconds: 30)).millisecondsSinceEpoch.toString(),
      );
      final repo = PinVerificationRepository(
        childProfileRepository: ChildProfileRepository(firestore: firestore),
        secureStorage: storage,
        now: () => now,
      );

      final result = await repo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: correctPin,
      );

      expect(result, isFalse);
    });

    test(
        'test_verify_never_calls_hashPinFn_while_locked_out',
        () async {
      // Direct spy on the injected hash function (recommended in code
      // review, complementing the indirect
      // no-PinCredentialsUnavailable-thrown proof above with a assertion of
      // the literal AC/QA wording: "assert the hash function is not
      // invoked").
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      final now = DateTime(2026, 7, 15, 12);
      var hashCallCount = 0;
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
        now: () => now,
        hashPinFn: (rawPin, salt) {
          hashCallCount++;
          return hashPin(rawPin, salt);
        },
      );

      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w1');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w2');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w3');
      expect(hashCallCount, 3);

      await repo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: correctPin,
      );

      expect(hashCallCount, 3); // unchanged — 4th call never reached hashPinFn
    });

    test(
        'test_verify_is_unlocked_exactly_at_the_lockUntil_boundary', () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      var currentTime = DateTime(2026, 7, 15, 12);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
        now: () => currentTime,
      );
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w1');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w2');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w3');
      final lockUntilRaw = await storage.read(key: 'pin_lock_$childId');
      currentTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lockUntilRaw!));

      // now == lockUntil exactly — pins down the inclusive `>=` boundary in
      // _isLockedOut (a future `>` regression would fail this test).
      final result = await repo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: correctPin,
      );

      expect(result, isTrue);
    });

    test(
        'test_verify_serializes_concurrent_calls_for_the_same_childId_no_lost_increment',
        () async {
      // Regression from code review: two near-simultaneous verify() calls
      // for the same child (a realistic double-tap) must not race on the
      // failCount read-modify-write and lose an increment.
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
      );

      final results = await Future.wait([
        repo.verify(parentId: parentId, childId: childId, rawPin: 'wA'),
        repo.verify(parentId: parentId, childId: childId, rawPin: 'wB'),
        repo.verify(parentId: parentId, childId: childId, rawPin: 'wC'),
      ]);

      expect(results, [false, false, false]);
      // All 3 concurrent failures landed — not lost to a lost-update race —
      // so the 3rd one engaged the lockout.
      expect(await storage.read(key: 'pin_lock_$childId'), isNotNull);
    });

    test(
        'test_verify_throws_PinCredentialsUnavailable_when_no_credentials_doc_exists',
        () async {
      final firestore = _FakeFirestore();
      final repo = PinVerificationRepository(
        childProfileRepository: ChildProfileRepository(firestore: firestore),
        secureStorage: _FakeSecureStorage(),
      );

      await expectLater(
        () => repo.verify(
          parentId: parentId,
          childId: childId,
          rawPin: correctPin,
        ),
        throwsA(isA<PinCredentialsUnavailable>()),
      );
    });

    test(
        'test_verify_lockout_expires_after_60_seconds_and_allows_a_fresh_attempt',
        () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      var currentTime = DateTime(2026, 7, 15, 12);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
        now: () => currentTime,
      );

      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w1');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w2');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w3');

      currentTime = currentTime.add(const Duration(seconds: 30));
      final stillLocked = await repo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: correctPin,
      );
      expect(stillLocked, isFalse);

      currentTime = currentTime.add(const Duration(seconds: 31)); // total 61s
      final result = await repo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: correctPin,
      );
      expect(result, isTrue);
    });
  });

  group('PinVerificationRepository.getLockUntil', () {
    test('test_getLockUntil_returns_null_when_never_locked', () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );

      expect(await repo.getLockUntil(childId), isNull);
    });

    test('test_getLockUntil_returns_the_expiry_after_3_failures', () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      final now = DateTime(2026, 7, 15, 12);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
        now: () => now,
      );

      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w1');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w2');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w3');

      expect(
        await repo.getLockUntil(childId),
        now.add(PinVerificationRepository.lockoutDuration),
      );
    });

    test('test_getLockUntil_returns_null_once_the_window_has_passed',
        () async {
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      var currentTime = DateTime(2026, 7, 15, 12);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
        now: () => currentTime,
      );

      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w1');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w2');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w3');

      currentTime = currentTime.add(const Duration(seconds: 61));

      expect(await repo.getLockUntil(childId), isNull);
    });

    test(
        'test_getLockUntil_does_not_mutate_storage_it_is_read_only',
        () async {
      // getLockUntil must not clear an expired lockout as a side effect
      // (that stays verify()'s job) — a read-only accessor called from the
      // UI's countdown display must not have write side effects.
      final firestore = _FakeFirestore();
      final childRepo = await seedCredentials(firestore, rawPin: correctPin);
      final storage = _FakeSecureStorage();
      var currentTime = DateTime(2026, 7, 15, 12);
      final repo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
        now: () => currentTime,
      );

      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w1');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w2');
      await repo.verify(parentId: parentId, childId: childId, rawPin: 'w3');
      currentTime = currentTime.add(const Duration(seconds: 61));

      await repo.getLockUntil(childId);

      // The (now-expired) lockUntil key is still physically present in
      // storage — getLockUntil only interpreted it as "not locked", it did
      // not delete it.
      expect(await storage.read(key: 'pin_lock_$childId'), isNotNull);
    });
  });

  group('pinVerificationActionsProvider (provider layer)', () {
    Future<User> waitForSignedInUser(
      ProviderContainer container,
      MockFirebaseAuth auth,
    ) {
      final completer = Completer<User>();
      late final ProviderSubscription<AsyncValue<User?>> sub;
      sub = container.listen(authStateProvider, (previous, next) {
        final user = next.value;
        if (user != null && !completer.isCompleted) {
          completer.complete(user);
        }
      });
      completer.future.whenComplete(sub.close);
      auth.signInWithEmailAndPassword(email: 'parent@example.com', password: 'x');
      return completer.future.timeout(const Duration(seconds: 5));
    }

    test(
        'test_verifyChildPin_correct_pin_sets_activeChildProvider_to_matching_profile',
        () async {
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        ],
      );
      addTearDown(container.dispose);
      final user = await waitForSignedInUser(container, auth);

      final salt = generatePinSalt();
      final hash = await hashPin(correctPin, salt);
      (firestore.doc(FirestorePaths.childCredentials(user.uid, childId))
              as _FakeDocumentReference)
          .stored = {'pinHash': hash, 'pinSalt': encodePinSalt(salt)};
      (firestore.collection(FirestorePaths.children(user.uid))
              as _FakeCollectionReference)
          .seeded[childId] = {
        'name': 'Bé An',
        'avatarId': 'avatar-1',
        'mochiName': 'Mochi',
      };

      final verified = await container
          .read(pinVerificationActionsProvider)
          .verifyChildPin(childId: childId, rawPin: correctPin);

      expect(verified, isTrue);
      final active = container.read(activeChildProvider);
      expect(active, isNotNull);
      expect(active!.childId, childId);
      expect(active.name, 'Bé An');
    });

    test(
        'test_verifyChildPin_wrong_pin_leaves_activeChildProvider_null',
        () async {
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        ],
      );
      addTearDown(container.dispose);
      final user = await waitForSignedInUser(container, auth);

      final salt = generatePinSalt();
      final hash = await hashPin(correctPin, salt);
      (firestore.doc(FirestorePaths.childCredentials(user.uid, childId))
              as _FakeDocumentReference)
          .stored = {'pinHash': hash, 'pinSalt': encodePinSalt(salt)};

      final verified = await container
          .read(pinVerificationActionsProvider)
          .verifyChildPin(childId: childId, rawPin: 'wrong');

      expect(verified, isFalse);
      expect(container.read(activeChildProvider), isNull);
    });

    test(
        'test_verifyChildPin_throws_VerifiedChildProfileMissing_when_pin_correct_but_no_matching_profile',
        () async {
      // Regression from code review: credentials sub-doc exists and the PIN
      // is right, but the profile-list doc for this childId is missing
      // (data-integrity edge case) — must not silently return true with
      // activeChildProvider left unset.
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        ],
      );
      addTearDown(container.dispose);
      final user = await waitForSignedInUser(container, auth);

      final salt = generatePinSalt();
      final hash = await hashPin(correctPin, salt);
      (firestore.doc(FirestorePaths.childCredentials(user.uid, childId))
              as _FakeDocumentReference)
          .stored = {'pinHash': hash, 'pinSalt': encodePinSalt(salt)};
      // Deliberately do NOT seed the children/ collection — credentials
      // exist but the profile-list doc doesn't.

      await expectLater(
        () => container
            .read(pinVerificationActionsProvider)
            .verifyChildPin(childId: childId, rawPin: correctPin),
        throwsA(isA<VerifiedChildProfileMissing>()),
      );
      expect(container.read(activeChildProvider), isNull);
    });
  });
}
