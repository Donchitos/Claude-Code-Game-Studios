class_name GdUnitOrphanNodesMonitor
extends GdUnitMonitor


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

	stop()
	if _orphan_ids_at_stop.is_empty():
		return

	var script_backtraces := Engine.capture_script_backtraces(true)
	for orphan_id in _orphan_ids_at_stop:
		var orphan_node := instance_from_id(orphan_id)
		_collect_orphan_info(orphan_node, script_backtraces)


func _collect_orphan_info(orphan_node: Object, script_backtraces: Array[ScriptBacktrace]) -> void:
	if orphan_node == null:
		return

	var orphan_info := _find_orphan_on_backtraces(orphan_node, script_backtraces)
	if orphan_info:
		_collected_orphan_infos.append(orphan_info)
		return

	if Engine.has_meta("GdUnitSceneRunner"):
		var current_scene_runner:GdUnitSceneRunner = Engine.get_meta("GdUnitSceneRunner")
		if is_instance_valid(current_scene_runner):
			orphan_info = _find_orphan_at_node(orphan_node, current_scene_runner.scene())
			if orphan_info:
				_collected_orphan_infos.append(orphan_info)
				return

	_collected_orphan_infos.append(
		GdUnitOrphanNodeInfo.new(
			orphan_node.get_instance_id(),
			orphan_node.get_class(),
			null)
		)


func _find_orphan_at_node(orphan_node: Object, node: Node) -> GdUnitOrphanNodeInfo:
	var script: Script = node.get_script()
	if script is not GDScript:
		return null

	# First search over all properties
	for property in script.get_script_property_list():
		# We lookup only over user script variables
		var property_usage: int = property["usage"]
		if property_usage != PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue

		var property_type: int = property["type"]
		# Is untyped or type object
		if property_type in [TYPE_NIL, TYPE_OBJECT]:
			var property_name: String = property["name"]
			var property_instance: Variant = node.get(property_name)
			@warning_ignore("unsafe_cast")
			var property_as_node := property_instance as Node
			if property_as_node == null:
				continue
			# If node match the curren property object
			if property_as_node == orphan_node:
				var property_class: String = property["class_name"]
				var source_line := _find_line_for_property(script, "", property_name)
				return GdUnitOrphanNodeInfo.new(
					orphan_node.get_instance_id(),
					property_class,
					GdUnitStackTraceElement.new(
						script.resource_path,
						source_line,
						property_name)
					)

			# Otherwise we need to search on child node script properties
			var orphan_info := _find_orphan_at_node(orphan_node, property_as_node)
			if orphan_info:
				return orphan_info

	# Second over all children
	for child_node in node.get_children():
		var orphan_info := _find_orphan_at_node(orphan_node, child_node)
		if orphan_info:
			return orphan_info
	return null


func _find_orphan_on_backtraces(orphan_node: Object, script_backtraces: Array[ScriptBacktrace]) -> GdUnitOrphanNodeInfo:
	for script_backtrace in script_backtraces:
		for frame in script_backtrace.get_frame_count():
			var frame_file := script_backtrace.get_frame_file(frame)
			if GdUnitStackTrace.filter_sources(frame_file):
				continue

			# Scan function variables
			for l_index in script_backtrace.get_local_variable_count(frame):
				var variable: Variant = script_backtrace.get_local_variable_value(frame, l_index)
				if typeof(variable) in [TYPE_NIL, TYPE_OBJECT]:
					@warning_ignore("unsafe_cast")
					var node := variable as Node
					if node == null:
						continue
					if variable == orphan_node:
						var variable_name := script_backtrace.get_local_variable_name(frame, l_index)
						var source_script := script_backtrace.get_frame_file(frame)
						var source_function := script_backtrace.get_frame_function(frame)
						var script: Script = load(source_script)
						var source_line := _find_line_for_property(script, source_function, variable_name)
						return GdUnitOrphanNodeInfo.new(
							orphan_node.get_instance_id(),
							orphan_node.get_class(),
							GdUnitStackTraceElement.new(source_script, source_line, variable_name)
							)
					else:
						var orphan_info := _find_orphan_at_node(orphan_node, node)
						if orphan_info:
							return orphan_info

			# Scan class members
			for m_index in script_backtrace.get_member_variable_count(frame):
				var member: Variant = script_backtrace.get_member_variable_value(frame, m_index)
				if typeof(member) in [TYPE_NIL, TYPE_OBJECT]:
					@warning_ignore("unsafe_cast")
					var node := member as Node
					if node == null:
						continue
					if member == orphan_node:
						var member_name := script_backtrace.get_member_variable_name(frame, m_index)
						return GdUnitOrphanNodeInfo.new(
							orphan_node.get_instance_id(),
							orphan_node.get_class(),
							GdUnitStackTraceElement.new(
								script_backtrace.get_frame_file(frame),
								script_backtrace.get_frame_line(frame),
								member_name))
					else:
						var orphan_info := _find_orphan_at_node(orphan_node, node)
						if orphan_info:
							return orphan_info
	return null


func _find_line_for_property(script: Script, func_name: String, property_name: String) -> int:
	if script == null or not script.has_source_code():
		return -1
	var lines := script.get_source_code().split("\n")
	var func_start_index := 0
	for index in range(0, lines.size()):
		var line :=  lines[index]
		if not func_name.is_empty():
			if line.begins_with("func") and line.contains(func_name):
				func_start_index = index + 1
				break;

	for index in range(func_start_index, lines.size()):
		var line := lines[index]
		if line.contains(property_name):
			return index + 1
		if line.begins_with("func"):
			break
	return -1


static func _get_orphan_node_ids() -> Array[int]:
	@warning_ignore("unsafe_property_access", "unsafe_method_access")
	var ids: Array[int] = Engine.get_main_loop().root.get_orphan_node_ids()
	# a node already queued for deletion is guaranteed to be freed, it is never a leak
	return ids.filter(func(node_id: int) -> bool:
		var node := instance_from_id(node_id) as Node
		return node == null or not node.is_queued_for_deletion()
	)
