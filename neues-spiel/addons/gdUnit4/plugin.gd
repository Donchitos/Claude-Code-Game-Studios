@tool
extends EditorPlugin

var _gd_inspector: Control
var _gd_console: Control
var _filesystem_context_menu: EditorContextMenuPlugin
var _editor_context_menu: EditorContextMenuPlugin
var _editor_code_context_menu: EditorContextMenuPlugin


func _enter_tree() -> void:
	var inferred_declaration := GdUnitSettings.validate_is_inferred_declaration_enabled()
	if inferred_declaration.is_error():
		printerr(inferred_declaration.error_message())
		printerr("Loading GdUnit4 Plugin failed.")
		return

	if check_running_in_test_env():
		@warning_ignore("return_value_discarded")
		GdUnitCSIMessageWriter.new().prints_warning("It was recognized that GdUnit4 is running in a test environment, therefore the GdUnit4 plugin will not be executed!")
		return

	if Engine.get_version_info().hex < 0x40500:
		prints("This GdUnit4 plugin version '%s' requires Godot version '4.5' or higher to run." % GdUnit4Version.current())
		return
	GdUnitSettings.setup()
	# Install the GdUnit Inspector
	_gd_inspector = (load("res://addons/gdUnit4/src/ui/GdUnitInspector.tscn") as PackedScene).instantiate()
	_add_context_menus()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, _gd_inspector)
	# Install the GdUnit Console
	_gd_console = (load("res://addons/gdUnit4/src/ui/GdUnitConsole.tscn") as PackedScene).instantiate()
	var control: Control = add_control_to_bottom_panel(_gd_console, "gdUnitConsole")
	@warning_ignore("unsafe_method_access")
	await _gd_console.setup_update_notification(control)
	if GdUnit4CSharpApiLoader.is_api_loaded():
		prints("GdUnit4Net version '%s' loaded." % GdUnit4CSharpApiLoader.version())
	else:
		prints("No GdUnit4Net found.")
	# Connect to be notified for script changes to be able to discover new tests
	GdUnitTestDiscoverGuard.instance()
	@warning_ignore("return_value_discarded")
	resource_saved.connect(_on_resource_saved)
	prints("Loading GdUnit4 Plugin success")


func _exit_tree() -> void:
	if check_running_in_test_env():
		return
	if is_instance_valid(_gd_inspector):
		remove_control_from_docks(_gd_inspector)
		_gd_inspector.free()
	_remove_context_menus()
	if is_instance_valid(_gd_console):
		remove_control_from_bottom_panel(_gd_console)
		_gd_console.free()
	var gdUnitTools: GDScript = load("res://addons/gdUnit4/src/core/GdUnitTools.gd")
	@warning_ignore("unsafe_method_access")
	gdUnitTools.dispose_all(true)
	prints("Unload GdUnit4 Plugin success")


func check_running_in_test_env() -> bool:
	var args: PackedStringArray = OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	return DisplayServer.get_name() == "headless" or args.has("--selftest") or args.has("--add") or args.has("-a") or args.has("--quit-after") or args.has("--import")


func _add_context_menus() -> void:
	_filesystem_context_menu = preload("res://addons/gdUnit4/src/ui/menu/GdUnitEditorFileSystemContextMenuHandler.gd").new()
	_editor_context_menu = preload("res://addons/gdUnit4/src/ui/menu/GdUnitScriptEditorContextMenuHandler.gd").new()
	_editor_code_context_menu = preload("res://addons/gdUnit4/src/ui/menu/GdUnitScriptEditorContextMenuHandler.gd").new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _filesystem_context_menu)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, _editor_context_menu)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, _editor_code_context_menu)


func _remove_context_menus() -> void:
	if is_instance_valid(_filesystem_context_menu):
		remove_context_menu_plugin(_filesystem_context_menu)
	if is_instance_valid(_editor_context_menu):
		remove_context_menu_plugin(_editor_context_menu)
	if is_instance_valid(_editor_code_context_menu):
		remove_context_menu_plugin(_editor_code_context_menu)


func _on_resource_saved(resource: Resource) -> void:
	if resource is Script:
		await GdUnitTestDiscoverGuard.instance().discover(resource as Script)
