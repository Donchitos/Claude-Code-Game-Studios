extends Control

## Loads level data for the editor from disk.
func load_level(path: String) -> Dictionary:
	return LevelData.load(path)

## Saves level data from the editor to disk.
func save_level(path: String, level: Dictionary) -> void:
	LevelData.save(path, level)

func _ready() -> void:
	pass
