# GdUnit generated TestSuite
class_name GdUnitGuidTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/discovery/GdUnitGUID.gd'


func test_initialization() -> void:
	# Test initialization with empty string
	var guid_a := GdUnitGUID.new()
	assert_str(guid_a._guid).is_not_empty()

	# Test initialization with existing GUID
	var existing_guid := "12345678-abcd-efgh-ijkl-mnopqrstuvwx"
	var guid_b := GdUnitGUID.new(existing_guid)
	assert_str(guid_b._guid).is_equal(existing_guid)


func test_equals() -> void:
	var guid_a := GdUnitGUID.new()
	var guid_b := GdUnitGUID.new()

	assert_that(guid_a).is_equal(guid_a)
	assert_that(guid_b).is_equal(guid_b)
	assert_that(guid_a).is_not_equal(guid_b)

	assert_bool(guid_a.equals(guid_a)).is_true()
	assert_bool(guid_a.equals(guid_b)).is_false()
	assert_bool(guid_b.equals(guid_a)).is_false()


func test_performance() -> void:
	var time := LocalTime.now()
	var construction_count := 10000.0
	for n in construction_count:
		GdUnitGUID.new()
	var error_message := "Expected to construct %d `GdUnitGUID` instances in less than 50ms but took %s ms" % [construction_count, time.elapsed_since_ms()]
	assert_int(time.elapsed_since_ms())\
		.override_failure_message(error_message)\
		.is_less(50)
	prints("Construction of %d 'GdUnitGUID's tooks %d ms" % [construction_count, time.elapsed_since_ms()])


func test_uniqueness() -> void:
	var _guids := []
	for n in 5000:
		var guid := GdUnitGUID.new()
		assert_bool(_guids.has(guid))\
			.override_failure_message("Expected GUID to be unique but found a duplicate!")\
			.is_false()
		_guids.append(guid)
