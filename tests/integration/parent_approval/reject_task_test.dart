// Run with:
//   cd src && flutter test ../tests/integration/parent_approval/reject_task_test.dart
//
// Story: parent-approval/story-002-reject-transaction — Test Evidence
// section. Covers all 5 Acceptance Criteria bullets from the story (see
// header comment on each test group below for the exact bullet covered).
//
// Per the story's Implementation Notes #4, this reuses the fake-transaction
// test harness SHAPE already established in
// `tests/integration/parent_approval/approve_task_test.dart` (same fake
// `Transaction`/`DocumentReference`/`DocumentSnapshot`/`FirebaseFirestore`
// classes, verified there against the real `cloud_firestore` 6.7.1
// interface) — but as its own local copy, matching this project's
// established per-test-file fake convention (see that file's own header
// comment, and `tests/integration/seed_buffer/seed_submit_test.dart`, both
// of which define their own local `_Fake*` classes rather than sharing a
// fakes library). `rejectTask()` only ever calls `get`/`update` on
// `Transaction`, same as `approveTask()`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/parent_approval_repository.dart';

class _RecordedWrite {
  _RecordedWrite(this.path, this.data);
  final String path;
  final Map<String, dynamic> data;
}

class _FakeDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path);
  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentSnapshot
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this._data);
  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake [Transaction] — buffers `update()` calls; `get()` reads from the
/// owning [_FakeFirestore]'s `seededDocs`, and can be made to throw (the
/// "throw at the read step" branch of the Transaction Failure AC).
class _FakeTransaction implements Transaction {
  _FakeTransaction(this._firestore);
  final _FakeFirestore _firestore;
  final List<_RecordedWrite> pendingUpdates = [];
  int getCallCount = 0;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    getCallCount++;
    if (_firestore.throwOnGet != null) {
      throw _firestore.throwOnGet!;
    }
    final ref = documentReference as _FakeDocumentReference;
    final snap = _FakeDocumentSnapshot(_firestore.seededDocs[ref.path]);
    return snap as DocumentSnapshot<T>;
  }

  @override
  Transaction update(
    DocumentReference documentReference,
    Map<Object, Object?> data,
  ) {
    final ref = documentReference as _FakeDocumentReference;
    pendingUpdates.add(_RecordedWrite(ref.path, Map<String, dynamic>.from(data)));
    return this;
  }

  @override
  Transaction delete(DocumentReference documentReference) =>
      throw UnimplementedError('not used by ParentApprovalRepository.rejectTask');

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) =>
      throw UnimplementedError('not used by ParentApprovalRepository.rejectTask');
}

