# The Last Seal (Voxel) — Master Architecture

## Document Status
- Version: 1.0
- Last Updated: 2026-07-11
- Engine: Godot 4.7-stable
- GDDs Covered: scene-world-management, voxel-world, camera-input,
  time-tick-system, resource-item-database, building-system,
  villager-ai-behavior, build-validation-navigability, needs-mood-system,
  building-ui, villager-info-ui (all 11 approved MVP GDDs)
- ADRs Referenced: ADR-0001..0014 all authored and resolved (13 Accepted,
  ADR-0003 Superseded by ADR-0014) — status as of 2026-07-11; original
  authoring session identified them as the 13 Required ADRs below
- Technical Director Sign-Off: 2026-07-11 — APPROVED WITH CONDITIONS (all 6
  Foundation/Core "must have" ADRs must be authored + Accepted before
  implementation begins; architecture is otherwise internally coherent, every
  TR is accounted for, every HIGH-risk engine domain is flagged with a
  resolution path)
- Lead Programmer Feasibility: LP-FEASIBILITY skipped — Lean review mode
  (not a PHASE-GATE per `.claude/docs/director-gates.md`)

## Engine Knowledge Gap Summary

Engine: Godot 4.7-stable (pinned 2026-07-09). LLM training data covers Godot up
to ~4.3; versions 4.4–4.7 are post-cutoff and require cross-referencing
`docs/engine-reference/godot/` before any API call is finalized.

**HIGH RISK domains** (verify before deciding):
- **Rendering** — RESOLVED 2026-07-11: chunked face-culled mesher + packed
  chunk storage (ADR-0014, prototype-validated at 2000x2000x32; supersedes
  the GridMap decision of ADR-0003). Ghosts: pooled MeshInstance3D.
- **Physics** — Jolt is now the *default* 3D engine (since 4.6); RESOLVED 2026-07-11: Jolt confirmed (ADR-0004);
  picking is DDA on the data layer, zero block colliders (ADR-0014/0004);
  villager-hit via Area3D intersect_ray with collide_with_areas=true.
- **Navigation/AI-Pathfinding** — RESOLVED 2026-07-11: AStar3D +
  shared walkability predicates, NO NavigationServer3D (ADR-0007;
  AStarGrid3D does not exist in 4.7). Region scope under the large world:
  settlement-core graph, spike tracked as QQ5.
- **Input** — 4.7 changed mouse/keyboard device IDs from hardcoded `0` to
  `DEVICE_ID_MOUSE`/`DEVICE_ID_KEYBOARD` (Camera & Input).
- **UI** — 4.6's dual-focus system (mouse/touch focus separate from keyboard/
  gamepad focus) affects Building UI's `toast_focus_cycle` keyboard-handoff
  contract and Villager Info UI's selection/hover model.

**MEDIUM RISK domains**:
- **Data/Resources** — `duplicate_deep()` (4.5+), `FileAccess.store_*`
  return-type change (4.4), typed `Dictionary[Vector3i,...]` (4.4+) touch
  Voxel World and Resource & Item Database.
- **Scene management** — the two-simultaneous-live-scenes model (Scene/World
  Management, for VS+ dungeons) touches NavigationServer3D map-sharing/RVO
  crosstalk and audio-listener/GI bleed.

**LOW RISK domains** (in training data, reliable): Audio (no breaking changes
4.3→4.6), Networking (unused — no multiplayer), core scene-tree/signal
patterns, GDScript syntax fundamentals.

User decision (2026-07-11): proceed through all phases with HIGH/MEDIUM risk
items flagged inline (⚠️) rather than pausing for external verification first.
Every flagged item becomes either a Required ADR (Phase 6) with an explicit
engine-reference citation, or an Open Question if it can't be resolved without
a spike.

## System Layer Map

```
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                             │
│  MVP: Building UI ⚠️ · Villager Info UI ⚠️                        │
│  Future: Economy UI · Combat/Wave UI · Township UI ·             │
│          Main Menu & Settings                                    │
├─────────────────────────────────────────────────────────────────┤
│  FEATURE LAYER                                                  │
│  MVP: Build Validation & Navigability ⚠️ · Needs & Mood System    │
│  Future: Professions & Ranks · Relationships & Bonds ·           │
│          Trade System · Economy Balance (Sinks) ·                │
│          Wave Defense ⚠️(design) · Dungeon System ·               │
│          Township Progression/Prosperity ·                       │
│          Recipe/Blueprint Unlocks ·                               │
│          Seal Lore & World Narrative · Villager Diaries          │
├─────────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                      │
│  MVP: Building System ⚠️ · Villager AI & Behavior ⚠️              │
│  Future: Gathering & Production Chains · Storage & Inventory ·   │
│          Squad & Combat System · Save/Load & World Persistence · │
│          Audio System                                            │
├─────────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER                                                │
│  MVP (all designed): Voxel World/Grid Data ⚠️ · Camera & Input ⚠️ │
│          · Time & Tick System · Scene/World Management ·         │
│          Resource & Item Database                                │
├─────────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                                  │
│  Godot 4.7-stable engine (RenderingServer, PhysicsServer3D/Jolt, │
│  NavigationServer3D, AudioServer, DisplayServer) · Windows (PC)  │
└─────────────────────────────────────────────────────────────────┘

  Cross-cutting POLISH layer (depends on everything, not yet designed):
  Onboarding/Tutorial · Accessibility
```
⚠️ = touches a HIGH-RISK engine domain identified above.

