# GdUnit generated TestSuite
class_name GdUnitEventTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/event/GdUnitEvent.gd'


func test_GdUnitEvent_defaults() -> void:
	var event := GdUnitEvent.new()

	assert_bool(event.is_success()).is_true()
	assert_bool(event.is_warning()).is_false()
	assert_bool(event.is_failed()).is_false()
	assert_bool(event.is_error()).is_false()
	assert_bool(event.is_skipped()).is_false()

	assert_int(event.elapsed_time()).is_zero()
	assert_int(event.orphan_nodes()).is_zero()
	assert_int(event.total_count()).is_zero()
	assert_int(event.failed_count()).is_zero()
	assert_int(event.skipped_count()).is_zero()
