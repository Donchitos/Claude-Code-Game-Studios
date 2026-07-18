import 'package:cloud_firestore/cloud_firestore.dart';

/// A `families/{parentId}/customTasks/{customTaskId}` document (ADR-0009
/// Decision §4) — a TEMPLATE a parent creates, structurally distinct from a
/// real `tasks/{taskId}` instance. Deliberately has NO `status`, `xuReward`,
/// or `energyReward` fields: a parent creating a template is not "the
/// child completed something in real life" (GDD Core Rule 4) — a parent
/// cannot set reward values here even if they wanted to, since this model
/// has no field to set them on. The real task instance (with `status` and
/// rewards re-derived from `categoryId`) is created only when the child
/// later picks this template and submits — that write is out of this
/// epic's scope (a future Task Submission Screen epic).
class CustomTaskTemplate {
  const CustomTaskTemplate({
    required this.title,
    required this.categoryId,
    required this.targetChildId,
    this.createdAt,
  });

  final String title;
  final String categoryId;
  final String targetChildId;

  /// Null when not yet written — [toFirestoreMap] substitutes
  /// `FieldValue.serverTimestamp()` in that case. Never populated by this
  /// story from a read (reading `customTasks` back is a future story's
  /// scope); exists on the model because the Firestore document always has
  /// this field once written.
  final Object? createdAt;

  Map<String, dynamic> toFirestoreMap() => {
        'title': title,
        'categoryId': categoryId,
        'targetChildId': targetChildId,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
