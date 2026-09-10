class_name GdUnitTestReporter
extends RefCounted


var _statistics := {}
var _summary := {}


func init_summary() -> void:
	_summary["suite_count"] = 0
	_summary["total_count"] = 0
	_summary["error_count"] = 0
	_summary["failed_count"] = 0
	_summary["skipped_count"] = 0
	_summary["flaky_count"] = 0
	_summary["orphan_nodes"] = 0
	_summary["elapsed_time"] = 0


func init_statistics() -> void:
	_statistics.clear()


func add_test_statistics(event: GdUnitEvent) -> void:
	_statistics[event.guid()] = {
		"error_count" :  event.error_count(),
		"failed_count" : event.failed_count(),
		"skipped_count" : event.skipped_count(),
		"flaky_count" : event.is_flaky() as int,
		"orphan_nodes" : event.orphan_nodes()
	}


func build_test_suite_statisitcs(event: GdUnitEvent) -> Dictionary:
	var statistic :=  {
		"total_count" : _statistics.size(),
		"error_count" : event.error_count(),
		"failed_count" : event.failed_count(),
		"skipped_count" : event.skipped_count(),
		"flaky_count" : 0,
		"orphan_nodes" : event.orphan_nodes()
	}
	_summary["suite_count"] += 1
	_summary["total_count"] += _statistics.size()
	_summary["error_count"] += event.error_count()
	_summary["failed_count"] += event.failed_count()
	_summary["skipped_count"] += event.skipped_count()
	_summary["orphan_nodes"] += event.orphan_nodes()
	_summary["elapsed_time"] += event.elapsed_time()

	for key: String in ["error_count", "failed_count", "skipped_count", "flaky_count", "orphan_nodes"]:
		var value: int = _statistics.values().reduce(get_value.bind(key), 0 )
		statistic[key] += value
		_summary[key] += value

	return statistic


func get_value(acc: int, value: Dictionary, key: String) -> int:
	return acc + value[key]


func processed_suite_count() -> int:
	return _summary["suite_count"]


func total_test_count() -> int:
	return _summary["total_count"]


func total_flaky_count() -> int:
	return _summary["flaky_count"]


func total_error_count() -> int:
	return _summary["error_count"]


func total_failure_count() -> int:
	return _summary["failed_count"]


func total_skipped_count() -> int:
	return _summary["skipped_count"]


func total_orphan_count() -> int:
	return _summary["orphan_nodes"]


func elapsed_time() -> int:
	return _summary["elapsed_time"]


func error_count(statistics: Dictionary) -> int:
	return statistics["error_count"]


func failed_count(statistics: Dictionary) -> int:
	return statistics["failed_count"]


func orphan_nodes(statistics: Dictionary) -> int:
	return statistics["orphan_nodes"]


func skipped_count(statistics: Dictionary) -> int:
	return statistics["skipped_count"]


func flaky_count(statistics: Dictionary) -> int:
	return statistics["flaky_count"]
