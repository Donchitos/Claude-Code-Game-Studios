# This test verifys only the scanner functionallity
# to find all given tests by pattern 'func test_<testname>():'
extends GdUnitTestSuite


func test_example() -> void:
	assert_str("This is an example message").has_length(26)
	assert_str("This is an example message").starts_with("This is an ex")


func test_b() -> void:
	pass


# test name starts with same name e.g. test_b vs test_b2
func test_b2() -> void:
	pass


# test scanning success with invalid formatting
func  	 test_b21 		 ( 	 ) 	 	  -> void:
	pass


# finally verify all tests are found
func after() -> void:
	assert_array(get_children())\
		.extract("test_name")\
		.contains_exactly(["test_example", "test_b", "test_b2", "test_b21"])
