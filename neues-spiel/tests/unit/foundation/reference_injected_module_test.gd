## Unit test — Foundation Spine Story 001 (ADR-0001 DI scaffold).
##
## Proves the injected-tier module shape is headless-mockable in isolation:
## Node.new() construction, mock @export assignment, and a direct setup()
## call, with zero scene tree and zero Autoload registration (AC-1 / AC-2).
class_name ReferenceInjectedModuleTest
extends GdUnitTestSuite


func test_reference_injected_module_setup_with_valid_mocks_completes() -> void:
	# Arrange
	var module: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	var mock_one: Node = auto_free(Node.new())
	var mock_two: Node = auto_free(Node.new())
	module.dependency_one = mock_one
	module.dependency_two = mock_two
	assert_bool(module.is_inside_tree()).is_false()
	assert_bool(module.is_set_up()).is_false()

	# Act
	module.setup()

	# Assert
	assert_bool(module.is_set_up()).is_true()
	assert_object(module.dependency_one).is_same(mock_one)
	assert_object(module.dependency_two).is_same(mock_two)


func test_reference_injected_module_setup_missing_dependency_one_raises_assertion() -> void:
	# Arrange
	var module: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module.dependency_two = auto_free(Node.new())

	# Act + Assert
	await assert_error(func() -> void: module.setup()).is_runtime_error(
		"Assertion failed: ReferenceInjectedModule.dependency_one not wired"
	)


func test_reference_injected_module_setup_missing_dependency_two_raises_assertion() -> void:
	# Arrange
	var module: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module.dependency_one = auto_free(Node.new())

	# Act + Assert
	await assert_error(func() -> void: module.setup()).is_runtime_error(
		"Assertion failed: ReferenceInjectedModule.dependency_two not wired"
	)


func test_reference_injected_module_setup_missing_both_dependencies_raises_assertion() -> void:
	# Arrange
	var module: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())

	# Act + Assert — dependency_one is asserted first, so its message fires.
	await assert_error(func() -> void: module.setup()).is_runtime_error(
		"Assertion failed: ReferenceInjectedModule.dependency_one not wired"
	)
