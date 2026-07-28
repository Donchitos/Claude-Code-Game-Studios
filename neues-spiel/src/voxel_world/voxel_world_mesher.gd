## Voxel World's chunked, face-culled [ArrayMesh] mesher (Story vox-007,
## ADR-0014 Decision Section 2; TR-voxel-world-025/052) -- the production
## redemption of the vertical slice's "missing faces" winding saga.
##
## Consumes [VoxelWorldGrid]'s read API only ([method
## VoxelWorldGrid.get_chunk_snapshot] -- Story vox-019's bulk read-loop
## optimization seam, [method VoxelWorldGrid.get_cell] retained only for the
## chunk-border/world-edge minority, see [method _build_chunk_arrays]'s doc
## comment) -- never mutates the grid, and issues zero physics API calls of
## any kind (ADR-0014 Decision Section 4 / ADR-0004 carryover).
##
## THE ONE mesher construction site in this codebase (sprint QA requirement,
## Control Manifest "never a second mesher code path"): every [ArrayMesh.new]
## + [method ArrayMesh.add_surface_from_arrays] call for committed-block
## chunk terrain lives in [method _build_chunk_arrays] and nowhere else --
## grep-verified by `tests/unit/voxel_world/mesher_material_contract_test.gd`.
##
## Winding (TR-voxel-world-052, HARD QA requirement): every emitted quad's
## two triangles are wound to match Godot 4.7's ACTUAL front-face convention,
## established from first principles by inspecting a native [BoxMesh]'s own
## index/normal data -- never a self-stored assumption. See [constant
## FACE_CORNERS]'s doc comment for the derived rule and
## `tests/unit/voxel_world/mesher_winding_derivation_test.gd` for the pinned,
## automated regression proof (reproduces the same BoxMesh check every test
## run, so a future engine change to this convention is caught immediately).
## The shared material ships with backface culling ENABLED (`cull_back`,
## Godot's default -- set EXPLICITLY per the sprint QA smoke item, never left
## implicit). `CULL_DISABLED` never appears anywhere in this system --
## grep-guarded by the same material-contract test file.
##
## Scope (vox-007 -- explicitly excludes Story 015's view-window streaming):
## this class does NOT decide WHICH chunks are meshed as the camera moves --
## it only (a) builds/rebuilds one chunk's [ArrayMesh] on demand via [method
## build_chunk], and (b) MARKS an ALREADY-tracked chunk dirty when [signal
## VoxelWorldGrid.cell_changed] / [signal VoxelWorldGrid.cells_changed_batch]
## reports a change inside it -- or across its border into a tracked
## neighbor, since a solid/air change at a chunk's edge changes the
## NEIGHBORING chunk's own border-face culling too. A cell change in a chunk
## this class was never asked to [method build_chunk] is left alone; Story
## 015 owns chunk-membership decisions, this class only reacts within
## whatever membership already exists.
##
## Story vox-020 (this revision, TD ruling Addendum D §D7): the two change
## handlers no longer call [method build_chunk] synchronously inside signal
## dispatch (the ~69 ms 9-chunk frame-spike defect D7 named) -- they mark the
## touched, tracked chunk(s) dirty instead ([member _dirty_chunks]), exposed
## via [method get_dirty_chunk_keys]/[method clear_dirty]. Draining the dirty
## set through a time budget is [VoxelWorldMeshStreamer]'s job (its new
## rebuild phase, drained FIRST, sharing [member
## VoxelWorldConfig.mesh_build_budget_ms]'s window with the build-new phase --
## no independent rebuild budget, see that class's own doc comment for why).
## This class also subscribes to [signal VoxelWorldGrid.chunk_became_resident]
## (Story vox-020, ADR-0015 amendment) and marks a tracked chunk dirty the
## instant its data pages in -- closing the "mesh window outruns the async
## residency window" hole (D7's Defect 2) through the SAME dirty-set
## machinery, no second mechanism. [method unload_chunk] erases a chunk's
## dirty entry along with its tracking entry -- no dirty-set bookkeeping
## survives past a chunk's own tracked lifetime (D7's explicit "do not build
## bookkeeping for this" ruling); a re-entering chunk is built fresh from
## current grid state by construction, correct with zero carried state.
##
## Story vox-015 (this revision, ADR-0014 Decision Section 3 / ADR-0015
## Decision Section 1; TR-voxel-world-025/026) lands the chunk-membership
## owner this Scope note names -- [VoxelWorldMeshStreamer] -- and adds the
## one lifecycle method this class's own construction/mutation surface was
## still missing for it: [method unload_chunk] (releases an already-tracked
## chunk's [MeshInstance3D] and its tracking entry, the mirror image of
## [method build_chunk]'s "creates on first call, reuses after"). Whether/how
## OFTEN [method unload_chunk] is called, and how many calls are staggered
## across how many frames, is entirely [VoxelWorldMeshStreamer]'s own
## per-frame TIME BUDGET decision (Control Manifest Forbidden: "queue_free
## bursts") -- this class itself applies no staggering of its own, exactly
## like [method build_chunk] applies none either.
##
## Texturing (deliberately deferred, not this story's scope): no atlas story
## exists yet anywhere in `production/epics/voxel-world/` as of this story --
## per-vertex COLOR is still a flat per-block-type placeholder, sampled by the
## shared shader as plain unlit-texture ALBEDO. Vertex-AO and the vertical
## slice's `y_cut` slice-view uniform are ALSO deferred -- neither is required
## by this story's acceptance criteria. ONE shared [ShaderMaterial]
## ([member _material], `res://assets/shaders/terrain_chunk.gdshader`) is
## still the canonical single-material contract (art-bible SS8.9.1)
## specifically so later atlas/AO/y_cut stories extend this SAME
## material/shader file in place, never introduce a second one (art-bible
## SS8.9.11 Reject-If gate #1).
##
## Story vox-023 ("Block appearance becomes DATA"): the placeholder colour is
## no longer a hardcoded `const DEBUG_BLOCK_COLORS` dictionary -- it is read
## from [member appearance], a [BlockAppearanceConfig] injected exactly like
## [member grid] (ADR-0001/0002). [constant DEBUG_UNKNOWN_COLOR] is RETAINED,
## unchanged, as the visible-fail path for an id [member appearance] has no
## entry for -- this project's "visible fail, never silent" rule. See
## [BlockAppearanceConfig]'s own class doc comment for the storage-shape
## rationale and [method setup]/[method build_chunk] for the
## never-optional-and-consequential wiring discipline (sprint-12's own
## deepest rule): there is NO fallback appearance table anywhere in this file
## -- an unwired [member appearance] is a loud assert failure, never a
## correct-looking render.
class_name VoxelWorldMesher
extends Node3D

