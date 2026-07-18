import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';
import 'models/custom_task_template.dart';
import 'reward_table.dart';

/// Writes `customTasks` template documents (ADR-0009 Decision §4). Kept as
/// its own small repository (matching `ChildProfileRepository`'s
/// constructor-injected-Firestore shape) rather than folded into an
/// existing one — `customTasks` is family-scoped like the rest of the
/// family tree, but its write shape (a template, no reward fields, no
/// atomic multi-document batch) doesn't share meaningful code with any
/// existing repository method.
class CustomTaskRepository {
  CustomTaskRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Creates a new `customTasks` template. Structurally impossible to pass
  /// a reward value — this function has no `xuReward`/`energyReward`
  /// parameter at all (ADR-0009 Decision §4: "the parent cannot set reward
  /// values here"). Rewards are re-derived from [categoryId] only when a
  /// child later picks this template and submits a real task instance (a
  /// future epic's write, not this one's).
  ///
  /// Validates [title] is non-empty and [categoryId] is one of the 6 known
  /// categories BEFORE attempting the write — a defensive, UX-quality
  /// guard, not a security boundary (there is no Security Rule gating
  /// `customTasks.categoryId`, since this collection has no reward fields
  /// to protect).
  Future<void> createCustomTaskTemplate({
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

    final template = CustomTaskTemplate(
      title: title.trim(),
      categoryId: categoryId,
      targetChildId: childId,
    );
    await _firestore
        .collection(FirestorePaths.customTasks(parentId))
        .add(template.toFirestoreMap());
  }
}
