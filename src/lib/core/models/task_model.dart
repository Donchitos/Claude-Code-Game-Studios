import 'package:cloud_firestore/cloud_firestore.dart';

/// A single `tasks/{taskId}` document (ADR-0009 Decision §1) — the
/// real-world task lifecycle: `pending → approved | rejected`, one document
/// per submission. No `cancelled` value exists anywhere in this schema —
/// TR-tasklib-001's "no withdrawal" rule is enforced by absence, not by a
/// runtime guard that could be bypassed.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.childId,
    required this.title,
    required this.flavorText,
    required this.categoryId,
    required this.xuReward,
    required this.energyReward,
    required this.status,
    required this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
  });

  /// The `tasks/{taskId}` document ID — required to call
  /// `approveTask()`/`rejectTask()` (Parent Approval #11, ADR-0013), which
  /// both take `taskId` as a parameter. Added for Parent Dashboard UI Story
  /// 001 (TR-parentdash-001) — this model's own reader is that story's
  /// pending-list cards.
  final String id;

  /// The owning child's ID — NOT a document field (tasks live at
  /// `families/{parentId}/children/{childId}/tasks/{taskId}`, `childId` is
  /// only ever present in the PATH). Derived in [fromFirestore] from
  /// `doc.reference.parent.parent!.id` rather than threaded in as a separate
  /// parameter — always correct regardless of whether the snapshot came from
  /// a single child's subcollection query or a merged multi-child stream
  /// (Parent Dashboard UI Story 001's `familyPendingTasksProvider`), since a
  /// `QueryDocumentSnapshot`'s `.reference` always carries its true full
  /// path. Required to resolve per-card avatar/name and to call
  /// `approveTask()`/`rejectTask()`, both of which take `childId`.
  final String childId;

  final String title;
  final String flavorText;
  final String categoryId;
  final int xuReward;
  final int energyReward;

  /// `'pending' | 'approved' | 'rejected'` — deliberately a plain String,
  /// not an enum with a `cancelled` case that would then need to be
  /// guarded against; the value space this schema can represent has no
  /// `cancelled` at all.
  final String status;

  final DateTime submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;

  factory TaskModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TaskModel(
      id: doc.id,
      // `tasks` collection's parent document IS the child doc — its `.id`
      // is the childId. `.parent` on a subcollection reference is only ever
      // null for a ROOT collection (never the case here); the `!` is safe.
      childId: doc.reference.parent.parent!.id,
      title: data['title'] as String,
      flavorText: data['flavorText'] as String,
      categoryId: data['categoryId'] as String,
      xuReward: (data['xuReward'] as num).toInt(),
      energyReward: (data['energyReward'] as num).toInt(),
      status: data['status'] as String,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
    );
  }
}
