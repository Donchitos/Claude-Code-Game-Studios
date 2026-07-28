## Story `building-034` -- [ScaffoldDismantlePlanner] (TD rulings D10/D4,
## ADR-0007 §1b invariant SC-INV-1).
class_name ScaffoldDismantlePlannerTest
extends GdUnitTestSuite


func test_next_top_down_demolition_cell_picks_highest_y_first() -> void:
	var cells: Array[Vector3i] = [
		Vector3i(5, 1, 5), Vector3i(5, 2, 5), Vector3i(5, 3, 5),
	]
	var result: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(cells, [])
	assert_vector(result).is_equal(Vector3i(5, 3, 5))


func test_next_top_down_demolition_cell_ties_broken_lexicographically_xz() -> void:
	var cells: Array[Vector3i] = [
		Vector3i(6, 3, 5), Vector3i(5, 3, 5), Vector3i(5, 3, 6),
	]
	var result: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(cells, [])
	assert_vector(result).is_equal(Vector3i(5, 3, 5))


func test_sc_inv_1_skips_a_cell_whose_body_column_is_occupied() -> void:
	var cells: Array[Vector3i] = [Vector3i(5, 1, 5), Vector3i(5, 2, 5), Vector3i(5, 3, 5)]
	# A villager's body-column occupies the topmost cell (5,3,5) -- it must
	# NEVER be selected while occupied; the next-highest UNOCCUPIED cell wins.
	var occupied: Array = [VillagerWalkabilityRules.body_column(Vector3i(5, 3, 5))]
	var result: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(cells, occupied)
	assert_vector(result).override_failure_message(
		"SC-INV-1: a cell occupied by a villager's body-column must never be selected for removal"
	).is_equal(Vector3i(5, 2, 5))


func test_no_cell_returned_when_every_remaining_cell_is_occupied() -> void:
	var cells: Array[Vector3i] = [Vector3i(5, 1, 5)]
	var occupied: Array = [VillagerWalkabilityRules.body_column(Vector3i(5, 1, 5))]
	var result: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(cells, occupied)
	assert_vector(result).is_equal(ScaffoldDismantlePlanner.NO_CELL)


func test_can_collapse_bottom_up_true_when_structure_unoccupied() -> void:
	var cells: Array[Vector3i] = [Vector3i(5, 1, 5), Vector3i(5, 2, 5)]
	assert_bool(ScaffoldDismantlePlanner.can_collapse_bottom_up(cells, [])).is_true()


func test_can_collapse_bottom_up_false_when_any_cell_occupied() -> void:
	var cells: Array[Vector3i] = [Vector3i(5, 1, 5), Vector3i(5, 2, 5)]
	var occupied: Array = [VillagerWalkabilityRules.body_column(Vector3i(5, 1, 5))]
	assert_bool(ScaffoldDismantlePlanner.can_collapse_bottom_up(cells, occupied)).override_failure_message(
		"D4: a bottom-up no-worker collapse must be refused if ANY cell of the structure is occupied"
	).is_false()
