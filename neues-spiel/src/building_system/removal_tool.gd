## Building System's removal tool -- the player-facing direct-removal entry
## point over a single target cell (GDD Core Rule 16, ADR-0016 primary;
## [TR-building-system-063]/[TR-building-system-123]). Story building-015
## (Draft eraser / removal branch, the third link of the demolition chain
## 009 -> 012 -> 015 -> 017).
##
## **Why this file also carries building-031's own scope** (flagged
## explicitly, not silently absorbed): building-031 ("Removal-tool base --
## Planned -> Canceled + job revoke") is scheduled the SAME sprint but is
## NOT a dependency of this story -- its own header lists only Story 002/009/
## 012 (the consuming story's header is authoritative, this project's
## established S09/S10 precedent for resolving a stale cross-reference). With
## no base file to extend, this class implements the FULL three-way
## micro-state branch in one place: 031's own Planned -> Canceled + job-revoke
## scope (AC41) IS the not-yet-Built half of this class's own [method
## remove_cell], and this story's Built -> demolition-order extension (AC13/
## 13b/AC65/AC73/AC74) is the other half. A future `/dev-story` pass on
## building-031 should find its own acceptance criteria already satisfied
## here, not reimplement a second base.
##
## **Terminology note** (Sprint 11 QA plan flag): building-031's AC41 calls
## the not-yet-Built target state "Planned"; this story's AC73/AC74 call the
## SAME [enum BlueprintCell.MicroState.PLANNED] value "Draft" (unreleased
## project) or "Queued" (released, not yet claimed) -- one underlying per-cell
## state, distinguished only by the OWNING PROJECT's own release state (Rule
## 16; [BlueprintCell]'s own doc comment; the GDD's "Blueprint cell lifecycle"
## table note: "Planned (= Draft)"). This class's own cancel path does not
## need to (and does not) distinguish Draft from Queued/UnderConstruction at
## all -- both use the identical `PLANNED -> CANCELED` /
## `UNDER_CONSTRUCTION -> (revoke) -> CANCELED` path.
##
## [method remove_cell] is a three-way branch on [param cell]'s own currently-
## tracked [BlueprintCell.state] (Rule 16, AC73/AC74, AC13/13b/AC65):
##
## 1. **Draft or Queued/UnderConstruction** (still [constant
##    BlueprintCell.MicroState.PLANNED] or [constant
##    BlueprintCell.MicroState.UNDER_CONSTRUCTION]): instant, free cancel --
##    no job is ever created and no notification of any kind is emitted
##    (AC73 -- this class defines no signal of its own, and cancels through
##    exactly the same silent path [PlanOnlyUndoGate]'s own "Cancel side"
##    already established for undo). An active claim (UNDER_CONSTRUCTION) is
##    revoked gracefully FIRST -- [method _revoke_active_job] mirrors
##    [PlanOnlyUndoGate._revoke_active_job] exactly: prefers [member
##    _job_queue]'s own [method ConstructionJobQueue.release_claim] (keeps
##    that queue's claim bookkeeping AND [member _tick_loop]'s active-job
##    state in sync in one call), falling back to [member _tick_loop]'s own
##    [method ConstructionTickLoop.release_job] only when no queue-recorded
##    claim attribution exists. [method BuildProject.cancel_cell] performs
##    the actual per-cell transition (PLANNED/UNDER_CONSTRUCTION -> CANCELED,
##    removed from [member BuildProject.cells]); this class then keeps
##    [member _registry] (and, if wired, [member _job_queue]) consistent --
##    [method BuildProjectRegistry.unregister_cell] frees the reverse-index
##    entry, and an emptied project ([method BuildProject.is_empty]) is
##    dropped from both entirely (Rule 14i/AC61's "the project entity itself
##    is deleted" -- the SAME registry-aware cleanup [PlanOnlyUndoGate]
##    already performs for the undo path, mirrored here verbatim for the
##    direct-removal path). A floor-excavation cell's `restore_value` needs no
##    special handling here: the raw grid was never touched for a not-yet-
##    Built cell in the first place ([PlanOnlyUndoGate]'s own documented
##    invariant -- "a not-yet-Built cell's terrain was never actually touched
##    in the grid, so there is nothing to write back on cancel") -- the
##    terrain simply stays exactly as it always was, which IS the correct
##    "restored" outcome for a cell that was never actually replaced.
## 2. **Built**: delegates entirely to [method
##    ConstructionTickLoop.create_demolition_order] (Story building-009,
##    widened to also accept FURNITURE by Story building-017) -- a
##    demolition order is created, already released/job-eligible; [param
##    cell]'s own [member BlueprintCell.state] and [member BuildProject.cells]
##    membership are left COMPLETELY untouched (AC65: "not removed
##    instantly"). This class never itself clears a Built cell and never
##    calls [method VoxelWorldGrid.set_cell]/[method VoxelWorldGrid.bulk_write]/
##    [method VoxelWorldGrid.clear_cell] anywhere in its own code (grep-guard,
##    mirrors every other Building System module's "the write happens
##    elsewhere" precedent). A FURNITURE-category Built cell is now ALSO
##    accepted by [method create_demolition_order] (Story building-017, this
##    revision, [TR-building-system-127]) -- this class performs no furniture
##    carve-out of its own, before or after that story: it only forwards
##    whatever that method decides, exactly as it always has. The atomic
##    multi-cell-footprint mechanics (Rule 16: "never a per-cell partial
##    teardown") live entirely inside [ConstructionTickLoop]/
##    [FurnitureFootprintGroup] -- this class still only ever resolves and
##    forwards ONE targeted [BlueprintCell] at a time, regardless of
##    category. A cell that already carries a demolition order ([member
##    BlueprintCell.is_demolition_queued]) is likewise a no-op via that SAME
##    method's own Edge 17 duplicate guard -- re-verified at this seam, not
##    reimplemented.
## 3. **Untracked** (no owning project at all -- raw terrain, or an address
##    this system has never touched): a no-op, `false`. Terrain targeting is
##    Story 013's own dig-order branch, out of this story's scope.
##
## `RefCounted`, population-wide shared collaborator -- mirrors
## [PlanOnlyUndoGate]'s exact composition shape (a small `RefCounted` gate
## that composes its dependencies at construction, never a second predicate-
## registration mechanism). A future [ToolStateMachine] `build_remove` mode
## (building-031's own named integration point) is this class's real future
## caller; directly callable by tests in the meantime, mirroring every other
## not-yet-assembled seam in this codebase.
class_name RemovalTool
extends RefCounted