## The 6 face directions this mesher tests for exposure, in a fixed
## deterministic order matching [VoxelWorldGrid.NEIGHBOR_OFFSETS] (+X, -X,
## +Y, -Y, +Z, -Z).
const FACE_NORMALS: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]

## Per-face-direction quad corners, as integer offsets from a solid cell's
## MINIMUM corner (matching [method VoxelWorldGrid.cell_to_world]'s
## convention that cell `(x,y,z)` occupies the unit box
## `[x,x+1] x [y,y+1] x [z,z+1]`). Each entry is exactly 4 corners in a fixed
## rotational order; [method _append_face] fan-triangulates them as
## `(0,1,2)` + `(0,2,3)`.
##
## Winding derivation (TR-voxel-world-052, HARD QA requirement -- established
## empirically against THIS engine install, never from memory, the ADR's
## prose, or a self-stored assumption): a native [BoxMesh]'s own stored index
## order, taken in order `(v0,v1,v2)` per triangle, produces
## `(v1-v0).cross(v2-v0)` that points OPPOSITE that triangle's own stored
## vertex normal, for all 12 of its triangles (reproduced live by
## `tests/unit/voxel_world/mesher_winding_derivation_test.gd`, Part 1). Since
## [BoxMesh] is a native Godot primitive that renders correctly -- solid, no
## holes -- under Godot's default backface-culling material settings, this
## proves Godot's FRONT-FACING winding (the winding that SURVIVES backface
## culling) is the one where `(corner1-corner0).cross(corner2-corner0)`
## points OPPOSITE a face's true outward normal -- NOT the OpenGL/CCW-front
## convention the vertical slice wrongly assumed (`prototypes/last-seal-vertical-slice/voxel_world.gd`'s
## documented TR-voxel-world-052 "missing faces" root cause, which shipped
## `CULL_DISABLED` to compensate instead of fixing the winding). Every entry
## below was constructed fresh against that derived rule -- never copied from
## the slice's face tables -- and the same conformance check
## (`(corner1-corner0).cross(corner2-corner0)` opposite the face normal, for
## BOTH triangles of every face) is pinned as Part 2 of the same test file.
const FACE_CORNERS: Array[Array] = [
	# +X (RIGHT)
	[Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(1, 1, 1), Vector3i(1, 1, 0)],
	# -X (LEFT)
	[Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 1, 1), Vector3i(0, 0, 1)],
	# +Y (TOP)
	[Vector3i(0, 1, 0), Vector3i(1, 1, 0), Vector3i(1, 1, 1), Vector3i(0, 1, 1)],
	# -Y (BOTTOM)
	[Vector3i(0, 0, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(1, 0, 0)],
	# +Z (BACK)
	[Vector3i(0, 0, 1), Vector3i(0, 1, 1), Vector3i(1, 1, 1), Vector3i(1, 0, 1)],
	# -Z (FORWARD)
	[Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0)],
]

