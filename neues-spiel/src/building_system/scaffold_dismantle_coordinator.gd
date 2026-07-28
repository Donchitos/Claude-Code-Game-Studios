## Scaffold dismantle LIVE orchestrator (story `building-034`, second pass --
## wiring the landed [ScaffoldDismantlePlanner] into the running game). This
## is the class that was still missing after commit `6cc9002`: that pass
## landed the planner's pure ORDERING/safety rules (D10/D4, SC-INV-1) but
## nothing in `src/` ever called them from a real game event. This class is
## that caller.
##
## **Two triggers (this story's own scope, both wired by [Valley])**:
## 1. A `BUILD`-kind [BuildProject] reaching [constant
##    BuildProject.ProjectState.DONE] -- detected here, not upstream: nothing
##    in `src/` calls [method BuildProject.recompute_state] after
##    [ConstructionTickLoop] flips a cell to `BUILT` (that class mutates
##    [member BlueprintCell.state] directly, bypassing [BuildProject]'s own
##    mutator methods, which are the only place [method
##    BuildProject.recompute_state] was previously invoked from). This class
##    closes that gap for every completing CONSTRUCTION cell, as a pure side
##    effect of listening for the scaffold-relevant DONE transition (never a
##    behavior change for a non-`BUILD`/non-`SCAFFOLD`-owning project).
## 2. [signal RemovalTool.project_canceled] for a `BUILD`-kind project (D4).
##
## **D10 (top-down, worker-first) / SC-INV-1**: every dismantle step is
## computed by [method ScaffoldDismantlePlanner.next_top_down_demolition_cell],
## which already refuses to name a cell whose body-column ANY hosted
## villager currently occupies. This class never removes a cell itself --
## it only asks the planner for the next SAFE cell and, when one exists,
## routes it through [ConstructionTickLoop]'s own REAL, tick-paced demolition
## job machinery ([method ConstructionTickLoop.create_demolition_order] +
## [method ConstructionTickLoop.claim_demolition_job]) -- the SAME mechanism
## and the SAME `base_demolition_ticks_scaffold` config cost erection's own
## sibling job already pays, never an instant removal.
##
## **Honest, named scope boundary**: no production [VillagerAi] decision path
## claims ANY demolition job today (grep-verified: [method
## ConstructionTickLoop.claim_demolition_job] has zero callers anywhere in
## `src/` before this class) -- Building System's demolition-job QUEUE
## mechanics (`building-009`/`building-017`) were never wired to Villager
## AI's own execution loop, a pre-existing gap outside this story's scope
## (this story is "wire scaffolding into the game," not "give villagers a
## demolition decision-making AI"). This coordinator claims each dismantle
## step on the STRUCTURE's own behalf via [constant SYSTEM_WORKER_ID] --
## never a real villager id, never a fabricated claim on a villager that
## never asked for the job -- so AC3's "the worker rides it down" is
## satisfied through nav-graph connectivity (the standing villager's OWN
## ordinary movement, once a step down is legal) while the actual cell
## REMOVAL keeps paying the same real, config-driven tick cost every other
## job on this loop pays.
##
## **Re-poll cadence**: subscribes directly to the SAME real
## `TimeTickSystem.tick` broadcast [ConstructionTickLoop] itself binds to
## (passed in by [Valley], mirroring that class's own [member
## ConstructionTickLoop.time_tick_system] resolution) -- a villager may step
## off the current top cell on any tick, off the back of its own ordinary
## travel decision, and this class must notice promptly rather than only on
## the next unrelated construction/demolition completion.
class_name ScaffoldDismantleCoordinator
extends RefCounted

## Attribution id used for every dismantle-step claim this class makes
## (never a real, hosted villager id -- see class doc comment's own scope
## boundary paragraph).
const SYSTEM_WORKER_ID: int = -999

var _build_project_registry: BuildProjectRegistry
var _construction_tick_loop: ConstructionTickLoop
var _scaffold_registry: Object
var _roster_provider: Object

## Owner (`BUILD`-kind) project ids currently being drained top-down --
## latched so a repeated DONE/cancel signal for the SAME owner never starts
## a second, redundant drain.
var _dismantling_owner_ids: Dictionary[int, bool] = {}

