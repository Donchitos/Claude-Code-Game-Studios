# ADR-0001: Inter-System Reference & Dependency-Injection Pattern

## Status
Accepted (2026-07-11 — per architecture-review-2026-07-11 recommendation; user-delegated decision. Not spike-gated and no dependency on a spike-gated ADR.)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | MEDIUM — no dedicated engine-reference module exists for this domain; relies on `breaking-changes.md`, `deprecated-apis.md`, and `current-best-practices.md`'s GDScript sections |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None required for MVP. `@abstract` decorator (4.5+) is a candidate tool if a shared interface base class is added later — see Risks. |
| **Verification Required** | Confirmed via `godot-specialist` validation pass (2026-07-11): typed custom-class `@export` properties behave normally in the 4.7 Inspector; scene-tree `_ready()` ordering (children before parents) is unchanged and is the actual hazard this ADR must design around, not a version regression. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — first ADR for this project |
| **Enables** | Every subsequent Required ADR (see `docs/architecture/architecture.md` "Required ADRs") and every implementation story across all 11 MVP systems |
| **Blocks** | All `/dev-story` implementation work — every module's API Boundaries (`architecture.md` Phase 4) presuppose this pattern is settled |
| **Ordering Note** | Must be Accepted before any other Foundation/Core ADR is implemented, though other ADRs (e.g. Voxel World Rendering) can be drafted in parallel since they don't depend on this pattern's specifics, only its existence |

## Context

### Problem Statement
Every MVP module's API boundary (defined in `docs/architecture/architecture.md` Phase 4) assumes some module can call into another — Building System calls Voxel World's `bulk_write`, Villager AI calls Needs & Mood's `start_recovery`, Building UI reads Build Validation's queryable state, and so on. Godot's idiomatic answer (Autoload singletons) creates hard global references that are difficult to substitute with test doubles. Multiple GDDs explicitly require headless mockability as a BLOCKING test-evidence tier (Building UI TR-038, Villager Info UI TR-023) or dependency-injected components for determinism (Villager AI's RNG TR-016, Resource & Item Database's testable validation TR-007, Needs & Mood's live-pair integration infra TR-025). A single, project-wide answer is needed before any module is implemented, or five programmers will invent five different wiring patterns.

### Constraints
- Godot 4.7-stable / GDScript, static typing enforced (`technical-preferences.md`)
- "All public methods must be unit-testable (dependency injection over singletons)" — already a project-wide mandate in `coding-standards.md`, not this ADR's opinion
- Solo/small-team project — must stay low-boilerplate; heavyweight DI frameworks/reflection are disproportionate
- 11 MVP modules today, 21 more systems planned post-MVP — the pattern must scale without a rewrite

