## Integration test — Villager AI story villager-ai-008 (incremental AStar3D
## graph patching on Voxel World writes, incl. dig-order writes; ADR-0007
## Decision Section 2 primary, ADR-0009 synchronous-signal race closure
## secondary).
##
## Proves, against [VillagerNavGraph.patch_cell]/[VillagerNavGraph.
## patch_cells]/[VillagerNavGraph.subscribe_to_voxel_world],
## [VillagerRepathFilter], and [VillagerAi.evaluate_repath_trigger]:
## 1. **AC1 (incremental patch)**: a `cell_changed` write that turns a
##    standable cell solid patches ONLY that cell's neighborhood — a
##    spurious point injected far away (one [VillagerAi.is_standable] would
##    never itself produce) survives the patch untouched, proving no full
##    `_astar.clear()`/rebuild ever happens.
## 2. **AC2 (dig write)**: a dig/demolition-shaped write (solid -> air)
##    patches through the IDENTICAL code path as a build write — no
##    special-casing, no separate API.
## 3. **Idempotent IDs**: re-adding a previously-removed cell reuses the
##    exact same deterministic `AStar3D` point id (never a counter).
## 4. **Race closure / no `CONNECT_DEFERRED`**: [method
##    VillagerNavGraph.subscribe_to_voxel_world] patches the graph
##    SYNCHRONOUSLY — visible immediately after a write, no `await`/yield of
##    any kind — and `CONNECT_DEFERRED` is grep-verifiably absent from
##    `src/villager_ai/`'s own code.
## 5. **AC18/AC49 (re-path filter, GDD Rule 10b)**: a write intersecting a
##    moving villager's remaining-movement clearance envelope (the movement
##    cells themselves, the 2 cells above each, or a diagonal step's
##    flankers) fires [signal VillagerAi.repath_evaluation_requested]
##    exactly once (AC18); a write outside that envelope, or any write while
##    the villager is stationary, fires it exactly zero times (AC49) — a
##    batch write intersecting the envelope via only ONE of its many records
##    still fires exactly once, never once per record.
## 6. [VillagerRepathFilter]'s own pure `clearance_envelope`/
##    `changed_cells_intersect_envelope` functions, directly.
##
## NOTE (accumulated pitfall): signal-fire counters use a captured [Array]
## with `.append()`/`.size()`, never a captured scalar `+= 1` inside a
## lambda — GDScript closures do not write back captured scalars
## (established precedent, see `bulk_write_batched_signal_test.gd`).
class_name GraphPatchingTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


## A [VillagerAi] with only [member VillagerAi.voxel_world] wired — enough
## to serve as [VillagerNavGraph]'s `predicate_source` (`is_standable`/
## `is_step_legal`), without needing a full [method VillagerAi.setup] call
## (mirrors `astar_graph_test.gd`'s own `_make_villager_ai` fixture).
func _make_bare_villager_ai(grid: VoxelWorldGrid) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.voxel_world = grid
	return villager_ai


## A fully [method VillagerAi.setup]-ed villager — real signal wiring to
## [param grid]'s `cell_changed`/`cells_changed_batch` (this story's own
## `setup()` addition), needed for the re-path-filter tests below (AC18/49),
## which exercise the actual live signal path, not a direct method call.
func _make_setup_villager(grid: VoxelWorldGrid) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.voxel_world = grid
	villager.scheduler = VillagerDecidingScheduler.new()
	villager.time_tick_system = auto_free(MockTimeTickSystem.new())
	villager.setup()
	return villager


func _solid() -> CellContents:
	return CellContents.new(1, 0)


## Fills a flat, uniform-height standable platform (mirrors
## `astar_graph_test.gd`'s own fixture): solid ground at y=0 for every
## (x, z) in `[0, size)` x `[0, size)`, leaving y=1+ empty — every (x, 1, z)
## in that footprint is standable by construction.
func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), _solid())


# ---------------------------------------------------------------------------
# AC1 — incremental patch: only the affected neighborhood changes, never a
# full rebuild
# ---------------------------------------------------------------------------

