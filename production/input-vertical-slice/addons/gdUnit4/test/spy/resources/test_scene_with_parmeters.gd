class_name TestSceneWithProperties
extends Node2D


@onready var progress := %ProgressBar

@warning_ignore("unused_private_class_variable")
var _parameter_obj := RefCounted.new()
@warning_ignore("unused_private_class_variable")
var _parameter_dict := {"key" : "value"}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#prints(progress, _parameter_obj, _parameter_dict)
	pass
