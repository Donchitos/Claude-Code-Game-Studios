// Run with:
//   cd src && flutter test ../tests/unit/pet-room-screen-ui/draw_call_budget_test.dart
//
// Story 002 (Flame Canvas Draw-Call Budget Contract — Formula 1), Pet Room
// Screen UI epic. ADR-0001 Draw-Call Budget Scope, TR-petroom-002. A pure
// arithmetic contract over fixed constants — not a live render-tree count
// (ADR-0001's own framing) — so this suite proves the formula's math and
// its equip-state independence, nothing else.

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/gameplay/draw_call_budget.dart';

void main() {
  group('computeSceneFlameDrawCalls (Formula 1)', () {
    test('test_computeSceneFlameDrawCalls_defaultConstants_equals5', () {
      expect(computeSceneFlameDrawCalls(), 5);
    });

    test(
        'test_computeSceneFlameDrawCalls_calledRepeatedly_staysAt5_noEquippedItemsInput',
        () {
      // AC-F1-2: the function takes no "equipped items" parameter at all —
      // simulating a "before equip" / "after equip" call site pair proves
      // there is no such input to vary the result by construction.
      final before = computeSceneFlameDrawCalls();
      final after = computeSceneFlameDrawCalls();

      expect(before, 5);
      expect(after, 5);
    });

    test('test_computeSceneFlameDrawCalls_worksOutFromNamedConstants', () {
      expect(
        computeSceneFlameDrawCalls(),
        kDrawCallsBackground + kDrawCallsMochiBase + kEquipmentSlotCount,
      );
    });

    test('test_computeSceneFlameDrawCalls_overridesAreRespected', () {
      // Not part of this story's own AC-F1 scope (Formula 1's real inputs
      // are fixed MVP constants), but proves the formula itself — not just
      // the default constants — sums correctly, matching the sibling
      // hit_area_formula_test.dart's precedent of testing a custom
      // override alongside the default-constant case.
      expect(
        computeSceneFlameDrawCalls(
          drawCallsBackground: 2,
          drawCallsMochiBase: 3,
          slotCount: 4,
        ),
        9,
      );
    });
  });
}
