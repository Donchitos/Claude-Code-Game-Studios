# Story 001: GameWorld root scene + injected-tier DI scaffold (`setup()` wiring)

> **Epic**: Foundation Spine (Boot, DI, Config & Test Harness)
> **Status**: In Progress
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-23

## Context

**GDD**: N/A — ADR-driven infrastructure. Source: `docs/architecture/architecture.md` §Initialization order (step 1, World Root instantiated) + §API Boundaries.
**Requirement**: `TR-building-ui-038`, `TR-villager-ai-behavior-016`, `TR-resource-item-database-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time. These three are the GDD-level "headless-mockable via DI" requirements this scaffold satisfies for every injected-tier module.)*

**ADR Governing Implementation**: ADR-0001: Inter-System Reference & Dependency-Injection Pattern (primary)
**ADR Decision Summary**: Hybrid model — only `TimeTickSystem` and `ResourceItemDatabase` are Autoloads (called by global name, never injected); every other module is injected-tier with typed `@export` node references wired exclusively in `GameWorld.tscn`'s Inspector, and all wiring/validation lives in an explicitly-callable `setup()` (never `_ready()`).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes** (from ADR-0001 Engine Compatibility + Control Manifest "Engine Facts"): Scene tree readies **bottom-up** — a child's `_ready()` runs before its parent's, and scene-file `@export`s are populated by then but **code-assigned** wiring (e.g. inside `GameWorld._ready()`) is NOT. `SomeModule.new()` in a headless test never enters the SceneTree, so `_ready()` never runs — this is exactly why wiring/validation must live in `setup()`, not `_ready()`. Cross-reference `docs/engine-reference/godot/` before finalizing any Inspector/`@export` API assumptions.

**Control Manifest Rules (Foundation Layer)**:
- Required: injected-tier modules expose typed `@export` node references, wired ONLY in `GameWorld.tscn`; all wiring/validation logic lives in `setup()` which asserts its dependencies are wired; `_ready()` does nothing beyond optionally calling `setup()`. Tests instantiate with `Node.new()`, assign mocks to `@export` props, call `setup()` directly — zero scene tree, zero Autoload registration.
- Forbidden: never `@export` an Autoload (`ResourceItemDatabase`/`TimeTickSystem`) into any module (grep `@export.*ResourceItemDatabase|@export.*TimeTickSystem` = zero); never read `@export` dependencies inside your own `_ready()`; never put validation in `_ready()`.
- Guardrail: wiring resolves once at scene load; revisit service-locator only above ~30 `@export` assignments (MVP: 9 modules).

---

## Acceptance Criteria

*Derived from ADR-0001 Decision + Validation Criteria (this epic is ADR-governed, not GDD-governed):*

- [ ] `GameWorld.tscn` exists with a root script that owns injected-tier children and exposes them for scene-file (Inspector) wiring.
- [ ] The injected-tier module shape is established: a reference module class exposes typed `@export` node-reference dependencies and implements `setup()`; `setup()` asserts each dependency is non-null; `_ready()` performs no wiring and no validation beyond (optionally) delegating to `setup()`.
- [ ] `GameWorld` invokes each injected-tier child's `setup()` explicitly (not via `_ready()` ordering), after scene-file wiring is resolved.
- [ ] A headless unit test instantiates the reference injected-tier module with `Node.new()`, assigns mock objects to its `@export` properties, and calls `setup()` — with zero scene tree and zero Autoload registration — proving the module is DI-mockable.
- [ ] No injected-tier module references `ResourceItemDatabase` or `TimeTickSystem` via an `@export` property (grep-verifiable, returns zero).
- [ ] No injected-tier module reads an `@export` dependency inside its own `_ready()` (grep-verifiable / review check).

---

## Implementation Notes

*Derived from ADR-0001 Decision (Wiring rule + Test-path parity) and Key Interfaces:*

- Injected-tier module shape (ADR-0001 §Key Interfaces):
  ```gdscript
  class_name BuildingSystem extends Node
  @export var voxel_world: VoxelWorld
  @export var camera_input: CameraInput
  func setup() -> void:
      assert(voxel_world != null, "BuildingSystem.voxel_world not wired")
  ```
- `@export` references between injected-tier modules are assigned **exclusively via `GameWorld.tscn`** (Inspector), resolved at scene deserialization — before any child's `_ready()` fires. If a dependency is only known at runtime, `GameWorld` calls an explicit `module.setup(dependency)`; never rely on `_ready()` timing for code-assigned wiring.
- Test-path parity: the identical `setup()` code path must run in both a real scene (called by `GameWorld`) and a headless test (called directly after mock assignment). `_ready()` must not contain anything a headless `new()` would skip.
- This story builds the **substrate only** — a reference/placeholder injected-tier module is sufficient to prove the pattern. The concrete Foundation/Core modules (Voxel World, Camera & Input, etc.) are wired into `GameWorld.tscn` as their own epics land.
- Engine code lives inside the Godot project root `neues-spiel/` (loadable via `res://`); tests live in `neues-spiel/tests/` per `tests/README.md`.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- Story 002: the boot-sequencing gate (BootState machine, RID Ready/Failed check-then-connect). This story only stands up the DI wiring + `setup()` convention that the gate drives.
- Story 003: the config-Resource pattern (`validate()` two-tier handling). Config `@export` fields follow the same injection mechanism but are specified there.
- Concrete module implementations (Voxel World, Camera & Input, Building System, etc.) — each module epic wires itself into `GameWorld.tscn`.

---

## QA Test Cases

*Automated test specs — the developer implements against these:*

- **AC-1 (module is DI-mockable headless)**:
  - Given: a reference injected-tier module constructed via `Node.new()` with mock objects assigned to its `@export` dependency properties.
  - When: `setup()` is called directly (no scene tree, no Autoload registration).
  - Then: `setup()` completes and the module holds the assigned mock references.
  - Edge cases: a dependency left null → `setup()`'s assertion fails (proving the guard fires); assigning a mock of the wrong shape is out of scope (GDScript duck-typing).

- **AC-2 (setup() asserts wiring)**:
  - Given: the reference module with one `@export` dependency unassigned (null).
  - When: `setup()` is called.
  - Then: the assertion for that dependency fails with the named message.
  - Edge cases: all-null vs. one-null-of-many — each missing dependency is individually asserted.

- **AC-3 (no `_ready()`-order dependence / no Autoload injection)**:
  - Given: the module source.
  - When: grep for `@export.*ResourceItemDatabase|@export.*TimeTickSystem` and for `@export`-dependency reads inside `_ready()` bodies.
  - Then: both return zero matches.
  - Edge cases: comments mentioning the pattern are acceptable; only real `@export`/read statements count.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration test at `neues-spiel/tests/integration/foundation/gameworld_di_scaffold_test.gd` — must exist and pass headless. (The isolated `setup()`/mock-injection assertions may also live as a unit test at `neues-spiel/tests/unit/foundation/`.)

**Status**: [x] Created — 3 integration test functions (`gameworld_di_scaffold_test.gd`) + 4 unit test functions (`reference_injected_module_test.gd`), all passing headless (2026-07-23)

---

## Dependencies

- Depends on: None (first story of the epic — the DI substrate every other spine story builds on).
- Unlocks: Story 002 (boot gate calls `setup()` on the injected tier), Story 003 (config injected via the same `@export` mechanism).
