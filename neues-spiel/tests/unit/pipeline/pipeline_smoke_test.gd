# Example unit test — proves the GdUnit4 pipeline runs end-to-end.
# Replace with real system tests as gameplay systems are implemented.
class_name PipelineSmokeTest
extends GdUnitTestSuite


func test_framework_executes_and_asserts() -> void:
	assert_int(1 + 1).is_equal(2)


func test_string_assertions_work() -> void:
	assert_str("gdUnit4").contains("Unit")


func test_godot_engine_version_is_4_7() -> void:
	var version: Dictionary = Engine.get_version_info()
	assert_int(version["major"]).is_equal(4)
	assert_int(version["minor"]).is_equal(7)
