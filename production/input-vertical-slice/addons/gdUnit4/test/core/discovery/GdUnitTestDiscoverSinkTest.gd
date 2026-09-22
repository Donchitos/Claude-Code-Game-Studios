extends GdUnitTestSuite

# example test discovery sink
class TestDiscoverSinkReceiver:

	var _discovered_tests: Array[GdUnitTestCase]

	func _init() -> void:
		GdUnitSignals.instance().gdunit_test_discover_added.connect(on_test_case_discovered)

	func on_test_case_discovered(test_case: GdUnitTestCase) -> void:
		_discovered_tests.append(test_case)


func test_discover() -> void:
	# Create two example test cases
	var test_a := GdUnitTestCase.new()
	test_a.guid = GdUnitGUID.new()
	test_a.test_name = "test_a"
	var test_b := GdUnitTestCase.new()
	test_b.guid = GdUnitGUID.new()
	test_b.test_name = "test_a"

	# Create two discovery sinks
	var receiver := TestDiscoverSinkReceiver.new()
	GdUnitTestDiscoverSink.discover(test_a)
	GdUnitTestDiscoverSink.discover(test_b)
	GdUnitTestDiscoverSink.discover(test_b)

	# verify the sink contains all discovered tests
	assert_array(receiver._discovered_tests).contains_exactly([test_a, test_b, test_b])
