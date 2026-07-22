import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/custom_task_repository.dart';
import '../core/firebase_providers.dart';
import '../core/firestore_paths.dart';
import '../core/models/task_model.dart';
import 'auth_providers.dart';

/// [CustomTaskRepository] instance (Parent Dashboard UI Story 002) — same
/// constructor-injected-Firestore shape as [childProfileRepositoryProvider]
/// in `auth_providers.dart`. Lives here, not in `auth_providers.dart`,
/// because `CustomTaskRepository` is a Task Library (#8) type, matching this
/// file's existing `pendingTasksProvider`/`taskHistoryProvider` domain.
final customTaskRepositoryProvider = Provider<CustomTaskRepository>((ref) {
  return CustomTaskRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

/// Pending tasks for the active child, newest-first (ADR-0009 Decision §5).
/// Composite-indexed: `(status ASC, submittedAt DESC)` — see
/// `firestore.indexes.json`. Null-guarded: resolves to `[]` rather than
/// issuing a query against a `families/null/children/null/tasks` path when
/// no parent/child is scoped (matches `taskHistoryProvider`'s own guard —
/// the GDD's own code sketch omitted this guard here, a real correction
/// applied per ADR-0009's Migration Plan §2).
final pendingTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final childId = ref.watch(activeChildProvider)?.childId;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return Stream.value(const []);

  return ref
      .watch(firebaseFirestoreProvider)
      .collection(FirestorePaths.tasks(parentId, childId))
      .where('status', isEqualTo: 'pending')
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
});

/// Approved/rejected tasks for the active child within the last 30 days,
/// newest-first (ADR-0009 Decision §5). Composite-indexed:
/// `(status ASC, submittedAt DESC)`. Uses `whereIn`, NEVER `not-in` — a
/// plain `in` combines with a range filter on a different field
/// (`submittedAt`); `not-in` cannot.
final taskHistoryProvider = StreamProvider<List<TaskModel>>((ref) {
  final childId = ref.watch(activeChildProvider)?.childId;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return Stream.value(const []);

  final cutoff =
      Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(FirestorePaths.tasks(parentId, childId))
      .where('status', whereIn: ['approved', 'rejected'])
      .where('submittedAt', isGreaterThanOrEqualTo: cutoff)
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
});
