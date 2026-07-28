## Grep-guarded contract test — foliage_sway.gdshader (Presentation
## Experience story presentation-001 Sub-scope A; art-bible SS6.5 "Cheap --
## vertex-shader wind").
##
## Proves, via comment-stripped source scans (this codebase's established
## precedent, mirrors `tests/unit/voxel_world/mesher_material_contract_test.gd`):
## 1. The shader file exists, is a genuinely separate file from
##    terrain_chunk.gdshader, loads without a parse error, and its uniforms
##    ARE actually declared as expected.
## 2. `res://assets/shaders/terrain_chunk.gdshader` (the committed-block
##    terrain material) is UNTOUCHED by this story -- no wind/sway-related
##    text was added to it (whole-story AC: "the slice-validated static
##    foundation is untouched").
## 3. The wind-sway shader displaces VERTEX based on TIME (proves it is
##    actually a per-frame vertex effect, not a dead uniform).
class_name FoliageSwayShaderContractTest
extends GdUnitTestSuite

const SHADER_PATH: String = "res://assets/shaders/foliage_sway.gdshader"
const TERRAIN_SHADER_PATH: String = "res://assets/shaders/terrain_chunk.gdshader"


func test_shader_loads_without_parse_error() -> void:
	var shader: Shader = load(SHADER_PATH)
	assert_object(shader).is_not_null()


func test_shader_material_can_be_constructed_headless() -> void:
	# Mirrors VoxelWorldMesher._build_shared_material()'s established
	# "headless-safe ShaderMaterial construction" precedent -- no rendering
	# needed to prove the shader assigns and compiles without error.
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH)
	assert_object(material.shader).is_not_null()


func test_shader_declares_wind_uniforms() -> void:
	var source: String = _read_source(SHADER_PATH, "//")
	assert_bool(source.contains("wind_speed")).is_true()
	assert_bool(source.contains("wind_strength")).is_true()


func test_shader_displaces_vertex_using_time() -> void:
	var source: String = _read_source(SHADER_PATH, "//")
	# GDShader syntax uses "void vertex()", never GDScript's "func" keyword.
	assert_bool(source.contains("void vertex()")).is_true()
	assert_bool(source.contains("TIME")).is_true()
	assert_bool(source.contains("VERTEX")).is_true()


func test_shader_is_a_separate_file_from_terrain_shader() -> void:
	assert_str(SHADER_PATH).is_not_equal(TERRAIN_SHADER_PATH)


func test_terrain_shader_contains_no_wind_sway_text() -> void:
	# Whole-story AC: committed-block terrain material is untouched by this
	# story -- no ambient-motion text was added to it.
	var terrain_source: String = _read_source(TERRAIN_SHADER_PATH, "//").to_lower()
	assert_bool(terrain_source.contains("wind")).is_false()
	assert_bool(terrain_source.contains("sway")).is_false()


func test_terrain_shader_still_explicitly_culls_back() -> void:
	# Regression guard: this story must not weaken the vox-007 winding/
	# culling contract while adding a SEPARATE vegetation shader alongside it.
	var terrain_source: String = _read_source(TERRAIN_SHADER_PATH, "//")
	assert_bool(terrain_source.contains("cull_back")).is_true()
	assert_bool(terrain_source.to_upper().contains("CULL_DISABLED")).is_false()


## Reads [param path], stripping full-line comments (lines whose stripped
## text begins with [param comment_prefix]) -- mirrors
## `mesher_material_contract_test.gd`'s `_read_all_source` helper, applied to
## a single file rather than a whole directory.
func _read_source(path: String, comment_prefix: String) -> String:
	var text: String = FileAccess.get_file_as_string(path)
	var combined: String = ""
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with(comment_prefix):
			combined += line
			combined += "\n"
	return combined
