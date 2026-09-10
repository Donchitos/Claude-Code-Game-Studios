@tool
extends Control

## Will be emitted when the test index counter is changed
signal test_counters_changed(index: int, total: int, state: GdUnitInspectorTreeConstants.STATE)
signal tree_item_selected(item: TreeItem)


@onready var _tree: Tree = %Tree
@onready var _report_panel: GdUnitReportPanel = %report
@onready var _context_menu: GdUnitInspectorContextMenu = %contextMenu
@onready var _discover_hint: Control = %discover_hint
@onready var _spinner: Button = %spinner

# loading tree icons
var ICON_SPINNER: Texture2D
var ICON_GD_SCRIPT: Texture2D
var ICON_CS_SCRIPT: Texture2D
var ICON_FOLDER: Texture2D


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
		if item_state in [STATE.FAILED, STATE.ERROR] and get_item_reports(item).is_empty():
			var item_by_state := _find_first_item_by_state(item, item_state, reverse)
			if item_by_state != null:
				return item_by_state

		if is_item_state(item, item_state):
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

	if item_state in [STATE.FAILED, STATE.ERROR] and get_item_reports(next).is_empty():
		return _find_item_by_state(next, item_state, prev)

	if is_item_state(next, item_state):
		return next
	return _find_item_by_state(next, item_state, prev)


func is_item_state(item: TreeItem, item_state: STATE) -> bool:
	return get_item_state(item).has(item_state)


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


func is_test_group(item: TreeItem) -> bool:
	return item.has_meta(META_GDUNIT_TYPE) and item.get_meta(META_GDUNIT_TYPE) == GdUnitType.TEST_GROUP


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

	_init_icons()
	init_tree()
	GdUnitSignals.instance().gdunit_settings_changed.connect(_on_settings_changed)
	GdUnitSignals.instance().gdunit_event.connect(_on_gdunit_event)
	GdUnitSignals.instance().gdunit_test_discover_added.connect(on_test_case_discover_added)
	GdUnitSignals.instance().gdunit_test_discover_deleted.connect(on_test_case_discover_deleted)
	GdUnitSignals.instance().gdunit_test_discover_modified.connect(on_test_case_discover_modified)
	if _run_test_recovery:
		GdUnitTestDiscoverer.restore_last_session()


func _notification(what: int) -> void:
	if what == EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED:
		_init_icons()


func _init_icons() -> void:
	_spinner.icon = GdUnitUiTools.get_spinner()
	ICON_GD_SCRIPT = GdUnitUiTools.get_icon("GDScript", GdUnitEditorColorTheme.state_initial)
	ICON_CS_SCRIPT = GdUnitUiTools.get_icon("CSharpScript", GdUnitEditorColorTheme.state_initial)
	ICON_FOLDER = GdUnitUiTools.get_icon("Folder", GdUnitEditorColorTheme.folder_color)


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
	_tree_root.set_meta(META_GDUNIT_SUCCESS_TESTS, 0)
	set_item_state(_tree_root, STATE.INITIAL)
	# fix tree icon scaling
	var scale_factor := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	_tree.set("theme_override_constants/icon_max_width", 16 * scale_factor)


func cleanup_tree() -> void:
	_report_panel.clear()
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
		set_item_state(_tree_root, STATE.INITIAL)
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
	item.set_tooltip_text(0, "")
	item.set_text_overrun_behavior(0, TextServer.OVERRUN_TRIM_CHAR)
	item.set_expand_right(0, true)

	item.set_text(1, "")
	item.set_expand_right(1, true)
	item.set_tooltip_text(1, "")
	item.set_meta(META_GDUNIT_TYPE, type)
	item.set_meta(META_GDUNIT_SUCCESS_TESTS, 0)
	item.set_meta(META_GDUNIT_EXECUTION_TIME, 0)
	if item.has_meta(META_GDUNIT_PROGRESS_COUNT_MAX) and item.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX) > 0:
		item.set_text(0, "(0/%d) %s" % [item.get_meta(META_GDUNIT_PROGRESS_COUNT_MAX), item.get_meta(META_GDUNIT_NAME)])
	item.remove_meta(META_GDUNIT_REPORT)
	item.remove_meta(META_GDUNIT_ORPHAN)

	set_item_state(item, STATE.INITIAL)


func set_state_running(item: TreeItem) -> void:
	if is_state_running(item):
		return
	if is_item_state(item, STATE.INITIAL):
		set_item_state(item, STATE.RUNNING)
		item.collapsed = false

	var parent := item.get_parent()
	if parent != _tree_root:
		set_state_running(parent)


