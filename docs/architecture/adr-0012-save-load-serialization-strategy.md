# ADR-0012: Save/Load Serialization Strategy

## Status
Accepted (2026-07-11 — per architecture-review-2026-07-11 recommendation; user-delegated decision. Not spike-gated and no dependency on a spike-gated ADR.)

**(Slice propagation 2026-07-23 — RESOLVED; ADR-0015 Accepted 2026-07-23)** Two impacts from the vertical-slice batch, now settled:

1. **16k save-size scaling → chunking escape hatch exercised via ADR-0015.** The persisted voxel payload scales ~64× areally at the 16k target, which would have blown a monolithic single-file save. **ADR-0015 (Large-World Storage & Residency, Accepted, spike-validated) resolves this: the save format for voxel data IS the set of region files** — chunked by construction, written/read per-region with no monolithic multi-GB pass (spike C5: 0.77 MB across 49 region files vs 7.63 GB naive; byte-identical round-trip). This is exactly this ADR's Alternative-C chunking escape hatch, now adopted for voxel storage specifically. **The per-system serialize contract below is UNCHANGED** — Voxel World's `serialize()` still owns its own format; ADR-0015 changes only *where that format lives on disk* (region files), which remains opaque to the orchestrator. The small non-voxel state (project entities, villager/needs state) still uses the plain-Dictionary `store_var` path of this ADR unchanged. Threading likewise follows ADR-0015 (region I/O is off-thread there); the orchestrator's own top-level assembly stays synchronous.

2. **New serialized state**, absorbed structurally by the "each system serializes itself" contract with no orchestrator change: Voxel World's `restore_value` (floor terrain-replace original terrain, TR-voxel-world-050); Building System's persistent **project entities** (draft/released/paused/built/demolition-queued status, `worker_ids`, change orders — formalized by ADR-0016, Accepted); and Villager AI's stuck-telemetry counters.

