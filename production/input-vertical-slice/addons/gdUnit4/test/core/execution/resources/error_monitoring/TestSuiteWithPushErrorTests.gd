extends GdUnitTestSuite


@onready var ExampleClassWithPushNotifications := preload("res://addons/gdUnit4/test/core/execution/resources/error_monitoring/ExampleClassWithPushNotifications.gd")

func test_without_push_errors() -> void:
	# should allways succeed
	assert_float(ExampleClassWithPushNotifications.get_square_root(25)).is_equal_approx(5, 1e-5)


func test_with_push_error() -> void:
	# should only failing when push_error reporting is activated
	ExampleClassWithPushNotifications.get_square_root(-1)


func test_with_push_error_is_catched() -> void:
	# should allways succeed, because it is catched by the assert_error
	assert_error(func() -> void: ExampleClassWithPushNotifications.get_square_root(-1)) \
			.is_push_error(ExampleClassWithPushNotifications.ERROR_NEGATIVE_VALUE)


func test_without_push_warning() -> void:
	# should allways succeed
	assert_str(ExampleClassWithPushNotifications.get_capitalized_text("T_ext")).is_equal("T Ext")


func test_with_push_warning() -> void:
	# should only failing when push_error reporting is activated
	assert_str(ExampleClassWithPushNotifications.get_capitalized_text("Text")).is_equal("Text")


func test_push_warning_is_catched() -> void:
	# should allways succeed, because it is catched by the assert_error
	assert_error(func() -> void: ExampleClassWithPushNotifications.get_capitalized_text("Text")) \
			.is_push_warning(ExampleClassWithPushNotifications.WARN_UNCHANGED)
