# this test test for serialization and deserialization succcess
# of GdUnitEvent class
extends GdUnitTestSuite


func test_serde_suite_before() -> void:
	var event := GdUnitEvent.new().suite_before("path", "test_suite_a", 22)
	var serialized := event.serialize()
	var deserialized := GdUnitEvent.new().deserialize(serialized)
	assert_object(deserialized).is_instanceof(GdUnitEvent)
	assert_that(deserialized).is_equal(event)


func test_serde_suite_after() -> void:
	var event := GdUnitEvent.new().suite_after("path","test_suite_a")
	var serialized := event.serialize()
	var deserialized := GdUnitEvent.new().deserialize(serialized)
	assert_that(deserialized).is_equal(event)


func test_serde_test_before() -> void:
	var event := GdUnitEvent.new().test_before(GdUnitGUID.new())
	var serialized := event.serialize()
	var deserialized := GdUnitEvent.new().deserialize(serialized)
	assert_that(deserialized).is_equal(event)


func test_serde_test_after_no_report() -> void:
	var event := GdUnitEvent.new().test_after(GdUnitGUID.new(), "test_case_a")
	var serialized := event.serialize()
	var deserialized := GdUnitEvent.new().deserialize(serialized)
	assert_that(deserialized).is_equal(event)


func test_serde_test_after_with_report() -> void:
	var reports :Array[GdUnitReport] = [\
		GdUnitReport.new().create(GdUnitReport.FAILURE, 24, "this is a error a"), \
		GdUnitReport.new().create(GdUnitReport.FAILURE, 26, "this is a error b")]
	var event := GdUnitEvent.new().test_after(GdUnitGUID.new(), "test_case_a", {}, reports)

	var serialized := event.serialize()
	var deserialized := GdUnitEvent.new().deserialize(serialized)
	assert_that(deserialized).is_equal(event)
	assert_array(deserialized.reports()).contains_exactly(reports)


func test_serde_TestReport() -> void:
	var report := GdUnitReport.new().create(GdUnitReport.FAILURE, 24, "this is a error")
	var serialized := report.serialize()
	var deserialized := GdUnitReport.new().deserialize(serialized)
	assert_that(deserialized).is_equal(report)
