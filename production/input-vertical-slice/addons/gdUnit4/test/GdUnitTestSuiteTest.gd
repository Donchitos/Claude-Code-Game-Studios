# GdUnit generated TestSuite
class_name GdUnitTestSuiteTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/GdUnitTestSuite.gd'

var _events :Array[GdUnitEvent] = []
var _retry_count := 0
var _test_unknown_argument_in_test_case_is_called := false


func collect_report(event :GdUnitEvent) -> void:
	_events.push_back(event)


func before() -> void:
	# register to receive test reports
	GdUnitSignals.instance().gdunit_event.connect(collect_report)
	ProjectSettings.set_setting(GdUnitSettings.TEST_FLAKY_CHECK, true)


func after() -> void:
	# verify the test case `test_unknown_argument_in_test_case` was skipped
	assert_bool(_test_unknown_argument_in_test_case_is_called)\
		.override_failure_message("Expecting 'test_unknown_argument_in_test_case' is skipped!")\
		.is_false()
	GdUnitSignals.instance().gdunit_event.disconnect(collect_report)


func test_assert_that_types() -> void:
	assert_object(assert_that(true)).is_instanceof(GdUnitBoolAssert)
	assert_object(assert_that(1)).is_instanceof(GdUnitIntAssert)
	assert_object(assert_that(3.12)).is_instanceof(GdUnitFloatAssert)
	assert_object(assert_that("abc")).is_instanceof(GdUnitStringAssert)
	assert_object(assert_that(Vector2.ONE)).is_instanceof(GdUnitVectorAssert)
	assert_object(assert_that(Vector2i.ONE)).is_instanceof(GdUnitVectorAssert)
	assert_object(assert_that(Vector3.ONE)).is_instanceof(GdUnitVectorAssert)
	assert_object(assert_that(Vector3i.ONE)).is_instanceof(GdUnitVectorAssert)
	assert_object(assert_that(Vector4.ONE)).is_instanceof(GdUnitVectorAssert)
	assert_object(assert_that(Vector4i.ONE)).is_instanceof(GdUnitVectorAssert)
	assert_object(assert_that([])).is_instanceof(GdUnitArrayAssert)
	assert_object(assert_that({})).is_instanceof(GdUnitDictionaryAssert)
	assert_object(assert_that(GdUnitResult.new())).is_instanceof(GdUnitObjectAssert)
	# all not a built-in types mapped to default GdUnitAssert
	assert_object(assert_that(Color.RED)).is_instanceof(GdUnitAssertImpl)
	assert_object(assert_that(Plane.PLANE_XY)).is_instanceof(GdUnitAssertImpl)


func test_unknown_argument_in_test_case(_invalid_arg :int) -> void:
	_test_unknown_argument_in_test_case_is_called = true
	fail("This test case should be not executed, it must be skipped.")


func test_find_child() -> void:
	var node_a :Node3D = auto_free(Node3D.new())
	node_a.set_name("node_a")
	var node_b :Node3D = auto_free(Node3D.new())
	node_b.set_name("node_b")
	var node_c :Node3D = auto_free(Node3D.new())
	node_c.set_name("node_c")
	add_child(node_a, true)
	node_a.add_child(node_b, true)
	node_b.add_child(node_c, true)

	assert_object(find_child("node_a", true, false)).is_same(node_a)
	assert_object(find_child("node_b", true, false)).is_same(node_b)
	assert_object(find_child("node_c", true, false)).is_same(node_c)


func test_find_by_path() -> void:
	var node_a :Node3D = auto_free(Node3D.new())
	node_a.set_name("node_a")
	var node_b :Node3D = auto_free(Node3D.new())
	node_b.set_name("node_b")
	var node_c :Node3D = auto_free(Node3D.new())
	node_c.set_name("node_c")
	add_child(node_a, true)
	node_a.add_child(node_b, true)
	node_b.add_child(node_c, true)

	assert_object(get_node(node_a.get_path())).is_same(node_a)
	assert_object(get_node(node_b.get_path())).is_same(node_b)
	assert_object(get_node(node_c.get_path())).is_same(node_c)


func test_flaky_success() -> void:
	_retry_count += 1
	# do fail on first two retries
	if _retry_count <= 2:
		fail("failure 1: at retry %d" % _retry_count)
		fail("failure 2: at retry %d" % _retry_count)
