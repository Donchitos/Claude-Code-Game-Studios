# Story 001: Tap Hit-Area Padding (Formula 2)

> **Epic**: Pet Room Screen UI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: 2-3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-room-screen-ui.md`
**Requirement**: `TR-petroom-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Pet Room Screen Rendering & Interaction Contract (Decision → TR-petroom-003).
**ADR Decision Summary**: ADR-0017 ratifies the GDD's Formula 2 unchanged (`padding = max(0, (hitBoxMin - spriteSize) / 2)`, `hitBoxSize = spriteSize + 2 × padding`) and supplies its concrete implementation: a pure `computeHitArea(spriteSize)` function in `src/lib/gameplay/hit_area_formula.dart` (no Flutter/Flame import), plus the `MochiComponent` wiring that sets `size` to the padded `hitBoxSize` while overriding `render()` to paint the sprite at its true unscaled size, centered — so the hit-test region grows without the visible art scaling past its pinned dimensions. This is the concrete output ADR-0016 (Pet Interaction) already declared Story 005 (Hit-Area Minimum Enforcement) is blocked on.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM
**Engine Notes**: `MochiComponent.size` doubles as the tap/drag hit-test surface (`PositionComponent.containsLocalPoint`, flame-specialist-confirmed plain AABB check against `size`) — this story is the first to make `size` reflect Formula 2's padded output rather than a placeholder. No `TapCallbacks`/`ShapeHitbox`/`RectangleHitbox` — `MochiComponent` remains `DragCallbacks`-only per ADR-0016, and this story does not touch gesture handling. `render()` must be overridden (not left to the inherited `SpriteComponent`/default paint path) or the sprite will visually stretch to fill the padded box — ADR-0017 Alternative 3 explicitly rejects that.

**Control Manifest Rules (this layer)**:
- Required: `drawCalls_sceneFlame` accounting is unaffected — the padded hit box is hit-test-only, not an additional renderable (source: ADR-0001, Presentation Layer Rules).
- Required: gameplay/formula values must be data-driven, not hardcoded inline at each call site — `kTapHitboxMin` is the single source for the 80dp constant (source: coding-standards.md; ADR-0017 Ordering Note).
- Forbidden: scaling the rendered sprite to fill the padded `size` (registry pattern `scaling_pinned_sprite_to_fill_padded_hitbox`) — source: ADR-0017 Alternative 3, GDD Core Rule 4.
- Forbidden: any child component inside `MochiComponent`'s bounds registering its own `TapCallbacks`/`DragCallbacks` (source: ADR-0016 §Decision 3 — this story does not add any such child, but must not regress it).

---

## Acceptance Criteria

*From GDD `design/gdd/pet-room-screen-ui.md`, scoped to this story:*

- [x] **AC-F2-1**: GIVEN `spriteSize` = 56dp (< `hitBoxMin`), THEN `padding` = 12.0dp and `hitBoxSize` = 80.0dp (±0.01dp tolerance).
- [x] **AC-F2-2**: GIVEN `spriteSize` = 96dp (> `hitBoxMin`), THEN `padding` = 0.0dp and `hitBoxSize` = 96.0dp (±0.01dp tolerance — verifies the `max(0, ...)` clamp).
- [x] **AC-F2-3**: GIVEN any `spriteSize` ≥ 0, THEN `hitBoxSize` ≥ 80dp always holds (property-based check).
- [x] **AC-F2-4** (worked examples, GDD Formula 2): `computeHitArea(72).hitBoxSize == 80.0` (Baby), `computeHitArea(112).hitBoxSize == 112.0` (Young), `computeHitArea(152).hitBoxSize == 152.0` (Grown).
- [x] **AC-F2-5** (Edge Case 1 / render-override regression, GDD Core Rule 4): GIVEN Baby Mochi (`spriteSize = 72`), THEN `MochiComponent.size == Vector2.all(80)` (the padded hit box) while the sprite is painted at its true `72dp`, centered — not stretched to `80dp`. Verified via a spy `Sprite` capturing `render()`'s actual `position`/`size` args (not re-derived from already-tested getters) — this test was strengthened during code review after qa-tester found the original version didn't actually exercise `render()`'s internals (see Dependencies/code-review note below).

---

## Implementation Notes

*Derived from ADR-0017 Decision → TR-petroom-003:*

