# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GdUnitTestResourceLoaderTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/test/GdUnitTestResourceLoader.gd'


func test_load_test_suite_gd() -> void:
	var resource_path := "res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteParameterizedTests.resource"
	var test_suite := GdUnitTestResourceLoader.load_test_suite_gd(resource_path)
	assert_that(test_suite).is_not_null()
	assert_object(test_suite).is_instanceof(GdUnitTestSuite)
	test_suite.free()
