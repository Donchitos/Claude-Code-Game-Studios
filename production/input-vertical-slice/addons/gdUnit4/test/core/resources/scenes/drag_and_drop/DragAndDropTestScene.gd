extends Control

@onready var texture := preload("res://addons/gdUnit4/test/core/resources/scenes/icon.png")

func _ready() -> void:
	# set initial drag texture
	($left/TextureRect as TextureRect).texture = texture


# Virtual method to be implemented by the user. Use this method to process and accept inputs on UI elements. See accept_event().
func _gui_input(_event :InputEvent) -> void:
	#prints("Game _gui_input", _event.as_text())
	pass


func _on_Button_button_down() -> void:
	# print("BUTTON DOWN")
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
