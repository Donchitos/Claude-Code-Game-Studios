## The Valley scene (Scene/World Management Story 001, ADR-0001 + ADR-0013).
##
## A thin, self-contained hosting container -- NOT an injected-tier DI module
## in its own right (it owns no [method setup] and takes no part in the boot
## gate, ADR-0005). Its sole responsibility is scene TOPOLOGY: it is the
## child the World Root ([GameWorld]) attaches at boot
## [TR-scene-world-management-034], and it is the structural PARENT every
## Foundation/Core system that needs a stable session-lifetime root attaches
## under [TR-scene-world-management-035] [TR-scene-world-management-036] --
## a hosting relationship, not a data dependency: this class never calls any
## hosted child's [code]setup()[/code]. [GameWorld]'s
## [code]_setup_injected_tier()[/code] remains the ONLY sanctioned call site
## for that (ADR-0005) -- wiring a hosted child into that array, if/when its
## own epic's boot-integration story needs it, is out of this story's scope.
##
## Hosted children landed by this story -- both already exist as
## injected-tier modules per their own epics, and are wired here purely
## structurally (config assigned so the node is inspector-sane; `setup()`
## is deliberately never called from here): [VoxelWorldGrid], [CameraInput].
##
## Time & Tick System is Autoload-tier (ADR-0001; `neues-spiel/CONTRACTS.md`
## §1) -- it is never a scene child of anything, including Valley. This is a
## standing architectural fact predating this story, not a gap it introduces.
##
## Story scene-004 (THE INTEGRATION CROWN, ADR-0001 primary, ADR-0005/0013
## secondary) adds the remaining Foundation/Core tier modules the GDD names
## as hosted systems, now that their own epics have landed real code:
## [VoxelWorldMesher] (`voxel-world` epic, vox-007), the four Building System
## modules [ToolStateMachine]/[PlacementPick]/[CommitPipeline]/
## [ConstructionTickLoop] (`building-system` epic, stories 019-021/029), and
## one [VillagerAi] instance (`villager-ai-behavior` epic, stories 001-009;
## `starting_villager_count` GDD default is 1 at MVP scope -- multi-villager
## spawning is a future world-generation story's job, out of this story's
## scope). Each module's own config Resource IS wired via `Valley.tscn`'s
## Inspector (mirroring the existing [VoxelWorldGrid]/[CameraInput]
## precedent exactly) -- but the Node-typed CROSS-REFERENCES between hosted
## siblings (e.g. [member PlacementPick.camera_input]) are assigned in code,
## by [method _wire_hosted_modules] below, NOT via a `NodePath(...)` value
## authored directly in the scene file: verified against the running engine
## that a hand-authored text `.tscn` assigning a `NodePath` literal to a
## Node-typed `@export` property does NOT auto-resolve to the referenced
## Node at scene instantiation (the property is left `null`) -- only the
## editor's own node-picker workflow produces a resolvable reference this
## way. [method _wire_hosted_modules] runs in [method _ready], mirroring
## [method _wire_villager_population]'s own already-established
## code-wiring precedent, so this remains code-assigned, not Inspector-wired,
## DI -- `setup()` is still never called from here (ADR-0005: the SOLE
## `setup()` call site remains [method GameWorld._setup_injected_tier],
## reached via [method get_injected_tier_modules] below, not a second one on
## this class).
##
## M01 Go/No-Go condition C4 (`production/milestones/milestone-01-review-
## 2026-07-26.md`, criterion #9's "visible in the build" gap) additionally
## hosts [TorchFlicker] (`presentation-experience` epic, story presentation-001
## Sub-scope A) driving a real [OmniLight3D] ("AmbientTorchLight", a structural
## child of this class, not itself an injected-tier module -- a plain light
## has no `setup()`) -- wired exactly like every other hosted sibling above:
## [member TorchFlicker.config] is Resource-typed and Inspector-assigned
## directly on `Valley.tscn` (Story scene-004's own established "a Resource
## export resolves fine from a hand-authored `.tscn`, only Node-typed
## cross-references need code assignment" distinction), while
## [member TorchFlicker.light] (Node-typed) is code-assigned in [method
## _wire_hosted_modules] below, mirroring [member
## VoxelWorldMeshStreamer.grid]/[member VoxelWorldMeshStreamer.mesher]'s own
## precedent exactly. [TorchFlicker] IS appended to [method
## get_injected_tier_modules] (it has a real `setup()`/`is_set_up()` contract,
## [GameWorld] calls it same as every other hosted module) -- this is a
## genuine wiring of already-landed presentation code into the real Valley,
## not a rebuild of it.
##
## **Honest scope note, not silently narrowed**: presentation-001 Sub-scope A
## shipped FOUR ambient elements ([ChimneySmokeEmitter], [TorchFlicker],
## [InteriorClutterPlacer], `foliage_sway.gdshader`) -- only [TorchFlicker] is
## wired here. The other three each require a REAL host system this codebase
## does not yet have in the boot chain: [ChimneySmokeEmitter]'s one gating
## input, [method ChimneySmokeEmitter.set_occupied_lit], has no real
## occupied/lit data source anywhere yet (that class's own doc comment --
## "does not exist yet anywhere in this codebase"), so wiring it here would
## mean driving it from an invented/fake signal, which this story explicitly
## does not do; [InteriorClutterPlacer] needs a real room/building fixture to
## place its scene-authored `clutter_transforms` inside, and no fixture/
## building-interior entity exists yet (Valley boots with an EMPTY
## [VoxelWorldGrid] -- no `generate_terrain()` call anywhere in the boot chain,
## by this class's own long-standing design, a future world-generation
## story's job per this class's already-existing doc comment above); the
## foliage shader needs a real vegetation-placement host over real terrain,
## which the same empty-world fact rules out today. [TorchFlicker] alone needs
## neither a fixture, a room, nor terrain -- only a positioned [Light3D] --
## which is exactly why it is the one component this condition can honestly
## close today; the other three remain the CD's own already-tracked Sub-B/
## wave-2 backlog (`ambient-life-wave-1-evidence.md`), not silently dropped.
##
## Story vox-018 (ADR-0014 primary -- the deferred live-wiring integration
## `VoxelWorldMeshStreamer`'s own class doc comment explicitly named as a
## LATER story's job; ADR-0015 secondary) additionally hosts
## [VoxelWorldMeshStreamer], structurally, exactly like every other hosted
## sibling above -- [method _wire_hosted_modules] code-assigns its
## [member VoxelWorldMeshStreamer.grid]/[member VoxelWorldMeshStreamer.mesher]
## cross-references; `setup()` is still ONLY ever reached via
## [method GameWorld._setup_injected_tier] (this class calls it nowhere).
## [method _process] is this story's ONE new per-frame hook on this class:
## every engine frame it reads the hosted [CameraInput]'s current orbit
## target ([method CameraInput.get_target] -- the SAME ground-plane point
## `tools/camera_sandbox.gd` already mirrors onto its own driven [Camera3D]
## every frame, not the mouse-dependent world-ray/ground-pick, which would
## tie the mesh STREAMING window to wherever the cursor happens to point
## rather than to where the camera itself actually is), converts it to a
## cell via [method VoxelWorldGrid.world_to_cell] (the same conversion
## [PlacementPick] already uses for its own screen-ray pick), and forwards it
## to [method VoxelWorldMeshStreamer.update_view_window] -- the budgeted,
## per-frame streaming step vox-015 built and proved correct in isolation,
## now finally driven by a live, continuously-moving focus point in
## production. The UNBOUNDED initial window build
## ([method VoxelWorldMeshStreamer.build_initial_window], vox-015 AC-3) is
## deliberately NOT called from here -- it must run exactly once, during
## [GameWorld]'s own boot/WIRING sequence, strictly before this class's first
## `_process` call ever lands (so the ~2.6s unbounded build is never
## interleaved with the budgeted per-frame path) -- see
## [method GameWorld._build_initial_voxel_mesh_window] for that call site and
## its own doc comment for the honest note on today's boot-overlay gap.
##
## **The villager population's non-`@export` shared collaborators**
## ([VillagerDecidingScheduler], [VillagerNavGraph]) cannot be Inspector-wired
## -- both are plain `RefCounted`, not `Node`/`Resource` (see each class's own
## doc comment for why). [method _wire_villager_population] performs that DI
## assignment structurally, in [method _ready] -- which fires for this
## instance (and every child already Inspector-wired beneath it, per Godot's
## bottom-up `_ready()` ordering) strictly BEFORE [GameWorld] can ever reach
## [method get_injected_tier_modules]/[method GameWorld._setup_injected_tier]
## for this SAME instance (that call chain only runs from [method
## GameWorld._on_database_settled], itself only reached AFTER [method
## GameWorld._attach_valley] has already returned). This is what satisfies
## [VillagerAi]'s own documented "wiring-order requirement" doc comment:
## [method VillagerNavGraph.subscribe_to_voxel_world] runs here, before any
## [VillagerAi]'s own `setup()` is ever called. Deliberately does NOT call
## [method VillagerNavGraph.build] -- this story adds no world-generation
## step to [GameWorld]'s boot sequence (a fresh grid has no terrain yet, so a
## graph built now would hold zero points; a future world-generation story
## re-derives/patches it once real terrain exists, per that class's own
## documented "idempotent/re-buildable" contract) -- out of this story's
## explicit "no new gameplay features" scope.
##
## Story villager-ai-021 (this revision, GDD Rule 14b /
## [TR-villager-ai-behavior-065]) adds the config-driven STARTING ROSTER
## capability -- [method spawn_starting_roster] -- built on the new
## [VillagerRosterSpawner] library (placement + assembly, see that class's
## own doc comment). [member _villager_ai] (villager_id 0, the pre-existing
## single hosted instance) is completely UNCHANGED by this story -- still
## wired unconditionally by [method _wire_villager_population], still the
## sole hosted villager any pre-existing test/boot path observes. [method
## spawn_starting_roster] is ADDITIVE and deliberately NEVER called from
## [method _ready] -- it mirrors this class's own doc comment paragraph
## above verbatim: exactly the same "a fresh grid has no terrain yet" reason
## [method VillagerNavGraph.build] is deferred to a future world-generation
## story applies here too, and more sharply -- [VoxelWorldGrid]'s own
## chunk residency (ADR-0015) regenerates terrain ASYNCHRONOUSLY, off the
## main thread, over several POST-boot frames, so calling this synchronously
## during [method _ready] would deterministically find zero standable cells
## on every single boot, for a search cost that scales with the bound
## instead of buying a meaningful placement. [method spawn_starting_roster]
## is the ready-to-call, fully-tested surface a future world-generation story
## wires in once real terrain is confirmed resident near the chosen center --
## this story's own explicit scope boundary ("Population growth / arrivals /
## recruitment is Township Progression's job") does not cover WHEN world
## generation itself first runs, only that growth BEYOND the starting roster
## is out of scope.
## Story scene-005 (World genesis in the boot sequence, ADR-0005 primary /
## ADR-0015 primary / ADR-0014 secondary) closes every deferral the paragraphs
## above name. [method GameWorld._run_world_genesis] -- a NEW orchestration
## method on [GameWorld], not this class (this class still owns no `setup()`
## and calls no hosted child's `setup()` itself, per the class doc comment's
## opening hosting-vs-DI distinction) -- now drives, in this load-bearing
## order, during WIRING, strictly before [constant
## GameWorld.BootState.ACTIVE]: the camera's start-focus target ([method
## CameraInput.set_target], the SAME cell everything else below anchors on),
## the boot-window residency drive ([method VoxelWorldGrid.update_residency]
## alternated with [method VoxelWorldGrid.drain_pending_async_reads], bounded
## by a config-driven wall-clock ceiling -- never [method
## VoxelWorldGrid.generate_terrain], the full-extent call this class's own
## class doc comment used to name as never-called and still is), [method
## VoxelWorldGrid.mark_generated], [method build_villager_nav_graph] (closing
## [method VillagerNavGraph.build]'s "a fresh grid has no terrain yet"
## deferral), and finally [method spawn_starting_roster] itself -- which is
## THEREFORE no longer dead code: it is called exactly once per boot, from
## [GameWorld], after real terrain is confirmed resident. [method _process]
## additionally gains the per-frame residency-drive line documented on that
## method itself -- vox-018's own named seam, now cashed.
##
## Story presentation-003 (Villager body view, hit proxy & slice hook; VB-1)
## additionally hosts [VillagerBodyPresenter] -- structural child, exactly
## like every other hosted module above -- wired via [method
## _wire_hosted_modules] with a small anonymous roster-provider [RefCounted]
## ([member _villager_roster_provider]) whose sole member,
## `get_villagers() -> Array[VillagerAi]`, delegates to [method get_villagers]
## (the SAME "one hard-wired villager + spawned roster" list every other
## consumer already reads). [method spawn_starting_roster] additionally
## calls [method VillagerBodyPresenter.refresh] immediately after adding each
## newly-spawned villager, so a real boot (which calls
## [method spawn_starting_roster] exactly once from [method
## GameWorld._run_world_genesis]) produces exactly one [VillagerBodyView] per
## hosted villager, INCLUDING [member _villager_ai] itself (villager_id 0,
## always present, view created by [method VillagerBodyPresenter.setup]'s own
## boot-gated initial pass -- see [GameWorld]'s own `setup()` sweep, appended
## via [method get_injected_tier_modules] below; this class never calls a
## hosted child's `setup()` itself, per the class doc comment's opening
## hosting-vs-DI distinction).
##
## Story scene-007 (Build-tool & project-lifecycle hosting, ADR-0005 + ADR-0001
## primary, ADR-0016 primary for the lifecycle tier's own semantics) closes
## the fourth ship-green-and-uncalled occurrence: the ENTIRE build-interaction
## tier -- [BuildEditorMode], the five placement tools ([WallTool]/[FloorTool]/
## [RoofTool]/[BlockTool]/[FurnitureTool]), [GhostPreview], [UndoRedoStack] --
## was, before this story, a set of already-green, already-tested `Node`s in
## no scene, and [BuildProjectRegistry]/[ConstructionJobQueue]/
## [PlanOnlyUndoGate]/[RemovalTool]/[FurnitureRegistry] were `RefCounted`
## collaborators constructed nowhere in `src/`. Hosted here on the SAME
## precedent every module above already establishes: each `Node`'s own config
## `Resource` (if any) is Inspector-wired on `Valley.tscn`; Node-typed
## cross-references between hosted siblings are code-assigned in [method
## _wire_hosted_modules] below; the `RefCounted` collaborators are constructed
## in [method _wire_build_project_lifecycle], mirroring [method
## _wire_villager_population]'s own established construction-site precedent.
## This class still never calls a hosted child's `setup()` itself (the class
## doc comment's opening hosting-vs-DI distinction, unchanged) -- [WallTool],
## [BuildEditorMode], [FurnitureTool], [GhostPreview], and [UndoRedoStack] are
## the five NEW `setup()`-bearing modules appended to [method
## get_injected_tier_modules] below; [FloorTool]/[RoofTool]/[BlockTool] gained
## a trivial `setup()`/`is_set_up()` pair of their own (this story's addition,
## see each class's own doc comment) for the SAME reason.
##
## **The armed-tool -> resolver router** (the one genuinely new piece of
## code this story adds, per its own Implementation Notes: "small"): [method
## _on_tool_armed] re-points [CommitPipeline]'s single [method
## CommitPipeline.set_cell_set_resolver] / [method
## CommitPipeline.set_terrain_replace_resolver] / [method
## CommitPipeline.set_furniture_support_predicate] slots on every [signal
## ToolStateMachine.tool_armed] emission, keyed by the tool-id vocabulary
## [ToolStateMachine] now owns ([constant ToolStateMachine.TOOL_ID_WALL] etc.,
## this story's own Open Decision 2 resolution).
##
## **Correction to this story's own Implementation Notes, found during this
## story's own development (recorded in the commit body) -- a real bug, not a
## hypothetical one.** The Implementation Notes read as "wire
## `set_furniture_support_predicate` once, unconditionally." That wiring was
## tried first and BROKE every non-furniture multi-cell-tall commit: a real,
## hosted 3-cell [WallTool] column was rejected with [constant
## CommitPipeline.RejectReason.FURNITURE_UNSUPPORTED], because [method
## CommitPipeline._all_cells_supported] is NOT category-gated -- it runs
## against EVERY commit, not only furniture ones -- and a column's own upper
## cells have no support directly below them until the commit itself lands
## (a chicken-and-egg: the predicate runs BEFORE any [BlueprintCell] of the
## SAME commit exists to count as support for the cell above it). The fix,
## proven by this story's own hosted-boot test: [method
## CommitPipeline.set_furniture_support_predicate] is tool-swapped exactly
## like the other two resolvers (see [member _furniture_support_predicates]),
## not wired once.
##
## **The `blueprint_cells_created` chain** (Sub-scope B, the C1 demolition
## chain's production caller): [method _on_blueprint_cells_created], the SOLE
## listener on [signal CommitPipeline.blueprint_cells_created], performs BOTH
## of this story's remaining seam connections in one place: records the whole
## commit as ONE [UndoRedoStack] command (Core Rule 17, Sub-scope C) THEN
## routes the same cells into [method BuildProjectRegistry.assign_cells]
## (Sub-scope B) -- a freshly-created OR newly-merged-into project is
## registered into [ConstructionJobQueue] via [method
## ConstructionJobQueue.add_project] exactly once per project id ([member
## _job_queue_registered_project_ids] guards a repeat visit on a later merge
## from double-registering the SAME project instance, since neither
## [BuildProjectRegistry] nor [ConstructionJobQueue] carries that guard
## itself -- this class is the seam-gluing layer that adds it, not a change to
## either landed class).
##
## **`BuildingSystemWriteTag` sharing** (Sub-scope C): [method
## _wire_hosted_modules] constructs ONE shared instance and assigns it to both
## [member UndoRedoStack.write_tag] and [member ConstructionTickLoop.write_tag]
## BEFORE either module's `setup()` ever runs (both lazily default-construct
## their own if left unassigned) -- so [ConstructionTickLoop]'s own batched
## completion write is recognized by [UndoRedoStack]'s undo-invalidation
## listener as self-originated, never silently invalidating the player's undo
## history (AC-UNDO-IS-PLAN-ONLY-THROUGH-THE-HOSTED-STACK).
##
## **`game_world` back-references**: [member ToolStateMachine.game_world] and
## [member UndoRedoStack.game_world] are both nullable `@export`s that no-op
## when unwired -- and both were `null` in production before this story (a
## pre-existing silent gap this story fixes, named explicitly in its own
## Implementation Notes rather than left unmentioned). This class reaches
## [GameWorld] through [method Node.get_parent] (cast, `null`-safe) --
## `GameWorld._attach_valley` always calls `add_child(_valley)` BEFORE this
## instance's own [method _ready] can run (Godot's bottom-up `_ready()`
## ordering means the parent link is already established the instant this
## method's body executes), so the cast resolves correctly in every real boot;
## a bare, test-constructed `Valley` added under a non-`GameWorld` parent (this
## project's own established direct-construction test convention) simply casts
## to `null`, an already-handled no-op for both consumers.
##
## **`FurnitureRegistry`/`FurnitureBedProvider`** (Open Decision 3, resolved
## (a) per this story's own producer recommendation): [method
## _wire_build_project_lifecycle] constructs both, wires
## [member ConstructionTickLoop.furniture_registry], and assigns the provider
## to every hosted [VillagerAi]'s `bed_provider` seam (both [member
## _villager_ai] and every [method spawn_starting_roster] member) -- the
## moment a completed bed becomes claimable by a real villager in the shipped
## game. **Honest, named deviation, not silently absorbed**: [FurnitureBedProvider]
## requires a `BuildValidation` collaborator for its own [method
## FurnitureBedProvider.is_bed_sheltered] query; `BuildValidation` is ITSELF a
## fifth uncalled-in-`src/` injected-tier module (found while reading for this
## story, exactly the same defect class as every module this story DOES host)
## -- hosting it is a materially different, unscoped change (a whole
## additional Foundation/Core module with its own config/signal-subscription
## surface) this story does not make. [method _wire_build_project_lifecycle]
## therefore passes `null` for that collaborator -- [FurnitureBedProvider]'s
## own documented nil-safe fallback means `is_bed_sheltered` conservatively
## reads `false` (never inflated) rather than crashing, and bed CLAIMING
## ([method FurnitureBedProvider.get_unowned_bed_cells]/[method
## FurnitureBedProvider.claim_bed], the literal "no villager can ever claim a
## bed" gap this story closes) is fully functional regardless -- only the
## shelter-quality bonus on top of a claimed bed remains a named, tracked
## follow-on gap ([VillagerAi]'s own `_is_bed_sheltered` doc comment already
## documents the conservative-`false`-is-safe fallback this exercises, unlike
## a NEW invented behavior).
##
## **Also found while reading, also explicitly NOT pulled into this story**:
## [VillagerOnSiteGate]/[VillagerSealPreventionGate] (`src/villager_ai/`) are
## likewise constructed nowhere in `src/` -- Villager AI's own occupancy-defer/
## seal-prevention wiring for [ConstructionJobQueue]/[ConstructionTickLoop],
## a DIFFERENT epic's gap (villager-ai-012/016's own documented "wires this for
## REAL... for the first time" language) than "build tool & project-lifecycle
## hosting." Both predicates default permissively (never occupied / always
## allow) when unwired, so leaving them unwired changes no existing behavior
## and blocks nothing this story's own ACs require -- named here so it is not
## silently mistaken for closed.
##
## Story scene-006 (Villager need seeding in the boot sequence, ADR-0005
## primary) closes `needs-mood-006`'s own "uncalled in `src/`" gap: [method
## NeedsMood.initialize_villager] is now driven from exactly two call sites,
## both on this class. [method spawn_starting_roster] seeds each villager it
## creates, inline, right where it already assigns `needs_provider`
## (already legal under ADR-0005 -- that method is only ever reached from
## [method GameWorld._run_world_genesis], strictly after every hosted
## module's `setup()` has run). [member _villager_ai] (villager_id 0) needed
## a NEW home: its provider ASSIGNMENT stays in [method
## _wire_villager_population], which [method _ready] calls -- seeding there
## would violate `needs-mood-006`'s own Control Manifest rule ("never in
## `_ready()`"). [method seed_default_villager_needs] is that new home: an
## explicitly-callable method reached ONLY from [method
## GameWorld._run_world_genesis] (duck-typed, mirroring [method
## build_villager_nav_graph]/[method spawn_starting_roster]'s own call-site
## shape) -- [method _ready]/[method _wire_villager_population] remain
## completely UNCHANGED by this story. Both call sites assert [method
## NeedsMood.is_set_up] first (AC-SEED-AFTER-SETUP: seeding must read
## POST-validate/clamp config, never pre-`setup()` state) -- a
## code-enforced ordering guarantee, not merely a documented one.
##
## Story cam-013 (Camera hosting in the shipped scene -- the sixth instance
## of ship-green-and-uncalled this project has hit, and the most visible:
## before this story `game_world.tscn` -> `Valley.tscn` hosted ZERO
## [Camera3D] nodes, so a human launching the real game saw nothing at all,
## despite `CameraInput`'s own orbit/pan/zoom math being fully landed and
## tested). Hosts [member _valley_camera] (a plain, scripted-nowhere
## [Camera3D], `current = true` authored directly in `Valley.tscn`) and
## [member _camera_mirror] (the real injected-tier module that drives it) --
## structural hosting + code-assigned cross-sibling DI, on the SAME
## established precedent as every other pairing above (see e.g. [member
## _torch_flicker] / [member _ambient_torch_light]). [CameraInput] ITSELF is
## completely UNTOUCHED by this story (AC3) -- its own class doc comment's
## "why no live Camera3D" rationale stays true; the mirroring lives here, in
## the hosting layer, via [CameraMirror]'s own one-way read-from-CameraInput/
## write-to-Camera3D relationship (see that class's own doc comment for the
## full rationale, including the frame-ordering hazard it fixes with its own
## [member Node.process_priority] -- deliberately scoped to ONLY that small
## driver node, leaving THIS class's own [method _process] -- the unrelated,
## pre-existing vox-018 residency/mesh-window drive -- completely untouched).
## No new `_input()`/`_unhandled_input()` handler is introduced anywhere by
## this story (AC5) -- [CameraMirror] reads no [InputEvent] at all. Because
## [method _run_world_genesis] (story scene-005) already calls [method
## CameraInput.set_target] with the roster's own world-center start-focus
## cell BEFORE this class's very first rendered frame, the hosted camera is
## already framed on the starting roster's neighbourhood the instant boot
## reaches ACTIVE (AC4) -- no additional target-setting call was needed here.
##
## Story presentation-004 ("The world has no sun" -- the seventh instance of
## this project's ship-green-and-uncalled failure mode, and the most visible
## yet: before this story `Valley.tscn` hosted ZERO [DirectionalLight3D]/
## [WorldEnvironment] nodes, counted directly, so a human launching the real
## game got a near-black screen; every "lit" screenshot this project ever
## produced was lit by a TOOL supplying its own throwaway lighting). Hosts
## [member _sun_light] (a plain, scripted-nowhere [DirectionalLight3D]) and
## [member _world_environment] (a plain [WorldEnvironment]) -- structural
## children only, mirrors [member _ambient_torch_light]'s own "a plain
## [Light3D]/host node has no `setup()` of its own" precedent exactly --
## plus [member _world_lighting], the real injected-tier module that applies
## the art bible SS2.1 golden-hour recipe to both of them exactly once, from
## config (ADR-0002), in [method WorldLighting.setup]. [method
## _wire_hosted_modules] code-assigns the two Node-typed cross-references
## ([member WorldLighting.directional_light]/[member
## WorldLighting.world_environment]), mirroring [member TorchFlicker.light]'s
## own identical wiring shape. [WorldLighting] IS appended to [method
## get_injected_tier_modules] (a real `setup()`/`is_set_up()` contract,
## [GameWorld] calls it same as every other hosted module). [method
## _assert_lighting_boot_invariant] (AC5) -- called from [method _ready],
## after [method _wire_hosted_modules] -- is this story's own boot-invariant
## addition: exactly one [DirectionalLight3D] and exactly one
## [WorldEnvironment] must be direct children of this Valley once wiring
## completes, asserted loudly (ADR-0005's own "fail loudly, not silently"
## convention) rather than left as an unstated hope. AC6 (the three tool
## scenes stop hand-rolling this same recipe and use this shipped
## [WorldLighting] instead) is that story's own scope, not this class's --
## see `tools/settlement_overview_capture.gd`/
## `tools/m01_c4_valley_ambient_capture.gd`/`tools/camera_sandbox.gd`'s own
## updated doc comments.
##
## Story villager-ai-022 ("the stray villager at the world corner", found by
## booting the real game and printing where everyone stands) closes the gap
## every paragraph above left unaddressed: [member _villager_ai] (villager_id
## 0) was NEVER placed by anything -- it kept its `Vector3i.ZERO` field
## default forever, the far corner of a 2000x2000 world, while [method
## spawn_starting_roster] placed only the members it itself constructed. This
## story's shape (its own "Design Note" Shape 1, chosen on scope grounds --
## keeps the scene-hosted node, which several other stories already reference
## as "the always-present default, villager_id 0"): [method
## spawn_starting_roster] now selects `starting_villager_count` cells and
## hands the FIRST one to [member _villager_ai] itself, via [method
## VillagerRosterSpawner.place_villager_at_cell] -- the SAME cell-selection +
## placement path every other roster member goes through (AC2: one placement
## rule, not two), never a second hand-rolled seam. **Chosen count
## convention (AC4), stated explicitly, not left implicit**: villager 0
## COUNTS toward `starting_villager_count` -- a config of 1 (the shipped MVP
## default) now yields exactly ONE total settler, never "1 default + 1
## roster-spawned" (the actual shipped bug this story's own bug report
## reproduced: `REPORT — villagers spawned: 2` for a `starting_villager_count
## = 1` world). This reads [TR-villager-ai-behavior-065]'s own requirement
## text literally -- "this system places `starting_villager_count`
## villagers" -- not "`starting_villager_count` PLUS the pre-existing one."
## [member _default_villager_placed] guards this to happen at most once: a
## LATER growth call (a future Township Progression call site reusing this
## SAME method, per its own already-documented "no growth bookkeeping of its
## own" shape) must never re-teleport an already-simulating villager 0 --
## only the very first successful placement ever consumes a cell for it;
## every call after that spends the full `count` on new roster members only,
## exactly like [method spawn_starting_roster]'s pre-existing behavior for
## every OTHER villager. AC3's edge case -- the search finds zero standable
## cells at all -- is a `push_warning`-logged, deterministic outcome (never a
## silent leave-at-the-origin): [member _default_villager_placed] simply
## stays `false`, so a LATER call (once real terrain exists) gets another
## chance. [method _assert_villager_placement_invariant] (AC1/AC5) is this
## story's own boot-invariant addition, mirroring [method
## _assert_lighting_boot_invariant]'s own "fail loudly, not silently"
## convention -- every hosted villager [method get_villagers] reports must
## stand on a cell [VillagerWalkabilityRules.is_standable] confirms, except
## villager 0 in the exact AC3 degenerate case just named (already logged,
## not re-failed here).
##
## Story scene-008 ("Hosting the gates that make work honest") closes BOTH
## deviations Story scene-007's own class doc comment named above but did not
## fix: [BuildValidation] ("Open Decision 3, resolved (a)") and
## [VillagerOnSiteGate]/[VillagerSealPreventionGate] ("Also found while
## reading, also explicitly NOT pulled into this story" -- a different
## epic's own gap). All three were fully built and fully tested, and all
## three were constructed NOWHERE in `src/` -- found this time by a capture
## tool (`tools/payoff_loop_demo.gd`) that drove the real shipped chain and
## photographed the result: a villager's walls rose while it stood visibly
## away from the house, because both gates default PERMISSIVELY when unwired
## ([ConstructionTickLoop] credited a claimed job on a timer, regardless of
## whether the claiming villager had physically arrived), and no bed in the
## shipped game could ever read sheltered ([method
## FurnitureBedProvider.is_bed_sheltered] structurally returned `false` for
## every bed, since its own [member FurnitureBedProvider.build_validation]
## dependency was `null`).
##
## [BuildValidation] is hosted exactly like every other injected-tier `Node`
## above ([member _build_validation], `config` Inspector-wired on
## `Valley.tscn` from `build_validation_config.tres`, `voxel_world`
## code-assigned in [method _wire_hosted_modules], `furniture_registry`
## code-assigned in [method _wire_build_project_lifecycle] once that
## collaborator exists, `setup()` reached ONLY via [method
## get_injected_tier_modules]) -- and its real instance now replaces the
## `null` [method _wire_build_project_lifecycle] used to pass into [method
## FurnitureBedProvider._init]. [VillagerOnSiteGate]/
## [VillagerSealPreventionGate] are `RefCounted` collaborators constructed in
## [method _wire_build_project_lifecycle], mirroring every other
## population-wide shared `RefCounted` this class already constructs there
## (`_construction_job_queue` etc.) -- both wire themselves into [member
## _construction_job_queue]'s own occupancy/seal-prevention predicate seams
## from their own `_init`, exactly as each class's own doc comment already
## documents. Every hosted [VillagerAi] -- [member _villager_ai] (in [method
## _wire_villager_population]) and every [method spawn_starting_roster]
## member -- is registered with BOTH gates, mirroring [method
## _wire_villager_population]'s own established "the SAME shared instance
## every hosted villager is assigned" precedent for `job_queue`/
## `bed_provider`. **Scope discipline, explicit**: this story changes NO
## rule inside [BuildValidation] or either gate -- all three are built and
## tested; this story only makes the running game construct and wire them.
## [method _assert_build_validation_gates_boot_invariant] (AC5) extends this
## class's own established "fail loudly, not silently" boot-invariant block
## (mirrors [method _assert_lighting_boot_invariant]/[method
## _assert_villager_placement_invariant]) to cover all three: each is
## asserted non-null (constructed) and [member
## FurnitureBedProvider.build_validation] is asserted non-null (wired, not
## the `null` Story scene-007 recorded).
##
## Story build-validation-009 ("Loop-payoff surface receives real signals,"
## milestone criterion #7 -- the ninth instance of this project's own
## ship-green-and-uncalled failure mode this sprint) hosts [LoopPayoffSignalSurface]
## (`presentation-002`, shipped and tested since its own scaffolding story but
## never called by anything real in `src/`) and [LoopPayoffAdapter] (this
## story's own new class -- the first real production writer) exactly like
## every other paired hosted-module/driver above ([member
## _ambient_torch_light]/[member _torch_flicker], [member _sun_light]/[member
## _world_lighting]): both are structural children; [member
## LoopPayoffAdapter.build_validation]/[member LoopPayoffAdapter.payoff_surface]
## are code-assigned Node-typed cross-references in [method
## _wire_hosted_modules]; `setup()` is reached ONLY via [method
## get_injected_tier_modules] (this class still calls no hosted child's
## `setup()` itself). [method _assert_loop_payoff_wiring_boot_invariant]
## extends this class's own "fail loudly, not silently" boot-invariant block
## once more: both hosted nodes must exist, and the adapter's own two
## dependencies must be wired (never left `null`, mirroring [method
## _assert_build_validation_gates_boot_invariant]'s own shape for
## [FurnitureBedProvider.build_validation]).
## Story vox-023 ("Block appearance becomes DATA") wires [VoxelWorldMesher]'s
## new [member VoxelWorldMesher.appearance] dependency
## (`res://data/config/block_appearance_config.tres`) via this scene's
## Inspector -- the same "a Resource export resolves fine from a
## hand-authored `.tscn`" precedent every other config field on this scene
## already uses (class doc comment above). [method
## _assert_block_appearance_boot_invariant] extends this class's own "fail
## loudly, not silently" boot-invariant block a fourth time: an unwired
## appearance config must halt boot loudly, never render a plausible-looking
## (but actually hardcoded) world -- sprint-12's own deepest rule, named
## against this exact shape.
##
## Story presentation-005 ("A built bed becomes visible" -- the furniture
## view layer, F7) hosts [FurniturePresenter] -- structural child, exactly
## like every other hosted module above, following [VillagerBodyPresenter]'s
## own landed per-entity-presenter precedent one-for-one (Open Decision D11:
## the TD render-mechanism call is named in sprint-12.md but explicitly not a
## blocker; this codebase's only landed precedent is followed, not
## re-litigated). [member FurniturePresenter.furniture_registry] is
## code-assigned in [method _wire_build_project_lifecycle] -- NOT in [method
## _wire_hosted_modules], because [member _furniture_registry] does not exist
## yet when that earlier method runs (mirrors [member
## BuildValidation.furniture_registry]'s own identical ordering constraint,
## same paragraph). `setup()` is reached ONLY via [method
## get_injected_tier_modules] (this class still calls no hosted child's
## `setup()` itself). [method _assert_furniture_presenter_boot_invariant]
## extends this class's own "fail loudly, not silently" boot-invariant block
## once more (sprint-12's own deepest rule: "no injected collaborator is both
## optional and consequential") -- [FurniturePresenter] must be hosted and
## its `furniture_registry` must be wired, asserted loudly at boot rather
## than left as an unstated hope.
##
## Story `building-034` second pass ("Scaffolding gets a body in the running
## game") closes the TENTH ship-green-and-uncalled occurrence this project
## has hit: [ScaffoldRegistry], [ScaffoldErectionCoordinator] and
## [ScaffoldPresentation] were fully built and fully unit-tested (commit
## `6cc9002`) but constructed NOWHERE in `src/` -- every lever proving
## scaffolding worked ran against the production classes called directly,
## never through this hosted boot chain.
##
## [member _scaffold_registry] is constructed in [method
## _wire_build_project_lifecycle] (Building-System-owned, TD ruling D1) and
## wired into FOUR places, each mirroring an already-landed precedent:
## [member ConstructionTickLoop.scaffold_registry] (a completing `SCAFFOLD`
## job routes here instead of [VoxelWorldGrid], D1/D3); [member
## ScaffoldPresentation.scaffold_registry] (the pooled placeholder-mesh tier,
## D2); [member VillagerAi.scaffold_registry] on EVERY hosted villager --
## both [member _villager_ai] and every [method spawn_starting_roster]
## member, mirroring [member _villager_onsite_gate]/[member
## _villager_seal_prevention_gate]'s own "the SAME shared instance every
## hosted villager is assigned" precedent -- so the walkability predicates
## actually see scaffolding in the running game; and [method
## VillagerNavGraph.subscribe_to_scaffold_registry] (ADR-0007 §2b's own
## synchronous patch trigger -- a scaffold write is never a [VoxelWorldGrid]
## write, so [signal VoxelWorldGrid.cell_changed] never fires for it; this is
## the ONLY path a scaffold change ever reaches the hosted nav graph
## through).
##
## [member _scaffold_erection_coordinator] (D5 point 3: "the AI detects, the
## Building System builds") is a `RefCounted` collaborator, constructed in
## [method _wire_build_project_lifecycle] mirroring [member
## _villager_onsite_gate]'s own "wires itself into its own signal seam from
## `_init`" shape -- it subscribes to [signal
## ConstructionJobQueue.job_reported_unreachable] itself; this class never
## calls it directly. [member scaffold_config] is Inspector-wired on
## `Valley.tscn` from the new `scaffold_config.tres` (D6's
## `scaffold_max_cantilever_cells = 6`, the user's own AC4 ruling), the SAME
## "a Resource export resolves fine from a hand-authored `.tscn`" precedent
## every other config field on this class already uses.
##
## **The live dismantle orchestrator (this pass's own new code)**: [member
## _scaffold_dismantle_coordinator] ([ScaffoldDismantleCoordinator], new this
## pass) closes AC3/D10/D4 -- nothing previously called [method
## BuildProject.recompute_state] after [ConstructionTickLoop] flips a cell to
## `BUILT` (that class mutates [member BlueprintCell.state] directly,
## bypassing every mutator that used to trigger it), so no `BUILD` project
## ever visibly reached [constant BuildProject.ProjectState.DONE] in the
## running game before this pass. It listens to [signal
## ConstructionTickLoop.construction_completed] (Trigger 1, DONE) and
## [signal RemovalTool.project_canceled] (Trigger 2, D4 -- a new, small
## signal this pass adds to [RemovalTool], fired only when a whole project's
## last cell is cancelled), and drives [ScaffoldDismantlePlanner]'s
## already-landed D10/SC-INV-1 ordering through [ConstructionTickLoop]'s own
## real, tick-paced demolition-job machinery -- see that class's own doc
## comment for the honest, named scope boundary this reuses (no production
## [VillagerAi] decision path claims ANY demolition job yet; a pre-existing
## gap this pass does not invent a fix for).
##
## [method _assert_scaffold_boot_invariant] extends this class's own "fail
## loudly, not silently" boot-invariant block a final time (sprint-12's own
## standing rule: "any injected collaborator whose absence changes behaviour
## must ASSERT AT BOOT").
class_name Valley
extends Node3D

