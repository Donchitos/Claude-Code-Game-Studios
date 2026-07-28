## Explicit "empty or block record" value object for a single Voxel World cell
## (`design/gdd/voxel-world.md` Core Rule 2, TR-voxel-world-003/030/031/045).
##
## Every cell holds exactly one of: empty (no block), or a block record
## containing a block-type identifier and a material identifier -- there is
## no "layering," one cell = one occupant (Core Rule 2). Both identifiers are
## ids defined by the Resource & Item Database; this system stores them as
## opaque values and never resolves their meaning (TR-voxel-world-028) --
## never construct one by looking anything up against that database.
##
## `RefCounted`, not `Resource` -- a transient per-call value object, never
## authored/serialized/shared, mirroring [CellQueryResult]'s precedent (which
## itself mirrors the Resource & Item Database's `ItemDefinition`, ADR-0006)
## of a fresh lightweight wrapper per call.
##
## Terrain-origin and player-placed cells with identical ids are
## indistinguishable by design (TR-voxel-world-030) -- this class carries NO
## origin flag of any kind, deliberately.
class_name CellContents
extends RefCounted

## The reserved "no block" sentinel for [member block_type_id] -- Voxel
## World's own convention (never resolved against the Resource & Item
## Database), matching the packed-chunk-storage reference this story
## implements against (`prototypes/last-seal-vertical-slice/voxel_world.gd`'s
## `AIR := 0`). Both packed storage buffers ([VoxelWorldGrid]'s internal
## `_ChunkBuffer`) rely on `PackedByteArray.resize()`'s zero-fill for this to
## be the correct "still untouched" value with no explicit fill pass.
const EMPTY_BLOCK_TYPE_ID: int = 0

## Opaque block-type id (Resource & Item Database's vocabulary,
## TR-voxel-world-028) -- [constant EMPTY_BLOCK_TYPE_ID] means "no block."
## Must fit the packed-byte storage range 0-255 -- [VoxelWorldGrid.set_cell]
## asserts this.
var block_type_id: int

## Opaque material id (Resource & Item Database's vocabulary,
## TR-voxel-world-028) -- meaningless when [member block_type_id] is
## [constant EMPTY_BLOCK_TYPE_ID]. Must also fit 0-255 -- see
## [member block_type_id].
var material_id: int


func _init(p_block_type_id: int = EMPTY_BLOCK_TYPE_ID, p_material_id: int = 0) -> void:
	block_type_id = p_block_type_id
	material_id = p_material_id


## Convenience factory for the empty ("no block") cell state -- reads more
## clearly at [VoxelWorldGrid] call sites than a bare `CellContents.new()`.
static func empty() -> CellContents:
	return CellContents.new()


## True if this represents the empty ("no block") cell state.
func is_empty() -> bool:
	return block_type_id == EMPTY_BLOCK_TYPE_ID