**MVP system → layer → module boundary (what it owns exclusively):**

| System | Layer | Owns exclusively |
|---|---|---|
| Scene/World Management | Foundation | World Root lifecycle; the 3-signal transition contract (begin/complete/abort); scene attach/detach topology |
| Voxel World / Grid Data ⚠️ | Foundation | The `Vector3i`-addressed cell grid itself; raw read/write primitives; change-signal emission; procedural terrain generation |
| Camera & Input ⚠️ | Foundation | Camera position derivation; all InputMap action registration/ownership; world-ray query API; Active/Suspended state |
| Time & Tick System | Foundation | `game_delta`/pause/warp computation; the global `tick` signal; tick accumulator |
| Resource & Item Database | Foundation | Item/material definitions; boot-time validation; `missing_item` fallback; category/tier/material_family vocabulary |
| Building System ⚠️ | Core | Blueprint lifecycle (Planned→UnderConstruction→Built); construction job queue/claim contract; placement validity; undo/redo stack |
| Villager AI & Behavior ⚠️ | Core | Per-villager agent state machine; walkability predicates (ground truth for Build Validation); job-claim consumption; F1–F4 movement/selection formulas |
| Build Validation & Navigability ⚠️ | Feature | Room/enclosure/shelter analysis (read-only, event-driven); the 4-signal typed bus; never mutates Building or Villager AI |
| Needs & Mood System | Feature | Per-villager need values + mood EMA; recovery source-rate table; why-string precedence (Rule 11) |
| Building UI ⚠️ | Presentation | Toolbar/palette/stepper/undo mirror; toast identity/severity/lifecycle model; HUD hover-suppression flag (shared contract) |
| Villager Info UI ⚠️ | Presentation | Selection state (the only state it owns); villager-hit physics query; panel display (pure mirror) |

The three "open architecture decision" flags from the GDDs land squarely on
layer boundaries: Voxel World's rendering representation (Foundation↔Platform),
the raycast/picking mechanism shared by Building System and Villager Info UI
(Core↔Platform), and Villager AI/Build Validation's pathfinding approach
(Core↔Platform) — all three become Required ADRs in Phase 6.

**Approved 2026-07-11.**

## Module Ownership

**Foundation Layer**

| Module | Owns | Exposes | Consumes | Engine APIs (risk) |
|---|---|---|---|---|
| Scene/World Management | World Root node; transition state machine (Booting/Active/Transitioning) | `transition_begun()`, `transition_ended(success: bool)` signals; transition-trigger API | Resource & Item Database's Ready state (boot gate only) | `add_child`/`remove_child`/`queue_free` — **never** `change_scene_to_file`/`change_scene_to_packed`/`reload_current_scene`/direct `current_scene` assignment (explicit ban) |
| Voxel World / Grid Data ⚠️ | chunked packed cell arrays (ADR-0014; was Vector3i-keyed dictionary); terrain generation; view-window mesh streaming | `get_cell`, `raycast_cells`, `get_neighbors`, `set_cell`/`clear_cell` (Building-only), `bulk_write` (1 batched signal), `cell_changed`/`cells_changed_batch` signals, `iterate_occupied` | Resource & Item Database ids (opaque, stored not resolved) | Typed `Dictionary[Vector3i,...]` (4.4+ ⚠️ verify syntax); raycast vs. manual DDA picking (⚠️ open ADR); `FastNoiseLite` for terrain |
| Camera & Input ⚠️ | Spherical camera params; InputMap action registrations; Active/Suspended state | `action_fired(name)` (opaque passthrough — never interprets it); `world_ray()`; ground-plane intersection | Scene/World Management's transition signals (drives Suspended) | `Camera3D.project_ray_origin/project_ray_normal` (⚠️ re-verify vs 4.7); must never branch on `DEVICE_ID_MOUSE/KEYBOARD` (design already avoids the 4.7 risk) |
| Time & Tick System | `game_delta`; pause/warp state; tick accumulator | `tick()` global signal; `game_delta` getter; `pause()`/`resume()`/`set_warp()` (synchronous return) | *Nothing* — explicit non-dependency contract, not even Scene/World Management | `_physics_process` fixed-step (default 60Hz, ⚠️ confirm unchanged); **forbidden**: `Engine.time_scale`, `SceneTree.paused` |
| Resource & Item Database | Item/material definitions; validation results; `missing_item` fallback; retired-ids ledger | `get_by_id`, `list_ids_by_category/material_family/tier`, `list_all_ids` (read-only) | *Nothing* — boot-time file load only | `FileAccess`/`Resource` loading (⚠️ 4.4 return-type change); `duplicate_deep()` (⚠️ 4.5+, if chosen as the immutability mechanism) |

