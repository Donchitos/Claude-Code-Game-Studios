@tool
extends VSplitContainer

## Will be emitted when the test index counter is changed
signal test_counters_changed(index: int, total: int, state: GdUnitInspectorTreeConstants.STATE)
signal tree_item_selected(item: TreeItem)


@onready var _tree: Tree = $Panel/Tree
@onready var _report_list: Node = $report/ScrollContainer/list
@onready var _report_template: RichTextLabel = $report/report_template
@onready var _context_menu: GdUnitInspectorContextMenu = $contextMenu
@onready var _discover_hint: Control = %discover_hint
@onready var _spinner: Button = %spinner

# loading tree icons
@onready var ICON_SPINNER := GdUnitUiTools.get_spinner()
@onready var ICON_FOLDER := GdUnitUiTools.get_icon("Folder")
# gdscript icons
@onready var ICON_GDSCRIPT_TEST_DEFAULT := GdUnitUiTools.get_icon("GDScript", Color.LIGHT_GRAY)
@onready var ICON_GDSCRIPT_TEST_SUCCESS := GdUnitUiTools.get_GDScript_icon("StatusSuccess", Color.DARK_GREEN)
@onready var ICON_GDSCRIPT_TEST_FLAKY := GdUnitUiTools.get_GDScript_icon("CheckBox", Color.GREEN_YELLOW)
@onready var ICON_GDSCRIPT_TEST_FAILED := GdUnitUiTools.get_GDScript_icon("StatusError", Color.SKY_BLUE)
@onready var ICON_GDSCRIPT_TEST_ERROR := GdUnitUiTools.get_GDScript_icon("StatusError", Color.DARK_RED)
@onready var ICON_GDSCRIPT_TEST_SUCCESS_ORPHAN := GdUnitUiTools.get_GDScript_icon("Unlinked", Color.DARK_GREEN)
@onready var ICON_GDSCRIPT_TEST_FAILED_ORPHAN := GdUnitUiTools.get_GDScript_icon("Unlinked", Color.SKY_BLUE)
@onready var ICON_GDSCRIPT_TEST_ERRORS_ORPHAN := GdUnitUiTools.get_GDScript_icon("Unlinked", Color.DARK_RED)
# csharp script icons
@onready var ICON_CSSCRIPT_TEST_DEFAULT := GdUnitUiTools.get_icon("CSharpScript", Color.LIGHT_GRAY)
@onready var ICON_CSSCRIPT_TEST_SUCCESS := GdUnitUiTools.get_CSharpScript_icon("StatusSuccess", Color.DARK_GREEN)
@onready var ICON_CSSCRIPT_TEST_FAILED := GdUnitUiTools.get_CSharpScript_icon("StatusError", Color.SKY_BLUE)
@onready var ICON_CSSCRIPT_TEST_ERROR := GdUnitUiTools.get_CSharpScript_icon("StatusError", Color.DARK_RED)
@onready var ICON_CSSCRIPT_TEST_SUCCESS_ORPHAN := GdUnitUiTools.get_CSharpScript_icon("Unlinked", Color.DARK_GREEN)
@onready var ICON_CSSCRIPT_TEST_FAILED_ORPHAN := GdUnitUiTools.get_CSharpScript_icon("Unlinked", Color.SKY_BLUE)
@onready var ICON_CSSCRIPT_TEST_ERRORS_ORPHAN := GdUnitUiTools.get_CSharpScript_icon("Unlinked", Color.DARK_RED)


enum GdUnitType {
	FOLDER,
	TEST_SUITE,
	TEST_CASE,
	TEST_GROUP
}

const META_GDUNIT_PROGRESS_COUNT_MAX := "gdUnit_progress_count_max"
const META_GDUNIT_PROGRESS_INDEX := "gdUnit_progress_index"
const META_TEST_CASE := "gdunit_test_case"
const META_GDUNIT_NAME := "gdUnit_name"
const META_GDUNIT_STATE := "gdUnit_state"
const META_GDUNIT_TYPE := "gdUnit_type"
const META_GDUNIT_SUCCESS_TESTS := "gdUnit_suite_success_tests"
const META_GDUNIT_REPORT := "gdUnit_report"
const META_GDUNIT_ORPHAN := "gdUnit_orphan"
const META_GDUNIT_EXECUTION_TIME := "gdUnit_execution_time"
const META_GDUNIT_ORIGINAL_INDEX = "gdunit_original_index"
const STATE = GdUnitInspectorTreeConstants.STATE


var _tree_root: TreeItem
var _current_selected_item: TreeItem = null
var _current_tree_view_mode := GdUnitSettings.get_inspector_tree_view_mode()
var _run_test_recovery := true


## Used for debugging purposes only
func print_tree_item_ids(parent: TreeItem) -> TreeItem:
	for child in parent.get_children():
		if child.has_meta(META_TEST_CASE):
			var test_case: GdUnitTestCase = child.get_meta(META_TEST_CASE)
			prints(test_case.guid, test_case.test_name)

		if child.get_child_count() > 0:
			print_tree_item_ids(child)

	return null


func _find_tree_item(parent: TreeItem, item_name: String) -> TreeItem:
	for child in parent.get_children():
		if child.get_meta(META_GDUNIT_NAME) == item_name:
			return child
	return null


func _find_tree_item_by_id(parent: TreeItem, id: GdUnitGUID) -> TreeItem:
	for child in parent.get_children():
		if is_test_id(child, id):
			return child
		if child.get_child_count() > 0:
			var item := _find_tree_item_by_id(child, id)
			if item != null:
				return item

	return null


func _find_tree_item_by_test_suite(parent: TreeItem, suite_path: String, suite_name: String) -> TreeItem:
	for child in parent.get_children():
		if child.get_meta(META_GDUNIT_TYPE) == GdUnitType.TEST_SUITE:
			var test_case: GdUnitTestCase = child.get_meta(META_TEST_CASE)
			if test_case.suite_resource_path == suite_path and test_case.suite_name == suite_name:
				return child
		if child.get_child_count() > 0:
			var item := _find_tree_item_by_test_suite(child, suite_path, suite_name)
			if item != null:
				return item
	return null


