import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

/// Story: parent-approval/story-001-approve-transaction — Test Evidence
/// section. Implements TR-parentapproval-001/002/003/004/005/008 per
/// ADR-0013 Decision §1-§4.
///
/// `null` == idempotent no-op (task was already approved/rejected — the
/// double-tap / two-device-race path). A non-null result means this call
/// genuinely committed the transaction; the CALLER (a future
/// `ConsumerWidget`, per ADR-0004 §3 adapter (a)) is responsible for
/// emitting `taskApproved`/`petLeveledUp` off of it — this class never
/// touches `GameEventBus`. [newPetLevel] is populated whenever [leveledUp]
/// is true — the already-registered `game_event_bus` contract
/// (`docs/registry/architecture.yaml`) declares `petLeveledUp`'s payload
/// type as `int`, not `null`.
class ApproveResult {
  const ApproveResult({required this.leveledUp, this.newPetLevel});
  final bool leveledUp;
  final int? newPetLevel; // non-null iff leveledUp
}

/// `nextLevelThreshold()`/`xuBonus()`/`gachaFreeChestMilestone` — pure
/// lookup functions/constant, sourced from `design/registry/entities.yaml`
/// (`pet_level_threshold_l2..l5` = 150/400/900/1800,
/// `pet_levelup_xu_bonus` = `level*25+25`, `gacha_free_chest_milestone` = 5)
/// — not invented. Formal ownership of these formulas belongs to Pet
/// Leveling (#16) / Gacha-Loot (#12), which have no ADR/epic yet (ADR-0013
/// Decision §4) — placed here alongside [ParentApprovalRepository] as a
/// "contract now, implement fully later" shape. Throws outside 1-4 by
/// design: every call site in this file guards `petLevel < 5`/
/// `newPetLevel < 5` first, and any future caller (e.g. a level-progress-bar
/// UI) must do the same.
int nextLevelThreshold(int currentLevel) => switch (currentLevel) {
      1 => 150,
      2 => 400,
      3 => 900,
      4 => 1800,
      _ => throw ArgumentError(
          'no next threshold at max level — callers must guard petLevel < 5 first',
        ),
    };

/// `pet_levelup_xu_bonus`, entities.yaml — [newLevel] is the level AFTER
/// the level-up (2-5).
int xuBonus(int newLevel) => newLevel * 25 + 25;

/// `gacha_free_chest_milestone`, entities.yaml.
const gachaFreeChestMilestone = 5;

