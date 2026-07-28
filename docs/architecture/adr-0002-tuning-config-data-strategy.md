# ADR-0002: Tuning/Config Data Strategy

## Status
Accepted (2026-07-11 — per architecture-review-2026-07-11 recommendation; user-delegated decision. Not spike-gated and no dependency on a spike-gated ADR.)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Data / Resources |
| **Knowledge Risk** | MEDIUM — no dedicated engine-reference module exists for this domain; relies on `breaking-changes.md`'s 4.3→4.4 `FileAccess` entry and `deprecated-apis.md`'s `duplicate_deep()` (4.5+) entry |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None required. `duplicate_deep()` (4.5+) is explicitly NOT used — see Decision's immutability rule. |
| **Verification Required** | Confirmed via `godot-specialist` validation pass (2026-07-11) — see Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Inter-System Reference & Dependency-Injection Pattern) — config Resources are wired into injected-tier modules via the same `@export` mechanism |
| **Enables** | Every module implementation story that has a Tuning Knobs section (all 11 MVP GDDs) |
| **Blocks** | Any `/dev-story` work that reads a "data-driven, never hardcoded" value — which is nearly every MVP story |
| **Ordering Note** | ADR-0005 "Boot Sequencing & System Initialization Gate" (authored 2026-07-11, Proposed) specifies exactly when config validation (this ADR's `validate()` step) runs relative to Resource & Item Database's Ready gate — see Related Decisions |

## Context

### Problem Statement
Every one of the 11 MVP GDDs' Tuning Knobs sections, and dozens of individual TRs (TR-scene-world-management-030, TR-voxel-world-023, TR-camera-input-019, TR-time-tick-system-020, TR-building-system-038, TR-building-ui-037, and the equivalent unlabeled clause in every other GDD), state the same requirement in different words: numeric/config values must be read from data, never hardcoded in script. No GDD specifies *how* — that's this ADR's job. Without one project-wide answer, every module invents its own config-loading boilerplate, and the "immutable to callers" and "dependency-injectable" testability requirements (already established generally by ADR-0001) would need re-solving per module.

### Constraints
- Godot 4.7-stable / GDScript, static typing enforced
- Config values must be injectable/mockable in headless tests (same testability bar as ADR-0001)
- Config data should be diffable in git (design/balance changes are frequent during Systems Design and will continue into Production tuning passes) — a binary format is a regression here
- Some config values carry cross-value invariants that specific GDDs mark BLOCKING at load time (e.g. needs-mood-system.md TR-needs-mood-system-020: `ground_penalty < unsheltered_bed_multiplier < 1.0`; build-validation-navigability.md TR-build-validation-navigability-016: `max_room_height >= wall_height`) — the mechanism must support per-GDD custom validation, not just single-field range clamps
- Designer/tuner iteration speed matters (`balance-check` and future tuning passes will edit these values repeatedly)

### Requirements
- One config-loading mechanism used by all 11 MVP modules (and future systems)
- Typed access to every config field (no stringly-typed key lookups)
- Config Resources must be trivially constructable in a unit test with `Resource.new()` + direct field assignment — no file I/O required for tests
- Config must be read-only at runtime from every consuming module's perspective
- Boot-time validation must support both "clamp with warning" (single out-of-range scalar) and "blocking halt" (a GDD-declared cross-value invariant)

## Decision

**Custom `Resource`-derived config classes, one per module, stored as `.tres` (text, never binary `.res`) files, injected exactly like any other typed dependency per ADR-0001.**

Each module that owns tuning knobs defines a small `Resource` subclass with typed `@export` fields, one per Tuning Knob in its GDD, defaulted to that GDD's stated default value:

```gdscript
class_name TimeTickConfig extends Resource

@export var ticks_per_second: float = 2.0
@export var max_ticks_per_frame: int = 10
@export var max_raw_delta: float = 0.1
@export var time_warp_options: Array[int] = [1, 2, 3]

## Returns a list of human-readable problems, empty if valid.
## Called once at boot by this config's owning module's setup().
func validate() -> Array[String]:
    var issues: Array[String] = []
    if ticks_per_second <= 0.0:
        issues.append("ticks_per_second must be > 0, got %f" % ticks_per_second)
    return issues
```

A `.tres` instance (e.g. `res://data/config/time_tick_config.tres`) is the actual data — editable via the Godot Inspector like any Resource, or hand-edited as plain text (`.tres` is human-readable and git-diff-friendly by default). Two validation tiers, matching the Constraints above:
- **Single-field range issues** (e.g. a knob outside its GDD-stated safe range): `validate()` returns a warning string, the value is clamped to the nearest valid bound, and the module proceeds — never a boot-halt for an isolated scalar.
- **Cross-value invariants a GDD explicitly marks BLOCKING** (the two examples in Context above): the owning module's `setup()` treats a non-empty `validate()` result touching a blocking invariant as a boot-halt, using the same terminal-halt pattern Resource & Item Database's GDD already established for its own Failed state — this ADR doesn't invent a new severity model, it reuses the one already accepted for RID.

**Wiring**: for injected-tier modules (per ADR-0001), the config Resource is just another `@export` dependency, wired via `GameWorld.tscn`'s Inspector alongside the module's other collaborators:
```gdscript
class_name BuildingSystem extends Node
@export var voxel_world: VoxelWorld
@export var config: BuildingSystemConfig
```
For the two Autoload-tier services (TimeTickSystem, ResourceItemDatabase), which per ADR-0001 are never `@export`-injected, each loads its own config directly via a fixed `const CONFIG_PATH` and `load()`/`preload()` in its own `setup()` — consistent with their "no injection layer" status.

**Immutability rule (the critical engine-specific gotcha)**: `load()`/`preload()` on a `.tres` path resolves through Godot's `ResourceLoader` cache (`CACHE_MODE_REUSE` by default) — if the same path is loaded twice while a reference to it is still alive, both callers get the *same object*, so a mutation by one is visible to the other. This is reference-counted, not a permanent guarantee: if every strong reference to a cached Resource were released, a subsequent `load()` would create a fresh instance. In practice this project always keeps a permanent strong reference (an Autoload's own `var config`, or a `GameWorld.tscn` `@export` field that lives for the process lifetime), so sharing holds for the app's whole lifetime — but the rule below does not depend on that detail either way. **No module may ever write to a field on its injected config Resource at runtime.** Config is read-only from every consumer's perspective, full stop; if a future system needs a runtime-adjustable value (e.g. a difficulty slider), that value does not belong in a shared config Resource — it needs its own explicitly-owned, non-shared state on the module that owns it.

