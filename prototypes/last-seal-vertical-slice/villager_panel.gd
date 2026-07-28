# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Villager Info Panel per design/ux/villager-panel.md (HUD zone Z4): name ->
# activity -> mood+why -> sleep bar. Selection state is OWNED here (villager
# id + show/hide); hud.gd only feeds pick results in via select()/deselect().
# Live-mirrors upstream state every _process frame on raw delta (readable
# during pause, never reads TimeTickSystem.game_delta). Why-slot reserves a
# stable height so the empty state never causes layout jump (villager-panel.md
# States table). Duck-typed Node deps (villager_ai/needs_mood) — no shared
# interface/class_name exists yet for those modules at this stage of the slice.
class_name VillagerPanel
extends Control

# -- Mood band -> icon shape (A1: shape + label, never hue alone) --
# 0 = circle (Happy), 1 = diamond (Content), 2 = triangle (Low).
class MoodIcon extends Control:
	var shape: int = 0

	func _init() -> void:
		custom_minimum_size = Vector2(16.0, 16.0)

	func _draw() -> void:
		var color: Color = Color(0.929, 0.902, 0.855)  # #EDE6DA
		var s: Vector2 = size
		match shape:
			0:  # Happy - circle
				draw_circle(s * 0.5, min(s.x, s.y) * 0.5, color)
			1:  # Content - diamond
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(s.x * 0.5, 0.0),
					Vector2(s.x, s.y * 0.5),
					Vector2(s.x * 0.5, s.y),
					Vector2(0.0, s.y * 0.5),
				])
				draw_colored_polygon(pts, color)
			2:  # Low - triangle
				var tri: PackedVector2Array = PackedVector2Array([
					Vector2(s.x * 0.5, 0.0),
					Vector2(s.x, s.y),
					Vector2(0.0, s.y),
				])
				draw_colored_polygon(tri, color)

	func set_shape(new_shape: int) -> void:
		if shape == new_shape:
			return
		shape = new_shape
		queue_redraw()


const PANEL_WIDTH := 260.0
const PANEL_HEIGHT := 220.0          # reserved height; stable regardless of why-slot content
const MIN_WHY_HEIGHT := 54.0         # reserved rows for C4/C5 (2-3 wrapped lines)
const EDGE_MARGIN := 16.0

const COLOR_CHROME := Color(0.149, 0.133, 0.125)     # #262220
const COLOR_TEXT := Color(0.929, 0.902, 0.855)       # #EDE6DA
const COLOR_GOLD := Color(0.961, 0.659, 0.235)       # #F5A83C
const COLOR_STATE_ORANGE := Color(0.86, 0.47, 0.20)  # [assumption] pending art-bible theme verification (hud.md A3 OPEN)

# Committed six-way activity mapping (villager-panel.md) - this UX spec owns
# the label wording, independent of whatever debug state_label VillagerAI emits.
const ACTIVITY_LABELS := {
	0: "Thinking",
	1: "On the way",
	2: "Working",
	3: "Sleeping",
	4: "Taking a break",
	5: "Strolling",
}
const ACTIVITY_ICONS := {
	0: "?",
	1: "→",  # ->
	2: "⚒",  # hammer/pick
	3: "z",
	4: "‖",  # pause bars
	5: "↻",  # loop arrow
}
const BAND_SHAPES := {0: 0, 1: 1, 2: 2}  # band int -> MoodIcon shape (identity map, kept explicit for clarity)


var _villager_ai: Node
var _needs_mood: Node
var _selected_id: Variant = null

