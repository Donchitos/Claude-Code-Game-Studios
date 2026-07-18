// Run with:
//   cd src && flutter test ../tests/integration/seed_buffer/seed_submit_test.dart
//
// Story: seed-buffer/story-001-seed-drop-on-submit — Test Evidence section.
//
// Uses this project's established hand-rolled minimal Firestore fake
// pattern (`fake_cloud_firestore` is incompatible with `cloud_firestore
// ^6.7.1` — see `tests/integration/auth_account/parent_login_test.dart`'s
// header comment for the verified details), extended here with a fake
// `WriteBatch` — no existing test file in this codebase needed one before
// this story, since Shop Purchase Pipeline (ADR-0011) uses `runTransaction`,
// not `WriteBatch`, and every other prior write path is a single `set()`/
// `add()`.
//
// `FieldValue.serverTimestamp()`/`FieldValue.increment()` both round-trip
// through equality correctly in a plain `flutter_test` unit test with no
// `Firebase.initializeApp()` call — verified against the installed
// `cloud_firestore_platform_interface` source (`MethodChannelFieldValue`'s
// value-based `==`), and already relied on by
// `tests/unit/task_library/custom_task_test.dart`'s
// `test_createCustomTaskTemplate_uses_FieldValue_serverTimestamp_for_createdAt`.
// This lets the assertions below compare the recorded `seedCount` update
// directly against `FieldValue.increment(1)` rather than needing a
// semantics-aware fake that actually resolves increments.
//
// AC-5 (offline submit sync) note: `WriteBatch`'s local-cache-then-sync
// behavior is a `cloud_firestore` SDK guarantee, not application logic —
// it cannot be genuinely exercised without the Firestore emulator, which
// is not available in this dev environment (the same no-emulator
// constraint ADR-0009/ADR-0012 both flag). The structural proxy used here
// (also used by the story's own Test Evidence item 8): assert that
// `submitTask()` completes by unconditionally calling `batch.commit()`
// with no connectivity precondition anywhere in the call path — the fake
// has no notion of "online"/"offline" at all, which is itself the point:
// the repository code never branches on connectivity.
//
// GameEventBus note (post-code-review correction, 2026-07-17): the first
// draft of `submitTask()` emitted `GameEventType.seedReceived` directly —
// an ADR-0004 §3 violation (a repository is neither of the two sanctioned
// emit adapters). That call was removed from the implementation, so this
// file no longer tests event emission at all — emitting is now the
// responsibility of whichever future story builds the Task Submission
// Screen's `ConsumerWidget`, tested there instead.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/reward_table.dart';
import 'package:pet_quest/core/task_repository.dart';

