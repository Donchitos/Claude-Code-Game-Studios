extends RefCounted

func test_level_roundtrip_save_load():
	var level := LevelData.load("res://assets/data/levels/example_level.json")
	LevelData.save("user://levels/tmp.json", level)
	var loaded := LevelData.load("user://levels/tmp.json")
	assert(level == loaded)
