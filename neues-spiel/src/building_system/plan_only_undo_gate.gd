## Building System's plan-only undo/redo wiring (Story building-011, ADR-0016
## primary -- "the undo stack governs the plan ONLY -- draft cells and queued
## orders. Built cells are never mutated by undo"; GDD Core Rule 17,
## [TR-building-system-119]).
##
## Story building-032/033 landed [UndoRedoStack]'s stack mechanics with two
## deliberately-unwired seams -- [member UndoRedoStack.cancel_cell_callable]/
## [member UndoRedoStack.recreate_cell_callable] -- and named THIS story as
## their real future caller. This class is that caller: it wires both seams
## in [method _init], mirroring [VillagerOnSiteGate]/[VillagerSealPreventionGate]'s
## own established "small `RefCounted` gate, composes its dependencies at
## construction, wires a bound method directly into another class's seam"
## architecture exactly -- never a second predicate-registration mechanism.
##
## `RefCounted`, population-wide shared collaborator (mirrors the two
## Villager AI gates above) -- one instance per running game, code-assigned,
## no Inspector-editable representation, constructed once a future
## scene-assembly story has a live [UndoRedoStack]/[BuildProjectRegistry]/
## [VoxelWorldGrid] to hand it (none of that assembly exists yet in this
## codebase, mirrors every other not-yet-wired seam here).
##
## **Cancel side** ([method _cancel_cell], Rule 17/AC27/AC29/AC68): resolves
## [param cell]'s owning [BuildProject] via [member _registry]'s reverse
## index, and refuses outright (`false`, nothing mutated) whenever the
## tracked [BlueprintCell] is already [constant BlueprintCell.MicroState.BUILT]
## -- no removal, no demolition order queued, exactly Rule 17's own words.
## For a still-pending (Draft/Queued) or claimed (UnderConstruction) cell,
## releases any active construction claim FIRST (via [member _job_queue]'s
## own [method ConstructionJobQueue.release_claim], resolved from [member
## BlueprintCell.claimed_by_villager_id] -- the SAME attribution Story
## building-005 already records as every successful claim's own side effect
## -- or, absent that attribution, a direct [member _tick_loop] fallback),
## THEN delegates the actual per-cell cancellation to [method
## BuildProject.cancel_cell] (that method's own pre-existing PLANNED/
## UNDER_CONSTRUCTION-only guard is what makes the BUILT refusal above
## doubly redundant-safe, never load-bearing on its own). On success, also
## performs the registry-aware cleanup [BuildProjectRegistry]'s OWN doc
## comment names as future work for exactly this kind of caller
## ("Reverse-index removal on cancel/demolish... a future story wires this
## once cancel/demolish flows reach a registry-aware caller"): [method
## BuildProjectRegistry.unregister_cell] keeps the reverse index from going
## stale at the canceled address, and an emptied project ([method
## BuildProject.is_empty]) is dropped from both [member _registry] and
## [member _job_queue] (AC61's "the project entity itself is deleted,"
## realized here for the very first time by an actual registry-aware
## caller).
##
## A multi-cell furniture footprint ([member BlueprintCell.footprint_group])
## is never special-cased into a single atomic accept/reject unit here --
## every cell of one player command is recorded together and [method
## UndoRedoStack.undo] already calls this callable once per cell of THAT
## SAME command in one pass, so an all-pending footprint's siblings are
## cancelled TOGETHER, in the same [method UndoRedoStack.undo] call, by
## construction (never "half a bed" for the common case). A footprint whose
## siblings straddle Built/not-yet-Built is handled by the exact SAME Rule 17
## refusal above, per cell, independently -- AC27/AC29 explicitly require
## this literal per-cell behavior even for a mixed command, so a stray
## still-Built footprint sibling with a cancelled twin is Rule 17's own
## accepted outcome, not a defect this gate special-cases around.
##
## **Recreate side** ([method _recreate_cell], Edge Case 8/AC28): [method
## _cancel_cell] snapshots the category/furniture-id/contents/project-kind of
## every cell it actually cancels (never a cell Rule 17 left standing --
## those have no snapshot and therefore cannot be recreated at all, which is
## exactly correct: [method UndoRedoStack.redo] replays every cell of the
## ORIGINAL command including any that were left Built, and a missing
## snapshot here makes that already-standing cell a guaranteed drop instead
## of a duplicate). A drop also occurs on any current-state re-validation
## failure -- out of bounds, the raw grid non-empty (a BLOCK-category Built
## cell reoccupying it), or [member _registry]'s reverse index already
## covering the address (catches a FURNITURE-category Built cell too, which
## never touches the grid at all per ADR-0016 BV-1, and catches a genuinely
## different project having since claimed it). A surviving cell is
## reconstructed as a fresh [constant BlueprintCell.MicroState.PLANNED]
## [BlueprintCell] and handed to [method BuildProjectRegistry.assign_cells]
## -- never routed back through [CommitPipeline], since a redo replays an
## already-validated former command, not a fresh player pick.
##
## **Known, deliberate limitation** (flagged, not silently absorbed): a
## multi-cell furniture footprint's shared [FurnitureFootprintGroup] is NOT
## reconstructed across a redo. [method UndoRedoStack.redo]'s own Callable
## seam invokes [method _recreate_cell] once per cell, independently, with no
## hook to learn "this is the last sibling of the group" before deciding any
## one cell's own survival -- coordinating that would mean extending
## [UndoRedoStack]'s own already-landed (building-032/033) redo() shape,
## which this story's own guidance is to honour, not rework. A redone
## multi-cell footprint therefore lands as N independent single-cell
## FURNITURE blueprints (each completing/registering on its own, rather than
## as one shared entity) -- correct for the redo of an all-BLOCK wall (every
## acceptance criterion's own worked example) and for a single-cell furniture
## item, but not yet a full round-trip for an undone-then-redone multi-cell
## footprint. A follow-up story is the right place to extend [UndoRedoStack]
## itself with a batch-aware redo hook if that round-trip is required.
##
## Story building-012 (this revision, ADR-0016 primary, GDD Rule 14l,
## [TR-building-system-120]) extends [_CanceledCellSnapshot] with [member
## _CanceledCellSnapshot.restore_value] -- a floor-excavation cell's captured
## terrain snapshot ([member BlueprintCell.restore_value]) must survive an
## undo-then-redo round-trip UNCHANGED (Edge 18: "a snapshot, never
## re-derived"), never dropped and never re-read from whatever the grid
## happens to hold at redo time (which, per Edge Case 18's own named scenario,
## could in principle have changed in the interim). [method _cancel_cell]
## copies it into the snapshot alongside the fields this class already
## carried; [method _recreate_cell] copies it back out onto the freshly
## reconstructed [BlueprintCell]. This class still never writes to
## [VoxelWorldGrid] itself (unchanged) -- a not-yet-Built cell's terrain was
## never actually touched in the grid, so there is nothing to write back on
## cancel; only the SNAPSHOT ITSELF (an in-memory value the project entity
## carries forward) needs to survive the round-trip so a LATER demolish of the
## eventually-redone-and-built cell still restores the correct original
## terrain ([ConstructionTickLoop]'s own already-landed Story building-009
## consuming half).
class_name PlanOnlyUndoGate
extends RefCounted

