// Run with:
//   cd src && flutter test ../tests/unit/pet-interaction/hit_area_contract_test.dart
//
// Story 005 (Hit-Area Minimum Enforcement), Pet Interaction epic.
// ADR-0016 §Decision 3 / GDD Core Rule 7 / TR-petinteraction-004, AC-12.
//
// This file verifies Pet Interaction's OWN contract — that whatever Pet Room
// Screen UI Story 001 (ADR-0017 Decision → TR-petroom-003, Formula 2)
// produces actually satisfies the ≥80×80dp tap/drag hit-area floor this
// system requires. It is a cross-epic CONTRACT check, not a re-test of
// Formula 2's internals:
//   - `tests/unit/pet-room-screen-ui/hit_area_formula_test.dart` (Pet Room
//     Screen UI's own story) already exhaustively unit-tests
//     `computeHitArea`'s pure math (boundary values, the `max(0, ...)` clamp,
//     a sampled property-based sweep, etc.) — none of that is repeated here.
//   - This file instead asserts, for every real evolution-stage `spriteSize`
//     Pet Leveling & Evolution's GDD defines (`design/gdd/pet-leveling-
//     evolution.md`: 3 evolution stages, Baby/Young/Grown — pinned dp values
//     72/112/152 per Art Bible Section 5.2, the same worked examples Pet
//     Room Screen UI Story 001's own AC-F2-4 verifies), that (a) the formula
//     output clears the 80dp floor, AND (b) the REAL `MochiComponent.size`
//     property — constructed via the actual production constructor/setter,
//     not re-derived — equals that formula output. (b) is the integration
//     half: it is the piece that would catch a future regression where
//     `MochiComponent` stops wiring `size` to `computeHitArea(...)`
//     correctly even though the formula itself still tests green in
//     isolation.
//
// Also covers the Implementation Notes' follow-up regression check (now
// unblocked since Pet Room Screen UI #18 exists): no child component inside
// `MochiComponent`'s subtree may itself mix in `TapCallbacks`/`DragCallbacks`
// (ADR-0016 §Decision 3) — such a child would silently shadow pointer events
// for whatever region it occupies.

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/hit_area_formula.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';

