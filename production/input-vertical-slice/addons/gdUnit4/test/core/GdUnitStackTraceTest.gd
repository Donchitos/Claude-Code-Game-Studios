class_name GdUnitStackTraceTest
extends GdUnitTestSuite

const __source = 'res://addons/gdUnit4/src/core/GdUnitStackTrace.gd'


#region helpers
func capture_stack() -> GdUnitStackTrace:
	return GdUnitStackTrace.new()


func capture_stack_1() -> GdUnitStackTrace:
	return capture_stack()


func capture_stack_2() -> GdUnitStackTrace:
	return capture_stack_1()


func capture_stack_3() -> GdUnitStackTrace:
	return capture_stack_2()


func capture_stack_4() -> GdUnitStackTrace:
	return capture_stack_3()


class InnerClass:

	static func capture_stack() -> GdUnitStackTrace:
		return GdUnitStackTrace.new()

#endregion


#region tests

func test_captures_stack_depth_0() -> void:
	var trace := GdUnitStackTrace.new()
	assert_int(trace.get_line_number()).is_equal(39)
	assert_str(trace.print_stack_trace())\
		.is_equal("\tat 'test_captures_stack_depth_0' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:39")


func test_captures_stack_depth_1() -> void:
	var trace := capture_stack()
	assert_int(trace.get_line_number()).is_equal(9)
	assert_str(trace.print_stack_trace())\
		.is_equal("""
			at 'capture_stack' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:9
			at 'test_captures_stack_depth_1' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:46"""
				.dedent().indent("\t").trim_prefix("\n"))


func test_captures_stack_depth_2() -> void:
	var trace := capture_stack_1()
	assert_int(trace.get_line_number()).is_equal(9)
	assert_str(trace.print_stack_trace())\
		.is_equal("""
			at 'capture_stack' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:9
			at 'capture_stack_1' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:13
			at 'test_captures_stack_depth_2' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:56"""
				.dedent().indent("\t").trim_prefix("\n"))


func test_captures_stack_depth_3() -> void:
	var trace := capture_stack_2()
	assert_int(trace.get_line_number()).is_equal(9)
	assert_str(trace.print_stack_trace())\
		.is_equal("""
			at 'capture_stack' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:9
			at 'capture_stack_1' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:13
			at 'capture_stack_2' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:17
			at 'test_captures_stack_depth_3' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:67"""
				.dedent().indent("\t").trim_prefix("\n"))


func test_captures_stack_depth_4() -> void:
	var trace := capture_stack_3()
	assert_int(trace.get_line_number()).is_equal(9)
	assert_str(trace.print_stack_trace())\
		.is_equal("""
			at 'capture_stack' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:9
			at 'capture_stack_1' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:13
			at 'capture_stack_2' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:17
			at 'capture_stack_3' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:21
			at 'test_captures_stack_depth_4' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:79"""
				.dedent().indent("\t").trim_prefix("\n"))


func test_captures_stack_depth_5() -> void:
	var trace := capture_stack_4()
	assert_int(trace.get_line_number()).is_equal(9)
	assert_str(trace.print_stack_trace())\
		.is_equal("""
			at 'capture_stack' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:9
			at 'capture_stack_1' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:13
			at 'capture_stack_2' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:17
			at 'capture_stack_3' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:21
			at 'capture_stack_4' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:25
			at 'test_captures_stack_depth_5' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:92"""
				.dedent().indent("\t").trim_prefix("\n"))


func test_mock_frames_are_filtered_from_stack_trace() -> void:
	var mock_node: Variant = mock(Node)
	assert_failure(func verify_call() -> void:
			@warning_ignore("unsafe_method_access")
			verify(mock_node, 1).set_process(true)\
		)\
		.has_stack_trace([
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd", 109, "verify_call"),
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd", 107, "test_mock_frames_are_filtered_from_stack_trace"),
		])


func test_spy_frames_are_filtered_from_stack_trace() -> void:
	var instance: Node = auto_free(Node.new())
	var spy_node: Variant = spy(instance)
	assert_failure(func verify_call() -> void:
			@warning_ignore("unsafe_method_access")
			verify(spy_node, 1).set_process(true)\
		)\
		.has_stack_trace([
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd", 122, "verify_call"),
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd", 120, "test_spy_frames_are_filtered_from_stack_trace"),
		])


func test_inner_class_frames_in_stack_trace() -> void:
	var trace := InnerClass.capture_stack()
	assert_int(trace.get_line_number()).is_equal(31)
	assert_str(trace.print_stack_trace())\
		.is_equal("""
			at 'capture_stack' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:31
			at 'test_inner_class_frames_in_stack_trace' in res://addons/gdUnit4/test/core/GdUnitStackTraceTest.gd:131"""
				.dedent().indent("\t").trim_prefix("\n"))

#endregion


#region serialize / deserialize

func test_serialize_empty_trace_returns_empty_json_array() -> void:
	var trace := GdUnitStackTrace.of([])
	assert_str(trace.serialize()).is_equal("[]")


func test_serialize_returns_json_string() -> void:
	var trace := GdUnitStackTrace.of([
		GdUnitStackTraceElement.new("res://test.gd", 10, "func_a"),
		GdUnitStackTraceElement.new("res://test.gd", 20, "func_b"),
	])
	var json := trace.serialize()
	assert_str(json)\
		.is_not_empty()\
		.is_equal('[{"function":"func_a","line":10,"source":"res://test.gd"},{"function":"func_b","line":20,"source":"res://test.gd"}]')


func test_deserialize_reconstructs_frames() -> void:
	var json := '[{"source":"res://test.gd","line":10,"function":"func_a"},{"source":"res://test.gd","line":20,"function":"func_b"}]'
	var trace := GdUnitStackTrace.deserialize(json)
	assert_that(trace).is_equal(GdUnitStackTrace.of([
		GdUnitStackTraceElement.new("res://test.gd", 10, "func_a"),
		GdUnitStackTraceElement.new("res://test.gd", 20, "func_b"),
	]))


func test_serialize_deserialize_round_trip() -> void:
	var original := GdUnitStackTrace.of([
		GdUnitStackTraceElement.new("res://my_test.gd", 42, "check_value"),
		GdUnitStackTraceElement.new("res://my_test.gd", 55, "run_suite"),
	])
	var restored := GdUnitStackTrace.deserialize(original.serialize())
	assert_that(restored).is_equal(original)
#endregion
