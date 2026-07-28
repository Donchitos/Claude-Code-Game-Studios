class_name GdUnitOrphanNodesMonitor
extends GdUnitMonitor

const excluded_frame_files: PackedStringArray = [
	"GdUnitOrphanNodesMonitor",
	"GdUnitExecutionContext",
	"_TestCase",
	"IGdUnitExecutionStage",
	"GdUnitTestCaseSingleTestStage",
	"GdUnitTestCaseSingleExecutionStage",
	"GdUnitTestCaseExecutionStage",
	"GdUnitTestSuiteExecutionStage",
	"GdUnitTestSuiteExecutor"
]

var _child_monitors: Array[GdUnitOrphanNodesMonitor] = []
var _orphan_detection_enabled :bool
var _initial_orphans: Array[int] = []
var _orphan_ids_at_start: Array[int] = []
var _orphan_ids_at_stop: Array[int] = []
var _collected_orphan_infos: Array[GdUnitOrphanNodeInfo] = []


func _init(name: String) -> void:
	super("OrphanNodesMonitor:" + name)
	_orphan_detection_enabled = GdUnitSettings.is_verbose_orphans()
	_initial_orphans = _get_orphan_node_ids()


func add_child_monitor(monitor: GdUnitOrphanNodesMonitor) -> void:
	if not _orphan_detection_enabled:
		return
	_child_monitors.append(monitor)


func start() -> void:
	if not _orphan_detection_enabled:
		return
	_collected_orphan_infos.clear()
	# Collect current orphan id's to be filtered out at `stop`
	_orphan_ids_at_start = _get_orphan_node_ids()


func stop() -> void:
	if not _orphan_detection_enabled:
		return
	# Collect only new detected orphan id's, we want only to collect orphans between start and stop time
	_orphan_ids_at_stop = _get_orphan_node_ids().filter(func(element: int) -> bool:
		# Excluding sub monitores orphans
		if _collect_child_orphan_ids().has(element):
			return false
		# Excluding orphans at start
		return not _orphan_ids_at_start.has(element) and not _initial_orphans.has(element)
	)


func _collect_child_orphan_ids() -> Array[int]:
	var collected_ids: Array[int] = []
	for child_monitor in _child_monitors:
		collected_ids.append_array(child_monitor._orphan_ids_at_stop)
		collected_ids.append_array(child_monitor._collect_child_orphan_ids())
	return collected_ids


func detected_orphans() -> Array[GdUnitOrphanNodeInfo]:
	if not _orphan_detection_enabled:
		return []
	return _collected_orphan_infos.filter(func(info: GdUnitOrphanNodeInfo) -> bool:
		return info._id in _orphan_ids_at_stop
	)


func orphans_count() -> int:
	if not _orphan_detection_enabled:
		return 0
	return _orphan_ids_at_stop.size()


func collect() -> void:
	if not _orphan_detection_enabled:
		return
	for orphan_id in _get_orphan_node_ids():
		var orphan_to_find := instance_from_id(orphan_id)
		_collect_orphan_info(orphan_to_find)


func _collect_orphan_info(orphan_to_find: Object) -> void:
	if orphan_to_find == null:
		return

	var orphan_node := _find_orphan_on_backtraces(orphan_to_find)
	if orphan_node:
		_collected_orphan_infos.append(orphan_node)
		return

	if Engine.has_meta("GdUnitSceneRunner"):
		var current_scene_runner:GdUnitSceneRunner = Engine.get_meta("GdUnitSceneRunner")
		if is_instance_valid(current_scene_runner):
			orphan_node = _find_orphan_at_node(orphan_to_find, current_scene_runner.scene())
			if orphan_node:
				_collected_orphan_infos.append(orphan_node)
				return

	# not able to find the orphan node via backtrace loaded nodeds
	var message := "No details found. Verify called functions manually."
	if not EngineDebugger.is_active():
		message = "No details available. [color=yellow]Run tests in debug mode to collect details.[/color]"

	_collected_orphan_infos.append(GdUnitOrphanNodeInfo.new(
		GdUnitOrphanNodeInfo.GdUnitOrphanType.unknown,
		orphan_to_find.get_instance_id(),
		orphan_to_find.get_class(),
		message,
		""))


