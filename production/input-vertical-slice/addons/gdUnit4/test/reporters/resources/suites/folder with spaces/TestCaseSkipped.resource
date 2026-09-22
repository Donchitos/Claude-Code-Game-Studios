extends GdUnitTestSuite


@warning_ignore('unused_parameter')
func test_case1(timeout := 1000, do_skip:=1==1, skip_reason:="do not run this") -> void:
	pass


@warning_ignore('unused_parameter')
func test_case2(skip_reason:="ignored") -> void:
	pass