### Architecture Diagram
```
res://data/config/
  time_tick_config.tres        ← loaded directly by TimeTickSystem (Autoload)
  resource_item_database_config.tres  ← loaded directly by ResourceItemDatabase (Autoload)
  voxel_world_config.tres      ┐
  camera_input_config.tres     │  wired via GameWorld.tscn's Inspector,
  building_system_config.tres  │  @export var config: <Type>Config
  building_ui_config.tres      ┘  on each injected-tier module

Boot sequence addition (after Resource & Item Database reaches Ready,
before each module's setup() completes):
  module.config.validate() → [] (proceed) | [blocking issues] (boot-halt,
                                              same terminal pattern as RID's
                                              own Failed state)
                                          | [warnings] (clamp + log, proceed)
```

### Key Interfaces
```gdscript
# Every config Resource follows this shape:
class_name <System>Config extends Resource
@export var some_knob: float = <GDD-stated default>
func validate() -> Array[String]:
    # returns human-readable problems; caller decides clamp vs. halt
    ...

# Injected-tier module consumes it exactly like any other ADR-0001 dependency:
@export var config: <System>Config
func setup() -> void:
    var issues := config.validate()
    # ... clamp-or-halt per the two-tier rule above

# Autoload-tier module loads its own, with no injection layer:
const CONFIG_PATH := "res://data/config/time_tick_config.tres"
var config: TimeTickConfig
func setup() -> void:
    config = load(CONFIG_PATH) as TimeTickConfig
```

## Alternatives Considered

### Alternative A: Custom `Resource`-derived config classes (`.tres`) — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: typed fields (compile-time-checked in GDScript's static-typing mode), native Inspector editing for designers, `.tres` is human-readable/git-diffable text by default, trivially constructable in tests (`Resource.new()`, no file I/O), and matches the idiom Resource & Item Database's own GDD already committed to ("Definitions authored as external data resources").
- **Cons**: one small class per module (~9-11 classes) is more upfront authoring than a single shared `ConfigFile`; the shared-cached-instance mutation gotcha (addressed above) must be understood project-wide.
- **Rejection Reason**: N/A — chosen.

