class_name ClassWithOverridenVirtuals
extends Node

var _x := "default"


func _init() -> void:
	_x = "_init"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if _x == "_init":
		_x = ""
	_x += "_ready"


func _input(event :InputEvent) -> void:
	_x = "_input"
	if event.is_action_released("ui_accept"):
		_x = "ui_accept"
