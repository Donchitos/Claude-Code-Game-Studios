## Region cell-set carrier (Story build-validation-003, GDD `design/gdd/
## build-validation-navigability.md` Rule 1's region definition,
## [TR-build-validation-navigability-024]).
##
## A **candidate region** is a maximal orthogonally-connected set of candidate
## interior cells -- [BuildValidationRegionFormation] is the sole class that
## forms one of these; this class is purely the resulting VALUE, carrying the
## region's interior cell SET rather than just a size or a boolean (the GDD's
## own requirement: "a region carries its interior cell set, not just a
## boolean") -- so story 004's outside-connection trace + `min_room_cells`
## thresholding, and story 005's incremental snapshot, have the actual
## membership to work against.
##
## Deliberately holds NOTHING beyond membership: no Room/Sealed verdict field,
## no reachability state, no furniture/shelter data -- those are story
## 004/006's own additions layered on top of a formed region, not this
## story's scope. `RefCounted`, not `Resource` -- a transient per-pass value
## object, never authored/serialized/shared, mirroring [CellChangeRecord]/
## [RescueSearchResult]'s established "fresh lightweight wrapper per call"
## precedent.
class_name BuildValidationRegion
extends RefCounted

## Interior cell membership, `Vector3i -> true` (ADR-0007's own reference
## shape for a BFS visited-set, reused here as the region's own O(1)
## membership store) -- [method contains] is a dictionary lookup, never a
## linear scan over an array.
var cells: Dictionary[Vector3i, bool] = {}


## Constructs a region from an already-BFS-collected visited-set
## ([BuildValidationRegionFormation] is the sole intended caller -- this class
## performs no BFS of its own and asserts nothing about how [param p_cells]
## was produced). No default value -- every caller has a concrete visited-set
## in hand (possibly empty, e.g. a non-candidate seed), never an implicit one.
func _init(p_cells: Dictionary[Vector3i, bool]) -> void:
	cells = p_cells


## Interior cell count (GDD: "Region size is counted so `min_room_cells` can
## be applied by the verdict step" -- story 004's own scope; this method only
## supplies the count this story is required to guarantee is available).
func size() -> int:
	return cells.size()


## Whether [param cell] is a member of this region.
func contains(cell: Vector3i) -> bool:
	return cells.has(cell)


## The region's membership as a plain typed array (story 004's outside-trace
## seed set, story 005's snapshot patching) -- a fresh array per call via
## [method Dictionary.keys], never a cached copy.
func cell_list() -> Array[Vector3i]:
	return cells.keys()