var _panel: PanelContainer
var _name_label: Label
var _activity_label: Label
var _mood_icon: MoodIcon
var _mood_label: Label
var _why_label: Label
var _distress_icon: Label
var _sleep_bar: ProgressBar
var _sleep_value_label: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)

	# Z4: left edge, lower half, grows upward (hud.md layout zones).
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.85
	anchor_bottom = 0.85
	offset_left = EDGE_MARGIN
	offset_right = EDGE_MARGIN + PANEL_WIDTH
	offset_top = -PANEL_HEIGHT
	offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_BEGIN

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", COLOR_TEXT)
	vbox.add_child(_name_label)

	vbox.add_child(HSeparator.new())

	_activity_label = Label.new()
	_activity_label.add_theme_font_size_override("font_size", 16)
	_activity_label.add_theme_color_override("font_color", COLOR_TEXT)
	vbox.add_child(_activity_label)

	var mood_row := HBoxContainer.new()
	mood_row.add_theme_constant_override("separation", 6)
	vbox.add_child(mood_row)

	_mood_icon = MoodIcon.new()
	mood_row.add_child(_mood_icon)

	_mood_label = Label.new()
	_mood_label.add_theme_font_size_override("font_size", 16)
	_mood_label.add_theme_color_override("font_color", COLOR_TEXT)
	mood_row.add_child(_mood_label)

	var why_row := HBoxContainer.new()
	why_row.add_theme_constant_override("separation", 6)
	why_row.custom_minimum_size = Vector2(0.0, MIN_WHY_HEIGHT)
	vbox.add_child(why_row)

	_why_label = Label.new()
	_why_label.add_theme_font_size_override("font_size", 16)
	_why_label.add_theme_color_override("font_color", COLOR_TEXT)
	_why_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_why_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_why_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	why_row.add_child(_why_label)

	_distress_icon = Label.new()
	_distress_icon.text = "!"
	_distress_icon.add_theme_font_size_override("font_size", 18)
	_distress_icon.add_theme_color_override("font_color", COLOR_STATE_ORANGE)
	_distress_icon.modulate.a = 0.0  # reserved-space toggle: never removed from the tree (C5)
	why_row.add_child(_distress_icon)

	var sleep_row := HBoxContainer.new()
	sleep_row.add_theme_constant_override("separation", 8)
	vbox.add_child(sleep_row)

	var sleep_caption := Label.new()
	sleep_caption.text = "Sleep"
	sleep_caption.add_theme_font_size_override("font_size", 16)
	sleep_caption.add_theme_color_override("font_color", COLOR_TEXT)
	sleep_row.add_child(sleep_caption)

	_sleep_bar = ProgressBar.new()
	_sleep_bar.min_value = 0.0
	_sleep_bar.max_value = 100.0
	_sleep_bar.show_percentage = false
	_sleep_bar.custom_minimum_size = Vector2(120.0, 16.0)
	_sleep_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sleep_bar.add_theme_stylebox_override("background", _make_panel_style(COLOR_CHROME.darkened(0.2)))
	_sleep_bar.add_theme_stylebox_override("fill", _make_panel_style(COLOR_GOLD))
	sleep_row.add_child(_sleep_bar)

	_sleep_value_label = Label.new()
	_sleep_value_label.add_theme_font_size_override("font_size", 16)
	_sleep_value_label.add_theme_color_override("font_color", COLOR_TEXT)
	_sleep_value_label.custom_minimum_size = Vector2(28.0, 0.0)
	_sleep_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sleep_row.add_child(_sleep_value_label)


func _process(_delta: float) -> void:
	if _selected_id == null or _villager_ai == null:
		return
	var ids: Array = _villager_ai.get_villager_ids()
	if not ids.has(_selected_id):
		# Despawn / stale handle (TR-040 / TR-010): graceful close, never a stale panel.
		deselect()
		return
	_refresh()


## Wires the upstream read-only data sources. Called once by hud.gd.setup().
func setup(villager_ai: Node, needs_mood: Node) -> void:
	_villager_ai = villager_ai
	_needs_mood = needs_mood


## Opens the panel on the given villager id (same-frame refresh).
func select(villager_id: int) -> void:
	_selected_id = villager_id
	visible = true
	_refresh()


## Closes the panel. Idempotent (safe to call when already deselected).
func deselect() -> void:
	_selected_id = null
	visible = false


func get_selected_id() -> Variant:
	return _selected_id


func _refresh() -> void:
	var info: Dictionary = _villager_ai.get_info(_selected_id)
	var display: Dictionary = _needs_mood.get_display(_selected_id)

	_name_label.text = String(info.get("name", ""))

	var state: int = int(info.get("state", 0))
	_activity_label.text = "%s  %s" % [ACTIVITY_ICONS.get(state, "?"), ACTIVITY_LABELS.get(state, "Unknown")]

	var band: int = int(display.get("band", 0))
	var band_label: String = String(display.get("band_label", ""))
	_mood_icon.set_shape(BAND_SHAPES.get(band, 0))
	_mood_icon.tooltip_text = band_label
	_mood_label.text = band_label
	_mood_label.tooltip_text = band_label

	_why_label.text = String(display.get("why", ""))

	var distress: String = String(info.get("distress", ""))
	if distress != "":
		_distress_icon.modulate.a = 1.0
		_distress_icon.tooltip_text = _distress_tooltip(distress)
	else:
		_distress_icon.modulate.a = 0.0
		_distress_icon.tooltip_text = ""

	var sleep_value: float = float(display.get("sleep", 0.0))
	_sleep_bar.value = sleep_value
	_sleep_value_label.text = str(int(round(sleep_value)))


func _distress_tooltip(kind: String) -> String:
	match kind:
		"trapped":
			return "Trapped"
		"ground_sleeping":
			return "Sleeping rough"
		_:
			return kind


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