func test_patch_cell_adds_point_and_connections_when_a_column_gains_ground() -> void:
	# Arrange — 3x3 flat platform except column (1,0,1) has no ground, so
	# (1,1,1) is not standable at build time.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	grid.clear_cell(Vector3i(1, 0, 1))
	var villager_ai: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)
	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_false()

	# Act — writes ground back under (1,1,1); patch_cell (not a rebuild)
	# must pick this up.
	grid.set_cell(Vector3i(1, 0, 1), _solid())
	graph.patch_cell(villager_ai, Vector3i(1, 0, 1))

	# Assert — the newly-standable cell gained its point and both its
	# orthogonal and diagonal legal-step connections.
	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_true()
	assert_bool(graph.has_direct_connection(Vector3i(0, 1, 1), Vector3i(1, 1, 1))).is_true()
	assert_bool(graph.has_direct_connection(Vector3i(1, 1, 1), Vector3i(2, 1, 2))).is_true()


func test_patch_cell_never_performs_a_full_rebuild_untouched_points_survive() -> void:
	# Arrange — build a small graph, then inject an extra point FAR from
	# where the next patch will land, one [VillagerAi.is_standable] would
	# NEVER itself produce (nothing supports it in the world). A full
	# rebuild (`_astar.clear()` + re-derive from predicate_source) would
	# remove it; a correctly-scoped incremental patch (this story's AC1)
	# has no reason to ever visit it.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)
	var spurious_cell := Vector3i(500, 50, 500)
	var spurious_id: int = VillagerNavGraph.cell_to_astar_id(spurious_cell)
	graph._astar.add_point(spurious_id, VoxelWorldGrid.cell_to_world(spurious_cell))
	assert_bool(graph.has_point(spurious_cell)).is_true()

	# Act — patch a cell far away from the spurious point (well outside any
	# plausible clearance/step neighborhood).
	grid.set_cell(Vector3i(2, 1, 2), _solid())
	graph.patch_cell(villager_ai, Vector3i(2, 1, 2))

	# Assert — the spurious, predicate-source-disagreeing point is still
	# there: this patch never cleared/rebuilt the whole graph.
	assert_bool(graph.has_point(spurious_cell)).is_true()


# ---------------------------------------------------------------------------
# AC2 — dig/demolition writes patch identically to build writes
# ---------------------------------------------------------------------------

func test_patch_cell_removes_point_and_connections_when_a_dig_write_removes_ground() -> void:
	# Arrange — vox-009's dig-order write path is "just a cell write" from
	# this graph's perspective (this story's own scope note) — a fully
	# standable 3x3 flat platform, graph built over it.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)
	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_true()
	assert_bool(graph.has_direct_connection(Vector3i(0, 1, 1), Vector3i(1, 1, 1))).is_true()

	# Act — a dig/demolition write: the ground block under (1,1,1) is
	# removed (solid -> air), through the SAME `set_cell` path a build write
	# uses — no special-cased "dig" API exists at this layer.
	grid.clear_cell(Vector3i(1, 0, 1))
	graph.patch_cell(villager_ai, Vector3i(1, 0, 1))

	# Assert — (1,1,1) lost its standability, point, and every connection
	# (`remove_point()` clears connections automatically); an untouched
	# neighbor stays standable and stays connected to another untouched
	# neighbor.
	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_false()
	assert_bool(graph.has_direct_connection(Vector3i(0, 1, 1), Vector3i(1, 1, 1))).is_false()
	assert_bool(graph.has_point(Vector3i(0, 1, 0))).is_true()
	assert_bool(graph.has_direct_connection(Vector3i(0, 1, 0), Vector3i(0, 1, 1))).is_true()


# ---------------------------------------------------------------------------
# Idempotent IDs — re-adding a previously-removed cell reuses the same id
# ---------------------------------------------------------------------------

