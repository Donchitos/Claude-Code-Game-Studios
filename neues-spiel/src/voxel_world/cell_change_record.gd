## Explicit per-cell change record for the bulk-write path (Story vox-003,
## ADR-0014 Implementation Notes; TR-voxel-world-042/043).
##
## A bulk write affects N cells under one call; the batched signal and the
## bulk-write API's return value must both carry per-cell granularity so the
## Building System's undo stack can restore each cell individually
## (TR-voxel-world-043). A single [Array] of bare [CellContents] pairs would
## lose which cell each pair belongs to -- this small wrapper pairs [member
## cell] with its [member before]/[member after] [CellContents], mirroring
## [VoxelWorldGrid.cell_changed]'s own (cell, before, after) signal shape for
## the single-cell case.
##
## `RefCounted`, not `Resource` -- a transient per-call value object, never
## authored/serialized/shared, matching [CellQueryResult]/[CellContents]'s
## established precedent (itself mirroring the Resource & Item Database's
## `ItemDefinition`, ADR-0006) of a fresh lightweight wrapper per call. Fields
## are set once in [method _init] and treated as read-only by every consumer.
class_name CellChangeRecord
extends RefCounted

## The cell this record describes.
var cell: Vector3i

## The cell's contents immediately before the write that produced this
## record -- for a cell touched for the first time, this is [method
## CellContents.empty].
var before: CellContents

## The cell's contents immediately after the write that produced this
## record.
var after: CellContents


func _init(p_cell: Vector3i, p_before: CellContents, p_after: CellContents) -> void:
	cell = p_cell
	before = p_before
	after = p_after
