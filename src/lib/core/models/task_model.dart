import 'package:cloud_firestore/cloud_firestore.dart';

/// A single `tasks/{taskId}` document (ADR-0009 Decision §1) — the
/// real-world task lifecycle: `pending → approved | rejected`, one document
/// per submission. No `cancelled` value exists anywhere in this schema —
/// TR-tasklib-001's "no withdrawal" rule is enforced by absence, not by a
/// runtime guard that could be bypassed.
class TaskModel {
  const TaskModel({
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
