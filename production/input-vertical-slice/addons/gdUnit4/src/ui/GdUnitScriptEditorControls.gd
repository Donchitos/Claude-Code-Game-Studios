# A tool to provide extended script editor functionallity
class_name GdUnitScriptEditorControls
extends RefCounted


static var _command_ids_initalizied := false
static var FILE_CLOSE := -1
static var FILE_CLOSE_ALL := -1
static var FILE_SAVE := -1
static var FILE_SAVE_ALL := -1


## We scan the file popup menu to find the file command ids to trigger it on save, close, etc.
static func init_file_command_ids() -> void:
	if _command_ids_initalizied:
		return

	var popup := get_file_menu_popup()
	for itemIndex in popup.item_count:
		var command := popup.get_item_text(itemIndex)
		var command_id := popup.get_item_id(itemIndex)
		match command:
			"Close":
				FILE_CLOSE = command_id
			"Close All":
				FILE_CLOSE_ALL = command_id
			"Save":
				FILE_SAVE = command_id
			"Save All":
				FILE_SAVE_ALL = command_id

	if FILE_CLOSE == -1:
		push_error("Can't determine ScriptEditor 'Close' command.")
	if FILE_CLOSE_ALL == -1:
		push_error("Can't determine ScriptEditor 'Close All' command.")
	if FILE_SAVE == -1:
		push_error("Can't determine ScriptEditor 'Save' command.")
	if FILE_SAVE_ALL == -1:
		push_error("Can't determine ScriptEditor 'Save All' command.")
	_command_ids_initalizied = true


# Saves the given script and closes if requested by <close=true>
# The script is saved when is opened in the editor.
# The script is closed when <close> is set to true.
static func save_and_close_script(script_path: String, close := false) -> bool:
	if !Engine.is_editor_hint():
		return false

	init_file_command_ids()
	var editor := EditorInterface.get_script_editor()
	# search for the script in all opened editor scrips
	for open_script in editor.get_open_scripts():
		if open_script.resource_path == script_path:
			# select the script in the editor
			EditorInterface.edit_script(open_script, 0);
			run_file_command(FILE_SAVE)
			if close:
				run_file_command(FILE_CLOSE)
			return true
	return false


# Saves all opened script
static func save_all_open_script() -> void:
	init_file_command_ids()
	run_file_command(FILE_SAVE_ALL)


static func close_open_editor_scripts() -> void:
	init_file_command_ids()
	run_file_command(FILE_CLOSE_ALL)


# Edits the given script.
# The script is openend in the current editor and selected in the file system dock.
# The line and column on which to open the script can also be specified.
# The script will be open with the user-configured editor for the script's language which may be an external editor.
static func edit_script(script_path: String, line_number := -1) -> void:
	if Engine.is_editor_hint():
		# scan() is required — update_file() alone does not refresh the dock for newly created files
		var file_system := EditorInterface.get_resource_filesystem()
		file_system.update_file(script_path)
		file_system.scan()
		var file_system_dock := EditorInterface.get_file_system_dock()
		file_system_dock.navigate_to_path(script_path)
		EditorInterface.select_file(script_path)
		var script: GDScript = load(script_path)
		EditorInterface.edit_script(script, line_number)


static func get_file_menu_popup() -> PopupMenu:
	@warning_ignore("unsafe_method_access")
	return EditorInterface.get_script_editor().get_child(0).get_child(0).get_child(0).get_popup()


static func run_file_command(command_id: int) -> void:
	if Engine.is_editor_hint():
		get_file_menu_popup().id_pressed.emit(command_id)


static func _print_menu(popup: PopupMenu) -> void:
	for itemIndex in popup.item_count:
		prints("get_item_id", popup.get_item_id(itemIndex))
		prints("get_item_accelerator", popup.get_item_accelerator(itemIndex))
		prints("get_item_shortcut", popup.get_item_shortcut(itemIndex))
		prints("get_item_text", popup.get_item_text(itemIndex))
		prints()
