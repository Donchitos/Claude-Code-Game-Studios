# this test suite fails on stage before_test()
extends GdUnitTestSuite

func before() -> void:
	assert_str("suite before").is_equal("suite before")

func after() -> void:
	assert_str("suite after").is_equal("suite after")

func before_test() -> void:
	assert_str("test before").override_failure_message("failed on before_test()").is_empty()

func after_test() -> void:
	assert_str("test after").is_equal("test after")

func test_case1() -> void:
	assert_str("test_case1").is_equal("test_case1")

func test_case2() -> void:
	assert_str("test_case2").is_equal("test_case2")
