## Voxel World's mesh VIEW-WINDOW streaming (Story vox-015, ADR-0014 Decision
## Section 3 primary / ADR-0015 Decision Section 1 secondary; TR-voxel-world-
## 025/026).
##
## Owns exactly the decision [VoxelWorldMesher]'s own class doc comment
## explicitly defers: WHICH chunks are meshed as the camera moves. This class
## never builds triangle data itself (THE ONE mesher construction site
## remains [method VoxelWorldMesher._build_chunk_arrays], unchanged) -- it
## only decides chunk MEMBERSHIP each call: which chunks should now be
## tracked ([method VoxelWorldMesher.build_chunk]) and which tracked chunks
## should now be released ([method VoxelWorldMesher.unload_chunk]), both
## bounded by a PER-FRAME TIME BUDGET (never a fixed chunks-per-frame count --
## ADR-0015 Decision Section 1's time-based streaming discipline, reused here
## for the mesh tier exactly as Story vox-012 already applied it to the data
## residency tier) so neither a build burst nor an unload burst (the
## prototype's one 133 ms hitch, ADR-0014 Context) can spike a single frame.
##
## The mesh view window is DISTINCT from Story vox-010's data residency
## window (packed-array [CellContents] bytes vs. [ArrayMesh] GPU resources) --
## but [member VoxelWorldConfig.view_radius_chunks] is the SAME knob both
## windows read (that config field's own doc comment names this exact
## reconciliation). A camera-near chunk is therefore always mesh-window-
## desired whenever it is residency-desired (same radius, same focus
## concept) -- though the two windows can still observe different MEMBERSHIP
## at any instant, since residency additionally unions in the active-
## settlement window (Story vox-010) that this class deliberately does not
## (a settlement chunk outside camera view has no mesh to show regardless of
## Villager AI needing its DATA resident) -- consistent with ADR-0014
## Decision Section 3's plain "view radius" (no settlement union) versus
## ADR-0015 Decision Section 1's richer "camera-near UNION active-settlement"
## set.
##
## Two entry points, ONE shared window-sync implementation ([method
## _sync_window]):
## - [method build_initial_window]: UNBOUNDED (no budget) -- the initial
##   view-window mesh build ADR-0005/ADR-0015's boot-timing notes and this
##   story's own AC-3 require to run BEHIND Scene/World Management's
##   transition overlay, not on a visible frozen frame. A caller (Scene/World
##   Management's boot sequence) calls this once per session, before the
##   transition overlay lifts. Story vox-021 (TD ruling Addendum D / D2):
##   this entry point's radius is [member
##   VoxelWorldConfig.boot_mesh_radius_chunks] -- deliberately SMALLER than
##   [member VoxelWorldConfig.view_radius_chunks] -- so the boot-time freeze
##   this method's own synchronous, unbounded nature would otherwise impose at
##   the measured 7.7 ms/chunk mesh-build cost stays inside the 2.5 s boot
##   mesh-phase ceiling; the window then grows to the full steady-state
##   radius over subsequent frames via [method update_view_window]'s own
##   ALREADY-budgeted path, never a second growth mechanism.
## - [method update_view_window]: budgeted -- this entry point's radius is
##   [member VoxelWorldConfig.view_radius_chunks], unchanged by vox-021 --
##   [member
##   VoxelWorldConfig.mesh_build_budget_ms] bounds a SINGLE shared drain
##   covering BOTH the rebuild phase and the build-new phase (Story vox-020,
##   TD ruling Addendum D §D7 -- see below), [member
##   VoxelWorldConfig.mesh_unload_budget_ms] bounds its own separate unload
##   phase, each re-checked after every single processed item (never before
##   the first -- the same "progress guaranteed" contract [method
##   VoxelWorldGrid._drain_budgeted] established) -- the per-frame streaming
##   step a live game loop calls every frame with the current camera focus
##   cell. Wiring this into `Valley`'s live per-frame loop (an actual
##   [CameraInput] focus point, continuously) is deliberately OUT of this
##   story's scope -- the same precedent Story vox-010 through vox-014 set
##   for [method VoxelWorldGrid.update_residency] itself, which remains
##   unwired in production to date. The 60 FPS-with-culling MEASUREMENT this
##   story unlocks (milestone criterion #12) is explicitly a LATER story's
##   job (story header Engine Notes / Dependencies), not this one's -- the
##   mechanism proven correct by this class's own tests IS this story's
##   scope.
##
## Story vox-020 (this revision, TD ruling Addendum D §D7; ADR-0014 amendment
## Decision §3): [method _sync_window] gains a REBUILD phase -- draining
## [method VoxelWorldMesher.get_dirty_chunk_keys] (filtered to keys still
## tracked) -- drained FIRST, strictly before the build-new phase and strictly
## before the unload phase (the player's own edit is always the most
## recently-relevant geometry on screen; a window-edge chunk they are driving
## toward is not). The rebuild phase and the build-new phase are drained
## through ONE COMBINED item list and ONE shared `(start_usec, budget_usec)`
## window -- rebuild keys first, build keys after -- rather than two
## independent [method _drain_budgeted] calls: two independent calls would
## each carry their OWN "first item always integrates" progress guarantee,
## which at the measured ~7.7 ms/chunk cost against the 4.0 ms budget would
## integrate one chunk in EACH phase (worst case 7.7 + 7.7 = 15.4 ms, a
## regression of vox-019's measured 16.947 ms p95). ONE combined list makes the
## progress guarantee fire exactly ONCE per call, so the worst case stays
## exactly one chunk meshed per frame -- today's measured profile -- while
## still giving a dirty chunk priority ordering over a newly-desired one. NO
## NEW BUDGET KNOB exists for the rebuild phase -- it reuses [member
## VoxelWorldConfig.mesh_build_budget_ms] exactly as named above; the unload
## phase's separate window is unaffected (a different work class,
## `queue_free`, not meshing).
class_name VoxelWorldMeshStreamer
extends Node

