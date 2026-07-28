## Root scene script for the injected-tier dependency-injection substrate
## (ADR-0001) and the boot-sequencing gate (ADR-0005), owned by Scene/World
## Management.
##
## Owns the injected-tier child modules listed in [member injected_tier_modules]
## and invokes each one's [code]setup()[/code] explicitly, once scene-file
## (Inspector) wiring has resolved -- never relying on [method _ready]
## ordering (ADR-0001). Additionally (ADR-0005), [method _ready] is the
## SINGLE unified boot gate: every injected-tier [code]setup()[/code] call is
## withheld until the Resource & Item Database dependency reports its
## Ready/Failed outcome via check-then-connect (a synchronous
## [code]is_ready()[/code] check first, a [code]validation_complete[/code]
## signal connect fallback otherwise). On Failed, [signal boot_halted] fires
## and NO injected-tier [code]setup()[/code] is ever called -- terminal, no
## recovery.
##
## Foundation Spine Story 003 scope note (ADR-0002): the WIRING loop
## additionally duck-types each injected-tier module for an optional
## [code]get_boot_blocking_issues() -> Array[String][/code] method, called
## immediately after that module's [code]setup()[/code]. A non-empty result
## means the module's config Resource failed a GDD-declared BLOCKING
## cross-value invariant (ADR-0002's two-tier `validate()` policy) -- the
## SAME terminal halt path as a RID Failed outcome fires (HALTED,
## [signal boot_halted], no further injected-tier `setup()` calls). This is
## an additive check, not a new call site: [method _setup_injected_tier]
## remains the sole place any injected-tier `setup()` is invoked.
##
## Foundation Spine Story 002 scope note (ADR-0005): [member
## resource_item_database] is deliberately NOT [code]@export[/code]ed --
## Resource & Item Database is Autoload-tier (ADR-0001 forbids
## [code]@export[/code]ing an Autoload into any module). The real
## [code]ResourceItemDatabase[/code] Autoload does not exist yet in this
## The ResourceItemDatabase autoload (rid-002) resolves at /root/ResourceItemDatabase.
## touch [code]project.godot[/code]), so the dependency is resolved lazily
## against [code]/root/ResourceItemDatabase[/code] the first time this node
## enters the tree, or assigned directly to a mock RID-shaped double in
## headless tests before that -- mirroring the existing
## [ReferenceInjectedModule] mock-assignment convention. rid-002's autoload
## the real Autoload, this resolves automatically with no further change
## here. Similarly, [signal validation_complete]'s payload is a plain
## [Dictionary] ([code]{"success": bool, "issues": Array}[/code]) rather than
## a typed [code]ValidationResult[/code] -- that class does not exist yet
## (rid-004/005); this shape is forward-compatible with the eventual typed
## contract.
##
## Scene/World Management Story 001 scope note (ADR-0001 ownership note +
## ADR-0013): this [code]GameWorld[/code] root IS the World Root
## [TR-scene-world-management-035]. [member valley_scene] / [method
## _attach_valley] add this story's scene-TOPOLOGY behavior on the SAME node
## the Foundation Spine's boot gate already lives on -- a separate concern
## from the gate. Scene handoff uses ONLY [method Node.add_child] -- never
## [code]change_scene_to_file[/code]/[code]change_scene_to_packed[/code]/
## [code]reload_current_scene[/code], and [member SceneTree.current_scene] is
## never assigned directly [TR-scene-world-management-037] -- this World Root
## node itself is never freed [TR-scene-world-management-038].
##
## Scene/World Management Story 002 scope note (ADR-0005 host relationship,
## AC17a/AC17b): [method _attach_valley] is no longer called unconditionally
## from [method _ready] -- it is now gated behind the boot gate's SUCCESS
## path only, invoked from [method _on_database_settled] at the start of
## WIRING, before the injected-tier [code]setup()[/code] sweep. On a
## Resource & Item Database `Failed` outcome, the Valley is never attached --
## no empty-palette Valley [TR-scene-world-management-004]. This is the
## scene-topology REACTION to the Foundation Spine's gate (story 002 of this
## epic); it does not re-implement the gate mechanism itself (that remains
## `foundation-spine` story 002 / [method _on_database_settled]).
##
## Scene/World Management Story 004 scope note (THE INTEGRATION CROWN,
## ADR-0001 primary): [method _gather_valley_tier_modules] is the GameWorld
## assembly seam this story adds, called from [method _on_database_settled]
## immediately after [method _attach_valley] returns, BEFORE the injected-tier
## sweep. [Valley]'s own hosted tier modules (Voxel World grid + mesher,
## Camera & Input, the four Building System modules, Villager AI -- see
## [Valley]'s own class doc comment) cannot be Inspector-wired directly onto
## this scene's [member injected_tier_modules] array, because [Valley] is
## instantiated from a [PackedScene] at RUNTIME ([method _attach_valley]), not
## present in `GameWorld.tscn`'s own saved node tree -- there is nothing for
## the Inspector to reference at edit time. This method closes that gap by
## reading [Valley]'s own reported module list ([method
## Valley.get_injected_tier_modules], duck-typed via [method
## Object.has_method] so the pre-existing DI/boot-gate-only test suites that
## predate this story -- which never wire a [Valley] exposing that method --
## remain unaffected) and appending it to the array [method
## _setup_injected_tier] already iterates. [method _setup_injected_tier]
## itself is UNCHANGED -- this remains the sole `setup()` call site (ADR-0005);
## this story only widens what feeds that array, never how it is consumed.
##
## Scene/World Management Story vox-018 scope note (ADR-0014 primary --
## the deferred live-wiring integration [VoxelWorldMeshStreamer]'s own class
## doc comment explicitly named as a LATER story's job; ADR-0005 secondary
## boot-timing): [method _build_initial_voxel_mesh_window] runs the hosted
## [VoxelWorldMeshStreamer]'s UNBOUNDED initial view-window mesh build
## exactly once, from [method _on_database_settled], AFTER
## [method _setup_injected_tier] returns and BEFORE [member _boot_state] ever
## reaches [constant BootState.ACTIVE] -- the same "before the first
## interactive frame" timing this class's boot gate already guarantees for
## every injected-tier `setup()` call, extended here to this ADDITIONAL,
## non-`setup()` initial-build call. **Honest note, not silently glossed
## over**: this codebase has no dedicated boot-time loading-overlay Control
## landed yet (TR-scene-world-management-032 is a signal/UI contract this
## class's own [signal transition_begun]/[signal transition_ended] surface
## anticipates, but no concrete full-screen presentation exists today --
## see this class's own Story 003 scope note above). Running the initial
## build during WIRING, strictly before ACTIVE, is the best available
## proxy for "behind the transition overlay, not on a visible frozen frame"
## until that dedicated overlay lands -- a later scene-world-management story
## wiring a real overlay Control to [signal boot_halted]'s sibling concern
## would slot in front of this same call site without changing it. This
## method itself calls no `setup()` (ADR-0005's sole `setup()` call site
## remains [method _setup_injected_tier], unchanged) -- [method
## VoxelWorldMeshStreamer.build_initial_window] is a distinct entry point.
##
## Scene/World Management Story 003 scope note (ADR-0001 contract surface +
## ADR-0013 Key Interfaces, which already anticipated this exact signal pair
## living on the World Root): [signal transition_begun] / [signal
## transition_ended] / [method get_transition_state] are the durable
## transition-signal CONTRACT SURFACE (GDD Core Rule 7's three-outcome
## contract, collapsed to two signals: begin, and end-with-a-[code]success[/code]
## bool covering both transition-complete and transition-abort). At MVP no
## real dungeon transition exists yet (VS-tier, ADR-0013) -- [method
## begin_transition]/[method end_transition] are the synthetic driver this
## story builds so the surface is testable in isolation today, and so VS-tier
## dungeon-entry/exit stories can slot into it later without changing the
## contract. Consumers (Camera & Input's Suspended entry/exit, Building
## System's undo-clear) bind via these signals ONLY -- this class makes no
## direct call into any consumer, by construction
## [TR-scene-world-management-049]. The double-trigger debounce (GDD Edge
## Cases, Logic/VS+) is deliberately NOT built here -- see [method
## begin_transition]'s doc comment.
class_name GameWorld
extends Node3D

