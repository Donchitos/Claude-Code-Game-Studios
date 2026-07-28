// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the approve action's reward reach the child's
// Mochi with the latency the multi-device sync spike measured (avg 151ms)?
// Date: 2026-07-13
//
// Scope cut: no real push notification (ADR-0010 is out of this slice's
// scope) - the parent switches here manually via the button in
// pet_room_screen.dart instead of tapping a notification.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_state.dart';
import '../core/game_event_bridge.dart';
import '../data/repository_providers.dart';
import '../economy/seed_buffer_provider.dart';
import '../tasks/task_models.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  Future<void> _approve(WidgetRef ref, Task task) async {
    final repo = ref.read(persistenceRepositoryProvider);
    await repo.approveTask(parentId: devParentId, childId: devChildId, taskId: task.id);
    // Signal the GameEventBridge (ADR-0004 sanctioned ref.listen adapter) -
    // this is the taskApproved event's own distinct payload (ADR-0004 SS3,
    // TR-parentapproval-007), not reused from petMoodChanged.
    ref.read(lastApprovedXuRewardProvider.notifier).state = task.xuReward;
    ref.read(taskApprovedNonceProvider.notifier).state++;
  }

  Future<void> _reject(WidgetRef ref, Task task) async {
    final repo = ref.read(persistenceRepositoryProvider);
    await repo.rejectTask(parentId: devParentId, childId: devChildId, taskId: task.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chế độ phụ huynh'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(appModeProvider.notifier).state = AppMode.childActive,
        ),
      ),
      body: pendingAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('Không có nhiệm vụ nào đang chờ duyệt 🎉'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final t = tasks[i];
              return Card(
                child: ListTile(
                  title: Text(t.title),
                  subtitle: Text('+${t.xuReward} xu · +${t.energyReward} energy'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () => _reject(ref, t),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _approve(ref, t),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
