# Story 002: Flame Canvas Draw-Call Budget Contract (Formula 1)

> **Epic**: Pet Room Screen UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: 1-2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-room-screen-ui.md`
**Requirement**: `TR-petroom-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Draw-Call Budget Scope.
**ADR Decision Summary**: Scopes the ≤200 draw-call budget to the Flame canvas only (post-`SpriteBatch` `SpriteComponent`-level render calls) — Flutter overlay compositing is governed separately (frame build/raster time), not folded into the same count. Ratifies this GDD's Formula 1 (`drawCalls_sceneFlame = drawCalls_background + drawCalls_mochiBase + slotCount = 1 + 1 + 3 = 5`) as-is.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM-HIGH
**Engine Notes**: This is an accounting contract, not a runtime measurement — the formula's inputs (`drawCalls_background = 1`, `drawCalls_mochiBase = 1`, `slotCount = 3`) are fixed constants for MVP scope, not values read off a live render tree. `drawCalls_sceneFlame` does not change whether equipment slots hold a real item or the default/"none" state — each of Pet Equipment #15's 3 slots is always 1 mounted `SpriteComponent`. No physical-device profiling is required by this story (ADR-0001's 3-device pass is a separate, still-outstanding Validation Criteria item, unaffected by this story).

**Control Manifest Rules (this layer)**:
- Required: `drawCalls_sceneFlame(screen) = Σ(Flame render calls, post-SpriteBatch)` is the only quantity checked against ≤200 (source: ADR-0001, Presentation Layer Rules).
- Forbidden: folding Flutter widget/overlay compositing cost into the 200-draw-call count (source: ADR-0001).
- Guardrail: ≤200 draw calls/frame (Flame canvas only); this story's output (5) is 2.5% utilization — no near-budget risk at MVP scope.

---

## Acceptance Criteria

*From GDD `design/gdd/pet-room-screen-ui.md`, scoped to this story:*

- [ ] **AC-F1-1**: GIVEN MVP scope (1 background, 1 Mochi base, 3 equipment slots always mounted), THEN `drawCalls_sceneFlame` = 5 exactly (integer equality — every input is a constant).
- [ ] **AC-F1-2**: GIVEN any item equipped in any slot (including default/"none"), THEN `drawCalls_sceneFlame` remains 5 — equip/unequip does not change the draw-call count.

---

## Implementation Notes

*Derived from ADR-0001 / GDD Formula 1:*

- New file `src/lib/gameplay/draw_call_budget.dart` (or co-located with `hit_area_formula.dart` if a shared "Pet Room formulas" file is preferred at review time — no existing precedent forces either choice; keep it a pure Dart file, no Flutter/Flame import, following `src/lib/core/compute_energy.dart`'s pattern):
  ```dart
  const int kDrawCallsBackground = 1;
  const int kDrawCallsMochiBase = 1;
  const int kEquipmentSlotCount = 3; // Pet Equipment #15's 3 always-mounted slots

  int computeSceneFlameDrawCalls({
    int drawCallsBackground = kDrawCallsBackground,
    int drawCallsMochiBase = kDrawCallsMochiBase,
    int slotCount = kEquipmentSlotCount,
  }) =>
      drawCallsBackground + drawCallsMochiBase + slotCount;
  ```
- This story does NOT need to count real mounted Flame components — the formula is a design-time contract over fixed constants (per the ADR's own framing: "not a value bit read off a live render tree"). Do not add a runtime component-tree walk/counter — that would be scope creep into an unrequested live-profiling feature.
- Equip/unequip independence (AC-F1-2) is proven by the function signature itself — `slotCount` is a constant (3), not a function of which items are equipped, so the test only needs to confirm the formula doesn't accidentally take an "equipped items" list as input that could vary the count.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003 (Flame Canvas Composition): the actual `RoomBackgroundComponent`/`MochiComponent`/equipment-slot component tree these constants describe — this story only verifies the arithmetic contract, not the real mounted tree.
- Physical-device Impeller/frame-time profiling (ADR-0001's outstanding 3-device Validation Criteria pass) — unrelated to this story, still pending regardless.
- Pet Equipment #15's own slot-rendering implementation (no epic yet) — this story only reserves the constant `slotCount = 3` this GDD's Formula 1 depends on.

---

## QA Test Cases

*Concrete test cases (lean review mode — written directly into the story, no qa-lead gate spawned per `production/review-mode.txt`).*

- **AC-F1-1**: Given the default constants (`kDrawCallsBackground=1`, `kDrawCallsMochiBase=1`, `kEquipmentSlotCount=3`) — When: `computeSceneFlameDrawCalls()` is called with no overrides — Then: assert result `== 5` (exact integer equality).
- **AC-F1-2**: Given `computeSceneFlameDrawCalls()` — When: called repeatedly (simulating "before equip" and "after equip" call sites, since the function takes no "equipped items" parameter at all) — Then: assert the result is `5` both times, proving the formula has no equip-state input to vary by construction.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pet-room-screen-ui/draw_call_budget_test.dart` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: None (informational contract; Story 003's real component tree should stay consistent with this story's constants but does not import code from it)
