# GdUnit generated TestSuite
class_name GdUnitUpdateTest
extends GdUnitTestSuite

# TestSuite generated from
const GdUnitUpdate = preload('res://addons/gdUnit4/src/update/GdUnitUpdate.gd')

# Store original content to restore after test execution
const testResource := "res://addons/gdUnit4/test/update/resources/ExampleSceneWithUids.txt"
var original_content: String

func before() -> void:
	var file := FileAccess.open(testResource, FileAccess.READ)
	original_content = file.get_as_text()
	file.close()


func after() -> void:
	var file := FileAccess.open(testResource, FileAccess.WRITE)
	file.store_string(original_content)
	file.close()

func after_test() -> void:
	clean_temp_dir()


func test_remove_uids_from_file() -> void:
	var update_tool: GdUnitUpdate = auto_free(GdUnitUpdate.new())

	# start uid patching
	update_tool.remove_uids_from_file(testResource)

	# Verify
	var patched_content := get_content(testResource)
	var expected_content := get_content("res://addons/gdUnit4/test/update/resources/ExampleScenePached.txt")
	assert_str(patched_content).is_equal(expected_content)


func get_content(resource: String) -> String:
	var file := FileAccess.open(resource, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	return content