VS-tier, not MVP-blocking. Status stays Accepted. See `change-impact-2026-07-23-slice-batch.md`.

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Data / Resources (Save/Load) |
| **Knowledge Risk** | MEDIUM — `FileAccess.store_var()`/all `store_*` methods changed return type `void` → `bool` at 4.4 (a save-write failure is now checkable, and must be) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None beyond the already-noted 4.4 `store_*` return-type change, which this ADR's design accounts for explicitly |
| **Verification Required** | Confirmed via `godot-specialist` validation (2026-07-11) — store_var/get_var round-trip behavior and the 4.4 return-type change verified accurate; a real missing-null-check gap found and fixed. See Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Inter-System Reference & Dependency-Injection Pattern) — the new Save/Load orchestrator module is injected-tier, wired the same way as every other Core-layer module |
| **Enables** | Save/Load & World Persistence `/dev-story` implementation (Vertical Slice tier) |
| **Blocks** | Any VS-tier work depending on save/load existing (Main Menu & Settings' load-game entry point, Alpha-tier persistence needs) |
| **Ordering Note** | Not MVP-blocking — deferred until Save/Load work actually begins, per the systems-index's own Vertical Slice tier placement |

## Context

### Problem Statement
Every MVP GDD already commits to a serialization contract (`architecture.md`'s Data Flow Phase 3 table: Voxel World's occupied cells, Building System's open blueprints + progress, Villager AI's per-villager state, Needs & Mood's need/mood values, Build Validation's deliberate non-serialization), but no GDD specifies the concrete file format, chunking strategy, or threading approach. The systems-index's own High-Risk table names this directly: "Serialization approach for a large, per-block-mutable voxel world is completely unspecified; naive per-block dumps risk save-time frame hitches at scale." A carry-forward directive from the concept-to-systems-design gate already states the governing principle: "each system serializes itself" — this ADR must honor that, not re-architect it.

### Constraints
- World is explicitly bounded, not infinite/streaming (`game-concept.md`'s Anti-Pillars: "NOT a free voxel-editor... will NOT support unbounded terraforming/mining outside the settlement's buildable footprint") — a genuinely large, streaming-scale save architecture is solving a problem this project doesn't have
- *(Premise revised 2026-07-11, ADR-0014)*: Voxel World now stores packed chunk arrays (~172 MB full world measured); the save payload grows to ~150–250 MB worst case at high density. The no-chunking DECISION below still stands — `store_var` on packed arrays is a fast bulk write behind the loading overlay — but must be re-measured at VS; the chunked/async escape hatch is unchanged
- "Each system serializes itself" (carry-forward directive) — the Save/Load module must not need to understand Voxel World's cell format vs. Villager AI's record format vs. any other system's internal representation
- Population ceiling 20-30 villagers (Full Vision) — modest data volume even at scale
- Save data is never designer-authored, never Inspector-edited, and (unlike config/item data, ADR-0002/ADR-0006) never git-tracked — the format choice is not bound by ADR-0002's diff-friendliness or Inspector-editability rationale

### Requirements
- Each serializing system (Voxel World, Building System, Villager AI, Needs & Mood) exposes its own `serialize()`/`deserialize()` pair; the Save/Load module treats each system's output as opaque
- Save-write failures (disk full, permissions) must be detected, not silently swallowed
- Schema drift (a need type removed/added between game versions, per Needs & Mood's own GDD) must be handled by each owning system's `deserialize()`, not centrally
- The mechanism must not require chunking or threading unless a measured need exists — matching this project's established pattern of deferring such complexity until proven necessary (ADR-0003's chunked-mesher escape hatch, ADR-0008's threading escape hatch)

## Decision

**A plain `Dictionary` (not a custom Resource/`.tres` class) serialized via `FileAccess.store_var()`/`get_var()` to a single binary file. Each system exposes `serialize() -> Dictionary` / `deserialize(data: Dictionary) -> void`; a new Save/Load orchestrator module collects/distributes these without inspecting their contents. No chunking, no threading, for MVP/VS — both named as explicit escape hatches.**

**1. File format: plain `Dictionary` via `store_var`/`get_var`, not a Resource/`.tres` class.** ADR-0002 and ADR-0006 established `Resource`/`.tres` as this project's format for *authored, designer-edited* data (tuning config, item definitions) — Inspector-editability and git-diff-friendliness were the deciding factors there. Save data is neither: it's pure runtime state, never opened in the Godot editor, never source-controlled (a save file is user data, `.gitignore`d). Godot's `FileAccess.store_var(value)`/`get_var()` natively round-trips nested `Dictionary`/`Array`/`Variant`-compatible structures to a binary file with no custom parsing code — a better fit for this category than defining parallel `Resource` classes purely to hold a save-file schema that adds no Inspector-editing value. The top-level structure:
```gdscript
{
    "save_format_version": 1,
    "voxel_world": {},       # opaque — Voxel World's own serialize() output
    "building_system": {},   # opaque — Building System's own serialize() output
    "villager_ai": {},       # opaque — Villager AI's own serialize() output
    "needs_mood": {},        # opaque — Needs & Mood's own serialize() output
}
```
`save_format_version` exists from day one even though no migration logic exists yet (nothing to migrate at MVP/VS) — a forward-looking field, not a currently-implemented migration system.

**2. Each system serializes itself — the orchestrator never inspects contents.** Every serializing system's public API gains exactly two methods:
```gdscript
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```
The Save/Load orchestrator (a new, injected-tier module, wired per ADR-0001) calls `serialize()` on each owning system, stores the results under that system's key, and — on load — calls `deserialize(data)` back on each system with its own previously-stored dictionary. The orchestrator has zero knowledge of what's inside any system's dictionary — it is purely a collector/distributor, honoring the "each system serializes itself" carry-forward directive structurally, not by convention.

**3. No chunking.** The world is still bounded and saves hide behind the transition overlay; ADR-0014's larger payload (~150–250 MB worst case) weakens but does not break this — re-measure at VS, escape hatch ready — a single monolithic dictionary, written and read in one pass, is simple and, at this scale, fast. Chunking is named as an explicit escape hatch if a future measured need (e.g., a much larger Full Vision world scale than currently planned) proves otherwise — not adopted now.

**4. No threading — synchronous save/load for MVP/VS.** At MVP/VS data volumes (a handful of villagers, a small built structure), a synchronous save/load is expected to complete in low single-digit milliseconds — well under a frame budget. Because saves are exclusively triggered on `transition_ended(success=true)` (Scene/World Management's existing contract, TR-scene-world-management-013/024), any save-time cost occurs while the scene transition's loading overlay is already visible (TR-scene-world-management-032) — the existing UI treatment naturally covers a brief synchronous save, with no new UI needed. `WorkerThreadPool`/background-thread saving is named as an explicit escape hatch if Full-Vision-scale saves are later measured to cause a visible hitch — not adopted now, consistent with ADR-0008's identical reasoning for AI threading.

**5. Load sequence is unchanged from `architecture.md`'s existing Data Flow Phase 3** — this ADR specifies the file format and per-system serialize/deserialize contract; it does not re-architect the already-specified load order (RID Ready → Save/Load reads file → Voxel World bulk-populated → Building blueprints/progress restored → Villager AI restored with stale-id revalidation → Needs & Mood restored → Build Validation runs one full analysis pass).

### Architecture Diagram
```
Save (triggered on Scene/World Management's transition_ended(success=true)):
  SaveLoadOrchestrator.save(path):
    var data := {
        "save_format_version": 1,
        "voxel_world": VoxelWorld.serialize(),
        "building_system": BuildingSystem.serialize(),
        "villager_ai": VillagerAI.serialize(),
        "needs_mood": NeedsAndMood.serialize(),
    }
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Save failed to open file: " + error_string(FileAccess.get_open_error()))
        return false
    var ok: bool = file.store_var(data)   # 4.4+ returns bool — checked, not assumed
    if not ok:
        push_error("Save failed to write data")
        return false
    return true

Load (triggered at boot if a save exists, after RID reaches Ready):
  SaveLoadOrchestrator.load(path):
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Load failed to open file: " + error_string(FileAccess.get_open_error()))
        return false
    var data: Dictionary = file.get_var()   # no analogous bool — a corrupt read
                                              # is caught by the null-open-check
                                              # above, not by get_var() itself
    VoxelWorld.deserialize(data.get("voxel_world", {}))
    BuildingSystem.deserialize(data.get("building_system", {}))
    VillagerAI.deserialize(data.get("villager_ai", {}))       # stale-id revalidation, own responsibility
    NeedsAndMood.deserialize(data.get("needs_mood", {}))       # schema-drift handling, own responsibility
    BuildValidation.run_full_analysis_pass()                   # NOT deserialized — full re-derive, per its own GDD
    return true
```

### Key Interfaces
```gdscript
# Every serializing system gains this pair (extends architecture.md's API Boundaries):
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void

# New Save/Load orchestrator module (injected-tier per ADR-0001):
func save(path: String) -> bool     # checks FileAccess.open()'s null AND store_var's bool return
func load(path: String) -> bool     # checks FileAccess.open()'s null (get_var() has no analogous signal)
```

## Alternatives Considered

### Alternative A: Plain `Dictionary` via `FileAccess.store_var()`/`get_var()`, no chunking, no threading — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: minimal code (no custom Resource classes to define purely for save schemas); each system's `serialize()` can return whatever structure suits its own internal representation without a shared schema class constraining it; simple to reason about at this project's stated bounded world scale.
- **Cons**: no static typing on the save-file's own structure (each system's dictionary is only as well-typed as that system's own `deserialize()` defensively makes it) — a deliberate trade-off given save data was never going to benefit from Resource's Inspector-editing value anyway.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Custom `Resource`-derived `SaveGameData` class (matching ADR-0002/0006's pattern), saved via `ResourceSaver`/`ResourceLoader`
- **Description**: define a `SaveGameData extends Resource` with typed `@export` fields per system, saved as binary `.res`.
- **Pros**: consistent with this project's established Resource-based data pattern; Godot's Resource deserialization is generally tolerant of missing/extra fields (a form of free forward/backward compatibility) — worth verifying precisely, see Engine Specialist Validation.
- **Cons**: adds a wrapper class whose only purpose is to hold `Dictionary`-typed export fields (since each system's actual serialized content is still opaque data, not individually-typed scalar fields) — the Resource wrapper provides no benefit over a plain top-level Dictionary here, since none of the reasons ADR-0002/0006 chose Resource (Inspector editing, git-diff-friendliness) apply to save files.
- **Rejection Reason**: adds a class with no functional benefit for this specific data category — explicitly not a case where ADR-0002's precedent should mechanically extend, since the deciding factors that motivated ADR-0002 aren't present here.

### Alternative C: Chunked save files (spatial regions) + async/threaded save
- **Description**: partition the world into fixed-size chunks, each independently saved/loaded; use `WorkerThreadPool` for save operations.
- **Pros**: would scale to a much larger or streaming-scale world than this project has.
- **Cons**: solves a scale problem not yet measured to exist (bounded world, overlay-hidden save window); ADR-0014's larger payload makes this the FIRST escape hatch to re-evaluate at VS — real, avoidable implementation complexity for MVP/VS.
- **Rejection Reason**: premature at this project's stated scale; named as the explicit escape hatch (both chunking and threading) if Full Vision scale later proves the simple approach insufficient — matching ADR-0003's and ADR-0008's identical reasoning pattern for their own scale-related decisions.

## Consequences

### Positive
- "Each system serializes itself" (the carry-forward directive) is honored structurally — the orchestrator cannot accidentally couple to any system's internal format, since it only ever handles opaque dictionaries.
- Minimal new code: two methods per serializing system, one small orchestrator module, no new Resource classes.
- Save-time cost naturally hides behind the already-existing scene-transition loading overlay, since saves are exclusively transition-triggered.

### Negative
- No chunking means a full save/load always processes the entire world state — acceptable at this project's stated scale, but a real limitation if that scale assumption changes later without revisiting this ADR.
- No static schema class means a save-file structure bug (e.g., a system's `deserialize()` expecting a key that `serialize()` never wrote) is only caught by tests, not by the type system — mitigated by the Validation Criteria below (round-trip tests per system).

### Risks
- **Risk** (found during engine-specialist validation — CORRECTED, not just noted): `get_var()` has no analogous success/failure signal the way `store_var()`'s 4.4+ bool return does — a read failure (missing file, corrupt data) is not detectable from `get_var()` itself. The first draft's pseudocode called `FileAccess.open()` and immediately called `store_var`/`get_var` on the result with no null check — if `open()` fails (missing file, bad path, permissions), this would be a null-reference crash, not the graceful `push_error` the "must be detected, not silently swallowed" requirement calls for. The actual failure-detection point for open-time errors is `FileAccess.open()` returning `null` (checked via `FileAccess.get_open_error()`), not `store_var`/`get_var` — both save() and load() pseudocode now check this explicitly before proceeding.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed `store_var`/`get_var` correctly round-trip nested `Dictionary`/`Array`/primitive Variant types (including `Vector3i`) in 4.7, using Godot's native Variant encoding — `full_objects` is correctly out of scope since nothing here stores actual Objects/Resources. Confirmed the 4.4 `store_var` void→bool change is accurate. **Found a real gap**: the first draft's pseudocode never checked `FileAccess.open()`'s return for `null`, which would crash on any file-open failure rather than reporting it gracefully — fixed in both save() and load() pseudocode above. Confirmed Resource deserialization's missing/extra-field tolerance (cited for Alternative B's comparison) is accurate, long-standing Godot behavior, unaffected by 4.4–4.7. Verdict: "needs a specific correction, not a reconsideration of the decision itself." Applied above.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| voxel-world.md | TR-voxel-world-021: "Save/Load iteration API exposes only occupied (non-empty) cells" | Voxel World's own `serialize()` calls `iterate_occupied()` internally — this ADR doesn't change that contract, just the file format wrapping it |
| building-system.md | TR-building-system-023/033: undo stack excluded; open blueprints + progress serialized | Building System's `serialize()` implements this; undo stack simply isn't included in its output |
| villager-ai-behavior.md | TR-villager-ai-behavior-027: "serialize per-villager position, activity, claimed job id, owned bed, need levels; re-validate stale claim/bed ids on load without crashing" | Villager AI's own `deserialize()` — this ADR's contract just requires it accept/return a `Dictionary`, the revalidation logic itself is unchanged from the GDD |
| needs-mood-system.md | TR-needs-mood-system-026..029: mood restored as-saved, schema-drift handling | Needs & Mood's own `deserialize()` — same relationship, format-agnostic |
| scene-world-management.md | TR-scene-world-management-013/024: savepoint creation bound to `transition_ended(success=true)` | Unchanged — this ADR's orchestrator is called at that trigger point, doesn't redefine it |

## Performance Implications
- **CPU**: A single synchronous `store_var`/`get_var` call per save/load — expected low single-digit milliseconds at MVP/VS data volumes, occurring during an already-visible loading overlay.
- **Memory** *(revised 2026-07-11, ADR-0014)*: One assembled top-level `Dictionary` momentarily held during save/load — proportional to total world+villager state, now up to ~150–250 MB worst case (was "tens of MB"); re-measure at VS.
- **Load Time**: Adds to the existing boot/transition sequence at the point Save/Load reads the file — not yet measured, a candidate check if Full Vision scale is later revisited.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code. `save_format_version` exists from the first implementation even though no migration path is needed yet.

## Validation Criteria
- A round-trip unit test per serializing system: `serialize()` then `deserialize()` on a synthetic populated state, asserting the restored state matches the original exactly (per each system's own already-specified ACs, e.g. Needs & Mood's "mood restored as-saved, never re-initialized").
- A unit test simulates a `store_var` failure (mocked `FileAccess` returning `false`) and asserts the orchestrator's `save()` returns `false` and logs an error, rather than silently reporting success.
- A unit test simulates `FileAccess.open()` returning `null` (e.g. an invalid path) for both `save()` and `load()`, and asserts both return `false` with a logged error rather than crashing on a null-reference.
- A unit test loads a save file with an extra, unknown top-level key (simulating a future format's forward-compatibility) and asserts the current orchestrator ignores it without crashing.

## Related Decisions
- Depends on ADR-0001 for the Save/Load orchestrator's injected-tier wiring.
- Deliberately diverges from ADR-0002/ADR-0006's Resource/`.tres` pattern for a different data category, with the distinction stated explicitly rather than left implicit.