## Voxel World / Grid Data dependency (ADR-0001 injected-tier) -- supplies
## both [method VoxelWorldGrid.chunk_key_for_cell] (window-center math) and
## [member VoxelWorldGrid.config] (the SAME [VoxelWorldConfig] instance
## [member mesher] itself reads, per the class doc comment's reconciliation
## note). Wired via a scene file's Inspector in production, or assigned
## directly in a headless test/tool -- never read inside `_ready()` (see
## [method setup]).
@export var grid: VoxelWorldGrid

## Voxel World mesher dependency (ADR-0001 injected-tier) -- the ONLY class
## this streamer ever calls [method VoxelWorldMesher.build_chunk] / [method
## VoxelWorldMesher.unload_chunk] on. Wired identically to [member grid] --
## see that member's doc comment.
@export var mesher: VoxelWorldMesher

## True once [method setup] has completed.
var _is_set_up: bool = false

## Injectable elapsed-time source (mirrors [VoxelWorldGrid]'s own private
## `_time_source_usec` field exactly, Story vox-012 precedent) for [method
## _drain_budgeted]'s per-item budget re-check -- a zero-arg [Callable]
## returning microseconds as an `int`, defaulting to the real engine wall
## clock ([Time.get_ticks_usec]). Tests override this via [method
## set_time_source_for_test] with a deterministic fake clock so budget-driven
## stop/defer behavior can be asserted precisely without any real sleep or
## wall-clock-dependent assertion (QA determinism rule) -- production code
## never calls the setter, so production always measures real elapsed time.
var _time_source_usec: Callable = Callable(Time, "get_ticks_usec")


## Explicitly callable wiring entry point (ADR-0001). Asserts [member grid],
## [member mesher], and [member grid]'s own wired [VoxelWorldConfig] are all
## present.
func setup() -> void:
	assert(grid != null, "VoxelWorldMeshStreamer.grid not wired")
	assert(mesher != null, "VoxelWorldMeshStreamer.mesher not wired")
	assert(grid.config != null, "VoxelWorldMeshStreamer.grid.config not wired")
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Test-only override for [member _time_source_usec] -- see that member's doc
## comment. Never called from production code.
func set_time_source_for_test(source: Callable) -> void:
	_time_source_usec = source