void main() {
  group('AC-12: hit area >= 80x80dp at every evolution stage (Formula 2 output)', () {
    // Pet Leveling & Evolution GDD (`design/gdd/pet-leveling-evolution.md`):
    // 3 evolution stages — Baby (L1), Young (L2-L3), Grown (L4-L5). Concrete
    // per-stage dp values pinned by Art Bible Section 5.2, the same set Pet
    // Room Screen UI Story 001's AC-F2-4 worked examples verify.
    const evolutionStageSpriteSizes = <String, double>{
      'Baby': 72.0,
      'Young': 112.0,
      'Grown': 152.0,
    };

    for (final entry in evolutionStageSpriteSizes.entries) {
      final stageName = entry.key;
      final spriteSize = entry.value;

      test(
        'test_computeHitArea_${stageName}_stage_hitBoxSize_meets_80dp_floor',
        () {
          final hitArea = computeHitArea(spriteSize);

          // "in both width and height" — hitBoxSize is a single dp value
          // because Formula 2 treats the hit box as square (GDD Formula 2's
          // own assumption), so it is asserted against both axes explicitly
          // rather than assuming squareness silently holds.
          final effectiveSize = Vector2.all(hitArea.hitBoxSize);
          expect(
            effectiveSize.x,
            greaterThanOrEqualTo(kTapHitboxMin),
            reason:
                '$stageName spriteSize=$spriteSize: hitBoxSize.x must satisfy '
                'GDD Core Rule 7 / TR-petinteraction-004 (>=80dp)',
          );
          expect(
            effectiveSize.y,
            greaterThanOrEqualTo(kTapHitboxMin),
            reason:
                '$stageName spriteSize=$spriteSize: hitBoxSize.y must satisfy '
                'GDD Core Rule 7 / TR-petinteraction-004 (>=80dp)',
          );
        },
      );

      testWithFlameGame(
        'test_MochiComponent_size_${stageName}_stage_matches_formula_and_meets_floor',
        (game) async {
          // Integration half: construct the REAL MochiComponent at this
          // evolution stage's spriteSize and read its actual `.size`
          // property — this is what Flame's default AABB hit test
          // (`PositionComponent.containsLocalPoint`, ADR-0016 §Decision 3)
          // registers pointer events against, not a value re-derived from
          // the formula in isolation.
          final mochi = MochiComponent(currentSpriteSize: spriteSize);
          await game.ensureAdd(mochi);

          // (a) the contract: whatever the component actually exposes as
          // its hit-test surface clears the floor, on both axes.
          expect(
            mochi.size.x,
            greaterThanOrEqualTo(kTapHitboxMin),
            reason: '$stageName ($spriteSize dp): MochiComponent.size.x must be >=80dp',
          );
          expect(
            mochi.size.y,
            greaterThanOrEqualTo(kTapHitboxMin),
            reason: '$stageName ($spriteSize dp): MochiComponent.size.y must be >=80dp',
          );

          // (b) the tie: the component's real size is not just >=80 by
          // coincidence — it equals exactly what Formula 2 computes for
          // this spriteSize, proving the two epics' code is actually wired
          // together, not just independently passing.
          final expected = computeHitArea(spriteSize).hitBoxSize;
          expect(
            mochi.size,
            Vector2.all(expected),
            reason:
                '$stageName ($spriteSize dp): MochiComponent.size must equal '
                'computeHitArea($spriteSize).hitBoxSize exactly',
          );

          // ADR-0016 §Decision 3 / this story's Control Manifest rule: if
          // `scale` is ever non-1.0, the EFFECTIVE hit area is `size *
          // scale`, not `size` alone. Evolution stages are asset/size swaps
          // for MVP (no scale transform applied by construction), but this
          // assertion is written against the effective area rather than
          // `size` alone so it stays correct if that assumption ever
          // changes without silently passing on stale reasoning.
          final effectiveHitArea = mochi.size.clone()..multiply(mochi.scale);
          expect(effectiveHitArea.x, greaterThanOrEqualTo(kTapHitboxMin));
          expect(effectiveHitArea.y, greaterThanOrEqualTo(kTapHitboxMin));
        },
      );
    }

    testWithFlameGame(
      'test_MochiComponent_size_tracks_formula_across_evolution_stage_transitions',
      (game) async {
        // Edge case called out by this story's own QA Test Cases: "a
        // formula that only clamps the minimum case could still
        // under-satisfy an intermediate stage" — exercised here as a single
        // component transitioning through all 3 stages in level-up order
        // (the real-world sequence, via the same `currentSpriteSize` setter
        // production code uses on a `petLeveledUp` evolution-stage
        // transition), not just 3 independently-constructed instances.
        final mochi = MochiComponent(); // starts at Baby (72dp) by default
        await game.ensureAdd(mochi);

        for (final spriteSize in [72.0, 112.0, 152.0]) {
          mochi.currentSpriteSize = spriteSize;

          expect(mochi.size.x, greaterThanOrEqualTo(kTapHitboxMin));
          expect(mochi.size.y, greaterThanOrEqualTo(kTapHitboxMin));
          expect(mochi.size, Vector2.all(computeHitArea(spriteSize).hitBoxSize));
        }
      },
    );
  });

  group('ADR-0016 §Decision 3 regression guard: no child shadows the hit area', () {
    testWithFlameGame(
      'test_MochiComponent_no_child_component_registers_own_tap_or_drag_callbacks_when_freshly_mounted',
      (game) async {
        // Unblocked now that Pet Room Screen UI #18 exists (this story's own
        // Implementation Notes flagged this as the follow-up once
        // unblocked). MochiComponent itself is expected to mix in
        // DragCallbacks (ADR-0016 §Decision 1) — only its CHILDREN must not.
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        _assertSubtreeHasNoOwnGestureCallbacks(mochi);
      },
    );

    for (final triggeredState in TriggeredState.values) {
      testWithFlameGame(
        'test_MochiComponent_no_child_component_registers_own_tap_or_drag_callbacks_during_${triggeredState.name}',
        (game) async {
          // Drive each triggered-state effect path individually (fresh
          // component per state, since `_play` clears the previous state's
          // effect/timer children before attaching the next one — checking
          // sequentially on one instance would only ever see the LAST
          // state's subtree) so every child-component shape a triggered
          // state can attach (ScaleEffect/RotateEffect/TimerComponent-based
          // triggers) is actually present in the subtree at assertion time,
          // not just a freshly-mounted empty component.
          final mochi = MochiComponent();
          await game.ensureAdd(mochi);

          mochi.onTrigger(triggeredState);
          _assertSubtreeHasNoOwnGestureCallbacks(mochi);
        },
      );
    }
  });
}

/// Walks [root]'s children (not `root` itself — the parent
/// `MochiComponent` is expected/required to mix in `DragCallbacks`) and
/// fails if any descendant mixes in `TapCallbacks` or `DragCallbacks`,
/// which would shadow pointer events intended for the parent's hit area
/// (ADR-0016 §Decision 3).
void _assertSubtreeHasNoOwnGestureCallbacks(Component root) {
  for (final child in root.children) {
    expect(
      child is TapCallbacks || child is DragCallbacks,
      isFalse,
      reason:
          'Child component ${child.runtimeType} must not register its own '
          'TapCallbacks/DragCallbacks (ADR-0016 §Decision 3) — it would '
          'shadow pointer events from reaching the parent MochiComponent.',
    );
    _assertSubtreeHasNoOwnGestureCallbacks(child);
  }
}