## Boot-sequencing states (ADR-0005). Progresses
## WAITING_FOR_DATABASE -> WIRING -> ACTIVE on the database dependency's
## Ready outcome. HALTED (from WAITING_FOR_DATABASE, on Failed) is terminal
## -- there is no path out of it.
enum BootState { WAITING_FOR_DATABASE, WIRING, ACTIVE, HALTED }

## Emitted exactly once, only on the HALTED transition (database dependency
## reported Failed). Carries the reported validation issues through
## untouched. This story's contract ends at "the halt path fires and no
## setup() is ever called" (ADR-0005 Implementation Notes) -- the concrete
## full-screen presentation (reusing the transition-overlay UI
## infrastructure, TR-scene-world-management-032) is a later scene-world-
## management story's job; this signal is the hook it connects to.
signal boot_halted(issues: Array)

## Scene/World Management Story 003 contract surface (ADR-0001 + ADR-0013;
## GDD Core Rule 7). Fires exactly once per [method begin_transition] call.
## Reserved for REVERSIBLE presentation/suspension effects only (camera
## Suspended, UI hiding, overlay fade-in) -- consumers MUST NOT bind
## irreversible state changes here [TR-scene-world-management-043]. Carries
## no payload -- an opaque contract consumers bind to by effect class, never
## by transition identity.
signal transition_begun()