## One cancelled cell's remembered shape (see class doc comment, "Recreate
## side") -- captured by [method _cancel_cell] immediately before the actual
## cancellation, consumed (and erased) by exactly one future [method
## _recreate_cell] call for the SAME cell address.
class _CanceledCellSnapshot:
	var category: BlueprintCell.Category
	var furniture_definition_id: StringName
	var contents: CellContents
	var kind: BuildProject.Kind

	## Story building-012 addition (Rule 14l) -- see class doc comment. `null`
	## for every ordinary cell (the overwhelming majority), matching [member
	## BlueprintCell.restore_value]'s own default.
	var restore_value: CellContents

	func _init(
		p_category: BlueprintCell.Category,
		p_furniture_definition_id: StringName,
		p_contents: CellContents,
		p_kind: BuildProject.Kind,
		p_restore_value: CellContents = null
	) -> void:
		category = p_category
		furniture_definition_id = p_furniture_definition_id
		contents = p_contents
		kind = p_kind
		restore_value = p_restore_value

## The stack this gate wires its composed callables into (see class doc
## comment). Stored for observability only -- every real effect flows
## through [member _registry]/[member _job_queue]/[member _tick_loop] below.
var _undo_redo_stack: UndoRedoStack

## The project registry this gate resolves a cell's owning [BuildProject]
## through, keeps the reverse index consistent via ([method
## BuildProjectRegistry.unregister_cell]), and re-registers a redo-surviving
## cell into via [method BuildProjectRegistry.assign_cells].
var _registry: BuildProjectRegistry