## Hosted Voxel World / Grid Data instance (ADR-0001 injected-tier module;
## `voxel-world` epic, already-landed story vox-001). Structural child only
## -- see the class doc comment's hosting-vs-DI distinction.
@onready var _voxel_world: VoxelWorldGrid = $VoxelWorldGrid

## Hosted Voxel World mesher instance (ADR-0001 injected-tier module;
## `voxel-world` epic, story vox-007). Structural child only -- Story
## scene-004 addition.
@onready var _voxel_world_mesher: VoxelWorldMesher = $VoxelWorldMesher

## Hosted Camera & Input instance (ADR-0001 injected-tier module;
## `camera-input` epic, already-landed story cam-001/002). Structural child
## only -- see [member _voxel_world]'s doc comment.
@onready var _camera_input: CameraInput = $CameraInput

## Hosted, passive [Camera3D] the shipped scene chain actually renders
## through (Story cam-013 -- "Camera hosting in the shipped scene"; before
## this story, `game_world.tscn` -> `Valley.tscn` hosted zero [Camera3D]
## nodes at all). Owns no config/script of its own -- [member _camera_mirror]
## is the real injected-tier module that drives its transform every frame;
## `current = true` is authored directly on this node in `Valley.tscn`
## (there is exactly one [Camera3D] anywhere in this scene's own subtree, so
## no runtime arbitration is needed for it to become the active camera).
@onready var _valley_camera: Camera3D = $ValleyCamera