## UNBOUNDED initial view-window build (AC-3, TR-voxel-world-026) -- meshes
## every chunk in [param camera_focus_cell]'s view window synchronously, with
## no per-frame budget, so a caller can complete it entirely BEHIND Scene/
## World Management's transition overlay before the first visible frame.
## Reuses the exact same window-membership/build logic [method
## update_view_window] uses every subsequent frame (the "same tested code
## path, different budget" design [VoxelWorldGrid]'s own
## `wait_for_async_residency_idle` escape hatch already established) -- never
## a second, parallel meshing implementation. Deliberately ignores [member
## VoxelWorldConfig.mesh_build_budget_ms]/[member
## VoxelWorldConfig.mesh_unload_budget_ms] entirely -- not merely a very
## generous reading of them.
##
## Story vox-021 (TD ruling Addendum D / D2): the ONE call site of [member
## VoxelWorldConfig.boot_mesh_radius_chunks] -- passed as [method
## _sync_window]'s radius parameter, distinct from [method update_view_window]'s
## own [member VoxelWorldConfig.view_radius_chunks] radius. This is what makes
## the boot-time window SMALLER than the steady-state window it later grows
## into (via [method update_view_window]'s own already-budgeted per-frame
## path -- no new growth mechanism).
func build_initial_window(camera_focus_cell: Vector3i) -> void:
	assert(grid != null, "VoxelWorldMeshStreamer.grid not wired")
	assert(grid.config != null, "VoxelWorldMeshStreamer.grid.config not wired")
	_sync_window(camera_focus_cell, -1.0, -1.0, grid.config.boot_mesh_radius_chunks)


## Budgeted per-frame streaming step (AC-1/AC-2, TR-voxel-world-025) -- a live
## game loop calls this every frame with the CURRENT camera focus cell.
## Builds newly-entered chunks bounded by [member
## VoxelWorldConfig.mesh_build_budget_ms] and unloads chunks that left the
## window bounded by [member VoxelWorldConfig.mesh_unload_budget_ms] -- see
## the class doc comment for why wiring this into a live per-frame loop is
## out of this story's own scope (the mechanism itself, proven by tests
## calling this directly, IS the scope).
func update_view_window(camera_focus_cell: Vector3i) -> void:
	assert(grid != null, "VoxelWorldMeshStreamer.grid not wired")
	assert(grid.config != null, "VoxelWorldMeshStreamer.grid.config not wired")
	_sync_window(camera_focus_cell, grid.config.mesh_build_budget_ms, grid.config.mesh_unload_budget_ms, grid.config.view_radius_chunks)


## Every chunk key the CURRENT STEADY-STATE view window desires around [param
## camera_focus_cell] -- test/tool introspection convenience exposing the
## exact same computation [method _sync_window] performs internally for
## [method update_view_window], not itself part of the streaming algorithm's
## build/unload side effects. Story vox-021: deliberately ALWAYS reads [member
## VoxelWorldConfig.view_radius_chunks], never [member
## VoxelWorldConfig.boot_mesh_radius_chunks] -- this method's meaning is
## "the steady-state window", and callers/tests must not overload it with the
## boot radius (that radius has no public introspection getter of its own;
## [method build_initial_window]'s own effect is the only place it is
## observable).
func get_desired_window_keys(camera_focus_cell: Vector3i) -> Array[Vector2i]:
	assert(grid != null, "VoxelWorldMeshStreamer.grid not wired")
	assert(grid.config != null, "VoxelWorldMeshStreamer.grid.config not wired")
	var desired: Dictionary[Vector2i, bool] = {}
	_collect_window(desired, _center_key(camera_focus_cell), grid.config.view_radius_chunks)
	var keys: Array[Vector2i] = []
	for key: Vector2i in desired:
		keys.append(key)
	return keys


