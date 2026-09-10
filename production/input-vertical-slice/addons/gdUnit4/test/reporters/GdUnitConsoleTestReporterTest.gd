# GdUnit generated TestSuite
class_name GdUnitConsoleTestReporterTest
extends GdUnitTestSuite


var reporter := GdUnitConsoleTestReporter.new(GdUnitCSIMessageWriter.new())


func before_test() -> void:
	reporter.test_session = GdUnitTestSession.new([], "res://reports")
	reporter.on_gdunit_event(GdUnitInit.new())


func test_on_gdunit_event_init() -> void:
	assert_int(reporter.processed_suite_count()).is_equal(0)
	assert_int(reporter.total_test_count()).is_equal(0)
	assert_int(reporter.total_flaky_count()).is_equal(0)
	assert_int(reporter.total_error_count()).is_equal(0)
	assert_int(reporter.total_failure_count()).is_equal(0)
	assert_int(reporter.total_skipped_count()).is_equal(0)
	assert_int(reporter.total_orphan_count()).is_equal(0)
	assert_int(reporter.elapsed_time()).is_equal(0)


func test_on_gdunit_event_empty_test_suite() -> void:
	reporter.on_gdunit_event(GdUnitEvent.new().suite_before("res://tests/suite_a.gd", "suide_a", 0))
	reporter.on_gdunit_event(GdUnitEvent.new().suite_after("res://tests/suite_a.gd", "suide_a"))

	assert_int(reporter.processed_suite_count()).is_equal(1)
	assert_int(reporter.total_test_count()).is_equal(0)
	assert_int(reporter.total_flaky_count()).is_equal(0)
	assert_int(reporter.total_error_count()).is_equal(0)
	assert_int(reporter.total_failure_count()).is_equal(0)
	assert_int(reporter.total_skipped_count()).is_equal(0)
	assert_int(reporter.total_orphan_count()).is_equal(0)
	assert_int(reporter.elapsed_time()).is_equal(0)


func test_on_gdunit_event_full_test_suite() -> void:
	var test_id_a := GdUnitGUID.new()
	var test_id_b := GdUnitGUID.new()
	var test_id_c := GdUnitGUID.new()
	reporter.on_gdunit_event(GdUnitEvent.new().suite_before("res://tests/suite_a.gd", "suide_a", 0))
	reporter.on_gdunit_event(GdUnitEvent.new().test_before(test_id_a))
	reporter.on_gdunit_event(GdUnitEvent.new().test_after(test_id_a, "test_a"))
	reporter.on_gdunit_event(GdUnitEvent.new().test_before(test_id_b))
	reporter.on_gdunit_event(GdUnitEvent.new().test_after(test_id_b, "test_b"))
	reporter.on_gdunit_event(GdUnitEvent.new().test_before(test_id_c))
	reporter.on_gdunit_event(GdUnitEvent.new().test_after(test_id_c, "test_c"))
	reporter.on_gdunit_event(GdUnitEvent.new().suite_after("res://tests/suite_a.gd", "suide_a"))

	assert_int(reporter.processed_suite_count()).is_equal(1)
	assert_int(reporter.total_test_count()).is_equal(3)
	assert_int(reporter.total_flaky_count()).is_equal(0)
	assert_int(reporter.total_error_count()).is_equal(0)
	assert_int(reporter.total_failure_count()).is_equal(0)
	assert_int(reporter.total_skipped_count()).is_equal(0)
	assert_int(reporter.total_orphan_count()).is_equal(0)
	assert_int(reporter.elapsed_time()).is_equal(0)
