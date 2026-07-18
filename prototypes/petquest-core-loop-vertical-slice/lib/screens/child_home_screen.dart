// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does submitting a real-world task feel immediate
// (Seed Buffer feedback) even though the reward doesn't land until a parent
// approves?
// Date: 2026-07-13

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository_providers.dart';
import '../tasks/task_models.dart';

class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen> {
  bool _submitting = false;

  Future<void> _submit(({String title, String categoryId}) taskDef) async {
    setState(() => _submitting = true);
    final repo = ref.read(persistenceRepositoryProvider);
    await repo.submitTask(
      parentId: devParentId,
      childId: devChildId,
      title: taskDef.title,
      categoryId: taskDef.categoryId,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn nhiệm vụ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: sliceTaskCatalog.map((t) {
          final reward = rewardTable[t.categoryId]!;
          return Card(
            child: ListTile(
              title: Text(t.title),
              subtitle: Text('+${reward.xu} xu · +${reward.energy} energy khi được duyệt'),
              trailing: _submitting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right),
              onTap: _submitting ? null : () => _submit(t),
            ),
          );
        }).toList(),
      ),
    );
  }
}
