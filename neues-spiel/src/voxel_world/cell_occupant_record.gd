## Per-cell pairing for [method VoxelWorldGrid.iterate_occupied] (Story vox-005,
## GDD "Save/Load & World Persistence" Interactions row; TR-voxel-world-021).
##
## [method VoxelWorldGrid.iterate_occupied] walks internal chunk storage
## chunk-by-chunk, but callers must never see that internal shape -- only a
## flat sequence of `(cell, occupant)` pairs (story Implementation Notes).
## This small wrapper is that pairing, mirroring [CellChangeRecord]'s
## established `(cell, ...)` record-object precedent for the read/iteration
## side rather than the write side.
##
## `RefCounted`, not `Resource` -- a transient per-call value object, never
## authored/serialized/shared, matching every other value object in this
## directory ([CellContents], [CellChangeRecord], [CellQueryResult],
## [RaycastHitResult]).
class_name CellOccupantRecord
extends RefCounted

## The occupied cell this record describes.
var cell: Vector3i

## The cell's contents at the moment [method VoxelWorldGrid.iterate_occupied]
## read it -- always non-empty ([method CellContents.is_empty] is always
## false here; TR-voxel-world-021 guarantees only occupied cells are ever
## wrapped by [method VoxelWorldGrid.iterate_occupied]).
var contents: CellContents


func _init(p_cell: Vector3i, p_contents: CellContents) -> void:
	cell = p_cell
	contents = p_contents
