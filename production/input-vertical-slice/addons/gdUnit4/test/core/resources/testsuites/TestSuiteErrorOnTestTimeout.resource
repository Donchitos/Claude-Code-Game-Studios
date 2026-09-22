# this test suite ends with error on testcase1 by a timeout
extends GdUnitTestSuite

func before() -> void:
	assert_str("suite before").is_equal("suite before")

func after() -> void:
	assert_str("suite after").is_equal("suite after")

func before_test() -> void:
	assert_str("test before").is_equal("test before")

func after_test() -> void:
	assert_str("test after").is_equal("test after")

# configure test with timeout of 2s
@warning_ignore('unused_parameter')
func test_case1(timeout:=2000) -> void:
	assert_str("test_case1").is_equal("test_case1")
	# wait 3s to let the test fail by timeout
	await await_millis(3000)

func test_case2() -> void:
	assert_str("test_case2").is_equal("test_case2")