### Alternative B: `ConfigFile` (Godot's built-in INI-style key/value API)
- **Description**: one or more `.cfg`/`.ini` files read via `ConfigFile.load()`, values retrieved by string key (`config.get_value("time_tick", "ticks_per_second", 2.0)`).
- **Pros**: zero custom classes to author, built into the engine, no Resource-caching gotcha since `ConfigFile` instances aren't implicitly shared the way loaded Resources are.
- **Cons**: every field access is a stringly-typed lookup (`get_value("section", "key")`) — no compile-time checking, no static typing, no Inspector editing, and typos in section/key strings fail silently at runtime (returns the default) rather than erroring. Directly works against this project's "static typing enforced" standard.
- **Rejection Reason**: trades away static-typing safety for marginal authoring convenience; the typo-silently-returns-default failure mode is a real risk for a project with 300+ tuning values across 11+ systems.

### Alternative C: Plain JSON / custom-parsed data files
- **Description**: hand-rolled JSON files per system, parsed with `JSON.parse_string()` into `Dictionary`, manually validated.
- **Pros**: most portable/tool-agnostic format, easiest to hand-edit outside the Godot editor, no engine-Resource-caching gotchas.
- **Cons**: throws away Godot's native typed-Resource system and Inspector editing entirely; every module needs its own manual `Dictionary`-to-typed-fields conversion and validation boilerplate that `Resource`'s `@export` system provides for free; inconsistent with Resource & Item Database's already-established "external data resources" idiom.
- **Rejection Reason**: reinvents a weaker version of what `Resource`/`.tres` already provides natively, for no constraint this project actually has (nothing here requires non-Godot tooling to edit config).

## Consequences

### Positive
- One mechanism, ~9-11 small config classes, typed fields throughout — no stringly-typed lookups anywhere in the tuning-data path.
- Designers/tuners can edit `.tres` files in the Godot Inspector without touching code, and diffs stay readable in git (`.tres` is text).
- Config Resources are trivially mockable in tests (`SomeConfig.new()` with fields set directly), satisfying every GDD's testability bar with zero extra mechanism beyond ADR-0001's existing injection pattern.
- Reuses Resource & Item Database's already-accepted "terminal boot-halt" severity model for blocking invariants rather than inventing a second one.

### Negative
- ~9-11 small boilerplate classes to author and maintain (one per module with tuning knobs) — mitigated by their small size (a handful of `@export` fields + one `validate()` method each).
- The shared-cached-Resource-instance behavior is a genuine Godot gotcha that a new contributor could violate by accident (writing to a config field expecting it to be instance-local). Mitigated by the explicit immutability rule above and by making it a `/code-review` checklist item.

