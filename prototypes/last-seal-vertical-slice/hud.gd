# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# HUD per design/ux/hud.md: zones Z1-Z6 built programmatically (no .tscn),
# flat chrome #262220 / text #EDE6DA / gold #F5A83C highlight, instant swaps,
# raw-delta only (never TimeTickSystem.game_delta, never SceneTree.paused).
# Duck-typed Node deps (building_system/camera_input/villager_ai/needs_mood/
# build_validation) — no shared interface/class_name exists yet for those
# modules at this stage of the slice; matches CONTRACTS.md's shape.
#
# CONTRACT ADDITION: setup() takes a 5th param `camera_input` not present in
# CONTRACTS.md's `setup(building_system, villager_ai, needs_mood, build_validation)`
# signature. It is required to wire the Z4 villager-pick flow (camera_input
# .build_click + .get_world_ray()) that CONTRACTS.md itself specifies for the
# villager panel. Flagged for CONTRACTS.md update; see task summary.
extends CanvasLayer

const VillagerPanelScript := preload("res://villager_panel.gd")

const TOOL_NONE := 0
const TOOL_WALL := 1
const TOOL_FLOOR := 2
const TOOL_ROOF := 3
const TOOL_BLOCK := 4
const TOOL_FURNITURE := 5
const TOOL_ROOM := 6       # BUILD UX PACKAGE (2026-07-22), feature 3
const TOOL_ROOF_AUTO := 7  # BUILD UX PACKAGE (2026-07-22), feature 4
const TOOL_HOUSE := 8      # BUILD UX PACKAGE (2026-07-22), feature 5

const TOOL_BUTTONS: Array[Dictionary] = [
	{"id": 1, "label": "Wall"},
	{"id": 2, "label": "Floor"},
	{"id": 3, "label": "Roof"},
	{"id": 4, "label": "Block"},
	{"id": 5, "label": "Bed"},
	{"id": 6, "label": "Raum"},
	{"id": 7, "label": "Dach"},
	{"id": 8, "label": "Haus"},
]

const ROOF_FORMATIONS := ["Flat", "Gable", "Hip", "Shed"]  # only Flat is functional this slice

const COLOR_CHROME := Color(0.149, 0.133, 0.125)     # #262220
const COLOR_TEXT := Color(0.929, 0.902, 0.855)       # #EDE6DA
const COLOR_GOLD := Color(0.961, 0.659, 0.235)       # #F5A83C
const COLOR_STATE_ORANGE := Color(0.86, 0.47, 0.20)  # [assumption] pending art-bible theme verification (hud.md A3 OPEN)
const COLOR_STATE_BLUE := Color(0.35, 0.58, 0.82)    # [assumption] pending art-bible theme verification (hud.md A3 OPEN)

const EDGE_MARGIN := 16.0
const ZONE_GAP := 8.0
const TOOLBAR_HEIGHT_ESTIMATE := 56.0
const CONTEXT_PANEL_HEIGHT := 120.0
# Bumped 48->84 (2026-07-22, BUILD UX PACKAGE feature 2): the slice-view row
# (Ebene label + 2 buttons) adds a 3rd row to the Z1 time-controls panel; the
# toast/anchor zones below derive their offsets from this constant.
const TIME_CONTROLS_HEIGHT_ESTIMATE := 84.0
const TOAST_HEIGHT_ESTIMATE := 40.0
# ZONE_HALF_WIDTH widened 240->400 (2026-07-22, BUILD UX PACKAGE) -- toolbar
# grew from 5 to 8 tool buttons + the "Bauen" toggle + undo/redo; the old
# envelope overflowed. Toolbar/context shared width envelope (hud.md E4 rule).
const ZONE_HALF_WIDTH := 400.0
const RIGHT_ZONE_WIDTH := 260.0    # time/toast/anchor column width

const TOAST_MAX_VISIBLE := 3
const TOAST_DISMISS_SECONDS := 30.0
const TOAST_STALE_SECONDS := 3.0   # auto-retire a key not re-emitted within this window


signal tool_button_pressed(tool_id: int)
signal material_selected(item_id: String)
signal formation_selected(formation_name: String)
signal wall_height_set(height: int)
signal undo_pressed()
signal redo_pressed()


var _building_system: Node
var _camera_input: Node
var _villager_ai: Node
var _needs_mood: Node
var _build_validation: Node
# CONTRACT ADDITION (2026-07-22, BUILD UX PACKAGE feature 2): setup() takes a
# 6th param `voxel_world`, needed for the "Ebene: N" slice indicator + the two
# slice buttons (get_slice_level()/set_slice_level()). Same pattern as the
# camera_input addition already flagged above. Flagged for CONTRACTS.md update.
var _voxel_world: Node

var _villager_panel: Control

var _current_tool: int = TOOL_NONE
var _current_material: String = ""
var _current_wall_height: int = 3
var _current_formation: String = "Flat"

var _tool_buttons: Dictionary = {}       # tool_id:int -> Button
var _undo_button: Button
var _redo_button: Button
var _build_mode_button: Button           # FEATURE 1: master "Bauen" toggle
var _build_mode_active: bool = false

var _context_panel: PanelContainer
var _context_content: VBoxContainer

# --- Build projects (2026-07-22, replaces the single "Bau starten (N)" button) ---
const PROJECT_STATE_DRAFT := 0
const PROJECT_STATE_BUILDING := 1
const PROJECT_STATE_PAUSED := 2
const PROJECT_STATE_DONE := 3
const PROJECT_STATE_LABELS_DE := {
	0: "Entwurf",
	1: "Im Bau",
	2: "Pausiert",
	3: "Fertig",
}
const PROJECTS_PANEL_WIDTH := 260.0
const PROJECTS_PANEL_MAX_HEIGHT := 320.0
const PROJECTS_REFRESH_INTERVAL := 0.5  # light periodic refresh for progress/workers

var _projects_panel: PanelContainer
var _projects_list: VBoxContainer
var _projects_scroll: ScrollContainer
var _project_row_refs: Dictionary = {}   # project_id:int -> {progress, count_label, workers_label, state, row}
var _projects_refresh_accum: float = 0.0
# CLICK SELECTION (2026-07-23, task 2b/2c): id:int of the selected project, or
# null. Drives the gold-bordered card highlight + scroll-into-view.
var _selected_project_id: Variant = null

