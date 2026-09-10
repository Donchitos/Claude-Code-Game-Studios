# GdUnit generated TestSuite
class_name GdUnitInspectorTreeMainPanelTest
extends GdUnitTestSuite

# TestSuite generated from
const GdUnitInspectorTreeMainPanel := preload('res://addons/gdUnit4/src/ui/parts/GdUnitInspectorTreeMainPanel.gd')

const FAILED := GdUnitInspectorTreeMainPanel.STATE.FAILED
const ERROR := GdUnitInspectorTreeMainPanel.STATE.ERROR
const FLAKY := GdUnitInspectorTreeMainPanel.STATE.FLAKY


const META_SCRIPT_PATH := "script_path"

var suite_a_item: TreeItem
var suite_b_item: TreeItem
var suite_c_item: TreeItem

var discovered_tests_suite_a := {}
var discovered_tests_suite_b := {}
var discovered_tests_suite_c := {}


var _inspector: GdUnitInspectorTreeMainPanel


func before_test() -> void:
	@warning_ignore("unsafe_method_access")
	_inspector = load("res://addons/gdUnit4/src/ui/parts/GdUnitInspectorTreeMainPanel.tscn").instantiate()
	_inspector.disable_test_recovery()
	add_child(_inspector)
	_inspector.init_tree()
	setup_example_tree()


func after_test() -> void:
	if is_instance_valid(_inspector):
		_inspector.cleanup_tree()
		remove_child(_inspector)
		_inspector.free()
		# Give the engine time to queue_free marked objects
		await await_idle_frame()


func setup_example_tree() -> void:
	# load a testsuite
	setup_test_env()

	# verify no failures are exists
	assert_array(_inspector._on_select_next_item_by_state(FAILED)).is_null()


func discover_sink(test_case: GdUnitTestCase) -> void:
	_inspector.on_test_case_discover_added(test_case)


func setup_test_env() -> void:
	var suite_a := GdUnitTestResourceLoader.load_gd_script("res://addons/gdUnit4/test/ui/parts/resources/foo/ExampleTestSuiteA.resource", true)
	var suite_b := GdUnitTestResourceLoader.load_gd_script("res://addons/gdUnit4/test/ui/parts/resources/foo/ExampleTestSuiteB.resource", true)
	var suite_c := GdUnitTestResourceLoader.load_gd_script("res://addons/gdUnit4/test/ui/parts/resources/foo/ExampleTestSuiteC.resource", true)


	GdUnitTestDiscoverer.discover_tests(suite_a, func(discover_test: GdUnitTestCase) -> void:
		discover_sink(discover_test)
		discovered_tests_suite_a[discover_test.test_name] = discover_test
	)
	GdUnitTestDiscoverer.discover_tests(suite_b, func(discover_test: GdUnitTestCase) -> void:
		discover_sink(discover_test)
		discovered_tests_suite_b[discover_test.test_name] = discover_test
	)
	GdUnitTestDiscoverer.discover_tests(suite_c, func(discover_test: GdUnitTestCase) -> void:
		discover_sink(discover_test)
		discovered_tests_suite_c[discover_test.test_name] = discover_test
	)

	suite_a_item = _inspector._find_tree_item_by_test_suite(_inspector._tree_root, suite_a.resource_path, "ExampleTestSuiteA")
	suite_b_item = _inspector._find_tree_item_by_test_suite(_inspector._tree_root, suite_b.resource_path, "ExampleTestSuiteB")
	suite_c_item = _inspector._find_tree_item_by_test_suite(_inspector._tree_root, suite_c.resource_path, "ExampleTestSuiteC")


func set_test_state(test_cases: Array[GdUnitTestCase], state: GdUnitInspectorTreeMainPanel.STATE) -> void:
	for test in test_cases:
		var item := _inspector._find_tree_item_by_id(_inspector._tree_root, test.guid)
		var test_event := GdUnitEvent.new().test_after(test.guid, "test")
		match state:
			ERROR:
				_inspector.set_state_error(item)
				_inspector.add_report(item, GdUnitReport.new().create(GdUnitReport.INTERUPTED, 42, "an error"))
			FAILED:
				_inspector.set_state_failed(item, test_event)
				_inspector.add_report(item, GdUnitReport.new().create(GdUnitReport.FAILURE, 42, "an failure"))
			FLAKY:
				_inspector.set_state_flaky(item, test_event)


	#		_inspector.set_state_succeded(item)


func get_item_state(parent :TreeItem, item_name :String = "") -> int:
	for item in parent.get_children():
		if item.get_text(0) == item_name:
			return GdUnitInspectorTreeMainPanel.get_item_state(item)[0]
	return GdUnitInspectorTreeMainPanel.get_item_state(parent)[0]