func set_state_succeded(item: TreeItem) -> void:
	# Do not overwrite higher states
	if is_state_error(item) or is_state_failed(item):
		return
	if item == _tree_root:
		return
	item.collapsed = GdUnitSettings.is_inspector_node_collapse()
	set_item_state(item, STATE.SUCCESS)


func set_state_flaky(item: TreeItem, event: GdUnitEvent) -> void:
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

	item.collapsed = false
	set_item_state(item, STATE.FLAKY)


func set_state_skipped(item: TreeItem) -> void:
	item.set_text(1, "(skipped)")
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	item.collapsed = false
	set_item_state(item, STATE.SKIPPED)


func set_state_warnings(item: TreeItem) -> void:
	# Do not overwrite higher states
	if is_state_error(item) or is_state_failed(item):
		return

	item.collapsed = false
	set_item_state(item, STATE.WARNING)


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
	item.collapsed = false
	set_item_state(item, STATE.FAILED)


func set_state_error(item: TreeItem) -> void:
	set_item_state(item, STATE.ERROR)
	item.collapsed = false


func set_state_aborted(item: TreeItem) -> void:
	item.set_text(1, "(aborted)")
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	set_item_state(item, STATE.ABORDED)
	item.collapsed = false


func set_state_orphan(item: TreeItem, event: GdUnitEvent) -> void:
	var orphan_count := event.statistic(GdUnitEvent.ORPHAN_NODES)
	if orphan_count == 0:
		return

	set_item_state(item, STATE.ORPHAN)
	item.set_meta(META_GDUNIT_ORPHAN, orphan_count)
	item.set_tooltip_text(0, "Total <%d> orphan nodes detected." % orphan_count)


func update_state(item: TreeItem, event: GdUnitEvent) -> void:
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
	set_state_orphan(item, event)


func add_report(item: TreeItem, report: GdUnitReport) -> void:
	var reports: Array[GdUnitReport] = []
	if item.has_meta(META_GDUNIT_REPORT):
		reports = get_item_reports(item)
	reports.append(report)
	item.set_meta(META_GDUNIT_REPORT, reports)


func add_reports(item: TreeItem, reports: Array[GdUnitReport]) -> void:
	for report in reports:
		add_report(item, report)


func abort_running(items := _tree_root.get_children()) -> void:
	for item in items:
		if is_state_running(item):
			if is_test_case(item):
				set_state_aborted(item)
			else:
				var state := _find_highest_state(item)
				if state == STATE.RUNNING:
					set_state_aborted(item)
				else:
					set_item_state(item, state)
				abort_running(item.get_children())


func _on_select_next_item_by_state(item_state: int) -> TreeItem:
	var current_selected := _tree.get_selected()
	# If nothing is selected, the first error is selected or the next one in the vicinity of the current selection is found
	current_selected = (_find_first_item_by_state(_tree_root, item_state)
		if current_selected == null
		else _find_item_by_state(current_selected, item_state))
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


func update_test_suite(event: GdUnitEvent) -> void:
	var item := _find_tree_item_by_test_suite(_tree_root, event.resource_path(), event.suite_name())
	if not item:
		push_error("[InspectorTreeMainPanel#update_test_suite] Internal Error: Can't find test suite item '{_suite_name}' for {_resource_path} ".format(event))
		return

	update_item_state_recursive(item)
	update_item_elapsed_time_counter_recursive(item, event.elapsed_time())
	update_item_orphan_counter_recursive(item)
	# update the state and add possible reports
	update_state(item, event)
	add_reports(item, event.reports())


func update_test_case(event: GdUnitEvent) -> void:
	var item := _find_tree_item_by_id(_tree_root, event.guid())
	if not item:
		#push_error("Internal Error: Can't find test id %s" % [event.guid()])
		return
	if event.type() == GdUnitEvent.TESTCASE_BEFORE:
		set_state_running(item)
		# force scrolling to current test case
		_tree.scroll_to_item(item, true)
		return

	if event.type() == GdUnitEvent.TESTCASE_AFTER:
		update_item_elapsed_time_counter_recursive(item, event.elapsed_time())
		if event.is_success() or event.is_warning():
			update_item_processed_counter(item)
		# update the state and add possible reports
		update_state(item, event)
		update_progress_counters(item)
		# update test group
		if is_test_group(item.get_parent()):
			update_state(item.get_parent(), event)
		add_reports(item, event.reports())


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


static func get_item_state(item: TreeItem) -> Array[STATE]:
	if item.has_meta(META_GDUNIT_STATE):
		return item.get_meta(META_GDUNIT_STATE)
	return [STATE.INITIAL, STATE.INITIAL]