var _pause_button: Button
var _speed_buttons: Dictionary = {}      # warp:int -> Button
var _sim_stats_label: Label
var _pause_dim: ColorRect

# --- SLICE VIEW (2026-07-22, BUILD UX PACKAGE feature 2) ---
var _slice_label: Label
var _slice_minus_btn: Button
var _slice_plus_btn: Button
var _last_slice_level_shown: int = -999999  # forces a first refresh

var _toast_container: VBoxContainer
var _toasts: Dictionary = {}             # key:String -> {severity,text,first_seen,last_seen,dismissed_until}
var _toast_visible_keys: Array = []

var _anchor_zone: PanelContainer
var _anchor_button: Button
var _anchor_expanded_panel: PanelContainer
var _anchor_expanded_list: VBoxContainer
var _anchor_expanded: bool = false
var _anchor_entries_cache: Array = []

var _hover_flags: Dictionary = {}        # zone name:String -> bool

var _distress_icons: Dictionary = {}     # villager_id:int -> Node3D


func _ready() -> void:
	_build_toolbar()
	_build_context_panel()
	_build_time_controls()
	_build_toast_zone()
	_build_anchor()
	_build_villager_panel()
	_build_projects_panel()


func _process(delta: float) -> void:
	_reconcile_toasts()
	_update_distress_icons()
	_update_sim_stats()
	_refresh_slice_indicator()
	_projects_refresh_accum += delta
	if _projects_refresh_accum >= PROJECTS_REFRESH_INTERVAL:
		_projects_refresh_accum = 0.0
		_refresh_projects_progress()


func _update_sim_stats() -> void:
	if _sim_stats_label == null or _building_system == null:
		return
	var sim_seconds: int = TimeTickSystem.total_ticks / int(TimeTickSystem.TICKS_PER_SECOND)
	var bp: Dictionary = _building_system.get_blueprint_cells()
	var beds: int = _building_system.get_furniture_cells().size()
	_sim_stats_label.text = "Sim %02d:%02d  ·  %d Villager  ·  %d Betten  ·  %d Auftraege" % [
		sim_seconds / 60, sim_seconds % 60,
		_villager_ai.get_villager_ids().size() if _villager_ai else 0,
		beds, bp.size()]


func _unhandled_input(event: InputEvent) -> void:
	if _building_system == null:
		return
	if event.is_action_pressed("build_cancel"):
		# P11 two-step: release HUD focus first, only then fall through to world (deselect).
		if _anchor_expanded:
			_anchor_expanded = false
			_anchor_expanded_panel.visible = false
			get_viewport().set_input_as_handled()
			return
		if _building_system.get_active_tool() == TOOL_NONE:
			_villager_panel.deselect()


## Wires injected systems. Called once by GameWorld after HUD enters the tree.
func setup(building_system: Node, camera_input: Node, villager_ai: Node, needs_mood: Node, build_validation: Node, voxel_world: Node = null) -> void:
	_building_system = building_system
	_camera_input = camera_input
	_villager_ai = villager_ai
	_needs_mood = needs_mood
	_build_validation = build_validation
	_voxel_world = voxel_world

	_current_tool = building_system.get_active_tool()
	_refresh_toolbar_highlight()
	_refresh_context_panel()

	# FEATURE 1: sync the master build-mode toggle to whatever state the
	# building system already booted with.
	_build_mode_active = building_system.get_build_mode()
	_apply_active_button_style(_build_mode_button, _build_mode_active)
	_refresh_projects_panel()

	building_system.tool_changed.connect(_on_tool_changed)
	building_system.palette_changed.connect(_on_palette_changed)
	building_system.wall_height_changed.connect(_on_wall_height_changed)
	building_system.formation_changed.connect(_on_formation_changed)
	building_system.undo_state_changed.connect(_on_undo_state_changed)
	building_system.build_mode_changed.connect(_on_build_mode_changed)
	building_system.projects_changed.connect(_on_projects_changed)
	building_system.project_selected.connect(_on_project_selected)

	build_validation.sealed_space_warning.connect(_on_sealed_space_warning)
	build_validation.unsheltered_furniture_info.connect(_on_unsheltered_furniture_info)

	camera_input.build_click.connect(_on_build_click)

	_villager_panel.setup(villager_ai, needs_mood)


## OR of mouse-over across every HUD Control zone (P2 shared hover-suppression gate).
func is_hover_suppressing() -> bool:
	for hovering in _hover_flags.values():
		if hovering:
			return true
	return false


## Keyed refresh-in-place toast (P1). severity 0 = info, 1 = warning.
func show_toast(key: String, severity: int, text: String) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if _toasts.has(key):
		var data: Dictionary = _toasts[key]
		data["severity"] = severity
		data["text"] = text
		data["last_seen"] = now
	else:
		_toasts[key] = {
			"severity": severity,
			"text": text,
			"first_seen": now,
			"last_seen": now,
			"dismissed_until": 0.0,
		}
	_refresh_toast_display()


## Removes a toast key entirely (no debounce), e.g. for external explicit clears.
func retire_toast(key: String) -> void:
	if not _toasts.has(key):
		return
	_toasts.erase(key)
	_refresh_toast_display()


# ---------------------------------------------------------------------------
# Z6 - Toolbar
# ---------------------------------------------------------------------------

