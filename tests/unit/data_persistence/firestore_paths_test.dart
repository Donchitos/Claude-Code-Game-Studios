// Run with:
//   cd src && flutter test ../tests/unit/data_persistence/firestore_paths_test.dart
//
// Pure string-construction tests — no Firestore, no fakes. Pins the exact
// path shapes ADR-0003 Decision §2 specifies, so a future typo/reordering
// in FirestorePaths breaks a test instead of silently misplacing every
// downstream epic's reads/writes.

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firestore_paths.dart';

void main() {
  const parentId = 'p1';
  const childId = 'c1';

  group('FirestorePaths.tasks / task', () {
    test('test_tasks_returns_the_child_scoped_collection_path', () {
      expect(
        FirestorePaths.tasks(parentId, childId),
        'families/p1/children/c1/tasks',
      );
    });

    test('test_task_returns_the_child_scoped_document_path', () {
      expect(
        FirestorePaths.task(parentId, childId, 't1'),
        'families/p1/children/c1/tasks/t1',
      );
    });
  });

  group('FirestorePaths.customTasks / customTask', () {
    test('test_customTasks_returns_the_family_scoped_collection_path_with_no_childId',
        () {
      expect(
        FirestorePaths.customTasks(parentId),
        'families/p1/customTasks',
      );
    });

    test('test_customTask_returns_the_family_scoped_document_path_with_no_childId',
        () {
      expect(
        FirestorePaths.customTask(parentId, 'ct1'),
        'families/p1/customTasks/ct1',
      );
    });
  });

  group('FirestorePaths.inventory / inventoryItem', () {
    test('test_inventory_returns_the_child_scoped_collection_path', () {
      expect(
        FirestorePaths.inventory(parentId, childId),
        'families/p1/children/c1/inventory',
      );
    });

    test('test_inventoryItem_returns_the_child_scoped_document_path', () {
      expect(
        FirestorePaths.inventoryItem(parentId, childId, 'i1'),
        'families/p1/children/c1/inventory/i1',
      );
    });
  });
}
