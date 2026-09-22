extends Node2D

class Player extends Node:
	var position :Vector3 = Vector3.ZERO


	func _init() -> void:
		set_name("Player")

	func is_on_floor() -> bool:
		return true


func _ready() -> void:
	add_child(Player.new(), true)
