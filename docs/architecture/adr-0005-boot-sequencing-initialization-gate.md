# ADR-0005: Boot Sequencing & System Initialization Gate

## Status
Accepted (2026-07-11 — per architecture-review-2026-07-11 recommendation; user-delegated decision. Not spike-gated and no dependency on a spike-gated ADR.)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Core / Scripting (boot order) |
| **Knowledge Risk** | LOW-MEDIUM — the core claim (Autoloads fully initialize before the Main Scene is instantiated) is pre-4.3 stable Godot behavior, not a post-cutoff change, but is verified explicitly below rather than assumed |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirmed via `godot-specialist` validation (2026-07-11) — Autoload-before-Main-Scene ordering is documented, stable Godot behavior, unchanged 4.4→4.7. See Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Inter-System Reference & Dependency-Injection Pattern) — this ADR specifies exactly how `GameWorld`'s wiring/`setup()` sequence from ADR-0001 is gated |
| **Enables** | Every injected-tier module's `/dev-story` implementation — none can safely assume its dependencies (especially Resource & Item Database's item catalog) are ready without this gate |
| **Blocks** | Building System, Villager AI, and Building UI implementation specifically (the modules that actually consume RID data), though the unified gate below covers all injected-tier modules |
| **Ordering Note** | None beyond depending on ADR-0001 |

## Context

### Problem Statement
`scene-world-management.md` (TR-scene-world-management-004/023) and `resource-item-database.md` (TR-resource-item-database-019) all state that Building System and Villager AI must not initialize until Resource & Item Database (RID) reaches its `Ready` state, with `Failed` (RID's TERMINAL boot-halt, TR-resource-item-database-006) requiring a full app restart. None of these GDDs specify a concrete *mechanism* — that's this ADR's job, building directly on ADR-0001's Autoload/injection split and `setup()` convention.

### Constraints
- RID is Autoload-tier (ADR-0001) — never `@export`-injected, called by global name
- Every other MVP module (Voxel World, Camera & Input, Building System, Villager AI, Build Validation, Needs & Mood, Building UI, Villager Info UI) is injected-tier, wired via `GameWorld.tscn` and given an explicit `setup()` call (ADR-0001) — no module may assume a dependency is ready inside its own `_ready()`
- RID's `Failed` state requires a full-screen boot-halt error, no in-game recovery
- *(Revised 2026-07-11, ADR-0014: initial view-window build is ~2.6 s behind the existing transition overlay — "near-instant" no longer holds; the gate must not ADD perceptible delay beyond that build.)* Original constraint: Terrain generation (Voxel World) must run "synchronously/near-instantly... no loading screen exists at MVP" (TR-voxel-world-026) — the gate must not introduce a perceptible delay for MVP's small tier-0 dataset

### Requirements
- A concrete, code-reviewable mechanism (not just a documented convention) that prevents any injected-tier module's `setup()` from running before RID reports `Ready`
- A `Failed` path that shows the boot-halt screen and never calls any injected-tier module's `setup()`
- Must work correctly regardless of whether RID's validation completes synchronously (same frame) or takes longer (future-proofing, since RID's dataset will grow post-MVP)

## Decision

**Scene/World Management's `Booting` state (the `GameWorld` root script) gates ALL injected-tier `setup()` calls behind Resource & Item Database's `Ready`/`Failed` outcome — a single unified gate, not a per-module allowlist — using a check-then-connect pattern against RID's existing `is_ready()` getter and a new `validation_complete` signal.**

**1. Unified gate, not a narrow allowlist.** The GDDs literally name only Building System and Villager AI, but Building UI's own palette query (TR-building-ui-008) also needs RID ready, and other injected-tier modules (Voxel World, Camera & Input, Build Validation, Needs & Mood, Villager Info UI) have no RID dependency but also incur no meaningful cost from waiting — RID's MVP validation (a handful of tier-0 items) is expected to complete in low single-digit milliseconds. Gating everything uniformly eliminates an entire class of "did I forget to add the new module to the gate list" bugs as more systems are added post-MVP, at a cost expected to be imperceptible. This is an explicit extension beyond the GDDs' literally-stated scope, recorded here for traceability.

