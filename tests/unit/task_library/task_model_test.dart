// Run with:
//   cd src && flutter test ../tests/unit/task_library/task_model_test.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/models/task_model.dart';
import 'package:pet_quest/core/reward_table.dart';
import 'package:yaml/yaml.dart';

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._data);
  final Map<String, dynamic> _data;

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
  });
}
