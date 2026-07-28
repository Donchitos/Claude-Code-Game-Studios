# ADR-0006: Data Definition Immutability & Reference Format

## Status
Accepted (2026-07-11 — per architecture-review-2026-07-11 recommendation; user-delegated decision. Not spike-gated and no dependency on a spike-gated ADR.)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Data / Resources |
| **Knowledge Risk** | MEDIUM — same domain as ADR-0002 (`duplicate_deep()` 4.5+, `FileAccess` 4.4 changes), though the chosen mechanism avoids needing Resource duplication at all |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None — the chosen mechanism deliberately avoids `duplicate_deep()` (4.5+) entirely, see Decision |
| **Verification Required** | Confirmed via `godot-specialist` validation (2026-07-11) — `RefCounted`-wrapping-a-`Resource` pattern is valid with no lifecycle gotcha; typed `Mesh` export behaves as expected. One overstated claim corrected (GDScript's `Object.get()`/`set()` bypasses getter-only designs). See Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Tuning/Config Data Strategy) — item definitions follow the same `Resource`/`.tres` authoring idiom already established for config data, and ADR-0001 for the Autoload-tier no-injection status of Resource & Item Database itself |
| **Enables** | Resource & Item Database `/dev-story` implementation, and every consumer of `get_by_id()` (Building System, Building UI, Voxel World's opaque id storage) |
| **Blocks** | Resource & Item Database implementation specifically |
| **Ordering Note** | None beyond depending on ADR-0002 |

## Context

### Problem Statement
Resource & Item Database's GDD requires two things this ADR must settle: (1) returned item definitions must be immutable to callers — "caller mutation must never affect subsequent queries" (TR-resource-item-database-010), with the mechanism explicitly deferred to a data-architecture ADR; (2) the `visual_asset` field must resolve to an existing asset at boot, with the reference mechanism (path-string vs. typed-Resource) explicitly deferred to a data-format ADR (TR-resource-item-database-023). Scope note: how *other systems* reference RID entries (always by opaque string id, never a direct Resource reference — TR-resource-item-database-020/021) is already settled by the GDDs themselves and is not part of this ADR.

### Constraints
- Item definitions are authored as external data resources (TR-resource-item-database-002), matching ADR-0002's established `Resource`/`.tres` idiom
- `get_by_id()` is called pervasively across gameplay (every UI palette render, every placement validity check, every furniture query) — far more frequently than config data, which is read once at boot per module
- Definitions must remain editable in the Godot Inspector for designer authoring (a `.tres` file is hand- or Inspector-edited, same as ADR-0002's config files)
- No GDScript language feature natively enforces "this Resource's fields cannot be written to externally" — whatever guarantee this ADR establishes must be structural (a type with no setters), not a documented convention alone, since RID's own GDD explicitly asked for a "mechanism"

### Requirements
- `get_by_id()`'s return value must have no code path by which a caller can mutate the canonical stored definition, ever
- The mechanism should not impose a real allocation/duplication cost on every one of RID's (frequent) queries if avoidable
- `visual_asset` resolution must fail boot validation cleanly if the referenced asset is missing, per RID's existing terminal-halt severity model (already established, not re-litigated here)

## Decision

**Two-type split: a private, freely `@export`-editable `ItemDefinitionResource` for authoring/storage, and a public, getter-only `ItemDefinition` view that `get_by_id()` returns — wrapping, not copying, the stored data. `visual_asset` is a typed `Mesh` reference, not a path string.**

**1. Internal authorable type — `ItemDefinitionResource` (private to RID's implementation).**
```gdscript
class_name ItemDefinitionResource extends Resource
@export var id: StringName
@export var display_name: String
@export var category: StringName
@export var material_family: StringName
@export var tier: int
@export var visual_asset: Mesh
@export var stackable: bool
@export var max_stack_size: int
@export var haulable: bool
@export var storage_category: StringName
```
This is exactly the `.tres`-authored type designers edit in the Inspector — freely settable, matching ADR-0002's established pattern precisely. RID loads a collection of these at boot as part of its existing `Unloaded → Validating → Ready | Failed` pipeline; nothing outside RID's own implementation ever holds a direct reference to an `ItemDefinitionResource`.

**2. Public query type — `ItemDefinition` (what `get_by_id()` actually returns).**
```gdscript
class_name ItemDefinition extends RefCounted
var _source: ItemDefinitionResource  # private; never exposed

func _init(source: ItemDefinitionResource) -> void:
    _source = source

func get_id() -> StringName: return _source.id
func get_display_name() -> String: return _source.display_name
func get_category() -> StringName: return _source.category
func get_material_family() -> StringName: return _source.material_family
func get_tier() -> int: return _source.tier
func get_visual_asset() -> Mesh: return _source.visual_asset
func get_stackable() -> bool: return _source.stackable
func get_max_stack_size() -> int: return _source.max_stack_size
func get_haulable() -> bool: return _source.haulable
func get_storage_category() -> StringName: return _source.storage_category
```
`ItemDefinition` has **no setters anywhere in its type** — not "setters that no-op," not "setters that error," simply none exist. This closes off all *idiomatic* mutation paths: no property syntax (`def.display_name = "x"` doesn't compile, there's no such property), no method call. It does **not** close off `Object.get()`/`Object.set()` generic string-keyed property access, which GDScript permits on any script-level `var` regardless of a `_`-prefix naming convention or static typing elsewhere in the project — `wrapper.get("_source")` would still return the live, shared `ItemDefinitionResource`, and static typing does not prevent this because `get()`/`set()` operate on `Variant`. This mechanism is therefore accurately described as protection against accidental or idiomatic misuse (the overwhelming majority of real mistakes), not a hard guarantee against deliberate reflection-based bypass — see Risks. `get_by_id()` constructs a fresh, lightweight `ItemDefinition` wrapper per call (a `RefCounted`, not a `Resource` — cheaper than duplicating a full Resource, no `@export`/serialization metadata overhead) around the *same* stored `ItemDefinitionResource`; this is deliberately not a defensive copy, since the wrapper's getter-only surface makes copying unnecessary for the mutation paths it actually closes.

**3. `visual_asset` is a typed `Mesh` reference, authored via drag-and-drop in the Inspector — not a path string.** This matches ADR-0003's ghost-preview design (pooled `MeshInstance3D` nodes reusing "the same mesh assets as the MeshLibrary items") and ADR-0003's boot-time MeshLibrary population (iterating RID's ids to register each `visual_asset` mesh into GridMap's palette). RID's existing boot validation pipeline (TR-resource-item-database-005) adds one check: `visual_asset != null` for every entry, treated as a validation failure under the already-accepted terminal-halt severity model — no new severity mechanism needed, just one more check in the existing pipeline.

### Architecture Diagram
```
Authoring (design time, Inspector-edited):
  res://data/items/wood_block.tres  (ItemDefinitionResource, freely @export-editable)
        │
        ▼  loaded once at boot, validated (existing RID pipeline + new
        │  visual_asset != null check)
        ▼
RID's internal storage:
  Dictionary[StringName, ItemDefinitionResource]  (never exposed directly)
        │
        │  get_by_id(id) constructs a fresh wrapper per call:
        ▼
  ItemDefinition (RefCounted, getter-only, wraps the SAME stored
  ItemDefinitionResource — no duplication, no exposed setters, no way for
  a caller to reach the underlying Resource through the wrapper)
        │
        ▼
  Callers (Building System, Building UI, etc.) — read-only, always
```

### Key Interfaces
```gdscript
# RID's public API (extends what's already in architecture.md's API Boundaries):
func get_by_id(id: StringName) -> ItemDefinition:
    var source := _definitions.get(id, _missing_item_resource)
    return ItemDefinition.new(source)
# every other lookup method (list_ids_by_category, etc.) is unaffected —
# they return Array[StringName], not definitions, per architecture.md

# ItemDefinition itself: see Decision §2 — getter-only, no setters, ever.
```

## Alternatives Considered

### Alternative A: Getter-only wrapper (`RefCounted`, wraps shared data) — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: no per-query duplication cost (cheaper than copying a full `Resource`); closes off every idiomatic mutation path (no setters exist, not just unused ones — reflection-based `Object.get()`/`set()` bypass remains theoretically possible, see Risks, but is not an idiomatic or accidental vector); clean separation between the authorable type (designers touch) and the query type (gameplay code touches).
- **Cons**: two types to maintain in lockstep (`ItemDefinitionResource`'s fields and `ItemDefinition`'s getters must stay synchronized — a missed getter when a field is added is a real but easily-caught-in-review gap); callers use method calls (`def.get_display_name()`) rather than direct property access (`def.display_name`), a small ergonomics cost versus idiomatic GDScript property style.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Defensive copy via `duplicate()`
- **Description**: `get_by_id()` returns `_source.duplicate()` — a shallow copy of the `ItemDefinitionResource` itself, still a plain `@export`-field Resource with normal setters.
- **Pros**: simpler to implement (one method call, no second type); preserves idiomatic property-access syntax (`def.display_name`).
- **Cons**: "immutable in effect, not in interface" — the returned copy still has ordinary public setters, so a caller could write `def.display_name = "x"` and have it silently succeed on their local copy (confusing — it looks like it worked, it just doesn't propagate anywhere), which is a worse failure mode than a compile-time "no such method" error. Costs a `Resource` allocation (with its full `@export`/serialization metadata overhead) on every one of RID's frequent queries, not just occasionally.
- **Rejection Reason**: weaker guarantee (misleading silent-success mutation) at a real, avoidable per-query cost, for a data type queried far more often than config.

### Alternative C: Read-only property syntax on the same type (`get =`/no-op or error `set =`)
- **Description**: give `ItemDefinitionResource` itself no-op or error-raising custom setters (`var display_name: String: get: return _display_name, set(v): pass`), and return the same instance from `get_by_id()` directly — no second type needed.
- **Pros**: idiomatic property-access syntax preserved, no second type to maintain, no per-query cost.
- **Cons**: the SAME type is used for both authoring (Inspector-edited `.tres` files, which need genuinely settable fields) and runtime querying (which needs them unsettable) — a no-op/error setter would either break in-editor authoring (designer can't actually edit the field anymore) or require a separate "authoring mode" flag on the class, which is exactly the kind of implicit, easy-to-get-wrong state this project's other ADRs (0001, 0005) have consistently avoided in favor of structural guarantees.
- **Rejection Reason**: the authoring/runtime tension is a real conflict this alternative doesn't resolve cleanly; the two-type split (Alternative A) resolves it by construction instead.

## Consequences

### Positive
- `TR-resource-item-database-010`'s "caller mutation must never affect subsequent queries" holds against every idiomatic mutation path (property assignment, method calls) by construction — no such path exists on `ItemDefinition` to test against, not just a passing test today that could regress later. (Deliberate `Object.get()`/`set()` reflection bypass is a separate, documented residual risk — see Risks.)
- Cheaper per-query cost than a defensive-copy approach, despite the stronger guarantee.
- `visual_asset` as a typed `Mesh` reference matches ADR-0003's ghost-rendering and MeshLibrary-population design exactly — no translation layer needed between RID's data and Voxel World's rendering.

### Negative
- Two types (`ItemDefinitionResource`, `ItemDefinition`) must be kept in sync as fields are added post-MVP — a missed getter is a real (if easily caught) maintenance seam.
- Slightly less idiomatic call sites (`def.get_display_name()` vs. `def.display_name`) — a readability trade-off accepted for the stronger guarantee.

### Risks
- **Risk** (found during engine-specialist validation — wording corrected, not a design change): GDScript's `Object.get(StringName)`/`Object.set()` generic property access can reach `ItemDefinition`'s private `_source` field despite the `_` naming convention and no exposed getter — `wrapper.get("_source")` returns the live, shared `ItemDefinitionResource`, and static typing does not prevent this (it's a compile-time/IDE aid, not a runtime access-control mechanism). This means the immutability guarantee is real against accidental/idiomatic misuse but not against deliberate reflection-based bypass.
  **Mitigation**: this class of deliberate bypass is not a realistic accidental-mistake vector (no GDScript code naturally reaches for `.get("_source")` on a typed wrapper class), and this project's code review already checks for forbidden patterns via grep per every prior ADR's Validation Criteria — a `grep -rn '\.get("_source")\|\.get(&"_source")'` check can be added as a mechanical safeguard if this is ever a concern in practice. Not blocking for MVP.
- **Risk** (found during engine-specialist validation): if the `.tres` file backing an `ItemDefinitionResource` has a missing `[ext_resource]` reference for `visual_asset` (the referenced mesh file no longer exists), the *entire* `ItemDefinitionResource` load can fail and return `null` before the `visual_asset != null` field check ever runs — a missing-mesh failure could otherwise present as a generic "entry failed to load" rather than the specific "visual_asset unresolved" diagnostic TR-resource-item-database-023 implies.
  **Mitigation**: RID's boot pipeline must check that the `ItemDefinitionResource` itself loaded successfully (non-null) before checking its `visual_asset` field, and report a distinct diagnostic for "resource failed to load entirely" vs. "resource loaded but visual_asset is null" — both are boot-halt failures either way, but the structured validation result (TR-resource-item-database-007) should distinguish them for a useful error message.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed the `RefCounted`-wrapping-a-`Resource` pattern is valid, idiomatic, and has no reference-cycle or lifecycle gotcha (one-directional reference, `Resource`'s own refcount keeps it alive). Confirmed typed `@export var visual_asset: Mesh` behaves as expected in the 4.7 Inspector. **Found one overstated claim in the first draft**: the "no code path, accidental or deliberate" immutability wording was inaccurate — GDScript's `Object.get()`/`set()` generic property access bypasses the getter-only design regardless of static typing, since it operates on `Variant` rather than respecting compile-time types. Wording corrected throughout to accurately scope the guarantee to accidental/idiomatic misuse. Also flagged the boot-pipeline caveat about `.tres` load failure vs. field-level null check, addressed above. Verdict: "needs a specific correction... the mechanism itself... is sound and safe to accept once that claim is scoped correctly." Both corrections applied.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| resource-item-database.md | TR-resource-item-database-010: "Returned definitions must be immutable to callers... caller mutation must never affect subsequent queries" | `ItemDefinition`'s getter-only design, Decision §2 |
| resource-item-database.md | TR-resource-item-database-023: "`visual_asset` reference must resolve to an existing asset at boot; unresolved references fail boot validation" | Typed `Mesh` reference + `visual_asset != null` boot check, Decision §3 |

## Performance Implications
- **CPU**: One lightweight `RefCounted` allocation per `get_by_id()` call — cheaper than a `Resource.duplicate()` (no serialization/`@export` metadata overhead), and unmeasured but expected negligible against the 16.6ms frame budget even under frequent UI palette queries.
- **Memory**: Wrapper objects are short-lived (typically used and discarded within the same function call) — no accumulation risk.
- **Load Time**: Unaffected — boot-time loading/validation is unchanged by this ADR, only the post-boot query path.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code.

## Validation Criteria
- `ItemDefinition`'s class definition contains zero `func set_*` methods and zero writable `var` properties — grep/static-analysis-verifiable.
- A unit test calls `get_by_id()` twice for the same id and asserts the two returned `ItemDefinition` instances reflect identical underlying data (proving they share, not diverge from, the canonical source) — while also asserting `ItemDefinition` exposes no *idiomatic* method or property that could be used to change that data (property assignment and method-call surfaces only; reflection-based `Object.get()`/`set()` bypass is a documented residual risk, not something a unit test is expected to close off).
- Every field in `ItemDefinitionResource` has a corresponding getter in `ItemDefinition` — a code-review checklist item.

## Related Decisions
- Depends on ADR-0002 for the `Resource`/`.tres` authoring idiom `ItemDefinitionResource` follows.
- Depends on ADR-0001 for RID's Autoload-tier, no-injection status (this ADR only concerns RID's *return type*, not how RID itself is referenced).
- Informs ADR-0003's MeshLibrary-population boot step (`visual_asset` as a typed `Mesh` is exactly what that step consumes).