## Hosted [CameraMirror] instance (Story cam-013). Structural child --
## [member CameraMirror.camera]/[member CameraMirror.camera_input] are
## code-assigned Node-typed cross-references in [method _wire_hosted_modules],
## mirroring every other hosted cross-sibling wiring on this class. See that
## class's own doc comment for the full one-way mirror + frame-ordering
## rationale (AC2/AC3).
@onready var _camera_mirror: CameraMirror = $CameraMirror

## Hosted Voxel World mesh view-window streamer instance (ADR-0001
## injected-tier module; `voxel-world` epic, story vox-015 landed the
## machinery, story vox-018 wires it live). Structural child only -- see
## [member _voxel_world]'s doc comment; cross-wired to [member _voxel_world]/
## [member _voxel_world_mesher] in [method _wire_hosted_modules], driven every
## frame by [method _process] -- see class doc comment's vox-018 scope note.
@onready var _voxel_world_mesh_streamer: VoxelWorldMeshStreamer = $VoxelWorldMeshStreamer

## Hosted Building System tool state machine instance (ADR-0001 injected-tier
## module; `building-system` epic, story building-019). Structural child
## only -- Story scene-004 addition.
@onready var _tool_state_machine: ToolStateMachine = $ToolStateMachine

## Hosted Building System placement-pick instance (ADR-0001 injected-tier
## module; `building-system` epic, story building-020/021). Structural child
## only -- Story scene-004 addition.
@onready var _placement_pick: PlacementPick = $PlacementPick

