@tool
extends EditorContextMenuPlugin

var _context_menus: Array[GdUnitContextMenuItem] = []


func _init() -> void:
	var is_test_suite := func is_visible(script: Script, is_ts: bool) -> bool:
		if script == null:
			return false
		return GdUnitTestSuiteScanner.is_test_suite(script) == is_ts
	# setup shortcuts
	_context_menus.append(GdUnitContextMenuItem.new(
		GdUnitCommandFileSystemRunTests.ID,
		"Run Testsuites",
		is_test_suite.bind(true)
	))
	_context_menus.append(GdUnitContextMenuItem.new(
		GdUnitCommandFileSystemDebugTests.ID,
		"Debug Testsuites",
		is_test_suite.bind(true)
	))


func _popup_menu(paths: PackedStringArray) -> void:
	# Filter for directories and test suite files
	var valid_paths := Array(paths)\
		.filter(func(path: String) -> bool:
			if DirAccess.dir_exists_absolute(path):
				return true
			if path.get_extension() in ["gd", "cs"]:
				var script := GdUnitTestSuiteScanner.load_with_disabled_warnings(path)
				return GdUnitTestSuiteScanner.is_test_suite(script)
			return false)

	# If no valid paths selected don't extend the context menu
	if valid_paths.is_empty():
		return

	for menu_item in _context_menus:
		if menu_item.shortcut():
			add_menu_shortcut(menu_item.shortcut(), menu_item.execute.bindv(valid_paths).unbind(1))
			add_context_menu_item_from_shortcut(menu_item.name, menu_item.shortcut(), menu_item.icon)
		else:
			add_context_menu_item(menu_item.name, menu_item.execute.bindv(valid_paths).unbind(1), menu_item.icon)