func test_find_item_by_id() -> void:
	var suite_script := GdUnitTestResourceLoader.load_gd_script("res://addons/gdUnit4/test/ui/parts/resources/bar/ExampleTestSuiteA.resource", true)
	var discovered_tests := {}
	GdUnitTestDiscoverer.discover_tests(suite_script, func(discover_test: GdUnitTestCase) -> void:
		discover_sink(discover_test)
		discovered_tests[discover_test.test_name] = discover_test
	)
	var test_aa: GdUnitTestCase = discovered_tests["test_aa"]
	var item := _inspector._find_tree_item_by_id(_inspector._tree_root, test_aa.guid)
	assert_object(item).is_not_null()


# Tests a special case, the test is named equal to the test suite
func test_find_item_by_id_GD809() -> void:
	var suite_script := GdUnitTestResourceLoader.load_gd_script("res://addons/gdUnit4/test/ui/parts/resources/gd_809/test_example.resource")
	var discovered_tests := {}
	GdUnitTestDiscoverer.discover_tests(suite_script, func(discover_test: GdUnitTestCase) -> void:
		discover_sink(discover_test)
		discovered_tests[discover_test.test_name] = discover_test
	)
	assert_dict(discovered_tests).contains_keys(["test_example", "test_example_b"])
	var test_aa: GdUnitTestCase = discovered_tests["test_example"]
	var item := _inspector._find_tree_item_by_id(_inspector._tree_root, test_aa.guid)
	assert_object(item).is_not_null()


# Tests a special case, the test is named equal to the test suite
func test_find_item_by_path_GD809() -> void:
	var suite_script := GdUnitTestResourceLoader.load_gd_script("res://addons/gdUnit4/test/ui/parts/resources/gd_809/test_example.resource")
	var discovered_tests := {}
	GdUnitTestDiscoverer.discover_tests(suite_script, func(discover_test: GdUnitTestCase) -> void:
		discover_sink(discover_test)
		discovered_tests[discover_test.test_name] = discover_test
	)
	assert_dict(discovered_tests).contains_keys(["test_example", "test_example_b"])
	var test_example: GdUnitTestCase = discovered_tests["test_example"]
	var test_example_b: GdUnitTestCase = discovered_tests["test_example"]
	# find test_suite by path
	var item := _inspector._find_tree_item_by_test_suite(_inspector._tree_root, test_example.suite_resource_path, "test_example")
	assert_object(item).is_not_null()
	# find tests by id
	assert_object(_inspector._find_tree_item_by_id(_inspector._tree_root, test_example.guid)).is_not_null()
	assert_object(_inspector._find_tree_item_by_id(_inspector._tree_root, test_example_b.guid)).is_not_null()


func test_select_first_failure() -> void:
	# test initial nothing is selected
	assert_object(_inspector._tree.get_selected()).is_null()

	# we have no failures or errors
	_inspector._on_select_next_item_by_state(FAILED)
	assert_object(_inspector._tree.get_selected()).is_null()

	# add failures
	set_test_state([
		discovered_tests_suite_a["test_aa"],
		discovered_tests_suite_a["test_ad"],
		discovered_tests_suite_c["test_cb"],
		discovered_tests_suite_c["test_cc"],
		discovered_tests_suite_c["test_ce"]]
		, FAILED)

	# select first failure
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_aa")


func test_select_last_failure() -> void:
	# test initial nothing is selected
	assert_object(_inspector._tree.get_selected()).is_null()

	# we have no failures or errors
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_object(_inspector._tree.get_selected()).is_null()

	# add failures
	set_test_state([
		discovered_tests_suite_a["test_aa"],
		discovered_tests_suite_a["test_ad"],
		discovered_tests_suite_c["test_cb"],
		discovered_tests_suite_c["test_cc"],
		discovered_tests_suite_c["test_ce"]]
		, FAILED)
	# select last failure
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ce")


func test_select_next_failure() -> void:
	# test initial nothing is selected
	assert_object(_inspector._tree.get_selected()).is_null()

	# first time select next but no failure exists
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected()).is_null()

	# add failures
	set_test_state([
		discovered_tests_suite_a["test_aa"],
		discovered_tests_suite_a["test_ad"],
		discovered_tests_suite_c["test_cb"],
		discovered_tests_suite_c["test_cc"],
		discovered_tests_suite_c["test_ce"]]
		, FAILED)

	# first time select next than select first failure
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_aa")
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ad")
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cb")
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cc")
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ce")
	# if current last failure selected than select first as next
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_aa")
	_inspector._on_select_next_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ad")


