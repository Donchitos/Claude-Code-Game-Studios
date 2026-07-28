## Unit test — Voxel World story vox-023 ("Block appearance becomes DATA — the
## palette owner can change a colour by editing data and nothing else").
##
## Carries all THREE anti-vacuity levers named in the story's own Test
## Evidence section (Lever 3's deletion probe is recorded in the commit body,
## per the `scene-007` discipline, not automated here — unwiring
## `Valley.tscn`'s appearance Inspector assignment is a one-line scene edit,
## not something this suite can express):
##
## - LEVER 1 (grep guard): zero hardcoded block colours in `src/voxel_world/`,
##   with the retained `DEBUG_UNKNOWN_COLOR` as the single named exception.
##   FAILED on the pre-story build against `voxel_world_mesher.gd:147`'s
##   `1: Color("9CAD6E")` (observed and recorded in the commit body).
## - LEVER 2 (zero unknown-colour faces): mesh a REAL chunk over REAL
##   `vox-022`-generated terrain through the REAL [method
##   VoxelWorldMesher.build_chunk] path, read the produced surface's
##   `Mesh.ARRAY_COLOR`, and assert NO vertex carries [constant
##   VoxelWorldMesher.DEBUG_UNKNOWN_COLOR] — for EVERY id the band
##   configuration can emit, with the id set READ from that configuration
##   (`VoxelWorldGrid._pure_band_id_for_height`), never pasted as a literal.
##   FAILS the instant `vox-022`'s config reaches an id ([VoxelWorldConfig]'s
##   own shipped tuning reaches all of 1-4) this story's appearance table
##   does not cover — verified by direct source inspection of the pre-story
##   `DEBUG_BLOCK_COLORS = {1: Color("9CAD6E")}` one-entry dictionary (any id
##   other than 1 fell through to the magenta fallback; recorded in the
##   commit body per the `vox-022`-established "hand-verified" evidentiary
##   convention for a negative control on removed code).
## - The INVERSE of Lever 2 (AC-VISIBLE-FAIL-SURVIVES): an id deliberately
##   outside the table DOES produce magenta faces, so Lever 2 cannot pass
##   because the magenta path was quietly deleted.
## - AC-DATA-ONLY-CHANGE-CHANGES-THE-WORLD: two `.tres`-shaped config
##   fixtures differing in exactly one colour value produce a DIFFERENT
##   `Mesh.ARRAY_COLOR` for that one id's faces, with zero `.gd` file changed
##   between the two runs.
## - AC-COVERS-EVERY-ID-VOX-022-CAN-EMIT's negative control: removing one
##   id's row from the appearance table makes that id's faces turn magenta
##   again — Lever 2 does not pass "by accident."
## - AC-NO-STATE-COLOUR-ON-WORLD-GEOMETRY: no build-state field/value exists
##   on [BlockAppearanceConfig] or its shipped `.tres`.
class_name DataDrivenBlockAppearanceTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Shared fixture helpers
# ---------------------------------------------------------------------------

## The shipped-shape terrain tuning `vox-022`'s own test file establishes
## (`multi_block_type_terrain_generation_test.gd`'s `_make_shipped_shape_config`)
## — reused rather than re-derived, so this file's id set matches the REAL
## production tuning, not a hand-picked one.
func _make_shipped_shape_config() -> VoxelWorldConfig:
	var config := VoxelWorldConfig.new()
	config.base_height = 4
	config.amplitude = 3.0
	config.frequency = 0.05
	config.min_y = 0
	config.max_y = 16
	config.world_width_cells = 40
	config.world_depth_cells = 40
	config.terrain_seed = 2026
	return config


## The full set of band ids [param config]'s band rule can produce for any Y
## in `[min_y, max_y]` — computed from the SAME production static
## [method VoxelWorldGrid._pure_band_id_for_height] the real generator calls,
## never a pasted literal (the cross-story seam `vox-023`'s own AC names).
func _reachable_band_ids(config: VoxelWorldConfig) -> Array[int]:
	var reachable: Dictionary[int, bool] = {}
	for y in range(config.min_y, config.max_y + 1):
		reachable[VoxelWorldGrid._pure_band_id_for_height(y, config.band_ids, config.effective_band_boundaries())] = true
	var ids: Array[int] = reachable.keys()
	ids.sort()
	return ids


func _make_valid_appearance_config() -> BlockAppearanceConfig:
	var config := BlockAppearanceConfig.new()
	config.block_type_ids = [1, 2, 3, 4]
	config.block_colors_hex = ["9CAD6E", "A98F5E", "7C818A", "C9D3D8"]
	return config


