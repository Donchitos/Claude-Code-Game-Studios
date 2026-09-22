# this test suite fails on multiple stages
extends GdUnitTestSuite

func before() -> void:
	assert_str("suite before").is_equal("suite before")

func after() -> void:
	assert_str("suite after").override_failure_message("failed on after()").is_empty()

func before_test() -> void:
	assert_str("test before").override_failure_message("failed on before_test()").is_empty()

func after_test() -> void:
	assert_str("test after").is_equal("test after")

func test_case1() -> void:
	assert_str("test_case1").override_failure_message("failed 1 on test_case1()").is_empty()
	assert_str("test_case1").override_failure_message("failed 2 on test_case1()").is_empty()

func test_case2() -> void:
	assert_str("test_case2").is_equal("test_case2")
