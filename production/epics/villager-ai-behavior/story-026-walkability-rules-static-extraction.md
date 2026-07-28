# Story 026: Extract `VillagerWalkabilityRules` static twin (behavior-preserving)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-26 — 958/958 suite green 0 orphans, parent-verified; zero-test-edit gate held: only one additive test file)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~0.5 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-009`, `TR-villager-ai-behavior-010`, `TR-villager-ai-behavior-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*
*(Downstream consumer requirement: `TR-build-validation-navigability-010` — Build Validation redefines no walkability rule or constant.)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding, Navigation & Room-Analysis)
**ADR Decision Summary**: Villager AI owns the walkability predicates **as shared pure functions** — the single source of truth every consumer (its own pathfinder, Build Validation, the watchdog rescue BFS) calls. No duplicated rules or constants anywhere. The landed instance-method shape is a **drift from that ADR text**, not a decision the ADR made; this story restores the stated shape.

**Ruling that creates this story**: `production/architecture-decisions-m02-preflight-2026-07-26.md` § **BV-4** — technical-director, **PROVISIONAL pending user ratification** (away-mode ruling; binding on Sprint 9 story authoring once ratified, and the planning assumption until then). Ruling summary: extract a pure static twin; Build Validation injects nothing and holds no villager reference.

**Why this exists** (BV-4, verified against landed source): `is_standable`, `is_step_legal`, `body_column` and `is_cell_in_body_column` are instance methods on `VillagerAi` (a `Node` carrying `villager_id`, `config`, `voxel_world`, scheduler, nav graph, telemetry), but their bodies read only `voxel_world` and the two class constants. They read **no** per-villager state, so every instance returns identical answers — which means "which villager does Build Validation inject?" has no meaningful answer. `VillagerNavGraph` already works around this with a `predicate_source: VillagerAi` parameter. Injecting a `VillagerAi` would encode a lie about the dependency, would break once `villager-ai-021` makes the roster plural, and would bake a freed-reference hazard into all ten build-validation stories' fixtures.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Cross-module static utility calls are already sanctioned and in use in this codebase (`VillagerAi` itself calls `VoxelWorldGrid.cell_to_world(...)` statically; `VoxelWorldGrid._pure_terrain_height` is the same precedent). `class_name` on a `RefCounted` with static-only members needs no autoload, no scene entry, and no instantiation. A `const` initialised from another class's `const` resolves at parse time, so the re-export alias costs nothing at runtime.

**Control Manifest Rules (this layer)**:
- Required (Feature layer): walkability = shared pure functions owned by Villager AI; EVERY consumer calls these — single source of truth.
- Forbidden: duplicate walkability rules or constants (no second copy of the clearance/step values); `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D`.
- Guardrail: the predicates stay pure queries against Voxel World data — no mutation, no caching state of their own. **This story changes no behavior at all.**

---

## Acceptance Criteria

*Scoped from ADR-0007's "shared pure functions" clause and BV-4:*

- [ ] New file `neues-spiel/src/villager_ai/villager_walkability_rules.gd` declares `class_name VillagerWalkabilityRules extends RefCounted` with **static functions only**; it is never instantiated anywhere in `src/`.
- [ ] It exposes exactly: `static func is_standable(voxel_world: VoxelWorldGrid, cell: Vector3i) -> bool`, `static func is_step_legal(voxel_world: VoxelWorldGrid, from_cell: Vector3i, to_cell: Vector3i) -> bool`, `static func body_column(cell: Vector3i) -> Array[Vector3i]`. The `_is_solid` / `_is_passable` helpers move with them as static privates.
- [ ] `VILLAGER_CLEARANCE` and `MAX_STEP_HEIGHT` are **declared on `VillagerWalkabilityRules` and nowhere else**. `VillagerAi` keeps `const VILLAGER_CLEARANCE: int = VillagerWalkabilityRules.VILLAGER_CLEARANCE` (likewise `MAX_STEP_HEIGHT`) as a re-export alias, so every existing call site — including `VillagerNavGraph`'s `VillagerAi.VILLAGER_CLEARANCE` read — compiles unchanged.
- [ ] **Exactly one literal `3` / `1` for these values exists in the codebase.** The epic's "zero duplicated walkability constants" grep guard is asserted against duplicated **literals**, not against the identifier (the identifier now legitimately appears twice: declaration + alias).
- [ ] `VillagerAi.is_standable` / `is_step_legal` / `body_column` **remain, with unchanged signatures, as one-line delegations** to the static twin. No caller anywhere is edited to reach the static class in this story.
- [ ] **The existing suite stays green with ZERO test edits.** No assertion, fixture, helper, or file under `neues-spiel/tests/` is modified, added-to in place, or renamed. *If any existing test needs editing, the extraction was not behavior-preserving and the story is not done.* This is the correctness proof for the whole story.
- [ ] A new additive test file proves the extraction's two structural claims: the static form returns identical answers to the instance form across a shared fixture set, and `VillagerAi.VILLAGER_CLEARANCE == VillagerWalkabilityRules.VILLAGER_CLEARANCE` (likewise `MAX_STEP_HEIGHT`) — alias identity, not two values that happen to match today.
- [ ] `VillagerNavGraph`'s `predicate_source` parameter is either migrated to the static class **or** left exactly as-is — **not both, and the choice is recorded in the commit body.** Leaving it is acceptable because it delegates to the same single implementation (BV-4 §5).
- [ ] No behavior change is introduced: no new branch, no reordered check, no changed out-of-bounds handling, no signature change on any surviving `VillagerAi` method.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines and BV-4:*