## Shared window-sync implementation (class doc comment) -- computes the
## desired chunk set from [param camera_focus_cell] and [param radius] (Story
## vox-021: the caller-supplied radius, [member
## VoxelWorldConfig.view_radius_chunks] from [method update_view_window] --
## the SAME radius knob [VoxelWorldGrid] itself reads for data residency's own
## camera-near half, per that config field's own reconciliation note -- or
## [member VoxelWorldConfig.boot_mesh_radius_chunks] from [method
## build_initial_window]; this method itself is radius-agnostic, never reading
## either config field directly), then:
## 1. Rebuilds every dirty, still-tracked chunk ([method
##    VoxelWorldMesher.get_dirty_chunk_keys], filtered) and builds every
##    desired chunk NOT already tracked ([method VoxelWorldMesher.build_chunk]
##    for both), as ONE combined list -- rebuild keys first (AC-REBUILD-FIRST)
##    -- drained through ONE shared `(start_usec, budget_usec)` window derived
##    from [param build_budget_ms] (see class doc comment's vox-020 paragraph
##    for why this must be one combined drain, not two independent ones).
##    [method VoxelWorldMesher.clear_dirty] is called immediately after a
##    rebuilt key's [method VoxelWorldMesher.build_chunk] returns (a key the
##    budget does not reach THIS call stays dirty for a later one). A newly
##    built (not rebuilt) chunk's [MeshInstance3D] gets [member
##    MeshInstance3D.visibility_range_end] set (ADR-0014 Decision Section 3,
##    Control Manifest Required) via [method _visibility_range_end] -- a value
##    DERIVED from [member VoxelWorldConfig.view_radius_chunks], never a
##    hardcoded literal; a rebuilt chunk's [member
##    MeshInstance3D.visibility_range_end] is left untouched (already set the
##    call it was first built).
## 2. Unloads every chunk [member mesher] currently tracks that is NOT in the
##    desired set ([method VoxelWorldMesher.unload_chunk]), bounded by [param
##    unload_budget_ms] in its OWN separate window, with the identical
##    per-item re-check discipline -- this IS the staggering the Control
##    Manifest's "never a queue_free burst" Forbidden rule requires: at most
##    as many `unload_chunk` calls as the budget allows land in a single call
##    to this method; any excess is left tracked, untouched, and simply
##    retried the NEXT call (exactly [VoxelWorldGrid]'s own "excess defers to
##    a later frame" contract).
##
## [param build_budget_ms] / [param unload_budget_ms] `< 0.0` means UNBOUNDED
## -- every item is processed regardless of elapsed time (see [method
## build_initial_window]) -- the rebuild-then-build combined list included,
## so [method build_initial_window]'s boot contract covers both (AC-BOOT-
## UNBOUNDED); harmless in practice since the dirty set is always empty at
## boot (nothing has been marked dirty yet).
func _sync_window(camera_focus_cell: Vector3i, build_budget_ms: float, unload_budget_ms: float, radius: int) -> void:
	assert(grid != null, "VoxelWorldMeshStreamer.grid not wired")
	assert(mesher != null, "VoxelWorldMeshStreamer.mesher not wired")
	assert(grid.config != null, "VoxelWorldMeshStreamer.grid.config not wired")

	var desired: Dictionary[Vector2i, bool] = {}
	_collect_window(desired, _center_key(camera_focus_cell), radius)
	# NOTE: visibility_range_end stays derived from view_radius_chunks alone
	# (AC-VISIBILITY-RANGE-DERIVED), regardless of which radius built this
	# particular window -- the distance fade is a STEADY-STATE property, so a
	# chunk built at the smaller boot radius still fades at the same distance
	# a chunk built later via update_view_window would.
	var range_end: float = _visibility_range_end()

	var to_rebuild: Array[Vector2i] = []
	for key: Vector2i in mesher.get_dirty_chunk_keys():
		if mesher.is_chunk_tracked(key):
			to_rebuild.append(key)
	var to_build: Array[Vector2i] = []
	for key: Vector2i in desired:
		if not mesher.is_chunk_tracked(key):
			to_build.append(key)
	# ONE combined list, rebuild keys first -- see this method's own doc
	# comment / class doc comment's vox-020 paragraph for why this must not be
	# two independent _drain_budgeted calls.
	var to_mesh: Array[Vector2i] = []
	to_mesh.append_array(to_rebuild)
	to_mesh.append_array(to_build)
	var build_start_usec: int = _now_usec()
	_drain_budgeted(to_mesh, build_start_usec, _budget_usec(build_budget_ms), func(key: Vector2i) -> void:
		var is_rebuild: bool = mesher.is_chunk_tracked(key)
		mesher.build_chunk(key)
		if is_rebuild:
			mesher.clear_dirty(key)
		else:
			var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(key)
			if mesh_instance != null:
				mesh_instance.visibility_range_end = range_end
	)

	var to_unload: Array[Vector2i] = []
	for key: Vector2i in mesher.get_tracked_chunk_keys():
		if not desired.has(key):
			to_unload.append(key)
	var unload_start_usec: int = _now_usec()
	_drain_budgeted(to_unload, unload_start_usec, _budget_usec(unload_budget_ms), func(key: Vector2i) -> void:
		mesher.unload_chunk(key)
	)


## [param camera_focus_cell]'s chunk coordinate, via [method
## VoxelWorldGrid.chunk_key_for_cell] -- the SAME chunk-key formula [member
## grid] itself uses internally, never a second copy of the `/ CHUNK_SIZE`
## math.
func _center_key(camera_focus_cell: Vector3i) -> Vector2i:
	return grid.chunk_key_for_cell(camera_focus_cell)