func _find_first_item_by_state(parent: TreeItem, item_state: STATE, reverse := false) -> TreeItem:
	var itmes := parent.get_children()
	if reverse:
		itmes.reverse()
	for item in itmes:
		if is_test_case(item) and (is_item_state(item, item_state)):
			return item
		var failure_item := _find_first_item_by_state(item, item_state, reverse)
		if failure_item != null:
			return failure_item
	return null


func _find_last_item_by_state(parent: TreeItem, item_state: STATE) -> TreeItem:
	return _find_first_item_by_state(parent, item_state, true)


func _find_item_by_state(current: TreeItem, item_state: STATE, prev := false) -> TreeItem:
	var next := current.get_prev_in_tree() if prev else current.get_next_in_tree()
	if next == null or next == _tree_root:
		return null
	if is_test_case(next) and is_item_state(next, item_state):
		return next
	return _find_item_by_state(next, item_state, prev)


func is_item_state(item: TreeItem, item_state: STATE) -> bool:
	return item.has_meta(META_GDUNIT_STATE) and item.get_meta(META_GDUNIT_STATE) == item_state


func is_state_running(item: TreeItem) -> bool:
	return is_item_state(item, STATE.RUNNING)


func is_state_success(item: TreeItem) -> bool:
	return is_item_state(item, STATE.SUCCESS)


func is_state_warning(item: TreeItem) -> bool:
	return is_item_state(item, STATE.WARNING)


func is_state_failed(item: TreeItem) -> bool:
	return is_item_state(item, STATE.FAILED)


func is_state_error(item: TreeItem) -> bool:
	return is_item_state(item, STATE.ERROR) or is_item_state(item, STATE.ABORDED)


func is_item_state_orphan(item: TreeItem) -> bool:
	return item.has_meta(META_GDUNIT_ORPHAN)


func is_test_suite(item: TreeItem) -> bool:
	return item.has_meta(META_GDUNIT_TYPE) and item.get_meta(META_GDUNIT_TYPE) == GdUnitType.TEST_SUITE


func is_test_case(item: TreeItem) -> bool:
	return item.has_meta(META_GDUNIT_TYPE) and item.get_meta(META_GDUNIT_TYPE) == GdUnitType.TEST_CASE


func is_folder(item: TreeItem) -> bool:
	return item.has_meta(META_GDUNIT_TYPE) and item.get_meta(META_GDUNIT_TYPE) == GdUnitType.FOLDER


func is_test_id(item: TreeItem, id: GdUnitGUID) -> bool:
	if not item.has_meta(META_TEST_CASE):
		return false

	var test_case: GdUnitTestCase = item.get_meta(META_TEST_CASE)
	return test_case.guid.equals(id)


func disable_test_recovery() -> void:
	_run_test_recovery = false


@warning_ignore("return_value_discarded")
func _ready() -> void:
	if Engine.is_editor_hint():
		var base_control := EditorInterface.get_base_control()
		base_control.set_meta("GdUnit4Inspector", self)

	_spinner.icon = GdUnitUiTools.get_spinner()
	init_tree()
	GdUnitSignals.instance().gdunit_settings_changed.connect(_on_settings_changed)
	GdUnitSignals.instance().gdunit_event.connect(_on_gdunit_event)
	GdUnitSignals.instance().gdunit_test_discover_added.connect(on_test_case_discover_added)
	GdUnitSignals.instance().gdunit_test_discover_deleted.connect(on_test_case_discover_deleted)
	GdUnitSignals.instance().gdunit_test_discover_modified.connect(on_test_case_discover_modified)
	if _run_test_recovery:
		GdUnitTestDiscoverer.restore_last_session()


# we need current to manually redraw bacause of the animation bug
# https://github.com/godotengine/godot/issues/69330
func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func init_tree() -> void:
	cleanup_tree()
	_tree.deselect_all()
	_tree.set_hide_root(true)
	_tree.ensure_cursor_is_visible()
	_tree.set_allow_reselect(true)
	_tree.set_allow_rmb_select(true)
	_tree.set_columns(2)
	_tree.set_column_clip_content(0, true)
	_tree.set_column_expand_ratio(0, 1)
	_tree.set_column_custom_minimum_width(0, 240)
	_tree.set_column_expand_ratio(1, 0)
	_tree.set_column_custom_minimum_width(1, 100)
	_tree_root = _tree.create_item()
	_tree_root.set_text(0, "tree_root")
	_tree_root.set_meta(META_GDUNIT_NAME, "tree_root")
	_tree_root.set_meta(META_GDUNIT_PROGRESS_COUNT_MAX, 0)
	_tree_root.set_meta(META_GDUNIT_PROGRESS_INDEX, 0)
	_tree_root.set_meta(META_GDUNIT_STATE, STATE.INITIAL)
	_tree_root.set_meta(META_GDUNIT_SUCCESS_TESTS, 0)
	# fix tree icon scaling
	var scale_factor := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	_tree.set("theme_override_constants/icon_max_width", 16 * scale_factor)


func cleanup_tree() -> void:
	clear_reports()
	if not _tree_root:
		return
	_free_recursive()
	_tree.clear()
	_current_selected_item = null


func _free_recursive(items:=_tree_root.get_children()) -> void:
	for item in items:
		_free_recursive(item.get_children())
		item.call_deferred("free")


func sort_tree_items(parent: TreeItem) -> void:
	_sort_tree_items(parent, GdUnitSettings.get_inspector_tree_sort_mode())
	_tree.queue_redraw()


static func _sort_tree_items(parent: TreeItem, sort_mode: GdUnitInspectorTreeConstants.SORT_MODE) -> void:
	parent.visible = false
	var items := parent.get_children()
	# first remove all childs before sorting
	for item in items:
		parent.remove_child(item)

	# do sort by selected sort mode
	match sort_mode:
		GdUnitInspectorTreeConstants.SORT_MODE.UNSORTED:
			items.sort_custom(sort_items_by_original_index)

		GdUnitInspectorTreeConstants.SORT_MODE.NAME_ASCENDING:
			items.sort_custom(sort_items_by_name.bind(true))

		GdUnitInspectorTreeConstants.SORT_MODE.NAME_DESCENDING:
			items.sort_custom(sort_items_by_name.bind(false))

		GdUnitInspectorTreeConstants.SORT_MODE.EXECUTION_TIME:
			items.sort_custom(sort_items_by_execution_time)

	# readding sorted childs
	for item in items:
		parent.add_child(item)
		if item.get_child_count() > 0:
			_sort_tree_items(item, sort_mode)
	parent.visible = true


