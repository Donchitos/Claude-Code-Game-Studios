# VERTICAL SLICE - NOT FOR PRODUCTION
# F3 debug console (user request 2026-07-20): live view of what is happening
# and what it costs. Toggle with F3. Wall-clock refresh, reads system state
# via the public slice APIs — owns nothing, mutates nothing.
extends CanvasLayer

const REFRESH_SEC := 0.25
const LOG_LINES := 9

var _villager_ai: Node3D
var _building_system: Node3D
var _needs_mood: Node
var _build_validation: Node
var _voxel_world: Node3D
var _camera_input: Node3D

var _panel: PanelContainer
var _label: Label
var _accum := 0.0
var _event_log: Array[String] = []
var _boot_msec: int = 0


func setup(voxel_world: Node3D, camera_input: Node3D, building_system: Node3D,
		villager_ai: Node3D, needs_mood: Node, build_validation: Node) -> void:
	_voxel_world = voxel_world
	_camera_input = camera_input
	_building_system = building_system
	_villager_ai = villager_ai
	_needs_mood = needs_mood
	_build_validation = build_validation
	_boot_msec = Time.get_ticks_msec()
	layer = 90

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.09, 0.82)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	_panel.add_theme_stylebox_override("panel", style)
	_panel.position = Vector2(8, 8)
	_panel.visible = false
	add_child(_panel)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.85))
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_label.add_theme_font_override("font", mono)
	_panel.add_child(_label)

	# Event log taps — presentational listeners only.
	_building_system.construction_completed.connect(func(cells: Array) -> void:
		_log("built %d cell(s)" % cells.size()))
	_building_system.furniture_placed.connect(func(cell: Vector3i, id: String) -> void:
		_log("furniture '%s' placed at %s" % [id, cell]))
	_building_system.invalid_commit.connect(func(_pos: Vector3, reason: String) -> void:
		_log("invalid commit: %s" % reason))
	_building_system.cells_removed.connect(func(cells: Array) -> void:
		_log("removed %d cell(s)" % cells.size()))
	_build_validation.room_recognized.connect(func(cells: Array, _c: bool) -> void:
		_log("ROOM recognized (%d interior cells)" % cells.size()))
	_build_validation.sealed_space_warning.connect(func(_cells: Array, _ids: Array, why: String) -> void:
		_log("warning: %s" % why))
	_villager_ai.state_changed.connect(func(id: int, _s: int) -> void:
		var info: Dictionary = _villager_ai.get_info(id)
		_log("%s -> %s" % [info.get("name", id), info.get("state_label", "?")]))
	_villager_ai.distress_changed.connect(func(id: int, kind: String) -> void:
		var info: Dictionary = _villager_ai.get_info(id)
		_log("%s distress: %s" % [info.get("name", id), kind if kind != "" else "cleared"]))
	# ANTI-STUCK WATCHDOG (2026-07-23): log every teleport-rescue.
	if _villager_ai.has_signal("villager_unstuck"):
		_villager_ai.villager_unstuck.connect(func(id: int, from_cell: Vector3i, to_cell: Vector3i) -> void:
			var info: Dictionary = _villager_ai.get_info(id)
			_log("%s unstuck %s -> %s" % [info.get("name", id), from_cell, to_cell]))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_F3:
		_panel.visible = not _panel.visible


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_accum += delta
	if _accum < REFRESH_SEC:
		return
	_accum = 0.0
	_label.text = _compose()


func _log(msg: String) -> void:
	var t := (Time.get_ticks_msec() - _boot_msec) / 1000.0
	_event_log.append("[%7.1fs] %s" % [t, msg])
	if _event_log.size() > LOG_LINES:
		_event_log = _event_log.slice(_event_log.size() - LOG_LINES)


func _compose() -> String:
	var lines: Array[String] = []
	# --- performance ---
	var fps := Engine.get_frames_per_second()
	var frame_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var vram_mb: float = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0
	var draws: int = int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims: int = int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	var objs: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	lines.append("== PERF ==  %d fps   frame %.2f ms  (physics %.2f ms)" % [fps, frame_ms, phys_ms])
	lines.append("draws %d   tris %s   RAM %.0f MB   VRAM %.0f MB   nodes %d" % [
		draws, _fmt_k(prims / 3), mem_mb, vram_mb, objs])
	# --- time / world ---
	var paused: bool = TimeTickSystem.get_paused()
	var warp: int = TimeTickSystem.get_warp()
	var cam: Camera3D = _camera_input.get_camera()
	var eye: Vector3 = cam.global_position
	var chunks: int = _voxel_world._chunk_nodes.size()
	lines.append("== SIM ==   %s   warp %dx   chunks %d   cam (%.0f, %.0f, %.0f)" % [
		"PAUSED" if paused else "running", warp, chunks, eye.x, eye.y, eye.z])
	# ANTI-STUCK WATCHDOG (2026-07-23): total teleport-rescue count.
	if _villager_ai.has_method("get_unstuck_count"):
		lines.append("unstuck: %d total" % _villager_ai.get_unstuck_count())
	# --- building ---
	var bp: Dictionary = _building_system.get_blueprint_cells()
	var claimed := 0
	for cell in bp:
		if int(bp[cell].get("claimed_by", 0)) != 0:
			claimed += 1
	var furniture: Dictionary = _building_system.get_furniture_cells()
	lines.append("build: %d blueprint (%d claimed)   %d furniture   tool %d" % [
		bp.size(), claimed, furniture.size(), _building_system.get_active_tool()])
	# --- villagers ---
	for id in _villager_ai.get_villager_ids():
		var info: Dictionary = _villager_ai.get_info(id)
		var disp: Dictionary = _needs_mood.get_display(id)
		var distress: String = info.get("distress", "")
		var unstuck_n: int = int(info.get("unstuck_count", 0))
		lines.append("%-6s %-14s %s  sleep %3.0f  %s%s%s" % [
			str(info.get("name", id)) + ":", info.get("state_label", "?"),
			info.get("cell", Vector3i.ZERO), disp.get("sleep", 0.0),
			disp.get("band_label", "?"),
			("  [!" + distress + "]") if distress != "" else "",
			("  unstuck:%d" % unstuck_n) if unstuck_n > 0 else ""])
	# --- events ---
	lines.append("== LOG ==")
	if _event_log.is_empty():
		lines.append("  (no events yet)")
	else:
		for entry in _event_log:
			lines.append("  " + entry)
	return "\n".join(lines)


func _fmt_k(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.0fk" % (n / 1000.0)
	return str(n)