## Hosted Building System commit-pipeline instance (ADR-0001 injected-tier
## module; `building-system` epic, story building-021). Structural child
## only -- Story scene-004 addition.
@onready var _commit_pipeline: CommitPipeline = $CommitPipeline

## Hosted Building System construction-tick-loop instance (ADR-0001
## injected-tier module; `building-system` epic, story building-029).
## Structural child only -- Story scene-004 addition.
@onready var _construction_tick_loop: ConstructionTickLoop = $ConstructionTickLoop

## Hosted Villager AI instance -- ONE villager at MVP scope (GDD
## `starting_villager_count` default 1; `villager-ai-behavior` epic, stories
## 001-009). Structural child only -- Story scene-004 addition. See class
## doc comment for the non-`@export` scheduler/nav_graph wiring this class
## performs on top of the plain structural hosting every other child gets.
## Story villager-ai-021: completely UNCHANGED by the new starting-roster
## capability -- still the always-present, unconditionally-wired default
## (villager_id 0); [method get_villagers] reports it first.
@onready var _villager_ai: VillagerAi = $VillagerAi

## Hosted Build Validation & Navigability instance (Story scene-008; ADR-0001
## injected-tier module; `build-validation` epic, stories 001-008). Structural
## child only -- `config` is Inspector-wired on `Valley.tscn` from the
## already-existing `build_validation_config.tres`; `voxel_world`
## (Node-typed cross-reference) is code-assigned in [method
## _wire_hosted_modules]; `furniture_registry` (duck-typed, plain `var`) is
## code-assigned in [method _wire_build_project_lifecycle], once that
## collaborator is constructed. See class doc comment's own Story scene-008
## paragraph for the full rationale.
@onready var _build_validation: BuildValidation = $BuildValidation

## Hosted Needs & Mood System instance (ADR-0001 injected-tier module;
## `needs-mood-system` epic, stories 001-008; Story needs-mood-010 -- THE
## CROWN's own production-wiring AC). Structural child only -- see [member
## _voxel_world]'s own hosting-vs-DI distinction. [method
## _wire_villager_population] assigns this SAME instance to every hosted
## [VillagerAi]'s `needs_provider` seam (both [member _villager_ai] and every
## member [method spawn_starting_roster] creates) -- the moment the landed
## nil-safe seam becomes live in the shipped game. This is the ONLY call site
## in `src/` that ever assigns [member VillagerAi.needs_provider].
@onready var _needs_mood: NeedsMood = $NeedsMood

## Tuning config for the whole starting roster (Story villager-ai-021,
## ADR-0002) -- Resource-typed, Inspector-assigned directly on `Valley.tscn`
## (Story scene-004's own established "a Resource export resolves fine from
## a hand-authored `.tscn`" distinction). Deliberately the SAME underlying
## `.tres` instance [member _villager_ai]'s own `config` field already
## points at (both wired from the identical ext_resource in `Valley.tscn`) --
## one shared Resource, read (never per-instance mutated) by every roster
## member [method spawn_starting_roster] creates.
@export var villager_ai_config: VillagerAIConfig

## Tuning config for scaffolding (Story `building-034` second pass, TD ruling
## D6, ADR-0002) -- Resource-typed, Inspector-assigned directly on
## `Valley.tscn` from `scaffold_config.tres` (`scaffold_max_cantilever_cells
## = 6`, the user's own AC4 ruling). Passed to [member
## _scaffold_erection_coordinator] at construction; asserted non-null by
## [method _assert_scaffold_boot_invariant] (sprint-12's own "never optional
## and consequential" rule).
@export var scaffold_config: ScaffoldConfig

## Every [VillagerAi] instance [method spawn_starting_roster] has created so
## far (Story villager-ai-021) -- additional to, and villager_id-numbered
## starting after, [member _villager_ai]'s own `0`. Empty until that method
## is first called (deliberately NOT from [method _ready] -- see that
## method's own doc comment).
var _spawned_villagers: Array[VillagerAi] = []

## Whether [member _villager_ai] (villager_id 0) has ever been successfully
## placed by [method spawn_starting_roster] (Story villager-ai-022). Guards
## against a LATER call (a future growth call site reusing this same method)
## re-teleporting an already-simulating villager 0 -- only the very first
## successful placement consumes a cell for it; stays `false` across a call
## that finds zero standable cells at all (AC3's own degenerate case), so a
## later call still gets a chance once real terrain exists.
var _default_villager_placed: bool = false

## Shared, population-wide unstuck-rescue telemetry accumulator (Story
## villager-ai-021, [VillagerUnstuckTelemetry]'s own doc comment: "the
## roster is its natural owner") -- ONE instance for [member _villager_ai]
## and every member of [member _spawned_villagers] alike, mirrors [member
## _villager_nav_graph]/[member _villager_deciding_scheduler]'s own "one
## shared instance, not duplicated per villager" precedent.
var _villager_unstuck_telemetry: VillagerUnstuckTelemetry = null

## Hosted ambient torch/lantern light fixture (M01 condition C4, see class
## doc comment). Structural child only, mirrors [member _voxel_world]'s own
## hosting-vs-DI distinction -- a plain [OmniLight3D] has no `setup()` of its
## own; [member _torch_flicker] is the actual injected-tier module that
## drives its `light_energy`.
@onready var _ambient_torch_light: Light3D = $AmbientTorchLight

## Hosted [TorchFlicker] instance (M01 condition C4; `presentation-experience`
## epic, story presentation-001 Sub-scope A). Structural child only -- see
## class doc comment for the full wiring rationale and the honest scope note
## on why the other three Sub-scope A elements are NOT hosted here.
@onready var _torch_flicker: TorchFlicker = $TorchFlicker

## Hosted [VillagerBodyPresenter] instance (Presentation Experience story
## presentation-003). Structural child only -- mirrors [member
## _torch_flicker]'s own "a real injected-tier module, `setup()` reached
## only via [GameWorld]'s boot-gated sweep" precedent. [member
## VillagerBodyPresenter.roster_provider] is code-assigned in [method
## _wire_hosted_modules] to [member _villager_roster_provider] below.
@onready var _villager_body_presenter: VillagerBodyPresenter = $VillagerBodyPresenter

## Hosted [FurniturePresenter] instance (Presentation Experience story
## presentation-005, F7). Structural child only -- mirrors [member
## _villager_body_presenter]'s own "a real injected-tier module, `setup()`
## reached only via [GameWorld]'s boot-gated sweep" precedent. [member
## FurniturePresenter.furniture_registry] is code-assigned in [method
## _wire_build_project_lifecycle] (not [method _wire_hosted_modules] -- see
## class doc comment for why).
@onready var _furniture_presenter: FurniturePresenter = $FurniturePresenter

## Hosted [ScaffoldPresentation] instance (Story `building-034` second pass).
## Structural child only -- mirrors [member _furniture_presenter]'s own "a
## real injected-tier module, `setup()` reached only via [GameWorld]'s
## boot-gated sweep" precedent. [member ScaffoldPresentation.scaffold_registry]
## is code-assigned in [method _wire_build_project_lifecycle] (not [method
## _wire_hosted_modules] -- [member _scaffold_registry] does not exist yet
## when that earlier method runs, same ordering constraint as [member
## _furniture_presenter]'s own).
@onready var _scaffold_presentation: ScaffoldPresentation = $ScaffoldPresentation

## Hosted Building System outer Build/Editor Mode gate instance (Story
## scene-007; `building-system` epic, story building-001). Structural child,
## wraps [member _tool_state_machine] -- see class doc comment's own Story
## scene-007 paragraph.
@onready var _build_editor_mode: BuildEditorMode = $BuildEditorMode

## Hosted Building System wall tool instance (Story scene-007; `building-system`
## epic, story building-024). Structural child -- [member WallTool.config] is
## Inspector-assigned directly on `Valley.tscn` from the already-existing
## `wall_tool_config.tres` (shipped `wall_height = 3`).
@onready var _wall_tool: WallTool = $WallTool

## Hosted Building System floor tool instance (Story scene-007; `building-system`
## epic, stories building-025/012). Structural child -- carries no config of
## its own (documented deviation, that class's own doc comment).
@onready var _floor_tool: FloorTool = $FloorTool

## Hosted Building System roof tool instance (Story scene-007; `building-system`
## epic, story building-026). Structural child -- carries no config/dependency
## of its own.
@onready var _roof_tool: RoofTool = $RoofTool

## Hosted Building System block tool instance (Story scene-007; `building-system`
## epic, story building-027). Structural child -- carries no config/dependency
## of its own.
@onready var _block_tool: BlockTool = $BlockTool

## Hosted Building System furniture tool instance (Story scene-007;
## `building-system` epic, stories building-028/016). Structural child -- its
## [member FurnitureTool.voxel_world]/[member FurnitureTool.commit_pipeline]
## Node-typed cross-references are code-assigned in [method
## _wire_hosted_modules], mirroring every other hosted sibling's precedent.
@onready var _furniture_tool: FurnitureTool = $FurnitureTool

## Hosted Building System ghost preview renderer instance (Story scene-007;
## `building-system` epic, story building-023). Structural child --
## [member GhostPreview.config] is Inspector-assigned directly on
## `Valley.tscn` from the already-existing `ghost_preview_config.tres`; its
## three Node-typed cross-references ([member GhostPreview.tool_state_machine]/
## [member GhostPreview.placement_pick]/[member GhostPreview.commit_pipeline])
## are code-assigned in [method _wire_hosted_modules].
@onready var _ghost_preview: GhostPreview = $GhostPreview

## Hosted Building System undo/redo stack instance (Story scene-007;
## `building-system` epic, stories building-032/033). Structural child --
## [member UndoRedoStack.config] is Inspector-assigned directly on
## `Valley.tscn` from the already-existing `undo_redo_stack_config.tres`; its
## `game_world`/`voxel_world_write_source`/`write_tag` fields are code-assigned
## in [method _wire_hosted_modules] -- see class doc comment's own Story
## scene-007 paragraphs.
@onready var _undo_redo_stack: UndoRedoStack = $UndoRedoStack

## Hosted sun (Story presentation-004, "The world has no sun"). Structural
## child only, owns no config/script of its own -- [member _world_lighting]
## is the real injected-tier module that drives it. Mirrors [member
## _ambient_torch_light]'s own hosting-vs-DI distinction.
@onready var _sun_light: DirectionalLight3D = $Sun

## Hosted environment host (Story presentation-004). Structural child only --
## [member _world_lighting] constructs and assigns the actual [Environment]
## resource onto it (see [WorldLighting._apply]'s own doc comment for why an
## empty [WorldEnvironment] node has nothing of its own to mutate in place).
@onready var _world_environment: WorldEnvironment = $WorldEnvironment

## Hosted [WorldLighting] instance (Story presentation-004). Structural
## child -- [member WorldLighting.directional_light]/[member
## WorldLighting.world_environment] are code-assigned Node-typed
## cross-references in [method _wire_hosted_modules], mirroring [member
## TorchFlicker.light]'s own identical wiring shape.
@onready var _world_lighting: WorldLighting = $WorldLighting

## Hosted [LoopPayoffSignalSurface] instance (Story build-validation-009).
## Structural child, no config/cross-reference of its own -- see class doc
## comment's own Story build-validation-009 paragraph.
@onready var _loop_payoff_signal_surface: LoopPayoffSignalSurface = $LoopPayoffSignalSurface

## Hosted [LoopPayoffAdapter] instance (Story build-validation-009) -- the
## first real production writer onto [member _loop_payoff_signal_surface].
## Structural child -- [member LoopPayoffAdapter.build_validation]/[member
## LoopPayoffAdapter.payoff_surface] are code-assigned Node-typed
## cross-references in [method _wire_hosted_modules].
@onready var _loop_payoff_adapter: LoopPayoffAdapter = $LoopPayoffAdapter

## The build-project lifecycle tier's `RefCounted` collaborators (Story
## scene-007, ADR-0016; Sub-scope B/C) -- constructed in [method
## _wire_build_project_lifecycle], mirroring [method
## _wire_villager_population]'s own established "population-wide shared
## `RefCounted`, code-assigned, no Inspector representation" construction-site
## precedent. See class doc comment's own Story scene-007 paragraphs for the
## full wiring rationale.
var _build_project_registry: BuildProjectRegistry = null
var _construction_job_queue: ConstructionJobQueue = null
var _removal_tool: RemovalTool = null
var _plan_only_undo_gate: PlanOnlyUndoGate = null
var _furniture_registry: FurnitureRegistry = null
var _furniture_bed_provider: FurnitureBedProvider = null

## Story scene-008's own population-wide shared `RefCounted` collaborators --
## constructed in [method _wire_build_project_lifecycle] alongside the ones
## above, mirroring their exact "identity supplied at construction, wires
## itself into [member _construction_job_queue]'s own predicate seam from its
## own `_init`" shape. Every hosted [VillagerAi] is registered with both (see
## [method _wire_villager_population]/[method spawn_starting_roster]).
var _villager_onsite_gate: VillagerOnSiteGate = null
var _villager_seal_prevention_gate: VillagerSealPreventionGate = null

## Story `building-034` second pass -- the scaffold occupancy registry
## (Building-System-owned, TD ruling D1) and its two `RefCounted`
## collaborators, constructed in [method _wire_build_project_lifecycle]
## alongside the pair above, mirroring their exact "identity supplied at
## construction, wires itself into its own signal seam from its own `_init`"
## shape. See class doc comment's own Story `building-034` paragraphs.
var _scaffold_registry: ScaffoldRegistry = null
var _scaffold_erection_coordinator: ScaffoldErectionCoordinator = null
var _scaffold_dismantle_coordinator: ScaffoldDismantleCoordinator = null