static func sort_items_by_name(a: TreeItem, b: TreeItem, ascending: bool) -> bool:
	var type_a: GdUnitType = a.get_meta(META_GDUNIT_TYPE)
	var type_b: GdUnitType = b.get_meta(META_GDUNIT_TYPE)

	# Sort folders to the top
	if type_a == GdUnitType.FOLDER and type_b != GdUnitType.FOLDER:
		return true
	if type_b == GdUnitType.FOLDER and type_a != GdUnitType.FOLDER:
		return false

	# sort by name
	var name_a: String = a.get_meta(META_GDUNIT_NAME)
	var name_b: String = b.get_meta(META_GDUNIT_NAME)
	var comparison := name_a.naturalnocasecmp_to(name_b)

	return comparison < 0 if ascending else comparison > 0


static func sort_items_by_execution_time(a: TreeItem, b: TreeItem) -> bool:
	var type_a: GdUnitType = a.get_meta(META_GDUNIT_TYPE)
	var type_b: GdUnitType = b.get_meta(META_GDUNIT_TYPE)

	# Sort folders to the top
	if type_a == GdUnitType.FOLDER and type_b != GdUnitType.FOLDER:
		return true
	if type_b == GdUnitType.FOLDER and type_a != GdUnitType.FOLDER:
		return false

	var execution_time_a :int = a.get_meta(META_GDUNIT_EXECUTION_TIME)
	var execution_time_b :int = b.get_meta(META_GDUNIT_EXECUTION_TIME)
	# if has same execution time sort by name
	if execution_time_a == execution_time_b:
		var name_a :String = a.get_meta(META_GDUNIT_NAME)
		var name_b :String = b.get_meta(META_GDUNIT_NAME)
		return name_a.naturalnocasecmp_to(name_b) > 0
	return execution_time_a > execution_time_b


static func sort_items_by_original_index(a: TreeItem, b: TreeItem) -> bool:
	var type_a: GdUnitType = a.get_meta(META_GDUNIT_TYPE)
	var type_b: GdUnitType = b.get_meta(META_GDUNIT_TYPE)

	# Sort folders to the top
	if type_a == GdUnitType.FOLDER and type_b != GdUnitType.FOLDER:
		return true
	if type_b == GdUnitType.FOLDER and type_a != GdUnitType.FOLDER:
		return false

	var index_a :int = a.get_meta(META_GDUNIT_ORIGINAL_INDEX)
	var index_b :int = b.get_meta(META_GDUNIT_ORIGINAL_INDEX)

	# Sorting by index
	return index_a < index_b


func restructure_tree(parent: TreeItem, tree_mode: GdUnitInspectorTreeConstants.TREE_VIEW_MODE) -> void:
	_current_tree_view_mode = tree_mode

	match tree_mode:
		GdUnitInspectorTreeConstants.TREE_VIEW_MODE.FLAT:
			restructure_tree_to_flat(parent)
		GdUnitInspectorTreeConstants.TREE_VIEW_MODE.TREE:
			restructure_tree_to_tree(parent)
	recalculate_counters(_tree_root)
	# finally apply actual sort mode
	sort_tree_items(_tree_root)


# Restructure into flat mode
func restructure_tree_to_flat(parent: TreeItem) -> void:
	var folders := flatmap_folders(parent)
	# Store current folder paths and their test suites
	for folder_path: String in folders:
		var test_suites: Array[TreeItem] = folders[folder_path]
		if test_suites.is_empty():
			continue

		# Create flat folder and move test suites into it
		var folder := _tree.create_item(parent)
		folder.set_meta(META_GDUNIT_NAME, folder_path)
		update_item_total_counter(folder)
		set_state_initial(folder, GdUnitType.FOLDER)

		# Move test suites under the flat folder
		for test_suite in test_suites:
			var old_parent := test_suite.get_parent()
			old_parent.remove_child(test_suite)
			folder.add_child(test_suite)

	# Cleanup old folder structure
	cleanup_empty_folders(parent)


# Restructure into hierarchical tree mode
func restructure_tree_to_tree(parent: TreeItem) -> void:
	var items_to_process := parent.get_children().duplicate()

	for item: TreeItem in items_to_process:
		if is_folder(item):
			var folder_path: String = item.get_meta(META_GDUNIT_NAME)
			var parts := folder_path.split("/")

			if parts.size() > 1:
				var current_parent := parent
				# Build folder hierarchy
				for part in parts:
					var next := _find_tree_item(current_parent, part)
					if not next:
						next = _tree.create_item(current_parent)
						next.set_meta(META_GDUNIT_NAME, part)
						set_state_initial(next, GdUnitType.FOLDER)
					current_parent = next

				# Move test suites to deepest folder
				var test_suites := item.get_children()
				for test_suite in test_suites:
					item.remove_child(test_suite)
					current_parent.add_child(test_suite)

				# Remove the flat folder
				item.get_parent().remove_child(item)
				item.free()


func flatmap_folders(parent: TreeItem) -> Dictionary:
	var folder_map := {}

	for item in parent.get_children():
		if is_folder(item):
			var current_path: String = item.get_meta(META_GDUNIT_NAME)
			# Get parent folder paths
			var parent_path := get_parent_folder_path(item)
			if parent_path:
				current_path = parent_path + "/" + current_path

			# Collect direct children of this folder
			var children: Array[TreeItem] = []
			for child in item.get_children():
				if is_test_suite(child):
					children.append(child)

			# Add children to existing path or create new entry
			if not children.is_empty():
				if folder_map.has(current_path):
					@warning_ignore("unsafe_method_access")
					folder_map[current_path].append_array(children)
				else:
					folder_map[current_path] = children

			# Recursively process subfolders
			var sub_folders := flatmap_folders(item)
			for path: String in sub_folders.keys():
				if folder_map.has(path):
					@warning_ignore("unsafe_method_access")
					folder_map[path].append_array(sub_folders[path])
				else:
					folder_map[path] = sub_folders[path]
	return folder_map