## Scene/World Management Story 003 contract surface (ADR-0001 + ADR-0013;
## GDD Core Rule 7). Fires exactly once per matching [signal
## transition_begun], covering the GDD's two end outcomes in one signal:
## transition-complete when [param success] is [code]true[/code]
## [TR-scene-world-management-044], transition-abort when [param success] is
## [code]false[/code] [TR-scene-world-management-045]. Either outcome MUST
## unwind every reversible begin-effect (camera exits Suspended, UI
## reappears) -- an abort must never strand a consumer in Suspended
## [TR-scene-world-management-048]. Carries no scene-specific payload beyond
## [param success].
signal transition_ended(success: bool)

## Scene/World Management Story 003 contract surface (ADR-0001 + ADR-0013).
## The three MVP-scoped states peers observe via [method
## get_transition_state] -- deliberately distinct from [enum BootState],
## which this class also owns for the unrelated boot-gate concern (ADR-0005).
## [constant Transitioning] is reachable today only via the synthetic [method
## begin_transition]/[method end_transition] driver -- no real dungeon
## transition exists yet (VS-tier).
enum TransitionState { Booting, Active, Transitioning }

## True while a transition is in progress -- between a [method
## begin_transition] call and its matching [method end_transition] call.
## Backs [method get_transition_state]'s [constant TransitionState.Transitioning]
## branch, and is the structural guard that makes the GDD's one-begin ->
## exactly-one-end invariant hold: [method end_transition] is a no-op once
## this is already [code]false[/code] [TR-scene-world-management-047].
var _transition_in_progress: bool = false

## Ordered list of injected-tier child modules whose [code]setup()[/code]
## this root invokes. Wired via the Inspector on [code]GameWorld.tscn[/code]
## -- the array holds direct node references (resolved at scene
## deserialization, before any child's [method _ready] runs), not
## [NodePath]s, so the full wiring list is visible and editable in one
## place. Order matters when one module's [code]setup()[/code] establishes
## signal connections another module's [code]setup()[/code] depends on;
## callers control that order via this array, not via scene-tree child order.
@export var injected_tier_modules: Array[Node] = []

## The Resource & Item Database boot-gate dependency (ADR-0005). See the
## class doc comment's Story 002 scope note for why this is a plain var, not
## [code]@export[/code]. Duck-typed against exactly two members: [code]
## is_ready() -> bool[/code] and [code]signal validation_complete(result:
## Dictionary)[/code]. Assign a mock double directly before this node enters
## the tree in headless tests; production leaves this null and [method
## _ready] resolves it against the real Autoload.
var resource_item_database: Object = null

## Current boot state (ADR-0005). Read-only from outside this class -- see
## [method get_boot_state].
var _boot_state: BootState = BootState.WAITING_FOR_DATABASE