## Owners whose served project is DONE but whose scaffolding is still somebody's
## way down (SC-INV-2). Re-polled every tick until the structure is free.
var _deferred_owner_ids: Dictionary[int, bool] = {}

## Scaffold cells this coordinator has already claimed a demolition step
## for -- guards against re-claiming the SAME cell on every subsequent tick
## while its job is still in flight (mirrors [ScaffoldErectionCoordinator]'s
## own [member ScaffoldErectionCoordinator._served_cells] latch shape).
var _claimed_cells: Dictionary[Vector3i, bool] = {}


func _init(
	build_project_registry: BuildProjectRegistry,
	construction_tick_loop: ConstructionTickLoop,
	scaffold_registry: Object,
	roster_provider: Object,
	time_tick_system: Object,
) -> void:
	assert(build_project_registry != null, "ScaffoldDismantleCoordinator requires build_project_registry")
	assert(construction_tick_loop != null, "ScaffoldDismantleCoordinator requires construction_tick_loop")
	_build_project_registry = build_project_registry
	_construction_tick_loop = construction_tick_loop
	_scaffold_registry = scaffold_registry
	_roster_provider = roster_provider
	_construction_tick_loop.construction_completed.connect(_on_construction_completed)
	_construction_tick_loop.demolition_completed.connect(_on_demolition_completed)
	connect_tick(time_tick_system)


## Connects the per-tick re-poll, separately from construction.
##
## THIS EXISTS BECAUSE THE CONSTRUCTOR-TIME VERSION SILENTLY DID NOTHING.
## Valley builds this coordinator during _wire_build_project_lifecycle, and at
## that moment ConstructionTickLoop has not run its own setup yet — so its
## `time_tick_system` is still null, the connection was skipped, and the tick
## re-poll never happened in the shipped game. Caught by a diagnostic print
## reading `dismantle_connected=false` on a real boot; no test covered it,
## because the SC-INV-2 test asserts the DEFERRAL DECISION and the two
## construction/cancel signals, never the tick that retries a deferred owner.
## The consequence was precise and invisible: a dismantle deferred because a
## builder was still up there would never have been retried at all.
##
## Safe to call more than once and safe to call with null — it simply does
## nothing until a real clock is passed.
func connect_tick(time_tick_system: Object) -> void:
	if time_tick_system == null:
		return
	@warning_ignore("unsafe_property_access")
	if not time_tick_system.tick.is_connected(_on_tick):
		@warning_ignore("unsafe_property_access")
		time_tick_system.tick.connect(_on_tick)


## Trigger 1 (AC3) -- see class doc comment point 1. Fires on EVERY
## completed CONSTRUCTION cell, from ANY project (never scaffold-only), so
## it also incidentally keeps every project's own [member BuildProject.state]
## roll-up current -- a pre-existing gap this class closes as a side effect,
## never a new rule of its own (recompute_state's own logic is completely
## unchanged).
func _on_construction_completed(cells: Array[Vector3i]) -> void:
	var visited_owner_ids: Dictionary[int, bool] = {}
	for cell: Vector3i in cells:
		var owner_id: int = _build_project_registry.project_at_cell(cell)
		if owner_id == -1 or visited_owner_ids.has(owner_id):
			continue
		visited_owner_ids[owner_id] = true
		var project: BuildProject = _build_project_registry.get_project(owner_id)
		if project == null:
			continue
		project.recompute_state()
		if project.kind == BuildProject.Kind.BUILD and project.state == BuildProject.ProjectState.DONE:
			_start_top_down_dismantle(owner_id)


## Trigger 2 (D4) -- [signal RemovalTool.project_canceled] handler, wired by
## [Valley]. Only ever acts for a `BUILD`-kind [param kind] (Out of Scope:
## "Build projects only") -- a canceled `SCAFFOLD`/`DIG` project is never
## this class's concern.
func on_project_canceled(owner_project_id: int, kind: BuildProject.Kind) -> void:
	if kind != BuildProject.Kind.BUILD:
		return
	var scaffold_projects: Array[BuildProject] = _scaffold_projects_for_owner(owner_project_id)
	if scaffold_projects.is_empty():
		return
	var all_cells: Array[Vector3i] = []
	for project: BuildProject in scaffold_projects:
		for blueprint_cell: BlueprintCell in project.get_cells():
			all_cells.append(blueprint_cell.cell)
	var occupied: Array = _occupied_body_columns()
	if ScaffoldDismantlePlanner.can_collapse_bottom_up(all_cells, occupied):
		_collapse_bottom_up_no_worker(scaffold_projects)
	else:
		_start_top_down_dismantle(owner_project_id)


