// Run with:
//   cd src && flutter test ../tests/unit/pet-room-screen-ui/hit_area_formula_test.dart
//
// Story 001 (Tap Hit-Area Padding — Formula 2), Pet Room Screen UI epic.
// ADR-0017 Decision → TR-petroom-003. Two halves:
// (1) a pure-Dart suite against `computeHitArea` — no Flame, no mounting,
//     fully deterministic — the actual Formula 2 math (AC-F2-1..4).
// (2) a `flame_test`-backed suite against the real `MochiComponent`, proving
//     `size` is wired to the padded `hitBoxSize` output and that `render()`
//     paints the sprite at its true unscaled size, centered — not stretched
//     to fill the padded box (AC-F2-5, ADR-0017 Alternative 3's regression
//     guard).
//
// This is the concrete output Pet Interaction epic's Story 005 (Hit-Area
// Minimum Enforcement, `production/epics/pet-interaction/story-005-hit-area-minimum-enforcement.md`)
// was blocked on — `computeHitArea` and `MochiComponent.size` are now real,
// importable, unit-tested code, not just a formula on paper.

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/gameplay/hit_area_formula.dart';
import 'package:pet_quest/gameplay/mochi_component.dart';

void main() {
  group('computeHitArea (pure Formula 2 logic)', () {
    test('test_computeHitArea_spriteSize_56_pads_to_80', () {
      final result = computeHitArea(56.0);

      expect(result.padding, closeTo(12.0, 0.01));
      expect(result.hitBoxSize, closeTo(80.0, 0.01));
    });

    test('test_computeHitArea_spriteSize_0_pads_to_80', () {
      final result = computeHitArea(0.0);

      expect(result.padding, closeTo(40.0, 0.01));
      expect(result.hitBoxSize, closeTo(80.0, 0.01));
    });

    test('test_computeHitArea_spriteSize_96_no_padding_no_shrink', () {
      final result = computeHitArea(96.0);

      expect(result.padding, closeTo(0.0, 0.01));
      expect(result.hitBoxSize, closeTo(96.0, 0.01));
    });

    test(
      'test_computeHitArea_spriteSize_exactly_hitBoxMin_no_padding',
      () {
        final result = computeHitArea(80.0);

        expect(result.padding, closeTo(0.0, 0.01));
        expect(result.hitBoxSize, closeTo(80.0, 0.01));
      },
    );

    test(
      'test_computeHitArea_hitBoxSize_always_gte_80_across_sampled_range',
      () {
        const samples = [0.0, 1.0, 10.0, 40.0, 79.9, 80.0, 80.1, 100.0, 250.0, 500.0];

        for (final spriteSize in samples) {
          final result = computeHitArea(spriteSize);
          expect(
            result.hitBoxSize,
            greaterThanOrEqualTo(80.0),
            reason: 'spriteSize=$spriteSize should still satisfy the floor',
          );
        }
      },
    );

    test(
      'test_computeHitArea_worked_examples_baby_young_grown_evolution_stages',
      () {
        // GDD Formula 2 worked examples / Art Bible Section 5.2 pinned sizes.
        expect(computeHitArea(72.0).hitBoxSize, closeTo(80.0, 0.01)); // Baby
        expect(computeHitArea(112.0).hitBoxSize, closeTo(112.0, 0.01)); // Young
        expect(computeHitArea(152.0).hitBoxSize, closeTo(152.0, 0.01)); // Grown
      },
    );

    test('test_computeHitArea_custom_hitBoxMin_override', () {
      final result = computeHitArea(10.0, hitBoxMin: 40.0);

      expect(result.padding, closeTo(15.0, 0.01));
      expect(result.hitBoxSize, closeTo(40.0, 0.01));
    });
  });

  group('MochiComponent size/render wiring (ADR-0017 component contract)', () {
    testWithFlameGame(
      'test_MochiComponent_defaults_to_Baby_spriteSize_with_padded_80dp_size',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        expect(mochi.currentSpriteSize, closeTo(72.0, 0.01));
        expect(mochi.size, Vector2.all(80.0));
      },
    );

    testWithFlameGame(
      'test_MochiComponent_size_is_padded_hitBoxSize_for_each_evolution_stage',
      (game) async {
        final mochi = MochiComponent();
        await game.ensureAdd(mochi);

        mochi.currentSpriteSize = 72.0; // Baby
        expect(mochi.size, Vector2.all(80.0));

        mochi.currentSpriteSize = 112.0; // Young
        expect(mochi.size, Vector2.all(112.0));

        mochi.currentSpriteSize = 152.0; // Grown
        expect(mochi.size, Vector2.all(152.0));
      },
    );

    testWithFlameGame(
      'test_MochiComponent_size_never_below_80_regardless_of_constructor_spriteSize',
      (game) async {
        final mochi = MochiComponent(currentSpriteSize: 10.0);
        await game.ensureAdd(mochi);

        expect(mochi.size.x, greaterThanOrEqualTo(80.0));
        expect(mochi.size.y, greaterThanOrEqualTo(80.0));
      },
    );

    testWithFlameGame(
      'test_MochiComponent_render_paints_sprite_at_true_unscaled_size_centered_not_stretched',
      (game) async {
        // Regression coverage for ADR-0017 Alternative 3's rejection (GDD
        // Core Rule 4): Baby Mochi (spriteSize=72) must render at 72dp,
        // centered, NOT stretched to fill the padded 80dp `size`. A spy
        // `Sprite` subclass captures the exact `position`/`size` args
        // `render()` passes down, so this test fails if `render()` is ever
        // changed to call `super.render()` (which paints `sprite` stretched
        // to fill `size` — the exact bug this guards against) or otherwise
        // stops applying the padding offset.
        final mochi = MochiComponent(); // Baby default, spriteSize=72
        await game.ensureAdd(mochi);

        expect(mochi.size, Vector2.all(80.0)); // padded hit box
        expect(mochi.currentSpriteSize, closeTo(72.0, 0.01)); // true sprite size

        final spy = _SpySprite(mochi.sprite!.image);
        mochi.sprite = spy;

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        mochi.render(canvas);

        expect(spy.lastRenderCallCount, 1);
        // padding = (80 - 72) / 2 = 4 — the exact offset a correct
        // implementation must pass as `position` so the 72dp sprite is
        // centered inside the 80dp padded box.
        expect(spy.lastRenderPosition, Vector2.all(4.0));
        // The sprite must be painted at its TRUE size (72), never at the
        // padded `size` (80) — that would reproduce the stretch bug.
        expect(spy.lastRenderSize, Vector2.all(72.0));

        // render() must not mutate `size` as a side effect of painting.
        expect(mochi.size, Vector2.all(80.0));
      },
    );
  });
}

/// Captures the exact args [MochiComponent.render] passes to
/// `Sprite.render()`, so the test above can assert on them directly instead
/// of re-deriving the expected offset from already-tested getters (which
/// would not actually exercise `render()`'s own painting logic).
class _SpySprite extends Sprite {
  _SpySprite(super.image);

  int lastRenderCallCount = 0;
  Vector2? lastRenderPosition;
  Vector2? lastRenderSize;

  @override
  void render(
    Canvas canvas, {
    Vector2? position,
    Vector2? size,
    Anchor anchor = Anchor.topLeft,
    Paint? overridePaint,
    double? bleed,
  }) {
    lastRenderCallCount++;
    lastRenderPosition = position?.clone();
    lastRenderSize = size?.clone();
    // Deliberately does not call super.render() — this spy only needs to
    // record call args, not actually paint pixels for this test.
  }
}