## Story `building-034` addition (TD ruling D4) -- fires whenever branch 1
## ([method _cancel_not_yet_built_cell]) cancels [param project]'s LAST
## tracked cell and drops it from [member _registry] entirely (the moment a
## whole project is genuinely "cancelled," not merely one of its cells).
## Carries [param kind] so a listener ([ScaffoldDismantleCoordinator]) can
## filter to `BUILD`-kind projects only, exactly like every other scaffold
## seam in this codebase (Out of Scope: "Build projects only"). This class
## does not itself know anything about scaffolding -- see class doc comment,
## unchanged by this addition.
signal project_canceled(project_id: int, kind: BuildProject.Kind)

## The project registry this tool resolves a target cell's owning
## [BuildProject] through (the reverse index, [method
## BuildProjectRegistry.project_at_cell]) and keeps consistent on cancel via
## [method BuildProjectRegistry.unregister_cell]/[method
## BuildProjectRegistry.remove_project].
var _registry: BuildProjectRegistry

## The SAME [ConstructionTickLoop] instance the rest of this Building-System
## slice shares -- this tool's Built-branch delegate ([method
## ConstructionTickLoop.create_demolition_order]) and this tool's own
## not-yet-Built-branch claim-revoke fallback ([method
## ConstructionTickLoop.release_job]/[method ConstructionTickLoop.is_job_active]).
var _tick_loop: ConstructionTickLoop

## Optional collaborator -- resolves an UNDER_CONSTRUCTION cell's claiming
## villager id to a real [method ConstructionJobQueue.release_claim] call
## before cancellation (see class doc comment, branch 1). `null` is
## tolerated: a project whose UNDER_CONSTRUCTION cells were never claimed
## through a real queue (e.g. an isolated test) simply falls back to [member
## _tick_loop] instead, mirroring [PlanOnlyUndoGate]'s identical tolerance.
var _job_queue: ConstructionJobQueue = null


func _init(
	registry: BuildProjectRegistry,
	tick_loop: ConstructionTickLoop,
	job_queue: ConstructionJobQueue = null
) -> void:
	assert(registry != null, "RemovalTool requires a BuildProjectRegistry")
	assert(tick_loop != null, "RemovalTool requires a ConstructionTickLoop")
	_registry = registry
	_tick_loop = tick_loop
	_job_queue = job_queue


## The removal tool's single entry point (Rule 16, AC73/AC74, AC13/13b/AC65)
## -- see class doc comment for the full three-way branch. Returns `false`
## (no-op, nothing mutated) if [param cell] belongs to no tracked project.
func remove_cell(cell: Vector3i) -> bool:
	var project_id: int = _registry.project_at_cell(cell)
	if project_id == -1:
		return false
	var project: BuildProject = _registry.get_project(project_id)
	if project == null:
		return false
	var blueprint_cell: BlueprintCell = project.cells.get(cell)
	if blueprint_cell == null:
		return false
	if blueprint_cell.state == BlueprintCell.MicroState.BUILT:
		# Branch 2 -- delegates entirely to Story 009's already-landed
		# contract; never removes/clears anything itself (AC65).
		return _tick_loop.create_demolition_order(blueprint_cell)
	return _cancel_not_yet_built_cell(project, blueprint_cell)


## Branch 1 (see class doc comment) -- the Draft/Queued/UnderConstruction
## instant-cancel path, mirroring [PlanOnlyUndoGate]'s own "Cancel side"
## registry-aware cleanup exactly.
func _cancel_not_yet_built_cell(project: BuildProject, blueprint_cell: BlueprintCell) -> bool:
	if blueprint_cell.state == BlueprintCell.MicroState.UNDER_CONSTRUCTION:
		_revoke_active_job(blueprint_cell)
	if not project.cancel_cell(blueprint_cell.cell):
		return false
	_registry.unregister_cell(blueprint_cell.cell)
	if project.is_empty():
		var project_id: int = project.id
		var project_kind: BuildProject.Kind = project.kind
		_registry.remove_project(project)
		if _job_queue != null:
			_job_queue.remove_project(project)
		project_canceled.emit(project_id, project_kind)
	return true


## Releases whichever active construction claim [param blueprint_cell]
## currently holds (see class doc comment, branch 1) -- prefers [member
## _job_queue]'s own [method ConstructionJobQueue.release_claim] when a
## claiming villager id is on record, falls back to [member _tick_loop]'s own
## [method ConstructionTickLoop.release_job] otherwise. Mirrors
## [PlanOnlyUndoGate._revoke_active_job] exactly.
func _revoke_active_job(blueprint_cell: BlueprintCell) -> void:
	if blueprint_cell.claimed_by_villager_id != -1 and _job_queue != null:
		_job_queue.release_claim(blueprint_cell.claimed_by_villager_id)
		return
	if _tick_loop.is_job_active(blueprint_cell.cell):
		_tick_loop.release_job(blueprint_cell.cell)