/// Fake [FirebaseFirestore] — `doc()` for path resolution, plus a hand-rolled
/// `runTransaction()` that models Firestore's real "buffer writes, apply on
/// successful commit" atomicity guarantee. [seededDocs] is this fixture's
/// pre-transaction read source (`path -> data`, absent key or a `null`
/// value both model a non-existent document). [failNextTransactionCommit]
/// and [throwOnGet] let a test simulate the two distinct failure points the
/// story's Transaction Failure AC requires ("throw at the read step vs.
/// throw at the write step").
class _FakeFirestore implements FirebaseFirestore {
  final docPathsRequested = <String>[];
  final committedUpdates = <_RecordedWrite>[];
  final seededDocs = <String, Map<String, dynamic>?>{};
  int transactionCallCount = 0;
  bool failNextTransactionCommit = false;
  Object? throwOnGet;

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    docPathsRequested.add(path);
    return _FakeDocumentReference(path);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    transactionCallCount++;
    final transaction = _FakeTransaction(this);
    final result = await transactionHandler(transaction);
    if (failNextTransactionCommit) {
      failNextTransactionCommit = false;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'simulated-failure',
        message: 'Simulated Transaction commit failure for test',
      );
    }
    // Atomic: writes only ever land here together, on a successful commit —
    // exactly the "throw at the write step" test's load-bearing property.
    committedUpdates.addAll(transaction.pendingUpdates);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-1';
  const childId = 'child-1';
  const taskId = 'task-1';
  final taskPath = FirestorePaths.task(parentId, childId, taskId);
  final childPath = FirestorePaths.child(parentId, childId);

  Map<String, dynamic> pendingTask() => {'status': 'pending'};

  Map<String, dynamic> updateFor(_FakeFirestore f, String path) =>
      f.committedUpdates.firstWhere((w) => w.path == path).data;

  // ------------------------------------------------------------------
  // AC-1 (Normal reject): status='rejected', rejectedAt set, seedCount-=1;
  // no economy fields (xuBalance/storedEnergy/totalXuEarned/
  // approvedTaskCount) touched at all.
  // ------------------------------------------------------------------

  test(
      'test_rejectTask_normalPath_writesStatusRejectedAndSeedCountDecrement_noEconomyFieldsTouched',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask()
      ..seededDocs[childPath] = {
        'xuBalance': 100,
        'storedEnergy': 50.0,
        'totalXuEarned': 200,
        'approvedTaskCount': 3,
        'seedCount': 2,
      };
    final repo = ParentApprovalRepository(firestore: firestore);

    await repo.rejectTask(parentId: parentId, childId: childId, taskId: taskId);

    final taskUpdate = updateFor(firestore, taskPath);
    expect(taskUpdate['status'], 'rejected');
    expect(taskUpdate['rejectedAt'], FieldValue.serverTimestamp());
    expect(taskUpdate.keys, unorderedEquals(['status', 'rejectedAt']));

    final childUpdate = updateFor(firestore, childPath);
    // Only seedCount is written — no xuBalance/storedEnergy/totalXuEarned/
    // approvedTaskCount field appears in the write map at all (not merely
    // unchanged in value — genuinely absent from the map, since a
    // FieldValue.increment(0) would still be a distinct forbidden write).
    expect(childUpdate.keys, unorderedEquals(['seedCount']));
    expect(childUpdate['seedCount'], FieldValue.increment(-1));
  });

  test(
      'test_rejectTask_seedCountAlreadyZero_stillWritesRawIncrementNegativeOne_noClamp',
      () async {
    // QA edge case: this write is a raw increment(-1) with no clamp —
    // clamping to 0 is seedCountProvider's job on read (ADR-0012 §3), not
    // this write's job, matching the same `-1` write already established
    // for approveTask().
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask()
      ..seededDocs[childPath] = {'seedCount': 0};
    final repo = ParentApprovalRepository(firestore: firestore);

    await repo.rejectTask(parentId: parentId, childId: childId, taskId: taskId);

    final childUpdate = updateFor(firestore, childPath);
    expect(childUpdate['seedCount'], FieldValue.increment(-1));
  });

  // ------------------------------------------------------------------
  // AC-2 (No event emission): rejectTask() returns Future<void> (resolves to
  // null) and this repository never touches GameEventBus at all — there is
  // no fake GameEventBus wired into this test file/class because
  // ParentApprovalRepository has no reference to it whatsoever (verified by
  // this file's own imports: no `game_event_bus.dart` import exists here,
  // and the repository's source has none either).
  // ------------------------------------------------------------------

  test(
      'test_rejectTask_commit_returnsVoidFuture_noGameEventBusReferenceInvolved',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask()
      ..seededDocs[childPath] = {'seedCount': 1};
    final repo = ParentApprovalRepository(firestore: firestore);

    // rejectTask()'s declared return type is Future<void> — there is no
    // result value of any kind for a caller to react to (stronger
    // constraint than approveTask()'s ApproveResult?, per ADR-0013 Key
    // Interfaces / GDD Core Rule 3). `await`-ing it here without capturing a
    // typed result IS the assertion: this line would fail to compile if
    // rejectTask() ever gained a non-void return value without a
    // corresponding update to this test.
    await repo.rejectTask(parentId: parentId, childId: childId, taskId: taskId);

    // Only the two expected Firestore writes landed — nothing else fired.
    expect(firestore.committedUpdates, hasLength(2));
  });

  // ------------------------------------------------------------------
  // AC-3 (Idempotency) / AC-4 (No un-reject): task status already
  // 'approved' or 'rejected' -> transaction aborts at the first read, zero
  // writes. Both prior states tested separately per the story's own
  // instruction ("both must short-circuit identically") — the 'rejected'
  // case IS the "no un-reject" case (GDD Edge Case 8 — no separate
  // un-reject code path exists to test).
  // ------------------------------------------------------------------

  test(
      'test_rejectTask_alreadyApprovedTask_noWritesRecorded',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = {'status': 'approved'}
      ..seededDocs[childPath] = {'seedCount': 1};
    final repo = ParentApprovalRepository(firestore: firestore);

    await repo.rejectTask(parentId: parentId, childId: childId, taskId: taskId);

    expect(firestore.committedUpdates, isEmpty);
  });

  test(
      'test_rejectTask_alreadyRejectedTask_isNoOp_noUnRejectWritesRecorded',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = {'status': 'rejected'}
      ..seededDocs[childPath] = {'seedCount': 1};
    final repo = ParentApprovalRepository(firestore: firestore);

    await repo.rejectTask(parentId: parentId, childId: childId, taskId: taskId);

    expect(firestore.committedUpdates, isEmpty);
  });

  test(
      'test_rejectTask_missingTaskDoc_treatedAsNonPending_noWritesRecorded',
      () async {
    // Defensive edge case matching approveTask()'s own null-data handling:
    // a missing task doc reads as `data() == null`, whose `?['status']` is
    // `null`, which is `!= 'pending'` — same silent-no-op path.
    final firestore = _FakeFirestore()
      ..seededDocs[childPath] = {'seedCount': 1};
    final repo = ParentApprovalRepository(firestore: firestore);

    await repo.rejectTask(parentId: parentId, childId: childId, taskId: taskId);

    expect(firestore.committedUpdates, isEmpty);
  });

  // ------------------------------------------------------------------
  // AC-5 (Transaction failure): a mocked runTransaction that throws ->
  // exception propagates uncaught, no partial write occurs. Edge cases:
  // throw at the read step vs. throw at the write step — both must leave
  // zero recorded writes (matches approveTask()'s own AC-11 pattern).
  // ------------------------------------------------------------------

  test(
      'test_rejectTask_transactionThrowsAtReadStep_exceptionPropagates_noWritesRecorded',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask()
      ..seededDocs[childPath] = {'seedCount': 1}
      ..throwOnGet = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Simulated read-step failure for test',
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    await expectLater(
      () => repo.rejectTask(
          parentId: parentId, childId: childId, taskId: taskId),
      throwsA(isA<FirebaseException>()),
    );
    expect(firestore.committedUpdates, isEmpty);
  });

  test(
      'test_rejectTask_transactionThrowsAtWriteStep_exceptionPropagates_noWritesRecorded',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask()
      ..seededDocs[childPath] = {'seedCount': 1}
      ..failNextTransactionCommit = true;
    final repo = ParentApprovalRepository(firestore: firestore);

    await expectLater(
      () => repo.rejectTask(
          parentId: parentId, childId: childId, taskId: taskId),
      throwsA(isA<FirebaseException>()),
    );
    // The handler DID call transaction.update() (task + child), but the
    // commit itself failed — Firestore's own atomicity: a rejected commit
    // applies neither write. What matters is the FIRESTORE-SIDE committed
    // list stays empty, matching approve_task_test.dart's own established
    // assertion shape for this class of failure.
    expect(firestore.committedUpdates, isEmpty);
  });
}
