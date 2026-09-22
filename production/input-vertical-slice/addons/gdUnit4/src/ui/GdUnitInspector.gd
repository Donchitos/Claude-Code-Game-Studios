@tool
class_name GdUnitInspecor
extends Control


var _command_handler := GdUnitCommandHandler.instance()
var _wait_time := 0.0


func _ready() -> void:
	@warning_ignore("return_value_discarded")
	GdUnitSignals.instance().gdunit_event.connect(func(event: GdUnitEvent) -> void:
		if event.type() != GdUnitEvent.SESSION_START:
			return

		var control: Control = get_parent_control()
		# if the tab is floating we dont need to set as current
		if control is TabContainer:
			var tab_container :TabContainer = control
			for tab_index in tab_container.get_tab_count():
				if tab_container.get_tab_title(tab_index) == "GdUnit":
					tab_container.set_current_tab(tab_index)
	)

	# Register for editor theme updates
	add_child(GdUnitEditorColorTheme.new(), true, Node.INTERNAL_MODE_BACK)


func _process(delta: float) -> void:
	_wait_time += delta
	if _wait_time > 2.0:
		_wait_time = 0
		_command_handler._do_process()
