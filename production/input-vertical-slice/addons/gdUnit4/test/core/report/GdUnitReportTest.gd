# GdUnit generated TestSuite
class_name GdUnitReportTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/report/GdUnitReport.gd'


#region _to_string

func test_to_string_failure_with_line_number() -> void:
	var report := GdUnitReport.new().create(GdUnitReport.FAILURE, 42, "test message")
	assert_str(report.to_string()).is_equal("[color=green]line [/color][color=aqua]42:[/color] test message")


func test_to_string_failure_with_unknown_line() -> void:
	var report := GdUnitReport.new().create(GdUnitReport.FAILURE, -1, "test message")
	assert_str(report.to_string()).is_equal("[color=green]line [/color][color=aqua]<n/a>:[/color] test message")

#endregion


#region stack_trace

func test_stack_trace_is_null_when_no_error() -> void:
	var report := GdUnitReport.new().create(GdUnitReport.FAILURE, 42, "test message")
	assert_that(report.stack_trace()).is_null()


func test_stack_trace_returns_trace_from_error() -> void:
	var trace := GdUnitStackTrace.of([
		GdUnitStackTraceElement.new("res://test.gd", 10, "func_a"),
		GdUnitStackTraceElement.new("res://test.gd", 20, "func_b"),
	])
	var report := GdUnitReport.new().from_error(GdUnitReport.FAILURE, GdUnitError.new("test message", 10, trace))
	assert_that(report.stack_trace()).is_equal(trace)

#endregion


#region serialize / deserialize

func test_serialize_report_contains_all_base_fields() -> void:
	var serialized := GdUnitReport.new().create(GdUnitReport.FAILURE, 42, "test message").serialize()
	assert_dict(serialized) \
		.contains_key_value("type", GdUnitReport.FAILURE) \
		.contains_key_value("line_number", 42) \
		.contains_key_value("message", "test message")


func test_serialize_report_without_error_has_no_stack_trace_key() -> void:
	var report := GdUnitReport.new().create(GdUnitReport.FAILURE, 42, "test message")
	assert_bool(report.serialize().has("stack_trace")).is_false()


func test_serialize_report_with_error_includes_stack_trace_key() -> void:
	var trace := GdUnitStackTrace.of([
		GdUnitStackTraceElement.new("res://test.gd", 10, "func_a"),
	])
	var serialized := GdUnitReport.new().from_error(GdUnitReport.FAILURE, GdUnitError.new("test message", 10, trace)).serialize()
	assert_dict(serialized).contains_key_value("stack_trace", trace.serialize())


func test_deserialize_without_stack_trace_produces_full_report() -> void:
	var serialized := {"type": GdUnitReport.FAILURE, "line_number": 42, "message": "test message"}
	assert_that(GdUnitReport.new().deserialize(serialized)).is_equal(GdUnitReport.new().create(GdUnitReport.FAILURE, 42, "test message"))


func test_deserialize_reconstructs_full_report() -> void:
	var trace := GdUnitStackTrace.of([
		GdUnitStackTraceElement.new("res://my_test.gd", 10, "func_a"),
		GdUnitStackTraceElement.new("res://my_test.gd", 20, "func_b"),
	])
	var expected := GdUnitReport.new().from_error(GdUnitReport.FAILURE, GdUnitError.new("test message", 10, trace))
	var serialized := {
		"type": GdUnitReport.FAILURE,
		"line_number": 10,
		"message": "test message",
		"stack_trace": trace.serialize()
	}
	assert_that(GdUnitReport.new().deserialize(serialized)).is_equal(expected)


func test_serialize_deserialize_round_trip_preserves_full_report() -> void:
	var original := GdUnitReport.new().from_error(GdUnitReport.FAILURE,
		GdUnitError.new("test message", 42, GdUnitStackTrace.of([
			GdUnitStackTraceElement.new("res://my_test.gd", 42, "check_value"),
			GdUnitStackTraceElement.new("res://my_test.gd", 55, "run_suite"),
		])))
	assert_that(GdUnitReport.new().deserialize(original.serialize())).is_equal(original)

#endregion
