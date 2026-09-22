# this test suite ends with success, no failures or errors
extends GdUnitTestSuite

func before() -> void:
	assert_str("suite before").is_equal("suite before")

func after() -> void:
	assert_str("suite after").is_equal("suite after")

func before_test() -> void:
	assert_str("test before").is_equal("test before")

func after_test() -> void:
	assert_str("test after").is_equal("test after")

func test_case1() -> void:
	assert_str("test_case1").is_equal("test_case1")

func test_case2() -> void:
	assert_str("test_case2").is_equal("test_case2")