func get_parent_folder_path(item: TreeItem) -> String:
	var path := ""
	var parent := item.get_parent()

	while parent != _tree_root:
		if is_folder(parent):
			path = parent.get_meta(META_GDUNIT_NAME) + ("/" + path if path else "")
		parent = parent.get_parent()

	return path


func cleanup_empty_folders(parent: TreeItem) -> void:
	var folders: Array[TreeItem] = []
	# First collect all folders to avoid modification during iteration
	for item in parent.get_children():
		if is_folder(item):
			folders.append(item)

	# Process collected folders
	for folder in folders:
		cleanup_empty_folders(folder)
		# Remove folder if it has no children after cleanup
		if folder.get_child_count() == 0:
			parent.remove_child(folder)
			folder.free()


func reset_tree_state(parent: TreeItem) -> void:
	if parent == _tree_root:
		_tree_root.set_meta(META_GDUNIT_PROGRESS_INDEX, 0)
		_tree_root.set_meta(META_GDUNIT_STATE, STATE.INITIAL)
		test_counters_changed.emit(0, 0, STATE.INITIAL)

	for item in parent.get_children():
		set_state_initial(item, get_item_type(item))
		reset_tree_state(item)


func select_item(item: TreeItem) -> TreeItem:
	if item != null:
		# enshure the parent is collapsed
		do_collapse_parent(item)
		item.select(0)
		_tree.ensure_cursor_is_visible()
		_tree.scroll_to_item(item, true)
	return item


func do_collapse_parent(item: TreeItem) -> void:
	if item != null:
		item.collapsed = false
		do_collapse_parent(item.get_parent())


func do_collapse_all(collapse: bool, parent := _tree_root) -> void:
	for item in parent.get_children():
		item.collapsed = collapse
		if not collapse:
			do_collapse_all(collapse, item)


func set_state_initial(item: TreeItem, type: GdUnitType) -> void:
	item.set_text(0, str(item.get_meta(META_GDUNIT_NAME)))
	item.set_custom_color(0, Color.LIGHT_GRAY)
	item.set_tooltip_text(0, "")
	item.set_text_overrun_behavior(0, TextServer.OVERRUN_TRIM_CHAR)
	item.set_expand_right(0, true)

	item.set_custom_color(1, Color.LIGHT_GRAY)
	item.set_text(1, "")
	item.set_expand_right(1, true)
	item.set_tooltip_text(1, "")

	item.set_meta(META_GDUNIT_STATE, STATE.INITIAL)
	item.set_meta(META_GDUNIT_TYPE, type)
	item.set_meta(META_GDUNIT_SUCCESS_TESTS, 0)
	item.set_meta(META_GDUNIT_EXECUTION_TIME, 0)
	if item.has_meta(META_GDUNIT_PROGRESS_COUNT_MAX) and item.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX) > 0:
		item.set_text(0, "(0/%d) %s" % [item.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX), item.get_meta(META_GDUNIT_NAME)])
	item.remove_meta(META_GDUNIT_REPORT)
	item.remove_meta(META_GDUNIT_ORPHAN)

	set_item_icon_by_state(item)


func set_state_running(item: TreeItem, is_running: bool) -> void:
	if is_state_running(item):
		return
	if is_item_state(item, STATE.INITIAL):
		item.set_custom_color(0, Color.DARK_GREEN)
		item.set_custom_color(1, Color.DARK_GREEN)
		item.set_meta(META_GDUNIT_STATE, STATE.RUNNING)
		item.collapsed = false

	if is_running:
		item.set_icon(0, ICON_SPINNER)
	else:
		set_item_icon_by_state(item)
		for child in item.get_children():
			set_item_icon_by_state(child)

	var parent := item.get_parent()
	if parent != _tree_root:
		set_state_running(parent, is_running)


func set_state_succeded(item: TreeItem) -> void:
	# Do not overwrite higher states
	if is_state_error(item) or is_state_failed(item):
		return
	if item == _tree_root:
		return
	item.set_custom_color(0, Color.GREEN)
	item.set_custom_color(1, Color.GREEN)
	item.set_meta(META_GDUNIT_STATE, STATE.SUCCESS)
	item.collapsed = GdUnitSettings.is_inspector_node_collapse()
	set_item_icon_by_state(item)


func set_state_flaky(item: TreeItem, event: GdUnitEvent) -> void:
	# Do not overwrite higher states
	if is_state_error(item):
		return
	var retry_count := event.statistic(GdUnitEvent.RETRY_COUNT)
	item.set_meta(META_GDUNIT_STATE, STATE.FLAKY)
	if retry_count > 1:
		var item_text: String = item.get_meta(META_GDUNIT_NAME)
		if item.has_meta(META_GDUNIT_PROGRESS_COUNT_MAX):
			var success_count: int = item.get_meta(META_GDUNIT_SUCCESS_TESTS)
			item_text = "(%d/%d) %s" % [success_count, item.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX), item.get_meta(META_GDUNIT_NAME)]
		item.set_text(0, "%s (%s retries)" % [item_text, retry_count])
	item.set_custom_color(0, Color.GREEN_YELLOW)
	item.set_custom_color(1, Color.GREEN_YELLOW)
	item.collapsed = false
	set_item_icon_by_state(item)


func set_state_skipped(item: TreeItem) -> void:
	item.set_meta(META_GDUNIT_STATE, STATE.SKIPPED)
	item.set_text(1, "(skipped)")
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	item.set_custom_color(0, Color.DARK_GRAY)
	item.set_custom_color(1, Color.DARK_GRAY)
	item.collapsed = false
	set_item_icon_by_state(item)


func set_state_warnings(item: TreeItem) -> void:
	# Do not overwrite higher states
	if is_state_error(item) or is_state_failed(item):
		return
	item.set_meta(META_GDUNIT_STATE, STATE.WARNING)
	item.set_custom_color(0, Color.YELLOW)
	item.set_custom_color(1, Color.YELLOW)
	item.collapsed = false
	set_item_icon_by_state(item)


