// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the "instant visual feedback while waiting for
// approval" beat (Seed Buffer #10) actually make the parent-latency gap feel
// okay, per game-concept.md's Short-Term loop?
// Date: 2026-07-13
//
// Slice simplification: seedCount = COUNT(pending tasks) directly from the
// live query, not a separately-maintained denormalized counter field (the
// real system's TR-seedbuffer-001 invariant - no ADR written yet for this
// system, so this is a reasonable placeholder pending that ADR).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository_providers.dart';
import '../tasks/task_models.dart';

final pendingTasksProvider = StreamProvider<List<Task>>((ref) {
  final repo = ref.watch(persistenceRepositoryProvider);
  return repo.watchPendingTasks(devParentId, devChildId);
});

final seedCountProvider = Provider<int>((ref) {
  return ref.watch(pendingTasksProvider).value?.length ?? 0;
});
