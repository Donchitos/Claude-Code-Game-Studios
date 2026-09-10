extends Control

signal panel_color_change(box :ColorRect, color :Color)

const COLOR_CYCLE := [Color.ROYAL_BLUE, Color.CHARTREUSE, Color.YELLOW_GREEN]

@onready var _box1 := $VBoxContainer/PanelContainer/HBoxContainer/Panel1
@onready var _box2 := $VBoxContainer/PanelContainer/HBoxContainer/Panel2
@onready var _box3 := $VBoxContainer/PanelContainer/HBoxContainer/Panel3

@warning_ignore("unused_private_class_variable")
@export var _initial_color := Color.RED

@warning_ignore("unused_private_class_variable")
var _nullable :Object

var _last_pressed_strength: float


func _ready() -> void:
	panel_color_change.connect(_on_panel_color_changed)
	# we call this function to verify the _ready is only once called
	# this is need to verify `add_child` is calling the original implementation only once
	only_one_time_call()


func only_one_time_call() -> void:
	pass


#func _notification(what):
#	prints("TestScene", GdObjects.notification_as_string(what))


func _on_test_pressed(button_id :int) -> void:
	var box :ColorRect
	match button_id:
		1: box = _box1
		2: box = _box2
		3: box = _box3
	panel_color_change.emit(box, Color.RED)
	# special case for button 3 we wait 1s to change to gray
	if button_id == 3:
		await get_tree().create_timer(1).timeout
	panel_color_change.emit(box, Color.GRAY)


func _on_panel_color_changed(box :ColorRect, color :Color) -> void:
	box.color = color


func create_timer(timeout :float) -> Timer:
	var timer :Timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timeout.bind(timer))
	timer.set_one_shot(true)
	timer.start(timeout)
	return timer


func _on_timeout(timer :Timer) -> void:
	remove_child(timer)
	timer.queue_free()


func color_cycle() -> String:
	prints("color_cycle")
	await create_timer(0.500).timeout
	emit_signal("panel_color_change", _box1, Color.RED)
	prints("timer1")
	await create_timer(0.500).timeout
	emit_signal("panel_color_change", _box1, Color.BLUE)
	prints("timer2")
	await create_timer(0.500).timeout
	emit_signal("panel_color_change", _box1, Color.GREEN)
	prints("cycle end")
	return "black"


func start_color_cycle() -> void:
	color_cycle()


# used for manuall spy checked created spy
func _create_spell() -> Spell:
	return Spell.new()


func create_spell() -> Spell:
	var spell := _create_spell()
	spell.connect("spell_explode", Callable(self, "_destroy_spell"))
	return spell


func _destroy_spell(spell :Spell) -> void:
	#prints("_destroy_spell", spell)
	remove_child(spell)
	spell.queue_free()


func _input(event :InputEvent) -> void:
	if event.is_action_released("ui_accept"):
		add_child(create_spell())

	if event is InputEventAction:
		_last_pressed_strength = (event as InputEventAction).strength

	#prints(event.as_text())


func add(a: int, b :int) -> int:
	return a + b


func _on_touch_1_pressed() -> void:
	pass


func _on_touch_1_released() -> void:
	pass


func _on_exit_pressed() -> void:
	get_tree().quit()
