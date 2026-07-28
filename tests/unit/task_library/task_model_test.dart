// Run with:
//   cd src && flutter test ../tests/unit/task_library/task_model_test.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/models/task_model.dart';
import 'package:pet_quest/core/reward_table.dart';
import 'package:yaml/yaml.dart';

/// Minimal fake `DocumentReference` built purely from a path STRING —
/// generic, reusable for any Firestore path shape, no hookup to any fake
/// Firestore registry needed. `.parent` is derived by splitting off the
/// last path segment, alternating collection/doc the way real Firestore
/// paths always do — this is what lets `TaskModel.fromFirestore`'s
/// `doc.reference.parent.parent!.id` (tasks collection -> its owning child
/// doc -> that doc's id, i.e. `childId`) resolve correctly against a fake.
class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this._path);
  final String _path;

  @override
  String get id => _path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> get parent =>
      _FakeCollectionReference(_path.substring(0, _path.lastIndexOf('/')));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this._path);
  final String _path;

  @override
  DocumentReference<Map<String, dynamic>>? get parent {
    final idx = _path.lastIndexOf('/');
    if (idx < 0) return null; // root collection — never hit by this schema.
    return _FakeDocumentReference(_path.substring(0, idx));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  /// [path] defaults to a plausible full task doc path so every EXISTING
  /// call site below (none of which cares about `id`/`childId`) keeps
  /// working unmodified — only the new id/childId-specific test passes an
  /// explicit path.
  _FakeQueryDocumentSnapshot(
    this._data, {
    String path = 'families/parent-1/children/child-1/tasks/task-1',
  }) : reference = _FakeDocumentReference(path);

  final Map<String, dynamic> _data;

  @override
  final DocumentReference<Map<String, dynamic>> reference;

  @override
  String get id => reference.id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('rewardFor', () {
    test('test_rewardFor_returns_the_exact_authoritative_table_for_all_6_known_categories',
        () {
      expect(rewardFor('study'), (xu: 25, energy: 20));
      expect(rewardFor('arts'), (xu: 25, energy: 20));
      expect(rewardFor('chores'), (xu: 15, energy: 25));
      expect(rewardFor('sport'), (xu: 15, energy: 25));
      expect(rewardFor('helping'), (xu: 10, energy: 30));
      expect(rewardFor('custom'), (xu: 15, energy: 25));
    });

    test('test_rewardFor_falls_back_to_custom_tier_for_an_unknown_categoryId',
        () {
      expect(rewardFor('bogus_category'), (xu: 15, energy: 25));
    });

    test(
        'test_rewardFor_table_matches_design_registry_entities_yaml_exactly_drift_guard',
        () {
      // Loaded relative to the `src/` working directory this test suite
      // always runs from (see file header) — matches this project's
      // established source-inspection test convention.
      final yamlSource =
          File('../design/registry/entities.yaml').readAsStringSync();
      final doc = loadYaml(yamlSource) as YamlMap;
      final constants = doc['constants'] as YamlList;

      int registryValue(String name) {
        for (final entity in constants) {
          final map = entity as YamlMap;
          if (map['name'] == name) {
            return (map['value'] as num).toInt();
          }
        }
        throw StateError('Registry entry not found: $name');
      }

      // study/arts/chores/sport/helping all have explicit registry entries.
      expect(rewardFor('study').xu, registryValue('task_xu_reward_study'));
      expect(
          rewardFor('study').energy, registryValue('task_energy_reward_study'));
      expect(rewardFor('arts').xu, registryValue('task_xu_reward_arts'));
      expect(
          rewardFor('arts').energy, registryValue('task_energy_reward_arts'));
      expect(rewardFor('chores').xu, registryValue('task_xu_reward_chores'));
      expect(rewardFor('chores').energy,
          registryValue('task_energy_reward_chores'));
      expect(rewardFor('sport').xu, registryValue('task_xu_reward_sport'));
      expect(
          rewardFor('sport').energy, registryValue('task_energy_reward_sport'));
      expect(rewardFor('helping').xu, registryValue('task_xu_reward_helping'));
      expect(rewardFor('helping').energy,
          registryValue('task_energy_reward_helping'));

      // 'custom' has NO registry entry (a real gap, flagged separately) —
      // the GDD's own Tuning Knobs table states custom's reward is
      // "same as chores/sport" by design, so validate against THAT
      // registry-backed value instead of a nonexistent task_*_custom key.
      expect(rewardFor('custom').xu, registryValue('task_xu_reward_chores'));
      expect(rewardFor('custom').energy,
          registryValue('task_energy_reward_chores'));
    });
  });

  group('TaskModel', () {
    test('test_TaskModel_has_no_cancelled_status_value_anywhere_in_its_schema',
        () {
      // Static/source check: the model's own CODE (not its doc comments,
      // which correctly document the absence in prose) must never
      // represent 'cancelled' as an actual value — e.g. as an enum case or
      // a string literal comparison. Doc-comment lines are excluded, same
      // pattern already established for the analogous `.index` false
      // positive in mochi_component_triggered_state_test.dart.
      final codeLines = File('lib/core/models/task_model.dart')
          .readAsLinesSync()
          .where((line) => !line.trim().startsWith('//'));
      expect(codeLines.any((line) => line.contains('cancelled')), isFalse);
    });

    test('test_fromFirestore_parses_a_complete_pending_task_correctly', () {
      final now = DateTime(2026, 7, 16, 10);
      final doc = _FakeQueryDocumentSnapshot({
        'title': 'Quét nhà',
        'flavorText': 'Dọn năng lượng cho Mochi',
        'categoryId': 'chores',
        'xuReward': 15,
        'energyReward': 25,
        'status': 'pending',
        'submittedAt': Timestamp.fromDate(now),
        'approvedAt': null,
        'rejectedAt': null,
      });

      final task = TaskModel.fromFirestore(doc);

      expect(task.title, 'Quét nhà');
      expect(task.flavorText, 'Dọn năng lượng cho Mochi');
      expect(task.categoryId, 'chores');
      expect(task.xuReward, 15);
      expect(task.energyReward, 25);
      expect(task.status, 'pending');
      expect(task.submittedAt, now);
      expect(task.approvedAt, isNull);
      expect(task.rejectedAt, isNull);
    });

    test(
        'test_fromFirestore_handles_xuReward_energyReward_stored_as_doubles',
        () {
      final now = DateTime(2026, 7, 16, 10);
      final doc = _FakeQueryDocumentSnapshot({
        'title': 'Quét nhà',
        'flavorText': 'desc',
        'categoryId': 'chores',
        'xuReward': 15.0,
        'energyReward': 25.0,
        'status': 'pending',
        'submittedAt': Timestamp.fromDate(now),
      });

      final task = TaskModel.fromFirestore(doc);

      expect(task.xuReward, 15);
      expect(task.xuReward, isA<int>());
      expect(task.energyReward, 25);
      expect(task.energyReward, isA<int>());
    });

    test('test_fromFirestore_parses_approvedAt_when_present', () {
      final submitted = DateTime(2026, 7, 16, 10);
      final approved = DateTime(2026, 7, 16, 18);
      final doc = _FakeQueryDocumentSnapshot({
        'title': 'Quét nhà',
        'flavorText': 'desc',
        'categoryId': 'chores',
        'xuReward': 15,
        'energyReward': 25,
        'status': 'approved',
        'submittedAt': Timestamp.fromDate(submitted),
        'approvedAt': Timestamp.fromDate(approved),
        'rejectedAt': null,
      });

      final task = TaskModel.fromFirestore(doc);

      expect(task.status, 'approved');
      expect(task.approvedAt, approved);
      expect(task.rejectedAt, isNull);
    });

    test(
        'test_fromFirestore_derives_id_and_childId_from_the_document_reference_path',
        () {
      // Parent Dashboard UI Story 001's blocker fix: `id` is the task doc's
      // own id; `childId` is NOT a document field (tasks live at
      // families/{parentId}/children/{childId}/tasks/{taskId} — childId only
      // ever appears in the PATH) and must be derived from
      // doc.reference.parent.parent!.id instead.
      final now = DateTime(2026, 7, 22, 9);
      final doc = _FakeQueryDocumentSnapshot(
        {
          'title': 'Quét nhà',
          'flavorText': 'desc',
          'categoryId': 'chores',
          'xuReward': 15,
          'energyReward': 25,
          'status': 'pending',
          'submittedAt': Timestamp.fromDate(now),
        },
        path: 'families/parent-9/children/child-42/tasks/task-abc',
      );

      final task = TaskModel.fromFirestore(doc);

      expect(task.id, 'task-abc');
      expect(task.childId, 'child-42');
    });
  });
}
