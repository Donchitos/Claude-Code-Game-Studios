# GdUnit generated TestSuite
class_name GdUnitPatcherTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/update/GdUnitPatcher.gd'

const _patches := "res://addons/gdUnit4/test/update/resources/patches/"

var _patcher :GdUnitPatcher


func before() -> void:
	_patcher = auto_free(GdUnitPatcher.new())


func before_test() -> void:
	Engine.set_meta(GdUnitPatch.PATCH_VERSION, [])
	_patcher._patches.clear()


func test__collect_patch_versions_no_patches() -> void:
	# using higher version than patches exists in patch folder
	assert_array(_patcher._collect_patch_versions(_patches, GdUnit4Version.new(3,0,0))).is_empty()


func test__collect_patch_versions_current_eq_latest_version() -> void:
	# using equal version than highst available patch
	assert_array(_patcher._collect_patch_versions(_patches, GdUnit4Version.new(1,1,4))).is_empty()


func test__collect_patch_versions_current_lower_latest_version() -> void:
	# using one version lower than highst available patch
	assert_array(_patcher._collect_patch_versions(_patches, GdUnit4Version.new(0,9,9)))\
		.contains_exactly(["res://addons/gdUnit4/test/update/resources/patches/v1.1.4"])

	# using two versions lower than highst available patch
	assert_array(_patcher._collect_patch_versions(_patches, GdUnit4Version.new(0,9,8)))\
		.contains_exactly([
			"res://addons/gdUnit4/test/update/resources/patches/v0.9.9",
			"res://addons/gdUnit4/test/update/resources/patches/v1.1.4"])

	# using three versions lower than highst available patch
	assert_array(_patcher._collect_patch_versions(_patches, GdUnit4Version.new(0,9,5)))\
		.contains_exactly([
			"res://addons/gdUnit4/test/update/resources/patches/v0.9.6",
			"res://addons/gdUnit4/test/update/resources/patches/v0.9.9",
			"res://addons/gdUnit4/test/update/resources/patches/v1.1.4"])


func test_scan_patches() -> void:
	_patcher._scan(_patches, GdUnit4Version.new(0,9,6))
	assert_dict(_patcher._patches)\
		.contains_key_value("res://addons/gdUnit4/test/update/resources/patches/v0.9.9", PackedStringArray(["patch_a.gd", "patch_b.gd"]))\
		.contains_key_value("res://addons/gdUnit4/test/update/resources/patches/v1.1.4", PackedStringArray(["patch_a.gd"]))
	assert_int(_patcher.patch_count()).is_equal(3)

	_patcher._patches.clear()
	_patcher._scan(_patches, GdUnit4Version.new(0,9,5))
	assert_dict(_patcher._patches)\
		.contains_key_value("res://addons/gdUnit4/test/update/resources/patches/v0.9.6", PackedStringArray(["patch_x.gd"]))\
		.contains_key_value("res://addons/gdUnit4/test/update/resources/patches/v0.9.9", PackedStringArray(["patch_a.gd", "patch_b.gd"]))\
		.contains_key_value("res://addons/gdUnit4/test/update/resources/patches/v1.1.4", PackedStringArray(["patch_a.gd"]))
	assert_int(_patcher.patch_count()).is_equal(4)


func test_execute_no_patches() -> void:
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_empty()

	_patcher.execute()
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_empty()


func test_execute_v_095() -> void:
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_empty()
	_patcher._scan(_patches, GdUnit4Version.parse("v0.9.5"))

	_patcher.execute()
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_equal([
		GdUnit4Version.parse("v0.9.6"),
		GdUnit4Version.parse("v0.9.9-a"),
		GdUnit4Version.parse("v0.9.9-b"),
		GdUnit4Version.parse("v1.1.4"),
	])


func test_execute_v_096() -> void:
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_empty()
	_patcher._scan(_patches, GdUnit4Version.parse("v0.9.6"))

	_patcher.execute()
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_equal([
		GdUnit4Version.parse("v0.9.9-a"),
		GdUnit4Version.parse("v0.9.9-b"),
		GdUnit4Version.parse("v1.1.4"),
	])


func test_execute_v_099() -> void:
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_empty()
	_patcher._scan(_patches, GdUnit4Version.new(0,9,9))

	_patcher.execute()
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_equal([
		GdUnit4Version.parse("v1.1.4"),
	])


func test_execute_v_150() -> void:
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_empty()
	_patcher._scan(_patches, GdUnit4Version.parse("v1.5.0"))

	_patcher.execute()
	assert_array(Engine.get_meta(GdUnitPatch.PATCH_VERSION)).is_empty()
