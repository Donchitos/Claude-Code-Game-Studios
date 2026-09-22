extends GdUnitTestSuite


func test_tuple_empty() -> void:
	var t := GdUnitTuple.new()
	assert_array(t.values()).is_empty()


func test_tuple_construct() -> void:
	assert_array(GdUnitTuple.new(0, 1).values()).contains_exactly(0, 1)
	assert_array(GdUnitTuple.new(0, 1, 2).values()).contains_exactly(0, 1, 2)
	assert_array(GdUnitTuple.new(0, 1, 2, 3).values()).contains_exactly(0, 1, 2, 3)
	assert_array(GdUnitTuple.new(0, 1, 2, 3, "abc").values()).contains_exactly(0, 1, 2, 3, "abc")
	assert_array(GdUnitTuple.new([0, 1, 2, 3], "abc").values()).contains_exactly([0, 1, 2, 3], "abc")


func test_tuple_of() -> void:
	assert_array(tuple(0, 1).values()).contains_exactly(0, 1)
	assert_array(tuple(0, 1, 2).values()).contains_exactly(0, 1, 2)
	assert_array(tuple(0, 1, 2, 3).values()).contains_exactly(0, 1, 2, 3)
	assert_array(tuple(0, 1, 2, 3, "abc").values()).contains_exactly(0, 1, 2, 3, "abc")
	assert_array(tuple([0, 1, 2, 3], "abc").values()).contains_exactly([0, 1, 2, 3], "abc")