## Visibly-wrong magenta for any block-type id [member appearance] does not
## recognize (this project's established "visible fail, never silent"
## precedent) -- the ONE permitted `Color(...)` construction in
## `src/voxel_world/` (grep-guarded, `data_driven_block_appearance_test.gd`),
## RETAINED unchanged by Story vox-023: a "sensible fallback colour" here
## would be the exact class of defect this project hunts -- a permissive
## default that lets a missing appearance mapping ship unnoticed.
const DEBUG_UNKNOWN_COLOR: Color = Color(1.0, 0.0, 1.0)

## Voxel World / Grid Data dependency (ADR-0001 injected-tier). Wired via a
## scene file's Inspector in production, or assigned directly in a headless
## test/tool -- never read inside `_ready()` (see [method setup]).
@export var grid: VoxelWorldGrid

## Block-appearance config (ADR-0001/0002 injected-tier; Story vox-023) --
## resolves a [CellContents.block_type_id] to a [Color] from DATA, replacing
## the old `const DEBUG_BLOCK_COLORS` dictionary. Wired via `Valley.tscn`'s
## Inspector in production (`res://data/config/block_appearance_config.tres`),
## or assigned directly in a headless test/tool -- never read inside
## `_ready()` (see [method setup]). ⚑ AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL:
## there is NO fallback table if this is left unwired -- [method setup] and
## [method build_chunk] both assert it non-null, the same shape as the
## existing `grid`/`grid.config` asserts, and `Valley`'s own boot-invariant
## block asserts the wiring a second time (belt-and-suspenders, mirroring
## [WorldLightingConfig]'s landed precedent).
@export var appearance: BlockAppearanceConfig

## True once [method setup] has completed.
var _is_set_up: bool = false

## The BLOCKING-tagged subset of the most recent `appearance.validate()`
## result, if any (Story vox-023, ADR-0002). Populated by [method setup]; read
## by [GameWorld]'s boot gate via [method get_boot_blocking_issues]. Every
## issue [method BlockAppearanceConfig.validate] can return is already
## BLOCKING-tagged (that config's own class doc comment -- its field shape has
## no clamp-and-warn tier), so this is simply that call's raw result, never
## filtered.
var _boot_blocking_issues: Array[String] = []

## ONE shared [ShaderMaterial] instance for every chunk this mesher ever
## builds (art-bible SS8.9.1 canonical contract, ADR-0014 Decision Section
## 2) -- constructed exactly once, at this node's own construction (field
## initializer), never per-chunk.
var _material: ShaderMaterial = _build_shared_material()

## Tracked chunk -> [MeshInstance3D] child, keyed identically to
## [VoxelWorldGrid]'s internal chunk storage
## (`Vector2i(cell.x / CHUNK_SIZE, cell.z / CHUNK_SIZE)`). Only chunks this
## mesher was explicitly asked to [method build_chunk] appear here -- see the
## class doc comment's Scope note.
var _chunk_nodes: Dictionary[Vector2i, MeshInstance3D] = {}