### Requirements
- Every module with a testability requirement in its GDD must be instantiable in isolation with mocked collaborators, in a headless test run
- Foundation-layer systems that are genuinely single-instance and boot-early (Time & Tick, Resource & Item Database) must remain simple to reach from anywhere without threading a reference through every constructor
- The pattern must not silently violate the Module Ownership boundaries already established (a module must not gain the ability to reach into another's private state just because a reference exists)
- Wiring must not depend on script-level `_ready()` execution order, since Godot resolves the scene tree bottom-up (children's `_ready()` runs before their parent's)

## Decision

**Hybrid model**: Godot Autoload singletons for genuinely-global Foundation services; scene-file-resolved `@export` dependency injection for everything with a same-session testability requirement.

**Autoload tier** — registered as Godot Autoloads, called by their global name directly in production code, everywhere, with no injection layer at all:
- `TimeTickSystem` — one process-wide clock, no meaningful "instance" concept, and its own GDD carries no per-test-substitution requirement (a test can simply call `TimeTickSystem.tick.emit()` or read `get_game_delta()` on the real Autoload — it's pure and deterministic once loaded)
- `ResourceItemDatabase` — one process-wide, boot-validated, read-only catalog; its own GDD's testability requirement (TR-resource-item-database-007) targets the *validation pipeline*, which is a pure function returning a structured result — testable independently of how the catalog is reached at runtime

These two are conceptually equivalent to Godot's own `Input` or `Time` singletons — global engine-adjacent services, not gameplay logic under test. **Production code calls them by global name directly** (`ResourceItemDatabase.get_by_id(id)`, `TimeTickSystem.get_game_delta()`) — there is no `@export`-injected reference to either, anywhere, ever. Keeping this absolute avoids the dual-access-path confusion (a module accidentally reachable both via injection and via global name) that a partial exemption would invite.

**Injected tier** — Scene/World Management, Voxel World, Camera & Input, Building System, Villager AI, Build Validation & Navigability, Needs & Mood, Building UI, Villager Info UI: each module exposes its Core/Feature dependencies as **typed `@export` node-reference properties**, resolved by a single top-level `GameWorld` root scene (owned by Scene/World Management, matching its existing "World Root" ownership in `architecture.md`'s Module Ownership section).

```gdscript
class_name BuildingSystem extends Node

@export var voxel_world: VoxelWorld
@export var camera_input: CameraInput
# NOTE: no reference to ResourceItemDatabase or TimeTickSystem here —
# those are called by global Autoload name directly in method bodies.
```

**Wiring rule (the ordering fix)**: `@export` references between injected-tier modules are assigned **exclusively via the scene file itself** — i.e., wired in the Godot editor Inspector on `GameWorld.tscn`, which Godot resolves during scene deserialization, *before* any child's `_ready()` runs. No injected-tier module may read its `@export` dependencies inside its own `_ready()` under the assumption another script assigned them there — scene-file-assigned exports are already populated by the time `_ready()` fires, but *code-assigned* wiring (e.g. inside `GameWorld._ready()`) is not, because Godot calls `_ready()` bottom-up (children before parents). If a dependency genuinely cannot be wired in the scene file (e.g. it's only known at runtime), `GameWorld` must call an explicit `module.setup(dependency)` method on the child *after* assignment — never rely on `_ready()` timing for anything code-assigned.

**Test-path parity (the `_ready()`-skipped gotcha)**: `SomeModule.new()` in a headless unit test never enters the `SceneTree`, so `_ready()` never runs at all in that context. Any wiring-validation or setup logic must therefore live in the same explicitly-callable `setup()` method that `GameWorld` invokes in production — never in `_ready()` — so the exact same code path is exercised in both a real scene and a headless test. A test instantiates the module directly, assigns mock objects to its `@export` properties (or passes them to `setup()`), and calls `setup()`/methods directly — no scene tree, no Autoload bootstrap.

### Architecture Diagram
```
Autoload tier (global name, called directly in method bodies, never injected):
  TimeTickSystem          ResourceItemDatabase
        ▲                        ▲
        │ TimeTickSystem.get_game_delta()   ResourceItemDatabase.get_by_id(id)
        │ (called directly, everywhere)     (called directly, everywhere)
        │
Injected tier (wired via GameWorld.tscn's Inspector — scene-file-resolved,
before any child's _ready() fires; setup() used only for runtime-only deps):
  SceneWorldManager ──┐
  VoxelWorld ─────────┼──► BuildingSystem ──► VillagerAI ──► NeedsAndMood
  CameraInput ─────────┘         │                 │
                                  ▼                 ▼
                          BuildValidation ◄── (walkability read)
                                  │
                          BuildingUI, VillagerInfoUI (read everything above)

GameWorld.tscn (root scene, owned by Scene/World Management):
  All injected-tier nodes are children; @export references between them are
  assigned in the Inspector (scene file), resolved at deserialization time —
  NOT in GameWorld._ready(). Any runtime-only wiring uses an explicit
  module.setup(dep) call, invoked identically by GameWorld and by tests.
```

### Key Interfaces
```gdscript
# Injected-tier module shape:
class_name BuildingSystem extends Node
@export var voxel_world: VoxelWorld
@export var camera_input: CameraInput
func setup() -> void:
    # Called explicitly by GameWorld after scene-file wiring, and identically
    # by headless tests after assigning mocks — NEVER relies on _ready() order.
    assert(voxel_world != null, "BuildingSystem.voxel_world not wired")

# Autoload-tier modules: called by global name directly, everywhere,
# with no @export reference anywhere in the codebase:
ResourceItemDatabase.get_by_id(&"wood_block")
TimeTickSystem.get_game_delta()
```

## Alternatives Considered

### Alternative A: Pure Autoload singletons
- **Description**: all 11 modules registered as Godot Autoloads, referenced globally by name everywhere (`BuildingSystem.claim_job(...)`).
- **Pros**: zero scene-wiring boilerplate, the pattern most Godot tutorials and the engine itself encourage, no ordering to hand-manage beyond Autoload load order.
- **Cons**: cannot substitute a mock collaborator without either monkeypatching Autoloads (a hard dependency on a specific test framework's mechanism) or reloading the whole Autoload tree per test. Directly violates the project's own `coding-standards.md` mandate and would fail Building UI's and Villager Info UI's BLOCKING headless-mock test-evidence requirement outright.
- **Rejection Reason**: contradicts an explicit, pre-existing, non-negotiable project standard. Not a close call.

### Alternative B: Pure dependency injection (no Autoloads at all)
- **Description**: every module, including Time & Tick and Resource & Item Database, is instantiated and wired by `GameWorld`; nothing is a global.
- **Pros**: maximally consistent (one pattern, no tiering to remember), maximally testable.
- **Cons**: Time & Tick and Resource & Item Database are read from everywhere, including deep inside UI code paths and likely future systems not yet designed (Save/Load, Audio System). Threading an explicit reference to them through every constructor in every future system is exactly the boilerplate the "low-boilerplate" constraint rules out, for two services whose own GDDs never asked for test substitution.
- **Rejection Reason**: over-applies a solution to a problem two of the eleven modules don't have, at a real ongoing authoring cost as the system count grows toward 32.

### Alternative C: Hybrid (Autoload for genuinely-global Foundation services, injection for everything else) — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: matches the actual shape of the testability requirements found in the GDDs (they cluster on Core/Feature/Presentation modules, not on Time & Tick or Resource & Item Database); keeps the two lowest-boilerplate, most-referenced services trivially reachable; satisfies `coding-standards.md` exactly where its rationale (test isolation) applies.
- **Cons**: two patterns to remember instead of one; a future contributor could misclassify a new system into the wrong tier. Mitigated by the explicit tier-membership rule above and by this ADR being cited in `docs/architecture/control-manifest.md` (produced next via `/create-control-manifest`).
- **Rejection Reason**: N/A — chosen.

## Consequences

### Positive
- Every GDD's headless-mockability requirement (Building UI, Villager Info UI, Resource & Item Database's validation, Villager AI's RNG, Needs & Mood's live-pair test infra) is satisfiable with plain GDScript, no third-party DI framework.
- `GameWorld.tscn`'s Inspector wiring becomes the single place that documents the full module dependency graph in actual project data — matching (and enforcing) the Module Ownership dependency diagram already in `architecture.md`.
- Adding a 12th, 13th... module (Vertical Slice/Alpha systems) has an unambiguous default: injected tier, unless it is a genuinely single-instance, boot-early, no-mock-requirement service like the existing two.
- The absolute "Autoloads are never injected" rule eliminates the dual-access-path confusion the engine specialist review flagged in an earlier draft.

### Negative
- `GameWorld.tscn`'s Inspector wiring is a load-bearing piece of scene data that must stay in sync with every new module — a missed wire-up is a silent null reference at runtime (caught only by the `setup()` assertion), not a compile error.
- Two Autoload-tier services means two special-cased places in the codebase that don't follow the "everything is injected" mental model; onboarding documentation must call this out explicitly.
- Every injected-tier module must implement the `setup()` convention rather than doing initialization in `_ready()`, which is a small but real deviation from the most common Godot tutorial pattern and needs to be documented as a project-wide rule, not left implicit.

### Risks
- **Risk**: A future system is added to the Autoload tier by convenience rather than by meeting the "genuinely global, no test-substitution need" bar, quietly reintroducing Alternative A's problems one system at a time.
  **Mitigation**: this ADR's tier-membership rule is the test; `docs/architecture/control-manifest.md` should restate it as a per-layer rule so `/dev-story` and `/code-review` check against it mechanically.
- **Risk**: `GameWorld.tscn`'s wiring grows unwieldy as more Core/Feature/Presentation modules are added post-MVP (21 more systems planned).
  **Mitigation**: not a Foundation-blocking risk for MVP (9 injected-tier modules); revisit if wiring exceeds ~30 explicit `@export` assignments — candidate follow-up ADR for a lightweight service-locator/registry pattern at that point, not before.
- **Risk** (engine-specific, confirmed in specialist review): code that assumes `_ready()` has already wired a module's dependencies will read `null`, because Godot's scene tree resolves `_ready()` bottom-up (children before parents) — a code-assigned wire-up in `GameWorld._ready()` runs *after* every child's own `_ready()` has already fired.
  **Mitigation**: the scene-file-only wiring rule + explicit `setup()` convention above is the direct fix; this must be called out in onboarding docs and checked in code review (`grep` for `@export` reads inside `_ready()` bodies is a cheap mechanical check).
- **Risk** (engine-specific, confirmed in specialist review): `SomeModule.new()` in a headless test never enters the `SceneTree`, so `_ready()` never runs — any validation/wiring-check logic placed there is silently skipped in tests but would run in production, creating a test/production behavior mismatch.
  **Mitigation**: the `setup()` convention above ensures the identical code path runs in both contexts; `_ready()` itself should do nothing beyond (optionally) calling `setup()` when running as a real scene node.
- **Risk** (watch-item, non-blocking for MVP): if a shared abstract interface base class is introduced later for any tier (e.g. a common `MockableSystem` base), use the `@abstract` decorator (4.5+) rather than a hand-rolled "not implemented" stub, and remember Godot 4.7 requires explicit `return` statements in typed-return method overrides.
  **Mitigation**: no MVP module currently needs a shared interface base class; revisit only if one is proposed.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| building-ui.md | TR-building-ui-038: "Mirror/event logic must be exercisable headless via mocked upstream signals and mocked queryable state (BLOCKING automated-test tier)" | Building UI is injected-tier; tests instantiate it directly and assign mock `BuildingSystem`/`BuildValidation`-shaped objects to its `@export` properties, then call `setup()` |
| villager-info-ui.md | TR-villager-info-ui-023: "Panel logic must support headless mocking of villager hits, tool-arm state, all six activity states... (BLOCKING automated-test tier)" | Same injected-tier mechanism; mocks assigned to `@export var villager_ai_ref`, `@export var needs_ref`, etc. |
| villager-ai-behavior.md | TR-villager-ai-behavior-016: "Dependency-injected RNG source (live RNG in production, fixed-sequence double in tests) required for deterministic wander/micro-behavior selection" | RNG is itself an injected `@export`/`setup()` parameter on the (injected-tier) Villager AI module, consistent with this ADR's general pattern |
| resource-item-database.md | TR-resource-item-database-007: "Validation produces a STRUCTURED result... returned by the validation call itself (dependency-injectable/unit-testable), not just logged" | Resource & Item Database is Autoload-tier for lookup, but its validation pipeline is a pure function returning a structured result — testable without any injection mechanism at all, satisfying this TR independently of the tier split |
| needs-mood-system.md | TR-needs-mood-system-025: "Live-pair integration-test infrastructure: real (non-mocked) Needs instance + real Villager AI villager exercised through a full decay→recovery→wake round trip" | Both Needs & Mood and Villager AI are injected-tier; a test instantiates both directly and wires them to each other without any scene tree or Autoload bootstrap, exactly the "real, non-mocked pair in isolation" the AC calls for |

## Performance Implications
- **CPU**: Negligible — `@export` property access is a plain field read, no different in cost from an Autoload global lookup. `GameWorld`'s wiring is resolved once at scene deserialization, not per-frame.
- **Memory**: Negligible — no additional allocation beyond the two Autoload singletons already required by the engine's Autoload system.
- **Load Time**: A small, fixed amount of boot-time cost (scene deserialization wiring ~9 injected-tier modules, plus each module's `setup()` call) — well within the boot-order budget already established in `architecture.md`'s Data Flow Phase 4 initialization sequence; does not change that sequence.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code. This ADR establishes the pattern before any module is implemented; `GameWorld.tscn` is created as part of the first Foundation-layer `/dev-story` work, not retrofitted.

## Validation Criteria
- Every injected-tier module can be instantiated and unit-tested with `Node.new()` + mock `@export` assignments + `setup()`, with zero scene tree and zero Autoload registration, verified by the first test file written against each module (`tests/unit/[system]/`).
- `GameWorld.tscn`'s Inspector wiring contains exactly one assignment per edge in `architecture.md`'s MVP dependency diagram (Phase 3, Data Flow) — a code review checklist item once Foundation-layer stories begin.
- No injected-tier module ever references `ResourceItemDatabase` or `TimeTickSystem` via an `@export` property — grep-verifiable (`grep -rn "@export.*ResourceItemDatabase\|@export.*TimeTickSystem" src/` should return zero matches once implementation exists).
- No injected-tier module reads an `@export` dependency inside its own `_ready()` body — grep-verifiable as a code-review check once implementation exists.

## Related Decisions
- Presupposed by every other Required ADR in `docs/architecture/architecture.md` (Required ADRs section) — none has been written yet.
- Directly implements the "dependency injection over singletons" mandate already stated in `.claude/docs/coding-standards.md`.
- Feeds `docs/architecture/control-manifest.md` (not yet created — run `/create-control-manifest` once the Foundation ADR set is written) as a per-layer Required/Forbidden rule.