func _build_real_chunk(grid: VoxelWorldGrid, appearance: BlockAppearanceConfig, chunk_coord: Vector2i) -> Array:
	var mesher: VoxelWorldMesher = auto_free(VoxelWorldMesher.new())
	mesher.grid = grid
	mesher.appearance = appearance
	mesher.setup()
	mesher.build_chunk(chunk_coord)
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(chunk_coord)
	if mesh_instance.mesh == null:
		return []
	return mesh_instance.mesh.surface_get_arrays(0)


# ---------------------------------------------------------------------------
# LEVER 1 — grep guard: zero hardcoded block colours in src/voxel_world/
# ---------------------------------------------------------------------------

func test_lever1_zero_hardcoded_block_colours_in_voxel_world_source() -> void:
	var violations: Array[String] = _find_block_colour_violations("res://src/voxel_world")
	assert_array(violations).is_empty()


## Scans every `.gd` file directly under [param dir_path] (this project's own
## established non-recursive `src/voxel_world` scan shape —
## `mesher_material_contract_test.gd`'s `_read_all_source` precedent) for a
## HARDCODED `Color(...)` LITERAL construction — `Color("...")` or
## `Color(<number>, ...)` — excluding `PackedColorArray(` call sites and any
## line naming the one permitted exception, [constant
## VoxelWorldMesher.DEBUG_UNKNOWN_COLOR] itself. Deliberately does NOT flag
## `Color(some_variable)` — [method BlockAppearanceConfig.get_color]'s own
## `Color(block_colors_hex[i])` conversion is the mechanism that makes the
## table DATA-driven, not a hardcoded colour, and a guard that flagged it
## would be asking for the exact literal-embedding this story exists to
## remove.
func _find_block_colour_violations(dir_path: String) -> Array[String]:
	var violations: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				var stripped: String = line.strip_edges()
				if stripped.begins_with("#"):
					continue
				if stripped.contains("DEBUG_UNKNOWN_COLOR"):
					continue  # the one permitted exception, named explicitly
				var scanned: String = stripped.replace("PackedColorArray(", "")
				if _contains_hardcoded_color_literal(scanned):
					violations.append("%s: %s" % [file_name, stripped])
		file_name = dir.get_next()
	dir.list_dir_end()
	return violations


## Returns whether [param line] contains a `Color(` call whose first argument
## is a LITERAL (a quote, digit, `.` or `-`) rather than an expression/
## variable — see [method _find_block_colour_violations]'s own doc comment.
func _contains_hardcoded_color_literal(line: String) -> bool:
	var search_from: int = 0
	while search_from != -1:
		var idx: int = line.find("Color(", search_from)
		if idx == -1:
			return false
		var arg_start: int = idx + "Color(".length()
		var next_char: String = line.substr(arg_start, 1)
		if next_char == "\"" or next_char == "." or next_char == "-" or next_char.is_valid_int():
			return true
		search_from = idx + 1
	return false


# ---------------------------------------------------------------------------
# LEVER 2 — zero unknown-colour faces for every id vox-022's generator can
# emit, driven from config, never a literal list
# ---------------------------------------------------------------------------

func test_lever2_real_chunk_over_generated_terrain_has_zero_unknown_colour_faces() -> void:
	# Arrange — real, generated multi-band terrain (vox-022's own shipped-shape
	# tuning), a real appearance config covering every id that tuning reaches.
	var config: VoxelWorldConfig = _make_shipped_shape_config()
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	grid.generate_terrain()
	var appearance: BlockAppearanceConfig = _make_valid_appearance_config()

	# The id set this table must cover — READ from the band config, never
	# pasted (the cross-story seam AC-COVERS-EVERY-ID-VOX-022-CAN-EMIT names).
	var expected_reachable: Array[int] = _reachable_band_ids(config)
	assert_int(expected_reachable.size()).is_greater_equal(2)
	for id: int in expected_reachable:
		assert_bool(appearance.block_type_ids.has(id)).is_true()

	# Act — the REAL mesher, the REAL build_chunk() path, over REAL generated
	# terrain (chunk (0,0), fully inside the 40x40 configured world).
	var arrays: Array = _build_real_chunk(grid, appearance, Vector2i(0, 0))
	assert_bool(arrays.is_empty()).is_false()
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	assert_int(colors.size()).is_greater(0)

	# Assert — the lever: zero magenta (DEBUG_UNKNOWN_COLOR) vertices anywhere.
	var unknown_count: int = 0
	for color: Color in colors:
		if color.is_equal_approx(VoxelWorldMesher.DEBUG_UNKNOWN_COLOR):
			unknown_count += 1
	assert_int(unknown_count).is_equal(0)


