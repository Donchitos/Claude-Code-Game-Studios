# Production Spine Contracts

> **Manifest Version**: 2026-07-23 · **Dated**: 2026-07-23
> Foundation Spine Story 005. This is the binding contract sheet every
> Milestone-01 module is verified against — not a re-narration of the ADRs.
> Each section states Required / Forbidden and cites its governing ADR +
> TR-IDs; read the ADR for the *why*, this file for the *what*.
>
> Reference-only note: `prototypes/last-seal-vertical-slice/CONTRACTS.md` is
> the slice's throwaway format reference. Nothing in it is authoritative for
> production — no slice-only assumption (`CULL_DISABLED`, full-world-at-boot,
> constants-instead-of-config) carries over here. This file is authored fresh
> from the Accepted ADRs against the as-built spine code.

---

## 1. Dependency Injection (ADR-0001)

**Required**
- Exactly two Autoloads, project-registered in this order (`project.godot`):
  1. `TimeTickSystem` — `res://src/time_tick_system/time_tick_system.gd`
  2. `ResourceItemDatabase` — `res://src/resource_item_database/resource_item_database.gd`
- Every other module is **injected-tier**: a typed `@export var dep: SomeType`
  wired via the owning scene's Inspector (`GameWorld.tscn`), resolved at
  scene deserialization — before any child's `_ready()` fires.
- All wiring/validation logic lives in an explicitly-callable `func setup() -> void`
  (or `-> Dictionary` for Autoloads that return their own result, e.g. RID).
  `GameWorld` calls it once per module in production; a headless test calls
  it directly after assigning mocks to the `@export` properties. `_ready()`
  does nothing beyond optionally calling `setup()`.
- Autoload-tier modules are called by **global singleton name** directly in
  method bodies everywhere (`ResourceItemDatabase.get_by_id(id)`,
  `TimeTickSystem.get_game_delta()`) — no injection layer, ever.
- Tests instantiate with `Node.new()`, assign mocks to `@export` props (or
  pass to `setup()`), call `setup()`/methods directly — zero scene tree,
  zero Autoload registration.

**Forbidden**
- Never `@export` an Autoload (`ResourceItemDatabase`/`TimeTickSystem`) into
  any module — grep: `@export.*ResourceItemDatabase|@export.*TimeTickSystem`
  under `src/` must return zero (verified clean, see Verification below).
- Never read an `@export` dependency inside your own `_ready()` assuming
  another script assigned it there — scene-file wiring is populated by
  `_ready()` time, code-assigned wiring is not (Godot resolves `_ready()`
  bottom-up, children before parents).
- No injected-tier module's `setup()` call site may exist outside
  `GameWorld`'s Booting path (see §3) — verified: the sole `module.setup()`
  call site in `src/` is `GameWorld._setup_injected_tier()`.

