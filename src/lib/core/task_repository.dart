import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';
import 'reward_table.dart';

/// Writes `tasks/{taskId}` task-instance documents (ADR-0009 Decision §1)
/// AND the `seedCount +1` denormalized-counter write (ADR-0012 Decision §1)
/// in the SAME [WriteBatch] — the two halves this story builds together
/// (see Story 001's "Scope Expansion Note": no prior story ever built the
/// base task-submission write, so this repository has to build it here
/// rather than merely extending an existing one).
///
/// Deliberately does NOT emit [GameEventType.seedReceived] itself. ADR-0004
/// §3 permits exactly two sanctioned adapters onto `GameEventBus` — a
/// `ref.listen` call inside a `ConsumerWidget`, or a Flame component's
/// tap/drag handler — and explicitly forbids any third path ("e.g. a
/// Notifier emitting directly"). A repository class is neither sanctioned
/// adapter, so this class stops at the Firestore write; whichever future
/// story builds the Task Submission Screen (no `/ux-design` spec exists yet
/// — see this story's Scope Expansion Note) is responsible for calling
/// [submitTask] from its own `ConsumerWidget` and emitting the event from
/// there, per ADR-0004 adapter (a). Found and corrected during this story's
/// own code review — the first draft violated this rule.
///
/// Kept as its own small repository, matching [CustomTaskRepository]'s
/// constructor-injected-`FirebaseFirestore` shape (the codebase's real
/// convention — see ADR-0003's "PersistenceRepository is the ONLY module
/// that touches Firestore paths directly" rule, applied here as one
/// focused repository class per write concern, not a single monolithic
/// `PersistenceRepository`).
class TaskRepository {
  TaskRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Creates a new `tasks/{taskId}` document (`status: 'pending'`, reward
  /// values looked up from [rewardFor] — NEVER caller-supplied, per
  /// ADR-0009 Decision §3's reward-integrity rule) and, in the SAME
  /// [WriteBatch], increments `families/{parentId}/children/{childId}
  /// .seedCount` by exactly 1 (ADR-0012 Decision §1). Both writes commit
  /// atomically or neither does — Firestore's own `WriteBatch` guarantee,
  /// not anything this method has to implement itself.
  ///
  /// Validates [title]/[categoryId] BEFORE attempting the write — a
  /// defensive, fast-fail UX guard matching
  /// [CustomTaskRepository.createCustomTaskTemplate]'s exact validation
  /// depth, not the actual security boundary (the deployed `rewardOk()`
  /// Security Rule, `firestore.rules:31-35`, is the real backstop — see
  /// ADR-0009 Decision §3).
  ///
  /// On any failure (validation OR a rejected/failed [WriteBatch.commit]),
  /// the exception is left to surface to the caller — no swallowed errors,
  /// matching [CustomTaskRepository]'s let-it-throw pattern.
  ///
  /// Does NOT emit `GameEventType.seedReceived` (see class doc comment) —
  /// that is the caller's responsibility, from a sanctioned ADR-0004 adapter.
  Future<void> submitTask({
    required String parentId,
    required String childId,
    required String title,
    required String categoryId,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    if (!knownCategoryIds.contains(categoryId)) {
      throw ArgumentError.value(
        categoryId,
        'categoryId',
        'must be one of $knownCategoryIds',
      );
    }

    final reward = rewardFor(categoryId);
    final batch = _firestore.batch();

    // Auto-generated task ID (ADR-0003's "tasks use auto-generated IDs"
    // rule) — never a predictable/caller-supplied ID.
    final taskRef =
        _firestore.collection(FirestorePaths.tasks(parentId, childId)).doc();
    batch.set(taskRef, {
      'title': title.trim(),
      'flavorText': flavorTextFor(categoryId),
      'categoryId': categoryId,
      'xuReward': reward.xu,
      'energyReward': reward.energy,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      // 'approvedAt'/'rejectedAt' deliberately absent — a pending task has
      // neither, and TaskModel treats their absence as null (ADR-0009 §1).
    });

    // The seedCount +1 lives on the CHILD doc, not under tasks/ — do not
    // confuse the two document references in this batch (ADR-0012 §1).
    final childRef = _firestore.doc(FirestorePaths.child(parentId, childId));
    batch.update(childRef, {'seedCount': FieldValue.increment(1)});

    // No prior read, no connectivity check — this is an unconditional,
    // offline-capable atomic write (ADR-0012 §1 / GDD AC-5). Firestore's
    // own local-cache-then-sync behavior handles the offline case
    // transparently; this method never branches on connectivity.
    await batch.commit();
  }
}