func _build_toolbar() -> void:
	var panel := PanelContainer.new()
	panel.name = "Z6_Toolbar"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -ZONE_HALF_WIDTH
	panel.offset_right = ZONE_HALF_WIDTH
	panel.offset_top = -(EDGE_MARGIN + TOOLBAR_HEIGHT_ESTIMATE)
	panel.offset_bottom = -EDGE_MARGIN
	panel.mouse_entered.connect(_set_hover.bind("toolbar", true))
	panel.mouse_exited.connect(_set_hover.bind("toolbar", false))
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	# FEATURE 1: master build/editor mode toggle, LEFT end of the toolbar.
	_build_mode_button = Button.new()
	_build_mode_button.text = "Bauen"
	_build_mode_button.tooltip_text = "Baumodus an/aus (Esc)"
	_build_mode_button.custom_minimum_size = Vector2(64.0, 40.0)
	_apply_flat_button_style(_build_mode_button)
	_build_mode_button.pressed.connect(_on_build_mode_button_pressed)
	row.add_child(_build_mode_button)

	row.add_child(VSeparator.new())

	for entry: Dictionary in TOOL_BUTTONS:
		var tool_id: int = entry["id"]
		var btn := Button.new()
		btn.text = String(entry["label"])
		if tool_id == TOOL_BLOCK:
			# FEATURE 1/2 (2026-07-22): the Block tool + Ctrl is also the
			# draft-eraser and terrain-dig tool -- call that out explicitly.
			btn.tooltip_text = "Key %d — Strg+Klick: Abbau: Blöcke/Entwürfe entfernen, Terrain abbauen" % tool_id
		else:
			btn.tooltip_text = "Key %d" % tool_id
		btn.custom_minimum_size = Vector2(64.0, 40.0)
		_apply_flat_button_style(btn)
		btn.pressed.connect(_on_tool_button_pressed.bind(tool_id))
		row.add_child(btn)
		_tool_buttons[tool_id] = btn

	row.add_child(VSeparator.new())

	_undo_button = Button.new()
	_undo_button.text = "Undo"
	_undo_button.tooltip_text = "Ctrl+Z"
	_undo_button.disabled = true
	_undo_button.custom_minimum_size = Vector2(56.0, 40.0)
	_apply_flat_button_style(_undo_button)
	_undo_button.pressed.connect(_on_undo_pressed)
	row.add_child(_undo_button)

	_redo_button = Button.new()
	_redo_button.text = "Redo"
	_redo_button.tooltip_text = "Ctrl+Y"
	_redo_button.disabled = true
	_redo_button.custom_minimum_size = Vector2(56.0, 40.0)
	_apply_flat_button_style(_redo_button)
	_redo_button.pressed.connect(_on_redo_pressed)
	row.add_child(_redo_button)


func _refresh_toolbar_highlight() -> void:
	for tool_id in _tool_buttons.keys():
		_apply_active_button_style(_tool_buttons[tool_id], tool_id == _current_tool)


func _on_tool_button_pressed(tool_id: int) -> void:
	tool_button_pressed.emit(tool_id)


func _on_undo_pressed() -> void:
	undo_pressed.emit()


func _on_redo_pressed() -> void:
	redo_pressed.emit()


func _on_tool_changed(tool_id: int) -> void:
	_current_tool = tool_id
	_refresh_toolbar_highlight()
	_refresh_context_panel()
	if tool_id != TOOL_NONE:
		# Arming a tool clears the villager selection (TR-villager-info-ui-043).
		_villager_panel.deselect()


func _on_undo_state_changed(can_undo: bool, can_redo: bool) -> void:
	_undo_button.disabled = not can_undo
	_redo_button.disabled = not can_redo


func _on_build_mode_button_pressed() -> void:
	_building_system.set_build_mode(not _build_mode_active)


func _on_build_mode_changed(active: bool) -> void:
	_build_mode_active = active
	_apply_active_button_style(_build_mode_button, active)


func _on_projects_changed() -> void:
	_refresh_projects_panel()


# ---------------------------------------------------------------------------
# Z7 - Build projects panel (2026-07-22: Stonehearth-style build projects,
# replaces the single global "Bau starten (N)" button)
# ---------------------------------------------------------------------------

func _build_projects_panel() -> void:
	_projects_panel = PanelContainer.new()
	_projects_panel.name = "Z7_Projects"
	_projects_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_projects_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_projects_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_projects_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_projects_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_projects_panel.offset_left = EDGE_MARGIN
	_projects_panel.offset_right = EDGE_MARGIN + PROJECTS_PANEL_WIDTH
	_projects_panel.offset_bottom = -EDGE_MARGIN
	_projects_panel.offset_top = _projects_panel.offset_bottom - PROJECTS_PANEL_MAX_HEIGHT
	_projects_panel.visible = false
	_projects_panel.mouse_entered.connect(_set_hover.bind("projects", true))
	_projects_panel.mouse_exited.connect(_set_hover.bind("projects", false))
	add_child(_projects_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	_projects_panel.add_child(outer)

	var title := Label.new()
	title.text = "Projekte"
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 16)
	outer.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PROJECTS_PANEL_WIDTH - 16.0, PROJECTS_PANEL_MAX_HEIGHT - 48.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	_projects_list = VBoxContainer.new()
	_projects_list.add_theme_constant_override("separation", 8)
	_projects_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_projects_list)
	_projects_scroll = scroll


## Full structural rebuild: called on projects_changed (creation, merge, state
## transitions, cancellation) and once from setup(). Cheap at this scale (a
## handful of projects at most in this slice).
func _refresh_projects_panel() -> void:
	if _building_system == null or _projects_list == null:
		return
	for child in _projects_list.get_children():
		child.queue_free()
	_project_row_refs.clear()

	var projects: Array = _building_system.get_projects()
	_projects_panel.visible = not projects.is_empty()
	for p: Dictionary in projects:
		_projects_list.add_child(_make_project_row(p))


## Light periodic refresh (progress bar / cell count / worker names) that does
## NOT rebuild buttons -- avoids flicker while a project is actively building.
func _refresh_projects_progress() -> void:
	if _building_system == null or _project_row_refs.is_empty():
		return
	var by_id: Dictionary = {}
	for p: Dictionary in _building_system.get_projects():
		by_id[int(p["id"])] = p
	for id in _project_row_refs.keys():
		if not by_id.has(id):
			continue  # structural change pending -- projects_changed will rebuild
		var p: Dictionary = by_id[id]
		var refs: Dictionary = _project_row_refs[id]
		var progress: ProgressBar = refs["progress"]
		var count_label: Label = refs["count_label"]
		var workers_label: Label = refs["workers_label"]
		progress.max_value = maxf(1.0, float(p["total_cells"]))
		progress.value = float(p["built_cells"])
		count_label.text = "%d/%d" % [int(p["built_cells"]), int(p["total_cells"])]
		if int(refs["state"]) == PROJECT_STATE_BUILDING:
			workers_label.text = _worker_names_text(p["worker_ids"])
		# NOTE: draft_cells/demolishing/state-label changes aren't picked up by
		# this light refresh (button layout depends on them) -- those need the
		# full _refresh_projects_panel() rebuild via projects_changed, same as
		# any other structural change.


