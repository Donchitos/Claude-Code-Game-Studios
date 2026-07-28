// Run with:
//   cd src && flutter test ../tests/integration/parent_approval/approve_task_test.dart
//
// Story: parent-approval/story-001-approve-transaction — Test Evidence
// section. Covers all 12 Acceptance Criteria bullets from the story (see
// header comment on each test group below for the exact bullet covered).
//
// This is the FIRST `runTransaction` fake in this codebase (Shop Purchase
// Pipeline's own `runTransaction` test file does not exist yet — no
// `shop_purchase_test.dart` or equivalent was found in `tests/`). Built by
// extending this project's established hand-rolled minimal Firestore fake
// pattern (`fake_cloud_firestore` is incompatible with the installed
// `cloud_firestore ^6.7.1` — see `tests/integration/seed_buffer/
// seed_submit_test.dart`'s header comment), the same way that file added a
// fake `WriteBatch` for its own first-of-its-kind need.
//
// `cloud_firestore` 6.7.1's `Transaction` and `WriteBatch` classes are both
// CONCRETE classes with private (`._`) constructors and private fields
// (verified directly against
// `<pub-cache>/cloud_firestore-6.7.1/lib/src/transaction.dart`, since this
// story's brief flagged the need to check for ADR-vs-installed-package
// drift). Dart's implicit-interfaces feature lets a fake `implements` a
// concrete class from outside its declaring library without needing to
// satisfy the private constructor or private fields — the same trick this
// codebase already relies on for `_FakeWriteBatch implements WriteBatch` in
// `seed_submit_test.dart`. `Transaction.get<T>()`/`update()`/`delete()`/
// `set()` are the only public members that matter here; `ParentApprovalRepository.
// approveTask()` only ever calls `get`/`update`, so `delete`/`set` fall
// through to `noSuchMethod` (never invoked by the code under test) exactly
// like `_FakeWriteBatch.delete` does for `submitTask()`.
//
// Commit-atomicity model: `_FakeTransaction.update()` only buffers writes
// into its own `pendingUpdates` list — nothing lands in
// `_FakeFirestore.committedUpdates` until `_FakeFirestore.runTransaction()`'s
// handler resolves WITHOUT throwing. This mirrors `_FakeWriteBatch`'s own
// buffer-then-commit shape and is what makes the "transaction throws at the
// write step" test (AC "Transaction failure") meaningful: `transaction.
// update()` can be called during the handler, yet zero writes still land on
// the FIRESTORE-SIDE committed list if the final commit itself is made to
// fail (`failNextTransactionCommit`).
//
// Two-device-race / double-tap note: this fake models a "commit" as a
// same-instance in-memory event, so simulating "the SAME task read as
// non-pending on a second call" requires the test itself to mutate
// `_FakeFirestore.seededDocs` between the two `approveTask()` calls, exactly
// as if the first call's transaction had already been durably committed
// server-side. This is the same "structural proxy" approach
// `seed_submit_test.dart`'s own header comment already uses for its
// offline-sync AC (no live emulator available in this environment — see
// ADR-0013's own Validation Criteria, matching Seed Buffer Story 003's
// precedent for this class of gap).

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
      throw UnimplementedError('not used by ParentApprovalRepository.approveTask');

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) =>
      throw UnimplementedError('not used by ParentApprovalRepository.approveTask');
}