## Every project id [method _on_blueprint_cells_created] has already
## registered into [member _construction_job_queue] -- this class's own
## guard against double-registering the SAME [BuildProject] instance on a
## later commit that merges INTO an already-registered project (neither
## [BuildProjectRegistry] nor [ConstructionJobQueue] carries that guard
## itself; see class doc comment's own "blueprint_cells_created chain"
## paragraph).
var _job_queue_registered_project_ids: Dictionary[int, bool] = {}

## The armed-tool -> [method CommitPipeline.set_cell_set_resolver] router's
## own lookup table (Story scene-007) -- built once in [method
## _wire_hosted_modules], keyed by [ToolStateMachine]'s own tool-id
## vocabulary ([constant ToolStateMachine.TOOL_ID_WALL] etc.). See class doc
## comment's own "armed-tool -> resolver router" paragraph.
var _cell_set_resolvers: Dictionary[StringName, Callable] = {}

## The armed-tool -> [method CommitPipeline.set_terrain_replace_resolver]
## router's own lookup table (Story scene-007, Story building-012's terrain-
## replace seam) -- only [constant ToolStateMachine.TOOL_ID_FLOOR] has an
## entry; every other tool-id falls back to an invalid [Callable] (no cell of
## that commit is terrain-replace eligible), re-pointed on every arm exactly
## like [member _cell_set_resolvers].
var _terrain_replace_resolvers: Dictionary[StringName, Callable] = {}

## The armed-tool -> [method CommitPipeline.set_furniture_support_predicate]
## router's own lookup table (Story scene-007). **Corrected from this story's
## own Implementation Notes, which read as "wire this once, unconditionally"
## -- found to be a real bug during this story's own development (recorded in
## the commit body): [method CommitPipeline._all_cells_supported] is NOT
## category-gated -- it applies to EVERY commit, not only furniture ones.
## Wiring [method FurnitureTool.is_cell_supported] unconditionally rejected
## every non-furniture multi-cell-tall commit (e.g. a 3-cell [WallTool]
## column) with [constant CommitPipeline.RejectReason.FURNITURE_UNSUPPORTED],
## because a column's own UPPER cells have no support directly below them
## until the commit ITSELF lands (chicken-and-egg: the predicate ran BEFORE
## any [BlueprintCell] of the same commit existed to count as support for the
## cell above it).** Tool-swapped exactly like [member _cell_set_resolvers]/
## [member _terrain_replace_resolvers] instead -- only
## [constant ToolStateMachine.TOOL_ID_FURNITURE] has an entry; every other
## tool-id falls back to an invalid [Callable] ("no support requirement",
## [CommitPipeline]'s own documented default for every non-furniture tool).
var _furniture_support_predicates: Dictionary[StringName, Callable] = {}

## Small anonymous roster-provider [RefCounted] (Story presentation-003) --
## its sole member, `get_villagers() -> Array[VillagerAi]`, delegates to
## [method get_villagers] (the SAME "one hard-wired villager + spawned
## roster" list every other consumer already reads). Exists purely so
## [VillagerBodyPresenter]'s duck-typed `roster_provider` seam has a live
## object to call without holding a direct `Valley` reference of its own
## (mirrors this codebase's established small-mock/small-adapter precedent).
class _ValleyRosterProvider:
	var _valley: Valley = null

	func _init(valley: Valley) -> void:
		_valley = valley

	func get_villagers() -> Array[VillagerAi]:
		return _valley.get_villagers()

	## Story villager-ai-025 -- [ScaffoldErectionCoordinator]'s own
	## villager-descent trigger duck-types this SAME provider for its
	## settlement-ground reference (see [member Valley._settlement_ground_cell]'s
	## own doc comment), rather than adding a second small adapter class.
	func get_settlement_ground_cell() -> Vector3i:
		return _valley.get_settlement_ground_cell()

	func has_settlement_ground_cell() -> bool:
		return _valley.has_settlement_ground_cell()

var _villager_roster_provider: _ValleyRosterProvider = null

## Story villager-ai-025 -- the settlement's own standable-ground reference
## cell, resolved by [method build_villager_nav_graph] (see that method's own
## new paragraph) from the SAME `region_center` genesis already anchors the
## camera/nav graph/starting roster on -- never a second, independently-
## chosen anchor. `Vector3i.ZERO`/unset until genesis actually runs; [member
## _has_settlement_ground_cell] is the honest presence flag ([method
## get_settlement_ground_cell] callers must check [method
## has_settlement_ground_cell] first -- this codebase's own established
## "optional value + honest presence flag" precedent, never a sentinel
## coordinate).
var _settlement_ground_cell: Vector3i = Vector3i.ZERO
var _has_settlement_ground_cell: bool = false

## The shared, population-wide [VillagerNavGraph] instance [method
## _wire_villager_population] constructs -- exposed read-only for tests/
## future world-generation stories that need to (re)build it once real
## terrain exists.
var _villager_nav_graph: VillagerNavGraph = null

## The shared, population-wide [VillagerDecidingScheduler] instance [method
## _wire_villager_population] constructs -- exposed read-only, mirrors
## [member _villager_nav_graph].
var _villager_deciding_scheduler: VillagerDecidingScheduler = null


func _ready() -> void:
	_wire_hosted_modules()
	_wire_build_project_lifecycle()
	_wire_villager_population()
	_assert_lighting_boot_invariant()
	_assert_build_validation_gates_boot_invariant()
	_assert_loop_payoff_wiring_boot_invariant()
	_assert_block_appearance_boot_invariant()
	_assert_furniture_presenter_boot_invariant()
	_assert_scaffold_boot_invariant()


## Code-assigned DI for the Node-typed cross-references between hosted
## Building System / Voxel World siblings -- see class doc comment for why
## this is code-wired rather than authored as a `NodePath(...)` value
## directly in `Valley.tscn`. Each target's OWN config Resource dependency
## (if any) is still wired via that scene file's Inspector; only the
## cross-sibling Node references are assigned here.
func _wire_hosted_modules() -> void:
	_voxel_world_mesher.grid = _voxel_world
	_voxel_world_mesh_streamer.grid = _voxel_world
	_voxel_world_mesh_streamer.mesher = _voxel_world_mesher
	_placement_pick.camera_input = _camera_input
	_placement_pick.voxel_world = _voxel_world
	_placement_pick.tool_state_machine = _tool_state_machine
	_commit_pipeline.placement_pick = _placement_pick
	_commit_pipeline.voxel_world = _voxel_world
	_construction_tick_loop.voxel_world = _voxel_world
	_villager_ai.voxel_world = _voxel_world
	_build_validation.voxel_world = _voxel_world
	_torch_flicker.light = _ambient_torch_light
	_villager_roster_provider = _ValleyRosterProvider.new(self)
	_villager_body_presenter.roster_provider = _villager_roster_provider

	# Story presentation-004: WorldLighting's two Node-typed cross-refs.
	_world_lighting.directional_light = _sun_light
	_world_lighting.world_environment = _world_environment

	# Story cam-013: the camera-mirror driver's two Node-typed cross-refs.
	_camera_mirror.camera = _valley_camera
	_camera_mirror.camera_input = _camera_input

	# Story build-validation-009: the loop-payoff adapter's two Node-typed
	# cross-refs -- see class doc comment's own Story build-validation-009
	# paragraph.
	_loop_payoff_adapter.build_validation = _build_validation
	_loop_payoff_adapter.payoff_surface = _loop_payoff_signal_surface

	# Story scene-007: the build-tool tier's cross-sibling Node references +
	# the armed-tool -> resolver router. See class doc comment's own Story
	# scene-007 paragraphs for the full rationale.
	var game_world: GameWorld = get_parent() as GameWorld
	_tool_state_machine.game_world = game_world
	_build_editor_mode.tool_state_machine = _tool_state_machine
	_floor_tool.voxel_world = _voxel_world
	_floor_tool.commit_pipeline = _commit_pipeline
	_furniture_tool.voxel_world = _voxel_world
	_furniture_tool.commit_pipeline = _commit_pipeline
	_ghost_preview.tool_state_machine = _tool_state_machine
	_ghost_preview.placement_pick = _placement_pick
	_ghost_preview.commit_pipeline = _commit_pipeline
	_undo_redo_stack.game_world = game_world
	_undo_redo_stack.voxel_world_write_source = _voxel_world

	# Sub-scope C: a SHARED BuildingSystemWriteTag, assigned to both modules
	# BEFORE either module's setup() ever runs (both lazily default-construct
	# their own if left unassigned) -- see class doc comment's own
	# "BuildingSystemWriteTag sharing" paragraph.
	var shared_write_tag := BuildingSystemWriteTag.new()
	_undo_redo_stack.write_tag = shared_write_tag
	_construction_tick_loop.write_tag = shared_write_tag

	# The armed-tool -> resolver router's own lookup tables (Implementation
	# Notes: "the natural shape is a StringName -> Callable map"). Rule 8's
	# furniture-support check is TOOL-SWAPPED, not wired once unconditionally
	# -- see class doc comment's own "Correction to this story's own
	# Implementation Notes" paragraph for the real bug this fixes.
	_cell_set_resolvers = {
		ToolStateMachine.TOOL_ID_WALL: _wall_tool.resolve_cell_set,
		ToolStateMachine.TOOL_ID_FLOOR: _floor_tool.resolve_cell_set,
		ToolStateMachine.TOOL_ID_ROOF: _roof_tool.resolve_cell_set,
		ToolStateMachine.TOOL_ID_BLOCK: _block_tool.resolve_cell_set,
		ToolStateMachine.TOOL_ID_FURNITURE: _furniture_tool.resolve_cell_set,
	}
	_furniture_support_predicates = {
		ToolStateMachine.TOOL_ID_FURNITURE: _furniture_tool.is_cell_supported,
	}
	_terrain_replace_resolvers = {
		ToolStateMachine.TOOL_ID_FLOOR: _floor_tool.resolve_terrain_replace_cells,
	}
	_tool_state_machine.tool_armed.connect(_on_tool_armed)


## Boot invariant (Story presentation-004, AC5) -- asserts exactly one
## [DirectionalLight3D] and exactly one [WorldEnvironment] are hosted as
## direct children of this Valley once [method _wire_hosted_modules] has run.
## Fails LOUDLY (ADR-0005's own "fail loudly, not silently" convention,
## matching [method seed_default_villager_needs]/[method
## spawn_starting_roster]'s own ordering-guard asserts) rather than leaving
## "exactly one sun, exactly one environment" as an unstated hope a future
## story could silently violate (e.g. a second hand-added light for a new
## feature). Counts direct children only -- every hosted lighting node this
## class owns is authored as a direct child of `.` in `Valley.tscn`, matching
## every other hosted module's own convention, so a direct-child count is
## sufficient and avoids over-counting anything a future child SCENE
## (e.g. a furniture prefab) might itself carry.
func _assert_lighting_boot_invariant() -> void:
	var sun_count: int = 0
	var environment_count: int = 0
	for child: Node in get_children():
		if child is DirectionalLight3D:
			sun_count += 1
		if child is WorldEnvironment:
			environment_count += 1
	assert(
		sun_count == 1,
		"Valley must host exactly one DirectionalLight3D, found %d" % sun_count
	)
	assert(
		environment_count == 1,
		"Valley must host exactly one WorldEnvironment, found %d" % environment_count
	)


## Boot invariant (Story vox-023, AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL, Lever 3)
## -- asserts the hosted [VoxelWorldMesher]'s [member VoxelWorldMesher.appearance]
## config is wired, mirroring [method _assert_lighting_boot_invariant]'s own
## "fail loudly, not silently" convention. Sprint-12's own deepest rule, named
## explicitly against this exact shape (S11's worst finding: both villager
## gates defaulted PERMISSIVE when unwired, making criterion #5 inert in the
## product while green in test) -- an unwired appearance config must be a
## loud boot failure, never a correct-looking render. This is a SECOND,
## independent catch alongside [method VoxelWorldMesher.setup]'s own identical
## assert -- belt-and-suspenders, not a replacement for it.
func _assert_block_appearance_boot_invariant() -> void:
	assert(
		_voxel_world_mesher.appearance != null,
		"Valley must wire VoxelWorldMesher.appearance (block appearance config) -- an unwired" +
		" appearance config must be a loud boot failure, never a correct-looking render"
	)


## Boot invariant (Story presentation-005, F7) -- extends this class's own
## "fail loudly, not silently" boot-invariant block once more (mirrors
## [method _assert_lighting_boot_invariant]/[method
## _assert_block_appearance_boot_invariant]): [FurniturePresenter] must be
## hosted (non-null) and its [member FurniturePresenter.furniture_registry]
## must be wired to the SAME instance this Valley constructed -- sprint-12's
## own deepest rule ("no injected collaborator is both optional and
## consequential") applied to this story's own new collaborator, exactly as
## its own story file requires.
func _assert_furniture_presenter_boot_invariant() -> void:
	assert(_furniture_presenter != null, "Valley must host exactly one FurniturePresenter instance")
	assert(
		_furniture_presenter.furniture_registry == _furniture_registry,
		"Valley: FurniturePresenter.furniture_registry must be wired to the SAME hosted" +
		" FurnitureRegistry instance -- never left null, never a second one"
	)


