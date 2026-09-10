# GdUnit generated TestSuite
class_name GdUnit4VersionTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/.gd'


func test_parse() -> void:
	var expected := GdUnit4Version.new(0, 9, 1)
	assert_object(GdUnit4Version.parse("v0.9.1-rc")).is_equal(expected)
	assert_object(GdUnit4Version.parse("v0.9.1RC")).is_equal(expected)
	assert_object(GdUnit4Version.parse("0.9.1 rc")).is_equal(expected)
	assert_object(GdUnit4Version.parse("0.9.1")).is_equal(expected)


func test_equals() -> void:
	var version := GdUnit4Version.new(0, 9, 1)
	assert_bool(version.equals(version)).is_true()
	assert_bool(version.equals(GdUnit4Version.new(0, 9, 1))).is_true()
	assert_bool(GdUnit4Version.new(0, 9, 1).equals(version)).is_true()

	assert_bool(GdUnit4Version.new(0, 9, 2).equals(version)).is_false()
	assert_bool(GdUnit4Version.new(0, 8, 1).equals(version)).is_false()
	assert_bool(GdUnit4Version.new(1, 9, 1).equals(version)).is_false()


func test_to_string() -> void:
	var version := GdUnit4Version.new(0, 9, 1)
	assert_str(str(version)).is_equal("v0.9.1")
	assert_str("%s" % version).is_equal("v0.9.1")


@warning_ignore("unused_parameter")
func test_is_greater_major(fuzzer_major := Fuzzers.rangei(1, 20), fuzzer_minor := Fuzzers.rangei(0, 20), fuzzer_patch := Fuzzers.rangei(0, 20), fuzzer_iterations := 500) -> void:
	var version := GdUnit4Version.new(0, 9, 1)
	@warning_ignore("unsafe_cast")
	var current := GdUnit4Version.new(fuzzer_major.next_value() as int, fuzzer_minor.next_value() as int, fuzzer_patch.next_value() as int);
	assert_bool(current.is_greater(version))\
		.override_failure_message("Expect %s is greater then %s" % [current, version])\
		.is_true()


@warning_ignore("unused_parameter")
func test_is_not_greater_major(fuzzer_major := Fuzzers.rangei(1, 10), fuzzer_minor := Fuzzers.rangei(0, 20), fuzzer_patch := Fuzzers.rangei(0, 20), fuzzer_iterations := 500) -> void:
	var version := GdUnit4Version.new(11, 0, 0)
	@warning_ignore("unsafe_cast")
	var current := GdUnit4Version.new(fuzzer_major.next_value() as int, fuzzer_minor.next_value() as int, fuzzer_patch.next_value() as int);
	assert_bool(current.is_greater(version))\
		.override_failure_message("Expect %s is not greater then %s" % [current, version])\
		.is_false()


@warning_ignore("unused_parameter")
func test_is_greater_minor(fuzzer_minor := Fuzzers.rangei(3, 20), fuzzer_patch := Fuzzers.rangei(0, 20), fuzzer_iterations := 500) -> void:
	var version := GdUnit4Version.new(0, 2, 1)
	@warning_ignore("unsafe_cast")
	var current := GdUnit4Version.new(0, fuzzer_minor.next_value() as int, fuzzer_patch.next_value() as int);
	assert_bool(current.is_greater(version))\
		.override_failure_message("Expect %s is greater then %s" % [current, version])\
		.is_true()


@warning_ignore("unused_parameter")
func test_is_greater_patch(fuzzer_patch := Fuzzers.rangei(1, 20), fuzzer_iterations := 500) -> void:
	var version := GdUnit4Version.new(0, 2, 0)
	@warning_ignore("unsafe_cast")
	var current := GdUnit4Version.new(0, 2, fuzzer_patch.next_value() as int);
	assert_bool(current.is_greater(version))\
		.override_failure_message("Expect %s is greater then %s" % [current, version])\
		.is_true()