## D4 Option (i)'s "unoccupied" branch -- Ruling 3's fast, Minecraft-style
## collapse: nobody is standing on any cell of the structure (already
## verified by the caller), so every cell is removed directly and
## immediately, never queued as a worker-executed job (there is no worker to
## protect and nothing SC-INV-1 needs to gate here).
func _collapse_bottom_up_no_worker(scaffold_projects: Array[BuildProject]) -> void:
	for project: BuildProject in scaffold_projects:
		for blueprint_cell: BlueprintCell in project.get_cells().duplicate():
			if blueprint_cell.state == BlueprintCell.MicroState.BUILT:
				if _scaffold_registry != null:
					@warning_ignore("unsafe_method_access")
					_scaffold_registry.remove(blueprint_cell.cell)
				project.demolish_cell(blueprint_cell.cell)
			else:
				project.cancel_cell(blueprint_cell.cell)
			_claimed_cells.erase(blueprint_cell.cell)
		if project.is_empty():
			_build_project_registry.remove_project(project)
	_dismantling_owner_ids.erase(_owner_id_of(scaffold_projects))


func _owner_id_of(scaffold_projects: Array[BuildProject]) -> int:
	if scaffold_projects.is_empty():
		return -1
	return scaffold_projects[0].owner_project_id


func _start_top_down_dismantle(owner_project_id: int) -> void:
	if _dismantling_owner_ids.has(owner_project_id):
		return
	if _someone_is_still_up_there(owner_project_id):
		# NOT an error, and NOT a reason to give up: the served project is done
		# but a villager is still standing at or above the structure, so the
		# scaffolding is still its way down. Park it as DEFERRED and let the
		# tick re-poll — without this the owner would simply never be revisited,
		# since the construction-completed trigger has already fired for good.
		_deferred_owner_ids[owner_project_id] = true
		return
	_deferred_owner_ids.erase(owner_project_id)
	_dismantling_owner_ids[owner_project_id] = true
	_advance(owner_project_id)


## SC-INV-2, the escape-route rule — the correction the first cut missed.
##
## SC-INV-1 protects the cell a villager STANDS IN. That is not enough: a
## builder that climbed a scaffold to lay the top course is standing on the
## structure's TOP, and removing anything below it takes away its descent even
## though its own cell is untouched.
##
## Measured, not theorised. The first payoff-demo run with scaffolding wired
## built 30/30 wall cells — the first time that had ever happened — and then
## stalled: the roof reached only 10/12 and the villager slept five times at
## y=10, above the walls (6..8) and above the roof plane (9). The wall project
## reaches DONE while the ROOF project is still a separate, unfinished project,
## so dismantle fired with the builder still up top.
##
## The rule this restores is the user's own: scaffolding exists while it is
## NEEDED. "The project I served is done" is not "nobody needs this any more" —
## exactly the same over-eagerness the erection side had before its persistence
## gate.
func _someone_is_still_up_there(owner_project_id: int) -> bool:
	var scaffold_projects: Array[BuildProject] = _scaffold_projects_for_owner(owner_project_id)
	if scaffold_projects.is_empty():
		return false

	var footprint: Dictionary[Vector2i, int] = {}
	for project: BuildProject in scaffold_projects:
		for cell: Vector3i in project.cells:
			var ground := Vector2i(cell.x, cell.z)
			var lowest: int = footprint.get(ground, cell.y)
			footprint[ground] = mini(lowest, cell.y)
	if footprint.is_empty():
		return false

	for column: Array in _occupied_body_columns():
		for occupied: Vector3i in column:
			var ground := Vector2i(occupied.x, occupied.z)
			if not footprint.has(ground):
				continue
			# At or above the structure's own base in this column: the villager
			# either stands on the scaffolding or on something it reached by
			# way of it. Either way it still needs the descent.
			if occupied.y >= footprint[ground]:
				return true
	return false