func set_state_failed(item: TreeItem, event: GdUnitEvent) -> void:
	# Do not overwrite higher states
	if is_state_error(item):
		return
	var retry_count := event.statistic(GdUnitEvent.RETRY_COUNT)
	if retry_count > 1:
		var item_text: String = item.get_meta(META_GDUNIT_NAME)
		if item.has_meta(META_GDUNIT_PROGRESS_COUNT_MAX):
			var success_count: int = item.get_meta(META_GDUNIT_SUCCESS_TESTS)
			item_text = "(%d/%d) %s" % [success_count, item.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX), item.get_meta(META_GDUNIT_NAME)]
		item.set_text(0, "%s (%s retries)" % [item_text, retry_count])
	item.set_meta(META_GDUNIT_STATE, STATE.FAILED)
	item.set_custom_color(0, Color.LIGHT_BLUE)
	item.set_custom_color(1, Color.LIGHT_BLUE)
	item.collapsed = false
	set_item_icon_by_state(item)


func set_state_error(item: TreeItem) -> void:
	item.set_meta(META_GDUNIT_STATE, STATE.ERROR)
	item.set_custom_color(0, Color.ORANGE_RED)
	item.set_custom_color(1, Color.ORANGE_RED)
	set_item_icon_by_state(item)
	item.collapsed = false


func set_state_aborted(item: TreeItem) -> void:
	item.set_meta(META_GDUNIT_STATE, STATE.ABORDED)
	item.set_custom_color(0, Color.ORANGE_RED)
	item.set_custom_color(1, Color.ORANGE_RED)
	item.clear_custom_bg_color(0)
	item.set_text(1, "(aborted)")
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	set_item_icon_by_state(item)
	item.collapsed = false


func set_state_orphan(item: TreeItem, event: GdUnitEvent) -> void:
	var orphan_count := event.statistic(GdUnitEvent.ORPHAN_NODES)
	if orphan_count == 0:
		return
	if item.has_meta(META_GDUNIT_ORPHAN):
		orphan_count += item.get_meta(META_GDUNIT_ORPHAN)
	item.set_meta(META_GDUNIT_ORPHAN, orphan_count)
	if item.get_meta(META_GDUNIT_STATE) != STATE.FAILED:
		item.set_custom_color(0, Color.YELLOW)
		item.set_custom_color(1, Color.YELLOW)
	item.set_tooltip_text(0, "Total <%d> orphan nodes detected." % orphan_count)
	set_item_icon_by_state(item)


func update_state(item: TreeItem, event: GdUnitEvent, add_reports := true) -> void:
	# we do not show the root
	if item == null:
		return

	if event.is_skipped():
		set_state_skipped(item)
	elif event.is_success() and event.is_flaky():
		set_state_flaky(item, event)
	elif event.is_success():
		set_state_succeded(item)
	elif event.is_error():
		set_state_error(item)
	elif event.is_failed():
		set_state_failed(item, event)
	elif event.is_warning():
		set_state_warnings(item)
	if add_reports:
		for report in event.reports():
			add_report(item, report)
	set_state_orphan(item, event)

	var parent := item.get_parent()
	if parent == null:
		return

	var item_state: int = item.get_meta(META_GDUNIT_STATE)
	var parent_state: int = parent.get_meta(META_GDUNIT_STATE)
	if item_state <= parent_state:
		return
	update_state(item.get_parent(), event, false)


func add_report(item: TreeItem, report: GdUnitReport) -> void:
	var reports: Array[GdUnitReport] = []
	if item.has_meta(META_GDUNIT_REPORT):
		reports = get_item_reports(item)
	reports.append(report)
	item.set_meta(META_GDUNIT_REPORT, reports)


func abort_running(items:=_tree_root.get_children()) -> void:
	for item in items:
		if item.get_icon(0) == ICON_SPINNER:
			set_state_aborted(item)
			abort_running(item.get_children())


func _on_select_next_item_by_state(item_state: int) -> TreeItem:
	var current_selected := _tree.get_selected()
	# If nothing is selected, the first error is selected or the next one in the vicinity of the current selection is found
	current_selected = _find_first_item_by_state(_tree_root, item_state) if current_selected == null else _find_item_by_state(current_selected, item_state)
	# If no next failure found, then we try to select first
	if current_selected == null:
		current_selected = _find_first_item_by_state(_tree_root, item_state)
	return select_item(current_selected)


func _on_select_previous_item_by_state(item_state: int) -> TreeItem:
	var current_selected := _tree.get_selected()
	# If nothing is selected, the first error is selected or the next one in the vicinity of the current selection is found
	current_selected = _find_last_item_by_state(_tree_root, item_state) if current_selected == null else _find_item_by_state(current_selected, item_state, true)
	# If no next failure found, then we try to select first last
	if current_selected == null:
		current_selected = _find_last_item_by_state(_tree_root, item_state)
	return select_item(current_selected)


func select_first_orphan() -> void:
	for parent in _tree_root.get_children():
		if not is_state_success(parent):
			for item in parent.get_children():
				if is_item_state_orphan(item):
					parent.set_collapsed(false)
					@warning_ignore("return_value_discarded")
					select_item(item)
					return


func clear_reports() -> void:
	for child in _report_list.get_children():
		_report_list.remove_child(child)
		child.queue_free()


func show_failed_report(selected_item: TreeItem) -> void:
	clear_reports()
	if selected_item == null or not selected_item.has_meta(META_GDUNIT_REPORT):
		return
	# add new reports
	for report in get_item_reports(selected_item):
		var reportNode: RichTextLabel = _report_template.duplicate()
		_report_list.add_child(reportNode)
		reportNode.push_color(Color.DARK_TURQUOISE)
		reportNode.append_text(report.to_string())
		reportNode.pop()
		reportNode.visible = true


func update_test_suite(event: GdUnitEvent) -> void:
	var item := _find_tree_item_by_test_suite(_tree_root, event.resource_path(), event.suite_name())
	if not item:
		push_error("[InspectorTreeMainPanel#update_test_suite] Internal Error: Can't find test suite item '{_suite_name}' for {_resource_path} ".format(event))
		return
	if event.type() == GdUnitEvent.TESTSUITE_AFTER:
		update_item_elapsed_time_counter(item, event.elapsed_time())
		update_state(item, event)
		set_state_running(item, false)