func test_select_previous_failure() -> void:
	# test initial nothing is selected
	assert_object(_inspector._tree.get_selected()).is_null()

	# first time select previous but no failure exists
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected()).is_null()

	# add failures
	set_test_state([
		discovered_tests_suite_a["test_aa"],
		discovered_tests_suite_a["test_ad"],
		discovered_tests_suite_c["test_cb"],
		discovered_tests_suite_c["test_cc"],
		discovered_tests_suite_c["test_ce"]]
		, FAILED)

	# first time select previous than select last failure
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ce")
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cc")
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cb")
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ad")
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_aa")
	# if current first failure selected than select last as next
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ce")
	_inspector._on_select_previous_item_by_state(FAILED)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cc")


func test_select_next_flaky() -> void:
	# test initial nothing is selected
	assert_object(_inspector._tree.get_selected()).is_null()

	# try select next but no flaky exists
	_inspector._on_select_next_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected()).is_null()

	# add flaky tests
	set_test_state([
		discovered_tests_suite_c["test_cb"],
		discovered_tests_suite_c["test_cc"],
		discovered_tests_suite_c["test_ce"]]
		, FLAKY)

	# first time select next than select first failure
	_inspector._on_select_next_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cb")
	_inspector._on_select_next_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cc")
	_inspector._on_select_next_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ce")
	# if current last failure selected than select first as next
	_inspector._on_select_next_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cb")
	_inspector._on_select_next_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cc")


func test_select_previous_flaky() -> void:
	# test initial nothing is selected
	assert_object(_inspector._tree.get_selected()).is_null()

	# try select previous but no flaky exists
	_inspector._on_select_previous_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected()).is_null()

	# add failures
	set_test_state([
		discovered_tests_suite_c["test_cb"],
		discovered_tests_suite_c["test_cc"],
		discovered_tests_suite_c["test_ce"]]
		, FLAKY)

	# first time select previous than select last failure
	_inspector._on_select_previous_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ce")
	_inspector._on_select_previous_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cc")
	_inspector._on_select_previous_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cb")
	# if current first failure selected than select last as next
	_inspector._on_select_previous_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_ce")
	_inspector._on_select_previous_item_by_state(FLAKY)
	assert_str(_inspector._tree.get_selected().get_text(0)).is_equal("test_cc")


func test_suite_text_shows_amount_of_cases() -> void:
	assert_str(suite_a_item.get_text(0)).is_equal("(0/5) ExampleTestSuiteA")
	assert_str(suite_b_item.get_text(0)).is_equal("(0/3) ExampleTestSuiteB")


func test_suite_text_responds_to_test_case_events() -> void:

	var test_aa: GdUnitTestCase = discovered_tests_suite_a["test_aa"]
	var test_ab: GdUnitTestCase = discovered_tests_suite_a["test_ab"]
	var test_ac: GdUnitTestCase = discovered_tests_suite_a["test_ac"]
	var test_ad: GdUnitTestCase = discovered_tests_suite_a["test_ad"]
	var test_ae: GdUnitTestCase = discovered_tests_suite_a["test_ae"]
	var success_aa := GdUnitEvent.new().test_after(test_aa.guid, "test_aa")
	_inspector._on_gdunit_event(success_aa)
	assert_str(suite_a_item.get_text(0)).is_equal("(1/5) ExampleTestSuiteA")

	var error_ad := GdUnitEvent.new().test_after(test_ad.guid, "test_ad", {GdUnitEvent.ERRORS: true})
	_inspector._on_gdunit_event(error_ad)
	assert_str(suite_a_item.get_text(0)).is_equal("(1/5) ExampleTestSuiteA")

	var failure_ab := GdUnitEvent.new().test_after(test_ab.guid, "test_ab", {GdUnitEvent.FAILED: true})
	_inspector._on_gdunit_event(failure_ab)
	assert_str(suite_a_item.get_text(0)).is_equal("(1/5) ExampleTestSuiteA")

	var skipped_ac := GdUnitEvent.new().test_after(test_ac.guid, "test_ac", {GdUnitEvent.SKIPPED: true})
	_inspector._on_gdunit_event(skipped_ac)
	assert_str(suite_a_item.get_text(0)).is_equal("(2/5) ExampleTestSuiteA")

	var success_ae := GdUnitEvent.new().test_after(test_ae.guid, "test_ae")
	_inspector._on_gdunit_event(success_ae)
	assert_str(suite_a_item.get_text(0)).is_equal("(3/5) ExampleTestSuiteA")