## Boot invariant (Story `building-034` second pass) -- extends this class's
## own "fail loudly, not silently" boot-invariant block a final time
## (sprint-12's own standing rule: "any injected collaborator whose absence
## changes behaviour must ASSERT AT BOOT or appear in the boot-invariant
## block. NEVER both optional and consequential."). [ScaffoldRegistry]/
## [ScaffoldErectionCoordinator]/[ScaffoldDismantleCoordinator] must each be
## constructed (non-null); [ScaffoldPresentation] must be hosted and its
## `scaffold_registry` wired to the SAME instance; every hosted [VillagerAi]'s
## `scaffold_registry` must point at the SAME instance too (D1's own
## "the SAME shared instance every hosted villager is assigned" precedent);
## [member scaffold_config] must not be left `null`.
func _assert_scaffold_boot_invariant() -> void:
	assert(_scaffold_registry != null, "Valley must construct exactly one ScaffoldRegistry")
	assert(
		_scaffold_erection_coordinator != null,
		"Valley must construct exactly one ScaffoldErectionCoordinator"
	)
	assert(
		_scaffold_dismantle_coordinator != null,
		"Valley must construct exactly one ScaffoldDismantleCoordinator"
	)
	assert(
		_scaffold_erection_coordinator.nav_graph == _villager_nav_graph,
		"Valley: ScaffoldErectionCoordinator.nav_graph must be wired to the SAME hosted" +
		" VillagerNavGraph instance -- never left null (Story villager-ai-025's own" +
		" villager-descent trigger silently never fires without it)"
	)
	assert(_scaffold_presentation != null, "Valley must host exactly one ScaffoldPresentation instance")
	assert(
		_scaffold_presentation.scaffold_registry == _scaffold_registry,
		"Valley: ScaffoldPresentation.scaffold_registry must be wired to the SAME hosted" +
		" ScaffoldRegistry instance -- never left null, never a second one"
	)
	assert(
		scaffold_config != null,
		"Valley must wire scaffold_config (ScaffoldConfig) -- an unwired config must be a loud" +
		" boot failure, never a silently-defaulted cantilever limit"
	)
	for villager: VillagerAi in get_villagers():
		assert(
			villager.scaffold_registry == _scaffold_registry,
			"Valley: villager_id %d's scaffold_registry must be wired to the SAME hosted" %
			villager.get_villager_id() + " ScaffoldRegistry instance"
		)


## The armed-tool -> resolver router (Story scene-007, AC-TOOL-RESOLVER-IS-LIVE)
## -- re-points [CommitPipeline]'s single cell-set/terrain-replace resolver
## slots every time [signal ToolStateMachine.tool_armed] fires, keyed by
## [param tool_id]. An unrecognized [param tool_id] (or the future furniture
## id before this story wired it) falls back to an invalid [Callable] for
## both slots -- [CommitPipeline]'s own documented fallback (the
## `_default_cell_set` placeholder for cell-set; "no cell of this commit is
## terrain-replace eligible" for the other) -- never a crash. This method
## itself never calls [method ToolStateMachine.arm_tool] (AC-BUILD-MODE-IS-
## THE-ONLY-ARMING-PATH's own grep guard: zero `arm_tool(` call sites in this
## file) -- it only REACTS to the signal [BuildEditorMode]/[ToolStateMachine]
## already fired.
func _on_tool_armed(tool_id: StringName) -> void:
	_commit_pipeline.set_cell_set_resolver(_cell_set_resolvers.get(tool_id, Callable()))
	_commit_pipeline.set_terrain_replace_resolver(_terrain_replace_resolvers.get(tool_id, Callable()))
	_commit_pipeline.set_furniture_support_predicate(_furniture_support_predicates.get(tool_id, Callable()))


## Constructs and wires the build-project lifecycle tier's `RefCounted`
## collaborators (Story scene-007, Sub-scopes B/C, ADR-0016) -- mirrors
## [method _wire_villager_population]'s own established construction-site
## precedent. Connects [signal CommitPipeline.blueprint_cells_created] to
## [method _on_blueprint_cells_created], the sole seam that drives BOTH the
## undo-recording (Sub-scope C) and the registry/job-queue chain (Sub-scope
## B) from one real commit. See class doc comment's own Story scene-007
## paragraphs for the full rationale, including the `BuildValidation`
## deviation named there.
func _wire_build_project_lifecycle() -> void:
	_build_project_registry = BuildProjectRegistry.new()
	_construction_job_queue = ConstructionJobQueue.new(_construction_tick_loop)
	_removal_tool = RemovalTool.new(_build_project_registry, _construction_tick_loop, _construction_job_queue)
	_plan_only_undo_gate = PlanOnlyUndoGate.new(
		_undo_redo_stack, _build_project_registry, _voxel_world, _construction_job_queue, _construction_tick_loop
	)
	_furniture_registry = FurnitureRegistry.new()
	_construction_tick_loop.furniture_registry = _furniture_registry
	# Story presentation-005: FurniturePresenter's own registry cross-reference --
	# assigned here, not in _wire_hosted_modules(), because _furniture_registry
	# does not exist until the line above runs (see class doc comment).
	_furniture_presenter.furniture_registry = _furniture_registry
	# Story scene-008 -- BuildValidation's own duck-typed furniture_registry
	# cross-reference, assigned before BuildValidation.setup() ever runs (that
	# call is reached only via [method get_injected_tier_modules], strictly
	# after this whole _ready() pass completes).
	_build_validation.furniture_registry = _furniture_registry
	# Story scene-008 closes "Open Decision 3, resolved (a)" (see class doc
	# comment): BuildValidation is now hosted, so its real instance replaces
	# the `null` this class used to pass here -- is_bed_sheltered() now
	# answers for real instead of structurally reading false.
	_furniture_bed_provider = FurnitureBedProvider.new(_furniture_registry, _build_validation)
	# Story scene-008 closes the OTHER deviation this class doc comment named
	# ("Also found while reading, also explicitly NOT pulled into this
	# story"): VillagerOnSiteGate/VillagerSealPreventionGate wire themselves
	# into _construction_job_queue's own occupancy/seal-prevention predicate
	# seams from their own _init (see each class's own doc comment) -- neither
	# was constructed anywhere in `src/` before this story, so both predicates
	# defaulted permissively and every claimed job credited on a timer
	# regardless of whether its claiming villager had actually arrived.
	_villager_onsite_gate = VillagerOnSiteGate.new(_construction_job_queue)
	_villager_seal_prevention_gate = VillagerSealPreventionGate.new(_construction_job_queue, villager_ai_config)
	_commit_pipeline.blueprint_cells_created.connect(_on_blueprint_cells_created)

	# Story `building-034` second pass -- the scaffold registry (D1) and its
	# live wiring into the rest of the running game (see class doc comment's
	# own Story `building-034` paragraphs).
	_scaffold_registry = ScaffoldRegistry.new()
	_construction_tick_loop.scaffold_registry = _scaffold_registry
	_scaffold_presentation.scaffold_registry = _scaffold_registry
	# The clock comes FROM the tick loop, never resolved here. Scene & World
	# Management is forbidden to reference TimeTickSystem at all — there is a
	# grep guard on this directory — and ConstructionTickLoop already resolves
	# and holds the same instance during its own setup, so reading it back is
	# both compliant and a guarantee that every scaffold-tier collaborator
	# shares one clock rather than racing several. Story villager-ai-025 wires
	# the SAME roster provider [VillagerBodyPresenter] already uses (see class
	# doc comment) into the erection coordinator's own new villager-descent
	# trigger here -- its own clock subscription and `nav_graph` cross-wire
	# both happen LATER (see [method connect_scaffold_erection_descent_trigger]/
	# [method _wire_villager_population]'s own new paragraphs): neither
	# [member _construction_tick_loop]'s own [member
	# ConstructionTickLoop.time_tick_system] NOR [member _villager_nav_graph]
	# exists yet at this exact point in `_ready()`.
	_scaffold_erection_coordinator = ScaffoldErectionCoordinator.new(
		_voxel_world, _scaffold_registry, _build_project_registry, _construction_job_queue,
		_furniture_registry, scaffold_config, _villager_roster_provider,
	)
	_scaffold_dismantle_coordinator = ScaffoldDismantleCoordinator.new(
		_build_project_registry, _construction_tick_loop, _scaffold_registry,
		_villager_roster_provider, _construction_tick_loop.time_tick_system,
	)
	_removal_tool.project_canceled.connect(_scaffold_dismantle_coordinator.on_project_canceled)


## The `blueprint_cells_created` chain (Story scene-007, Sub-scopes B + C) --
## see class doc comment's own dedicated paragraph. Records the WHOLE commit
## as one [UndoRedoStack] command FIRST (Core Rule 17: "one wall drag = one
## command = one undo step" -- the full cell list, not per-cell), then routes
## the same cells into [method BuildProjectRegistry.assign_cells] and
## registers every distinct resulting project into [member
## _construction_job_queue] EXACTLY ONCE per project id (see [member
## _job_queue_registered_project_ids]'s own doc comment for why this guard is
## this class's own responsibility, not either landed class's).
func _on_blueprint_cells_created(cells: Array[BlueprintCell]) -> void:
	var cell_addresses: Array[Vector3i] = []
	for cell: BlueprintCell in cells:
		cell_addresses.append(cell.cell)
	_undo_redo_stack.record_command(cell_addresses)
	var projects: Array[BuildProject] = _build_project_registry.assign_cells(cells, BuildProject.Kind.BUILD)
	for project: BuildProject in projects:
		if not _job_queue_registered_project_ids.has(project.id):
			_job_queue_registered_project_ids[project.id] = true
			_construction_job_queue.add_project(project)


## Story vox-018's ONE new per-frame hook (class doc comment) -- reads the
## hosted [CameraInput]'s CURRENT orbit target every engine frame, converts
## it to a cell, and drives the hosted [VoxelWorldMeshStreamer]'s budgeted
## per-frame streaming step. Safe to run from this class's very first
## processed frame onward: by the time any node's `_process` callback can
## fire, [GameWorld]'s entire boot sequence (`_attach_valley` ->
## `_gather_valley_tier_modules` -> `_setup_injected_tier` ->
## [method GameWorld._build_initial_voxel_mesh_window]) has already run
## synchronously to completion within the SAME call stack that attached this
## instance to the tree -- so [member _voxel_world_mesh_streamer]'s DI is
## wired, every hosted module's `setup()` has already run, and the UNBOUNDED
## initial window build has already happened exactly once, before this
## method is ever invoked for the first time.
## Story scene-005 (World genesis in the boot sequence, AC-NO-SYNC-IO-IN-
## FRAME-PATH): drives [member _voxel_world]'s BUDGETED residency window
## (never [method VoxelWorldGrid.drain_pending_async_reads]/[method
## VoxelWorldGrid.wait_for_async_residency_idle] -- both grep-guarded absent
## from any `_process`/`_physics_process` call graph, tests/boot-genesis-only
## synchronization points) every frame, BEFORE the pre-existing mesh
## view-window streaming call -- vox-018's own explicitly-named seam ("a
## shared per-frame focus-drive call site is the natural home for both").
## The settlement anchor is recomputed each frame from [method
## VillagerRosterSpawner.world_center_cell] -- a pure, cheap function of
## [member _voxel_world]'s own config, so this is always the SAME start-focus
## cell world genesis anchored on ([method GameWorld._run_world_genesis]),
## with no separate stored-anchor seam to keep in sync.
func _process(_delta: float) -> void:
	var focus_cell: Vector3i = VoxelWorldGrid.world_to_cell(_camera_input.get_target())
	var settlement_anchor_cell: Vector3i = VillagerRosterSpawner.world_center_cell(_voxel_world.config)
	_voxel_world.update_residency(focus_cell, settlement_anchor_cell)
	_voxel_world_mesh_streamer.update_view_window(focus_cell)


## Performs the villager population's non-`@export` DI assignment -- see
## class doc comment for the full rationale and the load-bearing ordering
## guarantee this relies on. Idempotent-safe to call more than once (a fresh
## [VillagerDecidingScheduler]/[VillagerNavGraph] pair is harmless to
## construct twice for this story's single-villager population -- a future
## multi-villager spawning story owns the "exactly one shared pair for the
## whole population" bookkeeping this method's own single-villager shape
## does not yet need to enforce).
func _wire_villager_population() -> void:
	_villager_deciding_scheduler = VillagerDecidingScheduler.new()
	_villager_nav_graph = VillagerNavGraph.new()
	_villager_unstuck_telemetry = VillagerUnstuckTelemetry.new()
	_villager_ai.scheduler = _villager_deciding_scheduler
	_villager_ai.nav_graph = _villager_nav_graph
	_villager_ai.unstuck_telemetry = _villager_unstuck_telemetry
	_villager_ai.needs_provider = _needs_mood
	# Story scene-007: the SAME ConstructionJobQueue/FurnitureBedProvider
	# instance every hosted VillagerAi (this one, plus every future roster
	# member spawn_starting_roster() creates) is assigned -- see class doc
	# comment's own Story scene-007 paragraphs.
	_villager_ai.job_queue = _construction_job_queue
	_villager_ai.bed_provider = _furniture_bed_provider
	# Story scene-008: register the always-present default villager with both
	# gates (see class doc comment) -- the SAME "the SAME shared instance
	# every hosted villager is assigned" precedent this method already
	# establishes for job_queue/bed_provider, extended to registration-style
	# collaborators.
	_villager_onsite_gate.register_villager(_villager_ai)
	_villager_seal_prevention_gate.register_villager(_villager_ai)
	# Story `building-034` second pass (D1's own named injection point --
	# "VillagerAi's existing one-line delegations") -- the SAME shared
	# ScaffoldRegistry every consumer holding this VillagerAi becomes
	# scaffold-aware through, for free (VillagerNavGraph, the re-path filter).
	_villager_ai.scaffold_registry = _scaffold_registry
	_villager_nav_graph.subscribe_to_voxel_world(_voxel_world, _villager_ai)
	# ADR-0007 §2b -- the ONLY path a scaffold write ever patches the hosted
	# nav graph through (a scaffold write is never a VoxelWorldGrid write, so
	# [signal VoxelWorldGrid.cell_changed] never fires for it).
	_villager_nav_graph.subscribe_to_scaffold_registry(_scaffold_registry, _villager_ai)
	# Story villager-ai-025 -- the erection coordinator's own per-tick
	# marooned-villager descent check needs this SAME shared nav graph; not
	# constructible earlier ([method _wire_build_project_lifecycle], which
	# already constructed the coordinator, runs strictly BEFORE this method --
	# see `_ready()`'s own call order), so it is cross-wired here instead,
	# mirroring [member _furniture_presenter]'s own established "assigned
	# once its own dependency exists" precedent (see [method
	# _wire_build_project_lifecycle]'s own doc comment).
	_scaffold_erection_coordinator.nav_graph = _villager_nav_graph