class _RecordedWrite {
  _RecordedWrite(this.path, this.data);
  final String path;
  final Map<String, dynamic> data;
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path);
  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this.path, this._firestore);
  @override
  final String path;
  final _FakeFirestore _firestore;

  @override
  String get id => path.split('/').last;

  // Auto-ID sequencing lives on the owning `_FakeFirestore`, keyed by
  // collection path — NOT on this object. `_FakeFirestore.collection()`
  // returns a fresh `_FakeCollectionReference` on every call (matching real
  // `FirebaseFirestore.collection()`, which is also not required to return
  // a cached instance), so a per-instance counter here would silently reset
  // to 0 on every `.collection(...).doc()` chain, producing colliding IDs
  // across repeated `submitTask()` calls against the same fake Firestore —
  // a real bug found in this file's own code review (qa-tester Finding 6,
  // 2026-07-17), before Story 002 could inherit it via this fixture.
  @override
  DocumentReference<Map<String, dynamic>> doc([String? docPath]) {
    final id = docPath ?? 'auto-${_firestore._nextAutoId(path)}';
    return _FakeDocumentReference('$path/$id');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A fake [WriteBatch] that buffers `set`/`update` calls and only applies
/// them to the owning [_FakeFirestore]'s "committed" lists on a successful
/// [commit] — modeling Firestore's real atomicity guarantee (both writes
/// land together or neither does) without needing a real Firestore
/// connection. [_FakeFirestore.failNextBatchCommit] lets a test simulate a
/// rejected/failed commit (e.g. a `rewardOk()` Security Rule denial) and
/// assert neither write was applied and no event fired.
class _FakeWriteBatch implements WriteBatch {
  _FakeWriteBatch(this._firestore);
  final _FakeFirestore _firestore;
  final List<_RecordedWrite> _pendingSets = [];
  final List<_RecordedWrite> _pendingUpdates = [];
  bool _committed = false;

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    final ref = document as _FakeDocumentReference;
    _pendingSets.add(_RecordedWrite(ref.path, data as Map<String, dynamic>));
  }

  @override
  void update<T>(DocumentReference<T> document, T data) {
    final ref = document as _FakeDocumentReference;
    _pendingUpdates
        .add(_RecordedWrite(ref.path, data as Map<String, dynamic>));
  }

  @override
  void delete(DocumentReference<Object?> document) {
    throw UnimplementedError('not used by TaskRepository.submitTask');
  }

  @override
  Future<void> commit() async {
    if (_committed) {
      throw StateError('WriteBatch already committed');
    }
    _committed = true;
    if (_firestore.failNextBatchCommit) {
      _firestore.failNextBatchCommit = false;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'simulated-failure',
        message: 'Simulated WriteBatch.commit() failure for test',
      );
    }
    // Atomic: both lists are only ever appended to together, right here.
    _firestore.committedSets.addAll(_pendingSets);
    _firestore.committedUpdates.addAll(_pendingUpdates);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final collectionPathsRequested = <String>[];
  final docPathsRequested = <String>[];
  final committedSets = <_RecordedWrite>[];
  final committedUpdates = <_RecordedWrite>[];
  int batchCallCount = 0;
  bool failNextBatchCommit = false;

  final _autoIdSeqByPath = <String, int>{};

  /// Next auto-ID sequence number for [collectionPath], scoped to THIS
  /// `_FakeFirestore` instance and persistent across repeated
  /// `.collection(path).doc()` calls — the fix for the ID-collision bug
  /// this replaces (see `_FakeCollectionReference.doc` doc comment).
  int _nextAutoId(String collectionPath) {
    final next = _autoIdSeqByPath[collectionPath] ?? 0;
    _autoIdSeqByPath[collectionPath] = next + 1;
    return next;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    collectionPathsRequested.add(path);
    return _FakeCollectionReference(path, this);
  }

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    docPathsRequested.add(path);
    return _FakeDocumentReference(path);
  }

  @override
  WriteBatch batch() {
    batchCallCount++;
    return _FakeWriteBatch(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-1';
  const childId = 'child-1';

  // --- Task Library AC (task creation) + reward integrity, all 6 categories ---

  for (final categoryId in knownCategoryIds) {
    test(
        'test_submitTask_writes_correct_reward_and_flavorText_for_category_$categoryId',
        () async {
      final firestore = _FakeFirestore();
      final repo = TaskRepository(firestore: firestore);
      final expectedReward = rewardFor(categoryId);

      await repo.submitTask(
        parentId: parentId,
        childId: childId,
        title: 'Quét nhà',
        categoryId: categoryId,
      );

      expect(firestore.committedSets, hasLength(1));
      final data = firestore.committedSets.single.data;
      expect(data['title'], 'Quét nhà');
      expect(data['flavorText'], flavorTextFor(categoryId));
      expect(data['categoryId'], categoryId);
      expect(data['xuReward'], expectedReward.xu);
      expect(data['energyReward'], expectedReward.energy);
      expect(data['status'], 'pending');
      expect(data['submittedAt'], FieldValue.serverTimestamp());
      expect(data.containsKey('approvedAt'), isFalse);
      expect(data.containsKey('rejectedAt'), isFalse);
    });
  }

  test(
      'test_submitTask_reward_values_match_the_SAME_table_the_deployed_rewardOk_rule_uses',
      () async {
    // Mirrors firestore.rules' rewardTable() literal (ADR-0009 §3) — this
    // test fails loudly if reward_table.dart ever drifts from the values
    // transcribed into the Security Rule, which is the actual enforcement
    // mechanism this write must satisfy.
    const deployedRuleTable = {
      'study': (xu: 25, energy: 20),
      'arts': (xu: 25, energy: 20),
      'chores': (xu: 15, energy: 25),
      'sport': (xu: 15, energy: 25),
      'helping': (xu: 10, energy: 30),
      'custom': (xu: 15, energy: 25),
    };

    for (final categoryId in knownCategoryIds) {
      final firestore = _FakeFirestore();
      final repo = TaskRepository(firestore: firestore);

      await repo.submitTask(
        parentId: parentId,
        childId: childId,
        title: 'Việc gì đó',
        categoryId: categoryId,
      );

      final data = firestore.committedSets.single.data;
      final expected = deployedRuleTable[categoryId]!;
      expect(data['xuReward'], expected.xu,
          reason: '$categoryId xuReward must match the deployed rule table');
      expect(data['energyReward'], expected.energy,
          reason:
              '$categoryId energyReward must match the deployed rule table');
    }
  });

  // --- Task Library edge case: empty/whitespace title ---

  test('test_submitTask_empty_title_throws_before_any_write_attempt',
      () async {
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await expectLater(
      () => repo.submitTask(
        parentId: parentId,
        childId: childId,
        title: '',
        categoryId: 'chores',
      ),
      throwsArgumentError,
    );
    expect(firestore.batchCallCount, 0);
    expect(firestore.committedSets, isEmpty);
    expect(firestore.committedUpdates, isEmpty);
  });

  test(
      'test_submitTask_whitespace_only_title_throws_before_any_write_attempt',
      () async {
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await expectLater(
      () => repo.submitTask(
        parentId: parentId,
        childId: childId,
        title: '   ',
        categoryId: 'chores',
      ),
      throwsArgumentError,
    );
    expect(firestore.batchCallCount, 0);
  });

  test('test_submitTask_trims_a_padded_title_before_writing', () async {
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await repo.submitTask(
      parentId: parentId,
      childId: childId,
      title: '  Quét nhà  ',
      categoryId: 'chores',
    );

    expect(firestore.committedSets.single.data['title'], 'Quét nhà');
  });

  // --- Unknown categoryId: client-side fast-fail ---

  test('test_submitTask_unknown_categoryId_throws_before_any_write_attempt',
      () async {
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await expectLater(
      () => repo.submitTask(
        parentId: parentId,
        childId: childId,
        title: 'Quét nhà',
        categoryId: 'not_a_real_category',
      ),
      throwsArgumentError,
    );
    expect(firestore.batchCallCount, 0);
    expect(firestore.committedSets, isEmpty);
    expect(firestore.committedUpdates, isEmpty);
  });

  // --- AC-1 (partial, submit-side): atomic single-batch seedCount +1 ---

  test(
      'test_submitTask_commits_task_create_and_seedCount_increment_in_the_SAME_batch',
      () async {
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await repo.submitTask(
      parentId: parentId,
      childId: childId,
      title: 'Quét nhà',
      categoryId: 'chores',
    );

    // Exactly one WriteBatch created for the whole submit — proves the
    // task-create and seedCount-increment writes share one batch instance,
    // not two separate ones.
    expect(firestore.batchCallCount, 1);
    expect(firestore.committedSets, hasLength(1));
    expect(firestore.committedUpdates, hasLength(1));
  });

  test('test_submitTask_increments_seedCount_by_exactly_1_via_FieldValue_increment',
      () async {
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await repo.submitTask(
      parentId: parentId,
      childId: childId,
      title: 'Quét nhà',
      categoryId: 'chores',
    );

    final update = firestore.committedUpdates.single;
    expect(update.path, FirestorePaths.child(parentId, childId));
    expect(update.data.keys, ['seedCount']);
    // Never an absolute set() — always FieldValue.increment(1) (ADR-0012 §1
    // / ADR-0003/ADR-0008's absolute_set_on_balance_or_counters rule).
    expect(update.data['seedCount'], FieldValue.increment(1));
  });

  // --- On WriteBatch failure: no partial write, exception surfaces ---

  test(
      'test_submitTask_batch_failure_applies_no_writes_and_rethrows',
      () async {
    final firestore = _FakeFirestore()..failNextBatchCommit = true;
    final repo = TaskRepository(firestore: firestore);

    await expectLater(
      () => repo.submitTask(
        parentId: parentId,
        childId: childId,
        title: 'Quét nhà',
        categoryId: 'chores',
      ),
      throwsA(isA<FirebaseException>()),
    );

    // Firestore's own atomicity: a rejected commit applies neither write —
    // nothing to assert about the batch's internal pending lists here
    // (they're never surfaced to the caller); what matters is the
    // FIRESTORE-SIDE committed lists stay empty.
    expect(firestore.committedSets, isEmpty);
    expect(firestore.committedUpdates, isEmpty);
  });

  // --- Fake fidelity regression: distinct auto-IDs across repeated calls ---

  test(
      'test_submitTask_generates_distinct_task_ids_across_repeated_calls_on_the_same_firestore',
      () async {
    // Regression test for qa-tester Finding 6 (2026-07-17 code review): the
    // fake's auto-ID sequencing used to live on an ephemeral
    // _FakeCollectionReference recreated on every `.collection()` call,
    // silently colliding every task at `.../tasks/auto-0`. This matters
    // because Story 002's own tests plan to reuse this fixture across
    // multiple `submitTask()` calls on one `_FakeFirestore` instance.
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await repo.submitTask(
      parentId: parentId,
      childId: childId,
      title: 'Quét nhà',
      categoryId: 'chores',
    );
    await repo.submitTask(
      parentId: parentId,
      childId: childId,
      title: 'Rửa bát',
      categoryId: 'chores',
    );

    expect(firestore.committedSets, hasLength(2));
    final paths = firestore.committedSets.map((w) => w.path).toSet();
    expect(paths, hasLength(2),
        reason: 'each submitTask() call must produce a distinct task path');
  });

  // --- No inline Firestore paths: everything routed through FirestorePaths ---

  test(
      'test_submitTask_routes_every_Firestore_path_through_FirestorePaths_constants',
      () async {
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await repo.submitTask(
      parentId: parentId,
      childId: childId,
      title: 'Quét nhà',
      categoryId: 'chores',
    );

    expect(firestore.collectionPathsRequested,
        [FirestorePaths.tasks(parentId, childId)]);
    expect(
        firestore.docPathsRequested, [FirestorePaths.child(parentId, childId)]);
  });

  // --- AC-5 (offline submit sync): structural proxy, see file header note ---

  test(
      'test_submitTask_issues_the_batch_unconditionally_with_no_connectivity_gate',
      () async {
    // No emulator available in this dev environment to exercise real
    // offline-cache behavior (see file header note). This asserts the
    // structural property that stands in for it: submitTask() completes
    // via a single unconditional batch().commit() call with no
    // connectivity check anywhere in the path — the fake Firestore never
    // models "online"/"offline" at all, and the repository never queries
    // one, which is exactly the offline-first contract (ADR-0012 §1: "no
    // explicit online check, no blocking on connectivity").
    final firestore = _FakeFirestore();
    final repo = TaskRepository(firestore: firestore);

    await repo.submitTask(
      parentId: parentId,
      childId: childId,
      title: 'Quét nhà',
      categoryId: 'chores',
    );

    expect(firestore.batchCallCount, 1);
    expect(firestore.committedSets, hasLength(1));
    expect(firestore.committedUpdates, hasLength(1));
  });
}
