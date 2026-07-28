## Explicit "in bounds or not" result for a World->Cell query
## (`design/gdd/voxel-world.md` Formulas + Edge Cases, TR-voxel-world-037).
##
## A bare `Vector3i` cannot distinguish "this is the correct cell" from
## "this position lies outside the world" without the caller separately
## remembering to call a bounds predicate -- exactly the silent-clamp/crash
## failure mode TR-voxel-world-037 forbids. [VoxelWorldGrid.query_world_to_cell]
## returns this small explicit wrapper instead: [member in_bounds] is checked
## first; [member cell] holds the exact (never clamped) floored cell either
## way, useful for diagnostics even when out of bounds.
##
## `RefCounted`, not `Resource` -- this is a transient per-call value object,
## never authored/serialized/shared, mirroring the Resource & Item Database's
## `ItemDefinition` precedent (ADR-0006) of a fresh lightweight wrapper per
## call. Fields are set once in [method _init] and treated as read-only by
## every consumer.
class_name CellQueryResult
extends RefCounted

## True if [member cell] lies within the configured world bounds.
var in_bounds: bool

## The exact floored cell from the World->Cell formula -- never clamped,
## valid to inspect regardless of [member in_bounds].
var cell: Vector3i


func _init(p_in_bounds: bool, p_cell: Vector3i) -> void:
	in_bounds = p_in_bounds
	cell = p_cell