- This is a **mechanical move**. Copy the bodies verbatim; the only edit permitted inside a moved body is replacing the implicit `voxel_world` member read with the new first parameter, and re-pointing `_is_solid`/`_is_passable` calls at their static twins.
- `is_cell_in_body_column` is a pure derivation of `body_column` and MAY move alongside it; if it does, `VillagerAi.is_cell_in_body_column` stays as a delegation with an unchanged signature. Moving it is optional — do not treat it as a second decision worth debate.
- Order of work that keeps the suite green at every step: (1) add the new file with the constants and the moved bodies; (2) turn the `VillagerAi` methods into delegations and the constants into aliases; (3) run the full suite; (4) add the new structural test. Do not batch these.
- Build Validation will call `VillagerWalkabilityRules.is_standable(voxel_world, cell)` **statically** — it already injects `voxel_world`, gains no new dependency, holds no reference to a gameplay entity, and cannot be null-ref'd by a despawned villager. That consumption lands in `build-validation-001`/`002`, **not here**.
- Keep the doc comments with the functions they document. The `is_standable` comment's Planned-blueprint-cells clause is load-bearing for build-validation story 002's AC23 — it must survive the move.

---

## Out of Scope

*Handled elsewhere — do not implement here:*

- **The `*_after_write` twins** (`_is_standable_after_write`, `_is_step_legal_after_write`, `_is_solid_after_write`, `_is_passable_after_write`) stay exactly where they are. Their duplication of the same control flow with override-aware reads is the **one sanctioned copy**; the clean fix is an overlay-predicate parameter on the extracted functions and is a **post-M02 tech-debt item** (BV-4 §6). Do not expand this story's scope to touch them.
- Build Validation's own consumption of the static class (`build-validation-001`, `build-validation-002`).
- Any change to what the predicates *decide* — that is stories 002/003's content and it is already Complete.
- ADR-0007's Key-Interfaces text update recording the canonical call form (technical-director's separate ADR pass).

---

## QA Test Cases

- **Equivalence**: Given a fixture world, When each of `is_standable` / `is_step_legal` / `body_column` is called through both the `VillagerAi` instance and `VillagerWalkabilityRules` statically over the same cell set, Then every pair of answers is identical (including the out-of-bounds and world-boundary cells, where `get_cell()` returns `null`).
- **Alias identity**: Given `VillagerAi.VILLAGER_CLEARANCE` and `VillagerWalkabilityRules.VILLAGER_CLEARANCE`, When compared, Then equal — and grep proves only one of them is a literal declaration. Same for `MAX_STEP_HEIGHT`.
- **Zero-edit regression**: Given the full suite at its pre-story revision, When run against the post-story tree, Then it is green and `git diff --stat -- neues-spiel/tests/` shows **no modification** to any pre-existing test file.
- **No instantiation**: Grep proves no `VillagerWalkabilityRules.new(` anywhere in `neues-spiel/src/`.
- **Single-source guard**: Grep proves no second declaration of a clearance or step-height value in `src/` (the guard tests literals, not the identifier).
- Edge cases: `VillagerNavGraph` still builds and patches identically (its `predicate_source` path is exercised by the landed AStar tests); the seal-prevention gate and rescue BFS keep passing untouched.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/villager_ai/walkability_rules_static_test.gd` — must exist and pass (**new file only**), **plus** the full existing suite green with a clean `git diff` over `neues-spiel/tests/` for all pre-existing files.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (walkability predicates — Complete), 003 (body-column — Complete). Both are landed; this story only moves them.
- Blocked on: nothing. **Ratification note**: the BV-4 ruling that creates this story is provisional pending user ratification; the extraction itself is behavior-preserving and low-risk either way.
- **Unlocks**: `build-validation-navigability` story 001 — **this story MUST land before it.** Build-validation 001's DI shape (call the static twin, inject nothing) is undefined until this exists.
