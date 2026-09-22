class_name GdUnitCommandHandler
extends Object


const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

var _commnand_mappings: Dictionary[String, GdUnitBaseCommand]= {}
var test_session_command := GdUnitCommandTestSession.new()

static func instance() -> GdUnitCommandHandler:
	return GdUnitSingleton.instance("GdUnitCommandHandler", func() -> GdUnitCommandHandler: return GdUnitCommandHandler.new())


@warning_ignore("return_value_discarded")
func _init() -> void:
	GdUnitSignals.instance().gdunit_event.connect(_on_event)
	GdUnitSignals.instance().gdunit_client_disconnected.connect(_on_client_disconnected)
	GdUnitSignals.instance().gdunit_settings_changed.connect(_on_settings_changed)

	_register_command(test_session_command)
	_register_command(GdUnitCommandStopTestSession.new(test_session_command))
	_register_command(GdUnitCommandInspectorRunTests.new(test_session_command))
	_register_command(GdUnitCommandInspectorDebugTests.new(test_session_command))
	_register_command(GdUnitCommandInspectorRerunTestsUntilFailure.new(test_session_command))
	_register_command(GdUnitCommandInspectorTreeCollapse.new())
	_register_command(GdUnitCommandInspectorTreeExpand.new())
	_register_command(GdUnitCommandScriptEditorRunTests.new(test_session_command))
	_register_command(GdUnitCommandScriptEditorDebugTests.new(test_session_command))
	_register_command(GdUnitCommandScriptEditorCreateTest.new())
	_register_command(GdUnitCommandFileSystemRunTests.new(test_session_command))
	_register_command(GdUnitCommandFileSystemDebugTests.new(test_session_command))
	_register_command(GdUnitCommandRunTestsOverall.new(test_session_command))

	# schedule discover tests if enabled and running inside the editor
	if Engine.is_editor_hint() and GdUnitSettings.is_test_discover_enabled():
		var timer :SceneTreeTimer = (Engine.get_main_loop() as SceneTree).create_timer(5)
		@warning_ignore("return_value_discarded")
		timer.timeout.connect(cmd_discover_tests)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for command: GdUnitBaseCommand in _commnand_mappings.values():
			if Engine.is_editor_hint():
				EditorInterface.get_command_palette().remove_command("GdUnit4/"+command.id)
			command.free()
		_commnand_mappings.clear()


func _do_process() -> void:
	# Do stop test execution when the user has stoped the test runner manually by hit the Godot editor stop button
	if test_session_command._is_debug and test_session_command.is_running() and not EditorInterface.is_playing_scene():
		if GdUnitSettings.is_verbose_assert_warnings():
			print_debug("Test Runner scene was stopped manually, force stopping the current test run!")
		command_execute(GdUnitCommandStopTestSession.ID)


func command_icon(command_id: String) -> Texture2D:
	if not _commnand_mappings.has(command_id):
		push_error("GdUnitCommandHandler:command_icon(): No command id '%s' is registered." % command_id)
		print_stack()
		return
	return _commnand_mappings[command_id].icon


func command_shortcut(command_id: String) -> Shortcut:
	if not _commnand_mappings.has(command_id):
		push_error("GdUnitCommandHandler:command_shortcut(): No command id '%s' is registered." % command_id)
		print_stack()
		return
	return _commnand_mappings[command_id].shortcut


func command_execute(...parameters: Array) -> void:
	if parameters.is_empty():
		push_error("Invalid arguments used on CommandHandler:execute()! Expecting [<command_id, args...>]")
		print_stack()
		return

	var command_id: String = parameters.pop_front()
	if not _commnand_mappings.has(command_id):
		push_error("GdUnitCommandHandler:command_execute(): No command id '%s' is registered." % command_id)
		print_stack()
		return
	await _commnand_mappings[command_id].callv("execute", parameters)


func _register_command(command: GdUnitBaseCommand) -> void:
	# first verify the command is not already registerd
	if _commnand_mappings.has(command.id):
		push_error("GdUnitCommandHandler:_register_command(): Command with id '%s' is already registerd!" % command.id)
		return

	_commnand_mappings[command.id] = command
	if Engine.is_editor_hint():
		EditorInterface.get_base_control().add_child(command)
		EditorInterface.get_command_palette().add_command(command.id, "GdUnit4/"+command.id, command.execute, command.shortcut.get_as_text() if command.shortcut else "None")


func cmd_discover_tests() -> void:
	await GdUnitTestDiscoverer.run()


################################################################################
# signals handles
################################################################################
func _on_event(event: GdUnitEvent) -> void:
	if event.type() == GdUnitEvent.SESSION_CLOSE:
		command_execute(GdUnitCommandStopTestSession.ID)


func _on_settings_changed(property: GdUnitProperty) -> void:
	for command: GdUnitBaseCommand in _commnand_mappings.values():
		command.update_shortcut()

	if property.name() == GdUnitSettings.TEST_DISCOVER_ENABLED:
		var timer :SceneTreeTimer = (Engine.get_main_loop() as SceneTree).create_timer(3)
		@warning_ignore("return_value_discarded")
		timer.timeout.connect(cmd_discover_tests)


################################################################################
# Network stuff
################################################################################
func _on_client_disconnected(_client_id: int) -> void:
	command_execute(GdUnitCommandStopTestSession.ID)