# test coverage for issue GD-117
func test_update_test_case_on_multiple_test_suite_with_same_name() -> void:
	# add a second test suite where has same name as suite_a_item
	var suite_script := GdUnitTestResourceLoader.load_gd_script("res://addons/gdUnit4/test/ui/parts/resources/bar/ExampleTestSuiteA.resource", true)
	var discovered_tests := {}
	GdUnitTestDiscoverer.discover_tests(suite_script, func(discover_test: GdUnitTestCase) -> void:
		discover_sink(discover_test)
		discovered_tests[discover_test.test_name] = discover_test
	)
	var suite_item := _inspector._find_tree_item_by_test_suite(_inspector._tree_root, suite_script.resource_path, "ExampleTestSuiteA")
	assert_object(suite_item).is_not_same(suite_a_item)

	# verify inital state
	assert_str(suite_item.get_text(0)).is_equal("(0/5) ExampleTestSuiteA")
	assert_int(get_item_state(suite_item, "test_aa")).is_equal(_inspector.STATE.INITIAL)
	assert_str(suite_a_item.get_text(0)).is_equal("(0/5) ExampleTestSuiteA")

	# set test starting checked suite_a_item
	var test_aa: GdUnitTestCase = discovered_tests["test_aa"]
	var test_ab: GdUnitTestCase = discovered_tests["test_ab"]
	_inspector._on_gdunit_event(GdUnitEvent.new().test_before(test_aa.guid))
	_inspector._on_gdunit_event(GdUnitEvent.new().test_before(test_ab.guid))
	assert_str(suite_item.get_text(0)).is_equal("(0/5) ExampleTestSuiteA")
	assert_int(get_item_state(suite_item, "test_aa")).is_equal(_inspector.STATE.RUNNING)
	assert_int(get_item_state(suite_item, "test_ab")).is_equal(_inspector.STATE.RUNNING)
	# test suite_a_item is not affected
	assert_str(suite_a_item.get_text(0)).is_equal("(0/5) ExampleTestSuiteA")
	assert_int(get_item_state(suite_a_item, "test_aa")).is_equal(_inspector.STATE.INITIAL)
	assert_int(get_item_state(suite_a_item, "test_ab")).is_equal(_inspector.STATE.INITIAL)

	# finish the tests with success
	_inspector._on_gdunit_event(GdUnitEvent.new().test_after(test_aa.guid, "test_aa"))
	_inspector._on_gdunit_event(GdUnitEvent.new().test_after(test_ab.guid, "test_bb"))

	# verify updated state checked suite_a_item
	assert_str(suite_item.get_text(0)).is_equal("(2/5) ExampleTestSuiteA")
	assert_int(get_item_state(suite_item, "test_aa")).is_equal(_inspector.STATE.SUCCESS)
	assert_int(get_item_state(suite_item, "test_ab")).is_equal(_inspector.STATE.SUCCESS)
	# test suite_a_item is not affected
	assert_str(suite_a_item.get_text(0)).is_equal("(0/5) ExampleTestSuiteA")
	assert_int(get_item_state(suite_a_item, "test_aa")).is_equal(_inspector.STATE.INITIAL)
	assert_int(get_item_state(suite_a_item, "test_ab")).is_equal(_inspector.STATE.INITIAL)


# Test coverage for issue GD-278: GdUnit Inspector: Test marks as passed if both warning and error
func test_update_icon_state() -> void:
	var suite_script := GdUnitTestResourceLoader.load_gd_script("res://addons/gdUnit4/test/core/execution/resources/orphans/TestSuiteFailAndOrpahnsDetected.gd", true)
	var discovered_tests := {}
	GdUnitTestDiscoverer.discover_tests(suite_script, func(discover_test: GdUnitTestCase) -> void:
		discover_sink(discover_test)
		discovered_tests[discover_test.test_name] = discover_test
	)
	var suite_script_path := suite_script.resource_path
	var suite_name := "TestSuiteFailAndOrpahnsDetected"
	var suite_item := _inspector._find_tree_item_by_test_suite(_inspector._tree_root, suite_script_path, suite_name)

	# Verify the inital state
	assert_str(suite_item.get_text(0)).is_equal("(0/2) " + suite_name)
	assert_int(get_item_state(suite_item)).is_equal(_inspector.STATE.INITIAL)
	assert_int(get_item_state(suite_item, "test_case1")).is_equal(_inspector.STATE.INITIAL)
	assert_int(get_item_state(suite_item, "test_case2")).is_equal(_inspector.STATE.INITIAL)

	# Set tests to running
	var test_case1: GdUnitTestCase = discovered_tests["test_case1"]
	var test_case2: GdUnitTestCase = discovered_tests["test_case2"]
	_inspector._on_gdunit_event(GdUnitEvent.new().test_before(test_case1.guid))
	_inspector._on_gdunit_event(GdUnitEvent.new().test_before(test_case2.guid))
	# Verify all items on state running.
	assert_str(suite_item.get_text(0)).is_equal("(0/2) " + suite_name)
	assert_int(get_item_state(suite_item, "test_case1")).is_equal(_inspector.STATE.RUNNING)
	assert_int(get_item_state(suite_item, "test_case2")).is_equal(_inspector.STATE.RUNNING)

	# Simulate test processed and fails on test_case2
	# test_case1 succeeded
	_inspector._on_gdunit_event(GdUnitEvent.new().test_after(test_case1.guid, "test_case1"))
	# test_case2 is failing by an orphan warning and an failure
	_inspector._on_gdunit_event(GdUnitEvent.new().test_after(test_case2.guid, "test_case2", {GdUnitEvent.FAILED: true}))
	# We check whether a test event with a warning does not overwrite a higher object status, e.g. an error.
	_inspector._on_gdunit_event(GdUnitEvent.new().test_after(test_case2.guid, "test_case2", {GdUnitEvent.WARNINGS: true}))
	# at last the suite after event
	_inspector._on_gdunit_event(GdUnitEvent.new().suite_after(suite_script_path, suite_name, {}))

	# Verify the final state
	assert_str(suite_item.get_text(0)).is_equal("(2/2) " + suite_name)
	assert_int(get_item_state(suite_item)).is_equal(_inspector.STATE.FAILED)
	assert_int(get_item_state(suite_item, "test_case1")).is_equal(_inspector.STATE.SUCCESS)
	assert_int(get_item_state(suite_item, "test_case2")).is_equal(_inspector.STATE.FAILED)