**2. RID exposes one additional signal beyond its existing API** (already specified in `architecture.md`'s API Boundaries: `is_ready() -> bool`):
```gdscript
# Resource & Item Database (Autoload):
signal validation_complete(result: ValidationResult)  # result.success: bool, result.issues: Array[ValidationIssue]
```

**3. `GameWorld`'s `Booting` state (Scene/World Management's own script — `GameWorld.tscn`'s root IS Scene/World Management's World Root, per ADR-0001's ownership note) implements a check-then-connect pattern** (a synchronous `is_ready()` check first; a `.connect(..., CONNECT_ONE_SHOT)` fallback only if not yet ready — not a literal `await`, since GDScript is single-threaded and there is no suspension point between the check and the connect call, so no race is possible either way):
```gdscript
func _ready() -> void:
    _boot_state = BootState.WAITING_FOR_DATABASE
    if ResourceItemDatabase.is_ready():
        _on_database_settled(true, [])
    else:
        ResourceItemDatabase.validation_complete.connect(
            func(result): _on_database_settled(result.success, result.issues),
            CONNECT_ONE_SHOT
        )

func _on_database_settled(success: bool, issues: Array) -> void:
    if not success:
        _show_boot_halt_screen(issues)  # reuses the existing transition-overlay
        return                           # UI infrastructure (TR-scene-world-management-032);
                                          # no injected-tier setup() is ever called
    _boot_state = BootState.WIRING
    for module in _injected_tier_modules:  # ALL of them — the unified gate
        module.setup()
    _boot_state = BootState.ACTIVE
```
The `is_ready()` check-first branch handles the confirmed-common case where RID's Autoload `_ready()` already completed validation before `GameWorld`'s own `_ready()` runs (Autoloads fully initialize — including their own `_ready()` — before the Main Scene is even added to the tree; verified below as documented, stable Godot behavior, unchanged 4.4→4.7); the `.connect(..., CONNECT_ONE_SHOT)` fallback branch handles it correctly even if that assumption is ever wrong or RID's validation becomes genuinely asynchronous post-MVP.

**4. This is not a violation of ADR-0001's "no `_ready()`-order-dependent injection" rule.** That rule governs *injected-tier child modules* reading their own dependencies inside their own `_ready()`. `GameWorld` is the orchestration root itself, not a consumer — its `_ready()` is exactly where the boot-gate coordination is expected to live, and it only calls each child's `setup()` explicitly and only after the gate resolves, which is the sanctioned pattern, not the forbidden one.

### Architecture Diagram
```
Engine boot:
  Autoloads load, in registration order (TimeTickSystem, ResourceItemDatabase)
  ResourceItemDatabase._ready() / _enter_tree() → runs Unloaded→Validating→Ready|Failed
        (expected to complete before the Main Scene is even instantiated —
         see Engine Specialist Validation)
  Main Scene (GameWorld.tscn) instantiated
        │
        ▼
  GameWorld._ready(): Booting state
        │
        ├─ ResourceItemDatabase.is_ready() == true? ──► _on_database_settled(true, [])
        │                                                       │
        └─ not ready yet ──► connect validation_complete signal ┤
                              (CONNECT_ONE_SHOT, not a literal await)
                                                                  ▼
                                                    success? ──► WIRING: call
                                                    │             setup() on ALL
                                                    │             injected-tier
                                                    │             modules → ACTIVE
                                                    ▼
                                              FAILED: show boot-halt screen
                                              (reuses transition-overlay UI),
                                              NO setup() ever called, terminal
```

### Key Interfaces
```gdscript
# Resource & Item Database (Autoload) — new addition to its existing API:
signal validation_complete(result: ValidationResult)

# GameWorld (Scene/World Management's World Root script) — internal boot logic:
enum BootState { WAITING_FOR_DATABASE, WIRING, ACTIVE, HALTED }
func _ready() -> void: ...           # check-then-await pattern, see Decision §3
func _on_database_settled(success: bool, issues: Array) -> void: ...
func _show_boot_halt_screen(issues: Array) -> void: ...
```

## Alternatives Considered

### Alternative A: Check-then-connect against `is_ready()` + `validation_complete` signal, unified gate — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: correct regardless of whether RID's validation is synchronous or async; a single code-reviewable choke point (`GameWorld._ready()`) rather than N modules each independently checking RID's state; eliminates "forgot to gate the new module" as a bug class entirely.
- **Cons**: every injected-tier module waits even if it has no RID dependency — a theoretical (expected-negligible) delay for modules that don't need it.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Narrow gate — only Building System and Villager AI wait, everything else initializes immediately
- **Description**: gate exactly the two modules the GDDs literally name; Voxel World, Camera & Input, Building UI, etc. call `setup()` unconditionally at boot.
- **Pros**: modules with no RID dependency start marginally sooner.
- **Cons**: Building UI's own palette-query requirement (TR-building-ui-008) is silently ungated despite needing RID — a real correctness gap the literal TR list misses; every future module added to the project must be manually assessed for "does this need RID" and added to (or correctly excluded from) the gate list, a recurring source of the exact kind of GDD-cross-reference gap this project's review logs have repeatedly found (see `gdd-cross-review-2026-07-10.md`'s pattern of staleness/cross-reference misses).
- **Rejection Reason**: trades a negligible, unmeasured performance gain for a real and recurring class of correctness bug.

### Alternative C: Polling instead of a signal-based connect
- **Description**: `GameWorld` polls `ResourceItemDatabase.is_ready()` every frame (or via a `Timer`) until it returns true, instead of connecting to a signal.
- **Pros**: doesn't require adding a new signal to RID's API.
- **Cons**: wastes frames polling something that, per this project's own "event-driven, not polled" architecture principle (`architecture.md`), should be a signal; adds a frame or more of latency versus an immediate signal callback; every other boot-relevant contract in this project (Scene/World Management's own transition signals, Build Validation's 4-signal bus) is signal-based, so polling here would be the one inconsistent exception.
- **Rejection Reason**: contradicts an already-established, approved architecture principle for no benefit.

## Consequences

### Positive
- One choke point (`GameWorld._ready()`) is the single place the boot gate lives — easy to audit, easy to extend as new injected-tier modules are added post-MVP.
- Correct under both synchronous and (future) asynchronous RID validation, without needing to revisit this ADR if RID's loading strategy changes later.
- Closes the Building UI gap Alternative B would have silently left open.

### Negative
- Every injected-tier module's `setup()` is delayed by however long RID validation takes, even for modules with zero RID dependency — expected negligible for MVP's small dataset, unmeasured.
- A new signal (`validation_complete`) is added to RID's API surface, which `architecture.md`'s API Boundaries section will need a follow-up edit to reflect (tracked in Related Decisions).

### Risks
- **Risk**: RID's validation cost is unmeasured; if the Alpha/Full Vision item catalog grows large enough to make validation genuinely slow, the unified gate would delay ALL injected-tier modules, not just the ones that need RID.
  **Mitigation**: not a concern at MVP scale (3 materials + bed); revisit if RID's own performance characteristics change materially post-MVP — not a blocking risk now.
**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed the central claim — Godot adds Autoload singletons as children of the root viewport, in Project-Settings-declared order, *before* the Main Scene is loaded and added; each Autoload's `_enter_tree()`/`_ready()` completes synchronously as part of that `add_child()` call, so by the time the Main Scene's own `_ready()` runs, every Autoload's `_ready()` has already finished. This is documented, stable Godot behavior, unchanged across 4.4→4.7. Found one documentation/code mismatch (not a functional bug): the first draft's prose and diagram said "await validation_complete signal" while the code used `.connect(callable, CONNECT_ONE_SHOT)` — confirmed both are valid GDScript, but the wording was inconsistent with the actual code. Corrected throughout to "check-then-connect." Verdict: "safe to accept with one correction... the core boot-order claim itself needs no correction." Applied above.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| scene-world-management.md | TR-scene-world-management-004: "Boot gate: Resource & Item Database must reach Ready before Valley attaches / Building & Villager AI initialize; DB failure halts boot on an error screen" | `GameWorld`'s `Booting` state, Decision §3 |
| scene-world-management.md | TR-scene-world-management-023: "Boot-order enforcement... (mechanism owned by a boot-order ADR)" | This ADR is that mechanism |
| resource-item-database.md | TR-resource-item-database-019: "Boot sequencing: Scene/World Management's Booting state gates on this database reaching Ready before Building System / Villager AI initialize; this system has no dependency back on Scene/World Management" | Confirmed — RID's `validation_complete` signal is a one-way notification; RID never calls into Scene/World Management |
| building-ui.md | TR-building-ui-008: "Material/furniture palette populated at runtime from Resource & Item Database queries" | Extended into the unified gate (Decision §1) despite not being in the GDDs' literal boot-gate list — an explicit, documented interpretive extension |

## Performance Implications
- **CPU**: RID validation for MVP's tier-0 dataset (3 materials + bed) is expected to complete in low single-digit milliseconds — imperceptible against boot time.
- **Memory**: Negligible — one new signal, one new enum on `GameWorld`.
- **Load Time**: The gate adds, at most, the time RID validation takes — expected sub-frame for MVP; TR-voxel-world-026's original "near-instant" requirement is superseded by ADR-0014's measured ~2.6 s initial window build (shown behind the transition overlay); the boot gate itself remains low-single-digit ms.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code.

## Validation Criteria
- A unit test constructs `GameWorld` with a mock `ResourceItemDatabase`-shaped Autoload double that reports `Failed`, and asserts zero injected-tier module `setup()` calls occur and the boot-halt screen is shown.
- A unit test constructs `GameWorld` with a mock reporting `Ready` (both via `is_ready()` returning true immediately, and via the `validation_complete` signal firing later) and asserts every injected-tier module's `setup()` is called exactly once, in both cases.
- Grep-verifiable: no injected-tier module's `setup()` call site exists outside `GameWorld`'s `Booting`-state completion path.

## Related Decisions
- Depends on ADR-0001 for the `setup()`/`GameWorld` wiring pattern this gate is built on.
- `architecture.md`'s API Boundaries section needs a follow-up edit to add RID's new `validation_complete` signal to its documented interface (not done as part of this ADR — architecture.md is a living document maintained outside individual ADRs, per its own versioning note).