**Governing ADR**: ADR-0001. **TR-IDs**: TR-building-ui-038, TR-villager-info-ui-023, TR-villager-ai-behavior-016, TR-resource-item-database-007, TR-needs-mood-system-025 (live-pair integration test — DI is its *enabler* per ADR-0001's Context, not itself a DI requirement; corrected 2026-07-26, see `production/architecture-decisions-m02-preflight-2026-07-26.md` NM-7).

---

## 2. Config Resource Pattern (ADR-0002)

**Required**
- One custom `Resource`-derived config class per module, extending the
  shared `ConfigResource` base (`@abstract`, `src/foundation/config_resource.gd`).
  Typed `@export` fields, one per GDD Tuning Knob, defaulted to the GDD's
  stated value.
- Every config exposes `func validate() -> Array[String]`, called exactly
  once at boot inside the owning module's `setup()`.
- **Two-tier policy, single return value, no second severity model**:
  - Single-field range issue → `validate()` clamps the field to its nearest
    valid bound (the ONE sanctioned runtime write to a config field, and it
    lives inside `validate()` itself) and appends a plain warning string.
    Boot proceeds.
  - GDD-declared BLOCKING cross-value invariant → `validate()` appends a
    string tagged via `ConfigResource.format_blocking()` (prefix
    `ConfigResource.BLOCKING_PREFIX = "BLOCKING: "`) instead of clamping.
    Callers test for this tier via `ConfigResource.has_blocking_issue(issues)`
    — an issue array with even one BLOCKING entry dominates a mix of
    warnings, and the owning module's `setup()` must reuse the terminal
    boot-halt path (§3), not invent a new one.
- Config files are `.tres` **text**, never `.res` binary.
- Injected-tier modules receive their config as another typed `@export`
  (e.g. `@export var config: TimeTickConfig`), wired exactly like any other
  ADR-0001 dependency. Autoload-tier modules `load()` their own via a fixed
  `const CONFIG_PATH` inside their own `setup()` (see `TimeTickSystem`).
- A module that wants `GameWorld`'s boot gate to observe a BLOCKING result
  implements the optional duck-typed method
  `func get_boot_blocking_issues() -> Array[String]` (see
  `ReferenceConfigConsumer`) — `GameWorld` calls it immediately after that
  module's `setup()` (§3); it is never a second call site for `validate()`.

**Forbidden**
- Never write to a config Resource field at runtime outside its own
  `validate()` — grep `config\.\w* *=` under `src/` (excluding each config
  class's own file) must return zero (verified clean, see Verification).
- Never `ConfigFile` or JSON for tuning data.

**Engine fact**: `load()`/`preload()` on the same `.tres` path returns the
same `ResourceLoader`-cached object — a runtime write is visible to every
holder project-wide. This is *why* config is read-only, not a separate rule.

**Governing ADR**: ADR-0002 (secondary: ADR-0001 injection, ADR-0005 halt reuse). **TR-IDs**: TR-scene-world-management-030, TR-voxel-world-023, TR-camera-input-019, TR-time-tick-system-020, TR-building-system-038, TR-building-ui-037.

---

## 3. Boot Gate (ADR-0005)

**Required**
- `GameWorld` (`src/scene_world_management/game_world.gd`) is the **single
  unified choke point**: `enum BootState { WAITING_FOR_DATABASE, WIRING, ACTIVE, HALTED }`.
  No per-module allowlist — every injected-tier module's `setup()` is gated,
  whether or not it has an RID dependency.
- **Check-then-connect**, not a literal `await`: `_ready()` first checks
  `resource_item_database.is_ready() -> bool` synchronously; only if not yet
  ready does it `.connect(callable, CONNECT_ONE_SHOT)` to
  `signal validation_complete(result: Dictionary)`
  (`result = {"success": bool, "issues": Array}`).
- On success: `WIRING` → `_setup_injected_tier()` calls `setup()` on every
  entry in `injected_tier_modules: Array[Node]`, in array order, then
  duck-types `get_boot_blocking_issues()` per §2 → `ACTIVE` (unless a
  BLOCKING result already diverted to `HALTED` mid-loop).
- On failure (RID Failed, or a BLOCKING config invariant mid-WIRING):
  `HALTED`, `signal boot_halted(issues: Array)` fires. **Terminal** — no
  path out, no further `setup()` calls, ever.
- `resource_item_database` on `GameWorld` is a plain `var: Object`
  (duck-typed against `is_ready()` + `validation_complete`), never
  `@export` — RID is Autoload-tier (ADR-0001). Production resolves it
  lazily via `get_node_or_null(^"/root/ResourceItemDatabase")`; tests assign
  a mock double directly before the node enters the tree.

**Forbidden**
- Never poll for boot readiness (no per-frame/`Timer` check against
  `is_ready()`) — the signal is the only fallback path.
- No injected-tier `setup()` call site outside `GameWorld`'s Booting path
  (verified — see §1 Forbidden).

**Governing ADR**: ADR-0005 (depends on ADR-0001). **TR-IDs**: TR-scene-world-management-004/023, TR-resource-item-database-019, TR-building-ui-008.

---

## 4. Data-Definition Immutability (ADR-0006)

*No standalone RID pipeline lands in this epic — this is the binding
contract the `resource-item-database` epic implements against.*

**Required**
- **Two-type split**:
  - `ItemDefinitionResource extends Resource` (`class_name ItemDefinitionResource`,
    `src/resource_item_database/item_definition_resource.gd`) — private to
    RID's own implementation, freely `@export`-editable, `.tres`-authored
    under `res://data/items/`. Nothing outside RID's implementation ever
    holds a reference to this type.
  - `ItemDefinition extends RefCounted` (`class_name ItemDefinition`,
    `src/resource_item_database/item_definition.gd`) — the public view
    `get_by_id(id: StringName) -> ItemDefinition` returns. **Getter-only**:
    every field has a `func get_<field>() -> <Type>` accessor and nothing
    else. `get_by_id()` constructs a **fresh, lightweight wrapper per call**
    around the *same* stored `ItemDefinitionResource` — it wraps, it never
    copies, and it is never a `duplicate()`.
- `visual_asset` is a typed `@export var visual_asset: Mesh` — never a path
  string.
- Boot validation order (both terminal, distinct diagnostics): check the
  `ItemDefinitionResource` itself loaded non-null **BEFORE** checking
  `visual_asset != null`. A `.tres` load failure and a null `visual_asset`
  are different failures and must report differently.
- Cross-system references to an item are opaque `StringName` ids only —
  never a direct `ItemDefinitionResource`/`ItemDefinition` reference held
  elsewhere.
- Footprint (multi-cell furniture, e.g. a bed): `@export var footprint: Vector2i`
  on `ItemDefinitionResource`, `get_footprint() -> Vector2i` on
  `ItemDefinition` — already present structurally; validation of it is a
  later story's scope.

**Forbidden**
- `ItemDefinition` has **zero** `func set_*` methods and zero writable
  `var`s anywhere in its public surface (verified — see Verification).
- Never defensive-copy via `duplicate()` for a definition query — copies
  still carry setters (silent-success mutation) and cost a per-query
  `Resource` allocation `RefCounted`-wrapping avoids.
- Nothing outside RID's own implementation holds an `ItemDefinitionResource`.

**Documented residual (not a defect, do not "fix")**: GDScript's generic
`Object.get(StringName)`/`Object.set()` reflection can still reach
`ItemDefinition._source` by key string, bypassing the getter-only surface.
This is real and known — the guarantee covers accidental/idiomatic misuse,
not deliberate reflection-based bypass (ADR-0006 Risks).

**Governing ADR**: ADR-0006 (depends on ADR-0002 authoring idiom, ADR-0001 RID Autoload-tier status). **TR-IDs**: TR-resource-item-database-010, TR-resource-item-database-023.

---

## 5. Shared Severity Model (cross-cutting, all sections above)

**One terminal-halt severity model, reused, never reinvented**: the RID
Failed pattern (ADR-0005) is the *same* mechanism a config's BLOCKING
invariant (ADR-0002) and a data-definition validation failure (ADR-0006)
both resolve through — `GameWorld`'s `HALTED` state + `boot_halted` signal,
no `setup()` calls after it fires, no recovery. There is no second enum, no
second signal, no per-system "severity level" concept anywhere in the spine.

---

## 6. Engine Constraints (established during Stories 001–004)

- **Never `class_name X` on a script registered as the Autoload singleton
  named `X`.** Godot 4.7 hard-errors *"Class 'X' hides an autoload
  singleton"* if both are true simultaneously. `time_tick_system.gd` and
  `resource_item_database.gd` deliberately carry **no** `class_name` for
  this reason — callers reach them exclusively via the registered
  Autoload's global name (`TimeTickSystem.foo()`, never a typed reference),
  which is consistent with §1's "never `@export` an Autoload" rule anyway.
- **Script class-name changes may need a project reload to take effect.**
  Godot caches the project's global `class_name` list; if you add, remove,
  or rename a `class_name` (e.g. resolving the conflict above by dropping
  one), the editor/CLI may not see the change until the project is
  reopened or reimported. If a `class_name`-based reference behaves as
  stale after such an edit, reload the project before treating it as a bug.
- `@abstract` (Godot 4.5+) is in active production use — `ConfigResource`
  is `@abstract`; every concrete `<System>Config` overrides `validate()`.

---

## Verification

Every signature and grep-verifiable rule above was checked against the
landed code, not asserted from the ADRs alone:

- `@export.*ResourceItemDatabase|@export.*TimeTickSystem` under
  `neues-spiel/src/` (`*.gd`) → **zero matches** (§1 Forbidden holds).
- `config\.\w* *=` under `neues-spiel/src/` (`*.gd`) → **zero matches**
  (§2 Forbidden holds; the one sanctioned clamp write lives inside each
  config's own `validate()`, e.g. `time_tick_config.gd`,
  `reference_module_config.gd`).
- `func setup\(\)|setup\(\)` across `neues-spiel/src/` → the only
  `module.setup()` *call site* (as opposed to a `func setup()` definition)
  is `game_world.gd:153` inside `_setup_injected_tier()` (§1/§3 holds).
- `func set_` in `neues-spiel/src/resource_item_database/item_definition.gd`
  → **zero matches** (§4 Forbidden holds).
- Read in full and cross-checked line-by-line against this file's claims:
  `game_world.gd` (BootState enum, `boot_halted` signal, check-then-connect,
  `_setup_injected_tier`), `config_resource.gd` + `reference_module_config.gd`
  + `reference_config_consumer.gd` (two-tier `validate()`, `BLOCKING_PREFIX`,
  `format_blocking`, `has_blocking_issue`, `get_boot_blocking_issues`),
  `time_tick_system.gd` + `time_tick_config.gd` (Autoload-tier `setup()`,
  `CONFIG_PATH`, no-`class_name` doc comment), `resource_item_database.gd`
  + `item_definition_resource.gd` + `item_definition.gd` (two-type split,
  `get_by_id()` signature, boot lifecycle, no-`class_name` doc comment),
  `camera_input.gd` (injected-tier config-consumer shape), `project.godot`
  (`[autoload]` registration order: `TimeTickSystem` then
  `ResourceItemDatabase`).