## Scene/World Management Story 001 (ADR-0001 + ADR-0013): the Valley scene
## this World Root attaches as its child at boot
## [TR-scene-world-management-034] [TR-scene-world-management-035]. Wired via
## [code]GameWorld.tscn[/code]'s Inspector in production to [code]Valley.tscn[/code].
## Deliberately optional -- left null, [method _attach_valley] is a no-op, so
## the existing DI/boot-gate-only test suites (which predate this story and
## never set this field) continue to construct a bare [code]GameWorld[/code]
## and boot to [constant BootState.ACTIVE] unaffected.
@export var valley_scene: PackedScene = null

## Runtime instance of [member valley_scene], once [method _attach_valley]
## has run. Null until then, and null forever if [member valley_scene] was
## never wired. See [method get_valley].
var _valley: Node = null

## Story scene-005 (World genesis in the boot sequence) tuning config
## (ADR-0002) -- [member GameWorldConfig.genesis_wall_clock_ceiling_ms] bounds
## [method _run_world_genesis]'s residency-drive loop. Deliberately optional,
## like [member valley_scene]: this class predates having any config Resource
## at all, and dozens of pre-existing DI/boot-gate-only tests construct
## [code]GameWorld.new()[/code] directly without ever wiring this field -- see
## [method _run_world_genesis]'s own null-tolerant fallback (mirrors [method
## Valley.spawn_starting_roster]'s established "config-optional, in-code
## default fallback" precedent for exactly this situation).
@export var config: GameWorldConfig = null

## Fallback ceiling (milliseconds) used ONLY when [member config] is unwired
## -- the one place this literal is allowed to live, matching [member
## config]'s own doc comment. Equal to [member
## GameWorldConfig.genesis_wall_clock_ceiling_ms]'s own shipped `.tres`
## default so an unwired [GameWorld] behaves identically to the production-
## wired one.
const DEFAULT_GENESIS_WALL_CLOCK_CEILING_MS: float = 1000.0


func _ready() -> void:
	if resource_item_database == null:
		resource_item_database = get_node_or_null(^"/root/ResourceItemDatabase")
	assert(
		resource_item_database != null,
		"GameWorld requires a ResourceItemDatabase-shaped dependency (assign"
		+ " a mock in tests; the real Autoload is registered since rid-002) before"
		+ " the boot gate can run"
	)
	if config != null:
		for issue: String in config.validate():
			if not issue.begins_with(ConfigResource.BLOCKING_PREFIX):
				push_warning(issue)
	_boot_state = BootState.WAITING_FOR_DATABASE
	@warning_ignore("unsafe_method_access")
	var database_already_ready: bool = resource_item_database.is_ready()
	if database_already_ready:
		_on_database_settled(true, [])
	else:
		@warning_ignore("unsafe_property_access")
		resource_item_database.validation_complete.connect(
			func(result: Dictionary) -> void:
				_on_database_settled(bool(result["success"]), result["issues"] as Array),
			CONNECT_ONE_SHOT
		)


## Returns the current boot state (ADR-0005) -- the test/observability seam
## for the gate's progress.
func get_boot_state() -> BootState:
	return _boot_state


## Attaches [member valley_scene] as a child of this World Root
## (TR-scene-world-management-034/035/038). Uses ONLY plain [method
## Node.add_child] -- never [code]change_scene_to_file[/code]/
## [code]change_scene_to_packed[/code]/[code]reload_current_scene[/code],
## nor ever a direct [member SceneTree.current_scene] assignment (all
## forbidden, TR-scene-world-management-037) -- this World Root node itself
## is never replaced or freed by this call (TR-scene-world-management-038).
##
## Gated at story 002 (AC17a/AC17b, ADR-0005 host relationship): called
## exactly once, from [method _on_database_settled]'s SUCCESS path only, at
## the start of WIRING -- before the injected-tier [code]setup()[/code] sweep
## (Implementation Notes: attach the Valley, THEN sweep injected-tier
## [code]setup()[/code], so Building System / Villager AI initialize only
## after the Valley exists -- AC17a holds by construction). On a Resource &
## Item Database `Failed` outcome, [method _on_database_settled] returns
## before this method is ever called -- no empty-palette Valley is ever
## attached [TR-scene-world-management-004]. A null [member valley_scene]
## (the existing DI/boot-gate-substrate tests that predate this story) is a
## no-op, never an error.
func _attach_valley() -> void:
	if valley_scene == null:
		return
	_valley = valley_scene.instantiate()
	add_child(_valley)