## Returns the hosted Voxel World / Grid Data instance.
func get_voxel_world() -> VoxelWorldGrid:
	return _voxel_world


## Returns the hosted Voxel World mesher instance.
func get_voxel_world_mesher() -> VoxelWorldMesher:
	return _voxel_world_mesher


## Returns the hosted Camera & Input instance.
func get_camera_input() -> CameraInput:
	return _camera_input


## Returns the hosted, passive [Camera3D] the shipped scene chain actually
## renders through (Story cam-013).
func get_valley_camera() -> Camera3D:
	return _valley_camera


## Returns the hosted [CameraMirror] instance (Story cam-013).
func get_camera_mirror() -> CameraMirror:
	return _camera_mirror


## Returns the hosted Voxel World mesh view-window streamer instance
## (story vox-018).
func get_voxel_world_mesh_streamer() -> VoxelWorldMeshStreamer:
	return _voxel_world_mesh_streamer


## Returns the hosted Building System tool state machine instance.
func get_tool_state_machine() -> ToolStateMachine:
	return _tool_state_machine


## Returns the hosted Building System placement-pick instance.
func get_placement_pick() -> PlacementPick:
	return _placement_pick


## Returns the hosted Building System commit-pipeline instance.
func get_commit_pipeline() -> CommitPipeline:
	return _commit_pipeline


## Returns the hosted Building System construction-tick-loop instance.
func get_construction_tick_loop() -> ConstructionTickLoop:
	return _construction_tick_loop


## Returns the hosted Villager AI instance.
func get_villager_ai() -> VillagerAi:
	return _villager_ai


## Returns the hosted Needs & Mood System instance (Story needs-mood-010).
func get_needs_mood() -> NeedsMood:
	return _needs_mood


## Returns the shared, population-wide [VillagerNavGraph] instance [method
## _wire_villager_population] constructs (fulfilling the "exposed read-only
## for... a future world-generation story" promise [member
## _villager_nav_graph]'s own doc comment already made -- this IS that story).
## Returns the settlement's own standable-ground reference cell (Story
## villager-ai-025) -- callers MUST check [method has_settlement_ground_cell]
## first; this returns `Vector3i.ZERO` (a real, potentially-misleading cell
## address) before genesis has run.
func get_settlement_ground_cell() -> Vector3i:
	return _settlement_ground_cell


## Whether [method build_villager_nav_graph] has ever resolved a real
## settlement-ground reference cell (Story villager-ai-025).
func has_settlement_ground_cell() -> bool:
	return _has_settlement_ground_cell


func get_villager_nav_graph() -> VillagerNavGraph:
	return _villager_nav_graph


## Default region size used ONLY when [member villager_ai_config] is unwired
## (mirrors [method spawn_starting_roster]'s own established "`if config !=
## null` else a documented literal default" precedent for this exact optional
## dependency) -- [constant VillagerAIConfig.NAV_REGION_SIZE_MIN], the GDD's
## own conservative floor, never an invented literal.
const DEFAULT_NAV_REGION_SIZE: int = VillagerAIConfig.NAV_REGION_SIZE_MIN


## Config-driven nav-graph build (Story scene-005, AC-NAV-GRAPH-BUILT) --
## builds the shared [VillagerNavGraph] over a [param region_size] x
## [param region_size] window centered on [param region_center], reading
## [member villager_ai_config]'s `nav_region_size` (never a literal, ADR-0002)
## with the same optional-config fallback [method spawn_starting_roster]
## already establishes. [member _villager_ai] (villager_id 0, always present)
## is the `predicate_source` -- [VillagerNavGraph.build]'s own predicate reads
## are instance-independent (BV-4 ruling: every [VillagerAi] instance answers
## identically), so which hosted villager supplies them is immaterial; this is
## the SAME predicate_source shape [VillagerNavGraph.subscribe_to_voxel_world]
## already uses in [method _wire_villager_population]. Called from [method
## GameWorld._run_world_genesis], AFTER the boot-window residency drive has
## made real terrain resident (this class never calls this on its own --
## exactly [VillagerNavGraph.build]'s own pre-existing "a fresh grid has no
## terrain yet" deferral this story closes).
func build_villager_nav_graph(region_center: Vector3i) -> void:
	var region_size: int = DEFAULT_NAV_REGION_SIZE
	if villager_ai_config != null:
		region_size = villager_ai_config.nav_region_size
	_villager_nav_graph.build(_voxel_world, _villager_ai, region_center, region_size)
	# Story villager-ai-025 -- a real standable ground cell near the SAME
	# center genesis already anchors the camera/nav graph/roster on (never a
	# second, independently-chosen anchor), resolved the SAME way
	# spawn_starting_roster's own ring search already finds real standable
	# placement cells (VillagerRosterSpawner.select_starting_cells) --
	# region_center itself is only a Y-midpoint guess (that method's own doc
	# comment), never itself guaranteed standable.
	var ground_candidates: Array[Vector3i] = VillagerRosterSpawner.select_starting_cells(
		_voxel_world, region_center, 1
	)
	if not ground_candidates.is_empty():
		_settlement_ground_cell = ground_candidates[0]
		_has_settlement_ground_cell = true


## Story villager-ai-025 -- connects [ScaffoldErectionCoordinator]'s own
## villager-descent trigger to the real clock, deferred to this call site for
## the SAME reason [method build_villager_nav_graph] already is: called from
## [method GameWorld._run_world_genesis], strictly AFTER `_setup_injected_tier()`
## has already run [method ConstructionTickLoop.setup] -- see [method
## ScaffoldErectionCoordinator.connect_tick]'s own doc comment for the full
## "reading [member ConstructionTickLoop.time_tick_system] any earlier reads
## it while still null" finding this call site exists to avoid.
func connect_scaffold_erection_descent_trigger() -> void:
	_scaffold_erection_coordinator.connect_tick(_construction_tick_loop.time_tick_system)
	# The dismantle coordinator needs the same deferred connection, and for the
	# same reason: its constructor-time attempt ran before ConstructionTickLoop
	# resolved its own clock, so the tick was silently never connected and
	# SC-INV-2's deferred retry could never fire in the shipped game.
	_scaffold_dismantle_coordinator.connect_tick(_construction_tick_loop.time_tick_system)


## Seeds [member _villager_ai] (villager_id 0, the always-present default)
## through [method NeedsMood.initialize_villager] -- Story scene-006's own
## new home for this call, since the provider ASSIGNMENT for this villager
## stays in [method _wire_villager_population] (unchanged, still [method
## _ready]'s own call graph) while the SEEDING moves here: an explicitly-
## callable method reached ONLY from [method GameWorld._run_world_genesis]
## (duck-typed, mirroring [method build_villager_nav_graph]/[method
## spawn_starting_roster]'s own call-site shape) -- never from [method
## _ready] (AC-SEED-NOT-FROM-READY, ADR-0005, `needs-mood-006`'s own Control
## Manifest "never in `_ready()`"). Asserts [method NeedsMood.is_set_up]
## first (AC-SEED-AFTER-SETUP) -- [method GameWorld._run_world_genesis] only
## ever runs after [method GameWorld._setup_injected_tier]'s own `setup()`
## sweep has already completed, so this assert should never trip in
## production; it exists to make the ordering constraint fail LOUDLY rather
## than silently seed from unvalidated config if a future call site ever
## violates it. Idempotent by [method NeedsMood.initialize_villager]'s own
## landed contract -- calling this twice never resets an already-decayed
## value.
func seed_default_villager_needs() -> void:
	assert(
		_needs_mood.is_set_up(),
		"Valley.seed_default_villager_needs called before NeedsMood.setup() has completed"
	)
	_needs_mood.initialize_villager(_villager_ai.villager_id)


## Returns every hosted [VillagerAi] instance (Story villager-ai-021) --
## [member _villager_ai] (the always-present default, villager_id 0) first,
## then any members [method spawn_starting_roster] has added so far, in the
## order they were spawned.
func get_villagers() -> Array[VillagerAi]:
	var all: Array[VillagerAi] = [_villager_ai]
	all.append_array(_spawned_villagers)
	return all


## Config-driven starting-roster spawn (Story villager-ai-021, GDD Rule 14b /
## [TR-villager-ai-behavior-065]) -- reads [member villager_ai_config]'s
## `starting_villager_count`, selects that many valid standable cells near
## the world center via [method VillagerRosterSpawner.select_starting_cells],
## and assembles + hosts one new [VillagerAi] per selected cell via [method
## VillagerRosterSpawner.assemble_roster] (DI-wired: config/voxel_world/
## scheduler/nav_graph/unstuck_telemetry, `villager_id` continuing after
## every villager already hosted, `current_cell`/`_from_cell`/`_to_cell` on
## its assigned cell). Adds each as a REAL child of this Valley (so its own
## [method VillagerAi._process] visual-lerp runs every frame in production,
## mirroring every other hosted module) and calls its `setup()` directly --
## a sanctioned, on-demand call site distinct from [GameWorld]'s own
## boot-gate sweep (ADR-0005: that rule governs the ONE-TIME INITIAL sweep
## only; a villager assembled well after boot, once real terrain actually
## exists, has no other entry point to reach `setup()` from).
##
## Deliberately NEVER called from [method _ready] -- see class doc comment's
## Story villager-ai-021 paragraph for the full "terrain pages in
## asynchronously, post-boot" rationale this mirrors from [method
## VillagerNavGraph.build]'s own pre-existing deferral. Returns however many
## villagers were actually placed -- fewer than `starting_villager_count` (or
## even zero) is a valid, deterministic outcome when the world does not yet
## have enough standable cells near the center within [constant
## VillagerRosterSpawner.MAX_SEARCH_RADIUS] (never a crash, never a partial/
## inconsistent villager).
func spawn_starting_roster() -> Array[VillagerAi]:
	# Story scene-006 (AC-SEED-AFTER-SETUP): checked FIRST, before any
	# placement/assembly work runs -- a villager is never even constructed
	# (let alone left as an unhosted orphan node) if this guard trips. Makes
	# the ordering constraint fail loudly rather than silently seed from
	# unvalidated config if a future call site ever violates it.
	assert(
		_needs_mood.is_set_up(),
		"Valley.spawn_starting_roster seeding a villager before NeedsMood.setup() has completed"
	)
	var center_cell: Vector3i = VillagerRosterSpawner.world_center_cell(_voxel_world.config)
	var count: int = 1
	if villager_ai_config != null:
		count = villager_ai_config.starting_villager_count
	var cells: Array[Vector3i] = VillagerRosterSpawner.select_starting_cells(
		_voxel_world, center_cell, count
	)

	# Story villager-ai-022 (AC2/AC4): villager 0 -- the always-present,
	# scene-hosted default -- is placed through this SAME selection call, not
	# a second hand-rolled path, and COUNTS toward `count` (see class doc
	# comment's own villager-ai-022 paragraph for the chosen convention).
	# Only the FIRST successful placement ever reserves a cell for it
	# (member _default_villager_placed) -- a later growth call must never
	# re-teleport an already-simulating villager 0.
	if not _default_villager_placed:
		if cells.is_empty():
			# AC3: a deterministic, LOGGED outcome -- never a silent leave-at-
			# the-origin. _default_villager_placed stays false, so a later
			# call (once real terrain exists) gets another chance.
			push_warning((
				"Valley.spawn_starting_roster: no standable cell found near world" +
				" center %s for villager 0 within VillagerRosterSpawner.MAX_SEARCH_RADIUS" +
				" -- it remains at %s (logged, not silently left there)"
			) % [center_cell, _villager_ai.current_cell])
		else:
			VillagerRosterSpawner.place_villager_at_cell(_villager_ai, cells[0])
			_default_villager_placed = true
			cells = cells.slice(1)

	var next_id: int = 1 + _spawned_villagers.size()
	var new_villagers: Array[VillagerAi] = VillagerRosterSpawner.assemble_roster(
		_voxel_world,
		villager_ai_config,
		_villager_deciding_scheduler,
		_villager_nav_graph,
		_villager_unstuck_telemetry,
		cells,
		next_id,
	)
	for villager: VillagerAi in new_villagers:
		villager.needs_provider = _needs_mood
		# Story scene-007: the SAME shared job_queue/bed_provider instances
		# every roster member is assigned -- see [method
		# _wire_villager_population]'s own identical assignment for villager_id
		# 0 and class doc comment's own Story scene-007 paragraphs.
		villager.job_queue = _construction_job_queue
		villager.bed_provider = _furniture_bed_provider
		# Story `building-034` second pass -- the SAME shared ScaffoldRegistry
		# every hosted villager is assigned (see [method
		# _wire_villager_population]'s own identical assignment for villager_id
		# 0 and class doc comment's own Story `building-034` paragraphs).
		villager.scaffold_registry = _scaffold_registry
		# Story scene-008: the SAME shared gates every hosted villager is
		# registered with -- see [method _wire_villager_population]'s own
		# identical registration for villager_id 0 and class doc comment's
		# own Story scene-008 paragraph.
		_villager_onsite_gate.register_villager(villager)
		_villager_seal_prevention_gate.register_villager(villager)
		# Story scene-006 (AC-SEED-EVERY-ROSTER-MEMBER): seed this villager's
		# needs through the landed [method NeedsMood.initialize_villager]
		# surface, right where its provider is assigned -- already legal here
		# (this method is only ever reached from [method
		# GameWorld._run_world_genesis], strictly after every hosted module's
		# `setup()` has run; see [method seed_default_villager_needs]'s own
		# doc comment for why villager_id 0 needed a DIFFERENT call site
		# instead of this one). The ordering guard already ran above, before
		# any villager in this loop was even assembled.
		_needs_mood.initialize_villager(villager.villager_id)
		add_child(villager)
		villager.setup()
		_spawned_villagers.append(villager)
	# Story presentation-003: re-sync the hosted body-view set so every newly
	# spawned villager gets a real VillagerBodyView -- [member
	# _villager_body_presenter]'s own `setup()` (boot-gated, [GameWorld]'s own
	# sweep) already created a view for [member _villager_ai] (villager_id 0)
	# before any roster spawn can run; this call only ADDS views for the
	# entries this method just created, never touching that one.
	_villager_body_presenter.refresh()
	_assert_villager_placement_invariant()
	return new_villagers


