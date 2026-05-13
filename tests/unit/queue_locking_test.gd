extends RefCounted

func test_queue_lock_blocks_next_row_if_front_not_consumed():
	var state := SimulationState.new()
	state.load_level(LevelData.load("res://assets/data/levels/example_level.json"))
	var available := state.get_available_units()
	assert(available.size() == state.columns.size())
