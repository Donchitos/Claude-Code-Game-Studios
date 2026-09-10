# GdUnit generated TestSuite
extends GdUnitTestSuite


func hook_service() -> GdUnitTestSessionHookService:
	return auto_free(GdUnitTestSessionHookService.new())


func test_load_hook_not_exists() -> void:
	var hook := hook_service().load_hook("res://addons/gdUnit4/test/core/hooks/InvalidTestSessionHook.gd")

	assert_result(hook)\
		.is_error()\
		.contains_message("The hook 'res://addons/gdUnit4/test/core/hooks/InvalidTestSessionHook.gd' not exists.")


func test_load_hook_not_inherits_hook() -> void:
	var hook := hook_service().load_hook("res://addons/gdUnit4/test/core/hooks/GdUnitTestSessionHookServiceTest.gd")

	assert_result(hook)\
		.is_error()\
		.contains_message("The hook 'res://addons/gdUnit4/test/core/hooks/GdUnitTestSessionHookServiceTest.gd' must inhertit from 'GdUnitTestSessionHook'.")


func test_load_hook_success() -> void:
	var hook := hook_service().load_hook("res://addons/gdUnit4/test/core/hooks/ExampleTestSessionHookA.gd")

	assert_result(hook).is_success()
	assert_object(hook.value())\
		.is_not_null()\
		.is_inheriting(GdUnitTestSessionHook)


func test_register_hook() -> void:
	var service := hook_service()

	var hook := ExampleTestSessionHookA.new()
	service.register(hook)

	# verify
	assert_array(service.enigne_hooks).contains_exactly([hook])

	# try to register at twice should fail
	var result := service.register(hook)
	assert_result(result)\
		.is_error()\
		.contains_message("A hook instance of 'res://addons/gdUnit4/test/core/hooks/ExampleTestSessionHookA.gd' is already registered.")
	assert_array(service.enigne_hooks).contains_exactly([hook])


func test_execute_startup() -> void:
	var service := hook_service()

	var hook := ExampleTestSessionHookA.new()
	service.register(hook)

	assert_array(hook._state).is_empty()

	service.execute_startup(GdUnitTestSession.new([], "res://reports"))
	assert_array(hook._state).contains_exactly(["startup"])


func test_execute_shutdown() -> void:
	var service := hook_service()

	var hook := ExampleTestSessionHookA.new()
	service.register(hook)

	assert_array(hook._state).is_empty()

	service.execute_shutdown(GdUnitTestSession.new([], "res://reports"))
	assert_array(hook._state).contains_exactly(["shutdown"])


func test_hook_priority_execution() -> void:
	var service := hook_service()
	var hook_a := ExampleTestSessionHookA.new()
	var hook_b := ExampleTestSessionHookB.new()
	var hook_c := ExampleTestSessionHookC.new()

	var start_up_called := PackedStringArray()
	hook_a.start_up.connect(func(hook_name: String) -> void: start_up_called.push_back(hook_name))
	hook_b.start_up.connect(func(hook_name: String) -> void: start_up_called.push_back(hook_name))
	hook_c.start_up.connect(func(hook_name: String) -> void: start_up_called.push_back(hook_name))
	var shutdown_called := PackedStringArray()
	hook_a.shut_down.connect(func(hook_name: String) -> void: shutdown_called.push_back(hook_name))
	hook_b.shut_down.connect(func(hook_name: String) -> void: shutdown_called.push_back(hook_name))
	hook_c.shut_down.connect(func(hook_name: String) -> void: shutdown_called.push_back(hook_name))

	# register order is important
	assert_result(service.register(hook_b)).is_success()
	assert_result(service.register(hook_a)).is_success()
	assert_result(service.register(hook_c)).is_success()
	assert_array(service.enigne_hooks).contains_exactly([hook_b, hook_a, hook_c])

	# must be executed ordered
	var test_session := GdUnitTestSession.new([], "res://reports")
	assert_result(await service.execute_startup(test_session)).is_success()
	assert_result(await service.execute_shutdown(test_session)).is_success()

	# verify is called in the correct order
	assert_array(start_up_called).contains_exactly(["hook_b", "hook_a", "hook_c"])
	assert_array(shutdown_called).contains_exactly(["hook_c", "hook_a", "hook_b"])


func test_move_before() -> void:
	var service := hook_service()
	var hook_a := ExampleTestSessionHookA.new()
	var hook_b := ExampleTestSessionHookB.new()
	var hook_c := ExampleTestSessionHookC.new()

	service.register(hook_a)
	service.register(hook_b)
	service.register(hook_c)

	assert_array(service.enigne_hooks).contains_exactly([hook_a, hook_b, hook_c])

	# Verify move hook_b before hook_a
	service.move_before(hook_b, hook_a)
	assert_array(service.enigne_hooks).contains_exactly([hook_b, hook_a, hook_c])
	# Call at twice to verify the order is not changed because it is already before
	service.move_before(hook_b, hook_a)
	assert_array(service.enigne_hooks).contains_exactly([hook_b, hook_a, hook_c])
	# Verify move hook_b before hook_c
	service.move_before(hook_c, hook_b)
	assert_array(service.enigne_hooks).contains_exactly([hook_c, hook_b, hook_a])


func test_move_after() -> void:
	var service := hook_service()
	var hook_a := ExampleTestSessionHookA.new()
	var hook_b := ExampleTestSessionHookB.new()
	var hook_c := ExampleTestSessionHookC.new()

	service.register(hook_a)
	service.register(hook_b)
	service.register(hook_c)

	assert_array(service.enigne_hooks).contains_exactly([hook_a, hook_b, hook_c])

	# Verify move hook_a after hook_b
	service.move_after(hook_a, hook_b)
	assert_array(service.enigne_hooks).contains_exactly([hook_b, hook_a, hook_c])
	# Call at twice to verify the order is not changed because it is already after
	service.move_after(hook_a, hook_b)
	assert_array(service.enigne_hooks).contains_exactly([hook_b, hook_a, hook_c])
	# Verify move hook_b after hook_c
	service.move_after(hook_b, hook_c)
	assert_array(service.enigne_hooks).contains_exactly([hook_a, hook_c, hook_b])