## Boot invariant (Story villager-ai-022, AC1/AC5) -- asserts every hosted
## villager [method get_villagers] reports stands on a cell the voxel world
## itself reports standable ([VillagerWalkabilityRules.is_standable]), UNLESS
## that villager is villager 0 in the exact AC3 degenerate case (the search
## found zero standable cells at all, so it was never placed -- already
## `push_warning`-logged above, not re-failed here). Fails LOUDLY (mirrors
## [method _assert_lighting_boot_invariant]/[method
## seed_default_villager_needs]'s own "fail loudly, not silently" convention)
## rather than letting a future regression silently reintroduce a villager
## stranded off the settlement -- this story's own root cause.
func _assert_villager_placement_invariant() -> void:
	for villager: VillagerAi in get_villagers():
		if villager == _villager_ai and not _default_villager_placed:
			continue
		assert(
			VillagerWalkabilityRules.is_standable(_voxel_world, villager.get_current_cell()),
			"Valley: villager_id %d stands on a non-standable cell %s after spawn_starting_roster" %
			[villager.get_villager_id(), villager.get_current_cell()]
		)


## Boot invariant (Story scene-008, AC5) -- extends this class's own
## established "fail loudly, not silently" boot-invariant block (mirrors
## [method _assert_lighting_boot_invariant]/[method
## _assert_villager_placement_invariant]) to cover the three classes this
## story hosts for the first time: [BuildValidation] and
## [VillagerOnSiteGate]/[VillagerSealPreventionGate] must each be
## constructed (non-null) exactly once per [method _ready] pass, and [member
## FurnitureBedProvider.build_validation] must be wired to a real instance,
## never the `null` Story scene-007 recorded. Called from [method _ready],
## after [method _wire_build_project_lifecycle]/[method
## _wire_villager_population] have both run.
func _assert_build_validation_gates_boot_invariant() -> void:
	assert(_build_validation != null, "Valley must host exactly one BuildValidation instance")
	assert(_villager_onsite_gate != null, "Valley must construct exactly one VillagerOnSiteGate")
	assert(
		_villager_seal_prevention_gate != null,
		"Valley must construct exactly one VillagerSealPreventionGate"
	)
	assert(
		_furniture_bed_provider.build_validation != null,
		"Valley: FurnitureBedProvider.build_validation must not be null -- BuildValidation must" +
		" be wired here, never passed null (Story scene-007's own recorded deviation)"
	)


## Boot invariant (Story build-validation-009) -- extends this class's own
## established "fail loudly, not silently" boot-invariant block once more
## (mirrors [method _assert_lighting_boot_invariant]/[method
## _assert_build_validation_gates_boot_invariant]): both [LoopPayoffSignalSurface]
## and [LoopPayoffAdapter] must be hosted (non-null), and the adapter's own
## two dependencies ([member LoopPayoffAdapter.build_validation]/[member
## LoopPayoffAdapter.payoff_surface]) must be wired -- never left `null`,
## which would otherwise surface only as a silent no-op the first time a
## real room is recognized, not as a loud boot-time failure. Called from
## [method _ready], after [method _wire_hosted_modules].
func _assert_loop_payoff_wiring_boot_invariant() -> void:
	assert(
		_loop_payoff_signal_surface != null,
		"Valley must host exactly one LoopPayoffSignalSurface instance"
	)
	assert(_loop_payoff_adapter != null, "Valley must host exactly one LoopPayoffAdapter instance")
	assert(
		_loop_payoff_adapter.build_validation != null,
		"Valley: LoopPayoffAdapter.build_validation must not be null"
	)
	assert(
		_loop_payoff_adapter.payoff_surface != null,
		"Valley: LoopPayoffAdapter.payoff_surface must not be null"
	)


## Returns the hosted ambient torch/lantern light fixture (M01 condition C4).
func get_ambient_torch_light() -> Light3D:
	return _ambient_torch_light


## Returns the hosted [TorchFlicker] instance (M01 condition C4).
func get_torch_flicker() -> TorchFlicker:
	return _torch_flicker


## Returns the hosted sun (Story presentation-004).
func get_sun_light() -> DirectionalLight3D:
	return _sun_light


## Returns the hosted environment host (Story presentation-004).
func get_world_environment() -> WorldEnvironment:
	return _world_environment


## Returns the hosted [WorldLighting] instance (Story presentation-004).
func get_world_lighting() -> WorldLighting:
	return _world_lighting


## Returns the hosted [VillagerBodyPresenter] instance (Story
## presentation-003).
func get_villager_body_presenter() -> VillagerBodyPresenter:
	return _villager_body_presenter


## Returns the hosted [FurniturePresenter] instance (Story presentation-005).
func get_furniture_presenter() -> FurniturePresenter:
	return _furniture_presenter


## Returns the hosted [ScaffoldPresentation] instance (Story `building-034`
## second pass).
func get_scaffold_presentation() -> ScaffoldPresentation:
	return _scaffold_presentation


## Returns the constructed [ScaffoldRegistry] collaborator (Story
## `building-034` second pass) -- the SAME instance every hosted [VillagerAi]/
## [ConstructionTickLoop]/[ScaffoldPresentation] points at.
func get_scaffold_registry() -> ScaffoldRegistry:
	return _scaffold_registry


## Returns the constructed [ScaffoldErectionCoordinator] collaborator (Story
## `building-034` second pass).
func get_scaffold_erection_coordinator() -> ScaffoldErectionCoordinator:
	return _scaffold_erection_coordinator


## Returns the constructed [ScaffoldDismantleCoordinator] collaborator (Story
## `building-034` second pass) -- the live dismantle orchestrator.
func get_scaffold_dismantle_coordinator() -> ScaffoldDismantleCoordinator:
	return _scaffold_dismantle_coordinator


## Returns the shared, population-wide [VillagerUnstuckTelemetry] accumulator
## (Story villager-ai-021) -- the SAME instance every hosted villager reports
## into. Story `building-034`'s own Lever 3 reads
## [method VillagerUnstuckTelemetry.get_self_seal_climb_total]/[method
## VillagerUnstuckTelemetry.get_marooned_relocation_total] through this
## getter.
func get_villager_unstuck_telemetry() -> VillagerUnstuckTelemetry:
	return _villager_unstuck_telemetry


## Returns the hosted [BuildEditorMode] instance (Story scene-007).
func get_build_editor_mode() -> BuildEditorMode:
	return _build_editor_mode


## Returns the hosted [WallTool] instance (Story scene-007).
func get_wall_tool() -> WallTool:
	return _wall_tool


## Returns the hosted [FloorTool] instance (Story scene-007).
func get_floor_tool() -> FloorTool:
	return _floor_tool


## Returns the hosted [RoofTool] instance (Story scene-007).
func get_roof_tool() -> RoofTool:
	return _roof_tool


## Returns the hosted [BlockTool] instance (Story scene-007).
func get_block_tool() -> BlockTool:
	return _block_tool


## Returns the hosted [FurnitureTool] instance (Story scene-007).
func get_furniture_tool() -> FurnitureTool:
	return _furniture_tool


## Returns the hosted [GhostPreview] instance (Story scene-007).
func get_ghost_preview() -> GhostPreview:
	return _ghost_preview


## Returns the hosted [UndoRedoStack] instance (Story scene-007).
func get_undo_redo_stack() -> UndoRedoStack:
	return _undo_redo_stack


## Returns the constructed [BuildProjectRegistry] collaborator (Story
## scene-007).
func get_build_project_registry() -> BuildProjectRegistry:
	return _build_project_registry


## Returns the constructed [ConstructionJobQueue] collaborator (Story
## scene-007) -- the SAME instance [method get_villager_ai]/every roster
## member's own `job_queue` field points at.
func get_construction_job_queue() -> ConstructionJobQueue:
	return _construction_job_queue


## Returns the constructed [RemovalTool] collaborator (Story scene-007).
func get_removal_tool() -> RemovalTool:
	return _removal_tool


## Returns the constructed [PlanOnlyUndoGate] collaborator (Story scene-007).
func get_plan_only_undo_gate() -> PlanOnlyUndoGate:
	return _plan_only_undo_gate


## Returns the constructed [FurnitureRegistry] collaborator (Story scene-007)
## -- the SAME instance [member ConstructionTickLoop.furniture_registry]
## points at.
func get_furniture_registry() -> FurnitureRegistry:
	return _furniture_registry


## Returns the constructed [FurnitureBedProvider] collaborator (Story
## scene-007) -- the SAME instance [method get_villager_ai]/every roster
## member's own `bed_provider` field points at.
func get_furniture_bed_provider() -> FurnitureBedProvider:
	return _furniture_bed_provider


## Returns the hosted [BuildValidation] instance (Story scene-008).
func get_build_validation() -> BuildValidation:
	return _build_validation


## Returns the constructed [VillagerOnSiteGate] collaborator (Story
## scene-008) -- the SAME instance every hosted [VillagerAi] is registered
## with.
func get_villager_onsite_gate() -> VillagerOnSiteGate:
	return _villager_onsite_gate


## Returns the constructed [VillagerSealPreventionGate] collaborator (Story
## scene-008) -- the SAME instance every hosted [VillagerAi] is registered
## with.
func get_villager_seal_prevention_gate() -> VillagerSealPreventionGate:
	return _villager_seal_prevention_gate


## Returns the hosted [LoopPayoffSignalSurface] instance (Story
## build-validation-009).
func get_loop_payoff_signal_surface() -> LoopPayoffSignalSurface:
	return _loop_payoff_signal_surface


## Returns the hosted [LoopPayoffAdapter] instance (Story
## build-validation-009) -- the real production writer onto [method
## get_loop_payoff_signal_surface].
func get_loop_payoff_adapter() -> LoopPayoffAdapter:
	return _loop_payoff_adapter


## The GameWorld assembly seam (Story scene-004): every hosted tier module
## this Valley owns, in the load-bearing DI order [method
## GameWorld._setup_injected_tier] will call `setup()` in (Voxel World grid,
## then its mesher, then its mesh view-window streamer (story vox-018 --
## placed here so both its `grid`/`mesher` dependencies have already
## completed their own `setup()` by the time this streamer's runs), then
## Camera & Input, then the four Building System modules, then Villager AI).
## Story needs-mood-010 appends [NeedsMood]; story presentation-003 appends
## [VillagerBodyPresenter] LAST -- its own `setup()` reads [method
## get_villagers] (already valid: [member _villager_ai] exists from this
## same `_ready()` pass), creating that villager's initial
## [VillagerBodyView] before any roster spawn can ever run.
## [GameWorld] calls this exactly once, from
## [method GameWorld._on_database_settled], AFTER [method
## GameWorld._attach_valley] has already attached this instance -- appending
## the result to its own [member GameWorld.injected_tier_modules] array
## rather than requiring these dynamically-instantiated (`PackedScene`)
## nodes to somehow be Inspector-wired directly onto `GameWorld.tscn` itself
## (structurally impossible -- this Valley instance does not exist in that
## scene file's own saved node tree; it is instantiated at runtime). This
## class still never calls `setup()` on any of these itself (see class doc
## comment's hosting-vs-DI distinction) -- it only reports the list. Story
## presentation-004 adds a TWENTY-SECOND, [WorldLighting] (21 -> 22) --
## updated consciously, not incidentally, mirroring every prior story's own
## "flag this file" precedent (see e.g. cam-013's own paragraph above). Story
## scene-008 adds a TWENTY-THIRD, [BuildValidation] (22 -> 23) -- updated
## consciously, not incidentally, per this story's own dev-story instructions
## to flag this file (`VillagerOnSiteGate`/`VillagerSealPreventionGate` are
## `RefCounted` collaborators, not scene children, and do not affect this
## list -- they mirror `_construction_job_queue`'s own established shape).
## Story build-validation-009 adds TWO more, [LoopPayoffSignalSurface] and
## [LoopPayoffAdapter] (23 -> 25) -- updated consciously, not incidentally.
## Story presentation-005 adds a TWENTY-SIXTH, [FurniturePresenter] (25 -> 26)
## -- updated consciously, not incidentally, mirroring every prior story's
## own "flag this file" precedent. Story `building-034` second pass adds a
## TWENTY-SEVENTH, [ScaffoldPresentation] (26 -> 27) -- [ScaffoldRegistry]/
## [ScaffoldErectionCoordinator]/[ScaffoldDismantleCoordinator] are
## `RefCounted` collaborators, not scene children, and do not affect this
## list (mirrors `_construction_job_queue`'s own established shape).
func get_injected_tier_modules() -> Array[Node]:
	return [
		_voxel_world,
		_voxel_world_mesher,
		_voxel_world_mesh_streamer,
		_camera_input,
		_tool_state_machine,
		_build_editor_mode,
		_placement_pick,
		_commit_pipeline,
		_wall_tool,
		_floor_tool,
		_roof_tool,
		_block_tool,
		_furniture_tool,
		_ghost_preview,
		_undo_redo_stack,
		_construction_tick_loop,
		_build_validation,
		_needs_mood,
		_villager_ai,
		_torch_flicker,
		_villager_body_presenter,
		_camera_mirror,
		_world_lighting,
		_loop_payoff_signal_surface,
		_loop_payoff_adapter,
		_furniture_presenter,
		_scaffold_presentation,
	]