func test_tree_view_mode_tree() -> void:
	var root: TreeItem = _inspector._tree_root

	var childs := root.get_children()
	assert_array(childs).extract("get_text", [0]).contains_exactly(["(0/13) ui"])


func test_custom_sort_by_original_index() -> void:
	var tree :Tree = auto_free(Tree.new())
	var tree_root := tree.create_item()

	create_folder_item(tree_root, "folder_a")
	create_test_item(tree_root, "test_a")
	create_test_item(tree_root, "test_b")
	create_folder_item(tree_root, "folder_b")
	create_test_item(tree_root, "test_c")

	for n in 10:
		# suffle to have a random order
		tree_root.get_children().shuffle()
		# sort it by original index
		GdUnitInspectorTreeMainPanel._sort_tree_items(tree_root, GdUnitInspectorTreeConstants.SORT_MODE.UNSORTED)
		# verify
		assert_array(tree_root.get_children()).extractv(ItemNameExtractor.new()).contains_exactly([
			# folders should be always on top
			"folder_a", "folder_b",
			"test_a", "test_b", "test_c"])
		if is_failure():
			break


func test_custom_sort_by_name_ascending() -> void:
	var tree :Tree = auto_free(Tree.new())
	var tree_root := tree.create_item()

	create_folder_item(tree_root, "folder_a")
	create_test_item(tree_root, "test_a")
	create_test_item(tree_root, "test_b")
	create_folder_item(tree_root, "folder_b")
	create_test_item(tree_root, "test_c")

	for n in 10:
		# suffle to have a random order
		tree_root.get_children().shuffle()
		# sort it by name ascending
		GdUnitInspectorTreeMainPanel._sort_tree_items(tree_root, GdUnitInspectorTreeConstants.SORT_MODE.NAME_ASCENDING)
		# verify
		assert_array(tree_root.get_children()).extractv(ItemNameExtractor.new()).contains_exactly([
			# folders should be always on top
			"folder_a", "folder_b",
			"test_a", "test_b", "test_c"])
		if is_failure():
			break


func test_custom_sort_by_name_descending() -> void:
	var tree :Tree = auto_free(Tree.new())
	var tree_root := tree.create_item()

	create_folder_item(tree_root, "folder_a")
	create_test_item(tree_root, "test_a")
	create_test_item(tree_root, "test_b")
	create_folder_item(tree_root, "folder_b")
	create_test_item(tree_root, "test_c")

	for n in 10:
		# suffle to have a random order
		tree_root.get_children().shuffle()
		# sort it by name descending
		GdUnitInspectorTreeMainPanel._sort_tree_items(tree_root, GdUnitInspectorTreeConstants.SORT_MODE.NAME_DESCENDING)
		# verify
		assert_array(tree_root.get_children()).extractv(ItemNameExtractor.new()).contains_exactly([
			# folders should be always on top
			"folder_b", "folder_a",
			"test_c", "test_b", "test_a"])
		if is_failure():
			break

func test_custom_sort_by_execution_time() -> void:
	var tree :Tree = auto_free(Tree.new())
	var tree_root := tree.create_item()

	create_folder_item(tree_root, "folder_a", 1000)
	create_test_item(tree_root, "test_a", 500)
	create_test_item(tree_root, "test_b", 600)
	create_folder_item(tree_root, "folder_b", 1500)
	create_test_item(tree_root, "test_c", 300)

	for n in 10:
		# suffle to have a random order
		tree_root.get_children().shuffle()
		# sort it by execution time
		GdUnitInspectorTreeMainPanel._sort_tree_items(tree_root, GdUnitInspectorTreeConstants.SORT_MODE.EXECUTION_TIME)
		# verify
		assert_array(tree_root.get_children()).extractv(ItemNameExtractor.new()).contains_exactly([
			# folders should be always on top
			"folder_b", "folder_a",
			"test_b", "test_a", "test_c"])
		if is_failure():
			break


