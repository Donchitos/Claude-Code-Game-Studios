## Building System's scaffold occupancy registry (story `building-034`,
## technical-director ruling D1 -- Option (a)). Mirrors [FurnitureRegistry]
## exactly (the landed BV-1 precedent this ruling names): a keyed occupancy
## store, `RefCounted`, never an Autoload/singleton/module-global (ADR-0007
## §1b Forbids), one change signal, consumers re-enumerate/re-query current
## state and never trust a signal payload as authoritative snapshot data.
##
## **A scaffold cell is NOT voxel data** (D1) -- it never enters
## [VoxelWorldGrid]; `CellContents.is_empty()` is completely unaffected by
## this class's contents. Scaffold occupancy is supplied to the shared
## walkability predicates ([VillagerWalkabilityRules.is_standable]/
## [method VillagerWalkabilityRules.is_step_legal]) as an explicit, defaulted
## `scaffold_source` parameter -- this registry is the concrete object every
## production caller passes; a caller that passes nothing (Build Validation)
## stays scaffold-blind structurally (ADR-0007 §1b).
##
## **O(1) keyed lookup only** (ADR-0007 §1a/D1 Performance clause, BINDING):
## [method has_scaffold] is a direct [Dictionary] read. No support, cantilever,
## or connectivity search of any kind runs here -- those are erection-time
## planning rules ([ScaffoldErectionPlanner]), never a predicate-time cost.
class_name ScaffoldRegistry
extends RefCounted

## Fires whenever [method add]/[method remove] changes this registry's
## membership -- carries the single changed cell (ADR-0007 §2b: "the scaffold
## occupancy source must expose its own change signal... routing into the
## existing `patch_cells` path"). The cell IS the information the nav graph's
## bounded patch needs to know WHERE to re-sync -- consumers still re-query
## CURRENT membership via [method has_scaffold] rather than trusting this
## payload as a snapshot of broader state (the same "never read the payload"
## discipline [VoxelWorldGrid.cell_changed] already established elsewhere in
## this codebase, applied here to a single-cell identity rather than a
## before/after content pair).
signal scaffold_changed(cell: Vector3i)

## Keyed occupancy store -- presence of a key IS "this cell is scaffold."
## `Dictionary[Vector3i, bool]` (never a richer record; a scaffold cell has no
## per-cell data beyond "is it one") mirrors [FurnitureRegistry]'s own
## `_cell_index` shape.
var _cells: Dictionary[Vector3i, bool] = {}


## Marks [param cell] as a scaffold cell. Returns `false` (no-op, no signal)
## if [param cell] is already scaffold -- idempotent, mirrors
## [FurnitureRegistry.place]'s own "the caller decides whether re-adding is
## meaningful" precedent, except this method itself guards against a
## redundant re-add so a caller never double-counts one cell.
func add(cell: Vector3i) -> bool:
	if _cells.has(cell):
		return false
	_cells[cell] = true
	scaffold_changed.emit(cell)
	return true


## Removes [param cell] from scaffold membership. Returns `false` (no-op, no
## signal) if [param cell] was not scaffold. Callers are responsible for
## SC-INV-1 (ADR-0007 §1b: "no scaffold cell is ever removed while any
## villager's body-column occupies it") -- this registry has no villager/
## occupancy concept of its own (mirrors [FurnitureRegistry]'s own "no
## Villager AI awareness" boundary); [ScaffoldDismantlePlanner] is the
## caller that enforces the invariant before ever calling this method.
func remove(cell: Vector3i) -> bool:
	if not _cells.has(cell):
		return false
	_cells.erase(cell)
	scaffold_changed.emit(cell)
	return true


## The O(1) keyed predicate every shared walkability predicate duck-types
## against (ADR-0007 Key Interfaces: `func has_scaffold(cell: Vector3i) ->
## bool`). A direct [Dictionary] read -- no search of any kind.
func has_scaffold(cell: Vector3i) -> bool:
	return _cells.has(cell)


## Every currently-scaffold cell (no defined order beyond [Dictionary]'s own
## insertion order) -- read-only observability for tests, the erection
## planner's support-chain reasoning (D6: "a supported scaffold cell"), and
## the presentation tier's re-enumeration on [signal scaffold_changed].
func get_cells() -> Array[Vector3i]:
	return _cells.keys()


## Whether this registry currently tracks zero scaffold cells (AC1: "a room
## whose every cell is already reachable produces zero scaffold cells").
func is_empty() -> bool:
	return _cells.is_empty()