func test_patch_re_adding_a_removed_cell_reuses_the_same_deterministic_id() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)
	var cell := Vector3i(1, 1, 1)
	var original_id: int = VillagerNavGraph.cell_to_astar_id(cell)
	assert_bool(graph.has_point(cell)).is_true()

	# Act — remove then re-add the same underlying cell via two patches
	# (a dig write followed by a build write, exactly as a player might undo
	# and redo the same edit).
	grid.clear_cell(Vector3i(1, 0, 1))
	graph.patch_cell(villager_ai, Vector3i(1, 0, 1))
	assert_bool(graph.has_point(cell)).is_false()

	grid.set_cell(Vector3i(1, 0, 1), _solid())
	graph.patch_cell(villager_ai, Vector3i(1, 0, 1))

	# Assert — the SAME deterministic id is in use again (never a fresh
	# incrementing-counter value), and the graph is fully queryable through
	# it: reconnected and path-findable.
	assert_bool(graph.has_point(cell)).is_true()
	assert_int(VillagerNavGraph.cell_to_astar_id(cell)).is_equal(original_id)
	assert_bool(graph.has_direct_connection(Vector3i(0, 1, 1), cell)).is_true()
	var path: Array[Vector3i] = graph.find_path(Vector3i(0, 1, 0), cell)
	assert_array(path).is_not_empty()


# ---------------------------------------------------------------------------
# Race closure — subscribe_to_voxel_world patches synchronously, no
# CONNECT_DEFERRED anywhere in src/villager_ai/
# ---------------------------------------------------------------------------

func test_subscribe_to_voxel_world_patches_synchronously_within_the_same_call() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	grid.clear_cell(Vector3i(1, 0, 1))
	var villager_ai: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)
	graph.subscribe_to_voxel_world(grid, villager_ai)
	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_false()

	# Act — if the subscription used `CONNECT_DEFERRED` the patch would be
	# queued for a later idle-frame flush and NOT yet visible here, in the
	# SAME synchronous call — proving the race-closure assertion (ADR-0009)
	# this story names explicitly.
	grid.set_cell(Vector3i(1, 0, 1), _solid())

	# Assert — already patched, no `await`/yield of any kind needed.
	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_true()


func test_subscribe_to_voxel_world_patches_on_a_bulk_write_batch_signal() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	grid.clear_cell(Vector3i(1, 0, 1))
	var villager_ai: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)
	graph.subscribe_to_voxel_world(grid, villager_ai)

	# Act
	var changes: Dictionary[Vector3i, CellContents] = {Vector3i(1, 0, 1): _solid()}
	grid.bulk_write(changes)

	# Assert
	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_true()


func test_no_connect_deferred_anywhere_in_villager_ai_source() -> void:
	# Grep-verifiable AC (ADR-0009 race closure; this story's own QA-named
	# assertion): `CONNECT_DEFERRED` must be absent from `src/villager_ai/`'s
	# own CODE (comment-stripped) — every signal connection in this
	# directory, old and new, must stay on Godot's default, synchronous
	# flags.
	var source: String = _read_all_gd_source("res://src/villager_ai")

	assert_bool(source.contains("CONNECT_DEFERRED")).is_false()


# ---------------------------------------------------------------------------
# AC18/AC49 — re-path filter (GDD Rule 10b): fires exactly once when a write
# intersects a moving villager's clearance envelope, exactly zero times
# otherwise
# ---------------------------------------------------------------------------

func test_write_outside_moving_villagers_envelope_triggers_zero_repath_evaluations() -> void:
	# Arrange — AC49: a villager mid-step from (0,0,0) to (1,0,0); its
	# clearance envelope covers only a small band around those two cells.
	var grid: VoxelWorldGrid = _make_grid()
	var villager: VillagerAi = _make_setup_villager(grid)
	villager.current_cell = Vector3i(0, 0, 0)
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)
	var repath_calls: Array = []
	villager.repath_evaluation_requested.connect(func() -> void: repath_calls.append(true))

	# Act — a write far away from the step's envelope.
	grid.set_cell(Vector3i(50, 0, 50), _solid())

	# Assert
	assert_int(repath_calls.size()).is_equal(0)