func update_test_case(event: GdUnitEvent) -> void:
	var item := _find_tree_item_by_id(_tree_root, event.guid())
	if not item:
		#push_error("Internal Error: Can't find test id %s" % [event.guid()])
		return
	if event.type() == GdUnitEvent.TESTCASE_BEFORE:
		set_state_running(item, true)
		# force scrolling to current test case
		_tree.scroll_to_item(item, true)
		return

	if event.type() == GdUnitEvent.TESTCASE_AFTER:
		update_item_elapsed_time_counter(item, event.elapsed_time())
		if event.is_success() or event.is_warning():
			update_item_processed_counter(item)
		update_state(item, event)
		update_progress_counters(item)


func create_item(parent: TreeItem, test: GdUnitTestCase, item_name: String, type: GdUnitType) -> TreeItem:
	var item := _tree.create_item(parent)
	item.collapsed = true
	item.set_meta(META_GDUNIT_ORIGINAL_INDEX, item.get_index())
	item.set_text(0, item_name)
	match type:
		GdUnitType.TEST_CASE:
			item.set_meta(META_TEST_CASE, test)
		GdUnitType.TEST_GROUP:
			# We need to create a copy of the test record meta with a new uniqe guid
			item.set_meta(META_TEST_CASE, GdUnitTestCase.from(test.suite_resource_path, test.source_file, test.line_number, test.test_name))
		GdUnitType.TEST_SUITE:
			# We need to create a copy of the test record meta with a new uniqe guid
			item.set_meta(META_TEST_CASE, GdUnitTestCase.from(test.suite_resource_path, test.source_file, test.line_number, test.suite_name))

	item.set_meta(META_GDUNIT_NAME, item_name)
	set_state_initial(item, type)
	update_item_total_counter(item)
	return item


func set_item_icon_by_state(item :TreeItem) -> void:
	if item == _tree_root:
		return
	var state :STATE = item.get_meta(META_GDUNIT_STATE)
	var is_orphan := is_item_state_orphan(item)
	var resource_path := get_item_source_file(item)
	item.set_icon(0, get_icon_by_file_type(resource_path, state, is_orphan))
	if item.get_meta(META_GDUNIT_TYPE) == GdUnitType.FOLDER:
		item.set_icon_modulate(0, Color.SKY_BLUE)


func update_item_total_counter(item: TreeItem) -> void:
	if item == null:
		return

	var child_count := get_total_child_count(item)
	if child_count > 0:
		item.set_meta(META_GDUNIT_PROGRESS_COUNT_MAX, child_count)
		item.set_text(0, "(0/%d) %s" % [child_count, item.get_meta(META_GDUNIT_NAME)])

	update_item_total_counter(item.get_parent())


func get_total_child_count(item: TreeItem) -> int:
	var total_count := 0
	for child in item.get_children():
		total_count += child.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX) if child.has_meta(META_GDUNIT_PROGRESS_COUNT_MAX) else 1
	return total_count


func update_item_processed_counter(item: TreeItem, add_count := 1) -> void:
	if item == _tree_root:
		return

	var success_count: int = item.get_meta(META_GDUNIT_SUCCESS_TESTS) + add_count
	item.set_meta(META_GDUNIT_SUCCESS_TESTS, success_count)
	if item.has_meta(META_GDUNIT_PROGRESS_COUNT_MAX):
		item.set_text(0, "(%d/%d) %s" % [success_count, item.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX), item.get_meta(META_GDUNIT_NAME)])

	update_item_processed_counter(item.get_parent(), add_count)


func update_progress_counters(item: TreeItem) -> void:
	var index: int = _tree_root.get_meta(META_GDUNIT_PROGRESS_INDEX) + 1
	var total_test: int = _tree_root.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX)
	var state: STATE = item.get_meta(META_GDUNIT_STATE)
	test_counters_changed.emit(index, total_test, state)
	_tree_root.set_meta(META_GDUNIT_PROGRESS_INDEX, index)


func recalculate_counters(parent: TreeItem) -> void:
	# Reset the counter first
	if parent.has_meta(META_GDUNIT_PROGRESS_COUNT_MAX):
		parent.set_meta(META_GDUNIT_PROGRESS_COUNT_MAX, 0)
	if parent.has_meta(META_GDUNIT_PROGRESS_INDEX):
		parent.set_meta(META_GDUNIT_PROGRESS_INDEX, 0)
	if parent.has_meta(META_GDUNIT_SUCCESS_TESTS):
		parent.set_meta(META_GDUNIT_SUCCESS_TESTS, 0)

	# Calculate new count based on children
	var total_count := 0
	var success_count := 0
	var progress_index := 0

	for child in parent.get_children():
		if child.get_child_count() > 0:
			# Recursively update child counters first
			recalculate_counters(child)
			# Add child's counters to parent
			if child.has_meta(META_GDUNIT_PROGRESS_COUNT_MAX):
				total_count += child.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX)
			if child.has_meta(META_GDUNIT_SUCCESS_TESTS):
				success_count += child.get_meta(META_GDUNIT_SUCCESS_TESTS)
			if child.has_meta(META_GDUNIT_PROGRESS_INDEX):
				progress_index += child.get_meta(META_GDUNIT_PROGRESS_INDEX)
		elif is_test_case(child):
			# Count individual test cases
			total_count += 1
			# Count completed tests
			if is_state_success(child) or is_state_warning(child) or is_state_failed(child) or is_state_error(child):
				progress_index += 1
			if is_state_success(child) or is_state_warning(child):
				success_count += 1

	# Update the counters
	if total_count > 0:
		parent.set_meta(META_GDUNIT_PROGRESS_COUNT_MAX, total_count)
		parent.set_meta(META_GDUNIT_PROGRESS_INDEX, progress_index)
		parent.set_meta(META_GDUNIT_SUCCESS_TESTS, success_count)

		# Update the display text
		parent.set_text(0, "(%d/%d) %s" % [success_count, total_count, parent.get_meta(META_GDUNIT_NAME)])


