class_name ClassWithAwaitFunc
extends Node


func normal_function() -> void:
	print("normal")


func await_function() -> void:
	print(await _await_function())


func _await_function() -> String:
	await get_tree().process_frame
	return "test"