func _project_state_label(state: int) -> String:
	return String(PROJECT_STATE_LABELS_DE.get(state, "?"))


func _worker_names_text(worker_ids: Array) -> String:
	if _villager_ai == null or worker_ids.is_empty():
		return "Niemand zugewiesen"
	var names: Array = []
	for wid in worker_ids:
		var info: Dictionary = _villager_ai.get_info(int(wid))
		names.append(String(info.get("name", "?")))
	return ", ".join(names)


func _make_project_row(p: Dictionary) -> PanelContainer:
	var id: int = int(p["id"])
	var state: int = int(p["state"])
	# CHANGE ORDERS (2026-07-23, task 3a): pending draft entries can exist on
	# ANY state now (attach rule, see building_system._assign_project).
	var draft_cells: int = int(p.get("draft_cells", 0))
	var demolishing: bool = bool(p.get("demolishing", false))

	var row := PanelContainer.new()

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	col.add_child(header)

	var name_label := Label.new()
	name_label.text = String(p["name"])
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var status_label := Label.new()
	if demolishing:
		status_label.text = "Wird abgerissen"
	elif state == PROJECT_STATE_DONE and draft_cells > 0:
		status_label.text = "Aenderungen geplant"
	else:
		status_label.text = _project_state_label(state)
	status_label.add_theme_color_override("font_color", COLOR_GOLD if (state == PROJECT_STATE_BUILDING or draft_cells > 0) else COLOR_TEXT)
	status_label.add_theme_font_size_override("font_size", 13)
	header.add_child(status_label)

	var progress := ProgressBar.new()
	progress.min_value = 0.0
	progress.max_value = maxf(1.0, float(p["total_cells"]))
	progress.value = float(p["built_cells"])
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0.0, 12.0)
	col.add_child(progress)

	var count_label := Label.new()
	count_label.text = "%d/%d" % [int(p["built_cells"]), int(p["total_cells"])]
	count_label.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72))
	count_label.add_theme_font_size_override("font_size", 13)
	col.add_child(count_label)

	var workers_label := Label.new()
	workers_label.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72))
	workers_label.add_theme_font_size_override("font_size", 13)
	workers_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	workers_label.visible = state == PROJECT_STATE_BUILDING
	if state == PROJECT_STATE_BUILDING:
		workers_label.text = _worker_names_text(p["worker_ids"])
	col.add_child(workers_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	col.add_child(button_row)

	if demolishing:
		# 3c: torn down entirely through jobs already in motion -- nothing to
		# click here; the row disappears on its own once every cell is gone.
		pass
	else:
		match state:
			PROJECT_STATE_DRAFT:
				var start_btn := Button.new()
				start_btn.text = "Bau starten"
				_apply_flat_button_style(start_btn)
				start_btn.pressed.connect(_on_project_release_pressed.bind(id))
				button_row.add_child(start_btn)
				var discard_btn := Button.new()
				discard_btn.text = "Verwerfen"
				_apply_flat_button_style(discard_btn)
				discard_btn.pressed.connect(_on_project_cancel_pressed.bind(id))
				button_row.add_child(discard_btn)
			PROJECT_STATE_BUILDING:
				var pause_btn := Button.new()
				pause_btn.text = "Pause"
				_apply_flat_button_style(pause_btn)
				pause_btn.pressed.connect(_on_project_pause_pressed.bind(id))
				button_row.add_child(pause_btn)
				var cancel_btn := Button.new()
				cancel_btn.text = "Abbrechen"
				_apply_flat_button_style(cancel_btn)
				cancel_btn.pressed.connect(_on_project_cancel_pressed.bind(id))
				button_row.add_child(cancel_btn)
				_maybe_add_release_drafts_button(button_row, id, draft_cells)
			PROJECT_STATE_PAUSED:
				var resume_btn := Button.new()
				resume_btn.text = "Fortsetzen"
				_apply_flat_button_style(resume_btn)
				resume_btn.pressed.connect(_on_project_resume_pressed.bind(id))
				button_row.add_child(resume_btn)
				var cancel_btn2 := Button.new()
				cancel_btn2.text = "Abbrechen"
				_apply_flat_button_style(cancel_btn2)
				cancel_btn2.pressed.connect(_on_project_cancel_pressed.bind(id))
				button_row.add_child(cancel_btn2)
				_maybe_add_release_drafts_button(button_row, id, draft_cells)
			PROJECT_STATE_DONE:
				if draft_cells == 0:
					var done_label := Label.new()
					done_label.text = "Fertig"
					done_label.add_theme_color_override("font_color", COLOR_GOLD)
					button_row.add_child(done_label)
				else:
					# CHANGE ORDERS (task 3a): "Bau starten" releases just the
					# pending change-order drafts -- the project returns to
					# BUILDING until they complete, then DONE again.
					_maybe_add_release_drafts_button(button_row, id, draft_cells)
				var demolish_btn := Button.new()
				demolish_btn.text = "Abriss"
				_apply_flat_button_style(demolish_btn)
				demolish_btn.pressed.connect(_on_project_cancel_pressed.bind(id))
				button_row.add_child(demolish_btn)

	_project_row_refs[id] = {"progress": progress, "count_label": count_label, "workers_label": workers_label, "state": state, "row": row}
	_apply_project_row_style(row, id == _selected_project_id)
	return row


## CHANGE ORDERS (2026-07-23, task 3a): shared "Bau starten" button for a
## project that already has SOME built/claimed work but also has pending
## draft entries attached via the change-order attach rule. Reuses the exact
## same release_project() call the DRAFT-state button uses -- it releases
## only the still-draft entries, leaving already-built/claimed cells alone.
func _maybe_add_release_drafts_button(button_row: HBoxContainer, id: int, draft_cells: int) -> void:
	if draft_cells <= 0:
		return
	var btn := Button.new()
	btn.text = "Bau starten"
	btn.tooltip_text = "%d geplante Aenderung(en) freigeben" % draft_cells
	_apply_flat_button_style(btn)
	btn.pressed.connect(_on_project_release_pressed.bind(id))
	button_row.add_child(btn)


## CLICK SELECTION (2026-07-23, task 2b): gold border on the selected
## project's card, matching the active-tool-button treatment; plain chrome
## otherwise.
func _apply_project_row_style(row: PanelContainer, selected: bool) -> void:
	if not selected:
		row.add_theme_stylebox_override("panel", _make_panel_style(COLOR_CHROME.lightened(0.06)))
		return
	var sb: StyleBoxFlat = _make_panel_style(COLOR_CHROME.lightened(0.06))
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = COLOR_GOLD
	row.add_theme_stylebox_override("panel", sb)


## CLICK SELECTION (2026-07-23, task 2b/2c): restyles every visible row and
## scrolls the selected one into view.
func _on_project_selected(id: Variant) -> void:
	_selected_project_id = id
	for pid in _project_row_refs.keys():
		var refs: Dictionary = _project_row_refs[pid]
		_apply_project_row_style(refs["row"], pid == id)
	if id != null and _project_row_refs.has(int(id)) and _projects_scroll != null:
		_projects_scroll.ensure_control_visible(_project_row_refs[int(id)]["row"])


func _on_project_release_pressed(id: int) -> void:
	_building_system.release_project(id)


func _on_project_pause_pressed(id: int) -> void:
	_building_system.pause_project(id)


func _on_project_resume_pressed(id: int) -> void:
	_building_system.resume_project(id)


func _on_project_cancel_pressed(id: int) -> void:
	_building_system.cancel_project(id)


# ---------------------------------------------------------------------------
# Z5 - Context panel (material palette / height stepper / formation picker / furniture)
# ---------------------------------------------------------------------------

func _build_context_panel() -> void:
	_context_panel = PanelContainer.new()
	_context_panel.name = "Z5_Context"
	_context_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_context_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_context_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_context_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_context_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_context_panel.offset_left = -ZONE_HALF_WIDTH
	_context_panel.offset_right = ZONE_HALF_WIDTH
	_context_panel.offset_bottom = -(EDGE_MARGIN + TOOLBAR_HEIGHT_ESTIMATE + ZONE_GAP)
	_context_panel.offset_top = _context_panel.offset_bottom - CONTEXT_PANEL_HEIGHT
	_context_panel.visible = false
	_context_panel.mouse_entered.connect(_set_hover.bind("context", true))
	_context_panel.mouse_exited.connect(_set_hover.bind("context", false))
	add_child(_context_panel)

	_context_content = VBoxContainer.new()
	_context_content.add_theme_constant_override("separation", 6)
	_context_panel.add_child(_context_content)


func _refresh_context_panel() -> void:
	for child in _context_content.get_children():
		child.queue_free()

	# TOOL_ROOF_AUTO/TOOL_HOUSE need no material/height context -- click-only
	# tools (Dach reuses whatever's already built; Haus is a fixed stamp).
	if _current_tool == TOOL_NONE or _current_tool == TOOL_ROOF_AUTO or _current_tool == TOOL_HOUSE:
		_context_panel.visible = false
		return

	_context_panel.visible = true

	match _current_tool:
		TOOL_WALL, TOOL_FLOOR, TOOL_ROOF, TOOL_BLOCK, TOOL_ROOM:
			_build_material_palette(ResourceItemDatabase.list_by_category("building_material"))
			if _current_tool == TOOL_WALL or _current_tool == TOOL_ROOM:
				_build_height_stepper()
			if _current_tool == TOOL_ROOF:
				_build_formation_picker()
		TOOL_FURNITURE:
			_build_material_palette(ResourceItemDatabase.list_by_category("furniture_fixture"))
		_:
			pass


func _build_material_palette(items: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_context_content.add_child(row)

	if items.is_empty():
		# Explicit empty state, never a broken panel (TR-resource-item-database-044).
		var empty_label := Label.new()
		empty_label.text = "No items available"
		empty_label.add_theme_color_override("font_color", COLOR_TEXT)
		empty_label.add_theme_font_size_override("font_size", 16)
		row.add_child(empty_label)
		return

	for item in items:
		var item_id: String = item.id
		var item_box := HBoxContainer.new()
		item_box.add_theme_constant_override("separation", 4)

		var swatch := ColorRect.new()
		swatch.color = item.color
		swatch.custom_minimum_size = Vector2(16.0, 16.0)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_box.add_child(swatch)

		var btn := Button.new()
		btn.text = String(item.display_name)
		btn.tooltip_text = String(item.display_name)
		btn.custom_minimum_size = Vector2(72.0, 32.0)
		_apply_flat_button_style(btn)
		_apply_active_button_style(btn, item_id == _current_material)
		btn.pressed.connect(_on_material_button_pressed.bind(item_id))
		item_box.add_child(btn)

		row.add_child(item_box)


func _on_material_button_pressed(item_id: String) -> void:
	material_selected.emit(item_id)


func _on_palette_changed(item_id: String) -> void:
	_current_material = item_id
	_refresh_context_panel()


func _build_height_stepper() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_context_content.add_child(row)

	var minus_btn := Button.new()
	minus_btn.text = "-"
	minus_btn.tooltip_text = "F"
	minus_btn.custom_minimum_size = Vector2(32.0, 32.0)
	_apply_flat_button_style(minus_btn)
	minus_btn.pressed.connect(_on_height_step.bind(-1))
	row.add_child(minus_btn)

	var value_label := Label.new()
	value_label.text = str(_current_wall_height)
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	value_label.custom_minimum_size = Vector2(32.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(value_label)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.tooltip_text = "R"
	plus_btn.custom_minimum_size = Vector2(32.0, 32.0)
	_apply_flat_button_style(plus_btn)
	plus_btn.pressed.connect(_on_height_step.bind(1))
	row.add_child(plus_btn)


func _on_height_step(delta: int) -> void:
	var new_height: int = clampi(_current_wall_height + delta, 1, 8)
	wall_height_set.emit(new_height)


func _on_wall_height_changed(h: int) -> void:
	_current_wall_height = h
	_refresh_context_panel()


func _build_formation_picker() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_context_content.add_child(row)

	for formation_name: String in ROOF_FORMATIONS:
		var functional: bool = formation_name == "Flat"
		var btn := Button.new()
		btn.text = formation_name
		btn.custom_minimum_size = Vector2(64.0, 32.0)
		btn.disabled = not functional
		_apply_flat_button_style(btn)
		if functional:
			_apply_active_button_style(btn, formation_name == _current_formation)
			btn.pressed.connect(_on_formation_button_pressed.bind(formation_name))
		else:
			btn.tooltip_text = "Not implemented in this slice"
		row.add_child(btn)


func _on_formation_button_pressed(formation_name: String) -> void:
	formation_selected.emit(formation_name)


func _on_formation_changed(formation_name: String) -> void:
	_current_formation = formation_name
	_refresh_context_panel()


# ---------------------------------------------------------------------------
# Z1 - Time controls (pause + speed) + pause dim
# ---------------------------------------------------------------------------

func _build_time_controls() -> void:
	var panel := PanelContainer.new()
	panel.name = "Z1_TimeControls"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.offset_left = -(EDGE_MARGIN + RIGHT_ZONE_WIDTH)
	panel.offset_right = -EDGE_MARGIN
	panel.offset_top = EDGE_MARGIN
	panel.offset_bottom = EDGE_MARGIN + TIME_CONTROLS_HEIGHT_ESTIMATE
	panel.mouse_entered.connect(_set_hover.bind("time", true))
	panel.mouse_exited.connect(_set_hover.bind("time", false))
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)

	_sim_stats_label = Label.new()
	_sim_stats_label.add_theme_font_size_override("font_size", 13)
	_sim_stats_label.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72))
	_sim_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_sim_stats_label)

	_pause_button = Button.new()
	_pause_button.custom_minimum_size = Vector2(36.0, 32.0)
	_apply_flat_button_style(_pause_button)
	_pause_button.pressed.connect(_on_pause_button_pressed)
	row.add_child(_pause_button)

	row.add_child(VSeparator.new())

	for warp: int in TimeTickSystem.WARPS:
		var btn := Button.new()
		btn.text = "%dx" % warp
		btn.custom_minimum_size = Vector2(36.0, 32.0)
		_apply_flat_button_style(btn)
		btn.pressed.connect(_on_speed_button_pressed.bind(warp))
		row.add_child(btn)
		_speed_buttons[warp] = btn

	var slice_row := HBoxContainer.new()
	slice_row.add_theme_constant_override("separation", 6)
	column.add_child(slice_row)

	_slice_minus_btn = Button.new()
	_slice_minus_btn.text = "▼"
	_slice_minus_btn.tooltip_text = "Ebene tiefer (PageDown)"
	_slice_minus_btn.custom_minimum_size = Vector2(32.0, 28.0)
	_apply_flat_button_style(_slice_minus_btn)
	_slice_minus_btn.pressed.connect(_on_slice_button_pressed.bind(-1))
	slice_row.add_child(_slice_minus_btn)

	_slice_label = Label.new()
	_slice_label.add_theme_font_size_override("font_size", 13)
	_slice_label.add_theme_color_override("font_color", COLOR_TEXT)
	_slice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slice_label.custom_minimum_size = Vector2(64.0, 0.0)
	_slice_label.visible = false
	slice_row.add_child(_slice_label)

	_slice_plus_btn = Button.new()
	_slice_plus_btn.text = "▲"
	_slice_plus_btn.tooltip_text = "Ebene hoeher (PageUp)"
	_slice_plus_btn.custom_minimum_size = Vector2(32.0, 28.0)
	_apply_flat_button_style(_slice_plus_btn)
	_slice_plus_btn.pressed.connect(_on_slice_button_pressed.bind(1))
	slice_row.add_child(_slice_plus_btn)

	_pause_dim = ColorRect.new()
	_pause_dim.name = "PauseDim"
	_pause_dim.color = Color(0.0, 0.0, 0.0, 0.15)
	_pause_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_dim.visible = false
	add_child(_pause_dim)
	move_child(_pause_dim, 0)  # behind all other HUD chrome, in front of the 3D world

	TimeTickSystem.time_state_changed.connect(_on_time_state_changed)
	_refresh_time_controls(TimeTickSystem.get_paused(), TimeTickSystem.get_warp())