## Tracked chunks awaiting a rebuild (Story vox-020) -- populated ONLY for
## keys already present in [member _chunk_nodes] (the same "tracked" gate
## [method is_chunk_tracked] exposes; AC-UNTRACKED-NO-BOOKKEEPING: a change to
## an untracked chunk records nothing here). Drained by
## [VoxelWorldMeshStreamer]'s budgeted rebuild phase via [method
## get_dirty_chunk_keys]/[method clear_dirty] -- this class itself never
## drains or budgets it, matching [method build_chunk]/[method unload_chunk]'s
## own "no staggering of its own" precedent.
var _dirty_chunks: Dictionary[Vector2i, bool] = {}


## Explicitly callable wiring entry point (ADR-0001). Asserts [member grid]
## (and its wired [VoxelWorldConfig]) and [member appearance] are present
## (Story vox-023, AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL -- the SAME assert
## shape as the two pre-existing ones, never a nullable fallback), applies
## ADR-0002's `validate()` discipline to [member appearance] exactly once,
## then subscribes to all three of [VoxelWorldGrid]'s change/residency signals
## so an already-[method build_chunk]'d chunk is marked dirty on any write
## inside (or bordering) it, or the instant its data pages in
## (TR-voxel-world-025/053) -- a chunk never asked for is left alone (Scope
## note).
func setup() -> void:
	assert(grid != null, "VoxelWorldMesher.grid not wired")
	assert(grid.config != null, "VoxelWorldMesher.grid.config not wired")
	assert(appearance != null, "VoxelWorldMesher.appearance not wired")
	_boot_blocking_issues = appearance.validate()
	grid.cell_changed.connect(_on_cell_changed)
	grid.cells_changed_batch.connect(_on_cells_changed_batch)
	grid.chunk_became_resident.connect(_on_chunk_became_resident)
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Returns the BLOCKING-tagged issues (if any) found in the most recent
## `appearance.validate()` call (Story vox-023, ADR-0002). [GameWorld]'s boot
## gate duck-types this method on every injected-tier module after calling
## `setup()` -- a non-empty result triggers the same terminal boot-halt path
## used for every other config's blocking invariant, no new severity model.
func get_boot_blocking_issues() -> Array[String]:
	return _boot_blocking_issues


## Builds (or rebuilds) the whole-chunk [ArrayMesh] for [param chunk_coord]
## from [member grid]'s CURRENT cell data -- the ONE mesher construction site
## (class doc comment). Creates the chunk's [MeshInstance3D] child on first
## call; subsequent calls reuse it and simply replace `.mesh` (ADR-0014
## Decision Section 2: "rebuilt whole on any cell change"). A chunk with zero
## exposed faces (fully empty, or fully buried with no border to air) gets
## `.mesh = null` -- the [MeshInstance3D] itself is kept (never freed), since
## chunk-instance lifecycle/unloading is Story 015's concern, not this
## method's.
func build_chunk(chunk_coord: Vector2i) -> void:
	assert(grid != null, "VoxelWorldMesher.grid not wired")
	assert(grid.config != null, "VoxelWorldMesher.grid.config not wired")
	assert(appearance != null, "VoxelWorldMesher.appearance not wired")
	var arrays: Array = _build_chunk_arrays(chunk_coord)
	var mesh_instance: MeshInstance3D = _get_or_create_chunk_node(chunk_coord)
	if arrays.is_empty():
		mesh_instance.mesh = null
		return
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _material)
	mesh_instance.mesh = mesh


## Returns the tracked [MeshInstance3D] for [param chunk_coord], or `null` if
## [method build_chunk] was never called for it.
func get_chunk_mesh_instance(chunk_coord: Vector2i) -> MeshInstance3D:
	return _chunk_nodes.get(chunk_coord)


## Whether [param chunk_coord] has ever been passed to [method build_chunk]
## -- the "already tracked" gate the change/residency-signal handlers check
## before marking dirty (Scope note; Story vox-020).
func is_chunk_tracked(chunk_coord: Vector2i) -> bool:
	return _chunk_nodes.has(chunk_coord)