func update_item_elapsed_time_counter(item: TreeItem, time: int) -> void:
	item.set_text(1, "%s" % LocalTime.elapsed(time))
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	item.set_meta(META_GDUNIT_EXECUTION_TIME, time)

	var parent := item.get_parent()
	if parent == _tree_root:
		return
	var elapsed_time :int = parent.get_meta(META_GDUNIT_EXECUTION_TIME) + time
	var type :GdUnitType = item.get_meta(META_GDUNIT_TYPE)
	match type:
		GdUnitType.TEST_CASE:
			return
		GdUnitType.TEST_SUITE:
			update_item_elapsed_time_counter(parent, elapsed_time)
		#GdUnitType.FOLDER:
		#	update_item_elapsed_time_counter(parent, elapsed_time)


func get_icon_by_file_type(path: String, state: STATE, orphans: bool) -> Texture2D:
	if path.get_extension() == "gd":
		match state:
			STATE.INITIAL:
				return ICON_GDSCRIPT_TEST_DEFAULT
			STATE.SUCCESS:
				return ICON_GDSCRIPT_TEST_SUCCESS_ORPHAN if orphans else ICON_GDSCRIPT_TEST_SUCCESS
			STATE.ERROR:
				return ICON_GDSCRIPT_TEST_ERRORS_ORPHAN if orphans else ICON_GDSCRIPT_TEST_ERROR
			STATE.FAILED:
				return ICON_GDSCRIPT_TEST_FAILED_ORPHAN if orphans else ICON_GDSCRIPT_TEST_FAILED
			STATE.WARNING:
				return ICON_GDSCRIPT_TEST_SUCCESS_ORPHAN if orphans else ICON_GDSCRIPT_TEST_DEFAULT
			STATE.FLAKY:
				return ICON_GDSCRIPT_TEST_SUCCESS_ORPHAN if orphans else ICON_GDSCRIPT_TEST_FLAKY
			_:
				return ICON_GDSCRIPT_TEST_DEFAULT
	if path.get_extension() == "cs":
		match state:
			STATE.INITIAL:
				return ICON_CSSCRIPT_TEST_DEFAULT
			STATE.SUCCESS:
				return ICON_CSSCRIPT_TEST_SUCCESS_ORPHAN if orphans else ICON_CSSCRIPT_TEST_SUCCESS
			STATE.ERROR:
				return ICON_CSSCRIPT_TEST_ERRORS_ORPHAN if orphans else ICON_CSSCRIPT_TEST_ERROR
			STATE.FAILED:
				return ICON_CSSCRIPT_TEST_FAILED_ORPHAN if orphans else ICON_CSSCRIPT_TEST_FAILED
			STATE.WARNING:
				return ICON_CSSCRIPT_TEST_SUCCESS_ORPHAN if orphans else ICON_CSSCRIPT_TEST_DEFAULT
			_:
				return ICON_CSSCRIPT_TEST_DEFAULT
	match state:
		STATE.INITIAL:
			return ICON_FOLDER
		STATE.ERROR:
			return ICON_FOLDER
		STATE.FAILED:
			return ICON_FOLDER
		_:
			return ICON_FOLDER


func on_test_case_discover_added(test_case: GdUnitTestCase) -> void:
	var test_root_folder := GdUnitSettings.test_root_folder().replace("res://", "")
	var fully_qualified_name := test_case.fully_qualified_name.trim_suffix(test_case.display_name)
	var parts := fully_qualified_name.split(".", false)
	parts.append(test_case.display_name)
	# Skip tree structure until test root folder
	var index := parts.find(test_root_folder)
	if index != -1:
		parts = parts.slice(index+1)

	match _current_tree_view_mode:
		GdUnitInspectorTreeConstants.TREE_VIEW_MODE.FLAT:
			create_items_tree_mode_flat(test_case, parts)
		GdUnitInspectorTreeConstants.TREE_VIEW_MODE.TREE:
			create_items_tree_mode_tree(test_case, parts)


func create_items_tree_mode_tree(test_case: GdUnitTestCase, parts: PackedStringArray) -> void:
	var parent := _tree_root
	var is_suite_assigned := false
	var suite_name := test_case.suite_name.split(".")[-1]
	for item_name in parts:
		var next := _find_tree_item(parent, item_name)
		if next != null:
			parent = next
			continue

		if not is_suite_assigned and suite_name == item_name:
			next = create_item(parent, test_case, item_name, GdUnitType.TEST_SUITE)
			is_suite_assigned = true
		elif item_name == test_case.display_name:
			next = create_item(parent, test_case, item_name, GdUnitType.TEST_CASE)
		# On grouped tests (parameterized tests)
		elif item_name == test_case.test_name:
			next = create_item(parent, test_case, item_name, GdUnitType.TEST_GROUP)
		else:
			next = create_item(parent, test_case, item_name, GdUnitType.FOLDER)
		parent = next


func create_items_tree_mode_flat(test_case: GdUnitTestCase, parts: PackedStringArray) -> void:
	# All parts except the last two (suite name and test name/display name)
	var slice_index := -2 if parts[-1] == test_case.test_name else -3
	var path_parts := parts.slice(0, slice_index)
	var folder_path := "/".join(path_parts)

	# Find or create flat folder
	var folder_item: TreeItem
	if folder_path.is_empty():
		folder_item = _tree_root
	else:
		folder_item = _find_tree_item(_tree_root, folder_path)
		if folder_item == null:
			folder_item = create_item(_tree_root, test_case, folder_path, GdUnitType.FOLDER)

	# Find suite under the flat folder (second to last part)
	var suite_item := _find_tree_item(folder_item, test_case.suite_name)
	if suite_item == null:
		suite_item = create_item(folder_item, test_case, test_case.suite_name, GdUnitType.TEST_SUITE)

	# Add test case or group under the suite
	if test_case.test_name != test_case.display_name:
		# It's a parameterized test group
		var group_item := _find_tree_item(suite_item, test_case.test_name)
		if group_item == null:
			group_item = create_item(suite_item, test_case, test_case.test_name, GdUnitType.TEST_GROUP)
		create_item(group_item, test_case, test_case.display_name, GdUnitType.TEST_CASE)
	else:
		create_item(suite_item, test_case, test_case.display_name, GdUnitType.TEST_CASE)


