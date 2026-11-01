class_name ActiveReloadBar
extends Control
## Synthetik-style active reload widget with sweet-spot timing indicator and outcome banner.

var combat_state: Resource

var _bar_bg: ColorRect
var _sweet_spot: ColorRect
var _indicator: ColorRect
var _feedback_label: Label
var _feedback_timer: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(180, 24)
	size = Vector2(180, 24)


func _ready() -> void:
	_bar_bg = ColorRect.new()
	_bar_bg.size = Vector2(180, 10)
	_bar_bg.position = Vector2(0, 7)
	_bar_bg.color = Color(0.12, 0.16, 0.22, 0.85)
	add_child(_bar_bg)

	_sweet_spot = ColorRect.new()
	# 45% to 75% of 180px = 81px to 135px (width: 54px)
	_sweet_spot.position = Vector2(81, 6)
	_sweet_spot.size = Vector2(54, 12)
	_sweet_spot.color = Color(0.2, 0.85, 0.5, 0.6)
	add_child(_sweet_spot)

	_indicator = ColorRect.new()
	_indicator.position = Vector2(0, 4)
	_indicator.size = Vector2(4, 16)
	_indicator.color = Color("ffffff")
	add_child(_indicator)

	_feedback_label = Label.new()
	_feedback_label.position = Vector2(-20, -22)
	_feedback_label.size = Vector2(220, 20)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override(&"font_size", 13)
	_feedback_label.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_feedback_label.visible = false
	add_child(_feedback_label)

	visible = false


func bind_state(state: Resource) -> void:
	combat_state = state
	if combat_state != null and combat_state.has_signal(&"active_reload_evaluated"):
		combat_state.active_reload_evaluated.connect(_on_active_reload_evaluated)


func _process(delta: float) -> void:
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(_feedback_timer - delta, 0.0)
		if _feedback_timer <= 0.0:
			_feedback_label.visible = false

	if combat_state == null:
		visible = false
		return

	var remaining: float = combat_state.get("reload_remaining")
	var duration: float = combat_state.get("reload_duration")

	if remaining > 0.0:
		visible = true
		var progress: float = 1.0 - clampf(remaining / maxf(duration, 0.001), 0.0, 1.0)
		_indicator.position.x = progress * 176.0
	else:
		if _feedback_timer <= 0.0:
			visible = false


func _on_active_reload_evaluated(success: bool, bonus_rounds: int) -> void:
	_feedback_label.visible = true
	_feedback_timer = 1.4
	if success:
		_feedback_label.text = tr("MÜKEMMEL DOLUM! (+%d GÜÇLÜ MERMİ)") % bonus_rounds
		_feedback_label.add_theme_color_override(&"font_color", Color("66e0c2"))
		_sweet_spot.color = Color("66e0c2")
	else:
		_feedback_label.text = tr("TUTUKLUK! (+0.5s GECİKME)")
		_feedback_label.add_theme_color_override(&"font_color", Color("ff5c5c"))
		_sweet_spot.color = Color("ff5c5c")