func _on_pause_button_pressed() -> void:
	TimeTickSystem.set_paused(not TimeTickSystem.get_paused())


func _on_speed_button_pressed(warp: int) -> void:
	TimeTickSystem.set_warp(warp)


## SLICE VIEW (2026-07-22): the two HUD buttons call voxel_world.set_slice_level()
## directly (same single source of truth PageUp/PageDown use via GameWorld) --
## VillagerAI stays in sync via voxel_world's own slice_level_changed signal,
## no extra plumbing needed here.
func _on_slice_button_pressed(delta: int) -> void:
	if _voxel_world == null:
		return
	_voxel_world.set_slice_level(_voxel_world.get_slice_level() + delta)


func _refresh_slice_indicator() -> void:
	if _voxel_world == null or _slice_label == null:
		return
	var level: int = _voxel_world.get_slice_level()
	if level == _last_slice_level_shown:
		return
	_last_slice_level_shown = level
	var active: bool = _voxel_world.is_slice_active()
	_slice_label.visible = active
	if active:
		_slice_label.text = "Ebene: %d" % level


func _on_time_state_changed(paused: bool, warp: int) -> void:
	_refresh_time_controls(paused, warp)


func _refresh_time_controls(paused: bool, warp: int) -> void:
	_pause_button.text = "▶" if paused else "⏸"
	_pause_button.tooltip_text = "Resume (Space)" if paused else "Pause (Space)"
	_pause_dim.visible = paused
	for w in _speed_buttons.keys():
		_apply_active_button_style(_speed_buttons[w], w == warp)


