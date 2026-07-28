import 'dart:async';

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

/// Family-wide pending tasks, merged across ALL of the family's children
/// (max 4, Auth & Account's own cap) — uncapped overall, newest-first.
/// Fixes Parent Dashboard UI Story 001's blocker: [pendingTasksProvider]
/// above only ever queries the single `activeChildProvider` child, which
/// returns empty for the primary "parent logs in directly, no active child
/// session" flow and silently omits every sibling's pending tasks (found in
/// `/dev-story`, 2026-07-18) — this story's own AC-2 (multi-child
/// correctness) needs a genuinely family-wide source.
///
/// Implementation: awaits [childProfilesProvider] for the child list, opens
/// one composite-indexed per-child `snapshots()` stream per child (the same
/// query shape [pendingTasksProvider] already uses — no new index needed),
/// then combines them with a hand-rolled combineLatest ([_mergeLatestLists]
/// — no `rxdart` dependency in this project; bounded to ≤4 sources, well
/// within what a manual merge handles cleanly). A `collectionGroup('tasks')`
/// query was considered instead but would need a NEW `COLLECTION_GROUP`-
/// scoped composite index deployed (the existing `firestore.indexes.json`
/// entry is `COLLECTION`-scoped only, i.e. per-subcollection) — this merge
/// approach needs no Firestore infra change, which matters given this
/// project's environment cannot run the Firestore emulator to verify a rules/
/// index deploy (documented gap, Task Library epic Completion Notes).
///
/// `retry: (retryCount, error) => null` — same rationale as
/// [childProfilesProvider]'s own doc comment: disables riverpod 3.3.2's
/// default silent ~38s retry-before-AsyncError, so a genuine failure (either
/// the children fetch or any per-child tasks stream) surfaces immediately
/// per this story's own "List load error state" AC, instead of leaving the
/// tab stuck on its loading skeleton.
final familyPendingTasksProvider = StreamProvider<List<TaskModel>>(
  (ref) async* {
    final parentId = ref.watch(authStateProvider).value?.uid;
    if (parentId == null) {
      yield const [];
      return;
    }

    final children = await ref.watch(childProfilesProvider.future);
    if (children.isEmpty) {
      yield const [];
      return;
    }

    final firestore = ref.watch(firebaseFirestoreProvider);
    final perChildStreams = [
      for (final child in children)
        firestore
            .collection(FirestorePaths.tasks(parentId, child.childId))
            .where('status', isEqualTo: 'pending')
            .orderBy('submittedAt', descending: true)
            .snapshots()
            .map((s) => s.docs.map(TaskModel.fromFirestore).toList()),
    ];

    yield* _mergeLatestLists(perChildStreams);
  },
  retry: (retryCount, error) => null,
);

/// Hand-rolled combineLatest for `List<TaskModel>` sources: re-emits the
/// concatenated, re-sorted (newest-`submittedAt`-first) union of every
/// source's latest value, once ALL sources have emitted at least once
/// (standard combineLatest semantics — matches Firestore's own "no partial
/// snapshot" expectation, so the UI never shows a merged list missing a
/// child that simply hasn't reported in yet). An update from any single
/// source re-emits the full merged list immediately — an Approve/Reject on
/// one child's card does not wait for a sibling child's snapshot to also
/// fire before the list reflects it.
Stream<List<TaskModel>> _mergeLatestLists(
  List<Stream<List<TaskModel>>> sources,
) {
  if (sources.isEmpty) return Stream.value(const []);

  late final StreamController<List<TaskModel>> controller;
  final latest = List<List<TaskModel>?>.filled(sources.length, null);
  final subscriptions = <StreamSubscription<List<TaskModel>>>[];

  void emitIfReady() {
    if (latest.any((value) => value == null)) return;
    final merged = <TaskModel>[for (final list in latest) ...list!]
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    controller.add(merged);
  }

  controller = StreamController<List<TaskModel>>(
    onListen: () {
      for (var i = 0; i < sources.length; i++) {
        final index = i;
        subscriptions.add(
          sources[index].listen(
            (value) {
              latest[index] = value;
              emitIfReady();
            },
            onError: controller.addError,
          ),
        );
      }
    },
    onCancel: () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
      subscriptions.clear();
    },
  );

  return controller.stream;
}

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
