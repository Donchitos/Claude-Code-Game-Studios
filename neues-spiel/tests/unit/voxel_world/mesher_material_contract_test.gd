## Grep-guarded material/construction-site contract for Story vox-007
## (TR-voxel-world-052, Control Manifest Presentation-layer Forbidden:
## "never CCW winding or CULL_DISABLED for committed-block materials";
## sprint-4 QA plan Smoke Test Scope item 2).
##
## Proves, all via comment-stripped source scans (this codebase's
## established precedent -- see
## `tests/integration/voxel_world/dda_raycast_test.gd`'s `_read_all_gd_source`
## helper, mirrored here for both `.gd` and `.gdshader` source):
## 1. `CULL_DISABLED` (any casing) appears NOWHERE in `src/voxel_world/`'s own
##    CODE nor in the shared terrain shader -- the vertical slice's
##    now-EXPIRED mitigation must not survive into production.
## 2. The shared terrain shader explicitly sets `cull_back` (never leaves
##    culling to an unstated engine default) -- the sprint QA smoke item.
## 3. Exactly ONE `ArrayMesh.new()` construction site exists under
##    `src/voxel_world/` -- "one mesher construction site" (no second,
##    independently-wound code path).
class_name MesherMaterialContractTest
extends GdUnitTestSuite


func test_cull_disabled_absent_in_voxel_world_gd_source() -> void:
	var source: String = _read_all_source("res://src/voxel_world", ".gd", "#")
	assert_bool(source.to_upper().contains("CULL_DISABLED")).is_false()


func test_cull_disabled_absent_in_terrain_shader_source() -> void:
	var source: String = _read_all_source("res://assets/shaders", ".gdshader", "//")
	assert_bool(source.to_upper().contains("CULL_DISABLED")).is_false()


func test_terrain_shader_explicitly_sets_cull_back() -> void:
	var source: String = _read_all_source("res://assets/shaders", ".gdshader", "//")
	assert_bool(source.contains("cull_back")).is_true()


func test_exactly_one_array_mesh_construction_site_in_voxel_world_source() -> void:
	# Comment-stripped scan (this file's own doc comment above legitimately
	# names "ArrayMesh.new()" to document the check -- stripping comment
	# lines first means only actual CODE usage counts).
	var source: String = _read_all_source("res://src/voxel_world", ".gd", "#")
	var count: int = source.count("ArrayMesh.new()")
	assert_int(count).is_equal(1)


## Reads and concatenates every file directly under [param dir_path]
## (non-recursive) ending in [param extension], STRIPPING full-line comments
## (lines whose stripped text begins with [param comment_prefix]) first --
## mirrors `tests/integration/voxel_world/dda_raycast_test.gd`'s
## `_read_all_gd_source` helper, generalized to accept any single-line
## comment prefix so it also covers `.gdshader`'s `//` comments.
func _read_all_source(dir_path: String, extension: String, comment_prefix: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(extension):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with(comment_prefix):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined
