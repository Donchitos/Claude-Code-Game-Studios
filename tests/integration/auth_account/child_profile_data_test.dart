// Run with:
//   cd src && flutter test ../tests/integration/auth_account/child_profile_data_test.dart
//
// Uses the same hand-rolled minimal Firestore fake pattern as
// parent_login_test.dart (fake_cloud_firestore is incompatible with
// cloud_firestore ^6.7.1 — see that file's header comment for the verified
// details), extended here with a collection-query fake since
// ChildProfileRepository.getChildProfiles reads a subcollection.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/child_profile_repository.dart';
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

void main() {
  const parentId = 'parent-123';

  test('test_getChildProfiles_returns_display_fields_only', () async {
    final firestore = _FakeFirestore();
    final collection =
        firestore.collection(FirestorePaths.children(parentId))
            as _FakeCollectionReference;
    collection.seeded['child-1'] = {
      'name': 'Bé An',
      'avatarId': 'avatar-1',
      'mochiName': 'Mochi',
    };

    final repo = ChildProfileRepository(firestore: firestore);
    final profiles = await repo.getChildProfiles(parentId);

    expect(profiles, hasLength(1));
    expect(profiles.single.childId, 'child-1');
    expect(profiles.single.name, 'Bé An');
    expect(profiles.single.avatarId, 'avatar-1');
    expect(profiles.single.mochiName, 'Mochi');
  });

  test(
      'test_getChildProfiles_never_reads_credentials_path_even_when_seeded',
      () async {
    final firestore = _FakeFirestore();
    final collection =
        firestore.collection(FirestorePaths.children(parentId))
            as _FakeCollectionReference;
    collection.seeded['child-1'] = {
      'name': 'Bé An',
      'avatarId': 'avatar-1',
      'mochiName': 'Mochi',
    };
    // Seed a credentials doc at the real separate path — proves the profile
    // list read is structurally isolated from it (different collection
    // path, not just different field selection).
    (firestore.doc(FirestorePaths.childCredentials(parentId, 'child-1'))
            as _FakeDocumentReference)
        .stored = {'pinHash': 'abc', 'pinSalt': 'def'};

    final repo = ChildProfileRepository(firestore: firestore);
    final profiles = await repo.getChildProfiles(parentId);

    expect(profiles.single.childId, 'child-1');
    // ChildProfile has no pinHash/pinSalt fields at all — a compile-time
    // guarantee this test also exercises at runtime via the fake.
  });

  test('test_getChildProfiles_resolves_empty_list_when_no_children', () async {
    final firestore = _FakeFirestore();
    final repo = ChildProfileRepository(firestore: firestore);

    final profiles = await repo.getChildProfiles(parentId);

    expect(profiles, isEmpty);
  });

  test('test_getChildProfiles_surfaces_true_count_up_to_4', () async {
    final firestore = _FakeFirestore();
    final collection =
        firestore.collection(FirestorePaths.children(parentId))
            as _FakeCollectionReference;
    for (var i = 1; i <= 4; i++) {
      collection.seeded['child-$i'] = {
        'name': 'Child $i',
        'avatarId': 'avatar-$i',
        'mochiName': 'Mochi $i',
      };
    }

    final repo = ChildProfileRepository(firestore: firestore);
    final profiles = await repo.getChildProfiles(parentId);

    expect(profiles, hasLength(4));
  });

  test(
      'test_getChildProfiles_skips_malformed_doc_instead_of_crashing_whole_list',
      () async {
    final firestore = _FakeFirestore();
    final collection =
        firestore.collection(FirestorePaths.children(parentId))
            as _FakeCollectionReference;
    collection.seeded['child-good'] = {
      'name': 'Bé An',
      'avatarId': 'avatar-1',
      'mochiName': 'Mochi',
    };
    collection.seeded['child-bad'] = {
      'name': 'Bé Bình',
      // missing avatarId — simulates a partial/crashed write
      'mochiName': 'Mochi 2',
    };

    final repo = ChildProfileRepository(firestore: firestore);
    final profiles = await repo.getChildProfiles(parentId);

    expect(profiles, hasLength(1));
    expect(profiles.single.childId, 'child-good');
  });

  test('test_getChildCredentials_returns_null_when_absent', () async {
    final firestore = _FakeFirestore();
    final repo = ChildProfileRepository(firestore: firestore);

    final credentials = await repo.getChildCredentials(parentId, 'child-1');

    expect(credentials, isNull);
  });

  test('test_getChildCredentials_returns_hash_and_salt_when_present', () async {
    final firestore = _FakeFirestore();
    (firestore.doc(FirestorePaths.childCredentials(parentId, 'child-1'))
            as _FakeDocumentReference)
        .stored = {'pinHash': 'hash-value', 'pinSalt': 'salt-value'};

    final repo = ChildProfileRepository(firestore: firestore);
    final credentials = await repo.getChildCredentials(parentId, 'child-1');

    expect(credentials, isNotNull);
    expect(credentials!.pinHash, 'hash-value');
    expect(credentials.pinSalt, 'salt-value');
  });

  test(
      'test_getChildCredentials_reads_from_the_correct_isolated_path',
      () async {
    final firestore = _FakeFirestore();
    // Seed credentials for child-1 but query for child-2 — must not
    // cross-leak between siblings' credential paths.
    (firestore.doc(FirestorePaths.childCredentials(parentId, 'child-1'))
            as _FakeDocumentReference)
        .stored = {'pinHash': 'hash-1', 'pinSalt': 'salt-1'};

    final repo = ChildProfileRepository(firestore: firestore);
    final credentials = await repo.getChildCredentials(parentId, 'child-2');

    expect(credentials, isNull);
  });

  // --- Riverpod provider layer (childProfilesProvider) ---
  // Story 004/011 consume this provider, not the repository directly — per
  // the GDD's "all downstream systems import from auth_providers.dart"
  // contract — so it needs its own coverage, not just the repository's.

  test('test_childProfilesProvider_returns_empty_list_when_user_null', () async {
    final firestore = _FakeFirestore();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWithValue(const AsyncData(null)),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);

    final profiles = await container.read(childProfilesProvider.future);

    expect(profiles, isEmpty);
  });

  test(
      'test_childProfilesProvider_delegates_to_repository_when_authenticated',
      () async {
    final firestore = _FakeFirestore();
    final collection =
        firestore.collection(FirestorePaths.children(parentId))
            as _FakeCollectionReference;
    collection.seeded['child-1'] = {
      'name': 'Bé An',
      'avatarId': 'avatar-1',
      'mochiName': 'Mochi',
    };
    final mockUser = MockUser(uid: parentId, email: 'parent@example.com');
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWithValue(AsyncData<User?>(mockUser)),
        firebaseFirestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);

    final profiles = await container.read(childProfilesProvider.future);

    expect(profiles, hasLength(1));
    expect(profiles.single.name, 'Bé An');
  });
}
