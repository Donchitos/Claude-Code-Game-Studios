class_name GdUnitEvent
extends Resource

const WARNINGS = "warnings"
const FAILED = "failed"
const FLAKY = "flaky"
const ERRORS = "errors"
const SKIPPED = "skipped"
const ELAPSED_TIME = "elapsed_time"
const ORPHAN_NODES = "orphan_nodes"
const ERROR_COUNT = "error_count"
const FAILED_COUNT = "failed_count"
const SKIPPED_COUNT = "skipped_count"
const RETRY_COUNT = "retry_count"

enum {
	INIT,
	STOP,
	TESTSUITE_BEFORE,
	TESTSUITE_AFTER,
	TESTCASE_BEFORE,
	TESTCASE_AFTER,
	DISCOVER_START,
	DISCOVER_END,
	SESSION_START,
	SESSION_CLOSE
}

var _event_type: int
var _guid: GdUnitGUID
var _resource_path: String
var _suite_name: String
var _test_name: String
var _total_count: int = 0
var _statistics := Dictionary()
var _reports: Array[GdUnitReport] = []


func suite_before(p_resource_path: String, p_suite_name: String, p_total_count: int) -> GdUnitEvent:
	_guid = GdUnitGUID.new()
	_event_type = TESTSUITE_BEFORE
	_resource_path = p_resource_path
	_suite_name = p_suite_name
	_test_name = "before"
	_total_count = p_total_count
	return self


func suite_after(p_resource_path: String, p_suite_name: String, p_statistics: Dictionary = {}, p_reports: Array[GdUnitReport] = []) -> GdUnitEvent:
	_guid = GdUnitGUID.new()
	_event_type = TESTSUITE_AFTER
	_resource_path = p_resource_path
	_suite_name  = p_suite_name
	_test_name = "after"
	_statistics = p_statistics
	_reports = p_reports
	return self


func test_before(p_guid: GdUnitGUID) -> GdUnitEvent:
	_event_type = TESTCASE_BEFORE
	_guid = p_guid
	return self


func test_after(p_guid: GdUnitGUID, name: String, p_statistics: Dictionary = {}, p_reports :Array[GdUnitReport] = []) -> GdUnitEvent:
	_event_type = TESTCASE_AFTER
	_guid = p_guid
	_test_name = name
	_statistics = p_statistics
	_reports = p_reports
	return self


func type() -> int:
	return _event_type


func guid() -> GdUnitGUID:
	return _guid


func suite_name() -> String:
	return _suite_name


func test_name() -> String:
	return _test_name


func elapsed_time() -> int:
	return _statistics.get(ELAPSED_TIME, 0)


func orphan_nodes() -> int:
	return  _statistics.get(ORPHAN_NODES, 0)


func statistic(p_type :String) -> int:
	return _statistics.get(p_type, 0)


func total_count() -> int:
	return _total_count


func success_count() -> int:
	return total_count() - error_count() - failed_count() - skipped_count()


func error_count() -> int:
	return _statistics.get(ERROR_COUNT, 0)


func failed_count() -> int:
	return _statistics.get(FAILED_COUNT, 0)


func skipped_count() -> int:
	return _statistics.get(SKIPPED_COUNT, 0)


func retry_count() -> int:
	return _statistics.get(RETRY_COUNT, 0)


func resource_path() -> String:
	return _resource_path


func is_success() -> bool:
	return not is_failed() and not is_error()


func is_warning() -> bool:
	return _statistics.get(WARNINGS, false) or orphan_nodes() > 0


func is_failed() -> bool:
	return _statistics.get(FAILED, false)


func is_error() -> bool:
	return _statistics.get(ERRORS, false)


func is_flaky() -> bool:
	return _statistics.get(FLAKY, false)


func is_skipped() -> bool:
	return _statistics.get(SKIPPED, false)


func reports() -> Array[GdUnitReport]:
	return _reports


func _to_string() -> String:
	return "Event: %s id:%s %s:%s, %s, %s" % [_event_type, _guid, _suite_name, _test_name, _statistics, _reports]


func serialize() -> Dictionary:
	var serialized := {
		"type"         : _event_type,
		"resource_path": _resource_path,
		"suite_name"   : _suite_name,
		"test_name"    : _test_name,
		"total_count"  : _total_count,
		"statistics"    : _statistics
	}
	if _guid != null:
		serialized["guid"] = _guid._guid
	serialized["reports"] = _serialize_TestReports()
	return serialized


func deserialize(serialized: Dictionary) -> GdUnitEvent:
	_event_type    = serialized.get("type", null)
	_guid          = GdUnitGUID.new(str(serialized.get("guid", "")))
	_resource_path = serialized.get("resource_path", null)
	_suite_name    = serialized.get("suite_name", null)
	_test_name     = serialized.get("test_name", "unknown")
	_total_count   = serialized.get("total_count", 0)
	_statistics    = serialized.get("statistics", Dictionary())
	if serialized.has("reports"):
		# needs this workaround to copy typed values in the array
		var reports_to_deserializ :Array[Dictionary] = []
		@warning_ignore("unsafe_cast")
		reports_to_deserializ.append_array(serialized.get("reports") as Array)
		_reports = _deserialize_reports(reports_to_deserializ)
	return self


func _serialize_TestReports() -> Array[Dictionary]:
	var serialized_reports :Array[Dictionary] = []
	for report in _reports:
		serialized_reports.append(report.serialize())
	return serialized_reports


func _deserialize_reports(p_reports: Array[Dictionary]) -> Array[GdUnitReport]:
	var deserialized_reports :Array[GdUnitReport] = []
	for report in p_reports:
		var test_report := GdUnitReport.new().deserialize(report)
		deserialized_reports.append(test_report)
	return deserialized_reports