/// Fake [FirebaseFirestore] — `doc()` for path resolution, plus a hand-rolled
/// `runTransaction()` that models Firestore's real "buffer writes, apply on
/// successful commit" atomicity guarantee (mirroring `_FakeWriteBatch` in
/// `seed_submit_test.dart`). [seededDocs] is this fixture's pre-transaction
/// read source (`path -> data`, absent key or a `null` value both model a
/// non-existent document). [failNextTransactionCommit] and [throwOnGet] let
/// a test simulate the two distinct failure points the story's Transaction
/// Failure AC requires ("throw at the read step vs. throw at the write
/// step").
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

  Map<String, dynamic> pendingTask({
    required int xuReward,
    required int energyReward,
  }) =>
      {'status': 'pending', 'xuReward': xuReward, 'energyReward': energyReward};

  Map<String, dynamic> childDoc({
    int? totalXuEarned,
    int? petLevel,
    int? approvedTaskCount,
  }) =>
      {
        if (totalXuEarned != null) 'totalXuEarned': totalXuEarned,
        if (petLevel != null) 'petLevel': petLevel,
        if (approvedTaskCount != null) 'approvedTaskCount': approvedTaskCount,
      };

  Map<String, dynamic> updateFor(_FakeFirestore f, String path) =>
      f.committedUpdates.firstWhere((w) => w.path == path).data;

  // ------------------------------------------------------------------
  // AC-1 (Normal path): field deltas, no other children/{childId} field
  // changes.
  // ------------------------------------------------------------------

  test(
      'test_approveTask_normalPath_writesExactFieldDeltas_andNoOtherChildFieldChanges',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] =
          pendingTask(xuReward: 25, energyReward: 20)
      ..seededDocs[childPath] =
          childDoc(totalXuEarned: 0, petLevel: 1, approvedTaskCount: 1);
    final repo = ParentApprovalRepository(firestore: firestore);

    await repo.approveTask(parentId: parentId, childId: childId, taskId: taskId);

    final taskUpdate = updateFor(firestore, taskPath);
    expect(taskUpdate['status'], 'approved');
    expect(taskUpdate['approvedAt'], FieldValue.serverTimestamp());
    expect(taskUpdate.keys, containsAll(['status', 'approvedAt']));
    expect(taskUpdate.keys, hasLength(2));

    final childUpdate = updateFor(firestore, childPath);
    expect(childUpdate['xuBalance'], FieldValue.increment(25));
    expect(childUpdate['storedEnergy'], FieldValue.increment(20.0));
    expect(childUpdate['lastApprovedAt'], FieldValue.serverTimestamp());
    expect(childUpdate['seedCount'], FieldValue.increment(-1));
    expect(childUpdate['totalXuEarned'], FieldValue.increment(25));
    expect(childUpdate['approvedTaskCount'], FieldValue.increment(1));
    // No other children/{childId} field changes — no level-up, no
    // milestone: petLevel/nextLevelThreshold/chestCount must be absent.
    expect(
      childUpdate.keys,
      unorderedEquals([
        'xuBalance',
        'storedEnergy',
        'lastApprovedAt',
        'seedCount',
        'totalXuEarned',
        'approvedTaskCount',
      ]),
    );
  });

  test(
      'test_approveTask_normalPath_zeroRewardTask_stillCommitsWithZeroIncrements',
      () async {
    // AC-1 edge case: X=0, Y=0 — still a valid commit.
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 0, energyReward: 0)
      ..seededDocs[childPath] =
          childDoc(totalXuEarned: 0, petLevel: 1, approvedTaskCount: 1);
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result, isNotNull);
    final childUpdate = updateFor(firestore, childPath);
    expect(childUpdate['xuBalance'], FieldValue.increment(0));
    expect(childUpdate['storedEnergy'], FieldValue.increment(0.0));
    expect(childUpdate['totalXuEarned'], FieldValue.increment(0));
    expect(updateFor(firestore, taskPath)['status'], 'approved');
  });

  // ------------------------------------------------------------------
  // AC-2 (Normal path result): ApproveResult(leveledUp: false,
  // newPetLevel: null).
  // ------------------------------------------------------------------

  test(
      'test_approveTask_normalPath_returnsApproveResult_leveledUpFalse_newPetLevelNull',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 25, energyReward: 20)
      ..seededDocs[childPath] =
          childDoc(totalXuEarned: 0, petLevel: 1, approvedTaskCount: 1);
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result, isNotNull);
    expect(result!.leveledUp, isFalse);
    expect(result.newPetLevel, isNull);
  });

  // ------------------------------------------------------------------
  // AC-3 (Level-up only): leveledUp=true, chestDelta=1, petLevel+=1,
  // xuBalance credited with BOTH task.xuReward AND xuBonus(newLevel).
  // ------------------------------------------------------------------

  test(
      'test_approveTask_levelUpOnly_creditsTaskRewardPlusXuBonus_incrementsPetLevelOnce_chestDeltaOne',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 20, energyReward: 15)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 390, // + 20 = 410 >= nextLevelThreshold(2)=400
        petLevel: 2,
        approvedTaskCount: 10, // + 1 = 11, not a multiple of 5
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result!.leveledUp, isTrue);
    expect(result.newPetLevel, 3);

    final childUpdate = updateFor(firestore, childPath);
    // xuBonus(3) = 3*25+25 = 100; task reward 20 + bonus 100 = 120.
    expect(childUpdate['xuBalance'], FieldValue.increment(120));
    expect(childUpdate['petLevel'], FieldValue.increment(1));
    expect(childUpdate['chestCount'], FieldValue.increment(1));
    expect(childUpdate.containsKey('chestCount'), isTrue);
  });

  test(
      'test_approveTask_levelUp_exactBoundary_totalXuEarnedEqualsThreshold_stillCountsAsLeveledUp',
      () async {
    // AC-3 edge case: newTotalXuEarned == nextLevelThreshold(petLevel) must
    // count as leveled up (>=, not strictly >).
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 10, energyReward: 5)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 140, // + 10 = 150 == nextLevelThreshold(1)
        petLevel: 1,
        approvedTaskCount: 0,
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result!.leveledUp, isTrue);
    expect(result.newPetLevel, 2);
  });

  // ------------------------------------------------------------------
  // AC-4 (Chest milestone only): hitChestMilestone=true, leveledUp=false,
  // chestDelta=1, chestCount+=1.
  // ------------------------------------------------------------------

  test(
      'test_approveTask_chestMilestoneOnly_atExactlyFive_incrementsChestCount_noLevelChange',
      () async {
    // AC-4 edge case: approvedTaskCount starting at 4 -> first milestone at
    // exactly 5.
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 10, energyReward: 5)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 0, // + 10 = 10, far under nextLevelThreshold(1)=150
        petLevel: 1,
        approvedTaskCount: 4, // + 1 = 5, 5 % 5 == 0
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result!.leveledUp, isFalse);
    expect(result.newPetLevel, isNull);

    final childUpdate = updateFor(firestore, childPath);
    expect(childUpdate['chestCount'], FieldValue.increment(1));
    expect(childUpdate.containsKey('petLevel'), isFalse);
    expect(childUpdate.containsKey('nextLevelThreshold'), isFalse);
  });

  // ------------------------------------------------------------------
  // AC-5 (Both triggers combo): GDD's exact worked example.
  // ------------------------------------------------------------------

  test(
      'test_approveTask_bothTriggersCombo_gddWorkedExample_chestDeltaTwo_petLevelIncrementsOnce',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 20, energyReward: 15)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 380, // + 20 = 400 == nextLevelThreshold(2)
        petLevel: 2,
        approvedTaskCount: 24, // + 1 = 25, 25 % 5 == 0
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    // petLevel increments exactly once (not double-counted) — proven by the
    // result landing on level 3, not 4, despite two chestDelta triggers.
    expect(result!.leveledUp, isTrue);
    expect(result.newPetLevel, 3);

    final childUpdate = updateFor(firestore, childPath);
    expect(childUpdate['chestCount'], FieldValue.increment(2));
    expect(childUpdate['petLevel'], FieldValue.increment(1));
    // xuBonus(3) = 100; 20 + 100 = 120.
    expect(childUpdate['xuBalance'], FieldValue.increment(120));
  });

  // ------------------------------------------------------------------
  // AC-6 (Neither trigger): chestDelta=0, chestCount field NOT written at
  // all (not written-as-zero).
  // ------------------------------------------------------------------

  test(
      'test_approveTask_neitherTrigger_chestCountFieldAbsentFromWriteMapEntirely',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 10, energyReward: 5)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 0,
        petLevel: 1,
        approvedTaskCount: 1, // + 1 = 2, not a multiple of 5
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    await repo.approveTask(parentId: parentId, childId: childId, taskId: taskId);

    final childUpdate = updateFor(firestore, childPath);
    expect(childUpdate.containsKey('chestCount'), isFalse);
  });

  // ------------------------------------------------------------------
  // AC-7 (Idempotency): status already 'approved' or 'rejected' -> null,
  // zero writes.
  // ------------------------------------------------------------------

  test('test_approveTask_alreadyApprovedTask_returnsNull_zeroWritesRecorded',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = {
        'status': 'approved',
        'xuReward': 10,
        'energyReward': 5,
      }
      ..seededDocs[childPath] = childDoc();
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result, isNull);
    expect(firestore.committedUpdates, isEmpty);
  });

  test('test_approveTask_alreadyRejectedTask_returnsNull_zeroWritesRecorded',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = {
        'status': 'rejected',
        'xuReward': 10,
        'energyReward': 5,
      }
      ..seededDocs[childPath] = childDoc();
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result, isNull);
    expect(firestore.committedUpdates, isEmpty);
  });

  // ------------------------------------------------------------------
  // AC-8 (Double-tap): two sequential approveTask() calls on the same task
  // -> second reads status != 'pending', returns null; credited exactly
  // once.
  // ------------------------------------------------------------------

  test(
      'test_approveTask_doubleTap_secondSequentialCall_returnsNull_creditedExactlyOnce',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 25, energyReward: 20)
      ..seededDocs[childPath] =
          childDoc(totalXuEarned: 0, petLevel: 1, approvedTaskCount: 1);
    final repo = ParentApprovalRepository(firestore: firestore);

    final firstResult = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);
    expect(firstResult, isNotNull);
    expect(firestore.committedUpdates, hasLength(2)); // task + child

    // Simulate the first call's commit having durably landed server-side
    // before the (near-simultaneous) second tap's transaction reads the
    // task doc — see file header comment for why this manual mutation is
    // the correct structural proxy in this hand-rolled fake.
    firestore.seededDocs[taskPath] = {
      ...firestore.seededDocs[taskPath]!,
      'status': 'approved',
    };

    final secondResult = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(secondResult, isNull);
    // No additional writes landed from the second call.
    expect(firestore.committedUpdates, hasLength(2));
  });

  // ------------------------------------------------------------------
  // AC-9 (Two-device race, testable portion only): same idempotency
  // mechanism as double-tap — this environment has no live Firestore
  // emulator, so this AC is verified via the mocked idempotency gate only
  // (ADR-0013's own Validation Criteria).
  // ------------------------------------------------------------------

  test(
      'test_approveTask_twoDeviceRace_secondCallReadsNonPendingStatus_returnsNull_viaMockedIdempotencyGateOnly',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 25, energyReward: 20)
      ..seededDocs[childPath] =
          childDoc(totalXuEarned: 0, petLevel: 1, approvedTaskCount: 1);
    // Two independently-constructed repository instances stand in for two
    // parent devices, both pointed at the same fake Firestore — mechanically
    // identical to the double-tap test (Firestore's own per-document
    // transaction serialization is what actually prevents the real race;
    // this fake has no concurrency model to exercise that serialization
    // itself, only the idempotency gate it produces).
    final deviceA = ParentApprovalRepository(firestore: firestore);
    final deviceB = ParentApprovalRepository(firestore: firestore);

    final deviceAResult = await deviceA.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);
    expect(deviceAResult, isNotNull);

    firestore.seededDocs[taskPath] = {
      ...firestore.seededDocs[taskPath]!,
      'status': 'approved',
    };

    final deviceBResult = await deviceB.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(deviceBResult, isNull);
    expect(firestore.committedUpdates, hasLength(2));
  });

  // ------------------------------------------------------------------
  // AC-10 (Max level + milestone): leveledUp=false regardless of
  // newTotalXuEarned (guarded by petLevel < 5), chestDelta=1, petLevel
  // unchanged.
  // ------------------------------------------------------------------

  test(
      'test_approveTask_maxLevelWithMilestoneHit_leveledUpFalseUnconditionally_chestDeltaOneOnly',
      () async {
    // Edge case: newTotalXuEarned deliberately set far above any threshold
    // to prove the petLevel < 5 GUARD, not the value, controls this.
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 10, energyReward: 5)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 999999,
        petLevel: 5,
        approvedTaskCount: 4, // + 1 = 5, hits milestone
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result!.leveledUp, isFalse);
    expect(result.newPetLevel, isNull);

    final childUpdate = updateFor(firestore, childPath);
    expect(childUpdate['chestCount'], FieldValue.increment(1));
    expect(childUpdate.containsKey('petLevel'), isFalse);
    expect(childUpdate.containsKey('nextLevelThreshold'), isFalse);
  });

  // ------------------------------------------------------------------
  // Code review follow-up (flame-specialist + qa-tester, 2026-07-18):
  // two real edge cases found in the implementation with no prior test
  // coverage. Not in the story's original 12 ACs — added during the
  // /code-review pass, not invented scope creep.
  // ------------------------------------------------------------------

  test(
      'test_approveTask_corruptedPetLevelZero_treatedAsLevel1_noCrash',
      () async {
    // Regression test for the fix: petLevel PRESENT but corrupted to 0 (bad
    // migration / manual edit) previously reached nextLevelThreshold(0),
    // which throws — an uncaught crash inside the transaction. The
    // repository now clamps petLevel<1 to 1, the same default used when the
    // field is absent entirely.
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 10, energyReward: 5)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 0,
        petLevel: 0, // corrupted — not a valid game state (level starts at 1)
        approvedTaskCount: 1,
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    // Treated identically to petLevel absent (defaults to 1): far below the
    // level-1 threshold (150), so no level-up, no crash.
    expect(result!.leveledUp, isFalse);
    expect(firestore.committedUpdates, hasLength(2));
  });

  test(
      'test_approveTask_malformedTaskDoc_missingXuReward_throwsTypeError',
      () async {
    // Documents current, accepted behavior — NOT a defended-against case.
    // GDD Edge Case 6 (parent-approval.md) explicitly scopes tampered/
    // missing reward values to Task Library's (#8) Reward Integrity Guard
    // at task-creation time, not this transaction. ADR-0013's own reference
    // code (Decision §2) uses the same non-nullable `as num` cast with no
    // `?? default` — this test exists so the failure mode (a raw
    // TypeError, not a graceful error) is documented and would be
    // noticed if it ever silently changed, not so it passes as "handled".
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = {
        'status': 'pending',
        // xuReward deliberately absent.
        'energyReward': 5,
      }
      ..seededDocs[childPath] = childDoc();
    final repo = ParentApprovalRepository(firestore: firestore);

    await expectLater(
      () => repo.approveTask(
          parentId: parentId, childId: childId, taskId: taskId),
      throwsA(isA<TypeError>()),
    );
    expect(firestore.committedUpdates, isEmpty);
  });

  // ------------------------------------------------------------------
  // AC-11 (Transaction failure): any throw propagates uncaught; no partial
  // write occurs; task.status untouched. Edge cases: throw at the read step
  // vs. throw at the write step — both must leave zero recorded writes.
  // ------------------------------------------------------------------

  test(
      'test_approveTask_transactionThrowsAtReadStep_exceptionPropagates_noWritesRecorded',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 25, energyReward: 20)
      ..seededDocs[childPath] = childDoc()
      ..throwOnGet = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Simulated read-step failure for test',
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    await expectLater(
      () => repo.approveTask(
          parentId: parentId, childId: childId, taskId: taskId),
      throwsA(isA<FirebaseException>()),
    );
    expect(firestore.committedUpdates, isEmpty);
  });

  test(
      'test_approveTask_transactionThrowsAtWriteStep_exceptionPropagates_noWritesRecorded',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 25, energyReward: 20)
      ..seededDocs[childPath] =
          childDoc(totalXuEarned: 0, petLevel: 1, approvedTaskCount: 1)
      ..failNextTransactionCommit = true;
    final repo = ParentApprovalRepository(firestore: firestore);

    await expectLater(
      () => repo.approveTask(
          parentId: parentId, childId: childId, taskId: taskId),
      throwsA(isA<FirebaseException>()),
    );
    // The handler DID call transaction.update() (task + child), but the
    // commit itself failed — Firestore's own atomicity: a rejected commit
    // applies neither write. What matters is the FIRESTORE-SIDE committed
    // list stays empty, matching seed_submit_test.dart's own established
    // assertion shape for this class of failure.
    expect(firestore.committedUpdates, isEmpty);
  });

  // ------------------------------------------------------------------
  // AC-12 (nextLevelThreshold cache sync): on level-up, nextLevelThreshold
  // is written to the new level's threshold, or null if the new level is 5.
  // ------------------------------------------------------------------

  test(
      'test_approveTask_levelUp_writesNextLevelThreshold_inSyncWithNewLevel',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 20, energyReward: 15)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 390, // -> newPetLevel 3
        petLevel: 2,
        approvedTaskCount: 10,
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    await repo.approveTask(parentId: parentId, childId: childId, taskId: taskId);

    final childUpdate = updateFor(firestore, childPath);
    // nextLevelThreshold(newPetLevel=3) = 900 (pet_level_threshold_l4,
    // entities.yaml).
    expect(childUpdate['nextLevelThreshold'], 900);
  });

  test(
      'test_approveTask_levelUp_toMaxLevelFive_writesNextLevelThreshold_null',
      () async {
    final firestore = _FakeFirestore()
      ..seededDocs[taskPath] = pendingTask(xuReward: 20, energyReward: 15)
      ..seededDocs[childPath] = childDoc(
        totalXuEarned: 1790, // + 20 = 1810 >= nextLevelThreshold(4)=1800
        petLevel: 4,
        approvedTaskCount: 10,
      );
    final repo = ParentApprovalRepository(firestore: firestore);

    final result = await repo.approveTask(
        parentId: parentId, childId: childId, taskId: taskId);

    expect(result!.newPetLevel, 5);
    final childUpdate = updateFor(firestore, childPath);
    // Key must be PRESENT with a null value (not simply absent) — the ADR's
    // explicit fix for keeping the cache field in sync at max level too.
    expect(childUpdate.containsKey('nextLevelThreshold'), isTrue);
    expect(childUpdate['nextLevelThreshold'], isNull);
  });
}