## Read-only occupancy source for [method _recreate_cell]'s bounds/empty
## re-validation -- this gate never writes to it (never `set_cell(`/
## `bulk_write(`/`clear_cell(`).
var _voxel_world: VoxelWorldGrid

## Optional collaborator -- resolves an UNDER_CONSTRUCTION cell's claiming
## villager id to a real [method ConstructionJobQueue.release_claim] call
## before cancellation (see class doc comment, "Cancel side"). `null` is
## tolerated: a project whose UNDER_CONSTRUCTION cells were never claimed
## through a real queue (e.g. an isolated test) simply skips this step and
## falls back to [member _tick_loop] instead.
var _job_queue: ConstructionJobQueue

## Optional fallback collaborator -- directly releases an active job when no
## [member _job_queue]-recorded claim attribution exists for the cell (see
## [member BlueprintCell.claimed_by_villager_id]'s own `-1` sentinel). `null`
## is tolerated exactly like [member _job_queue].
var _tick_loop: ConstructionTickLoop

## Every cell this gate has cancelled and not yet either recreated (redo) or
## permanently dropped -- see [_CanceledCellSnapshot] and the class doc
## comment's "Recreate side".
var _snapshots: Dictionary[Vector3i, _CanceledCellSnapshot] = {}


## Wires this gate's two composed callables into [param undo_redo_stack]
## immediately (see class doc comment) -- mirrors [VillagerOnSiteGate]'s own
## `_init` precedent exactly. [param job_queue]/[param tick_loop] are
## optional (see their own doc comments above).
func _init(
	undo_redo_stack: UndoRedoStack,
	registry: BuildProjectRegistry,
	voxel_world: VoxelWorldGrid,
	job_queue: ConstructionJobQueue = null,
	tick_loop: ConstructionTickLoop = null
) -> void:
	assert(undo_redo_stack != null, "PlanOnlyUndoGate requires an UndoRedoStack")
	assert(registry != null, "PlanOnlyUndoGate requires a BuildProjectRegistry")
	assert(voxel_world != null, "PlanOnlyUndoGate requires a VoxelWorldGrid")
	_undo_redo_stack = undo_redo_stack
	_registry = registry
	_voxel_world = voxel_world
	_job_queue = job_queue
	_tick_loop = tick_loop
	_undo_redo_stack.set_cancel_cell_callable(_cancel_cell)
	_undo_redo_stack.set_recreate_cell_callable(_recreate_cell)


## Read-only observability/test seam -- whether [param cell] currently holds
## a snapshot awaiting a future [method _recreate_cell] call (i.e. it was
## actually cancelled by this gate, not left standing as Built).
func has_snapshot(cell: Vector3i) -> bool:
	return _snapshots.has(cell)


## The plan-only cancel callable (see class doc comment, "Cancel side") --
## wired as [member UndoRedoStack.cancel_cell_callable]. Returns `false`
## (nothing mutated) if [param cell] is untracked by any project, or its
## tracked cell is already [constant BlueprintCell.MicroState.BUILT] (Rule
## 17/AC27/AC29/AC68 -- the plan-only invariant this whole story exists to
## enforce).
func _cancel_cell(cell: Vector3i) -> bool:
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
		return false
	if blueprint_cell.state == BlueprintCell.MicroState.UNDER_CONSTRUCTION:
		_revoke_active_job(cell, blueprint_cell)
	var restore_value_snapshot: CellContents = null
	if blueprint_cell.restore_value != null:
		restore_value_snapshot = CellContents.new(
			blueprint_cell.restore_value.block_type_id, blueprint_cell.restore_value.material_id
		)
	var snapshot := _CanceledCellSnapshot.new(
		blueprint_cell.category,
		blueprint_cell.furniture_definition_id,
		CellContents.new(blueprint_cell.contents.block_type_id, blueprint_cell.contents.material_id),
		project.kind,
		restore_value_snapshot
	)
	if not project.cancel_cell(cell):
		return false
	_registry.unregister_cell(cell)
	if project.is_empty():
		_registry.remove_project(project)
		if _job_queue != null:
			_job_queue.remove_project(project)
	_snapshots[cell] = snapshot
	return true