## The INVERSE of Lever 2 (AC-VISIBLE-FAIL-SURVIVES): an id deliberately
## outside the table DOES produce magenta — proving Lever 2 does not pass
## because the magenta path was quietly deleted.
func test_inverse_unmapped_id_still_produces_magenta_faces() -> void:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(5, 5, 5), CellContents.new(5, 0))  # id 5: inside the
	# 1..5 family (so set_cell's own assertion passes) but deliberately absent
	# from the appearance table below.
	var appearance: BlockAppearanceConfig = _make_valid_appearance_config()
	assert_bool(appearance.block_type_ids.has(5)).is_false()

	var arrays: Array = _build_real_chunk(grid, appearance, Vector2i(0, 0))
	assert_bool(arrays.is_empty()).is_false()
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	assert_int(colors.size()).is_greater(0)
	for color: Color in colors:
		assert_that(color).is_equal(VoxelWorldMesher.DEBUG_UNKNOWN_COLOR)


## AC-COVERS-EVERY-ID-VOX-022-CAN-EMIT's own negative control: remove one id's
## row from the table and its faces turn magenta again — Lever 2 does not
## pass "by accident" once a real row is missing.
func test_removing_one_ids_row_reintroduces_magenta_for_that_id() -> void:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(5, 5, 5), CellContents.new(2, 0))

	var appearance: BlockAppearanceConfig = _make_valid_appearance_config()
	var midland_index: int = appearance.block_type_ids.find(2)
	appearance.block_type_ids.remove_at(midland_index)
	appearance.block_colors_hex.remove_at(midland_index)

	var arrays: Array = _build_real_chunk(grid, appearance, Vector2i(0, 0))
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	assert_int(colors.size()).is_greater(0)
	for color: Color in colors:
		assert_that(color).is_equal(VoxelWorldMesher.DEBUG_UNKNOWN_COLOR)


# ---------------------------------------------------------------------------
# AC-DATA-ONLY-CHANGE-CHANGES-THE-WORLD — the user's own requirement, tested
# ---------------------------------------------------------------------------

func test_ac_data_only_change_changes_the_world_editing_one_hex_moves_one_colour() -> void:
	# Arrange — one real grid, one real chunk, two config FIXTURES differing
	# in exactly Lowland's (id 1) hex value — zero `.gd` file touched between
	# the two builds, exactly the palette owner's own edit-one-number loop.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(5, 5, 5), CellContents.new(1, 0))

	var fixture_a: BlockAppearanceConfig = _make_valid_appearance_config()
	var fixture_b: BlockAppearanceConfig = _make_valid_appearance_config()
	fixture_b.block_colors_hex[fixture_b.block_type_ids.find(1)] = "FF0000"

	# Act — the SAME cell, the SAME mesher code path, mesh against each fixture.
	var arrays_a: Array = _build_real_chunk(grid, fixture_a, Vector2i(0, 0))
	var arrays_b: Array = _build_real_chunk(grid, fixture_b, Vector2i(0, 0))

	# Assert — the produced ARRAY_COLOR differs, and differs to EXACTLY the
	# edited value.
	var colors_a: PackedColorArray = arrays_a[Mesh.ARRAY_COLOR]
	var colors_b: PackedColorArray = arrays_b[Mesh.ARRAY_COLOR]
	assert_int(colors_a.size()).is_equal(colors_b.size())
	assert_int(colors_a.size()).is_greater(0)
	for i in colors_a.size():
		assert_bool(colors_a[i].is_equal_approx(colors_b[i])).is_false()
		assert_that(colors_a[i]).is_equal(Color("9CAD6E"))
		assert_that(colors_b[i]).is_equal(Color("FF0000"))


# ---------------------------------------------------------------------------
# AC-NO-STATE-COLOUR-ON-WORLD-GEOMETRY
# ---------------------------------------------------------------------------

func test_ac_no_state_colour_no_build_state_field_on_appearance_config() -> void:
	# Grep guard over the config class's own source — no draft/released/
	# paused/done/validity field or literal anywhere.
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/block_appearance_config.gd")
	var forbidden_terms: Array[String] = ["draft", "released", "paused", "DRAFT", "RELEASED", "PAUSED", "validity"]
	for term: String in forbidden_terms:
		assert_bool(source.contains(term)).is_false()
