extends GdUnitTestSuite


func test_testsuite_loading_performance() -> void:
	var time := LocalTime.now()
	var reload_counter := 100.0
	for i in range(1, reload_counter):
		ResourceLoader.load("res://addons/gdUnit4/src/GdUnitTestSuite.gd", "GDScript", ResourceLoader.CACHE_MODE_IGNORE)
	var error_message := "Expecting the loading time of test-suite is less than 50ms\n But was %s" % (time.elapsed_since_ms() / reload_counter)
	assert_float(time.elapsed_since_ms()/ reload_counter)\
		.override_failure_message(error_message)\
		.is_less(50)
	prints("loading takes %d ms" % (time.elapsed_since_ms() / reload_counter))