func test_write_at_a_movement_cell_triggers_a_repath_evaluation() -> void:
	# Arrange — AC18: same moving villager as above.
	var grid: VoxelWorldGrid = _make_grid()
	var villager: VillagerAi = _make_setup_villager(grid)
	villager.current_cell = Vector3i(0, 0, 0)
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)
	var repath_calls: Array = []
	villager.repath_evaluation_requested.connect(func() -> void: repath_calls.append(true))

	# Act — a write directly AT one of the step's own movement cells.
	grid.set_cell(Vector3i(1, 0, 0), _solid())

	# Assert
	assert_int(repath_calls.size()).is_equal(1)


func test_write_in_clearance_column_above_a_movement_cell_triggers_a_repath_evaluation() -> void:
	# Arrange — the envelope explicitly includes the 2 cells directly ABOVE
	# each movement cell (GDD Rule 10b), not just the movement cell itself.
	var grid: VoxelWorldGrid = _make_grid()
	var villager: VillagerAi = _make_setup_villager(grid)
	villager.current_cell = Vector3i(0, 0, 0)
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)
	var repath_calls: Array = []
	villager.repath_evaluation_requested.connect(func() -> void: repath_calls.append(true))

	# Act — a write 2 cells directly above the "to" movement cell.
	grid.set_cell(Vector3i(1, 2, 0), _solid())

	# Assert
	assert_int(repath_calls.size()).is_equal(1)


func test_write_at_diagonal_flanker_of_a_moving_villagers_step_triggers_a_repath_evaluation() -> void:
	# Arrange — a diagonal step; the envelope includes both flanking
	# orthogonal cells (GDD Rule 9/10b).
	var grid: VoxelWorldGrid = _make_grid()
	var villager: VillagerAi = _make_setup_villager(grid)
	villager.current_cell = Vector3i(0, 0, 0)
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 1)
	var repath_calls: Array = []
	villager.repath_evaluation_requested.connect(func() -> void: repath_calls.append(true))

	# Act — a write at one of the two flanker cells: (1,0,0) or (0,0,1).
	grid.set_cell(Vector3i(1, 0, 0), _solid())

	# Assert
	assert_int(repath_calls.size()).is_equal(1)


func test_write_while_villager_is_stationary_triggers_zero_repath_evaluations() -> void:
	# Arrange — a stationary villager (from_cell == to_cell, e.g. Working)
	# is never "moving" per GDD Rule 10b's scope, regardless of where the
	# write lands — even directly at its own current cell.
	var grid: VoxelWorldGrid = _make_grid()
	var villager: VillagerAi = _make_setup_villager(grid)
	villager.current_cell = Vector3i(3, 0, 3)
	villager._from_cell = Vector3i(3, 0, 3)
	villager._to_cell = Vector3i(3, 0, 3)
	var repath_calls: Array = []
	villager.repath_evaluation_requested.connect(func() -> void: repath_calls.append(true))

	# Act
	grid.set_cell(Vector3i(3, 0, 3), _solid())

	# Assert
	assert_int(repath_calls.size()).is_equal(0)


func test_bulk_write_intersecting_moving_villagers_envelope_triggers_exactly_one_repath_evaluation() -> void:
	# Arrange — a bulk write batches many records under one signal; the
	# filter must still fire exactly once per relevant batch, never once
	# per record.
	var grid: VoxelWorldGrid = _make_grid()
	var villager: VillagerAi = _make_setup_villager(grid)
	villager.current_cell = Vector3i(0, 0, 0)
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)
	var repath_calls: Array = []
	villager.repath_evaluation_requested.connect(func() -> void: repath_calls.append(true))

	# Act — one cell inside the envelope, several far outside it.
	var changes: Dictionary[Vector3i, CellContents] = {
		Vector3i(1, 0, 0): _solid(),
		Vector3i(80, 0, 80): _solid(),
		Vector3i(90, 0, 90): _solid(),
	}
	grid.bulk_write(changes)

	# Assert
	assert_int(repath_calls.size()).is_equal(1)


func test_bulk_write_entirely_outside_envelope_triggers_zero_repath_evaluations() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	var villager: VillagerAi = _make_setup_villager(grid)
	villager.current_cell = Vector3i(0, 0, 0)
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)
	var repath_calls: Array = []
	villager.repath_evaluation_requested.connect(func() -> void: repath_calls.append(true))

	# Act
	var changes: Dictionary[Vector3i, CellContents] = {
		Vector3i(80, 0, 80): _solid(),
		Vector3i(90, 0, 90): _solid(),
	}
	grid.bulk_write(changes)

	# Assert
	assert_int(repath_calls.size()).is_equal(0)