func create_test_item(parent: TreeItem, test_name: String, execution_time := 0 ) -> TreeItem:
	var item := parent.create_child()
	var index := parent.get_child_count()
	item.set_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_TYPE, GdUnitInspectorTreeMainPanel.GdUnitType.TEST_CASE)
	item.set_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_NAME, test_name)
	item.set_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_ORIGINAL_INDEX, index)
	item.set_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_EXECUTION_TIME, execution_time)
	return item


func create_folder_item(parent: TreeItem, folder_name: String, execution_time := 0) -> TreeItem:
	var item := parent.create_child()
	var index := parent.get_child_count()
	item.set_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_TYPE, GdUnitInspectorTreeMainPanel.GdUnitType.FOLDER)
	item.set_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_NAME, folder_name)
	item.set_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_ORIGINAL_INDEX, index)
	item.set_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_EXECUTION_TIME, execution_time)
	return item

func test_discover_tests() -> void:
	# verify the InspectorProgressBar is connected to gdunit_test_discovered signal
	assert_bool(GdUnitSignals.instance().gdunit_test_discover_added.is_connected(_inspector.on_test_case_discover_added))\
		.override_failure_message("The 'InspectorProgressBar' must be connected to signal 'gdunit_test_discovered'")\
		.is_true()


func test_on_test_case_discover_added() -> void:
	_inspector.init_tree()
	_inspector.on_test_case_discover_added(GdUnitTestCase.from("res://addons/gdUnit4/test/dir_a/dir_b/my_test_suite.gd", "res://addons/gdUnit4/test/dir_a/dir_b/my_test_suite.gd", 0, "test_foo"))
	_inspector.on_test_case_discover_added(GdUnitTestCase.from("res://addons/gdUnit4/test/dir_a/dir_b/my_test_suite.gd", "res://addons/gdUnit4/test/dir_a/dir_b/my_test_suite.gd", 0, "test_bar"))
	_inspector.on_test_case_discover_added(GdUnitTestCase.from("res://addons/gdUnit4/test/dir_a/dir_x/my_test_suite2.gd", "res://addons/gdUnit4/test/dir_a/dir_x/my_test_suite2.gd", 0, "test_foo"))
	_inspector.on_test_case_discover_added(GdUnitTestCase.from("res://my_test_suite3.gd", "res://my_test_suite3.gd", 0, "test_foo"))

	# create expected tree
	var tree: Tree = auto_free(Tree.new())
	var expected_root := tree.create_item()
	expected_root.set_text(0, "tree_root")
	expected_root.set_meta("gdUnit_name", "tree_root")
	var dir_a := create_child(expected_root, "(0/3) dir_a")
	var dir_b := create_child(dir_a, "(0/2) dir_b")
	var my_test_suite := create_child(dir_b, "(0/2) my_test_suite")
	create_child(my_test_suite, "test_foo")
	create_child(my_test_suite, "test_bar")
	var dir_x := create_child(dir_a, "(0/1) dir_x")
	var my_test_suite2 := create_child(dir_x, "(0/1) my_test_suite2")
	create_child(my_test_suite2, "test_foo")
	var my_test_suite3 := create_child(expected_root,  "(0/1) my_test_suite3")
	create_child(my_test_suite3,  "test_foo")

	assert_tree_equals(_inspector._tree_root, expected_root)


func test_add_parameterized_test_case() -> void:
	_inspector.init_tree()
	_inspector.on_test_case_discover_added(GdUnitTestCase.from("res://addons/gdUnit4/test/dir_a/dir_b/my_test_suite.gd", "res://addons/gdUnit4/test/dir_a/dir_b/my_test_suite.gd", 0, "test_parameterized", 0, "1.2"))
	_inspector.on_test_case_discover_added(GdUnitTestCase.from("res://addons/gdUnit4/test/dir_a/dir_b/my_test_suite.gd", "res://addons/gdUnit4/test/dir_a/dir_b/my_test_suite.gd", 0, "test_parameterized", 1, "2.2"))

	# create expected tree
	var tree: Tree = auto_free(Tree.new())
	var expected_root := tree.create_item()
	expected_root.set_text(0, "tree_root")
	expected_root.set_meta("gdUnit_name", "tree_root")
	var dir_a := create_child(expected_root, "(0/2) dir_a")
	var dir_b := create_child(dir_a, "(0/2) dir_b")
	var my_test_suite := create_child(dir_b, "(0/2) my_test_suite")
	var test_parameterized := create_child(my_test_suite, "(0/2) test_parameterized")
	create_child(test_parameterized, "test_parameterized:0 (1.2)")
	create_child(test_parameterized, "test_parameterized:1 (2.2)")

	assert_tree_equals(_inspector._tree_root, expected_root)