# ---------------------------------------------------------------------------
# Z2 / Z3 - Toast stack + issues anchor
# ---------------------------------------------------------------------------

func _build_toast_zone() -> void:
	var panel := PanelContainer.new()
	panel.name = "Z2_Toasts"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.offset_left = -(EDGE_MARGIN + RIGHT_ZONE_WIDTH)
	panel.offset_right = -EDGE_MARGIN
	panel.offset_top = EDGE_MARGIN + TIME_CONTROLS_HEIGHT_ESTIMATE + ZONE_GAP
	panel.offset_bottom = panel.offset_top + TOAST_MAX_VISIBLE * (TOAST_HEIGHT_ESTIMATE + ZONE_GAP)
	panel.mouse_entered.connect(_set_hover.bind("toast", true))
	panel.mouse_exited.connect(_set_hover.bind("toast", false))
	add_child(panel)

	_toast_container = VBoxContainer.new()
	_toast_container.add_theme_constant_override("separation", 6)
	panel.add_child(_toast_container)


func _refresh_toast_display() -> void:
	for child in _toast_container.get_children():
		child.queue_free()

	var now: float = Time.get_ticks_msec() / 1000.0
	var eligible: Array = []
	for key in _toasts.keys():
		var data: Dictionary = _toasts[key]
		if float(data["dismissed_until"]) <= now:
			eligible.append(key)
	eligible.sort_custom(_sort_toast_keys)

	_toast_visible_keys = eligible.slice(0, TOAST_MAX_VISIBLE)
	for key in _toast_visible_keys:
		_toast_container.add_child(_make_toast_row(key, _toasts[key]))

	_refresh_anchor()


