class_name TestClassWithFunctions
extends Control

signal panel_color_change(box :ColorRect, color :Color)

@onready var _box1 := $VBoxContainer/PanelContainer/HBoxContainer/Panel1
@onready var _box2 := $VBoxContainer/PanelContainer/HBoxContainer/Panel2
@onready var _box3 := $VBoxContainer/PanelContainer/HBoxContainer/Panel3


func _on_test_pressed(button_id: int) -> void:
	var box: ColorRect
	match button_id:
		1: box = _box1
		2: box = _box2
		3: box = _box3
	panel_color_change.emit(box, Color.RED)
	# special case for button 3 we wait 1s to change to gray
	if button_id == 3:
		await get_tree().create_timer(1).timeout
	panel_color_change.emit(box, Color.GRAY)