**Core Layer**

| Module | Owns | Exposes | Consumes | Engine APIs (risk) |
|---|---|---|---|---|
| Building System ⚠️ | Blueprint 4-state lifecycle; construction job queue; undo/redo stack; placement-validity engine; tool state machine | `commit_command`, `claim_job`/`release_job`/`on_site_check`, combined occupancy query, `undo()`/`redo()`, `construction_completed_batch` signal, `furniture_revoked` signal, tool-state query | Voxel World (read + `bulk_write`); Resource & Item Database (palette query); Time & Tick (`tick`); Camera & Input (`world_ray`, `action_fired`); Scene/World Management (`transition_ended` → clear undo stack) | Raycast pick (⚠️ shared ADR with Voxel World); pooled MeshInstance3D ghost rendering (ADR-0014); `InputEventKey.echo` for undo/redo repeat |
| Villager AI & Behavior ⚠️ | Per-villager state machine; walkability predicates (**canonical ground truth**); bed ownership; F1–F4 formulas; injected RNG | State/position/activity query (read by UI); `start_recovery`/`stop_recovery` calls (into Needs); walkability query (consumed by Build Validation) | Voxel World (occupancy read + write-signal subscribe); Time & Tick (`tick`); Building System (`claim_job`/`release`/`on_site`); Needs & Mood (polls `has_urgent_need(villager_id)` at every decision point — never trusts the threshold-cross events alone); Building System's `furniture_revoked` | `NavigationServer3D`/`NavigationAgent3D` vs. custom `AStar3D`/`AStarGrid3D` (⚠️ open ADR); typed `Dictionary` (⚠️) |

**Feature Layer**

