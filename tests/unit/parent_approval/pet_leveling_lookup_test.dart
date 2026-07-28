// Run with:
//   cd src && flutter test ../tests/unit/parent_approval/pet_leveling_lookup_test.dart
//
// Story: parent-approval/story-001-approve-transaction — code review
// suggestion (qa-tester, 2026-07-18): the pure `nextLevelThreshold()`/
// `xuBonus()` functions were only exercised indirectly through
// `approve_task_test.dart`'s full transaction integration tests.
// coding-standards.md's Testing Standards table marks Logic-type formula
// tests as a BLOCKING requirement — this file closes that gap with direct,
// injection-free unit tests.
//
// Values verified against design/registry/entities.yaml:
// pet_level_threshold_l2..l5 = 150/400/900/1800, pet_levelup_xu_bonus =
// level*25+25 (L2=75, L3=100, L4=125, L5=150), gacha_free_chest_milestone=5.

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/parent_approval_repository.dart';

void main() {
  group('nextLevelThreshold', () {
    test('test_nextLevelThreshold_level1_returns150', () {
      expect(nextLevelThreshold(1), 150);
    });
    test('test_nextLevelThreshold_level2_returns400', () {
      expect(nextLevelThreshold(2), 400);
    });
    test('test_nextLevelThreshold_level3_returns900', () {
      expect(nextLevelThreshold(3), 900);
    });
    test('test_nextLevelThreshold_level4_returns1800', () {
      expect(nextLevelThreshold(4), 1800);
    });
    test('test_nextLevelThreshold_level5_throwsArgumentError', () {
      // Max level has no "next" threshold — every real call site guards
      // `petLevel < 5` before calling this function.
      expect(() => nextLevelThreshold(5), throwsArgumentError);
    });
    test('test_nextLevelThreshold_level0_throwsArgumentError', () {
      // Corrupted/invalid input below the valid range — the caller
      // (ParentApprovalRepository.approveTask) is responsible for clamping
      // before this point (see the repository's own petLevel<1 guard, added
      // in the same code review pass this test was added in).
      expect(() => nextLevelThreshold(0), throwsArgumentError);
    });
    test('test_nextLevelThreshold_negativeLevel_throwsArgumentError', () {
      expect(() => nextLevelThreshold(-1), throwsArgumentError);
    });
  });

  group('xuBonus', () {
    test('test_xuBonus_newLevel2_returns75', () {
      expect(xuBonus(2), 75);
    });
    test('test_xuBonus_newLevel3_returns100', () {
      expect(xuBonus(3), 100);
    });
    test('test_xuBonus_newLevel4_returns125', () {
      expect(xuBonus(4), 125);
    });
    test('test_xuBonus_newLevel5_returns150', () {
      // The one level-up boundary whose xuBalance math wasn't directly
      // asserted anywhere in approve_task_test.dart (code review finding).
      expect(xuBonus(5), 150);
    });
  });

  test('test_gachaFreeChestMilestone_equals5', () {
    expect(gachaFreeChestMilestone, 5);
  });
}
