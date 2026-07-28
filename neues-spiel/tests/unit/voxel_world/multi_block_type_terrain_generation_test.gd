## Unit test — Voxel World story vox-022 (multi block-type terrain
## generation, art bible §4.3 height bands, GDD Core Rule 8 /
## TR-voxel-world-051's dig-order-eligible "1..5 value family", ADR-0015 §5/§6).
##
## Proves, all against [VoxelWorldGrid] / [VoxelWorldConfig] / [VoxelWorldRegionFile]:
##
## 1. ⚑ THE ANTI-VACUITY LEVER (sprint-12.md Must table, carried verbatim):
##    generated terrain yields >= 2 distinct non-empty `block_type_id`
##    values (target >= 3), run TWICE — once against
##    [method VoxelWorldGrid.generate_terrain]'s output, once against the
##    lazy page-in regenerator's output ([method
##    VoxelWorldGrid._bg_regenerate_from_seed], driven through the public
##    [method VoxelWorldGrid.update_residency] API, never called directly) —
##    with the expected reachable id set COMPUTED from
##    [member VoxelWorldConfig.band_ids]/[member VoxelWorldConfig.band_boundaries]
##    via the SAME production static [method VoxelWorldGrid._pure_band_id_for_height],
##    never a pasted-in literal. On the PRE-STORY build this returned exactly
##    1 distinct id and failed — recorded verbatim in this story's commit
##    body (test name, observed count, exit code), the `scene-006`-style
##    format.
## 2. AC-BOTH-PATHS-AGREE — the drift guard: for the SAME chunk key and seed,
##    [method VoxelWorldGrid.generate_terrain]'s output and the lazy
##    regenerator's output are BYTE-IDENTICAL in `block_type_ids`, not merely
##    "both banded". Negative control (documented, not automated — reverting
##    either call site to the bare [constant VoxelWorldGrid.TERRAIN_BLOCK_TYPE_ID]
##    literal breaks this comparison immediately, which is exactly the drift
##    this assertion exists to catch): this test was hand-verified to FAIL
##    when either write path's [method VoxelWorldGrid._pure_band_id_for_height]
##    call is reverted to the single-id literal.
## 3. AC-IDS-ARE-IN-RANGE-AND-DIG-ELIGIBLE — every emitted id stays inside
##    `0-255` (the existing [method VoxelWorldGrid.set_cell]/
##    [method VoxelWorldGrid.bulk_write] packed-byte assertions, unmodified)
##    AND inside the `1..5` dig-order-eligible family.
## 4. AC-ID-1-STAYS-LOWLAND — the valley floor (`y == min_y`, always filled)
##    keeps id `1` — a compatibility constraint (already-serialized region
##    files, `blueprint_cell.gd`'s built-cell default), not a taste call.
## 5. AC-BACKGROUND-PATH-READS-NO-INSTANCE-STATE — [method
##    VoxelWorldGrid._bg_regenerate_from_seed]'s own body references no
##    `config.`/`self.` instance state (grep-guard), and two INDEPENDENT
##    grids regenerating the SAME never-touched chunk from the SAME seed
##    produce byte-identical results regardless of which thread ran them.
## 6. AC-ONE-RULE-TWO-PATHS + AC-NO-MEANING-RESOLVED-HERE (grep-guards) — the
##    band-boundary comparison exists in exactly ONE place (a `static func`),
##    neither write path assigns [constant VoxelWorldGrid.TERRAIN_BLOCK_TYPE_ID]
##    as a cell value any more, no second implementation of the comparison
##    exists anywhere else in `src/voxel_world/`, and
##    `voxel_world_grid.gd` resolves no block-type MEANING (no `Color`, no
##    `ResourceItemDatabase` reference).
## 7. AC-BAND-BOUNDARIES-ARE-CONFIG-NOT-LITERALS — [VoxelWorldConfig.validate]'s
##    new band-boundary invariants (count-matching, strictly-increasing,
##    inside `[min_y, max_y]`, id family, id-1-stays-Lowland), each a
##    BLOCKING cross-value issue (ADR-0002 two-tier policy), never a silent
##    clamp.
## 8. AC-REGION-FILES-STAY-READABLE — a region file shaped exactly like a
##    PRE-STORY payload (every cell `id 1`, the only id the pre-story
##    generator ever wrote) round-trips through the post-story build's own
##    read path unchanged, byte-for-byte — proving the on-disk layout did
##    not change (Open Decision 2: no format change, no migration, this
##    story never touches the region-file header/payload shape).
##
## Test isolation (accumulated pitfall): every test that engages residency
## gets its OWN region directory under `user://` (never `res://`, never
## shared, never committed), removed recursively in [method after_test] —
## same pattern `region_file_residency_test.gd` established.
##
## NOTE (accumulated pitfall): the shipped world is NOT empty after boot —
## chunks lazily regenerate real terrain the moment residency is requested.
## Every fixture in this file that drives residency uses a FRESH, isolated
## region directory and asserts against ITS OWN generated data, never
## against a shared/ambient grid.
class_name MultiBlockTypeTerrainGenerationTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test isolation — per-test temp region directories, cleaned up after each test
# (helpers ABOVE every test function, accumulated pitfall)
# ---------------------------------------------------------------------------