## Releases whichever active construction claim [param cell] currently holds
## (see class doc comment, "Cancel side") -- prefers [member _job_queue]'s
## own [method ConstructionJobQueue.release_claim] (keeps both that queue's
## claim bookkeeping AND [member _tick_loop]'s active-job state in sync in
## one call, mirroring [VillagerSealPreventionGate]'s own established "call
## the queue, not the tick loop directly" precedent) when a claiming
## villager id is on record; falls back to [member _tick_loop]'s own [method
## ConstructionTickLoop.release_job] only when no such attribution exists
## (e.g. an isolated test that claimed a job directly against the tick loop,
## bypassing the queue).
func _revoke_active_job(cell: Vector3i, blueprint_cell: BlueprintCell) -> void:
	if blueprint_cell.claimed_by_villager_id != -1 and _job_queue != null:
		_job_queue.release_claim(blueprint_cell.claimed_by_villager_id)
		return
	if _tick_loop != null and _tick_loop.is_job_active(cell):
		_tick_loop.release_job(cell)


## The plan-only redo callable (see class doc comment, "Recreate side") --
## wired as [member UndoRedoStack.recreate_cell_callable]. Returns `false`
## (dropped) if [param cell] carries no snapshot (never actually cancelled by
## this gate -- including a cell Rule 17 left standing as Built), is now out
## of bounds, is already tracked by SOME project in [member _registry]'s
## reverse index (catches a FURNITURE-category Built cell, which never
## touches the grid at all, and catches a different project having since
## claimed the address), or fails its own current-state re-validation.
##
## Story building-012 addition (Rule 14l, Edge 18) -- current-state
## re-validation now branches on whether [param cell] carries a captured
## [member _CanceledCellSnapshot.restore_value]: an ORDINARY cell (no
## `restore_value`, the overwhelming majority) must still read EMPTY in the
## raw grid, exactly as every pre-012 caller already required. A
## FLOOR-EXCAVATION cell (non-null `restore_value`) is NEVER empty by design
## (its own captured terrain still physically occupies the address -- nothing
## writes the actual grid until the cell reaches Built) -- it is instead valid
## iff the raw grid's CURRENT contents still match the captured snapshot
## EXACTLY (the terrain has not drifted since replacement); Edge 18's own
## named scenario ("the stored terrain has itself changed since replacement...
## not possible in MVP's static terrain, but the bookkeeping must not assume
## otherwise") is exactly this branch's failure path -- a diverged current
## terrain drops the redo rather than silently recreating a stale excavation.
## On success, reconstructs a fresh [constant BlueprintCell.MicroState.PLANNED]
## [BlueprintCell] carrying the snapshot's category/furniture id/contents
## (AND `restore_value`, unchanged from whatever was originally captured --
## never re-read from the current grid state even on the matching path) and
## hands it to [method BuildProjectRegistry.assign_cells] under the
## snapshot's original project [enum BuildProject.Kind].
func _recreate_cell(cell: Vector3i) -> bool:
	var snapshot: _CanceledCellSnapshot = _snapshots.get(cell)
	if snapshot == null:
		return false
	_snapshots.erase(cell)
	if not _voxel_world.is_in_bounds(cell):
		return false
	var current: CellContents = _voxel_world.get_cell(cell)
	if snapshot.restore_value != null:
		if (
			current.block_type_id != snapshot.restore_value.block_type_id
			or current.material_id != snapshot.restore_value.material_id
		):
			return false
	elif not current.is_empty():
		return false
	if _registry.project_at_cell(cell) != -1:
		return false
	var restored_restore_value: CellContents = null
	if snapshot.restore_value != null:
		restored_restore_value = CellContents.new(
			snapshot.restore_value.block_type_id, snapshot.restore_value.material_id
		)
	var recreated := BlueprintCell.new(
		cell,
		BlueprintCell.MicroState.PLANNED,
		snapshot.category,
		CellContents.new(snapshot.contents.block_type_id, snapshot.contents.material_id),
		snapshot.furniture_definition_id,
		restored_restore_value
	)
	_registry.assign_cells([recreated], snapshot.kind)
	return true
