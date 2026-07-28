# Story 001: Config resource, DI scaffold & blocking lockstep invariant

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-26 — 993/993 suite green 0 orphans, parent-verified)
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: ~0.5 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-016`, `TR-build-validation-navigability-061`, `TR-build-validation-navigability-062`, `TR-build-validation-navigability-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary; ADR-0001 (Inter-System Reference & DI Pattern); ADR-0005 (Boot Sequencing & Initialization Gate)
**ADR Decision Summary**: One `Resource`-derived config class per module with typed `@export` fields (one per Tuning Knob, at GDD defaults) stored as a `.tres`, exposing `validate() -> Array[String]` called once at boot in the owner's `setup()`. A single-field range issue warns + clamps + proceeds; a **GDD-declared BLOCKING cross-value invariant is a terminal boot-halt**. New systems are injected-tier: typed `@export` refs wired in `GameWorld.tscn`, all wiring in an explicitly-callable `setup()` that asserts its dependencies.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `load()` on a `.tres` returns the same shared cached object — config must be treated as read-only at runtime. Never `@export` an Autoload. Scene-file `@export`s are populated before `_ready()`; code-assigned wiring is not — so `setup()` must be explicitly called, never inferred from `_ready()`.

**Control Manifest Rules (this layer)**:
- Required (Foundation): one config class, typed `@export` fields, `.tres`; `validate()` called once at boot in `setup()`; injected-tier module; `_ready()` does nothing beyond optionally calling `setup()`.
- Required (Feature): walkability is **two shared pure functions owned by Villager AI** — every consumer calls those, Build Validation included. Under BV-4 those functions are reached **statically**; this story wires no walkability reference at all and does not implement or copy a predicate.
- Documented cross-module exception: "Cross-module config invariants are validated by whichever module's GDD states them (e.g. Build Validation reads Building System's config for `max_room_height >= wall_height`)" — source ADR-0002.
- Forbidden: `@export` an Autoload; write to a config field at runtime; `ConfigFile`/JSON for tuning; a second copy of `villager_clearance` / `max_step_height` anywhere in this module.
- Guardrail: config loads once at boot; validation low-single-digit ms.

**RESOLVED — walkability DI shape** (was Epic Known Conflict 4). Technical-director
ruling **BV-4**, `production/architecture-decisions-m02-preflight-2026-07-26.md`
— **PROVISIONAL, pending user ratification** (away-mode ruling; treat as the
planning assumption until ratified).

**Ruling: extract a pure static twin. Build Validation injects nothing and holds
no villager reference.** `villager-ai-026` extracts
`VillagerWalkabilityRules` (static functions only, the two constants declared
there and re-exported as aliases on `VillagerAi`); this module calls
`VillagerWalkabilityRules.is_standable(voxel_world, cell)` **statically**. It
already injects `voxel_world`, so it gains **no** new dependency, holds no
reference to a gameplay entity, and cannot be null-ref'd by a despawned villager.
Rationale (BV-4): the predicates read no per-villager state, so injecting a
`VillagerAi` would encode a lie about the dependency, would break when
`villager-ai-021` makes the roster plural, and would bake the shape into all ten
build-validation stories' fixtures.