## Returns the runtime Valley instance attached by [method _attach_valley],
## or null if none was ever attached (see that method's doc comment).
func get_valley() -> Node:
	return _valley


## Settles the boot gate on the database dependency's Ready/Failed outcome
## (ADR-0005 Decision §3). On failure: HALTED, [signal boot_halted] fires,
## [method _attach_valley] is NEVER called -- no empty-palette Valley
## (Scene/World Management story 002, AC17b) -- and NO injected-tier
## [code]setup()[/code] is ever called -- terminal. On success: WIRING, the
## Valley is attached FIRST (story 002 -- the scene-topology reaction to this
## gate), THEN every injected-tier module's [code]setup()[/code] runs (until/
## unless one halts on a BLOCKING config invariant -- ADR-0002, see [method
## _setup_injected_tier]), then ACTIVE -- unless that WIRING pass already
## settled HALTED, in which case ACTIVE is never reached either.
func _on_database_settled(success: bool, issues: Array) -> void:
	if not success:
		_boot_state = BootState.HALTED
		_show_boot_halt_screen(issues)
		return
	_boot_state = BootState.WIRING
	_attach_valley()
	_gather_valley_tier_modules()
	_setup_injected_tier()
	if _boot_state != BootState.HALTED:
		_run_world_genesis()
	if _boot_state != BootState.HALTED:
		_build_initial_voxel_mesh_window()
	if _boot_state != BootState.HALTED:
		_boot_state = BootState.ACTIVE


## The GameWorld assembly seam (Story scene-004) -- see class doc comment's
## Story 004 scope note. A no-op when no Valley was ever attached (a null
## [member valley_scene], the existing DI/boot-gate-only suites' precedent) or
## when the attached Valley does not expose [method
## Valley.get_injected_tier_modules] (any hand-constructed test Valley stand-in
## that predates this story) -- either way, [member injected_tier_modules]
## is left exactly as scene-file/test wiring set it, unaffected.
func _gather_valley_tier_modules() -> void:
	if _valley == null:
		return
	if not _valley.has_method(&"get_injected_tier_modules"):
		return
	@warning_ignore("unsafe_method_access")
	var valley_modules: Array[Node] = _valley.get_injected_tier_modules()
	injected_tier_modules.append_array(valley_modules)


## Story vox-018 (see class doc comment's own scope note above for the full
## timing rationale). Runs the hosted [VoxelWorldMeshStreamer]'s UNBOUNDED
## initial view-window build exactly once, using the hosted [CameraInput]'s
## CURRENT orbit target as the initial focus cell (the SAME
## [method CameraInput.get_target] -> [method VoxelWorldGrid.world_to_cell]
## conversion [Valley]'s own [method Valley._process] uses every subsequent
## frame -- see that method's doc comment) -- so the very first frame this
## streamer's budgeted per-frame path takes over, the window it maintains is
## already centered on exactly where the boot-time build left it, never a
## mismatched center. A no-op when no Valley was ever attached, or the
## attached Valley does not expose
## [method Valley.get_voxel_world_mesh_streamer]/[method Valley.get_camera_input]
## (duck-typed via [method Object.has_method], mirroring [method
## _gather_valley_tier_modules]'s own guard) -- every pre-existing DI/
## boot-gate-only test Valley stand-in that predates this story remains
## unaffected.
func _build_initial_voxel_mesh_window() -> void:
	if _valley == null:
		return
	if not _valley.has_method(&"get_voxel_world_mesh_streamer"):
		return
	@warning_ignore("unsafe_method_access")
	var streamer: Object = _valley.get_voxel_world_mesh_streamer()
	if streamer == null:
		return
	var focus_cell: Vector3i = Vector3i.ZERO
	if _valley.has_method(&"get_camera_input"):
		@warning_ignore("unsafe_method_access")
		var camera_input: Object = _valley.get_camera_input()
		if camera_input != null and camera_input.has_method(&"get_target"):
			@warning_ignore("unsafe_method_access")
			var target: Vector3 = camera_input.get_target()
			focus_cell = VoxelWorldGrid.world_to_cell(target)
	@warning_ignore("unsafe_method_access")
	streamer.build_initial_window(focus_cell)