## Every chunk coordinate CURRENTLY tracked (class doc comment, Story vox-015)
## -- snapshotted into a plain array, mirroring [method
## VoxelWorldGrid.get_resident_chunk_keys]'s identical "current key set"
## shape. [VoxelWorldMeshStreamer] uses this to compute which tracked chunks
## have fallen OUTSIDE the current view window and should be [method
## unload_chunk]'d.
func get_tracked_chunk_keys() -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	for key: Vector2i in _chunk_nodes:
		keys.append(key)
	return keys


## Releases an already-tracked chunk's [MeshInstance3D] (Story vox-015, class
## doc comment) -- the mirror image of [method build_chunk]'s "creates the
## chunk's [MeshInstance3D] child on first call; subsequent calls reuse it":
## this method erases [param chunk_coord]'s [member _chunk_nodes] entry FIRST
## (so a [method is_chunk_tracked] check immediately after this call returns
## `false`, and a LATER [method build_chunk] call for the same coordinate
## creates a genuinely fresh node rather than reusing one already queued for
## deletion), then [method Node.queue_free]s the node itself -- never
## [method Object.free] directly, matching this engine's standard safe-removal
## discipline for a node that may still be mid-frame elsewhere in the
## [SceneTree]. A no-op (no error, nothing to free) if [param chunk_coord] was
## never tracked in the first place -- the same lenient "erase what may not be
## there" tolerance [VoxelWorldMeshStreamer]'s own budgeted retry logic relies
## on (an already-unloaded chunk showing up in a stale worklist is harmless).
##
## Calling THIS method for many chunks in a single frame is exactly the
## "queue_free burst" the Control Manifest forbids (ADR-0014 Context: "the
## prototype's one 133 ms hitch came from an unload burst") -- staggering
## across frames is entirely [VoxelWorldMeshStreamer]'s own per-frame time-
## budget responsibility, never this method's; this method itself performs no
## staggering or budgeting of any kind.
func unload_chunk(chunk_coord: Vector2i) -> void:
	if not _chunk_nodes.has(chunk_coord):
		return
	var mesh_instance: MeshInstance3D = _chunk_nodes[chunk_coord]
	_chunk_nodes.erase(chunk_coord)
	_dirty_chunks.erase(chunk_coord)  # Story vox-020, AC-UNLOAD-CLEARS-DIRTY: no dirty-set persistence across unload
	mesh_instance.queue_free()


## Returns the ONE shared [ShaderMaterial] instance (art-bible SS8.9.1) --
## exposed read-only for tests/tools that need to inspect it (e.g. confirming
## `cull_mode`), never for a caller to assign a second, per-chunk instance.
func get_shared_material() -> ShaderMaterial:
	return _material


## Every chunk key CURRENTLY marked dirty (Story vox-020) -- snapshotted into
## a plain array, mirroring [method get_tracked_chunk_keys]'s identical
## "current key set" shape. [VoxelWorldMeshStreamer]'s rebuild phase drains
## this (filtered to keys still tracked) via [method build_chunk] + [method
## clear_dirty], under its own shared, budgeted drain -- this class performs
## no draining or budgeting of its own.
func get_dirty_chunk_keys() -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	for key: Vector2i in _dirty_chunks:
		keys.append(key)
	return keys


## Erases [param chunk_coord] from the dirty set (Story vox-020) -- called by
## [VoxelWorldMeshStreamer]'s rebuild-phase drain action immediately after
## [method build_chunk] returns, so a key the budget did not reach THIS call
## stays dirty for a later one. A no-op if [param chunk_coord] was not dirty.
func clear_dirty(chunk_coord: Vector2i) -> void:
	_dirty_chunks.erase(chunk_coord)


## Single-cell change reaction (TR-voxel-world-025): marks [param cell]'s own
## chunk dirty if tracked, and its chunk-boundary neighbor(s) if [param cell]
## sits on a chunk edge and that neighboring chunk is ALSO tracked (a
## solid/air change at a chunk's border changes the adjacent chunk's own
## face-culling at that shared boundary -- class doc comment Scope note).
## Story vox-020: marks dirty instead of rebuilding synchronously (D7 Defect
## 1) -- [VoxelWorldMeshStreamer]'s budgeted rebuild phase does the actual
## [method build_chunk] call, later.
func _on_cell_changed(cell: Vector3i, _before: CellContents, _after: CellContents) -> void:
	_mark_tracked_chunks_touched_by(cell)


