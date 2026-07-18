// Run with:
//   cd src && flutter test ../tests/unit/auth_account/pin_reset_test.dart
//
// Uses the same hand-rolled minimal Firestore fake pattern as
// pin_verification_test.dart / child_profile_data_test.dart
// (fake_cloud_firestore is incompatible with cloud_firestore ^6.7.1 — see
// parent_login_test.dart's header comment). `_FakeSecureStorage` matches
// pin_verification_test.dart's in-memory fake.

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
import 'package:pet_quest/core/pin_reset_repository.dart';
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
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
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
  final _docs = <String, _FakeDocumentReference>{};

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _docs.putIfAbsent(path, () => _FakeDocumentReference());
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

  group('PinResetRepository.resetChildPin', () {
    test(
        'test_resetChildPin_overwrites_with_a_fresh_different_salt_and_old_pin_stops_verifying',
        () async {
      final firestore = _FakeFirestore();
      final oldSalt = generatePinSalt();
      final oldHash = await hashPin('1111', oldSalt);
      final doc = firestore.doc(FirestorePaths.childCredentials(parentId, childId))
          as _FakeDocumentReference;
      doc.stored = {'pinHash': oldHash, 'pinSalt': encodePinSalt(oldSalt)};

      final childRepo = ChildProfileRepository(firestore: firestore);
      final storage = _FakeSecureStorage();
      final resetRepo = PinResetRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
      );

      await resetRepo.resetChildPin(
        parentId: parentId,
        childId: childId,
        newPin: '2222',
      );

      expect(doc.stored!['pinSalt'], isNot(encodePinSalt(oldSalt)));
      expect(doc.stored!['pinHash'], isNot(oldHash));

      // Old PIN must no longer verify.
      final verifyRepo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );
      final oldStillWorks = await verifyRepo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: '1111',
      );
      expect(oldStillWorks, isFalse);

      // New PIN verifies.
      final newWorks = await verifyRepo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: '2222',
      );
      expect(newWorks, isTrue);
    });

    test(
        'test_resetChildPin_for_a_child_with_no_prior_credentials_doc_creates_it_correctly',
        () async {
      // A genuinely new child (or a data-integrity gap) — no credentials
      // sub-document exists yet at all before this call.
      final firestore = _FakeFirestore();
      final childRepo = ChildProfileRepository(firestore: firestore);
      final resetRepo = PinResetRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );
      final doc = firestore.doc(FirestorePaths.childCredentials(parentId, childId))
          as _FakeDocumentReference;
      expect(doc.stored, isNull); // precondition: nothing exists yet

      await resetRepo.resetChildPin(
        parentId: parentId,
        childId: childId,
        newPin: '9090',
      );

      expect(doc.stored, isNotNull);
      expect(doc.stored!.keys.toSet(), {'pinHash', 'pinSalt'});
      expect(doc.stored!['pinHash'], isNotEmpty);
      expect(doc.stored!['pinSalt'], isNotEmpty);

      final verifyRepo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );
      final verified = await verifyRepo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: '9090',
      );
      expect(verified, isTrue);
    });

    test(
        'test_resetChildPin_concurrent_calls_for_the_same_child_are_internally_consistent',
        () async {
      // Last-write-wins is the accepted design (see resetChildPin's doc
      // comment) — this proves the property that design relies on: whichever
      // call wins, the stored pinHash/pinSalt always come from the SAME
      // call, never a mix of one call's salt with another's hash.
      final firestore = _FakeFirestore();
      final childRepo = ChildProfileRepository(firestore: firestore);
      final resetRepo = PinResetRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );

      await Future.wait([
        resetRepo.resetChildPin(parentId: parentId, childId: childId, newPin: '1111'),
        resetRepo.resetChildPin(parentId: parentId, childId: childId, newPin: '2222'),
      ]);

      final verifyRepo = PinVerificationRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );
      final firstWorks = await verifyRepo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: '1111',
      );
      final secondWorks = await verifyRepo.verify(
        parentId: parentId,
        childId: childId,
        rawPin: '2222',
      );
      // Exactly one of the two concurrent PINs is the winner — never both
      // (which would mean the hash didn't match its own salt) and never
      // neither (which would mean a corrupted mixed write).
      expect([firstWorks, secondWorks].where((w) => w).length, 1);
    });

    test('test_resetChildPin_clears_an_existing_lockout', () async {
      final firestore = _FakeFirestore();
      final childRepo = ChildProfileRepository(firestore: firestore);
      final storage = _FakeSecureStorage();
      await storage.write(key: 'pin_fail_$childId', value: '3');
      await storage.write(key: 'pin_lock_$childId', value: '9999999999999');
      final resetRepo = PinResetRepository(
        childProfileRepository: childRepo,
        secureStorage: storage,
      );

      await resetRepo.resetChildPin(
        parentId: parentId,
        childId: childId,
        newPin: '4321',
      );

      expect(await storage.read(key: 'pin_fail_$childId'), isNull);
      expect(await storage.read(key: 'pin_lock_$childId'), isNull);
    });

    test(
        'test_resetChildPin_rejects_non_4_digit_pin_before_any_write_or_hashing',
        () async {
      final firestore = _FakeFirestore();
      final childRepo = ChildProfileRepository(firestore: firestore);
      var hashCallCount = 0;
      final resetRepo = PinResetRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
        hashPinFn: (rawPin, salt) {
          hashCallCount++;
          return hashPin(rawPin, salt);
        },
      );

      for (final invalid in ['12a4', '123', '12345', '', 'abcd']) {
        await expectLater(
          () => resetRepo.resetChildPin(
            parentId: parentId,
            childId: childId,
            newPin: invalid,
          ),
          throwsA(isA<InvalidPinFormat>()),
        );
      }

      expect(hashCallCount, 0);
      final doc = firestore.doc(FirestorePaths.childCredentials(parentId, childId))
          as _FakeDocumentReference;
      expect(doc.stored, isNull); // never written
    });

    test(
        'test_resetChildPin_accepts_pins_with_a_leading_zero',
        () async {
      // 4-digit format check, not a numeric-value check — '0012' is valid.
      final firestore = _FakeFirestore();
      final childRepo = ChildProfileRepository(firestore: firestore);
      final resetRepo = PinResetRepository(
        childProfileRepository: childRepo,
        secureStorage: _FakeSecureStorage(),
      );

      await expectLater(
        resetRepo.resetChildPin(
          parentId: parentId,
          childId: childId,
          newPin: '0012',
        ),
        completes,
      );
    });
  });

  group('pinResetActionsProvider (provider layer)', () {
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
        'test_resetChildPin_does_not_touch_activeChildProvider',
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

      const activeChild = ChildProfile(
        childId: childId,
        name: 'Bé An',
        avatarId: 'avatar-1',
        mochiName: 'Mochi',
      );
      container.read(activeChildProvider.notifier).state = activeChild;

      await container.read(pinResetActionsProvider).resetChildPin(
            childId: childId,
            newPin: '5678',
          );

      expect(container.read(activeChildProvider), activeChild);
      final doc = firestore.doc(FirestorePaths.childCredentials(user.uid, childId))
          as _FakeDocumentReference;
      expect(doc.stored, isNotNull);
    });

    test(
        'test_resetChildPin_throws_when_no_parent_signed_in',
        () async {
      final firestore = _FakeFirestore();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          firebaseFirestoreProvider.overrideWithValue(firestore),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        () => container
            .read(pinResetActionsProvider)
            .resetChildPin(childId: childId, newPin: '5678'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
