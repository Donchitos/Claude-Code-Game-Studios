# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GdDiffToolTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdDiffTool.gd'


func test_string_diff_empty() -> void:
	var diffs := GdDiffTool.string_diff("", "")
	assert_array(diffs).has_size(2)
	assert_array(diffs[0]).is_empty()
	assert_array(diffs[1]).is_empty()


func test_string_diff_equals() -> void:
	var diffs := GdDiffTool.string_diff("Abc", "Abc")
	var expected_l_diff := "Abc".to_utf8_buffer()
	var expected_r_diff := "Abc".to_utf8_buffer()

	assert_array(diffs).has_size(2)
	assert_array(diffs[0]).contains_exactly(expected_l_diff)
	assert_array(diffs[1]).contains_exactly(expected_r_diff)


func test_string_diff() -> void:
	# tests the result of string diff function like assert_str("Abc").is_equal("abc")
	var diffs := GdDiffTool.string_diff("Abc", "abc")
	var chars := "Aabc".to_utf8_buffer()
	var ord_A := chars[0]
	var ord_a := chars[1]
	var ord_b := chars[2]
	var ord_c := chars[3]
	var expected_l_diff := PackedByteArray([GdDiffTool.DIV_SUB, ord_A, GdDiffTool.DIV_ADD, ord_a, ord_b, ord_c])
	var expected_r_diff := PackedByteArray([GdDiffTool.DIV_ADD, ord_A, GdDiffTool.DIV_SUB, ord_a, ord_b, ord_c])

	assert_array(diffs).has_size(2)
	assert_array(diffs[0]).contains_exactly(expected_l_diff)
	assert_array(diffs[1]).contains_exactly(expected_r_diff)


@warning_ignore("unused_parameter")
func test_string_diff_large_value(fuzzer := Fuzzers.rand_str(1000, 4000), fuzzer_iterations := 10) -> void:
	# test diff with large values not crashes the API GD-100
	var value :String = fuzzer.next_value()
	GdDiffTool.string_diff(value, value)
