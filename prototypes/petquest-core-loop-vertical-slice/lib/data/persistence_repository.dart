// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the offline-first Firestore write contract
// (ADR-0003) - runTransaction for approve/reject, FieldValue.increment() for
// balances, idempotency-read-first - actually hold up when built, not just
// described on paper?
// Date: 2026-07-13
//
// Scope cut: no onTaskApproved Cloud Function (would require the Functions
// emulator + Node.js deploy, out of proportion for a 1-3 week slice). The
// storedEnergy cap-at-100 that ADR-0003 assigns to that Cloud Function is
// applied synchronously inside this file's approve transaction instead -
// documented here and in REPORT.md as an intentional scope cut, not a defense
// -in-depth regression (there is no adversarial client in a solo vertical
// slice validating fun and architecture).

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../tasks/task_models.dart';

class PersistenceRepository {
  final FirebaseFirestore _db;
  PersistenceRepository(this._db);

  static const int _maxEnergy = 100;
  static const int _initialEnergy = 70;
  static const int _initialXu = 0;

  /// Dev bootstrap only (Onboarding Flow #24 is out of scope) - creates the
  /// single family/child this slice exercises if they don't already exist.
  Future<void> seedDevFamilyAndChild({
    required String parentId,
    required String childId,
    required String childName,
    required String pinHash,
    required String pinSalt,
  }) async {
    final childRef = _db.doc(FirestorePaths.child(parentId, childId));
    final snap = await childRef.get();
    if (snap.exists) return;

    final batch = _db.batch();
    batch.set(_db.doc(FirestorePaths.family(parentId)), {
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(childRef, {
      'name': childName,
      'xuBalance': _initialXu,
      'storedEnergy': _initialEnergy,
      'lastApprovedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.doc(FirestorePaths.credentials(parentId, childId)), {
      'pinHash': pinHash,
      'pinSalt': pinSalt,
    });
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getCredentials(
    String parentId,
    String childId,
  ) async {
    final snap = await _db.doc(FirestorePaths.credentials(parentId, childId)).get();
    return snap.data();
  }

  Stream<Map<String, dynamic>?> watchChild(String parentId, String childId) {
    return _db
        .doc(FirestorePaths.child(parentId, childId))
        .snapshots()
        .map((s) => s.data());
  }

  /// Submit task (child, offline-capable write). Reward is derived from the
  /// category table client-side, then re-validated synchronously by
  /// firestore.rules on create (ADR-0009 - never client-settable in practice,
  /// even though this client is the one deriving it here).
  Future<void> submitTask({
    required String parentId,
    required String childId,
    required String title,
    required String categoryId,
  }) async {
    final reward = rewardTable[categoryId] ?? rewardTable['custom']!;
    await _db.collection(FirestorePaths.tasks(parentId, childId)).add({
      'title': title,
      'categoryId': categoryId,
      'xuReward': reward.xu,
      'energyReward': reward.energy,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Task>> watchPendingTasks(String parentId, String childId) {
    return _db
        .collection(FirestorePaths.tasks(parentId, childId))
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(Task.fromFirestore).toList());
  }

  /// Approve: idempotency read FIRST inside the transaction (ADR-0003
  /// "Required Patterns"), then a single atomic write of task status + reward.
  Future<void> approveTask({
    required String parentId,
    required String childId,
    required String taskId,
  }) async {
    final taskRef = _db.doc(FirestorePaths.task(parentId, childId, taskId));
    final childRef = _db.doc(FirestorePaths.child(parentId, childId));

    await _db.runTransaction((txn) async {
      final taskSnap = await txn.get(taskRef);
      if (!taskSnap.exists || taskSnap.data()!['status'] != 'pending') {
        return; // already resolved by a prior attempt - idempotent no-op
      }
      final childSnap = await txn.get(childRef);
      final currentEnergy =
          (childSnap.data()?['storedEnergy'] as num?)?.toInt() ?? _initialEnergy;
      final energyReward = (taskSnap.data()!['energyReward'] as num).toInt();
      final newEnergy = (currentEnergy + energyReward).clamp(0, _maxEnergy);

      txn.update(taskRef, {'status': 'approved'});
      txn.update(childRef, {
        'xuBalance': FieldValue.increment((taskSnap.data()!['xuReward'] as num).toInt()),
        'storedEnergy': newEnergy,
        'lastApprovedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectTask({
    required String parentId,
    required String childId,
    required String taskId,
  }) async {
    final taskRef = _db.doc(FirestorePaths.task(parentId, childId, taskId));
    await _db.runTransaction((txn) async {
      final taskSnap = await txn.get(taskRef);
      if (!taskSnap.exists || taskSnap.data()!['status'] != 'pending') {
        return;
      }
      txn.update(taskRef, {'status': 'rejected'});
    });
  }
}