func test_collect_test_cases() -> void:
	var script := load_non_cached("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")
	var tests_by_id := {}
	GdUnitTestDiscoverer.discover_tests(script, func(test_to_discover: GdUnitTestCase) -> void:
		discover_sink(test_to_discover)
		tests_by_id[test_to_discover.display_name] = test_to_discover
	)

	var test_case1: GdUnitTestCase = tests_by_id["test_case1"]

	# Test select a single suite
	# Collect all test cases from the suite node (parent of test_case1)
	var test := _inspector._find_tree_item_by_id(_inspector._tree_root, test_case1.guid)
	var collected_tests := _inspector.collect_test_cases(test.get_parent())
	# Do verify all tests are collected, ignoring the order could be different according to selected sort mode
	assert_array(collected_tests).contains_exactly_in_any_order(tests_by_id.values())

	# Test select a single test
	# Find tree node by test id
	test = _inspector._find_tree_item_by_id(_inspector._tree_root, test_case1.guid)
	# Collect all test cases by given tree node
	collected_tests = _inspector.collect_test_cases(test)
	assert_array(collected_tests).contains_exactly([test_case1])

	# Test select on paramaterized
	var paramaterized_test: GdUnitTestCase = tests_by_id["test_parameterized_static:0 (1, 1)"]
	test = _inspector._find_tree_item_by_id(_inspector._tree_root, paramaterized_test.guid)
	# Collect all paramaterized tests (by parent of paramaterized_test)
	collected_tests = _inspector.collect_test_cases(test.get_parent())
	# Do verify all tests are collected, ignoring the order could be different according to selected sort mode
	var expected_tests: Array = tests_by_id.values().filter(func(test_to_filter: GdUnitTestCase) -> bool:
		return test_to_filter.test_name == "test_parameterized_static"
	)
	assert_array(collected_tests)\
		.has_size(3)\
		.contains_exactly_in_any_order(expected_tests)


func test_collect_test_cases_GD_872(_do_skip := not GdUnit4CSharpApiLoader.is_api_loaded(), _skip_reason := "Do run only for Godot .Net version") -> void:
	var tests_by_id := {}
	var resource_path := "res://addons/gdUnit4/test/ui/parts/resources/gd_872/"
	for suite_path: String in ["ATests.cs", "AZTests.cs"]:
		var script := cs_load_non_cached(resource_path + suite_path)
		GdUnitTestDiscoverer.discover_tests(script, func(test_to_discover: GdUnitTestCase) -> void:
			discover_sink(test_to_discover)
			tests_by_id[test_to_discover.fully_qualified_name] = test_to_discover
		)
	# Validate if all tests discovered first
	assert_dict(tests_by_id)\
		.contains_keys([
			"Minimal.Tests.ATests.TestExample",
			"Minimal.Tests.ATests.TestExample2",
			"Minimal.Tests.AZTests.TestExample",
			"Minimal.Tests.AZTests.TestExample2"])\
		.has_size(4)
	# Validate suite `Minimal.Tests.ATests`
	var test_case1: GdUnitTestCase = tests_by_id["Minimal.Tests.ATests.TestExample"]
	var test_case2: GdUnitTestCase = tests_by_id["Minimal.Tests.ATests.TestExample2"]
	# Validate tree paths
	assert_str(buld_test_case_tree_path(test_case1)).is_equal("tree_root/Minimal/Tests/ATests/TestExample")
	assert_str(buld_test_case_tree_path(test_case2)).is_equal("tree_root/Minimal/Tests/ATests/TestExample2")
	# Valide suite find by resource name
	assert_object(_inspector._find_tree_item_by_test_suite(_inspector._tree_root, test_case1.suite_resource_path, "ATests")).is_not_null()

	# Validate suite `Minimal.Tests.AZTests`
	test_case1 = tests_by_id["Minimal.Tests.AZTests.TestExample"]
	test_case2 = tests_by_id["Minimal.Tests.AZTests.TestExample2"]
	# Validate tree paths
	assert_str(buld_test_case_tree_path(test_case1)).is_equal("tree_root/Minimal/Tests/AZTests/TestExample")
	assert_str(buld_test_case_tree_path(test_case2)).is_equal("tree_root/Minimal/Tests/AZTests/TestExample2")
	# Valide suite find by resource name
	assert_object(_inspector._find_tree_item_by_test_suite(_inspector._tree_root, test_case1.suite_resource_path, "AZTests")).is_not_null()

## test helpers to validate two trees
# ------------------------------------------------------------------------------------------------------------------------------------------