## Story scene-005 (World genesis in the boot sequence -- ADR-0005 primary,
## the one call site the story adds; ADR-0015 primary for the residency
## shape; ADR-0014 secondary for the mesh-window ordering it now precedes;
## ADR-0001 secondary). Runs during WIRING, strictly AFTER [method
## _setup_injected_tier] returns and STRICTLY BEFORE [method
## _build_initial_voxel_mesh_window] -- the one new phase this story inserts
## into [method _on_database_settled]'s existing sequence, called from that
## SAME sole orchestration site, never a second one. Duck-typed against the
## Valley exactly like [method _gather_valley_tier_modules]/[method
## _build_initial_voxel_mesh_window] (guards with [code]_valley == null[/code]
## and [method Object.has_method]), so every pre-existing DI/boot-gate-only
## test Valley stand-in that predates this story -- which never wires a
## Valley exposing these methods -- remains completely unaffected: this
## method is a no-op for every one of them, exactly as the two existing
## seams already are.
##
## Order inside genesis is load-bearing (the story's own Implementation
## Notes): the camera's start-focus target is established FIRST (so [method
## _build_initial_voxel_mesh_window] -- unchanged by this story, still reads
## the camera's CURRENT target -- automatically centers the initial mesh
## window on the SAME cell genesis anchors everything else on,
## AC-ONE-START-FOCUS), THEN the boot-window residency drive (terrain
## resident), THEN the grid's GENERATED lifecycle marker, THEN the nav graph
## build, THEN Story scene-006's default-villager need seeding (needs no
## terrain -- placed here, right before the roster spawn it reads
## naturally alongside), THEN the roster spawn (which now ALSO seeds each
## new villager it creates, inline) -- the nav graph's predicate walk and
## the roster's standable-cell search both read the grid and are silently
## empty if run before real terrain is resident.
func _run_world_genesis() -> void:
	if _valley == null:
		return
	if not _valley.has_method(&"get_voxel_world"):
		return
	@warning_ignore("unsafe_method_access")
	var voxel_world: Object = _valley.get_voxel_world()
	if voxel_world == null:
		return
	@warning_ignore("unsafe_property_access")
	var voxel_world_config: Object = voxel_world.config
	if voxel_world_config == null:
		return

	var start_focus: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world_config)

	if _valley.has_method(&"get_camera_input"):
		@warning_ignore("unsafe_method_access")
		var camera_input: Object = _valley.get_camera_input()
		if camera_input != null and camera_input.has_method(&"set_target"):
			@warning_ignore("unsafe_method_access")
			camera_input.set_target(VoxelWorldGrid.cell_to_world(start_focus))

	var ceiling_ms: float = DEFAULT_GENESIS_WALL_CLOCK_CEILING_MS
	if config != null:
		ceiling_ms = config.genesis_wall_clock_ceiling_ms
	_drive_boot_residency(voxel_world, start_focus, ceiling_ms)

	if voxel_world.has_method(&"mark_generated"):
		@warning_ignore("unsafe_method_access")
		voxel_world.mark_generated()

	if _valley.has_method(&"build_villager_nav_graph"):
		@warning_ignore("unsafe_method_access")
		_valley.build_villager_nav_graph(start_focus)

	# Story villager-ai-025 -- connects ScaffoldErectionCoordinator's own
	# villager-descent trigger to the real clock, deferred to here for the
	# SAME reason build_villager_nav_graph is: ConstructionTickLoop.setup()
	# (called by _setup_injected_tier(), above this method in
	# _on_database_settled) has only just resolved time_tick_system by now.
	if _valley.has_method(&"connect_scaffold_erection_descent_trigger"):
		@warning_ignore("unsafe_method_access")
		_valley.connect_scaffold_erection_descent_trigger()

	# Story scene-006 (AC-SEED-NOT-FROM-READY, AC-SEED-AFTER-SETUP): the
	# always-present default villager's need seeding -- deliberately NOT
	# reachable from Valley._ready()/_wire_villager_population(), reached
	# ONLY from here, strictly after _setup_injected_tier()'s own setup()
	# sweep (above this method in _on_database_settled) has already run.
	if _valley.has_method(&"seed_default_villager_needs"):
		@warning_ignore("unsafe_method_access")
		_valley.seed_default_villager_needs()

	if _valley.has_method(&"spawn_starting_roster"):
		@warning_ignore("unsafe_method_access")
		_valley.spawn_starting_roster()