func _sort_toast_keys(a: String, b: String) -> bool:
	var da: Dictionary = _toasts[a]
	var db: Dictionary = _toasts[b]
	if da["severity"] != db["severity"]:
		return da["severity"] > db["severity"]  # warning outranks info
	return da["first_seen"] < db["first_seen"]  # longest-waiting first


func _make_toast_row(key: String, data: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_theme_stylebox_override("panel", _make_panel_style())
	row.custom_minimum_size = Vector2(0.0, TOAST_HEIGHT_ESTIMATE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)

	var is_warning: bool = int(data["severity"]) == 1

	var icon := Label.new()
	icon.text = "!" if is_warning else "i"
	icon.add_theme_color_override("font_color", COLOR_STATE_ORANGE if is_warning else COLOR_STATE_BLUE)
	icon.add_theme_font_size_override("font_size", 18)
	hbox.add_child(icon)

	var text_label := Label.new()
	text_label.text = String(data["text"])
	text_label.add_theme_color_override("font_color", COLOR_TEXT)
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_label)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "X"
	dismiss_btn.tooltip_text = "Dismiss"
	dismiss_btn.custom_minimum_size = Vector2(24.0, 24.0)
	_apply_flat_button_style(dismiss_btn)
	dismiss_btn.pressed.connect(_on_toast_dismiss_pressed.bind(key))
	hbox.add_child(dismiss_btn)

	return row


func _on_toast_dismiss_pressed(key: String) -> void:
	if not _toasts.has(key):
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	_toasts[key]["dismissed_until"] = now + TOAST_DISMISS_SECONDS
	_refresh_toast_display()


func _reconcile_toasts() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var stale_keys: Array = []
	for key in _toasts.keys():
		if now - float(_toasts[key]["last_seen"]) > TOAST_STALE_SECONDS:
			stale_keys.append(key)
	if stale_keys.is_empty():
		return
	for key in stale_keys:
		_toasts.erase(key)
	_refresh_toast_display()


func _on_sealed_space_warning(cells: Array, _item_ids: Array, why: String) -> void:
	if cells.is_empty():
		return
	show_toast("sealed:%s" % str(cells[0]), 1, why)


func _on_unsheltered_furniture_info(cell: Vector3i, why: String) -> void:
	show_toast("unshelter:%s" % str(cell), 0, why)


func _build_anchor() -> void:
	_anchor_zone = PanelContainer.new()
	_anchor_zone.name = "Z3_Anchor"
	_anchor_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	_anchor_zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_anchor_zone.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_anchor_zone.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_anchor_zone.grow_vertical = Control.GROW_DIRECTION_END
	_anchor_zone.offset_left = -(EDGE_MARGIN + RIGHT_ZONE_WIDTH)
	_anchor_zone.offset_right = -EDGE_MARGIN
	_anchor_zone.offset_top = EDGE_MARGIN + TIME_CONTROLS_HEIGHT_ESTIMATE + ZONE_GAP \
		+ TOAST_MAX_VISIBLE * (TOAST_HEIGHT_ESTIMATE + ZONE_GAP)
	_anchor_zone.offset_bottom = _anchor_zone.offset_top + 200.0  # room for chip + expanded list
	_anchor_zone.visible = false
	_anchor_zone.mouse_entered.connect(_set_hover.bind("anchor", true))
	_anchor_zone.mouse_exited.connect(_set_hover.bind("anchor", false))
	add_child(_anchor_zone)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_anchor_zone.add_child(vbox)

	_anchor_button = Button.new()
	_anchor_button.custom_minimum_size = Vector2(80.0, 28.0)
	_apply_flat_button_style(_anchor_button)
	_anchor_button.pressed.connect(_on_anchor_button_pressed)
	vbox.add_child(_anchor_button)

	_anchor_expanded_panel = PanelContainer.new()
	_anchor_expanded_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_anchor_expanded_panel.visible = false
	vbox.add_child(_anchor_expanded_panel)

	_anchor_expanded_list = VBoxContainer.new()
	_anchor_expanded_list.add_theme_constant_override("separation", 4)
	_anchor_expanded_panel.add_child(_anchor_expanded_list)


