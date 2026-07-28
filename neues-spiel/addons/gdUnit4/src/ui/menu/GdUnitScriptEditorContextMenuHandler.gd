@tool
extends EditorContextMenuPlugin


var _context_menus: Array[GdUnitContextMenuItem] = []


func _init() -> void:
	var is_test_suite := func is_visible(script: Script, is_ts: bool) -> bool:
		return GdUnitTestSuiteScanner.is_test_suite(script) == is_ts
	# setup shortcuts
	_context_menus.append(GdUnitContextMenuItem.new(
		GdUnitCommandScriptEditorRunTests.ID,
		"Run Tests",
		is_test_suite.bind(true)
	))
	_context_menus.append(GdUnitContextMenuItem.new(
		GdUnitCommandScriptEditorDebugTests.ID,
		"Debug Tests",
		is_test_suite.bind(true)
	))
	_context_menus.append(GdUnitContextMenuItem.new(
		GdUnitCommandScriptEditorCreateTest.ID,
		"Create Test",
		is_test_suite.bind(false)
	))


func _popup_menu(_paths: PackedStringArray) -> void:
	var current_script := EditorInterface.get_script_editor().get_current_script()

	for menu_item in _context_menus:
		if menu_item.is_visible(current_script):
			if menu_item.shortcut():
				add_menu_shortcut(menu_item.shortcut(), menu_item.execute.unbind(1))
				add_context_menu_item_from_shortcut(menu_item.name, menu_item.shortcut())
			else:
				add_context_menu_item(menu_item.name, menu_item.execute.unbind(1))