func _find_orphan_at_node(orphan_to_find: Object, node: Node) -> GdUnitOrphanNodeInfo:
	var script: Script = node.get_script()
	if script is not GDScript:
		return null

	# First search over all properties
	for property in script.get_script_property_list():
		var property_name: String = property["name"]
		var property_type: int = property["type"]
		# Is untyped or type object
		if property_type in [TYPE_NIL, TYPE_OBJECT]:
			var property_instance: Variant = node.get(property_name)
			@warning_ignore("unsafe_cast")
			var property_as_node := property_instance as Node if property_instance != null else null
			if property_as_node == null:
				continue
			if property_as_node == orphan_to_find:
				return GdUnitOrphanNodeInfo.new(
					GdUnitOrphanNodeInfo.GdUnitOrphanType.member,
					orphan_to_find.get_instance_id(),
					orphan_to_find.get_class(),
					property_name,
					script.resource_path)

			# Search on node childs
			var orphan_node_info := _find_orphan_at_node(orphan_to_find, property_as_node)
			if orphan_node_info:
				orphan_node_info._next = GdUnitOrphanNodeInfo.new(
					GdUnitOrphanNodeInfo.GdUnitOrphanType.member,
					orphan_to_find.get_instance_id(),
					orphan_to_find.get_class(),
					property_name,
					script.resource_path)
				return orphan_node_info

	# Second over all children
	for child_node in node.get_children():
		var orphan_node_info := _find_orphan_at_node(orphan_to_find, child_node)
		if orphan_node_info:
			return orphan_node_info
	return null


func _is_frame_file_excluded(frame_file: String) -> bool:
	for file in excluded_frame_files:
		if frame_file.contains(file):
			return true
	return false


func _find_orphan_on_backtraces(orphan_to_find: Object) -> GdUnitOrphanNodeInfo:
	for script_backtrace in Engine.capture_script_backtraces(true):
		for frame in script_backtrace.get_frame_count():
			var frame_file := script_backtrace.get_frame_file(frame)
			if _is_frame_file_excluded(frame_file):
				continue

			# Scan function variables
			for l_index in script_backtrace.get_local_variable_count(frame):
				var variable_instance: Variant = script_backtrace.get_local_variable_value(frame, l_index)
				var variable_name := script_backtrace.get_local_variable_name(frame, l_index)
				if typeof(variable_instance) in [TYPE_NIL, TYPE_OBJECT]:
					@warning_ignore("unsafe_cast")
					var node := variable_instance as Node
					if node == null:
						continue
					if variable_instance == orphan_to_find:
						return GdUnitOrphanNodeInfo.new(
							GdUnitOrphanNodeInfo.GdUnitOrphanType.variable,
							orphan_to_find.get_instance_id(),
							orphan_to_find.get_class(),
							variable_name,
							script_backtrace.get_frame_file(frame),
							script_backtrace.get_frame_function(frame))
					else:
						var orphan_node_info := _find_orphan_at_node(orphan_to_find, node)
						if orphan_node_info:
							return orphan_node_info

			# Scan class members
			for m_index in script_backtrace.get_member_variable_count(frame):
				var member_instance: Variant = script_backtrace.get_member_variable_value(frame, m_index)
				var member_name := script_backtrace.get_member_variable_name(frame, m_index)
				if typeof(member_instance) in [TYPE_NIL, TYPE_OBJECT]:
					@warning_ignore("unsafe_cast")
					var node := member_instance as Node
					if node == null:
						continue
					if member_instance == orphan_to_find:
						return GdUnitOrphanNodeInfo.new(
							GdUnitOrphanNodeInfo.GdUnitOrphanType.member,
							orphan_to_find.get_instance_id(),
							orphan_to_find.get_class(),
							member_name,
							script_backtrace.get_frame_file(frame))
					else:
						var orphan_node_info := _find_orphan_at_node(orphan_to_find, node)
						if orphan_node_info:
							return orphan_node_info
	return null


static func _get_orphan_node_ids() -> Array[int]:
	@warning_ignore("unsafe_property_access", "unsafe_method_access")
	return Engine.get_main_loop().root.get_orphan_node_ids()