## Batched-write change reaction (TR-voxel-world-042/025): the same per-cell
## chunk-touching logic as [method _on_cell_changed], applied once per
## changed cell in [param changes] -- marking [member _dirty_chunks] is
## naturally idempotent, so no separate per-batch dedup pass is needed (unlike
## the pre-vox-020 rebuild-now version this replaces).
func _on_cells_changed_batch(changes: Array[CellChangeRecord]) -> void:
	for record: CellChangeRecord in changes:
		_mark_tracked_chunks_touched_by(record.cell)


## Residency page-in reaction (Story vox-020, TR-voxel-world-053, D7 Defect 2):
## marks [param chunk_key] dirty if (and only if) it is already tracked -- a
## chunk this class was never asked to [method build_chunk] gets no
## bookkeeping (AC-UNTRACKED-NO-BOOKKEEPING), and is simply built fresh, with
## correct data, whenever [VoxelWorldMeshStreamer] first tracks it.
func _on_chunk_became_resident(chunk_key: Vector2i) -> void:
	if _chunk_nodes.has(chunk_key):
		_dirty_chunks[chunk_key] = true


## Marks every tracked chunk [param cell] touches (its own chunk, plus a
## chunk-boundary neighbor if applicable) dirty -- the single-cell path's
## version of [method _on_cells_changed_batch]'s per-record loop.
func _mark_tracked_chunks_touched_by(cell: Vector3i) -> void:
	for key: Vector2i in _chunk_keys_touched_by(cell):
		if _chunk_nodes.has(key):
			_dirty_chunks[key] = true


## Returns every chunk coordinate [param cell] can affect the MESH of: its
## own chunk, always -- plus the chunk across a chunk boundary when [param
## cell] sits on that boundary's outermost local index (matching
## [VoxelWorldGrid.CHUNK_SIZE] / that class's own chunk-key formula).
func _chunk_keys_touched_by(cell: Vector3i) -> Array[Vector2i]:
	var chunk_size: int = VoxelWorldGrid.CHUNK_SIZE
	var own_key := Vector2i(cell.x / chunk_size, cell.z / chunk_size)
	var keys: Array[Vector2i] = [own_key]
	var local_x: int = cell.x - own_key.x * chunk_size
	var local_z: int = cell.z - own_key.y * chunk_size
	if local_x == 0:
		keys.append(Vector2i(own_key.x - 1, own_key.y))
	elif local_x == chunk_size - 1:
		keys.append(Vector2i(own_key.x + 1, own_key.y))
	if local_z == 0:
		keys.append(Vector2i(own_key.x, own_key.y - 1))
	elif local_z == chunk_size - 1:
		keys.append(Vector2i(own_key.x, own_key.y + 1))
	return keys


## Returns the [MeshInstance3D] child tracked for [param chunk_coord],
## creating and adding it (and registering it in [member _chunk_nodes]) on
## first call.
func _get_or_create_chunk_node(chunk_coord: Vector2i) -> MeshInstance3D:
	if _chunk_nodes.has(chunk_coord):
		return _chunk_nodes[chunk_coord]
	var mesh_instance := MeshInstance3D.new()
	add_child(mesh_instance)
	_chunk_nodes[chunk_coord] = mesh_instance
	return mesh_instance


