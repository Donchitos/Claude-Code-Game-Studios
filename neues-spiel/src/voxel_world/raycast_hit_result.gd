## Explicit "hit or miss" result for [VoxelWorldGrid.raycast_cells] (Story
## vox-004, `design/gdd/voxel-world.md` Core Rule 5, TR-voxel-world-017/049).
##
## Mirrors [CellQueryResult]'s established precedent: an explicit boolean +
## payload object, never a bare sentinel value or `null` for a legitimate "no
## hit" outcome -- a miss is the MOST common per-frame hover-pick result
## (TR-voxel-world-047), not an error case, so it gets its own flag rather
## than reusing [method get_cell]'s "`null` means out-of-bounds" convention.
##
## `RefCounted`, not `Resource` -- a transient per-call value object, never
## authored/serialized/shared, matching [CellQueryResult]/[CellContents]/
## [CellChangeRecord]'s shared precedent (itself mirroring the Resource & Item
## Database's `ItemDefinition`, ADR-0006) of a fresh lightweight wrapper per
## call. Fields are set once in [method _init] and treated as read-only by
## every consumer.
class_name RaycastHitResult
extends RefCounted

## True if the ray hit an occupied cell within the queried `max_distance`.
## Callers MUST check this before trusting [member cell]/[member normal].
var hit: bool

## The hit cell -- meaningless when [member hit] is `false`.
var cell: Vector3i

## The entry face's outward normal (e.g. `Vector3i(0, 1, 0)` for a hit on a
## cell's top face) -- `Vector3i.ZERO` when the ray's own origin was already
## embedded in solid geometry (no face was "entered" from outside). Meaningless
## when [member hit] is `false`.
var normal: Vector3i


func _init(p_hit: bool, p_cell: Vector3i = Vector3i.ZERO, p_normal: Vector3i = Vector3i.ZERO) -> void:
	hit = p_hit
	cell = p_cell
	normal = p_normal
