@tool
class_name GdUnitInspectorContextMenu
extends PopupMenu


const CONTEXT_MENU_RUN_ID = 0
const CONTEXT_MENU_DEBUG_ID = 1
const CONTEXT_MENU_RERUN_UNTIL_ID = 2
# id 3 is the seperator
const CONTEXT_MENU_COLLAPSE_ALL = 4
const CONTEXT_MENU_EXPAND_ALL = 5


var command_handler: GdUnitCommandHandler


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	command_handler = GdUnitCommandHandler.instance()
	_setup_item(CONTEXT_MENU_RUN_ID, "Run Tests", GdUnitCommandInspectorRunTests.ID)
	_setup_item(CONTEXT_MENU_DEBUG_ID, "Debug Tests", GdUnitCommandInspectorDebugTests.ID)
	_setup_item(CONTEXT_MENU_RERUN_UNTIL_ID, "Run Tests Until Fail", GdUnitCommandInspectorRerunTestsUntilFailure.ID)
	_setup_item(CONTEXT_MENU_EXPAND_ALL, "Expand All",  GdUnitCommandInspectorTreeExpand.ID)
	_setup_item(CONTEXT_MENU_COLLAPSE_ALL, "Collapse All", GdUnitCommandInspectorTreeCollapse.ID)


func _setup_item(item_id: int, item_name: String, command_id: String) -> void:
	set_item_text(item_id, item_name)
	set_item_icon(item_id, command_handler.command_icon(command_id))
	set_item_shortcut(item_id, command_handler.command_shortcut(command_id))


func disable_items() -> void:
	set_item_disabled(CONTEXT_MENU_RUN_ID, true)
	set_item_disabled(CONTEXT_MENU_DEBUG_ID, true)
	set_item_disabled(CONTEXT_MENU_RERUN_UNTIL_ID, true)


func enable_items() -> void:
	set_item_disabled(CONTEXT_MENU_RUN_ID, false)
	set_item_disabled(CONTEXT_MENU_DEBUG_ID, false)
	set_item_disabled(CONTEXT_MENU_RERUN_UNTIL_ID, false)


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int, source: Tree) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		position = source.get_screen_position() + mouse_position
		popup()


func _on_index_pressed(index: int) -> void:
	match index:
		CONTEXT_MENU_RUN_ID:
			command_handler.command_execute(GdUnitCommandInspectorRunTests.ID)
		CONTEXT_MENU_DEBUG_ID:
			command_handler.command_execute(GdUnitCommandInspectorDebugTests.ID)
		CONTEXT_MENU_RERUN_UNTIL_ID:
			command_handler.command_execute(GdUnitCommandInspectorRerunTestsUntilFailure.ID)
		CONTEXT_MENU_EXPAND_ALL:
			command_handler.command_execute(GdUnitCommandInspectorTreeExpand.ID)
		CONTEXT_MENU_COLLAPSE_ALL:
			command_handler.command_execute(GdUnitCommandInspectorTreeCollapse.ID)