## [signal TimeTickSystem.tick] handler -- re-polls every currently-draining
## structure so a villager stepping off the current top cell (its own
## ordinary movement decision, on any tick) is noticed promptly. See class
## doc comment's own "Re-poll cadence" paragraph.
func _on_tick() -> void:
	# Retry the deferred ones FIRST — a villager that has just climbed down
	# should not have to wait an extra tick for its scaffolding to start
	# coming apart.
	for owner_id: int in _deferred_owner_ids.keys():
		_start_top_down_dismantle(owner_id)
	for owner_id: int in _dismantling_owner_ids.keys():
		_advance(owner_id)
	_cleanup_finished()


## [signal ConstructionTickLoop.demolition_completed] handler -- clears this
## coordinator's own per-cell claim latch and immediately tries to advance
## every in-progress drain one more step (never waits for the next tick when
## a step just finished).
func _on_demolition_completed(cells: Array[Vector3i]) -> void:
	for cell: Vector3i in cells:
		_claimed_cells.erase(cell)
	for owner_id: int in _dismantling_owner_ids.keys():
		_advance(owner_id)
	_cleanup_finished()


## D10 + SC-INV-1 -- advances EVERY scaffold structure owned by [param
## owner_project_id] by at most one safe cell each (never more than one
## in-flight claim per structure at a time -- [member _claimed_cells] is the
## guard).
func _advance(owner_project_id: int) -> void:
	for project: BuildProject in _scaffold_projects_for_owner(owner_project_id):
		_advance_one(project)


func _advance_one(scaffold_project: BuildProject) -> void:
	var built_cells: Array[Vector3i] = []
	for blueprint_cell: BlueprintCell in scaffold_project.get_cells():
		if blueprint_cell.state == BlueprintCell.MicroState.BUILT and not blueprint_cell.is_demolition_queued:
			built_cells.append(blueprint_cell.cell)
	if built_cells.is_empty():
		return
	var occupied: Array = _occupied_body_columns()
	var next_cell: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(built_cells, occupied)
	if next_cell == ScaffoldDismantlePlanner.NO_CELL or _claimed_cells.has(next_cell):
		return
	var blueprint_cell: BlueprintCell = scaffold_project.cells.get(next_cell)
	if blueprint_cell == null:
		return
	if _construction_tick_loop.create_demolition_order(blueprint_cell):
		_construction_tick_loop.claim_demolition_job(blueprint_cell, SYSTEM_WORKER_ID)
		_claimed_cells[next_cell] = true


## Drops the latch for any owner whose ENTIRE linked scaffold structure has
## fully emptied (AC3: "both paths terminate with zero scaffold cells
## remaining") -- also drops the now-empty [BuildProject]s from the registry,
## mirroring [RemovalTool]'s own established empty-project cleanup.
func _cleanup_finished() -> void:
	for owner_id: int in _dismantling_owner_ids.keys().duplicate():
		var projects: Array[BuildProject] = _scaffold_projects_for_owner(owner_id)
		var all_empty: bool = true
		for project: BuildProject in projects:
			if not project.cells.is_empty():
				all_empty = false
				break
		if not all_empty:
			continue
		for project: BuildProject in projects:
			_build_project_registry.remove_project(project)
		_dismantling_owner_ids.erase(owner_id)


func _scaffold_projects_for_owner(owner_project_id: int) -> Array[BuildProject]:
	var result: Array[BuildProject] = []
	for project: BuildProject in _build_project_registry.get_projects():
		if project.kind == BuildProject.Kind.SCAFFOLD and project.owner_project_id == owner_project_id:
			result.append(project)
	return result


## Every hosted villager's full body-column (SC-INV-1) -- read fresh on
## every call, never cached (a villager's own `current_cell` changes purely
## through its own ordinary movement, which this class never drives).
func _occupied_body_columns() -> Array:
	var result: Array = []
	if _roster_provider == null:
		return result
	@warning_ignore("unsafe_method_access")
	var villagers: Array = _roster_provider.get_villagers()
	for villager: VillagerAi in villagers:
		result.append(VillagerWalkabilityRules.body_column(villager.get_current_cell()))
	return result


## Read-only observability for tests -- whether [param owner_project_id]
## currently has an in-progress top-down drain latched.
func is_dismantling(owner_project_id: int) -> bool:
	return _dismantling_owner_ids.has(owner_project_id)