## Face-culled geometry pass for one chunk (ADR-0014 Decision Section 2:
## "faces emitted only where a cell borders air") -- Story vox-019's
## profile-confirmed READ-LOOP OPTIMIZATION of what used to be ~8,448
## per-cell [method VoxelWorldGrid.get_cell] calls (root cause,
## `production/qa/evidence/voxel-world-60fps-culling-evidence-20260725.md`;
## before/after cost captured in
## `production/qa/evidence/voxel-world-60fps-culling-evidence-[date].md`).
##
## Consumes [method VoxelWorldGrid.get_chunk_snapshot]'s bulk, read-only
## [VoxelWorldGrid.ChunkSnapshot] ONCE per chunk and walks it via DIRECT
## array indexing ([method VoxelWorldGrid.local_offset]) instead of one
## [method VoxelWorldGrid.get_cell] call (bounds check + chunk-dict lookup +
## a fresh [CellContents] allocation) per cell -- both for the cell's own
## solid/air test AND for its +Y/-Y and WITHIN-chunk +X/-X/+Z/-Z neighbor
## tests. A chunk with no [VoxelWorldGrid.ChunkSnapshot] (never touched, or
## not currently resident) short-circuits to the empty-mesh contract
## immediately -- the exact "all air" result [method VoxelWorldGrid.get_cell]
## itself would have produced for every one of that chunk's cells, just
## without walking a single one of them.
##
## The only remaining [method VoxelWorldGrid.get_cell] calls are [method
## _is_air]'s, retained EXCLUSIVELY for a face whose neighbor steps OUTSIDE
## this chunk's own local bounds (a genuine chunk-border crossing into a
## NEIGHBORING chunk, or a world X/Z edge) -- a small minority of the total
## face tests, and the one case this method cannot resolve from its own
## snapshot alone. [method _is_chunk_local_air] is the single dispatch point
## deciding, per face, which of the two paths applies -- see its own doc
## comment for the full case breakdown and why each case is provably
## equivalent to the pre-optimization per-cell behavior (TR-voxel-world-052
## regression guard: `tests/unit/voxel_world/mesher_bulk_read_equivalence_test.gd`
## asserts old-vs-new byte-identical output on a fixture chunk that exercises
## BOTH paths, including a chunk-border cell).
##
## Emission order is UNCHANGED from the pre-optimization loop -- local_x ->
## local_z -> local_y -> face_index, fan-triangulated `(0,1,2)+(0,2,3)` via
## the SAME [method _append_face] -- this is load-bearing for the
## equivalence test's byte-for-byte array comparison. Returns an empty
## [Array] (never a populated-but-zero-length arrays [Array]) when the chunk
## has zero exposed faces -- [method build_chunk]'s empty-mesh contract
## depends on this exact return shape, unchanged from before this story.
##
## THE ONE mesher geometry-assembly site (class doc comment) -- no other
## method in this class or file builds triangle data.
func _build_chunk_arrays(chunk_coord: Vector2i) -> Array:
	var chunk_size: int = VoxelWorldGrid.CHUNK_SIZE
	var snapshot: VoxelWorldGrid.ChunkSnapshot = grid.get_chunk_snapshot(chunk_coord)
	if snapshot == null:
		return []
	var block_type_ids: PackedByteArray = snapshot.block_type_ids
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for local_x in chunk_size:
		var global_x: int = chunk_coord.x * chunk_size + local_x
		for local_z in chunk_size:
			var global_z: int = chunk_coord.y * chunk_size + local_z
			for local_y in snapshot.height:
				var offset: int = VoxelWorldGrid.local_offset(local_x, local_y, local_z)
				var block_type_id: int = block_type_ids[offset]
				if block_type_id == CellContents.EMPTY_BLOCK_TYPE_ID:
					continue
				var global_y: int = snapshot.min_y + local_y
				var cell := Vector3i(global_x, global_y, global_z)
				var color: Color = appearance.get_color(block_type_id, DEBUG_UNKNOWN_COLOR)
				for face_index in FACE_NORMALS.size():
					if _is_chunk_local_air(snapshot, block_type_ids, chunk_size, local_x, local_y, local_z, cell, face_index):
						_append_face(verts, normals, colors, indices, cell, face_index, color)
	if verts.is_empty():
		return []
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