- New file `src/lib/gameplay/hit_area_formula.dart` — pure Dart, no Flutter/Flame import, mirrors `src/lib/core/compute_energy.dart`'s pattern of an engine-independent, fully deterministic formula function:
  ```dart
  const double kTapHitboxMin = 80.0; // dp — requirement owned by ADR-0016 / Pet Interaction #14

  class HitArea {
    const HitArea({required this.padding, required this.hitBoxSize});
    final double padding;
    final double hitBoxSize;
  }

  HitArea computeHitArea(double spriteSize, {double hitBoxMin = kTapHitboxMin}) {
    final padding = math.max(0.0, (hitBoxMin - spriteSize) / 2);
    return HitArea(padding: padding, hitBoxSize: spriteSize + 2 * padding);
  }
  ```
- `MochiComponent` wiring (the same file, `src/lib/gameplay/mochi_component.dart`):
  - `size` must be set from `computeHitArea(currentSpriteSize).hitBoxSize` (`Vector2.all(...)`), recomputed only on evolution-stage transition — not per-frame.
  - `render(Canvas canvas)` must be overridden to paint the sprite at its true `currentSpriteSize`, centered inside the padded `size` — the offset is exactly `padding` (Formula 2's own output), not a value recomputed separately:
    ```dart
    @override
    void render(Canvas canvas) {
      final offset = (size - Vector2.all(currentSpriteSize)) / 2; // == Vector2.all(padding)
      sprite?.render(canvas, position: offset, size: Vector2.all(currentSpriteSize));
    }
    ```
  - Add a required doc comment on `MochiComponent.size` stating it is the padded tap hit-test region (ADR-0016), not the visual sprite size — regression guard called out in ADR-0017 Consequences → Negative.
  - `MochiComponent` currently extends `PositionComponent` (per Pet Interaction Story 002's own doc comment, which explicitly deferred the `SpriteComponent` migration to "Story 001 or Pet Room Screen UI #18"). This story is the one that performs that migration: `MochiComponent extends SpriteComponent with GameEventSubscriber, DragCallbacks` (ADR-0016 Key Interfaces / ADR-0017 Key Interfaces) — additive change only, do not alter the existing mood/triggered-state machinery (`onGameEvent`, `_play`, `_queueHighest`, etc.) or the Pet Interaction Story 002 guard logic (`onDragStart`/`onDragEnd`/`onDragCancel`, sleeping-peek, interaction guard). `PositionComponent`'s public surface is a subset of `SpriteComponent`'s, so this migration should not require touching unrelated methods.
  - A `currentSpriteSize` field/getter is needed to drive both `size` and `render()` — for this story's scope (no real sprite asset pipeline exists yet), a `double` field defaulting to a sensible placeholder is sufficient; do not block this story on Art Bible asset loading, which is out of scope (see Out of Scope).
- **Concurrency note**: `src/lib/gameplay/mochi_component.dart` may be under concurrent edit by Pet Interaction's own Story 001 implementation in this same window. Re-read the file immediately before editing and keep the change additive/targeted (only the base-class line, `size` computation, and `render()` override) — do not restructure unrelated sections.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002 (Draw-Call Budget Contract, Formula 1): counting/verifying `drawCalls_sceneFlame` — unrelated formula, no shared code.
- Story 003 (Flame Canvas Composition & Modal Mutual Exclusivity): the `RoomBackgroundComponent`, `World` tree, and `priority` ordering that `MochiComponent` is eventually mounted into — this story only changes `MochiComponent` itself, not where/how it's mounted.
- Real Mochi sprite asset loading/evolution-stage swap logic (Pet Leveling #16's own future story) — this story treats `currentSpriteSize` as a settable value for the padding/render math, not the asset pipeline that produces it.
- Pet Interaction epic's Story 005 (Hit-Area Minimum Enforcement) — that story is a separate epic's own verification of this story's output; it imports `computeHitArea`/reads `MochiComponent.size`, it does not implement any of this story's code.

---

## QA Test Cases

*Concrete test cases (lean review mode — written directly into the story, no qa-lead gate spawned per `production/review-mode.txt`).*

- **AC-F2-1**: Given `spriteSize = 56.0` — When: `computeHitArea(56.0)` is called — Then: assert `padding == 12.0` and `hitBoxSize == 80.0` within `±0.01`. Edge cases: `spriteSize = 0`.
- **AC-F2-2**: Given `spriteSize = 96.0` — When: `computeHitArea(96.0)` is called — Then: assert `padding == 0.0` and `hitBoxSize == 96.0` within `±0.01`. Edge cases: `spriteSize` exactly equal to `hitBoxMin` (80.0) → `padding == 0.0`, `hitBoxSize == 80.0`.
- **AC-F2-3**: Given a sampled range of `spriteSize` values (e.g. `[0, 1, 10, 40, 79.9, 80, 80.1, 100, 250, 500]`) — When: `computeHitArea` is called for each — Then: assert `hitBoxSize >= 80.0` holds for every sample (property-based check, no tolerance needed since this is a `>=` assertion).
- **AC-F2-4**: Given the three pinned evolution-stage sprite sizes (72/112/152dp) — When: `computeHitArea` is called for each — Then: assert `hitBoxSize` equals `80.0`/`112.0`/`152.0` respectively (exact worked examples from the GDD).
- **AC-F2-5**: Given a `MochiComponent` with `currentSpriteSize = 72` — When: constructed/mounted (`testWithFlameGame`, matching the existing `flame_test` harness pattern in `tests/integration/pet_state_machine/`) — Then: assert `component.size == Vector2.all(80)` AND, via a `render()` call against a recording `Canvas`/mock `Sprite`, assert the sprite is rendered with `size == Vector2.all(72)` at `position == Vector2.all(4)` (the padding offset), not stretched to `80`.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pet-room-screen-ui/hit_area_formula_test.dart` — must exist and pass

**Status**: [x] Created — 11 tests, all passing (`cd src && flutter test ../tests/unit/pet-room-screen-ui/hit_area_formula_test.dart`).

---

## Implementation Record

**Files created**:
- `src/lib/gameplay/hit_area_formula.dart` — pure `computeHitArea(spriteSize, {hitBoxMin})`, `HitArea`, `kTapHitboxMin`.
- `tests/unit/pet-room-screen-ui/hit_area_formula_test.dart` — 11 tests (7 pure-formula, 4 `MochiComponent` wiring).

**Files modified**:
- `src/lib/gameplay/mochi_component.dart` — migrated `MochiComponent` from `extends PositionComponent` to `extends SpriteComponent with GameEventSubscriber, DragCallbacks` (per ADR-0016 Key Interfaces); wired `size` to `computeHitArea(currentSpriteSize).hitBoxSize` (constructor + `@visibleForTesting` setter); added `onLoad()` to set a transparent 1×1 placeholder `Sprite` (satisfies `SpriteComponent.onMount()`'s `sprite != null` assertion — no real per-stage art asset is wired yet, out of this story's scope); added a `render()` override (not calling `super.render()`, lint suppressed with rationale) painting the sprite at true `currentSpriteSize`, centered inside the padded `size`. All Pet Interaction Story 002 drag/guard logic in the same file left untouched.

**Code review**: `flame-specialist` — **APPROVE** (1 non-blocking nit: placeholder `Image` is never disposed; inconsequential for a 1×1 session-lifetime placeholder, noted for whoever swaps in real per-stage sprites later). `qa-tester` — initially **ADEQUATE WITH GAPS** (1 blocking gap: the original AC-F2-5 test asserted padding arithmetic re-derived from already-tested getters rather than actually exercising `render()`'s paint call, and empirically did not fail when qa-tester reintroduced the exact stretch-bug ADR-0017 Alternative 3 rejects). Fixed by replacing that test with a spy-`Sprite`-based version that captures `render()`'s actual `position`/`size` args; self-verified by temporarily reintroducing the stretch bug (`render()` → `super.render(canvas)`) and confirming the new test fails, then reverting (file diff confirmed identical to pre-experiment state) and confirming green again. Final state: both reviewers' findings resolved.

**Test results**: Full suite — baseline 510 passing / 1 pre-existing skip → final 534 passing / 1 pre-existing skip (net +24: +11 from this story, +13 from a concurrent Pet Interaction Story 001 process's own additions to `gesture_classification_test.dart`/`interaction_state_guards_test.dart`, confirmed via file mtimes to be unrelated to and non-conflicting with this story's changes). `flutter analyze` (project-wide, from `src/`): 0 issues in `mochi_component.dart`/`hit_area_formula.dart`; 13 pre-existing `info`-level issues elsewhere (unrelated `prefer_initializing_formals` in Auth/PIN repositories), unchanged by this story.

---

## Dependencies

- Depends on: None
- Unlocks: Pet Interaction epic's Story 005 (Hit-Area Minimum Enforcement) — cross-epic, supplies the concrete `size` data it verifies against. Story 007 (Context Menu & Wardrobe Bottom Sheet) — context menu anchor positioning reads `MochiComponent.size`/position.
