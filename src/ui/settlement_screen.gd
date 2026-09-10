class_name ProductionSettlementScreen
extends Control

signal retry_requested
signal home_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## Builds the immutable settlement summary for one completed run.
## Example: `settlement.present(true, 4, 120, 75.0)`.
func present(victory: bool, level: int, kills: int, elapsed: float) -> void:
	var background := ColorRect.new()
	background.color = Color("071a20")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var title := Label.new()
	title.text = "试炼完成" if victory else "试炼失败"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(45.0, 280.0)
	title.size = Vector2(630.0, 90.0)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("f4d27a"))
	add_child(title)
	var summary := Label.new()
	summary.text = "等级 %d · 击杀 %d · 用时 %.1f 秒" % [level, kills, elapsed]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.position = Vector2(45.0, 395.0)
	summary.size = Vector2(630.0, 80.0)
	summary.add_theme_font_size_override("font_size", 25)
	summary.add_theme_color_override("font_color", Color("d6e8d1"))
	add_child(summary)
	var retry := Button.new()
	retry.name = "RetryButton"
	retry.text = "再试一局"
	retry.tooltip_text = "重新开始试炼"
	retry.position = Vector2(100.0, 570.0)
	retry.size = Vector2(520.0, 105.0)
	retry.add_theme_font_size_override("font_size", 28)
	retry.pressed.connect(func() -> void: retry_requested.emit())
	add_child(retry)
	var home := Button.new()
	home.name = "HomeButton"
	home.text = "返回首页"
	home.tooltip_text = "返回掌天试炼首页"
	home.position = Vector2(100.0, 710.0)
	home.size = Vector2(520.0, 96.0)
	home.add_theme_font_size_override("font_size", 25)
	home.pressed.connect(func() -> void: home_requested.emit())
	add_child(home)

