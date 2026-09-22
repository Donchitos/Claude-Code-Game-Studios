class_name ProductionSettlementScreen
extends Control

signal retry_requested
signal home_requested

var _title: Label
var _summary: Label
var _retry: Button
var _home: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## Builds the immutable settlement summary for one completed run.
## Example: `settlement.present(true, 4, 120, 75.0, 0)`.
func present(victory: bool, level: int, kills: int, elapsed: float, pages_granted: int = 0, reason: String = "") -> void:
	var background := ColorRect.new()
	background.color = Color("071a20")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_title = Label.new()
	var title := _title
	title.text = "试炼完成" if victory else "试炼失败"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(45.0, 280.0)
	title.size = Vector2(630.0, 90.0)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("f4d27a"))
	add_child(title)
	_summary = Label.new()
	var summary := _summary
	summary.text = "等级 %d · 击杀 %d · 用时 %.1f 秒\n功法残页 +%d" % [level, kills, elapsed, pages_granted]
	if not reason.is_empty():
		summary.text += "\n" + reason
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.position = Vector2(45.0, 395.0)
	summary.size = Vector2(630.0, 80.0)
	summary.add_theme_font_size_override("font_size", 25)
	summary.add_theme_color_override("font_color", Color("d6e8d1"))
	add_child(summary)
	_retry = Button.new()
	var retry := _retry
	retry.name = "RetryButton"
	retry.text = "再试一局"
	retry.tooltip_text = "重新开始试炼"
	retry.position = Vector2(100.0, 570.0)
	retry.size = Vector2(520.0, 105.0)
	retry.add_theme_font_size_override("font_size", 28)
	retry.pressed.connect(func() -> void: retry_requested.emit())
	add_child(retry)
	_home = Button.new()
	var home := _home
	home.name = "HomeButton"
	home.text = "返回首页"
	home.tooltip_text = "返回掌天试炼首页"
	home.position = Vector2(100.0, 710.0)
	home.size = Vector2(520.0, 96.0)
	home.add_theme_font_size_override("font_size", 25)
	home.pressed.connect(func() -> void: home_requested.emit())
	add_child(home)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	if _home == null:
		return
	var viewport_size := get_viewport_rect().size
	var content_width := minf(760.0, viewport_size.x - 48.0)
	var left := (viewport_size.x - content_width) * 0.5
	_title.position = Vector2(left, viewport_size.y * 0.25)
	_title.size = Vector2(content_width, 90.0)
	_summary.position = Vector2(left, viewport_size.y * 0.40)
	_summary.size = Vector2(content_width, 110.0)
	_retry.position = Vector2(left + content_width * 0.15, viewport_size.y * 0.57)
	_retry.size = Vector2(content_width * 0.70, 88.0)
	_home.position = Vector2(left + content_width * 0.15, viewport_size.y * 0.72)
	_home.size = Vector2(content_width * 0.70, 76.0)