func on_test_case_discover_deleted(test_case: GdUnitTestCase) -> void:
	var item := _find_tree_item_by_id(_tree_root, test_case.guid)
	if item != null:
		var parent := item.get_parent()
		parent.remove_child(item)

		# update the cached counters
		var item_success_count: int = item.get_meta(META_GDUNIT_SUCCESS_TESTS)
		var item_total_test_count: int = item.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX, 0)
		var total_test_count: int = parent.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX, 0)
		parent.set_meta(META_GDUNIT_PROGRESS_COUNT_MAX, total_test_count-item_total_test_count)

		# propagate counter update to all parents
		update_item_total_counter(parent)
		update_item_processed_counter(parent, -item_success_count)


func on_test_case_discover_modified(test_case: GdUnitTestCase) -> void:
	var item := _find_tree_item_by_id(_tree_root, test_case.guid)
	if item != null:
		item.set_meta(META_TEST_CASE, test_case)
		item.set_text(0, test_case.display_name)
		item.set_meta(META_GDUNIT_NAME, test_case.display_name)


func get_item_reports(item: TreeItem) -> Array[GdUnitReport]:
	return item.get_meta(META_GDUNIT_REPORT)


func get_item_test_line_number(item: TreeItem) -> int:
	if item == null or not item.has_meta(META_TEST_CASE):
		return -1

	var test_case: GdUnitTestCase = item.get_meta(META_TEST_CASE)
	return test_case.line_number


func get_item_source_file(item: TreeItem) -> String:
	if item == null or not item.has_meta(META_TEST_CASE):
		return ""

	var test_case: GdUnitTestCase = item.get_meta(META_TEST_CASE)
	return test_case.source_file


func get_item_type(item: TreeItem) -> GdUnitType:
	if item == null or not item.has_meta(META_GDUNIT_TYPE):
		return GdUnitType.FOLDER
	return item.get_meta(META_GDUNIT_TYPE)


func _dump_tree_as_json(dump_name: String) -> void:
	var dict := _to_json(_tree_root)
	var file := FileAccess.open("res://%s.json" % dump_name, FileAccess.WRITE)
	file.store_string(JSON.stringify(dict, "\t"))


func _to_json(parent :TreeItem) -> Dictionary:
	var item_as_dict := GdObjects.obj2dict(parent)
	item_as_dict["TreeItem"]["childrens"] = parent.get_children().map(func(item: TreeItem) -> Dictionary:
			return _to_json(item))
	return item_as_dict


func extract_resource_path(event: GdUnitEvent) -> String:
	return ProjectSettings.localize_path(event.resource_path())


func collect_test_cases(item: TreeItem, tests: Array[GdUnitTestCase] = []) -> Array[GdUnitTestCase]:
	for next in item.get_children():
		collect_test_cases(next, tests)

	if is_test_case(item):
		var test: GdUnitTestCase = item.get_meta(META_TEST_CASE)
		if not tests.has(test):
			tests.append(test)

	return tests


func test_session_start() -> void:
	_context_menu.disable_items()
	reset_tree_state(_tree_root)
	clear_reports()


func test_session_stop() -> void:
	_context_menu.enable_items()
	abort_running()
	sort_tree_items(_tree_root)
	# wait until the tree redraw
	await get_tree().process_frame
	var failure_item := _find_first_item_by_state(_tree_root, STATE.FAILED)
	select_item( failure_item if failure_item else _current_selected_item)


################################################################################
# Tree signal receiver
################################################################################
func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_context_menu.position = get_screen_position() + mouse_position
		_context_menu.popup()


func _on_Tree_item_selected() -> void:
	_current_selected_item = _tree.get_selected()
	show_failed_report(_current_selected_item)
	tree_item_selected.emit(_current_selected_item)


# Opens the test suite
func _on_Tree_item_activated() -> void:
	var selected_item := _tree.get_selected()
	var line_number := get_item_test_line_number(selected_item)
	if line_number != -1:
		var script_path := ProjectSettings.localize_path(get_item_source_file(selected_item))
		var resource: Script = load(script_path)

		if selected_item.has_meta(META_GDUNIT_REPORT):
			var reports := get_item_reports(selected_item)
			var report_line_number := reports[0].line_number()
			# if number -1 we use original stored line number of the test case
			# in non debug mode the line number is not available
			if report_line_number != -1:
				line_number = report_line_number

		EditorInterface.get_file_system_dock().navigate_to_path(script_path)
		EditorInterface.edit_script(resource, line_number)
	elif selected_item.get_meta(META_GDUNIT_TYPE) == GdUnitType.FOLDER:
		# Toggle collapse if dir
		selected_item.collapsed = not selected_item.collapsed


################################################################################
# external signal receiver
################################################################################

func _on_gdunit_event(event: GdUnitEvent) -> void:
	match event.type():
		GdUnitEvent.DISCOVER_START:
			_tree_root.visible = false
			_discover_hint.visible = true
			init_tree()

		GdUnitEvent.DISCOVER_END:
			sort_tree_items(_tree_root)
			select_item(_tree_root.get_first_child())
			_discover_hint.visible = false
			_tree_root.visible = true
			#_dump_tree_as_json("tree_example_discovered")

		GdUnitEvent.TESTCASE_BEFORE:
			update_test_case(event)

		GdUnitEvent.TESTCASE_AFTER:
			update_test_case(event)

		GdUnitEvent.TESTSUITE_BEFORE:
			update_test_suite(event)

		GdUnitEvent.TESTSUITE_AFTER:
			update_test_suite(event)

		GdUnitEvent.SESSION_START:
			test_session_start()

		GdUnitEvent.SESSION_CLOSE:
			await test_session_stop()


func _on_settings_changed(property :GdUnitProperty) -> void:
	match property.name():
		GdUnitSettings.INSPECTOR_TREE_SORT_MODE:
			sort_tree_items(_tree_root)
			#_dump_tree_as_json("tree_sorted_by_%s" % GdUnitInspectorTreeConstants.SORT_MODE.keys()[property.value()])

		GdUnitSettings.INSPECTOR_TREE_VIEW_MODE:
			restructure_tree(_tree_root, GdUnitSettings.get_inspector_tree_view_mode())