# ---------------------------------------------------------------------------
# is_moving() / get_remaining_movement_cells() — direct, no live signal
# ---------------------------------------------------------------------------

func test_is_moving_true_when_from_and_to_cell_differ() -> void:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)

	assert_bool(villager.is_moving()).is_true()


func test_is_moving_false_when_from_and_to_cell_are_equal() -> void:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager._from_cell = Vector3i(2, 0, 2)
	villager._to_cell = Vector3i(2, 0, 2)

	assert_bool(villager.is_moving()).is_false()


func test_get_remaining_movement_cells_returns_from_and_to_cell_when_moving() -> void:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)

	assert_array(villager.get_remaining_movement_cells()).contains_exactly([
		Vector3i(0, 0, 0), Vector3i(1, 0, 0),
	])


func test_get_remaining_movement_cells_returns_empty_when_stationary() -> void:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager._from_cell = Vector3i(3, 0, 3)
	villager._to_cell = Vector3i(3, 0, 3)

	assert_array(villager.get_remaining_movement_cells()).is_empty()


# ---------------------------------------------------------------------------
# VillagerRepathFilter — pure clearance-envelope / intersection functions
# ---------------------------------------------------------------------------

func test_clearance_envelope_includes_movement_cell_and_two_cells_above() -> void:
	var envelope: Array[Vector3i] = VillagerRepathFilter.clearance_envelope([Vector3i(2, 0, 2)])

	assert_bool(envelope.has(Vector3i(2, 0, 2))).is_true()
	assert_bool(envelope.has(Vector3i(2, 1, 2))).is_true()
	assert_bool(envelope.has(Vector3i(2, 2, 2))).is_true()
	assert_bool(envelope.has(Vector3i(2, 3, 2))).is_false()


func test_clearance_envelope_diagonal_step_includes_both_flanking_orthogonal_cells() -> void:
	var envelope: Array[Vector3i] = VillagerRepathFilter.clearance_envelope([
		Vector3i(0, 0, 0), Vector3i(1, 0, 1),
	])

	assert_bool(envelope.has(Vector3i(1, 0, 0))).is_true()
	assert_bool(envelope.has(Vector3i(0, 0, 1))).is_true()


func test_clearance_envelope_orthogonal_step_adds_no_flanker_cells() -> void:
	var envelope: Array[Vector3i] = VillagerRepathFilter.clearance_envelope([
		Vector3i(0, 0, 0), Vector3i(1, 0, 0),
	])

	# Only the two movement cells' own clearance columns — no flanker
	# addition for a purely orthogonal step (2 cells x 3-cell column each).
	assert_int(envelope.size()).is_equal(6)


func test_changed_cells_intersect_envelope_empty_movement_cells_returns_false() -> void:
	var empty_movement: Array[Vector3i] = []

	assert_bool(
		VillagerRepathFilter.changed_cells_intersect_envelope([Vector3i(0, 0, 0)], empty_movement)
	).is_false()


func test_changed_cells_intersect_envelope_true_when_any_changed_cell_is_inside() -> void:
	var movement: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	var changed: Array[Vector3i] = [Vector3i(50, 0, 50), Vector3i(1, 0, 0)]

	assert_bool(VillagerRepathFilter.changed_cells_intersect_envelope(changed, movement)).is_true()


func test_changed_cells_intersect_envelope_false_when_no_changed_cell_is_inside() -> void:
	var movement: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	var changed: Array[Vector3i] = [Vector3i(50, 0, 50)]

	assert_bool(VillagerRepathFilter.changed_cells_intersect_envelope(changed, movement)).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive — Villager AI's directory is flat),
## stripping full-line `#`/`##` doc-comment lines first (this codebase's
## established precedent — see `config_and_scaffold_test.gd`'s/
## `dda_raycast_test.gd`'s own identically-named helper).
func _read_all_gd_source(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined
