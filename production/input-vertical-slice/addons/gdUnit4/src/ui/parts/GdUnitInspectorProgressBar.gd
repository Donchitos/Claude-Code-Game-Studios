@tool
extends ProgressBar


@onready var progress_counter: Label = %progess_counter
@onready var style: StyleBoxFlat = get("theme_override_styles/fill")

var _state: GdUnitInspectorTreeConstants.STATE


func _ready() -> void:
	style.bg_color = Color.TRANSPARENT
	value = 0
	max_value = 0
	update_text()
	# register for progress changes
	if Engine.is_editor_hint():
		@warning_ignore("unsafe_property_access", "unsafe_method_access")
		if get_parent().get_parent().get_parent().find_child("MainPanel", true, false).test_counters_changed.connect(_on_test_counter_changed) != OK:
			push_error("ProgressBar: Can't connect to MainPanel")


func update_text() -> void:
	progress_counter.text = "%d:%d" % [value, max_value]


func _on_test_counter_changed(index: int, total: int, state: GdUnitInspectorTreeConstants.STATE) -> void:
	value = index
	max_value = total
	update_text()

	# inital state
	if index == 0:
		_state = GdUnitInspectorTreeConstants.STATE.INITIAL
		style.bg_color = Color.TRANSPARENT

	# do only update the state is higher prio than current state
	if state <= _state:
		return
	_state = state

	if is_failed(state):
		style.bg_color = Color.DARK_RED
	else:
		style.bg_color = Color.DARK_GREEN


func is_failed(state: GdUnitInspectorTreeConstants.STATE) -> bool:
	return state in [
		GdUnitInspectorTreeConstants.STATE.FAILED,
		GdUnitInspectorTreeConstants.STATE.ERROR,
		GdUnitInspectorTreeConstants.STATE.ABORDED]


func is_flaky(state: GdUnitInspectorTreeConstants.STATE) -> bool:
	return state == GdUnitInspectorTreeConstants.STATE.FLAKY