func buld_test_case_tree_path(test_case: GdUnitTestCase) -> String:
	var test := _inspector._find_tree_item_by_id(_inspector._tree_root, test_case.guid)
	return _build_tree_path(test)


func _build_tree_path(item: TreeItem, tree_path: String = "") -> String:
	if item == null:
		return tree_path
	var part: String = item.get_meta("gdUnit_name")
	if not tree_path.is_empty():
		part += "/" + tree_path
	return _build_tree_path(item.get_parent(), part)


func assert_tree_equals(tree_left :TreeItem, tree_right: TreeItem) -> bool:
	var left_childs := tree_left.get_children()
	var right_childs := tree_right.get_children()

	assert_that(left_childs.size())\
		.override_failure_message("Expecting same child count %d vs %d on item %s" % [left_childs.size(), right_childs.size(), tree_left.get_meta("gdUnit_name")])\
		.is_equal(right_childs.size())

	if is_failure():
		return false

	for index in left_childs.size():
		var l := left_childs[index]
		var r := right_childs[index]

		assert_that(get_item_name(l))\
		.override_failure_message("Expecting '%s' == '%s'" % [get_item_name(l), get_item_name(r)])\
		.is_equal(get_item_name(r))
		if is_failure():
			_print_tree_up(l)
			_print_tree_up(r)
			_print_execution_times(tree_left)
			_print_execution_times(tree_right)
			return false
		if not assert_tree_equals(l, r):
			return false
	return true


func _print_execution_times(item: TreeItem) -> void:
	for child in item.get_children():
		prints(get_item_name(child), get_item_execution_time(child))
	prints("_________________________________________________")


func _print_tree(tree_left :TreeItem, indent: String = "\t") -> void:
	var left := tree_left.get_children()
	for index in left.size():
		var l: TreeItem = left[index]
		var state_value: int = l.get_meta(_inspector.META_GDUNIT_STATE)
		var state :Variant = _inspector.STATE.keys()[state_value]
		prints(indent, l.get_meta("gdunit_original_index"), ":", get_item_name(l), state)
		_print_tree(l, indent+"\t")


func _print_tree_up(item :TreeItem, indent: String = "\t") -> void:
	prints(indent, get_item_name(item), "index:", item.get_meta("gdunit_original_index"))
	var parent := item.get_parent()
	if parent != null:
		_print_tree_up(parent, indent+"\t")


func get_item_name(item: TreeItem) -> String:
	return item.get_meta("gdUnit_name")


func get_item_execution_time(item: TreeItem) -> String:
	if item.has_meta("gdUnit_execution_time"):
		return "'" + str(item.get_meta("gdUnit_execution_time")) + "'"
	return "''"


func rebuild_tree_from_resource(resource: String) -> TreeItem:
	var json := FileAccess.open(resource, FileAccess.READ)
	var dict :Dictionary = JSON.parse_string(json.get_as_text())
	var tree :Tree = auto_free(Tree.new())
	var root := tree.create_item()
	var items: Dictionary = dict["TreeItem"]
	create_tree_item_form_dict(root, items)
	return root


func create_tree_item_form_dict(item: TreeItem, data: Dictionary) -> TreeItem:
	for key:String in data.keys():
		match key:
			"collapsed":
				@warning_ignore("unsafe_cast")
				item.collapsed = data[key] as bool

			"TreeItem":
				var next := item.create_child()
				@warning_ignore("unsafe_cast")
				return create_tree_item_form_dict(next, data[key] as Dictionary)

			"childrens":
				var childs_data :Array = data[key]
				for child_data:Dictionary in childs_data:
					create_tree_item_form_dict(item, child_data)

		if key.begins_with("metadata"):
			var meta_key := key.replace("metadata/", "")
			item.set_meta(meta_key, data[key])
	return item


func create_child( parent: TreeItem, item_name: String) -> TreeItem:
	var item := parent.create_child()
	item.set_text(0, item_name)
	var regex := RegEx.new()
	regex.compile("^\\(\\d+/\\d+\\)\\s*")
	var test_name := regex.sub(item_name, "", false)
	item.set_meta("gdUnit_name", test_name)
	item.collapsed = true
	return item


# we need to load the scripts freshly uncached because of script changes during test execution
func load_non_cached(resource_path: String) -> GDScript:
	return ResourceLoader.load(resource_path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE)


func cs_load_non_cached(resource_path: String) -> Script:
	return ResourceLoader.load(resource_path, "CSharpScript", ResourceLoader.CACHE_MODE_IGNORE)


class ItemNameExtractor extends GdUnitValueExtractor:

	func extract_value(value :Variant) -> Variant:
		var item: TreeItem = value
		return item.get_meta(GdUnitInspectorTreeMainPanel.META_GDUNIT_NAME)
