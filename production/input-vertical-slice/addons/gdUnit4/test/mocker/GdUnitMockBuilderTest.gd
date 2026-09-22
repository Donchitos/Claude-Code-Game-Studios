# GdUnit generated TestSuite
class_name GdUnitMockBuilderTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/mocking/GdUnitMockBuilder.gd'

func test_mock_on_script_path_without_class_name() -> void:
	var instance :Object = (load("res://addons/gdUnit4/test/mocker/resources/ClassWithoutNameA.gd") as GDScript).new()
	var script := GdUnitMockBuilder.mock_on_script(instance, "res://addons/gdUnit4/test/mocker/resources/ClassWithoutNameA.gd", [], true);
	assert_str(script.resource_name).starts_with("MockClassWithoutNameA")
	assert_that(script.get_instance_base_type()).is_equal("Resource")
	# finally check the mocked script is valid
	assert_int(script.reload()).is_equal(OK)


func test_mock_on_script_path_with_custom_class_name() -> void:
	# the class contains a class_name definition
	var instance :Object = (load("res://addons/gdUnit4/test/mocker/resources/ClassWithCustomClassName.gd") as GDScript).new()
	var script := GdUnitMockBuilder.mock_on_script(instance, "res://addons/gdUnit4/test/mocker/resources/ClassWithCustomClassName.gd", [], false);
	assert_str(script.resource_name).starts_with("MockGdUnitTestCustomClassName")
	assert_that(script.get_instance_base_type()).is_equal("Resource")
	# finally check the mocked script is valid
	assert_int(script.reload()).is_equal(OK)


func test_mock_on_class_with_class_name() -> void:
	var script := GdUnitMockBuilder.mock_on_script(ClassWithNameA.new(), ClassWithNameA, [], false);
	assert_str(script.resource_name).starts_with("MockClassWithNameA")
	assert_that(script.get_instance_base_type()).is_equal("Resource")
	# finally check the mocked script is valid
	assert_int(script.reload()).is_equal(OK)


func test_mock_on_class_with_custom_class_name() -> void:
	# the class contains a class_name definition
	var script := GdUnitMockBuilder.mock_on_script(GdUnit_Test_CustomClassName.new(), GdUnit_Test_CustomClassName, [], false);
	assert_str(script.resource_name).starts_with("MockGdUnitTestCustomClassName")
	assert_that(script.get_instance_base_type()).is_equal("Resource")
	# finally check the mocked script is valid
	assert_int(script.reload()).is_equal(OK)


func test_mock_on_script_with_multilines() -> void:
	var instance :Object = (load("res://addons/gdUnit4/test/mocker/resources/ClassWithMultilineBlocks.gd") as GDScript).new()
	var script := GdUnitMockBuilder.mock_on_script(instance, instance.get_script(), [], false);
	assert_str(script.resource_name).starts_with("MockClassWithMultilineBlocks")
	assert_that(script.get_instance_base_type()).is_equal("RefCounted")
	# finally check the mocked script is valid
	assert_int(script.reload()).is_equal(OK)
