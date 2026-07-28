## Scaffold dismantle ordering (story `building-034`, TD rulings D10/D4,
## ADR-0007 §1b invariant SC-INV-1). A pure, static planning library -- no
## instance, no cached state, mirrors [ScaffoldErectionPlanner]'s own
## established shape. Owns ONLY the ORDERING/occupancy-safety rules; the
## actual worker-executed demolition job mechanics are
## [ConstructionTickLoop.create_demolition_order]/[method
## ConstructionTickLoop.claim_demolition_job] (unchanged by this story beyond
## the `Category.SCAFFOLD` widening already landed there).
##
## **D10 (RULED: Option (i))** -- top-down, worker-first: the worker
## descends one scaffold cell first (an ordinary scaffold-to-scaffold
## vertical step ADR-0007 §2a already makes legal), THEN the cell above is
## dismantled. Dismantle order is strictly DESCENDING Y, ties broken
## lexicographically on `(x, z)`.
##
## **SC-INV-1 (ADR-0007 §1b, load-bearing):** no scaffold cell is ever
## removed while any villager's body-column occupies it -- an escape route
## `would_trap_builder` counts on can never be safely yanked away.
##
## **D4 (RULED: Option (i))** -- a player cancel checks the scaffold
## structure for occupancy FIRST (any villager whose body-column intersects
## ANY cell of the structure): occupied => fall back to the top-down,
## worker-ridden dismantle above; unoccupied => the fast bottom-up collapse
## ruling 3 permits, with no worker to protect.
class_name ScaffoldDismantlePlanner
extends RefCounted

## Sentinel meaning "no cell is currently safe to dismantle" -- either the
## structure is already empty, or every remaining cell's body-column is
## currently occupied.
const NO_CELL: Vector3i = Vector3i(-2147483648, -2147483648, -2147483648)


## D10 + SC-INV-1: the NEXT scaffold cell safe to dismantle from [param
## built_scaffold_cells] (a `SCAFFOLD` project's own currently-BUILT cells) --
## strictly TOP-DOWN (highest Y first, ties lexicographic on `(x, z)` via
## [method VillagerJobSelector.lexicographic_cell_less_than], reused rather
## than a second tie-break), skipping any cell whose full body-column
## ([method VillagerWalkabilityRules.body_column]) intersects ANY entry of
## [param occupied_body_columns] (SC-INV-1). Returns [constant NO_CELL] if
## [param built_scaffold_cells] is empty or every remaining cell is currently
## occupied (the caller must wait -- e.g. for the worker to finish its own
## one-step descent -- and ask again next tick, never force a removal).
static func next_top_down_demolition_cell(
	built_scaffold_cells: Array[Vector3i], occupied_body_columns: Array
) -> Vector3i:
	var ordered: Array[Vector3i] = built_scaffold_cells.duplicate()
	ordered.sort_custom(_less_than_descending_y_then_xz)
	for candidate: Vector3i in ordered:
		if not _is_occupied(candidate, occupied_body_columns):
			return candidate
	return NO_CELL


## D4 (RULED: Option (i)) -- whether [param scaffold_cells] (the WHOLE
## structure, not just the topmost cell) may be collapsed bottom-up with no
## worker: `true` iff NO entry of [param occupied_body_columns] intersects
## ANY cell of the structure. A cancel that finds this `false` MUST fall back
## to the top-down, worker-ridden dismantle ([method
## next_top_down_demolition_cell]) instead (D4 Forbids: "any dismantle path
## that removes a cell occupied by a body-column").
static func can_collapse_bottom_up(
	scaffold_cells: Array[Vector3i], occupied_body_columns: Array
) -> bool:
	for cell: Vector3i in scaffold_cells:
		if _is_occupied(cell, occupied_body_columns):
			return false
	return true


## Whether [param cell] falls within ANY body-column in [param
## occupied_body_columns] -- the SC-INV-1 check every method above shares.
static func _is_occupied(cell: Vector3i, occupied_body_columns: Array) -> bool:
	for body_column: Array[Vector3i] in occupied_body_columns:
		if body_column.has(cell):
			return true
	return false


## D10's own tie-break: descending Y first (top-down), then lexicographic
## `(x, z)` for cells sharing a Y (mirrors [method
## VillagerJobSelector.lexicographic_cell_less_than]'s own `(y, x, z)`
## convention, inverted on Y only -- this is a DESCENDING sort, the one place
## this codebase's tie-break runs in reverse, by D10's own explicit
## requirement).
static func _less_than_descending_y_then_xz(a: Vector3i, b: Vector3i) -> bool:
	if a.y != b.y:
		return a.y > b.y
	if a.x != b.x:
		return a.x < b.x
	return a.z < b.z