/// Writes the atomic "task approved -> reward assembly" transaction (ADR-0013
/// Decision §1-§2). Kept as its own small repository, matching
/// [TaskRepository]/[CustomTaskRepository]'s constructor-injected-Firestore
/// shape — one focused repository per write concern, not a monolithic
/// `PersistenceRepository` (ADR-0013 Decision §1 explicitly supersedes
/// ADR-0003's earlier "PersistenceRepository is the ONLY module" framing).
///
/// Deliberately does NOT call `GameEventBus().emit()` anywhere in this
/// class. ADR-0004 §3 permits exactly two sanctioned adapters onto the bus
/// (a `ref.listen` call inside a `ConsumerWidget`, or a Flame component's
/// tap/drag handler) — a repository is neither. `approveTask()` returns an
/// [ApproveResult]? for a future caller to react to instead (this exact
/// mistake was already made and fixed once in this codebase, Seed Buffer
/// Story 001 — see [TaskRepository]'s own doc comment).
///
class ParentApprovalRepository {
  ParentApprovalRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Single `runTransaction` per GDD Core Rule 4 (one transaction per task,
  /// never a batch of tasks). Read order is FIXED and load-bearing: the task
  /// doc's `status` field must be the FIRST read inside the transaction —
  /// this is the idempotency gate itself (GDD Core Rule 2), not a separate
  /// pre-check outside the transaction (which would be a TOCTOU race).
  ///
  /// Returns `null` on an idempotent no-op (task already `approved`/
  /// `rejected` — covers both the double-tap and the two-device-race paths,
  /// both silent by design). Returns a non-null [ApproveResult] iff this
  /// call genuinely committed the transaction.
  ///
  /// Any `runTransaction` throw (offline, transient, or other) propagates
  /// uncaught — no partial write occurs (Firestore's own transaction
  /// atomicity), matching [CustomTaskRepository]'s let-it-throw pattern
  /// (ADR-0013 Decision §5, unified error handling).
  Future<ApproveResult?> approveTask({
    required String parentId,
    required String childId,
    required String taskId,
  }) {
    return _firestore.runTransaction<ApproveResult?>((transaction) async {
      final taskRef =
          _firestore.doc(FirestorePaths.task(parentId, childId, taskId));
      final childRef = _firestore.doc(FirestorePaths.child(parentId, childId));

      // FIRST read, inside the transaction — the idempotency gate. Not a
      // separate pre-check (TOCTOU race); this is what Firestore's
      // per-document transaction serialization actually protects against
      // (GDD Core Rule 2).
      final taskSnap = await transaction.get(taskRef);
      final taskData = taskSnap.data();
      if (taskData == null || taskData['status'] != 'pending') {
        return null; // Idempotent no-op — double-tap or two-device race, both silent.
      }

      final childSnap = await transaction.get(childRef);
      final childData = childSnap.data() ?? {};
      final xuReward = (taskData['xuReward'] as num).toInt();
      final energyReward = (taskData['energyReward'] as num).toInt();
      final totalXuEarned = (childData['totalXuEarned'] as num?)?.toInt() ?? 0;
      // Corrupted-to-<1 (e.g. a bad migration or manual edit) is treated the
      // same as missing — mirrors Currency's established two-distinct-
      // clamp-paths precedent (missing-field vs. invalid-value both resolve
      // to the same safe default). Without this, petLevel=0 would pass the
      // `petLevel < 5` guard below and crash inside nextLevelThreshold()'s
      // switch, which only covers 1-4 (found in code review, qa-tester).
      final rawPetLevel = (childData['petLevel'] as num?)?.toInt() ?? 1;
      final petLevel = rawPetLevel < 1 ? 1 : rawPetLevel;
      final approvedTaskCount =
          (childData['approvedTaskCount'] as num?)?.toInt() ?? 0;

      final newTotalXuEarned = totalXuEarned + xuReward;
      final leveledUp =
          petLevel < 5 && newTotalXuEarned >= nextLevelThreshold(petLevel);
      final newApprovedTaskCount = approvedTaskCount + 1;
      final hitChestMilestone =
          newApprovedTaskCount % gachaFreeChestMilestone == 0;
      final chestDelta = (leveledUp ? 1 : 0) + (hitChestMilestone ? 1 : 0);
      final newPetLevel = leveledUp ? petLevel + 1 : petLevel;
      var xuIncrement = xuReward;
      if (leveledUp) xuIncrement += xuBonus(newPetLevel);

      transaction.update(taskRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(childRef, {
        'xuBalance': FieldValue.increment(xuIncrement),
        // .toDouble() — storedEnergy is a real double field (Time & Decay,
        // ADR-0005); the increment literal's type must match the target
        // field's stored type (ADR-0003).
        'storedEnergy': FieldValue.increment(energyReward.toDouble()),
        'lastApprovedAt': FieldValue.serverTimestamp(), // resets Time & Decay's clock, ADR-0005
        'seedCount': FieldValue.increment(-1), // clamp-at-0 is seedCountProvider's job (ADR-0012 §3), not this write's
        'totalXuEarned': FieldValue.increment(xuReward),
        'approvedTaskCount': FieldValue.increment(1),
        if (leveledUp) ...{
          'petLevel': FieldValue.increment(1),
          // Keeps the stored nextLevelThreshold cache field in sync with
          // petLevel on every level-up this transaction is the sole writer
          // of. null at max level (no "next" threshold beyond L5).
          'nextLevelThreshold':
              newPetLevel < 5 ? nextLevelThreshold(newPetLevel) : null,
        },
        if (chestDelta > 0) 'chestCount': FieldValue.increment(chestDelta),
      });

      return ApproveResult(
        leveledUp: leveledUp,
        newPetLevel: leveledUp ? newPetLevel : null,
      );
    });
  }

  /// Story: parent-approval/story-002-reject-transaction — Test Evidence
  /// section. Implements TR-parentapproval-006/008 per ADR-0013 Decision §3.
  ///
  /// Same idempotency shape as [approveTask]: the task doc's `status` field
  /// is the FIRST read inside the transaction (the idempotency gate itself,
  /// GDD Core Rule 2) — not a separate pre-check outside the transaction
  /// (which would be a TOCTOU race). Unlike [approveTask], no economy fields
  /// are touched: only `status`/`rejectedAt` on the task and `seedCount` on
  /// the child.
  ///
  /// Returns `Future<void>` — there is no result value to hand off to a
  /// future caller (stronger constraint than [approveTask]'s, which at
  /// least returns [ApproveResult]?). This method deliberately never touches
  /// `GameEventBus`: GDD Core Rule 3 is explicit that reject's "wither"
  /// animation is UI-local (owned by Task Management UI #19 off the
  /// task-list transition), not a Pet State Machine trigger / bus event.
  ///
  /// No un-reject: an already-`rejected` task (or an already-`approved`
  /// one) short-circuits identically at the idempotency gate — there is no
  /// separate "un-reject" code path (GDD Edge Case 8).
  ///
  /// Writes `seedCount` on [childRef] without first reading it (unlike
  /// [approveTask]) — safe only because a task can never exist under a
  /// child doc that doesn't exist itself (tasks are a subcollection of
  /// `children/{childId}`), the same invariant ADR-0012 §2 already states
  /// for Seed Buffer's own `-1` write. If that invariant is ever violated
  /// (e.g. a future admin tool creates orphaned task docs), this `update()`
  /// throws `NOT_FOUND` — which propagates uncaught via the unified error
  /// handling below, the same as any other transaction failure (found in
  /// code review, qa-tester, 2026-07-18).
  ///
  /// Any `runTransaction` throw (offline, transient, or other) propagates
  /// uncaught — no partial write occurs (Firestore's own transaction
  /// atomicity), matching [approveTask]'s unified error handling (ADR-0013
  /// Decision §5).
  Future<void> rejectTask({
    required String parentId,
    required String childId,
    required String taskId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final taskRef =
          _firestore.doc(FirestorePaths.task(parentId, childId, taskId));
      final childRef = _firestore.doc(FirestorePaths.child(parentId, childId));

      final taskSnap = await transaction.get(taskRef);
      if (taskSnap.data()?['status'] != 'pending') {
        return; // Idempotent no-op — already approved/rejected, both silent.
      }

      transaction.update(taskRef, {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(childRef, {
        'seedCount': FieldValue.increment(-1),
      });
    });
    // No GameEvent — wither is a UI-local animation Task Management UI (#19)
    // owns directly off the task list transition, not a Pet State Machine
    // trigger (GDD Core Rule 3, explicit).
  }
}