### Risks
- **Risk** (engine-specific, confirmed in specialist review): `load()`/`preload()` returns Godot's `ResourceLoader`-cached, shared Resource instance for as long as at least one strong reference to it stays alive — a runtime write to any config field is visible to every other holder of that same Resource, project-wide, silently.
  **Mitigation**: the immutability rule above is absolute — config is read-only after `validate()`/clamp completes at boot. Grep-verifiable in code review (`grep -rn "config\.\w* *=" src/` outside each config class's own `validate()`/clamp logic should return zero matches).
- **Risk** (minor, engine-specific): Godot's project export process converts text (`.tres`) resources to binary form inside the exported `.pck` by default — an export-pipeline step, not a save-time flag.
  **Mitigation**: this doesn't touch source-controlled `.tres` files or contradict the diffability goal; noted so a binary resource observed inside an exported build is never mistaken for a violation of this ADR's text-format rule.
- **Risk**: a GDD's blocking invariant (e.g. the ladder-ordering or `max_room_height`≥`wall_height` checks) spans TWO different modules' config Resources, but each module only validates its own — a cross-module invariant could silently go unchecked if each module's `validate()` only sees its own fields.
  **Mitigation**: cross-module invariants are validated by whichever module's GDD explicitly states the invariant (build-validation-navigability.md states the `max_room_height`≥`wall_height` check, so Build Validation's `setup()` reads both its own config AND Building System's config — an intentional, narrow exception to per-module isolation, not a general pattern). This must be called out per-instance in the relevant module's implementation story, not solved generically here.
- **Risk**: config file sprawl as more systems are added post-MVP (21 more systems planned) — mitigated by the same reasoning as ADR-0001's Autoload-tier-sprawl risk: not a Foundation-blocking concern for 11 MVP modules, revisit only if it becomes unwieldy.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`): checked `VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` — no `ResourceLoader`/caching/`@export`-resolution changes are listed across 4.4→4.7, so this subsystem's behavior is unchanged from general Godot 4.x documentation. Confirmed the shared-cached-instance claim is accurate (via `ResourceLoader`'s default `CACHE_MODE_REUSE`, refcounted as described in the Immutability Rule above) and that `.tres` vs `.res` is purely extension-driven with no other 4.7 mechanism overriding it at the source level. One verdict note from the review: "safe to accept with a minor precision edit — not a rework; the core architecture and its central engine claim are correct." Both flagged precisions (refcounted-cache wording, export-conversion footnote) are applied above.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| scene-world-management.md | TR-scene-world-management-030: "All transition tunables read from data/config, never literals" | `SceneWorldManagerConfig` Resource, injected via ADR-0001's `@export` pattern |
| voxel-world.md | TR-voxel-world-023: "World/terrain tuning values read from config, never hardcoded" | `VoxelWorldConfig` Resource |
| camera-input.md | TR-camera-input-019: "All tuning-knob values read from config/exported vars, not hardcoded" | `CameraInputConfig` Resource |
| time-tick-system.md | TR-time-tick-system-020: "All tunables read from config, not hardcoded" | `TimeTickConfig` Resource, loaded directly (Autoload-tier, no injection per ADR-0001) |
| building-system.md | TR-building-system-038: "All tuning knobs must be externally data-driven, no hardcoding" | `BuildingSystemConfig` Resource |
| building-ui.md | TR-building-ui-037: "All numeric UI-behavior values must be externally data-driven config, not hardcoded" | `BuildingUIConfig` Resource |
| needs-mood-system.md | TR-needs-mood-system-020: "Config-load-time blocking validation of the ladder-ordering invariant" | `validate()`'s blocking-tier path, reusing Resource & Item Database's accepted terminal-halt severity model |
| build-validation-navigability.md | TR-build-validation-navigability-016: "Config-load-time blocking validation: `max_room_height` ≥ Building System's max `wall_height`" | `validate()`'s blocking-tier path; the cross-module exception documented in Risks above |
| *(all remaining GDDs)* | Every GDD's Tuning Knobs section carries the same "data-driven, never hardcoded" clause per `coding-standards.md`'s mandatory 8-section GDD structure | Same `Resource`-derived config pattern applies uniformly; not individually enumerated here since the mechanism is identical |

## Performance Implications
- **CPU**: Negligible — `Resource` loading happens once at boot via `load()`/`preload()`; field access afterward is a plain property read, no different from any other typed field.
- **Memory**: Negligible — ~9-11 small Resource instances, a handful of scalar/array fields each.
- **Load Time**: Config loading adds to the existing boot sequence (architecture.md Phase 3, Data Flow) at the same point Resource & Item Database's own validation already runs — no new boot-order stage, just additional work inside the existing gate.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code. `.tres` config files are authored alongside each module's first `/dev-story` implementation, with defaults taken directly from the owning GDD's Tuning Knobs section.

## Validation Criteria
- Every module with a Tuning Knobs section has a corresponding `<System>Config` Resource class with one `@export` field per knob, defaulted to the GDD-stated value.
- Every config class's `validate()` is exercised by at least one unit test per blocking invariant named in its GDD (needs-mood's ladder-ordering, build-validation's height invariant).
- No config field is ever written to outside a `validate()`/clamp call — grep-verifiable per the Risks section above.
- All config files use the `.tres` extension (never `.res`) — verifiable via `find res://data/config -name "*.res"` returning zero results.

## Related Decisions
- Depends on ADR-0001 (Inter-System Reference & Dependency-Injection Pattern) for the injection mechanism.
- Reuses the terminal boot-halt severity model already implicit in `resource-item-database.md`'s Failed state (not yet its own ADR — Resource & Item Database's own boot-validation behavior may warrant a dedicated ADR later if it grows more complex; out of scope here).
- ADR-0005 "Boot Sequencing & System Initialization Gate" (authored 2026-07-11, Proposed) specifies exactly when `validate()` runs relative to Resource & Item Database's Ready gate.
- Feeds `docs/architecture/control-manifest.md` (not yet created) as a per-layer Required rule ("tuning values live in a `<System>Config` Resource, never a literal").
