## Scaffold erection plan outcome (story `building-034`, TD ruling D8) --
## `RefCounted`, transient per-call value object, mirroring
## [JobSelectionResult]'s own "explicit hit-or-miss rather than a bare
## nullable return" precedent.
class_name ScaffoldPlan
extends RefCounted

## The scaffold cells to erect, in D8's own required erection ORDER: strictly
## ascending Y within the support column, then the cantilever run (D8.4).
## Empty iff [method has_plan] is `false`.
var cells: Array[Vector3i] = []

## The staging cell `A` this plan makes standable (D8.1) -- orthogonally
## adjacent to the originally-unreachable blueprint cell, never the blueprint
## cell's own address.
var staging_cell: Vector3i = Vector3i.ZERO

## The plan-time cantilever distance (D6.3) of [member staging_cell] --
## `0` for a directly-supported column, `> 0` for a cantilevered run.
var cantilever_distance: int = 0


func _init(
	p_cells: Array[Vector3i] = [], p_staging_cell: Vector3i = Vector3i.ZERO, p_cantilever_distance: int = 0
) -> void:
	cells = p_cells
	staging_cell = p_staging_cell
	cantilever_distance = p_cantilever_distance


## Whether this plan actually produces any scaffold cells (D5: "the erection
## planner must be allowed to return 'no plan'... never loop").
func has_plan() -> bool:
	return not cells.is_empty()


## A `false`/empty [ScaffoldPlan] -- no valid staging cell or support could be
## found within the cantilever limit.
static func no_plan() -> ScaffoldPlan:
	return ScaffoldPlan.new([], Vector3i.ZERO, 0)
