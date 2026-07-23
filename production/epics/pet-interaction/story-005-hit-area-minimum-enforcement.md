# Story 005: Hit-Area Minimum Enforcement

> **Epic**: Pet Interaction
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2-3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-interaction.md`
**Requirement**: `TR-petinteraction-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: Pet Interaction Input Handling (§Decision 3).
**ADR Decision Summary**: ADR-0016 §Decision 3 fixes the hit-area contract: `MochiComponent`'s tap/drag registration area is Flame's default AABB hit test (`PositionComponent.containsLocalPoint`) against the component's `size` property — NOT a custom `RectangleHitbox`/`ShapeHitbox`, and NOT the same thing as the visually rendered sprite's dimensions. Whoever positions `MochiComponent` (Pet Room Screen UI #18, not yet an epic) MUST set `size` to at least `Vector2(80, 80)` regardless of Mochi's actual evolution-stage sprite size, with the sprite rendered smaller and centered within that larger hit area if needed. `scale` (if ever applied) affects the *effective* hit area as `size * scale`, not `size` alone — flagged as a documented risk for Pet Leveling/Equipment, not an active MVP concern (evolution stages are asset/size swaps, not runtime scale transforms). No child component inside Mochi's bounds may register its own `TapCallbacks`/`DragCallbacks`, or it will shadow pointer events from reaching the parent.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM
**Engine Notes**: GDD Core Rule 7 states the tap/drag hit area must be ≥80×80dp regardless of the Mochi sprite's actual rendered size at any evolution stage. This is a cross-epic contract: Pet Interaction (#14) owns the *requirement* (now formalized in ADR-0016 §Decision 3), Pet Room Screen UI (#18) owns the *implementation* (layout padding math, per #18's own Formula 2, not yet written since #18 has no epic). This story's job is narrower than it may look: verify that whatever hit area #18 produces actually satisfies the ≥80×80dp floor — not to implement the padding/layout logic itself (that belongs to #18).

**Control Manifest Rules (this layer)**:
- Required: hit-test the component's `size` property, not a custom `RectangleHitbox`/`ShapeHitbox` (source: ADR-0016 §Decision 3).
- Required: if `component.scale` is ever non-1.0, the effective hit area is `size * scale` — the test must account for this if/when a future evolution stage introduces scale transforms (source: ADR-0016 §Decision 3, flame-specialist-flagged risk).
- Forbidden: any child component inside Mochi's bounds registering its own `TapCallbacks`/`DragCallbacks` (would shadow parent pointer events) (source: ADR-0016 §Decision 3).

---

## Acceptance Criteria

*From GDD `design/gdd/pet-interaction.md`, scoped to this story:*

- [x] **AC-12**: GIVEN Mochi's sprite is at any evolution stage (any `spriteSize`), WHEN the actual tap/drag-registering area is measured, THEN that area is always ≥ 80×80dp (Core Rule 7) — verified against Pet Room Screen UI (#18)'s Formula 2 output.

---

## Implementation Notes

*Derived from ADR-0016 §Decision 3 — the architecture is now resolved; this story is still blocked on Pet Room Screen UI (#18) existing to supply the concrete per-evolution-stage `size` data the test below asserts against.*

- The test this story writes is a pure geometric assertion: `mochiComponent.size.x >= 80 && mochiComponent.size.y >= 80`, repeated for every evolution-stage `spriteSize` #18's Formula 2 defines (not just the smallest stage — a formula that only clamps the minimum case could still under-satisfy an intermediate stage depending on its shape, per this story's own QA Test Cases below).
- Do NOT implement `RectangleHitbox`/`ShapeHitbox` — ADR-0016 §Decision 3 explicitly chose the default `PositionComponent.containsLocalPoint` AABB-against-`size` hit test, since this system needs a simple rectangular pointer-registration area, not collision detection between components.
- If `component.scale` is ever non-1.0 by the time this is implemented, the assertion must multiply `size * scale`, not check `size` alone — this is currently a documented risk, not an active MVP case (evolution stages are asset/size swaps per current Pet Leveling design, not scale transforms).
- Once #18 exists and this story is fully unblocked: also add a regression check that no child component inside `MochiComponent`'s subtree (e.g. a future Pet Equipment #15 accessory overlay) mixes in `TapCallbacks`/`DragCallbacks` — such a child would shadow parent pointer events for whatever region it occupies, silently breaking hit-area coverage without any error signal.

GDD context for reference:
- Core Rule 7 (`design/gdd/pet-interaction.md`): "Vùng nhận tap/drag trên Mochi sprite phải ≥ 80×80dp (registry: `tap_hitbox_min`) — bất kể kích thước hiển thị thật của sprite tại evolution stage hiện tại." This is stated as a requirement OF Pet Interaction, not a suggestion — #18 must satisfy it, and this story is Pet Interaction's own verification that #18 actually does.
- The GDD's own Dependencies section documents this as a bidirectional relationship (added 2026-07-06, found during `/review-all-gdds`): #18 is both an Upstream Dependency of #14 (hosts the Flame `World` component) and a Downstream Dependent (#18 consumes the hit-area contract this story verifies).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001-004: interaction detection/classification/cooldown/mutation behavior — this story only checks the geometric hit-area contract, independent of gesture logic correctness.
- Pet Room Screen UI (#18): the actual padding/layout formula that produces the hit area — this epic does not own that implementation, only the requirement it must satisfy.

---

## QA Test Cases

*The developer implements against these — do not invent new test cases during implementation. To be refined once #18's Formula 2 exists — current specs are provisional based on the GDD's stated contract.*

- **AC-12**: GIVEN the Mochi sprite at its smallest defined evolution-stage `spriteSize` (the case most likely to violate the floor) — When: query the actual registered tap/drag hit area (via #18's Formula 2 output, once it exists) — Then: assert width ≥ 80dp AND height ≥ 80dp. Edge cases: repeat for every other evolution stage's `spriteSize`, not just the smallest — a formula that only clamps the minimum case could still under-satisfy an intermediate stage depending on its shape.
- **AC-12 (added retroactively at implementation, per this story's own Implementation Notes)**: GIVEN this story's own Implementation Notes' explicit follow-up ("once #18 exists and this story is fully unblocked: also add a regression check that no child component inside `MochiComponent`'s subtree mixes in `TapCallbacks`/`DragCallbacks`") — When: `MochiComponent` is freshly mounted, and separately for each of the 5 `TriggeredState` values (to populate its subtree with every Effect/TimerComponent shape a triggered state can attach) — Then: assert no descendant component mixes in `TapCallbacks` or `DragCallbacks` (ADR-0016 §Decision 3's "no child may shadow the parent's hit area" rule). Flagged here per qa-tester code-review finding (traceability gap: the test existed before this QA Test Case entry did) — not scope creep, since the story's own Implementation Notes explicitly called for it once unblocked.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pet-interaction/hit_area_contract_test.dart` — must exist and pass

**Status**: [x] Created — 13 tests, all passing (`cd src && flutter test ../tests/unit/pet-interaction/hit_area_contract_test.dart`).

---

## Implementation Record

**Both prior blockers confirmed resolved before implementation began** (verified fresh, not taken on faith):
- ADR-0016 (Pet Interaction Input Handling) — `docs/architecture/adr-0016-pet-interaction-input-handling.md` — Status: **Accepted** (2026-07-23).
- Pet Room Screen UI epic's Story 001 (Tap Hit-Area Padding, Formula 2) — `production/epics/pet-room-screen-ui/story-001-tap-hit-area-padding-formula.md` — Status: **Complete**, producing the real `computeHitArea(spriteSize, {hitBoxMin})` at `src/lib/gameplay/hit_area_formula.dart` and wiring `MochiComponent.size` to its padded `hitBoxSize` output in `src/lib/gameplay/mochi_component.dart`.

Evolution-stage `spriteSize` values used (GDD `design/gdd/pet-leveling-evolution.md`: 3 evolution stages, Baby/Young/Grown; concrete dp values per Art Bible Section 5.2, the same worked examples Pet Room Screen UI Story 001's AC-F2-4 verifies): **Baby = 72dp, Young = 112dp, Grown = 152dp**.

**Files created**:
- `tests/unit/pet-interaction/hit_area_contract_test.dart` — 13 tests. Two groups:
  1. AC-12 contract (7 tests): for each of the 3 evolution stages — `computeHitArea(spriteSize).hitBoxSize >= 80` on both axes, AND the real `MochiComponent.size` (constructed via the production constructor) equals that formula's output exactly (the cross-epic integration tie, not a re-derivation) — plus a single-instance stage-transition test exercising the `currentSpriteSize` setter path (the real level-up code path), and an effective-hit-area (`size * scale`) assertion per this story's own Control Manifest rule.
  2. ADR-0016 §Decision 3 regression guard (6 tests): no child component in `MochiComponent`'s subtree mixes in `TapCallbacks`/`DragCallbacks` — checked at fresh mount and separately for all 5 `TriggeredState` values (each attaches a different Effect/TimerComponent child shape).

**Files modified**: None. `mochi_component.dart` was read fresh immediately before starting (per this story's own coordination note about concurrent Story 003 edits) and found to already satisfy the AC-12 contract correctly — `size` is genuinely wired to `computeHitArea(currentSpriteSize).hitBoxSize` via both the constructor and the `currentSpriteSize` setter. No bug found, so no change was made to avoid any collision risk with Story 003's concurrent cooldown-logic work in the same file.

**Code review**: `flame-specialist` — **APPROVE WITH NITS** (no blocking issues; Flame API usage — `testWithFlameGame`, `Vector2.clone()/multiply()`, `ComponentSet.children` direct-children semantics — all confirmed correct; confirmed genuine cross-epic coverage, not duplication of `tests/unit/pet-room-screen-ui/hit_area_formula_test.dart`'s pure-function suite. One non-blocking nit acted on: the regression-guard test originally only drove `TriggeredState.excited`, contradicting its own comment claiming "every triggered-state effect path" — expanded to loop over all 5 `TriggeredState` values, one fresh component per state, since `_play()` clears the previous state's children before attaching the next). `qa-tester` — **ADEQUATE WITH GAPS** (both minor, non-blocking): traced a hypothetical regression (constructor bypassing `computeHitArea`) through the test's assertions and confirmed it would actually fail, not pass vacuously; confirmed the stage-transition test is what catches a setter-path-specific wiring bug the constructor-only tests would miss; one real gap — the child-callback regression test wasn't listed in this story's original QA Test Cases section even though it's explicitly authorized by this story's own Implementation Notes — closed by retroactively adding that QA Test Case entry above.

**Test results**: Full suite (`cd src && flutter test ../tests/`) — 549 passing / 1 pre-existing skip / 4 failing. The 4 failures are entirely in `tests/unit/pet-interaction/cooldown_enforcement_test.dart` (Story 003's own in-progress cooldown-logic work, landed concurrently during this story's implementation — file mtime confirms it postdates this story's start; failures are `GameEventBus` emitted-event-count mismatches unrelated to `size`/hit-area). Isolated run of both hit-area test files (`hit_area_contract_test.dart` + Pet Room Screen UI's own `hit_area_formula_test.dart`) — 24/24 passing, 0 failures. `flutter analyze` (project-wide, from `src/`): 0 issues attributable to this story's test file; pre-existing 13 `info`-level issues elsewhere (unrelated `prefer_initializing_formals`) plus 3 `warning`-level issues in `mochi_component.dart` (`unused_import`, 2× `unused_field`) that are Story 003's own in-progress WIP artifacts, not introduced by this story and not touched by this story.

---

## Dependencies

- Depends on: Story 001 (Gesture Classification & Event Emission — the component this hit area gates), Pet Room Screen UI (#18) epic/story producing Formula 2 — **satisfied**: `production/epics/pet-room-screen-ui/story-001-tap-hit-area-padding-formula.md`, Status Complete.
- Unlocks: None