var _created_region_dirs: Array[String] = []


func after_test() -> void:
	for dir_path: String in _created_region_dirs:
		_remove_dir_recursive(dir_path)
	_created_region_dirs.clear()


func _make_temp_region_dir(suffix: String) -> String:
	var dir_path: String = "user://vox022_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
	_created_region_dirs.append(dir_path)
	return dir_path


func _remove_dir_recursive(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path: String = dir_path.path_join(entry)
			if dir.current_is_dir():
				_remove_dir_recursive(full_path)
			else:
				DirAccess.remove_absolute(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)


# ---------------------------------------------------------------------------
# Shared test helpers
# ---------------------------------------------------------------------------

## The shipped-shape tuning (base_height=4, amplitude=3, min_y=0, max_y=16,
## frequency=0.05) every lever/agreement test below shares — the exact
## tuning Open Decision 1's anchor (a) arithmetic was computed against.
func _make_shipped_shape_config() -> VoxelWorldConfig:
	var config := VoxelWorldConfig.new()
	config.base_height = 4
	config.amplitude = 3.0
	config.frequency = 0.05
	config.min_y = 0
	config.max_y = 16
	return config


## The full set of band ids [param config]'s band rule COULD produce for any
## Y in `[min_y, max_y]` — computed by calling the SAME production static
## [method VoxelWorldGrid._pure_band_id_for_height] the two write paths call,
## never a re-derivation of the comparison itself. This is "the expected
## distinct-id set computed from the band config, never a literal" the
## story's anti-vacuity lever hardening requires.
func _reachable_band_ids(config: VoxelWorldConfig) -> Array[int]:
	var reachable: Dictionary[int, bool] = {}
	for y in range(config.min_y, config.max_y + 1):
		reachable[VoxelWorldGrid._pure_band_id_for_height(y, config.band_ids, config.effective_band_boundaries())] = true
	var ids: Array[int] = reachable.keys()
	ids.sort()
	return ids


func _strip_comments(text: String) -> String:
	var stripped: String = ""
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			stripped += line
			stripped += "\n"
	return stripped


## Isolates one named function's source text (from its `func name(` line up
## to the next top-level `func` declaration) — used by the
## AC-BACKGROUND-PATH-READS-NO-INSTANCE-STATE grep-guard to scope the
## "no `config.`/`self.` reference" check to exactly that method's own body,
## never the whole file (which legitimately mentions `config` elsewhere).
func _extract_function_body(source: String, func_name: String) -> String:
	var marker: String = "func %s(" % func_name
	var start: int = source.find(marker)
	if start == -1:
		return ""
	var next_func: int = source.find("\nfunc ", start + 1)
	if next_func == -1:
		next_func = source.length()
	return source.substr(start, next_func - start)


## Recursively finds every `.gd` file under [param dir_path] (except [param
## exclude_filename]) whose comment-stripped text contains [param needle] —
## the "no second, independently-maintained copy anywhere else" grep-guard,
## generalizing `shelter_recovery_live_pair_test.gd`'s `_find_files_assigning`
## helper (same shape, reused rather than re-derived).
func _find_files_containing(dir: DirAccess, dir_path: String, needle: String, exclude_filename: String) -> Array[String]:
	var found: Array[String] = []
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			var subdir: DirAccess = DirAccess.open(full_path)
			if subdir != null:
				found.append_array(_find_files_containing(subdir, full_path, needle, exclude_filename))
		elif entry.ends_with(".gd") and entry != exclude_filename:
			var text: String = FileAccess.get_file_as_string(full_path)
			var stripped: String = _strip_comments(text)
			if stripped.contains(needle):
				found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


# ---------------------------------------------------------------------------
# ⚑ THE ANTI-VACUITY LEVER — run against BOTH write paths
# ---------------------------------------------------------------------------

func test_lever_generate_terrain_yields_distinct_band_ids_computed_from_config() -> void:
	# Arrange
	var config: VoxelWorldConfig = _make_shipped_shape_config()
	config.world_width_cells = 40
	config.world_depth_cells = 40
	config.terrain_seed = 2026
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act
	grid.generate_terrain()
	var distinct_ids: Dictionary[int, bool] = {}
	for x in config.world_width_cells:
		for z in config.world_depth_cells:
			for y in range(config.min_y, config.max_y + 1):
				var contents: CellContents = grid.get_cell(Vector3i(x, y, z))
				if not contents.is_empty():
					distinct_ids[contents.block_type_id] = true

	# Assert — the lever: >= 2, target >= 3, expected set computed from config.
	var expected_reachable: Array[int] = _reachable_band_ids(config)
	assert_int(distinct_ids.size()).is_greater_equal(2)
	assert_int(distinct_ids.size()).is_greater_equal(mini(3, expected_reachable.size()))
	for id: int in distinct_ids.keys():
		assert_bool(expected_reachable.has(id)).is_true()


func test_lever_lazy_regenerator_yields_distinct_band_ids_computed_from_config() -> void:
	# Arrange — a real, never-touched world; residency drives the lazy
	# regenerator ([method VoxelWorldGrid._bg_regenerate_from_seed]) for
	# every chunk in a 3x3 window, never [method VoxelWorldGrid.generate_terrain].
	var config: VoxelWorldConfig = _make_shipped_shape_config()
	config.world_width_cells = 64
	config.world_depth_cells = 64
	config.terrain_seed = 2026
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("lever_lazy")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var focus := Vector3i(16, 0, 16)  # chunk (1, 1) -- pristine, never touched

	# Act
	grid.update_residency(focus, focus)
	grid.wait_for_async_residency_idle()

	var distinct_ids: Dictionary[int, bool] = {}
	for chunk_key: Vector2i in grid.get_resident_chunk_keys():
		var snapshot: VoxelWorldGrid.ChunkSnapshot = grid.get_chunk_snapshot(chunk_key)
		for i in snapshot.block_type_ids.size():
			var id: int = snapshot.block_type_ids[i]
			if id != CellContents.EMPTY_BLOCK_TYPE_ID:
				distinct_ids[id] = true

	# Assert — same lever, same expected-set-from-config discipline, against
	# the LAZY path this time (the sprint's own "one-path fix must fail the
	# lever" hardening -- this is the path most of the world uses, most of
	# the time, under ADR-0015 residency).
	var expected_reachable: Array[int] = _reachable_band_ids(config)
	assert_int(distinct_ids.size()).is_greater_equal(2)
	assert_int(distinct_ids.size()).is_greater_equal(mini(3, expected_reachable.size()))
	for id: int in distinct_ids.keys():
		assert_bool(expected_reachable.has(id)).is_true()


# ---------------------------------------------------------------------------
# AC-BOTH-PATHS-AGREE — the drift guard
# ---------------------------------------------------------------------------

func test_both_paths_agree_byte_identical_block_type_ids_for_same_chunk_and_seed() -> void:
	# Arrange — path A: generate_terrain(), a one-chunk-exact world.
	var config_a: VoxelWorldConfig = _make_shipped_shape_config()
	config_a.world_width_cells = VoxelWorldGrid.CHUNK_SIZE
	config_a.world_depth_cells = VoxelWorldGrid.CHUNK_SIZE
	config_a.terrain_seed = 4242
	var grid_a: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_a.config = config_a

	# Arrange — path B: the SAME tuning/seed, a SEPARATE never-touched grid,
	# paged in via the lazy regenerator only.
	var config_b: VoxelWorldConfig = _make_shipped_shape_config()
	config_b.world_width_cells = VoxelWorldGrid.CHUNK_SIZE
	config_b.world_depth_cells = VoxelWorldGrid.CHUNK_SIZE
	config_b.terrain_seed = 4242
	config_b.region_directory = _make_temp_region_dir("both_paths_agree")
	var grid_b: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_b.config = config_b

	# Act
	grid_a.generate_terrain()
	var snapshot_a: VoxelWorldGrid.ChunkSnapshot = grid_a.get_chunk_snapshot(Vector2i(0, 0))

	grid_b._request_resident(Vector2i(0, 0))
	grid_b.drain_pending_async_reads()
	var snapshot_b: VoxelWorldGrid.ChunkSnapshot = grid_b.get_chunk_snapshot(Vector2i(0, 0))

	# Assert — byte-identical, not merely "both banded".
	assert_object(snapshot_a).is_not_null()
	assert_object(snapshot_b).is_not_null()
	assert_bool(snapshot_a.block_type_ids == snapshot_b.block_type_ids).is_true()
	assert_bool(snapshot_a.material_ids == snapshot_b.material_ids).is_true()


# ---------------------------------------------------------------------------
# AC-IDS-ARE-IN-RANGE-AND-DIG-ELIGIBLE
# ---------------------------------------------------------------------------

func test_generated_ids_stay_in_packed_byte_range_and_dig_order_eligible_family() -> void:
	# Arrange
	var config: VoxelWorldConfig = _make_shipped_shape_config()
	config.world_width_cells = 32
	config.world_depth_cells = 32
	config.terrain_seed = 909
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act
	grid.generate_terrain()

	# Assert
	for x in config.world_width_cells:
		for z in config.world_depth_cells:
			for y in range(config.min_y, config.max_y + 1):
				var contents: CellContents = grid.get_cell(Vector3i(x, y, z))
				if contents.is_empty():
					continue
				assert_bool(contents.block_type_id >= 0 and contents.block_type_id <= 255).is_true()
				assert_bool(
					contents.block_type_id >= VoxelWorldConfig.BAND_ID_MIN
					and contents.block_type_id <= VoxelWorldConfig.BAND_ID_MAX
				).is_true()


# ---------------------------------------------------------------------------
# AC-ID-1-STAYS-LOWLAND
# ---------------------------------------------------------------------------

func test_id_1_stays_lowland_at_the_valley_floor() -> void:
	# Arrange — every column is filled from min_y upward (AC1/AC-4), so
	# y == min_y is always occupied and always the lowest band.
	var config: VoxelWorldConfig = _make_shipped_shape_config()
	config.world_width_cells = 24
	config.world_depth_cells = 24
	config.terrain_seed = 55
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act
	grid.generate_terrain()

	# Assert
	for x in config.world_width_cells:
		for z in config.world_depth_cells:
			var contents: CellContents = grid.get_cell(Vector3i(x, config.min_y, z))
			assert_int(contents.block_type_id).is_equal(1)


# ---------------------------------------------------------------------------
# AC-BACKGROUND-PATH-READS-NO-INSTANCE-STATE
# ---------------------------------------------------------------------------

func test_bg_regenerate_from_seed_body_references_no_instance_state() -> void:
	# Arrange + Act
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")
	var body: String = _extract_function_body(source, "_bg_regenerate_from_seed")

	# Assert
	assert_bool(body.is_empty()).is_false()
	assert_bool(body.contains("config.")).is_false()
	assert_bool(body.contains("self.")).is_false()


func test_bg_regenerate_from_seed_deterministic_across_two_independent_grids_same_seed() -> void:
	# Arrange — two entirely separate grids/configs, identical tuning/seed,
	# each paged in via the lazy regenerator ONLY (never generate_terrain()).
	var focus := Vector3i(0, 0, 0)

	var config_a: VoxelWorldConfig = _make_shipped_shape_config()
	config_a.world_width_cells = 64
	config_a.world_depth_cells = 64
	config_a.terrain_seed = 777
	config_a.region_directory = _make_temp_region_dir("bg_determinism_a")
	var grid_a: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_a.config = config_a

	var config_b: VoxelWorldConfig = _make_shipped_shape_config()
	config_b.world_width_cells = 64
	config_b.world_depth_cells = 64
	config_b.terrain_seed = 777
	config_b.region_directory = _make_temp_region_dir("bg_determinism_b")
	var grid_b: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_b.config = config_b

	# Act
	var chunk_key: Vector2i = grid_a.chunk_key_for_cell(focus)
	grid_a._request_resident(chunk_key)
	grid_a.drain_pending_async_reads()
	grid_b._request_resident(chunk_key)
	grid_b.drain_pending_async_reads()

	# Assert
	var snapshot_a: VoxelWorldGrid.ChunkSnapshot = grid_a.get_chunk_snapshot(chunk_key)
	var snapshot_b: VoxelWorldGrid.ChunkSnapshot = grid_b.get_chunk_snapshot(chunk_key)
	assert_object(snapshot_a).is_not_null()
	assert_object(snapshot_b).is_not_null()
	assert_bool(snapshot_a.block_type_ids == snapshot_b.block_type_ids).is_true()
	assert_bool(snapshot_a.material_ids == snapshot_b.material_ids).is_true()


# ---------------------------------------------------------------------------
# AC-ONE-RULE-TWO-PATHS + AC-NO-MEANING-RESOLVED-HERE — grep-guards
# ---------------------------------------------------------------------------

func test_one_rule_two_paths_shared_static_used_by_both_write_paths() -> void:
	# Arrange
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")
	var stripped: String = _strip_comments(source)

	# Assert — exactly one implementation of the band-boundary comparison...
	assert_int(stripped.count("static func _pure_band_id_for_height")).is_equal(1)
	# ...called by both write paths (1 definition line + 2 call sites, no more).
	assert_int(stripped.count("_pure_band_id_for_height(")).is_equal(3)
	# Neither write path assigns the single fixed id as a cell value any more.
	assert_int(stripped.count("CellContents.new(TERRAIN_BLOCK_TYPE_ID")).is_equal(0)
	assert_int(stripped.count("= TERRAIN_BLOCK_TYPE_ID")).is_equal(0)


func test_one_rule_two_paths_no_second_band_comparison_anywhere_else_in_voxel_world() -> void:
	# Arrange + Act — no OTHER file under src/voxel_world/ implements a
	# second, independently-maintained copy of the band-boundary comparison.
	var dir: DirAccess = DirAccess.open("res://src/voxel_world")
	var offending_files: Array[String] = _find_files_containing(
		dir, "res://src/voxel_world", "_pure_band_id_for_height", "voxel_world_grid.gd"
	)

	# Assert
	assert_array(offending_files).is_empty()


func test_no_meaning_resolved_here_grep_guard() -> void:
	# Arrange + Act
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")
	var stripped: String = _strip_comments(source)

	# Assert — TR-voxel-world-028: this class still resolves NOTHING about
	# what a block-type id means.
	assert_bool(stripped.contains("Color")).is_false()
	assert_bool(stripped.contains("ResourceItemDatabase")).is_false()


# ---------------------------------------------------------------------------
# AC-BAND-BOUNDARIES-ARE-CONFIG-NOT-LITERALS — VoxelWorldConfig.validate()
# ---------------------------------------------------------------------------

func test_config_validate_gdd_defaulted_bands_return_no_issues() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_array(issues).is_empty()


func test_config_validate_non_monotonic_band_boundaries_is_blocking() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.band_boundaries = [4, 2, 5]

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_config_validate_band_ids_boundaries_count_mismatch_is_blocking() -> void:
	# Arrange — 4 ids need exactly 3 boundaries; only 2 supplied.
	var config := VoxelWorldConfig.new()
	config.band_boundaries = [2, 4]

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_config_validate_band_id_outside_dig_eligible_family_is_blocking() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.band_ids = [1, 2, 3, 9]

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_config_validate_band_id_zero_not_starting_with_lowland_is_blocking() -> void:
	# Arrange — AC-ID-1-STAYS-LOWLAND: band_ids[0] must stay 1.
	var config := VoxelWorldConfig.new()
	config.band_ids = [2, 3, 4, 5]

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_config_validate_band_boundary_outside_min_y_max_y_is_blocking() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.band_boundaries = [2, 4, 999]

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_config_validate_duplicate_band_ids_is_blocking() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.band_ids = [1, 2, 2, 4]

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


# ---------------------------------------------------------------------------
# AC-REGION-FILES-STAY-READABLE — pre-story-shaped payload round-trips
# ---------------------------------------------------------------------------

func test_pre_story_shaped_region_payload_reads_back_unchanged() -> void:
	# Arrange — a region file shaped EXACTLY like a pre-story-generated
	# chunk: every cell id 1 (the only id the pre-story generator ever
	# wrote), material 0.
	var config: VoxelWorldConfig = _make_shipped_shape_config()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_directory = _make_temp_region_dir("pre_story_payload")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	var chunk_key := Vector2i(0, 0)
	var cell_count: int = VoxelWorldGrid.CHUNK_SIZE * VoxelWorldGrid.CHUNK_SIZE * (config.max_y - config.min_y + 1)
	var pre_story_block_type_ids := PackedByteArray()
	pre_story_block_type_ids.resize(cell_count)
	for i in cell_count:
		pre_story_block_type_ids[i] = 1
	var pre_story_material_ids := PackedByteArray()
	pre_story_material_ids.resize(cell_count)
	var payload := PackedByteArray()
	payload.append_array(pre_story_block_type_ids)
	payload.append_array(pre_story_material_ids)

	var region_key: Vector2i = grid._region_key_for_chunk(chunk_key)
	var region_file: VoxelWorldRegionFile = grid._get_or_create_region_file(region_key)
	var slot: int = grid._slot_in_region(chunk_key, region_key)
	var offset: int = region_file.reserve_offset_for_write(slot)
	var write_ok: bool = VoxelWorldRegionFile.write_payload_at(region_file.path, slot, offset, payload)
	assert_bool(write_ok).is_true()

	# Act — post-story build pages this already-persisted (pre-story-shaped)
	# chunk in via the SAME real read path (never re-banded — a persisted
	# read is [method VoxelWorldGrid._bg_read_from_disk], untouched by this
	# story; the stale-content consequence for a chunk like this is
	# documented, not fixed, per Open Decision 2).
	grid._request_resident(chunk_key)
	grid.drain_pending_async_reads()

	# Assert — byte-for-byte unchanged; the on-disk layout did not change.
	var snapshot: VoxelWorldGrid.ChunkSnapshot = grid.get_chunk_snapshot(chunk_key)
	assert_object(snapshot).is_not_null()
	assert_bool(snapshot.block_type_ids == pre_story_block_type_ids).is_true()
	assert_bool(snapshot.material_ids == pre_story_material_ids).is_true()
