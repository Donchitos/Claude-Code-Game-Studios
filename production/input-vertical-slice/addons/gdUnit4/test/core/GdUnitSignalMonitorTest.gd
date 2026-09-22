extends GdUnitTestSuite
@warning_ignore_start("redundant_await")

# This test setup uses two monitors, which are created for each new test.
# The monitors must be reinitialized for each run, otherwise signals from previous runs will be detected incorrectly.
# See https://github.com/MikeSchulze/gdUnit4/issues/1002
func before_test() -> void:
	monitor_signals(o2.o1, false)
	monitor_signals(o2, false)


# This test runs first and emits on object o1 and o2 the signals and is cauched by both monitors
func test_monitor_obj1() -> void:
	o2.o1.emit()
	await assert_signal(o2.o1).is_emitted("s1")
	await assert_signal(o2).is_emitted("s2")
	assert_int(o2.x).is_equal(2)


# This test runs after `test_monitor_obj1` and must fail because the signal is not emitted yet
func test_monitor_obj2() -> void:
	var result := await assert_failure_await(await func() -> void:
		await assert_signal(o2).wait_until(50).is_emitted("s2")
	)
	result.has_message("Expecting emit signal: 's2()' but timed out after 50ms")


func test_monitor_obj2_success() -> void:
	o2._on_s1()
	await assert_signal(o2).wait_until(500).is_emitted("s2")

class C1:
	signal s1

	func emit() -> void:
		s1.emit()

class C2:
	signal s2
	var x := 0
	var o1: C1

	func _init() -> void:
		o1 = C1.new()
		o1.s1.connect(_on_s1)
		x = 1

	func _on_s1() -> void:
		s2.emit()
		x = 2

var o2: C2


func before() -> void:
	o2 = C2.new()
