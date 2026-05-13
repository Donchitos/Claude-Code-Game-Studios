extends RefCounted

func test_inner_building_not_attackable_if_outer_exists():
	var state := SimulationState.new()
	state.load_level(LevelData.load("res://assets/data/levels/example_level.json"))
	var targets := state.get_attackable_buildings("B")
	assert(targets.all(func(t): return int(t.get("layer_depth", 0)) == 1))