## Genesis's own bounded residency-drive loop (Implementation Notes:
## "Alternate update_residency() with drain_pending_async_reads() until
## is_chunk_resident() holds for the desired set or the config-driven
## wall-clock ceiling elapses -- bounded, never a spin"). Driven exclusively
## through [method VoxelWorldGrid.update_residency] and [method
## VoxelWorldGrid.drain_pending_async_reads] -- never [method
## VoxelWorldGrid.wait_for_async_residency_idle], whose own doc comment names
## it the wrong primitive for a side-channel dispatch; this loop drives
## residency itself; it is not a side channel. [param ceiling_ms] itself
## bounds the REMAINING budget passed into each nested [method
## VoxelWorldGrid.drain_pending_async_reads] call too, so one slow settle can
## never silently consume more than what is left of the ceiling on its own.
##
## Termination is a TWO-PART fixed point, not a bare "zero in flight" check:
## [member VoxelWorldConfig.max_concurrent_async_tasks] caps how many NEW
## chunks a SINGLE [method VoxelWorldGrid.update_residency] call can dispatch
## (Story vox-011/ADR-0015 §6) -- a boot window desiring more chunks than that
## cap genuinely needs SEVERAL rounds, each dispatching another capped batch,
## to become fully resident. Stopping the instant one round's dispatched
## batch drains to zero in-flight (without re-checking for a NEXT round) would
## silently leave every chunk beyond the first cap's worth of dispatches
## never even requested -- so this loop additionally tracks [method
## VoxelWorldGrid.get_resident_chunk_keys]'s size across rounds and only
## terminates once BOTH nothing remains in flight AND a round produced no
## resident-count growth over the previous one (the window's own focus never
## moves during genesis, so resident count is monotonically non-decreasing
## until it plateaus at the full desired-window size -- growth stopping is
## therefore a correct convergence signal, not merely "this round's batch
## settled"). [param ceiling_ms] still bounds the loop overall -- never an
## unbounded spin.
func _drive_boot_residency(voxel_world: Object, start_focus: Vector3i, ceiling_ms: float) -> void:
	var start_usec: int = Time.get_ticks_usec()
	var ceiling_usec: int = int(ceiling_ms * 1000.0)
	var previous_resident_count: int = -1
	while true:
		@warning_ignore("unsafe_method_access")
		voxel_world.update_residency(start_focus, start_focus)
		var elapsed_usec: int = Time.get_ticks_usec() - start_usec
		if elapsed_usec >= ceiling_usec:
			_warn_genesis_ceiling_hit(ceiling_ms)
			return
		var remaining_msec: int = maxi(1, int(float(ceiling_usec - elapsed_usec) / 1000.0))
		@warning_ignore("unsafe_method_access")
		voxel_world.drain_pending_async_reads(remaining_msec)
		@warning_ignore("unsafe_method_access")
		var in_flight_count: int = voxel_world.get_in_flight_async_task_count()
		@warning_ignore("unsafe_method_access")
		var resident_count: int = voxel_world.get_resident_chunk_keys().size()
		if in_flight_count == 0 and resident_count == previous_resident_count:
			return
		previous_resident_count = resident_count
		if (Time.get_ticks_usec() - start_usec) >= ceiling_usec:
			_warn_genesis_ceiling_hit(ceiling_ms)
			return


## Logs the deterministic, bounded termination of [method
## _drive_boot_residency] when its wall-clock ceiling is hit before every
## boot-window chunk settled -- a documented, non-crashing outcome (Control
## Manifest: "the boot loop is bounded -- a wall-clock ceiling and a
## deterministic outcome when it is hit -- never an unbounded spin"), not a
## silently-swallowed failure.
func _warn_genesis_ceiling_hit(ceiling_ms: float) -> void:
	push_warning(
		(
			"GameWorld._run_world_genesis: boot residency drive hit its %sms wall-clock" +
			" ceiling before every boot-window chunk settled -- terminating deterministically," +
			" not spinning further"
		) % [ceiling_ms]
	)