## Story vox-019's per-face air/solid dispatch: resolves [param face_index]'s
## neighbor of the cell at chunk-local `(local_x, local_y, local_z)`
## (chunk-local coordinate; [param cell] is the SAME cell's already-computed
## GLOBAL coordinate, passed through only for the border-fallback case
## below) via exactly one of three provably-equivalent paths:
##
## 1. **Vertical neighbor steps outside [param snapshot]'s own [member
##    VoxelWorldGrid.ChunkSnapshot.height]** (`local_y + FACE_NORMALS[i].y`
##    below `0` or `>= height`) -- this chunk spans the world's FULL
##    configured vertical extent (no vertical chunking, class doc comment),
##    so stepping outside `[0, height)` here means stepping outside
##    `[min_y, max_y]` -- a genuine world Y-bound miss. [method
##    VoxelWorldGrid.get_cell] would return `null` for that global cell
##    (Core Rule 1) -- treated as air. Resolved directly as air, with ZERO
##    [method VoxelWorldGrid.get_cell] calls.
## 2. **Horizontal neighbor (+X/-X/+Z/-Z) stays WITHIN [param chunk_size]'s
##    local bounds** -- the overwhelming majority of face tests (every
##    interior cell, every face). Read directly from [param
##    block_type_ids] via [method VoxelWorldGrid.local_offset] -- the EXACT
##    same buffer element [method VoxelWorldGrid.get_cell] would have read
##    for that global cell (same chunk, same offset formula), so this is
##    byte-identical BY CONSTRUCTION, not merely "usually the same result."
## 3. **Horizontal neighbor steps OUTSIDE [param chunk_size]'s local
##    bounds** -- a genuine chunk-border crossing into a NEIGHBORING chunk,
##    or a world X/Z edge. Falls back to [method _is_air] (unchanged,
##    [method VoxelWorldGrid.get_cell]-based) -- the ONE remaining per-face
##    [method VoxelWorldGrid.get_cell] call site in this class, deliberately
##    retained because it is a small minority of the total face-test volume
##    (only cells on a chunk's outer local-x/local-z edge ever reach it) and
##    because it is EXACTLY the pre-optimization code path, so its behavior
##    (including any residency page-in [method VoxelWorldGrid.get_cell]
##    itself may trigger) is unchanged, not reimplemented.
func _is_chunk_local_air(
		snapshot: VoxelWorldGrid.ChunkSnapshot, block_type_ids: PackedByteArray, chunk_size: int,
		local_x: int, local_y: int, local_z: int, cell: Vector3i, face_index: int
) -> bool:
	var normal: Vector3i = FACE_NORMALS[face_index]
	var neighbor_local_y: int = local_y + normal.y
	if neighbor_local_y < 0 or neighbor_local_y >= snapshot.height:
		return true
	var neighbor_local_x: int = local_x + normal.x
	var neighbor_local_z: int = local_z + normal.z
	if neighbor_local_x < 0 or neighbor_local_x >= chunk_size or neighbor_local_z < 0 or neighbor_local_z >= chunk_size:
		return _is_air(cell + normal)
	var offset: int = VoxelWorldGrid.local_offset(neighbor_local_x, neighbor_local_y, neighbor_local_z)
	return block_type_ids[offset] == CellContents.EMPTY_BLOCK_TYPE_ID


## Air/solid predicate for face-culling (ADR-0014 Decision Section 2): a cell
## OUTSIDE the configured world bounds ([method VoxelWorldGrid.get_cell]
## returns `null`) counts as air. Story vox-019: retained EXCLUSIVELY as the
## chunk-border/world-X/Z-edge fallback [method _is_chunk_local_air] calls --
## no longer called for every cell's own solid test or for a within-chunk
## neighbor (both now resolved directly from the bulk [VoxelWorldGrid.ChunkSnapshot]
## -- see that method's doc comment).
func _is_air(cell: Vector3i) -> bool:
	var contents: CellContents = grid.get_cell(cell)
	return contents == null or contents.is_empty()


## Appends one face's two triangles (4 shared corner vertices, fan-
## triangulated) to the in-progress mesh arrays. [param face_index] indexes
## both [constant FACE_NORMALS] and [constant FACE_CORNERS] -- see that
## constant's doc comment for the winding derivation this method's fixed
## `(0,1,2)` + `(0,2,3)` triangulation relies on.
func _append_face(verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array,
		cell: Vector3i, face_index: int, color: Color) -> void:
	var base: int = verts.size()
	var normal := Vector3(FACE_NORMALS[face_index])
	var corners: Array = FACE_CORNERS[face_index]
	for corner: Vector3i in corners:
		verts.append((Vector3(cell) + Vector3(corner)) * VoxelWorldConfig.CELL_SIZE)
		normals.append(normal)
		colors.append(color)
	indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])


## Constructs the ONE shared [ShaderMaterial] instance every chunk's surface
## uses (see [member _material]'s doc comment).
## `res://assets/shaders/terrain_chunk.gdshader` ships `cull_back` explicitly
## (never `cull_disabled`) -- see that shader file's own doc comment and
## `mesher_material_contract_test.gd`'s grep guard.
func _build_shared_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/terrain_chunk.gdshader")
	return material