**Consequence: this story's DI surface is SMALLER than originally planned** —
config + `voxel_world` + (later, per BV-1) the furniture-registry provider. There
is no "walkability provider" reference to wire, assert, or mock.

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [ ] `BuildValidationConfig` is a `Resource`-derived class with one typed `@export` per Tuning Knob — `min_room_cells` (default 2, safe 1–9), `max_room_height` (default 8, safe 8–16), `unsheltered_bed_multiplier` (default 0.7, safe 0.5–0.9), `room_cue_cooldown_ticks` (default 20, safe 0–120) — stored as a `.tres`. All values data-driven; none player-facing (Tuning Knobs, TR-062).
- [ ] **GIVEN** a config where `max_room_height` < the Building System's maximum `wall_height`, **WHEN** config loads, **THEN** the load fails loudly naming the lockstep invariant (AC27 — escalated from advisory to BLOCKING; mirrors Needs & Mood AC29's pattern). [TR-016]
- [ ] `validate() -> Array[String]` range-checks each knob against its GDD safe range; a single-field range issue warns + clamps + proceeds (never a boot-halt) — the blocking path is reserved for the AC27 cross-value invariant alone.
- [ ] The ladder-ordering invariant `ground_penalty < unsheltered_bed_multiplier < 1.0` is checked here as an **advisory** smoke check only — its blocking enforcement is owned by Needs & Mood (its AC29); this check is the courtesy duplicate. [TR-061]
- [ ] The module is instantiable headless via `Node.new()` with mocks assigned to `@export` props / passed to `setup()` — zero scene tree, zero Autoload registration; `setup()` asserts every dependency is wired (Voxel World ref, structural-change signal source, config). **Per BV-4 there is NO walkability dependency to wire or assert**; per BV-1 the furniture-registry provider is a separate, nil-safe, duck-typed `Object` whose `null` value is a valid state ("no furniture exists") and therefore is NOT asserted by `setup()`.
- [ ] No walkability rule or constant is redefined in this module — `villager_clearance` and `max_step_height` are reached only via `VillagerWalkabilityRules`' static surface, never copied (Rule 2 verbatim consumption). [TR-010]
- [ ] **No `VillagerAi` reference exists in this module** — grep-asserted. The walkability call form is `VillagerWalkabilityRules.<fn>(voxel_world, …)` (BV-4).

---

## Implementation Notes

*Derived from ADR-0002/0001/0005 Implementation Guidelines:*

- One `BuildValidationConfig extends Resource`, injected as another `@export`. Consumers read config; never write a config field at runtime.
- The AC27 check reads the Building System's **maximum** `wall_height`, not its current value — `WallToolConfig.WALL_HEIGHT_MAX` is the landed constant (currently 8, matching the GDD's "8 = 8" statement). Read the bound; do not hardcode 8.
- Terminal boot-halt follows the RID `Failed` pattern (ADR-0005): boot-halt screen, no `setup()` calls, terminal. Do not call `setup()` from `_ready()`.
- The GDD's tuning invariant is directional: `max_room_height ≥` max `wall_height`. Its safe range's lower bound **is** the invariant — the range was corrected from 3–16 to 8–16 by the 2026-07-10 review precisely because 3–7 were "safe" yet broke it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the candidate-cell predicate itself.
- Story 005: the analysis-pass trigger wiring and queryable-state surface.
- Needs & Mood epic: the recovery-ladder rate values and their blocking enforcement.

---

## QA Test Cases

**AC27 — blocking lockstep invariant:**
- Given a config with `max_room_height` = 7 and the Building System's max `wall_height` = 8, When config loads, Then the load fails terminally and the message names the lockstep invariant.
- Given `max_room_height` = 8 and max `wall_height` = 8, When config loads, Then it passes (boundary is inclusive).

**AC — single-field ranges:**
- Given `min_room_cells` = 0 (below safe range), When `validate()` runs, Then a warning string is returned and the value is clamped — not a boot-halt.
- Edge cases: every knob exactly at each safe-range boundary (inclusive); every knob present at its GDD default.

**AC — advisory ladder check:**
- Given `unsheltered_bed_multiplier` = 0.3 with `ground_penalty` = 0.4, When `validate()` runs, Then an advisory warning is returned and the load still proceeds (Needs & Mood owns the blocking half).

**AC — headless DI:**
- Given the module built via `Node.new()` with mock Voxel World / structural-signal source / config assigned, When `setup()` is called directly, Then it succeeds with no scene tree and no Autoload registration — **and with no walkability object of any kind supplied**.
- Given no furniture-registry provider assigned (`null`), When `setup()` is called, Then it succeeds — a null provider means "no furniture exists", which is exactly true until `building-028` lands (BV-1 §5).
- Edge cases: a missing required dependency (Voxel World, signal source, config) makes `setup()` assert/fail rather than silently proceed.

**AC — no duplicated constants / no villager reference:**
- Grep assertion: no `villager_clearance` / `max_step_height` literal or constant declaration exists in this module's source.
- Grep assertion: no `VillagerAi` type reference, `@export var` of that type, or `get_villager_ai()` call exists in this module's source (BV-4).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `neues-spiel/tests/integration/build_validation/config_and_scaffold_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None inside this epic (assumes the M01 Foundation Boot/DI/config spine). **External, hard**: `villager-ai-026` (extract `VillagerWalkabilityRules`) — **must land before this story starts**; the static call form does not exist until it does (BV-4).
- Unlocks: 002, 005

