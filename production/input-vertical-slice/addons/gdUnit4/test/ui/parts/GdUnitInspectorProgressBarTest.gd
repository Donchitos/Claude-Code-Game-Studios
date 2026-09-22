extends GdUnitTestSuite


const GdUnitInspectorProgressBar := preload("res://addons/gdUnit4/src/ui/parts/GdUnitInspectorProgressBar.gd")


var _progress: GdUnitInspectorProgressBar
var _progress_counter: Label
var _style: StyleBoxFlat


func before_test() -> void:
	@warning_ignore("unsafe_method_access")
	var control: Control = load('res://addons/gdUnit4/src/ui/parts/GdUnitInspectorProgressBar.tscn').instantiate()
	add_child(control)
	_progress = control.find_child("ProgressBar", true, false)

	_progress_counter = _progress.progress_counter
	_style = _progress.style


func test_progress_init() -> void:
	assert_that(_progress.value).is_equal(0.000000)
	assert_that(_progress.max_value).is_equal(0.000000)
	assert_that(_progress_counter.text).is_equal("0:0")


func test_progress_on_test_counter_changed(index: int, total_count: int, state: GdUnitInspectorTreeConstants.STATE, expected_color: Color, _test_parameters := [
	[0, 0, GdUnitInspectorTreeConstants.STATE.INITIAL, Color.TRANSPARENT],
	[1, 2, GdUnitInspectorTreeConstants.STATE.SUCCESS, Color.DARK_GREEN],
	[2, 2, GdUnitInspectorTreeConstants.STATE.WARNING, Color.DARK_GREEN],
	[3, 5, GdUnitInspectorTreeConstants.STATE.RUNNING, Color.DARK_GREEN],
	[4, 5, GdUnitInspectorTreeConstants.STATE.FAILED, Color.DARK_RED],
	[5, 5, GdUnitInspectorTreeConstants.STATE.ERROR, Color.DARK_RED],
]) -> void:

	_progress._on_test_counter_changed(index, total_count, state)
	assert_float(_progress.value).is_equal(index as float)
	assert_float(_progress.max_value).is_equal(total_count as float)
	assert_str(_progress_counter.text).is_equal("%d:%d" % [index, total_count])
	assert_that(_style.bg_color).is_equal(expected_color)