static func get_item_orphans(item: TreeItem) -> int:
	if item.has_meta(META_GDUNIT_ORPHAN):
		return item.get_meta(META_GDUNIT_ORPHAN)
	return 0


func get_item_children_orphans(item: TreeItem) -> int:
	var orphans_total := 0
	for child_item in item.get_children():
		orphans_total += get_item_orphans(child_item)
	return orphans_total


func get_item_children_elapsed_time(item: TreeItem) -> int:
	var elapsed_time_total := 0
	for child_item in item.get_children():
		elapsed_time_total += child_item.get_meta(META_GDUNIT_EXECUTION_TIME)
	return elapsed_time_total


func set_item_state(item: TreeItem, state: STATE) -> void:
	if item == _tree_root:
		return

	if state != STATE.RUNNING and is_folder(item):
		var resource_path := get_item_source_file(item)
		item.set_icon(0, get_icon_by_file_type(resource_path))
	else:
		item.set_icon(0, GdUnitUiTools.get_state_icon(state))

	if state == STATE.INITIAL:
		var inital_state: Array[STATE] = [STATE.INITIAL, STATE.INITIAL]
		item.set_meta(META_GDUNIT_STATE, inital_state)
	elif state == STATE.ORPHAN:
		get_item_state(item)[1] = state
	else:
		get_item_state(item)[0] = state

	set_item_state_color(item, state)


func set_item_state_color(item: TreeItem, state: STATE) -> void:
	if item == _tree_root:
		return

	var state_color := GdUnitEditorColorTheme.state_initial
	match state:
		STATE.INITIAL:
			state_color = GdUnitEditorColorTheme.state_initial
		STATE.RUNNING, STATE.SUCCESS:
			state_color = GdUnitEditorColorTheme.state_success
		STATE.WARNING:
			state_color = GdUnitEditorColorTheme.state_warning
		STATE.FLAKY:
			state_color = GdUnitEditorColorTheme.state_flaky
		STATE.ERROR, STATE.ABORDED:
			state_color = GdUnitEditorColorTheme.state_error
		STATE.FAILED:
			state_color = GdUnitEditorColorTheme.state_failure
		STATE.SKIPPED:
			state_color = GdUnitEditorColorTheme.state_skipped
		STATE.ORPHAN:
			# For orphan state we do not overwrite the orignal color state
			return

	item.set_custom_color(0, state_color)
	item.set_custom_color(1, state_color)


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
	var state := get_item_state(item)[0]
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


func update_item_elapsed_time_counter_recursive(item: TreeItem, elapsed_time: int) -> void:
	if item == _tree_root:
		return
	if is_folder(item) or is_test_group(item):
		elapsed_time = get_item_children_elapsed_time(item)

	item.set_text(1, "%s" % LocalTime.elapsed(elapsed_time))
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	item.set_meta(META_GDUNIT_EXECUTION_TIME, elapsed_time)
	update_item_elapsed_time_counter_recursive(item.get_parent(), elapsed_time)


func update_item_orphan_counter_recursive(item: TreeItem) -> void:
	if item == _tree_root:
		return

	var orphan_count := 0
	var type: GdUnitType = item.get_meta(META_GDUNIT_TYPE)
	match type:
		GdUnitType.TEST_CASE:
			return
		GdUnitType.TEST_SUITE:
			orphan_count = get_item_children_orphans(item) + get_item_orphans(item)
			if orphan_count > 0:
				set_item_state(item, STATE.ORPHAN)
		GdUnitType.FOLDER:
			orphan_count = get_item_children_orphans(item)

	if orphan_count == 0:
		return
	item.set_meta(META_GDUNIT_ORPHAN, orphan_count)
	item.set_tooltip_text(0, "Total <%d> orphan nodes detected." % orphan_count)
	update_item_orphan_counter_recursive(item.get_parent())


func update_item_state_recursive(item: TreeItem) -> void:
	if item == _tree_root:
		return

	var state := _find_highest_state(item)
	set_item_state(item, state)

	update_item_state_recursive(item.get_parent())


func _find_highest_state(item: TreeItem) -> STATE:
	var state := STATE.INITIAL
	for child in item.get_children():
		var item_state := get_item_state(child)[0]
		if item_state > state:
			state = item_state
	return state



func get_icon_by_file_type(path: String) -> Texture2D:
	if path.get_extension() == "gd":
		return ICON_GD_SCRIPT
	if path.get_extension() == "cs":
		return ICON_CS_SCRIPT
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
	if item == null or not item.has_meta(META_GDUNIT_REPORT):
		return []
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
	_report_panel.clear()


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
	var reports := get_item_reports(_current_selected_item)
	_report_panel.show_report(reports)
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