func _refresh_anchor() -> void:
	var overflow_keys: Array = []
	for key in _toasts.keys():
		if not _toast_visible_keys.has(key):
			overflow_keys.append(key)
	_anchor_entries_cache = overflow_keys

	if overflow_keys.is_empty():
		_anchor_zone.visible = false
		_anchor_expanded = false
		_anchor_expanded_panel.visible = false
		return

	_anchor_zone.visible = true
	_anchor_button.text = "%d !" % overflow_keys.size()
	_anchor_expanded_panel.visible = _anchor_expanded
	if _anchor_expanded:
		_rebuild_anchor_list()


func _on_anchor_button_pressed() -> void:
	_anchor_expanded = not _anchor_expanded
	_anchor_expanded_panel.visible = _anchor_expanded
	if _anchor_expanded:
		_rebuild_anchor_list()


func _rebuild_anchor_list() -> void:
	for child in _anchor_expanded_list.get_children():
		child.queue_free()

	var sorted_keys: Array = _anchor_entries_cache.duplicate()
	sorted_keys.sort_custom(_sort_toast_keys)

	for key in sorted_keys:
		if not _toasts.has(key):
			continue
		var data: Dictionary = _toasts[key]
		var label := Label.new()
		var prefix: String = "!" if int(data["severity"]) == 1 else "i"
		label.text = "%s %s" % [prefix, String(data["text"])]
		label.add_theme_color_override("font_color", COLOR_TEXT)
		label.add_theme_font_size_override("font_size", 16)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_anchor_expanded_list.add_child(label)


# ---------------------------------------------------------------------------
# Z4 - Villager panel host + selection wiring + overhead distress icons
# ---------------------------------------------------------------------------

func _build_villager_panel() -> void:
	_villager_panel = VillagerPanelScript.new()
	_villager_panel.name = "Z4_VillagerPanel"
	add_child(_villager_panel)
	_villager_panel.mouse_entered.connect(_set_hover.bind("villager_panel", true))
	_villager_panel.mouse_exited.connect(_set_hover.bind("villager_panel", false))


## CLICK SELECTION (2026-07-23, task 2b): project selection works ANY time
## (build mode or not), but tools keep priority -- a click while a tool is
## armed never selects (matches the pre-existing villager-pick gate below).
## Order: project cell hit -> select it (and clear any villager selection);
## else deselect the current project and fall through to villager picking
## (existing behavior), so clicking empty ground / a non-project cell / a
## villager all behave exactly as before.
func _on_build_click(pressed: bool) -> void:
	if not pressed:
		return
	if _building_system.get_active_tool() != TOOL_NONE:
		return
	var ray: Dictionary = _camera_input.get_world_ray()
	if _voxel_world != null:
		var extra_solid: Callable = Callable(_building_system, "_is_blueprint_solid_for_pick")
		var hit: Dictionary = _voxel_world.raycast_cells(ray["origin"], ray["dir"], 200.0, extra_solid)
		if not hit.is_empty():
			var project_id: Variant = _building_system.get_project_at_cell(hit["cell"])
			if project_id != null:
				_building_system.select_project(project_id)
				_villager_panel.deselect()
				return
	_building_system.deselect_project()
	var villager_id: Variant = _villager_ai.pick_villager(ray["origin"], ray["dir"], 200.0)
	if villager_id == null:
		_villager_panel.deselect()
	else:
		_villager_panel.select(villager_id)


func _update_distress_icons() -> void:
	if _villager_ai == null:
		return

	var ids: Array = _villager_ai.get_villager_ids()
	var seen: Dictionary = {}

	for id in ids:
		var info: Dictionary = _villager_ai.get_info(id)
		var distress: String = String(info.get("distress", ""))
		if distress == "":
			if _distress_icons.has(id):
				_distress_icons[id].queue_free()
				_distress_icons.erase(id)
			continue

		seen[id] = true
		var marker: Node3D = _distress_icons.get(id)
		if marker == null:
			marker = _make_distress_marker()
			_distress_icons[id] = marker

		var visual_pos: Vector3 = info.get("visual_pos", Vector3.ZERO)
		marker.global_position = visual_pos + Vector3(0.0, 1.4, 0.0)

	var stale_ids: Array = []
	for id in _distress_icons.keys():
		if not seen.has(id):
			stale_ids.append(id)
	for id in stale_ids:
		_distress_icons[id].queue_free()
		_distress_icons.erase(id)


func _make_distress_marker() -> Node3D:
	var marker := Node3D.new()
	marker.name = "DistressIcon"

	var label := Label3D.new()
	label.text = "!"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # full billboard (P13, user decision 2026-07-11)
	label.modulate = COLOR_STATE_ORANGE
	label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	label.font_size = 72
	label.outline_size = 12
	label.pixel_size = 0.01
	label.no_depth_test = true  # readability outranks physicality for a distress signal
	marker.add_child(label)

	add_child(marker)
	return marker


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

func _set_hover(zone: String, hovering: bool) -> void:
	_hover_flags[zone] = hovering


func _make_panel_style(bg: Color = COLOR_CHROME) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


func _apply_flat_button_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _make_panel_style(COLOR_CHROME))
	btn.add_theme_stylebox_override("hover", _make_panel_style(COLOR_CHROME.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", _make_panel_style(COLOR_CHROME.lightened(0.20)))
	btn.add_theme_stylebox_override("disabled", _make_panel_style(COLOR_CHROME))
	btn.add_theme_stylebox_override("focus", _make_panel_style(COLOR_CHROME.lightened(0.08)))
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	btn.add_theme_color_override("font_disabled_color", COLOR_TEXT.darkened(0.4))
	btn.add_theme_font_size_override("font_size", 16)


func _apply_active_button_style(btn: Button, active: bool) -> void:
	if not active:
		_apply_flat_button_style(btn)
		return
	var gold := _make_panel_style(COLOR_GOLD)
	btn.add_theme_stylebox_override("normal", gold)
	btn.add_theme_stylebox_override("hover", gold)
	btn.add_theme_stylebox_override("pressed", gold)
	btn.add_theme_stylebox_override("focus", gold)
	btn.add_theme_color_override("font_color", COLOR_CHROME)
	btn.add_theme_color_override("font_hover_color", COLOR_CHROME)
	btn.add_theme_color_override("font_pressed_color", COLOR_CHROME)
	btn.add_theme_font_size_override("font_size", 16)