## Calls [code]setup()[/code] on every wired injected-tier module, in array
## order. This is the ONLY sanctioned call site for injected-tier
## [code]setup()[/code] invocation (ADR-0005) -- no module may call its own
## [code]setup()[/code] from its own [method _ready]. Only ever reached from
## [method _on_database_settled]'s success path.
##
## Story 003 addition (ADR-0002): immediately after each module's
## [code]setup()[/code], duck-types an optional
## [code]get_boot_blocking_issues() -> Array[String][/code] getter. A
## non-empty result -- a GDD-declared BLOCKING config invariant failure --
## reuses the exact same terminal halt path as a RID Failed outcome and
## stops calling further modules' [code]setup()[/code] (terminal, no
## recovery, matching ADR-0005's existing halt semantics).
func _setup_injected_tier() -> void:
	for module: Node in injected_tier_modules:
		assert(
			module.has_method(&"setup"),
			"GameWorld.injected_tier_modules contains a module without setup(): %s" % module.name
		)
		module.setup()
		if module.has_method(&"get_boot_blocking_issues"):
			@warning_ignore("unsafe_method_access")
			var blocking_issues: Array[String] = module.get_boot_blocking_issues()
			if not blocking_issues.is_empty():
				_boot_state = BootState.HALTED
				_show_boot_halt_screen(blocking_issues)
				return


## Fires [signal boot_halted] with the reported validation issues. The
## concrete full-screen presentation is scene-world-management's own story
## to build (see class doc comment) -- this story's responsibility ends at
## firing the hook and guaranteeing no [code]setup()[/code] call happened.
func _show_boot_halt_screen(issues: Array) -> void:
	boot_halted.emit(issues)


## Scene/World Management Story 003 (ADR-0001 contract surface). Returns the
## current transition state so peers can observe a stable post-boot state
## without inspecting [enum BootState] directly:
## [constant TransitionState.Transitioning] while a transition is in
## progress (see [member _transition_in_progress]); otherwise [constant
## TransitionState.Active] once the boot gate has resolved to [constant
## BootState.ACTIVE]; [constant TransitionState.Booting] at any earlier boot
## state -- including [constant BootState.HALTED], which this story does not
## need to distinguish (story 002 owns the HALT contract via [signal
## boot_halted]).
func get_transition_state() -> TransitionState:
	if _transition_in_progress:
		return TransitionState.Transitioning
	if _boot_state == BootState.ACTIVE:
		return TransitionState.Active
	return TransitionState.Booting


## Scene/World Management Story 003 (ADR-0001 contract surface, synthetic
## MVP driver -- see class doc comment). Begins a transition: fires [signal
## transition_begun] exactly once and marks [method get_transition_state] as
## [constant TransitionState.Transitioning] until the matching [method
## end_transition] call resolves it.
##
## The GDD's double-trigger debounce (Edge Cases, re-tiered Logic/VS+) is
## deliberately NOT built here -- this story only guarantees the one-begin ->
## exactly-one-end invariant (below), not the "ignore a second trigger while
## one is in progress" policy, which is a later VS-tier story's job to layer
## in front of this call. Calling this while a transition is already in
## progress is therefore a caller-contract violation today, asserted
## against rather than silently ignored.
func begin_transition() -> void:
	assert(
		not _transition_in_progress,
		"GameWorld.begin_transition() called while a transition is already in progress"
		+ " -- the double-trigger debounce is VS-tier scope, not built yet (story 003)"
	)
	_transition_in_progress = true
	transition_begun.emit()


## Scene/World Management Story 003 (ADR-0001 contract surface, synthetic
## MVP driver). Resolves the in-progress transition: fires [signal
## transition_ended] with [param success] exactly once per [method
## begin_transition] call [TR-scene-world-management-047]. A call made while
## no transition is in progress -- including a SECOND call after the first
## already resolved it -- is a structural no-op: it does NOT emit [signal
## transition_ended] again. This is the enforcement mechanism for the GDD's
## one-begin -> exactly-one-end invariant (Core Rule 7).
func end_transition(success: bool) -> void:
	if not _transition_in_progress:
		return
	_transition_in_progress = false
	transition_ended.emit(success)