## The square view-window chunk set around [param center], radius [param
## radius] (Story vox-021: caller-supplied -- [member
## VoxelWorldConfig.view_radius_chunks] or [member
## VoxelWorldConfig.boot_mesh_radius_chunks] depending on caller, see [method
## _sync_window]'s own doc comment; this method reads neither config field
## directly), bounds-filtered against the configured world extent -- mirrors
## [VoxelWorldGrid]'s own private `_collect_window`/`_is_chunk_in_world` shape
## exactly (that pair is private to [VoxelWorldGrid], so this is a deliberate,
## behavior-identical local copy rather than a cross-class private call).
## Populates [param desired] in place, matching that same private method's
## in/out-parameter signature.
func _collect_window(desired: Dictionary[Vector2i, bool], center: Vector2i, radius: int) -> void:
	for dz in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var candidate := center + Vector2i(dx, dz)
			if _is_chunk_in_world(candidate):
				desired[candidate] = true


## True if [param chunk_key] has at least one cell inside the configured
## world bounds -- see [method _collect_window]'s doc comment for why this is
## a deliberate local copy of [VoxelWorldGrid]'s identical private logic.
func _is_chunk_in_world(chunk_key: Vector2i) -> bool:
	return (
		chunk_key.x >= 0 and chunk_key.x * VoxelWorldGrid.CHUNK_SIZE < grid.config.world_width_cells
		and chunk_key.y >= 0 and chunk_key.y * VoxelWorldGrid.CHUNK_SIZE < grid.config.world_depth_cells
	)


## Distance-culling radius for [member MeshInstance3D.visibility_range_end]
## (ADR-0014 Decision Section 3, Control Manifest Required) -- DERIVED from
## [member VoxelWorldConfig.view_radius_chunks] (never a hardcoded literal,
## Control Manifest "no hardcoded values" precedent), converted to world
## units via [constant VoxelWorldGrid.CHUNK_SIZE] and [constant
## VoxelWorldConfig.CELL_SIZE] -- the exact radius (in world units) the mesh
## view window itself spans, so a chunk fades out of visibility distance
## right around where the streaming window would unload it anyway.
func _visibility_range_end() -> float:
	return VoxelWorldMeshStreamer.compute_visibility_range_end(grid.config.view_radius_chunks)


## Pure counterpart of [method _visibility_range_end] -- see that method's
## doc comment. `view_radius_chunks * CHUNK_SIZE * CELL_SIZE` (world units).
## Stateless -- exercisable directly with any `int`, without an instance.
static func compute_visibility_range_end(view_radius_chunks: int) -> float:
	return float(view_radius_chunks * VoxelWorldGrid.CHUNK_SIZE) * VoxelWorldConfig.CELL_SIZE


## Current elapsed-time reading in microseconds -- see [member
## _time_source_usec]'s doc comment.
func _now_usec() -> int:
	return _time_source_usec.call()


## Converts a millisecond budget knob to the microsecond unit [method
## _drain_budgeted] compares against. `< 0.0` (see [method _sync_window]'s
## UNBOUNDED contract) maps to `-1` -- [method _drain_budgeted]'s own
## unbounded sentinel.
func _budget_usec(budget_ms: float) -> int:
	if budget_ms < 0.0:
		return -1
	return int(budget_ms * 1000.0)


## Generic per-item time-budget drain -- BEHAVIOR-IDENTICAL copy of
## [VoxelWorldGrid]'s own private `_drain_budgeted` (that method is private to
## [VoxelWorldGrid]; duplicated here rather than exposed cross-class, the
## same deliberate-local-copy rationale as [method _collect_window]). Invokes
## [param action] once per entry of [param items], in order, re-checking
## elapsed time against [param budget_usec] (elapsed since [param
## start_usec]) AFTER every single invocation -- never BEFORE the first, so
## the first item in any batch is always processed unconditionally (a single
## item that alone exceeds the budget is still integrated, then the loop
## stops -- the progress guarantee). [param budget_usec] `< 0` means
## UNBOUNDED -- every item in [param items] is processed regardless of
## elapsed time, and [method _now_usec] is never even called.
func _drain_budgeted(items: Array, start_usec: int, budget_usec: int, action: Callable) -> void:
	if budget_usec < 0:
		for item in items:
			action.call(item)
		return
	var exceeded: bool = false
	for item in items:
		if exceeded:
			break
		action.call(item)
		exceeded = (_now_usec() - start_usec) >= budget_usec