| Module | Owns | Exposes | Consumes | Engine APIs (risk) |
|---|---|---|---|---|
| Build Validation & Navigability ⚠️ | Room/enclosure classification; transient (non-persisted) snapshot | 4-signal typed bus: `shelter_status_changed`, `room_recognized`, `sealed_space_warning`, `unsheltered_furniture_info`; queryable room-status/warnings state | Voxel World (read-only occupancy); Building System's `construction_completed_batch` (trigger); Villager AI's walkability constants (read-only reference — **zero** calls into either system's mutators, verified by mock call-count) | Same flood-fill vs. `NavigationServer3D` rebake question as Villager AI (⚠️ shared ADR) |
| Needs & Mood System | Per-villager need floats; mood EMA; recovery source→rate table; why-string precedence | `get_need_value`/`get_mood`/`get_why_string` query; `has_urgent_need` (pure urgency gate, polled by Villager AI's decision loop — ADR-0008); urgency/satisfied threshold-cross events (latency hints only) | Time & Tick (`tick`); Villager AI's `start_recovery`/`stop_recovery` (Needs is the callee); Build Validation's `shelter_status_changed`; Building System's `furniture_revoked` | None engine-specific — pure GDScript logic (LOW risk) |

**Presentation Layer**

| Module | Owns | Exposes | Consumes | Engine APIs (risk) |
|---|---|---|---|---|
| Building UI ⚠️ | Toast/anchor presentation state (session-local, unserialized); per-tool last-material memory; **HUD hover-suppression flag** | Hover-suppression flag (shared contract — consumed by Building System's pick AND Villager Info UI's selection query) | Building System (pure mirror); Build Validation (state + signals); Time & Tick (pause/warp synchronous API); Resource & Item Database (palette query); Scene/World Management (Suspended-tied timer pause); Camera & Input (InputMap actions) | `Control` theme/focus (⚠️ 4.6 dual-focus system); `Timer`/`Tween` pause-with-Control-hidden semantics (⚠️ non-obvious gap flagged in-GDD); `InputEventKey.echo` |
| Villager Info UI ⚠️ | Selection state (villager id/handle) — the **only** state it owns | *Nothing outward* (leaf node) | Villager AI (state/position/distress query); Needs & Mood (need/mood/why-string, verbatim); Building UI (hover-suppression flag + armed-tool state); Camera & Input (click action) | Dedicated villager collision layer for hit-testing (⚠️ shared risk with Building's picking ADR); billboard/outline rendering (deferred to shader) |

**Dependency diagram (MVP systems only):**

```
Foundation:  Resource&ItemDB   VoxelWorld   Camera&Input   Time&Tick   Scene/WorldMgmt
                    │               │            │             │            │
                    │  (ids, opaque)│            │(Suspended)  │            │(boot gate)
                    ▼               ▼            │◄────────────┘            │
Core:          BuildingSystem ◄─────┴──────────────┘                        │
                    │      ▲                                                │
      (bulk_write,  │      │(claim/release/on_site)                        │
       tick, ray)    │      │                                                │
                    ▼      │                                                │
              VillagerAI ──┘◄──────────(occupancy read + re-path signal)────┤
                    │  ▲                                                    │
      (walkability, │  │(start_recovery/stop_recovery)                     │
       poll needs)   │  │                                                   │
                    ▼  │                                                   │
Feature:    BuildValidation      NeedsAndMood ◄────────────────────────────┘
                    │  (4-signal bus)   │ (why-string, mood, need)
                    │                    │
                    ▼                    ▼
Presentation:  BuildingUI ───────► VillagerInfoUI
              (hover-suppress flag,
               armed-tool state — shared contracts)

Legend: solid arrow = "consumes API/signal of". BuildValidation → BuildingSystem
and BuildValidation → VillagerAI arrows are READ-ONLY (never call a mutator —
the never-blocks invariant, verified by mock call-count per the GDD's ACs).
```

No dependency cycles among MVP modules. The Building↔Township circular
dependency flagged in systems-index.md does not surface here (Township
Progression is Alpha-tier, not yet designed).

**Approved 2026-07-11.**

## Data Flow

### 1. Frame update path

```
RAW FRAME (_process, every frame, unscaled delta):
  Input → Camera & Input (rotate/zoom/pan; emits action_fired)
        → Building UI / Villager Info UI (poll upstream state on RAW delta —
          pure mirror, stays responsive during pause)
        → Villager AI (movement INTERPOLATION only — continuous, smooth,
          decoupled from tick-gated decision logic)
        → Rendering (camera position, meshes, UI redraw)

PHYSICS FRAME (_physics_process, fixed 60Hz, drives Time & Tick's accumulator):
  Time & Tick: tick_accumulator += game_delta; while >= tick_interval: fire tick()
    tick() ⇒ Building System   (construction progress, burst-capped per job)
    tick() ⇒ Villager AI       (decide → travel-step → perform → re-evaluate,
                                 burst-capped, at most 1 decision re-eval/tick)
    tick() ⇒ Needs & Mood      (F1 decay → F2 recovery → F3 mood EMA, strict
                                 per-tick order, intra-tick before next system)
```
Two clocks, deliberately: raw delta keeps camera/UI alive through pause;
`game_delta`/`tick` drives simulation and is the only clock Building/Villager
AI/Needs read.

### 2. Event/signal path

| Signal | Producer | Consumer(s) | Notes |
|---|---|---|---|
| `cell_changed` / `cells_changed_batch` | Voxel World | Building System (undo-invalidation, self-write-exempt); Villager AI (re-path filter — only if it intersects the remaining path + clearance envelope) | Event-driven, zero polling |
| `construction_completed_batch` | Building System | Build Validation & Navigability | Triggers exactly one re-analysis pass per frame-batch |
| `shelter_status_changed` | Build Validation | Needs & Mood (feeds recovery-source enum); Building UI (toast/anchor reconciliation) | Level-triggered, no "cleared" variant — consumers reconcile against each pass's emission set |
| `room_recognized` | Build Validation | *(internal only — drives Build Validation's own celebration VFX/audio)* | Explicitly **not** consumed by Building UI's toast system |
| `sealed_space_warning` / `unsheltered_furniture_info` | Build Validation | Building UI | Feeds the toast identity/severity/grace/debounce model |
| `transition_begun` / `transition_ended` | Scene/World Management | Camera & Input (Suspended entry/exit); Building System (undo-clear on COMPLETE only, never begin); Building UI (Suspended-tied timer pause/resume-with-remaining-time); Villager Info UI (Suspended state — selection retained, not cleared) | Villager AI has **no** Suspended state — keeps simulating through transitions |
| `furniture_revoked` (targeted, per-owner) | Building System | Villager AI | Villager AI reacts (wake, dissolve bed ownership, re-enter Deciding) and **itself calls** `Needs.stop_recovery()` — not a direct Building→Needs signal |
| urgency/satisfied threshold-cross events | Needs & Mood | Villager AI | Latency hints only — Villager AI still polls authoritative need state at decision points, never trusts the event alone |

### 3. Save/Load path

Save/Load & World Persistence is Vertical-Slice tier (not yet designed), but
every MVP GDD already declares its serialization contract:

| Module | Serializes | Notes |
|---|---|---|
| Voxel World | Occupied cells only, via `iterate_occupied()` | Decoupled from internal storage representation |
| Resource & Item Database | *Nothing* | Definitions are static data, re-loaded fresh; other systems store only ids |
| Building System | Open blueprint cells + per-cell construction progress | Undo/redo stack **explicitly excluded** |
| Villager AI | Position, activity, claimed job id, owned bed, need levels | Must re-validate stale claim/bed ids on load without crashing |
| Needs & Mood | Per-villager need values + smoothed mood state | Mood restored **as-saved**, never re-initialized via the F4 spawn formula |
| Build Validation & Navigability | *Nothing* | Full re-derive on every load; must reproduce pre-save statuses identically, suppressing `room_recognized`/`shelter_status_changed` transition events while still emitting persisting-cause warnings |
| Scene/World Management | *(triggers, doesn't own data)* | Savepoint creation is bound exclusively to `transition_ended(success=true)` |

Load sequence: Resource & Item Database Ready → Save/Load reads file → Voxel
World bulk-populated → Building System blueprints/progress restored →
Villager AI villagers restored (stale-id revalidation) → Needs & Mood restored
→ Build Validation runs **one** full analysis pass (load-time rebuild,
transition-events suppressed) → UI reflects final state.

### 4. Initialization order

```
1. World Root instantiated (Scene/World Management)
2. Resource & Item Database: Unloaded → Validating → Ready | Failed
                              ── BLOCKING GATE ── Failed = terminal halt screen
3. Voxel World generates terrain (synchronous, deterministic seeded noise)
4. Valley scene attaches under World Root
5. Camera & Input, Time & Tick initialize (defaults: paused=false, warp=1)
6. Building System initializes            ┐  both gated on step 2's Ready
7. Villager AI initializes (roster placed) ┘
8. Needs & Mood initializes (F4 spawn-init per starting villager)
9. Build Validation runs initial analysis pass (no rooms yet on fresh boot;
   full load-time pass instead if restoring a save)
10. Building UI / Villager Info UI attach, begin mirroring (Idle, no selection)
```
The step-2→6/7 gate is the sharpest boot-order constraint in the GDDs and has
no owning mechanism yet — it becomes a **Required ADR** in Phase 6.

**Approved 2026-07-11.**

## API Boundaries

Public contracts per module, in GDScript per this project's static-typing
standard. Each block shows only the *exposed* surface — full implementation
is a `/dev-story` concern, not architecture.

```gdscript
# ── Scene/World Management ──────────────────────────────────────────
signal transition_begun()
signal transition_ended(success: bool)
func request_dungeon_entry(dungeon_id: StringName) -> void
func request_valley_return(leave_reason: LeaveReason) -> void
func get_transition_state() -> TransitionState  # Booting | Active | Transitioning
# INVARIANT: exactly one of complete/abort fires per begin, exactly once.
# GUARANTEE: World Root is never freed. This is the ONLY legal entry point
# for scene topology change — direct change_scene_to_file()/current_scene
# assignment anywhere else in the codebase is a code-review-blocking violation.

# ── Voxel World / Grid Data ⚠️ ───────────────────────────────────────
signal cell_changed(cell: Vector3i, before: CellData, after: CellData)
signal cells_changed_batch(changes: Array[CellChange])
func get_cell(cell: Vector3i) -> CellQueryResult      # .in_bounds, .data — never silently clamps
func raycast_cells(from: Vector3, to: Vector3) -> RaycastResult
func get_neighbors(cell: Vector3i) -> Array[Vector3i]
func set_cell(cell: Vector3i, data: CellData) -> WriteResult    # Building System only, by convention
func clear_cell(cell: Vector3i) -> WriteResult                  # Building System only, by convention
func bulk_write(changes: Array[CellChange]) -> BulkWriteResult  # GUARANTEE: exactly 1 signal
func iterate_occupied() -> Array[Vector3i]                      # Save/Load only
# INVARIANT: single cell read/write is O(1). Writes serialized — no torn reads.
# ⚠️ raycast_cells' mechanism (native physics vs. manual DDA) is undecided —
#   the ADR must not change this function's signature, only its internals.

# ── Camera & Input ⚠️ ────────────────────────────────────────────────
signal action_fired(action_name: StringName)   # opaque passthrough ONLY
func get_world_ray() -> Dictionary   # {origin: Vector3, direction: Vector3} — always computable, even Suspended
func get_ground_plane_intersection() -> Vector3
func get_camera_state() -> CameraState  # Active | Suspended
# INVARIANT: never branches on action_name or input device id.
# GUARANTEE: exactly one owner per click — if a Control consumed it
# (mouse_filter STOP), no world-action fires for that same click.

# ── Time & Tick System ───────────────────────────────────────────────
signal tick()
func get_game_delta() -> float
func is_paused() -> bool
func get_time_warp() -> int                # {1, 2, 3}
func set_paused(value: bool) -> bool       # returns new state, SYNCHRONOUS
func set_time_warp(value: int) -> int      # returns new state, SYNCHRONOUS
# GUARANTEE: ticks never fire while paused; pause is idempotent; warp changes
# while paused don't touch game_delta until unpause. Callers MUST derive
# durations from observed tick COUNTS, never wall/game-clock arithmetic.

# ── Resource & Item Database ─────────────────────────────────────────
signal validation_complete(result: ValidationResult)  # added by ADR-0005 — Scene/World Management's boot gate connects to this
func is_ready() -> bool
func get_by_id(id: StringName) -> ItemDefinition   # ADR-0006: returns an immutable getter-only view; missing_item fallback, logged once/load
func list_ids_by_category(category: StringName) -> Array[StringName]
func list_ids_by_material_family(family: StringName) -> Array[StringName]
func list_ids_by_tier(tier: int) -> Array[StringName]
func list_all_ids() -> Array[StringName]            # excludes missing_item
# GUARANTEE: returned ItemDefinition is immutable to the caller. No write API
# exists — mechanism (defensive copy vs. read-only Resource) is a data-arch ADR.

# ── Building System ⚠️ ───────────────────────────────────────────────
signal construction_completed_batch(cells: Array[Vector3i])
signal furniture_revoked(villager_id: int, furniture_cell: Vector3i)
func commit_command(cells: Array[Vector3i], tool: ToolType, material_id: StringName) -> CommitResult
func get_combined_occupancy(cell: Vector3i) -> OccupancyState  # Voxel World + blueprint
func claim_job(villager_id: int) -> JobHandle    # nearest-reachable, atomic — exactly 1 winner
func release_job(job_handle: JobHandle) -> void
func on_site_check(villager_id: int, job_handle: JobHandle) -> bool
func undo() -> void
func redo() -> void
func get_tool_state() -> ToolState               # Idle | ToolArmed(tool) | Dragging | Suspended
# INVARIANT: max_cells_per_command enforced; one job per villager at a time.
# GUARANTEE: construction_completed_batch fires AT MOST ONCE per frame,
# regardless of cell/command/villager count that frame.

# ── Villager AI & Behavior ⚠️ ────────────────────────────────────────
func get_state(villager_id: int) -> VillagerState   # 6-value activity enum + position + distress flags
func is_walkable(cell: Vector3i) -> bool            # CANONICAL ground truth — Build Validation must reuse, not redefine
func is_standable(cell: Vector3i) -> bool
# Villager AI CONSUMES (does not expose) Needs & Mood's start_recovery/stop_recovery
# as the caller, and polls its has_urgent_need(villager_id) at every decision
# point — see Needs & Mood block below.
# GUARANTEE: never teleports/clips/despawns a trapped villager. Deterministic
# same-tick claim-contention resolution via stable villager processing order.

# ── Build Validation & Navigability ⚠️ ───────────────────────────────
signal shelter_status_changed(item_cell: Vector3i, source_enum: RecoverySource)
signal room_recognized(pass_group_id: int, room_ids: Array[int])
signal sealed_space_warning(region_id: int, why_string: String)
signal unsheltered_furniture_info(item_cell: Vector3i, why_string: String)
func get_room_status(cell: Vector3i) -> RoomStatus
func get_active_warnings() -> Array[WarningRecord]
# INVARIANT (mock-call-count-verified in tests): ZERO calls into Building
# System's or Villager AI's mutating APIs, ever. Pure analysis, one direction.

# ── Needs & Mood System ──────────────────────────────────────────────
func start_recovery(villager_id: int, need: StringName, source_enum: RecoverySource) -> void
func stop_recovery(villager_id: int, need: StringName, reason: StringName) -> void
func get_need_value(villager_id: int, need: StringName) -> float   # 0-100
func get_mood(villager_id: int) -> float                            # 0-100, EMA-smoothed
func get_why_string(villager_id: int) -> String
func has_urgent_need(villager_id: int) -> bool   # REQUIRED — the urgency gate Villager AI's
                                                  # decision loop polls every tick (ADR-0008)
signal need_urgent(villager_id: int, need: StringName)      # latency hint only
signal need_satisfied(villager_id: int, need: StringName)   # latency hint only
# GUARANTEE: mood has ZERO consuming references in scheduling/work code (MVP,
# display-only — statically checkable).
# GUARANTEE: has_urgent_need is a PURE QUERY — emits no signal, mutates no state,
# and never lazily initializes a villager's need record as a side effect of being
# asked. An unknown/despawned villager_id returns false WITHOUT creating a record.
# Nil-safety for an unwired provider belongs to the CALLER
# (VillagerAi._has_urgent_need's existing guard) — Needs & Mood carries no
# null-provider branch of its own.

# ── Building UI ⚠️ (leaf — exposes one shared flag, nothing else outward) ─
func is_hover_suppressing_world_pick() -> bool   # shared contract: read by
                                                  # Building System's pick AND
                                                  # Villager Info UI's selection query

# ── Villager Info UI ⚠️ (leaf — exposes nothing outward) ─────────────
func get_selected_villager() -> int   # -1 if none
```

Two contracts are load-bearing across the whole architecture: the
**never-blocks invariant** (Build Validation calls nothing mutating, ever)
and the **hover-suppression flag** (a single boolean, owned by Building UI,
read by two unrelated systems — a shared-mutable-flag pattern whose update
timing needs an ADR, not just a signature).

**Approved 2026-07-11.**

## ADR Audit

**ADR Quality Check**: Confirmed via directory scan — zero ADRs exist in
`docs/architecture/` (only `tr-registry.yaml`, still an empty template). This
is the project's first architecture pass, so the quality table and
conflict-detection are trivially empty — there's nothing yet to check for
staleness, engine-compat gaps, or conflicts with this session's layer/
ownership decisions.

**Traceability Coverage Check** (349 TRs from the session's Technical
Requirements Baseline, 0 existing ADRs, 0 covered): rather than forcing an
ADR per individual TR — most of the 349 are already fully specified by their
GDD (exact formulas, enums, state machines, signal payloads) and need no
separate technical decision, just implementation — TRs were sorted into two
buckets:

- **~295 TRs are GDD-specified and implementation-ready without a dedicated
  ADR.** Traceability for these is satisfied directly by their GDD + this
  document's Module Ownership/API Boundaries sections. A story implementing
  them cites the GDD's AC + this doc; escalate to an ADR only if
  implementation reveals a genuine engine-compatibility conflict.
- **~54 TRs represent a genuinely open technical decision** — an
  engine-capability tradeoff, a cross-system coupling pattern, or an explicit
  "deferred to ADR" flag written into the GDD text itself. These cluster into
  13 candidate ADRs, detailed below.

Interpretive call, recorded per user approval (2026-07-11): "ADR-worthy" means
*the requirement represents a choice*, not *the requirement exists*. A
stricter 1:1 TR-to-ADR mapping was offered and explicitly declined.

## Required ADRs

**Must have before coding starts (Foundation & Core decisions):**

1. `/architecture-decision "Inter-System Reference & Dependency-Injection Pattern"` → covers: TR-building-ui-038, TR-villager-info-ui-023, TR-villager-ai-behavior-016, TR-resource-item-database-007, TR-needs-mood-system-025 — *how modules find each other* (autoload singletons vs. service locator vs. exported references) is presupposed by every other module-boundary decision in this doc and by the "headless-mockable" testability requirement repeated across 5+ GDDs. Nothing else can be implemented cleanly until this is decided.
2. `/architecture-decision "Tuning/Config Data Strategy"` → covers: TR-scene-world-management-030, TR-voxel-world-023, TR-camera-input-019, TR-time-tick-system-020, TR-building-system-038, TR-building-ui-037 (and the "data-driven, never hardcoded" clause in effectively every GDD's Tuning Knobs section) — one config format/loading mechanism (`.tres` Resource vs `ConfigFile` vs JSON) for the whole project.
3. `/architecture-decision "Voxel World Rendering Approach"` → covers: TR-voxel-world-025, TR-building-system-003/035/039/041, game-concept.md's own Open Question — the keystone decision (GridMap vs MultiMeshInstance3D vs chunked/greedy mesher) carried forward from the systems-design gate as "FIRST, provisional-pending-spike."
4. `/architecture-decision "3D Physics Backend & Picking/Raycast Strategy"` → covers: TR-voxel-world-017/018, TR-building-system-002/026, TR-villager-info-ui-014/015 — Jolt-vs-GodotPhysics3D plus the native-raycast-vs-DDA cell-picking mechanism; sequenced after #3 since the rendering choice constrains which picking strategies are viable.
5. `/architecture-decision "Boot Sequencing & System Initialization Gate"` → covers: TR-scene-world-management-004/023, TR-resource-item-database-019 — the Resource & Item Database Ready gate before Building/Villager AI init is the sharpest boot-order constraint in the GDDs and has no owning mechanism yet.
6. `/architecture-decision "Data Definition Immutability & Reference Format"` → covers: TR-resource-item-database-010/023 — defensive-copy vs. read-only Resource vs. immutable wrapper, plus `visual_asset` path-string vs. typed-Resource reference.

**Core Layer:**

7. `/architecture-decision "AI Pathfinding, Navigation & Room-Analysis Architecture"` → covers: TR-villager-ai-behavior-009/010/011/035/036, TR-build-validation-navigability-008/009/019 — NavigationServer3D vs. custom AStar3D/AStarGrid3D; must serve both villager movement and Build Validation's room/enclosure flood-fill, since both consume the identical walkability rules.
8. `/architecture-decision "Villager AI Execution & Threading Strategy"` → covers: TR-villager-ai-behavior-013/041/047 — Deciding-pass staggering, tick-burst budget, and whether/how Godot's worker-thread-pool applies at the 20-30 population ceiling.
9. `/architecture-decision "Deterministic Movement/Occupancy Intra-Frame Ordering"` → covers: TR-building-system-040, TR-villager-ai-behavior-046 — the "mid-path solidification race" both GDDs independently flagged as unresolved: does a villager's continuous position update or a same-frame Voxel World write win?

**Feature / cross-cutting:**

10. `/architecture-decision "Cross-System UI/World Input Arbitration"` → covers: TR-camera-input-020, TR-building-ui-028/029, TR-villager-info-ui-002 — the hover-suppression flag's update timing and the exactly-one-owner-per-click contract, shared by 3 systems.
11. `/architecture-decision "UI Timer/Expiry Management Pattern"` → covers: TR-building-ui-014/015/018/040 — centralized expiry-timestamp manager vs. N per-issue `Timer` nodes, needed correctly for grace/debounce/invalid-cue semantics under Suspended.

**Should have before the relevant system is built:**

12. `/architecture-decision "Save/Load Serialization Strategy"` → covers: TR-voxel-world-021, TR-building-system-023/033, TR-villager-ai-behavior-027, TR-needs-mood-system-026..029, TR-scene-world-management-013/024 — VS-tier (Save/Load isn't MVP), but every MVP GDD already commits to a serialization contract this ADR must honor.
13. `/architecture-decision "Multi-Scene Concurrency Model (Valley + Dungeon)"` → covers: TR-scene-world-management-033 — WorldEnvironment/Camera3D.current/audio-listener/NavigationServer3D-map partitioning; VS-tier (no Dungeon scene exists at MVP).

**Can defer to implementation:**
- Villager identity/handle stability across Suspended transitions — GDD already labels this `[assumption]`, resolve when Villager AI's identity system is actually built (TR-villager-info-ui-010).
- Distress-icon billboard mode (full-billboard vs. Y-locked) — pure shader/implementation detail once the camera-angle is finalized (TR-villager-info-ui-027).
- Non-Flat roof formation algorithms (Gable/Hip/Shed) — Flat is MVP-sufficient; the other 3 are VS scope (TR-building-system-007).

**Approved 2026-07-11.**

## Architecture Principles

1. **UI is a pure mirror — never a second source of truth.** Every displayed
   value is read from its owning system; UI-local state is limited to
   session-scoped presentation bookkeeping (toast timers, last-selected
   material) that nothing else ever consumes.
2. **Two clocks, cleanly separated.** Raw delta drives camera/input/UI so they
   stay responsive through pause; `game_delta`/`tick` drives simulation. The
   engine's global `Engine.time_scale`/`SceneTree.paused` are permanently
   forbidden — confirmed again by this session, not just carried from
   `technical-preferences.md`.
3. **Event-driven, not polled.** Systems react to signals (`cell_changed`,
   `construction_completed_batch`, the Build Validation 4-signal bus); the
   only sanctioned per-frame poll is UI reading upstream state, justified
   specifically by the pause-responsiveness requirement.
4. **Analysis observes, it never corrects.** Read-only validation/analysis
   layers (Build Validation today, likely Economy Balance or a future Wave
   Defense telemetry system later) must never call a mutating API on the
   systems they watch — verified by mock call-count in tests, not just
   convention.
5. **Determinism is a first-class constraint.** Every simultaneous-event or
   tie-break case (job-claim contention, tick-burst ordering, wander/
   nudge-aside selection) resolves via a stable, injected, testable rule —
   never engine-dependent iteration order.

## Open Questions

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ1 | Wave-defense ↔ freeform-base spatial contract undefined — no chokepoint concept against a fully player-authored settlement | High | `/prototype wave-defense` (pre-dates this architecture; a future Squad & Combat System architecture pass consumes the result) |
| QQ2 | Township "prosperity" — the core progression-gating variable — is unnamed even as a candidate | Medium | Must be defined as an explicit function of measurable state in the Township Progression GDD before that system gets its own architecture pass |
| QQ3 | ~~Rendering/Pathfinding/AI-execution ADRs provisional pending the pre-VS performance spike~~ **RESOLVED 2026-07-11**: spike PASSED at ADR-ceiling scale (`prototypes/perf-spike-qq3/REPORT.md`) — ADR-0003/0007/0008 Accepted. Deliverable: `max_deciding_per_tick = 1`. Watch-items: draw-call density margin ~20%, Deciding-pass cost (mitigations named in report), BFS boundary ~12k connected cells | ~~High~~ Closed | Done |
| QQ4 | Villager identity/handle stability across Suspended transitions is `[assumption]` in villager-info-ui.md | Low | Resolve when Villager AI's identity system is implemented |
| QQ5 | ~~Nav graph at large-world scale unmeasured~~ **RESOLVED 2026-07-11**: region-bounded spike (perf-spike-qq3 s5) — patch cost FLAT ~0.37 ms at every region size; query p95 1.8 ms @100^2 / 9.2 ms @200^2 / 24-49 ms @300^2+ (frame-breaking). **Settlement-core nav region committed <= 200x200** (47k points, 1.1 s boot build, 73 MB); growth past that requires hierarchical/regional graphs (named escape hatch in ADR-0007) | ~~High~~ Closed | Done |

**Approved 2026-07-11.**
