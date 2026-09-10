# GdUnit generated TestSuite
class_name LocalTimeTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/LocalTime.gd'


func test_time_constants() -> void:
	assert_int(LocalTime.MILLIS_PER_HOUR).is_equal(1000*60*60)
	assert_int(LocalTime.MILLIS_PER_MINUTE).is_equal(1000*60)
	assert_int(LocalTime.MILLIS_PER_SECOND).is_equal(1000)
	assert_int(LocalTime.HOURS_PER_DAY).is_equal(24)
	assert_int(LocalTime.MINUTES_PER_HOUR).is_equal(60)
	assert_int(LocalTime.SECONDS_PER_MINUTE).is_equal(60)


func test_now() -> void:
	var current := Time.get_datetime_dict_from_system(true)
	var local_time := LocalTime.now()
	assert_int(local_time.hour()).is_equal(current.get("hour"))
	assert_int(local_time.minute()).is_equal(current.get("minute"))
	assert_int(local_time.second()).is_equal(current.get("second"))
	#  Time.get_datetime_dict_from_system() does not provide milliseconds
	#assert_that(local_time.millis()).is_equal(0)


@warning_ignore("integer_division")
func test_of_unix_time() -> void:
	var time := LocalTime._get_system_time_msecs()
	var local_time := LocalTime.of_unix_time(time)
	@warning_ignore("integer_division")
	assert_int(local_time.hour()).is_equal((time / LocalTime.MILLIS_PER_HOUR) % 24)
	@warning_ignore("integer_division")
	assert_int(local_time.minute()).is_equal((time / LocalTime.MILLIS_PER_MINUTE) % 60)
	@warning_ignore("integer_division")
	assert_int(local_time.second()).is_equal((time / LocalTime.MILLIS_PER_SECOND) % 60)
	assert_int(local_time.millis()).is_equal(time % 1000)


func test_to_string() -> void:
	assert_str(LocalTime.local_time(10, 12, 22, 333)._to_string()).is_equal("10:12:22.333")
	assert_str(LocalTime.local_time(23, 59, 59, 999)._to_string()).is_equal("23:59:59.999")
	assert_str(LocalTime.local_time( 0, 0, 0, 000)._to_string()).is_equal("00:00:00.000")
	assert_str(LocalTime.local_time( 2, 4, 3, 10)._to_string()).is_equal("02:04:03.010")


func test_plus_seconds() -> void:
	var time := LocalTime.local_time(10, 12, 22, 333)
	assert_str(time.plus(LocalTime.TimeUnit.SECOND, 10)._to_string()).is_equal("10:12:32.333")
	assert_str(time.plus(LocalTime.TimeUnit.SECOND, 27)._to_string()).is_equal("10:12:59.333")
	assert_str(time.plus(LocalTime.TimeUnit.SECOND, 1)._to_string()).is_equal("10:13:00.333")

	# test overflow
	var time2 := LocalTime.local_time(10, 59, 59, 333)
	var start_time := time2._time
	for iteration in 10000:
		var t := LocalTime.of_unix_time(start_time)
		var seconds:int = randi_range(0, 1000)
		t.plus(LocalTime.TimeUnit.SECOND, seconds)
		var expected :=  LocalTime.of_unix_time(start_time + (seconds * LocalTime.MILLIS_PER_SECOND))
		assert_str(t._to_string()).is_equal(expected._to_string())


func test_elapsed() -> void:
	assert_str(LocalTime.elapsed(10)).is_equal("10ms")
	assert_str(LocalTime.elapsed(201)).is_equal("201ms")
	assert_str(LocalTime.elapsed(999)).is_equal("999ms")
	assert_str(LocalTime.elapsed(1000)).is_equal("1s 0ms")
	assert_str(LocalTime.elapsed(2000)).is_equal("2s 0ms")
	assert_str(LocalTime.elapsed(3040)).is_equal("3s 40ms")
	assert_str(LocalTime.elapsed(LocalTime.MILLIS_PER_MINUTE * 6 + 3040)).is_equal("6min 3s 40ms")
