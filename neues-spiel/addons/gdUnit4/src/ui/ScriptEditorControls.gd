# A tool to provide extended script editor functionallity
class_name ScriptEditorControls
extends RefCounted

# https://github.com/godotengine/godot/blob/master/editor/plugins/script_editor_plugin.h
# the Editor menu popup items
enum {
	FILE_NEW,
	FILE_NEW_TEXTFILE,
	FILE_OPEN,
	FILE_REOPEN_CLOSED,
	FILE_OPEN_RECENT,
	FILE_SAVE,
	FILE_SAVE_AS,
	FILE_SAVE_ALL,
	FILE_THEME,
	FILE_RUN,
	FILE_CLOSE,
	CLOSE_DOCS,
	CLOSE_ALL,
	CLOSE_OTHER_TABS,
	TOGGLE_SCRIPTS_PANEL,
	SHOW_IN_FILE_SYSTEM,
	FILE_COPY_PATH,
	FILE_TOOL_RELOAD_SOFT,
	SEARCH_IN_FILES,
	REPLACE_IN_FILES,
	SEARCH_HELP,
	SEARCH_WEBSITE,
	HELP_SEARCH_FIND,
	HELP_SEARCH_FIND_NEXT,
	HELP_SEARCH_FIND_PREVIOUS,
	WINDOW_MOVE_UP,
	WINDOW_MOVE_DOWN,
	WINDOW_NEXT,
	WINDOW_PREV,
	WINDOW_SORT,
	WINDOW_SELECT_BASE = 100
}


# Saves the given script and closes if requested by <close=true>
# The script is saved when is opened in the editor.
# The script is closed when <close> is set to true.
static func save_an_open_script(script_path: String, close:=false) -> bool:
	#prints("save_an_open_script", script_path, close)
	if !Engine.is_editor_hint():
		return false
	var editor := EditorInterface.get_script_editor()
	var editor_popup := _menu_popup()
	# search for the script in all opened editor scrips
	for open_script in editor.get_open_scripts():
		if open_script.resource_path == script_path:
			# select the script in the editor
			EditorInterface.edit_script(open_script, 0);
			# save and close
			editor_popup.id_pressed.emit(FILE_SAVE)
			if close:
				editor_popup.id_pressed.emit(FILE_CLOSE)
			return true
	return false


# Saves all opened script
static func save_all_open_script() -> void:
	if Engine.is_editor_hint():
		_menu_popup().id_pressed.emit(FILE_SAVE_ALL)


static func close_open_editor_scripts() -> void:
	if Engine.is_editor_hint():
		_menu_popup().id_pressed.emit(CLOSE_ALL)


# Edits the given script.
# The script is openend in the current editor and selected in the file system dock.
# The line and column on which to open the script can also be specified.
# The script will be open with the user-configured editor for the script's language which may be an external editor.
static func edit_script(script_path: String, line_number := -1) -> void:
	var file_system := EditorInterface.get_resource_filesystem()
	file_system.update_file(script_path)
	var file_system_dock := EditorInterface.get_file_system_dock()
	file_system_dock.navigate_to_path(script_path)
	EditorInterface.select_file(script_path)
	var script: GDScript = load(script_path)
	EditorInterface.edit_script(script, line_number)


static func _menu_popup() -> PopupMenu:
	@warning_ignore("unsafe_method_access")
	return EditorInterface.get_script_editor().get_child(0).get_child(0).get_child(0).get_popup()


static func _print_menu(popup: PopupMenu) -> void:
	for itemIndex in popup.item_count:
		prints("get_item_id", popup.get_item_id(itemIndex))
		prints("get_item_accelerator", popup.get_item_accelerator(itemIndex))
		prints("get_item_shortcut", popup.get_item_shortcut(itemIndex))
		prints("get_item_text", popup.get_item_text(itemIndex))
		prints()
