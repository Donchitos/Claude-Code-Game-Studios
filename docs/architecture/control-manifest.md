# Control Manifest

> **Engine**: Godot 4.7-stable
> **Last Updated**: 2026-07-27
> **Manifest Version**: 2026-07-27
> **ADRs Covered**: ADR-0001 … ADR-0016 (0003 Superseded by 0014; ADR-0014's full-world-at-boot storage clause Superseded by ADR-0015; ADR-0015 Accepted spike-validated 2026-07-23; ADR-0016 Accepted; the rest Accepted)
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change
> **Provenance**: TD-MANIFEST gate skipped — Lean mode (no `production/review-mode.txt`). Deltas since v2026-07-23: ADR-0009's story `villager-ai-024` addendum (mutation points (c)/(d)) and **ADR-0007 v1.1's scaffolding amendment** (§1a/§1b/§2a/§2b — technical-director rulings D1/D2/D8 on story `building-034`, 2026-07-27). Prior deltas since v2026-07-11: ADR-0015 (Accepted), ADR-0016 (Accepted), and the `(Slice propagation 2026-07-23)` amendments to ADR-0009/0010/0014 + ADR-0012/0013 resolution notes (see `change-impact-2026-07-23-slice-batch.md`).

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs,
technical preferences, and engine reference docs. For the reasoning behind each
rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: boot sequencing, DI/reference architecture, config loading, data definitions, save/load*

### Required Patterns
- **Hybrid reference model**: ONLY `TimeTickSystem` and `ResourceItemDatabase` are Autoloads — call them by global name in method bodies. Every other module is injected-tier: typed `@export` node references, wired exclusively in `GameWorld.tscn` via the editor Inspector — source: ADR-0001
- **All wiring/validation logic lives in an explicitly-callable `setup()`** that `GameWorld` calls in production and tests call directly; `setup()` asserts its dependencies are wired; `_ready()` does nothing beyond optionally calling `setup()` — source: ADR-0001
- **New systems default to injected-tier**; Autoload requires: genuinely single-instance, boot-early, no test-substitution need — source: ADR-0001
- **Tests**: instantiate with `Node.new()`, assign mocks to `@export` props (or pass to `setup()`), call methods directly — zero scene tree, zero Autoload registration — source: ADR-0001
- **Config**: one custom `Resource`-derived config class per module, typed `@export` fields (one per Tuning Knob, GDD defaults), stored as **`.tres` text files**; injected modules get config as another `@export`; Autoloads `load()` their own via `const CONFIG_PATH` — source: ADR-0002
- **Every config class exposes `validate() -> Array[String]`**, called once at boot in the owner's `setup()`. Single-field range issue → warn + clamp + proceed. GDD-declared BLOCKING cross-value invariant → terminal boot-halt (RID Failed pattern) — source: ADR-0002
- **Boot gate (unified)**: `GameWorld`'s Booting state gates ALL injected-tier `setup()` calls behind RID `Ready`/`Failed`. Check-then-connect: synchronous `is_ready()` first, `validation_complete.connect(..., CONNECT_ONE_SHOT)` fallback. On Failed: boot-halt screen, NO `setup()` calls, terminal. BootState: `{WAITING_FOR_DATABASE, WIRING, ACTIVE, HALTED}` — source: ADR-0005
- **Boot loads only the initial residency set, NOT the full world** — with paged residency (ADR-0015), boot allocates the camera-near ∪ settlement working set, not a full-world packed-array allocation; this reduces ADR-0014's ~2.6 s initial-window-build storage component — source: ADR-0005 (timing note revised by ADR-0015) + ADR-0015 Decision §1
- **Data definitions two-type split**: private `ItemDefinitionResource` (authoring, `@export`-editable) + public getter-only `ItemDefinition extends RefCounted` returned by `get_by_id()` — a fresh lightweight wrapper per call (wraps, never copies). `visual_asset` is a typed `Mesh` reference, never a path string. Boot validation: resource-null check BEFORE `visual_asset != null` check, distinct diagnostics, both terminal — source: ADR-0006
- **Multi-cell furniture adds a `footprint` field** to the definition (e.g. bed = 2 cells); the two-type authoring/view split absorbs it structurally — add when the RID story lands — source: ADR-0006 (slice propagation)
- **Save/load (VS-tier)**: plain `Dictionary` via `FileAccess.store_var()/get_var()`, single binary file for non-voxel state, top-level keys `save_format_version` (=1 from day one), `voxel_world`, `building_system`, `villager_ai`, `needs_mood`. Each system exposes `serialize() -> Dictionary` / `deserialize(data)` — source: ADR-0012
- **Voxel save format IS ADR-0015's region files** (chunked by construction — the ADR-0012 Alternative-C chunking escape hatch is now the adopted format for the 16k target). A save is the set of persisted/dirty region files PLUS the small non-voxel Dictionary state (project entities per ADR-0016, villager state, needs/mood). No single monolithic multi-GB voxel pass — source: ADR-0012 (finalized) + ADR-0015 Decision §4
- **Building System `serialize()` includes project entities** — per project: state, cells, `restore_value` (floor-replace cells), `worker_ids`, pending change/demolition orders. New slice state (`restore_value`, project entities, stuck-telemetry counters) is absorbed structurally by the per-system contract — source: ADR-0016 Decision §7 + ADR-0012
- **Saves fire exclusively on `transition_ended(success=true)`** (cost hides behind the loading overlay) — source: ADR-0012

### Forbidden Approaches
- **Never `@export` an Autoload** (`ResourceItemDatabase`/`TimeTickSystem`) into any module — grep: `@export.*ResourceItemDatabase|@export.*TimeTickSystem` must return zero — source: ADR-0001
- **Never read `@export` dependencies inside your own `_ready()`** assuming code-assigned wiring, and never put validation in `_ready()` (headless `new()` never runs it — silent test/production mismatch) — source: ADR-0001
- **Never write to a config Resource field at runtime** — config is read-only from every consumer (grep: `config\.\w* *=` outside the config class's own clamp logic = zero). Runtime-adjustable values get their own owned state, never a shared config Resource — source: ADR-0002
- **Never `ConfigFile` or JSON for tuning data** (stringly-typed, silent-failure lookups / no typed Inspector) — source: ADR-0002
- **`ItemDefinition` has zero setters and zero writable `var`s**; nothing outside RID holds an `ItemDefinitionResource`; cross-system references are opaque string ids only — source: ADR-0006
- **Never defensive-copy via `duplicate()`** for definition queries (copies still have setters = silent-success mutation; plus per-query allocation cost) — source: ADR-0006
- **Never a custom `SaveGameData` Resource via `ResourceSaver`** (no benefit for Dictionary-only payloads; ADR-0002's Resource precedent does NOT extend to save files) — source: ADR-0012
- **Never save the undo/redo stack** — the project undo/redo stack is excluded from serialization (ADR-0012, building-system TR-033); it governs the live plan only, not persisted state — source: ADR-0016 Decision §7 + ADR-0012
- **Save data is never designer-authored, never Inspector-edited, never git-tracked** — region files are user data (`.gitignore`d), consistent with the save-data category — source: ADR-0012 + ADR-0015 Decision §4
- **Never poll for boot readiness** (per-frame/`Timer` polling contradicts the event-driven principle — use the signal); no injected-tier `setup()` call site outside `GameWorld`'s Booting path — source: ADR-0005

### Performance Guardrails
- Wiring resolves once at scene load; revisit service-locator only if `@export` assignments exceed ~30 (MVP: 9 modules) — source: ADR-0001
- Config loads once at boot; RID tier-0 validation must stay low-single-digit ms; the boot GATE itself stays low-single-digit ms — source: ADR-0002/0005
- Save/load synchronous at MVP/VS for non-voxel state; voxel save is region files (chunked by construction) — disk footprint scales with *mutated* regions, not world size (spike: 0.77 MB from 49 of 1,024 possible regions vs a 7.63 GB naive full-world save, ~1,600× reduction); population ceiling 20–30 villagers — source: ADR-0012 + ADR-0015

---

## Core Layer Rules

*Applies to: physics, picking, building pipeline, project lifecycle, occupancy, gameplay orchestration*

### Required Patterns
- **Jolt Physics 3D (4.6+ default), no override**; villagers carry a child `Area3D` + `CollisionShape3D`, `collision_layer = 1`, `collision_mask = 0` — source: ADR-0004
- **Block picking = manual DDA grid-walk** against Voxel World's cell data (chunked accessor), driven by Camera & Input's `get_world_ray()` — no collider of any kind involved — source: ADR-0014 (carried from ADR-0003 §3)
- **Occupancy authoritative value = discrete `current_cell: Vector3i`** — the SOLE authoritative value for all logic (occupancy, F4 targeting, walled-in checks, `get_current_cell()`); it changes ONLY at tick boundaries, atomically. `_visual_position` is render-only — source: ADR-0009
- **Occupancy is a body-column, not a single cell** (2-block character scale): every occupancy/seal/walled-in query derives the villager's vertical body-column (feet `current_cell` + the cell(s) above spanning its height) from the single authoritative discrete `current_cell`. The derivation is deterministic and interpolation-free — the "single unambiguous answer" property holds for the column exactly as for one cell — source: ADR-0009 (slice propagation)
- **`current_cell` changes at EXACTLY four sanctioned points**: (a) tick-boundary travel arrival; (b) an unstuck-watchdog rescue (deterministic stuck-tick threshold; target via expanding-ring BFS with the F2 lexicographic `y,x,z` tie-break); (c) a self-seal climb (`VillagerAi.climb_onto_self_sealed_cell`, story villager-ai-024) — a deterministic `+1` in Y at the instant villager-ai Rule 16's self-seal exemption fires, so a wall-building villager lands on the column's next blueprint cell instead of staying entombed; (d) a marooned-relocation (`VillagerAi._relocate_if_marooned`, story villager-ai-024) — reuses the SAME expanding-ring BFS/tie-break as (b) the instant a construction claim finishes/is revoked and leaves the villager on a now-isolated graph node with no reachable job. All four are discrete and snap `_visual_position` to match (no lerp) — source: ADR-0009 (slice propagation; story villager-ai-024 addendum) + villager-ai Rule 15/F5/Rule 16
- **Seal prevention is a negative-write gate the Building System write path MUST accept**: a Planned→Built write that would entrap a villager is gated by reading the discrete `current_cell`/body-column (never `_visual_position`). The one deliberate exception — a builder sealing itself with its own same-job completion write — proceeds unconditionally and is self-healed by the watchdog — source: ADR-0009 (slice propagation) + villager-ai Rule 16/F6
- **Visual lerp**: `_visual_position = _from_cell.lerp(_to_cell, _intra_tick_progress)` each frame; `_intra_tick_progress` advances via `game_delta` ticks only — frozen during pause, no glide — source: ADR-0009
- **Villager visual node sets `physics_interpolation_mode = OFF` explicitly** (defends against project-wide setting flips causing double-interpolation) — source: ADR-0009
- **Race closure relies on synchronous signals**: Voxel World's `cell_changed` fires synchronously; the re-path filter redirects in the same call stack — source: ADR-0009
- **Load-before-write for far-world mutations**: any write to a cell in a non-resident chunk (dig order TR-voxel-world-051, building write, save flush) MUST first page in that chunk's region, apply the write to the resident copy, mark it dirty, and let staggered eviction flush it. This rule lives in ONE place — Voxel World's single batched write path — not in every caller. A write is never applied to disk blind or dropped — source: ADR-0015 Decision §3
- **Built cells mutate ONLY via worker-executed jobs** — built geometry is authoritative Voxel World data; it changes only through a villager-claimed, worker-executed build/demolition job, never via a direct edit or an undo — source: ADR-0016 constraint + Decision §1/§5
- **Project entity lifecycle (Building-System-owned, injected-tier)**: a persistent project entity aggregates blueprint/built cells with state ∈ `{DRAFT, BUILDING, PAUSED, DONE}` + demolition orders. Draft → Released(BUILDING) ⇄ Paused → Done. Paused revokes in-flight claims gracefully, offers no new jobs, leaves queued cells untouched, and resumes the SAME remaining cells without re-creation — source: ADR-0016 Decision §1
- **Plan-only undo/redo**: the undo stack governs the plan ONLY — draft cells and queued orders. Undo of a released-but-unbuilt cell removes the pending job; redo re-creates only still-valid cells, dropping invalidated ones with feedback. Planning/undo work identically paused or unpaused — source: ADR-0016 Decision §5
- **26-neighborhood grouping/merge (deterministic)**: mutually 26-adjacent blueprint cells belong to one project; a commit bridging existing projects merges them so every resulting cell belongs to exactly one project (batch-merge guarantee, even a template stamp whose sub-shapes aren't all mutually adjacent) — source: ADR-0016 Decision §2
- **Change orders attach to released/done projects**: an edit targeting an already-released or done project attaches as a change order (added cells → new jobs; removed cells → demolition orders) WITHOUT recreating the project entity — source: ADR-0016 Decision §3
- **Worker attribution**: `on_job_claimed(project_id, villager_id)` records `worker_ids` on the project; attribution is read/display + save state, never a control channel — source: ADR-0016 Decision §4
- **Selection via cell→project reverse index**: every project cell maps back to its owning project (`project_at_cell(cell) -> int`, O(1)); a world click on any cell selects the whole project regardless of tool-armed state — this is the DDA→owning-project resolution ADR-0010 §4 calls into — source: ADR-0016 Decision §6
- **Demolition is job-based and uniform for blocks AND furniture** — no instant-removal carve-out; demolition orders queue worker-executed jobs; `restore_value` is written back for demolished floor-replace cells, never left empty — source: ADR-0016 Decision §1 + constraint
- **Collision-layer convention**: Layer 1 = villagers; 2–8 reserved for future gameplay; 9–20 untouched. Future ADRs extend, never redefine — source: ADR-0004
- **Building System placement pick calls ONLY the DDA step** (`raycast_cells()`) — structurally incapable of hitting villagers — source: ADR-0004
- **Drag ownership**: a drag validly begun via `_unhandled_input()` switches release-listening to `_input()` (`set_process_input(true)`) for the drag's duration; on release, immediately `get_viewport().set_input_as_handled()`, then revert to `_unhandled_input()` — source: ADR-0010
- **Cross-module config invariants** are validated by whichever module's GDD states them (documented per-instance exception, e.g. Build Validation reads Building System's config for `max_room_height >= wall_height`) — source: ADR-0002
- **Save/Load orchestrator** (injected-tier module): collects/distributes per-system Dictionaries as opaque blobs; `save()` checks `FileAccess.open()` null (via `get_open_error()`) AND `store_var()`'s bool return; `load()` checks open-null before `get_var()`; on load Villager AI revalidates stale claims, Build Validation is NOT deserialized (full re-derive) — source: ADR-0012

### Forbidden Approaches
- **Zero physics API calls in Building System's pick path** — grep: `intersect_ray|PhysicsDirectSpaceState3D` in `src/building_system/` = zero — source: ADR-0004
- **Never `StaticBody3D`/`CharacterBody3D` on villagers** (implies unwanted collision response; movement is cell-interpolation) — source: ADR-0004
- **Never mutate built cells via undo or a direct edit** — full undo of built geometry is rejected (it would make built geometry non-authoritative and bypass ADR-0009's occupancy/seal semantics and the worker-executed mutation contract) — source: ADR-0016 Alternative C rejected
- **Never apply a far-world write to disk blind, and never drop it** — route through load-before-write (page-in → resident-copy write → mark dirty → staggered flush) — source: ADR-0015 Decision §3
- **Never `MOUSE_MODE_CAPTURED` during placement drags** (cursor must stay visible and free) — source: ADR-0010
- **Camera & Input never interprets action names** and never emits a world action for a UI-consumed click (exactly-one-owner) — source: ADR-0010
- **Never silently swallow save/write failures** — detect, `push_error`, return false — source: ADR-0012
- **`_visual_position` is never read outside the movement/rendering path** (grep-verifiable) — occupancy, seal, targeting, and walled-in checks read the discrete `current_cell`/body-column; never integrate raw `_delta` into `_intra_tick_progress`; never flip `current_cell` at interpolation midpoint — source: ADR-0009
- **Never snap/teleport during ORDINARY travel** — interpolation must never snap; the watchdog rescue is the ONE sanctioned discrete-teleport exception, nothing else — source: ADR-0009 (slice propagation)
- **Zero `PhysicsServer3D`/`RayCast3D` in any picking path** (Voxel World AND Building System, grep-verifiable) — source: ADR-0014 (carried from ADR-0003)

### Performance Guardrails
- Villager-hit query runs once per click (event-driven, never per-frame) — source: ADR-0004
- `_input()` is actively listened to only during an in-progress drag window — source: ADR-0010
- Project reverse-index lookup is O(1) per cell; grouping/merge is bounded by the committed batch's neighborhood, not world size; one entity per active project + a cell→project index proportional to built/draft cell count — modest at settlement scale — source: ADR-0016
- Far-world writes incur one page-in each; low-frequency and player-directed at MVP/slice scope, run asynchronously (never blocking the frame per ADR-0015 §6) — source: ADR-0015

---

## Feature Layer Rules

*Applies to: AI systems, pathfinding, villager behavior*

### Required Patterns
- **Walkability = two shared pure functions** owned by Villager AI: `is_standable(cell) -> bool` (solid below **OR the cell is a scaffold cell** + clearance for the 2-block body) and `is_step_legal(from, to) -> bool` (|dy| ≤ 1; diagonal only if both flanking orthogonals passable; **a same-column step (`dx = dz = 0`, `|dy| = 1`) is legal ONLY if BOTH endpoints are scaffold cells — it must be refused explicitly, it is no longer prevented structurally**). EVERY consumer (pathfinder, Build Validation, watchdog rescue-target BFS) calls these — single source of truth — source: ADR-0007 (§1/§1a/§2a, scaffolding amendment 2026-07-27)
- **Scaffold occupancy is a second occupancy source, passed as an explicit predicate PARAMETER** — never voxel data (`CellContents.is_empty()` is unchanged; a scaffold cell is never solid, never a wall, never a roof), never a module-global, never a singleton read. A caller that passes nothing sees exactly pre-amendment behaviour, so Build Validation stays scaffold-blind structurally; its blindness is provably conservative (scaffolding can only ever ADD standable cells/edges, so a blind consumer never under-reports "sealed"). The lookup must be **O(1) keyed** — no cantilever/support/connectivity search inside any predicate, ever — source: ADR-0007 §1a/§1b
- **The `after_write` twins MUST receive the scaffold source too** (`_is_standable_after_write` and friends, the inputs to `would_trap_builder`): a villager on a scaffold cell has air below, so a scaffold-blind twin would report "trapped" on nearly every write. This preserves seal prevention, it does not weaken it. **SC-INV-1**: no scaffold cell is ever removed while any villager's body-column occupies it — dismantle is top-down and worker-first; bottom-up collapse only when no villager occupies the structure — source: ADR-0007 §1b + story building-034 D4/D10
- **Scaffold changes patch the nav graph via the scaffold source's OWN signal**, connected with default (synchronous) flags — never `CONNECT_DEFERRED` — routed into the existing bounded `patch_cells` path; a scaffold write is not a `VoxelWorldGrid` write and `cell_changed` will never fire for it — source: ADR-0007 §2b
- **Travel pathfinding via `AStar3D`**: graph built once at boot, incrementally patched on `cell_changed` (never rebuilt); point IDs are deterministic bit-packed `Vector3i → int64` (`x&0x1FFFFF | y<<21 | z<<42`), never an incrementing counter — source: ADR-0007
- **Build Validation runs its own independent BFS** calling the shared predicates; it never touches Villager AI's `AStar3D` instance — source: ADR-0007
- **AI is a plain explicit FSM**: state enum + `match`, strict discrete priority (Urgent need > Work > Idle/Wander); tick-driven via Time & Tick's signal, never raw delta in `_physics_process` — source: ADR-0008
- **Deciding staggering**: FIFO `Array[int]` queue + `max_deciding_per_tick` budget (config knob per ADR-0002; **spike-tuned initial value: 1**); budget caps new passes STARTED per tick, never interrupts an in-progress pass; dequeue in stable villager order — source: ADR-0008
- **Unstuck watchdog**: a cheap O(villagers) per-tick check for Traveling/Working agents; fires a deterministic rescue teleport at `unstuck_watchdog_threshold_ticks`, target via expanding-ring BFS (`unstuck_rescue_search_radius`/`_max_radius`) with the F2 lexicographic tie-break; `villager_unstuck` telemetry counters — source: ADR-0008 + ADR-0009 (slice propagation) + villager-ai Rule 15
- Villager AI exposes `serialize()/deserialize()`; `deserialize()` owns stale claim/bed-id revalidation — source: ADR-0012

### Forbidden Approaches
- **Zero `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D`** anywhere in Villager AI or Build Validation (grep-verifiable) — navmesh cannot express the exact cell rules — source: ADR-0007
- **Zero `Thread`/`WorkerThreadPool` in Villager AI** for MVP/VS (grep-verifiable) — occupancy dict, AStar3D graph, Needs state are not thread-safe; threading is the escape hatch only on measured need. (NOTE: the `WorkerThreadPool` used for voxel residency I/O per ADR-0015 lives in Voxel World's storage tier, NOT in Villager AI) — source: ADR-0008
- **Never duplicate walkability rules or constants** — no plain 4/8-neighbor flood-fill in Build Validation, no second copy of clearance/step values — source: ADR-0007
- **Never make scaffolding solid** — no `block_type_id` for scaffolding, no entry in `VoxelWorldGrid`, no passability flag on `CellContents`, no scaffold read in the mesher's face-culling or in `src/build_validation/`. Scaffolding is passable in every solidity read, which is the ONLY reason phantom rooms and self-sealing are impossible for free. **Never generalize the vertical edge** — no ladders, stairs, jumping, falling, or gravity; no raise of `max_step_height` or `villager_clearance` — source: ADR-0007 §1a/§2a + story building-034
- **Never a behavior tree or utility-AI addon** (would breach the empty Allowed-Libraries list; priorities are discrete, not scored) — source: ADR-0008

### Performance Guardrails
- **Base tick rate = 4.0 ticks/sec** (`design/registry/entities.yaml`; time-tick-system.md is the authoritative source). More Deciding passes fire per second than at earlier rates, but the per-tick `max_deciding_per_tick` budget still bounds them — no FSM or staggering change — source: ADR-0008 + resolution 2026-07-23
- Population ceiling 20–30; frame budget must hold at 1x AND warp (spike-verified: p95 16.7 ms at 3x with `max_deciding_per_tick = 1`) — source: ADR-0008 + spike report
- **Watch-item**: one Deciding pass measured avg 11 ms p95 35 ms (GDScript stand-in) — mitigations before threading: cheaper pre-filter, smaller BFS bound, pass slicing — source: spike report
- `max_selection_candidates = 15` per-villager F2 budget; Build Validation BFS exceeds one frame above ~12k connected cells (documented accepted-risk boundary) — source: ADR-0007 + spike report

---

## Presentation Layer Rules

*Applies to: rendering, voxel meshing, world-storage residency, UI, HUD, input arbitration surface, UI timers*

### Required Patterns
- **Committed blocks render via the chunked mesher**: 16×16-column chunks, one `ArrayMesh` per chunk, faces emitted only where a cell borders air; whole-chunk rebuild on any cell change (~1.1 ms measured); view-window streaming with per-frame budgets for BOTH chunk builds AND unloads (`queue_free` bursts caused the prototype's only hitch); `visibility_range_end` on chunk instances — source: ADR-0014
- **Faces wind CW with backface culling ENABLED** — Godot 4.7's front-face convention is clockwise (an engine fact, not a project convention); the material ships with culling enabled (TR-voxel-world-052). Audit rule: face-winding checks validate against the engine's actual convention, never a self-stored one — source: ADR-0014 (slice propagation)
- **World storage = paged region-file residency** (ADR-0015 supersedes ADR-0014's full-world-at-boot clause for the 16k target): the resident working set = camera-near chunks (ADR-0014 view radius) ∪ active-settlement chunks (ADR-0007 nav region). Resident memory is a function of that footprint, NOT of world size. Everything else lives in on-disk region files (fixed-size chunk groups, `region_size_chunks`; `store_var` on the same `PackedByteArray`-class storage), paged in on approach, evicted staggered on leaving the margin. Voxel World's public accessor API (O(1) `get`/`set` by `Vector3i`, `cell_changed`, `raycast_cells`) is UNCHANGED — the residency tier is transparent to every consumer — source: ADR-0015 Decision §1/§2 + ADR-0014
- **Streaming budget is TIME-BASED, not a fixed chunk count**: page-in and eviction are each bounded per frame by a time budget (`page_budget_ms`/`evict_budget_ms`, validated at 4.0 ms each — leaves ~12 ms of the 16.6 ms frame for game work). The budget is re-checked after EVERY single integrated item (not once per frame), so a burst of ready items in one frame cannot collectively exceed it — the excess defers to a later frame — source: ADR-0015 Decision §1
- **Read-through in-flight-write cache**: when a dirty chunk is evicted its flush runs asynchronously; if that chunk is re-needed before its flush completes, the read MUST be served from the in-memory not-yet-durable bytes (`_write_in_flight_data`), NEVER re-read from the region file (which may be mid-write/incomplete) — source: ADR-0015 Decision §3
- **Save format = region files** — a save is the set of persisted/dirty region files + small non-voxel state; chunked by construction — source: ADR-0015 Decision §4 (see Foundation Layer)
- **Blueprint ghosts = pooled `MeshInstance3D` nodes** with `material_override` tint; bounded by `max_cells_per_command = 512`, outline-degrade above `preview_degradation_threshold` — source: ADR-0014 (carried from ADR-0003 §4)
- **Ghost-anchored picking predicate lives on the ADR-0014 §4 DDA path**: the "ghost/draft cells pick as solid; dig-orders and water do not pick" contract is an `extra_solid` predicate on `raycast_cells` (an overlay of uncommitted ghost/draft cells) — owned by ADR-0014 / Voxel World's read API, NOT by ADR-0004. Building System's placement pick still issues zero physics queries — source: ADR-0014 §4 (slice propagation)
- **Multi-scene (Valley+Dungeon, VS+): ONE shared `World3D`**, Dungeon at fixed spatial offset (`100_000` units, documented at definition site; 84,000-unit absolute gap vs the 16k span, ~6.25× ratio — kept, not increased, because float32 ULP scales with magnitude); exactly ONE `WorldEnvironment` node with swapped `.environment` resource; per-scene toggles for `Camera3D.current`, `AudioListener3D`, `DirectionalLight3D.visible` — ALL centralized in one `_activate_scene`/`_deactivate_scene` pair — source: ADR-0013 (finalized 2026-07-23)
- **New-click ownership via native propagation**: HUD Controls keep default `mouse_filter = STOP`; world systems listen in `_unhandled_input()`; Camera & Input needs zero new code — source: ADR-0010
- **Build-Mode-gated click routing + Selection arbitration** (extension of the hover-suppression gate, not a new mechanism): Building UI exposes the interaction mode (WorldNav vs Build Mode). When an armed tool consumes picks (Build Mode, ToolArmed) a world press routes to the placement pipeline (Decision §1–§3). When no tool consumes the pick (WorldNav, or Build Mode Idle) a world press that survives hover-suppression routes to **Selection** instead — checked at the same point/precedence as `is_hover_suppressing_world_pick()`. Selection resolves to at most one of: a villager (ADR-0004 `Area3D` hit-test) or a project (ADR-0014 §4 DDA block pick → owning project); nearest-wins with villager-winning ties (`pick_tie_epsilon`); empty terrain/water clears Selection. Building UI owns this routing/Selection state; the in-progress-drag `_input()` release rule (§3) is unaffected — source: ADR-0010 Decision §4 (slice propagation)
- **Hover-suppression flag**: Building UI ORs hover across its three HUD zones via `mouse_entered`/`mouse_exited` (event-driven, NEVER per-frame polling), exposed as `is_hover_suppressing_world_pick() -> bool`; consumers check it before starting any new pick/drag/selection; it also gates ghost-preview updates — source: ADR-0010
- **Villager click pick** (Idle only): DDA block distance + `intersect_ray()` with `collision_mask = 1`, **`collide_with_areas = true`, `collide_with_bodies = false`**; nearest wins, villager wins within `pick_tie_epsilon` — source: ADR-0004
- **UI timers**: ONE centralized `UITimerManager` (plain class owned by Building UI — not an Autoload, not a module) with `Dictionary[StringName, TimerRecord]` + one shared `_process(delta)` on **raw delta**; API `start_timer/cancel_timer/has_timer/get_remaining/on_suspended_begin/on_suspended_end` — source: ADR-0011
- **Suspended handling**: single `_suspended` guard at the top of the shared loop; timers freeze ONLY on Suspended (scene transitions), never on game pause; decoupled from Control visibility — source: ADR-0011
- **Two-pass expiry** (collect keys, then fire+erase); grace-expiry callbacks re-query Build Validation's current state, never trust the triggering event — source: ADR-0011
- **Every visual `Tween` pauses/resumes explicitly** (`tween.pause()/play()`) tied to the same Suspended signal — source: ADR-0011
- **Building UI mirrors project lifecycle state, never owns it** — the Projects Panel renders/routes (ADR-0010 §4); the project entity is owned solely by Building System — source: ADR-0016 Decision §1 + building-ui contract

### Forbidden Approaches
- **NEVER synchronous disk I/O or terrain-gen in the per-frame path — full stop**: region reads, region-flush writes, AND terrain regeneration ALL run on a capped `WorkerThreadPool` (`MAX_CONCURRENT_ASYNC_TASKS`). A chunk whose background task is unfinished — OR could not be dispatched because the pool is at capacity — simply STAYS QUEUED for a later frame; it is NEVER regenerated or read synchronously on the main thread as a fallback. A synchronous fallback IS the failure mode (it left a ~55 ms worst-case tail no budget could preempt). The one sanctioned exception is per-region header I/O (the `SLOTS_PER_REGION` offset table), read/created synchronously ONCE per region — never per-tick — source: ADR-0015 Decision §6
- **Never a fixed chunks-per-frame streaming count at 16k scale** — a fixed count (ADR-0014's `stream_chunk_budget = 2`, tuned for ~25 c/s) under-provisions ~12× at the game's real max camera speed (144 c/s ⇒ ~24 new chunks/frame), producing a chronic backlog that climbs memory ~5.7× and blows the frame budget; use the time-based budget — source: ADR-0015 Decision §1
- **Never re-read an evicting dirty chunk from its region file before its flush completes** — serve from the in-flight-write cache; the file may be mid-write and incomplete — source: ADR-0015 Decision §3
- **Never CCW winding or `CULL_DISABLED` for committed-block materials** — the slice's CCW + `CULL_DISABLED` was a documented, now-EXPIRED mitigation (2× overdraw); it must not survive a jump in scene complexity — source: ADR-0014 (slice propagation)
- **Never `GridMap` for committed-block rendering** (fails measurably at scale: >16 GB at 2000², 65k draw calls at 1000²); never full greedy meshing or a GDExtension mesher until measurement demands them (named reserves); never per-instance custom-data plumbing for ghost tint — source: ADR-0014
- **Never separate SubViewports with own `World3D`s** for scene concurrency; never a second `WorldEnvironment` node (grep-verifiable); never assume SubViewports isolate `_input()` (they don't); no GI system under ADR-0013 — source: ADR-0013
- **Never restructure `mouse_filter` geometry to solve drag-release** (brittle; releases legitimately land on widgets) — source: ADR-0010
- **Never N per-issue `Timer` nodes** for toast/grace/debounce timing (node churn + still needs the dictionary + violates the no-per-consumer-timers precedent) — source: ADR-0011
- **Never rely on Control visibility to pause timers/tweens** — hiding a Control pauses nothing — source: ADR-0011
- **State colors never render on world geometry** — build-state coloring (draft/released/paused/done) lives on ghost/overlay presentation and the Projects Panel, never baked into committed-block materials — source: ADR-0014 + ADR-0016 (UI-mirror discipline)

### Performance Guardrails
- **Residency memory is FLAT vs world size**: spike peak 43.9–83.7 MB (≤4 GB ceiling, ~1–2% utilization) across a repeated full-16k-span traverse; worst frame 13.3–14.5 ms (budget 16.6), `io_worst`/`regen_worst` = 0.00 ms by construction; the async concurrency cap value is non-critical (worst frame moved ~0.3 ms between cap 32 and 64) because cap-miss = "stay queued," not "run sync" — source: ADR-0015 Validation Criteria
- **One-time per-region header I/O** measured 31–63 ms *cumulative across an entire 27k–32k-tick run* — never a per-tick spike, invisible in every worst-frame number — source: ADR-0015 Decision §6
- Streaming reuses ADR-0014's staggered-unload discipline (the slice's single 133 ms hitch came from an unload burst — a solved-by-discipline problem) — source: ADR-0014 + ADR-0015
- Timer manager iterates dozens of records max in one `_process`; suspend/resume costs one boolean flip — source: ADR-0011
- Hover flag memory: one 3-bool array; boundary-crossing events only — source: ADR-0010

---

## Global Rules (All Layers)

### Naming Conventions (technical-preferences.md)
| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `PlayerController` |
| Variables | snake_case | `move_speed` |
| Signals/Events | snake_case past tense | `health_changed` |
| Files | snake_case matching class | `player_controller.gd` |
| Scenes | PascalCase matching root node | `PlayerController.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH` |

### Performance Budgets (technical-preferences.md)
| Target | Value |
|--------|-------|
| Framerate | 60 FPS |
| Frame budget | 16.6 ms |
| Draw calls | ≤ 2000 (PC mid-range) |
| Memory ceiling | 4 GB — held at the 16k target by paged residency (ADR-0015); resident set is footprint-bounded, not world-size-bounded |

### Approved Libraries / Addons
- **GdUnit4 v6.1.3** (`neues-spiel/addons/gdUnit4/`) — test framework (approved 2026-07-11)

### Forbidden Patterns (technical-preferences.md — project-wide, absolute)
- **`SceneTree.paused`** — pause is owned by Time & Tick (`game_delta = 0`); engine-global pause would freeze camera/UI/overlays that must run on raw delta
- **`Engine.time_scale`** — warp is owned by Time & Tick (`game_delta` multiplier)

### Forbidden / Deprecated APIs (Godot 4.7 — engine-reference/deprecated-apis.md)
Use the replacement, never the deprecated form:
- `yield()` → `await signal` · string-`connect()` → `signal.connect(callable)` · `instance()` → `instantiate()` · `get_world()` → `get_world_3d()` · `OS.get_ticks_msec()` → `Time.get_ticks_msec()`
- `TileMap` → `TileMapLayer` · `VisibilityNotifier2D/3D` → `VisibleOnScreenNotifier2D/3D` · `YSort` → `y_sort_enabled` · `Navigation2D/3D` → `NavigationServer2D/3D`
- Hardcoded input device ID `0` → `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` (4.7 — `0` no longer guaranteed)
- `$NodePath` in `_process()` → `@onready` cached reference · untyped `Array`/`Dictionary` → typed (`Array[Type]`)
- GodotPhysics3D for new 3D work → Jolt (4.6 default; matches ADR-0004)
- NOTE: `duplicate_deep()` (4.5+) exists but ADR-0002/0006/0012 **deliberately avoid it** — do not introduce it for config/definitions/saves

### Engine Facts That Differ From LLM Instinct (verified for 4.7)
- Scene tree readies **bottom-up**: child `_ready()` before parent `_ready()`; scene-file `@export`s are populated by then, code-assigned wiring is NOT — source: ADR-0001
- `load()` on the same `.tres` path returns the **same shared object** (ResourceLoader cache) — mutations are visible project-wide; the reason config is read-only — source: ADR-0002
- `PhysicsRayQueryParameters3D` defaults: `collide_with_bodies = true`, **`collide_with_areas = false`** — an Area3D-only query without the explicit flag silently returns nothing, every time — source: ADR-0004
- Autoloads fully `_ready()` **before** the Main Scene loads (declared order, synchronous) — source: ADR-0005
- GDScript `Object.get("/_private")` bypasses the getter-only pattern — immutability guards against idiomatic misuse, not reflection — source: ADR-0006
- `FileAccess.store_*` returns `bool` since 4.4 — **check it**; `get_var()` has no success signal — the check point is `FileAccess.open()` null — source: ADR-0012
- **`WorkerThreadPool.wait_for_task_completion()` returns an Error code, NOT the Callable's return value** — a background task must write its result into a mutex-guarded structure, never rely on the return of `wait_for_task_completion` — source: ADR-0015 spike (bug found + fixed)
- **Godot 4.7 front-face winding is CLOCKWISE (CW)** — generated voxel triangles must be wound CW with backface culling enabled; auditing against a self-stored CCW assumption was the slice's multi-session "missing faces" root cause — source: ADR-0014 (slice propagation)
- Input routing order: `_input()` → `_gui_input()` → `_unhandled_input()`; `set_input_as_handled()` from `_input()` stops later stages — source: ADR-0010
- `Timer`/`Tween` are NOT paused by hiding their Control — source: ADR-0011
- Godot 4.6 dual-focus system separates mouse focus from keyboard/gamepad focus (hover signals unaffected) — flagged BLOCKING for HUD focus-cycling implementation (building-ui OQ7)
- **`AStarGrid3D` does NOT exist in Godot 4.7** (only `AStarGrid2D`) — manual `AStar3D` graph management is the only built-in option; `AStar3D` IDs are never auto-recycled on `remove_point()` — source: ADR-0007
- (Historical, GridMap now forbidden for blocks:) GridMap collision is octant-batched, NOT per-cell — source: ADR-0003 (Superseded)
- Default signal connections are **synchronous** (in the `emit()` call stack, connection order) — load-bearing for the ADR-0009 race closure — source: ADR-0009
- `_input()`/`_unhandled_input()` are dispatched **SceneTree-global, not per-Viewport**; `DirectionalLight3D` affects the whole `World3D` regardless of distance (hence the explicit visibility toggle); `Camera3D.current`/listener exclusivity is per-Viewport — source: ADR-0013
- **float32 ULP scales with magnitude** (~7.8 mm @ 100k units → ~62 mm @ 1M) — why ADR-0013's dungeon offset is kept at `100_000`, not increased, at the 16k world span — source: ADR-0013 (finalized 2026-07-23)

### Tooling
- **ripgrep has no `gdscript` type** — `rg --type gdscript` errors. Always `rg --glob "*.gd"`. All grep-verifiable ADR checks above depend on this.
- Test naming/evidence rules: see `tests/README.md` and coding-standards.md — Logic stories need a passing GdUnit4 unit test before Done.

### Cross-Cutting Constraints
- **Event-driven, not polled** — boot gate (ADR-0005), hover flag (ADR-0010), timer expiry (ADR-0011): no per-frame polling for state that has a signal. (Production note: the residency drain loop should be completion-driven — re-examine only items whose background task just completed, not poll `is_task_completed` across the whole queue each tick — ADR-0015 §6 production note.)
- **No synchronous disk I/O or terrain-gen in the per-frame path** — all region I/O and terrain regen run on a capped `WorkerThreadPool`; cap-miss items stay queued, never run synchronously as a fallback (ADR-0015 §6). The one exception is one-time-per-region header I/O.
- **Built geometry is authoritative and job-mutated** — built voxel cells change ONLY via worker-executed jobs; undo is plan-only; occupancy/seal reads are discrete `current_cell`/body-column (ADR-0016 + ADR-0009)
- **One terminal-halt severity model** (RID Failed pattern) — reused by config blocking-invariants (ADR-0002) and data-definition validation (ADR-0006); never invent a new severity scheme
- **Escape hatches are named, not preemptively built**: greedy meshing / GDExtension mesher (ADR-0014), AI threading (ADR-0008); a GDExtension/native swap of the residency I/O behind the same interface (ADR-0015) — adopt only on measured need. (The chunked-save escape hatch of ADR-0012 is now EXERCISED as ADR-0015's region-file format.)
- **Raw delta vs `game_delta`**: camera/UI/overlays run on raw engine delta; simulation runs on Time & Tick's `game_delta` (base tick rate 4.0 ticks/sec); never blend the two clocks for one piece of state
