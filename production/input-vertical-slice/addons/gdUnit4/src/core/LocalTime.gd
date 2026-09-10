# This class provides Date/Time functionallity to Godot
class_name LocalTime
extends Resource

enum TimeUnit {
	DEFAULT = 0,
	MILLIS = 1,
	SECOND = 2,
	MINUTE = 3,
	HOUR   = 4,
	DAY    = 5,
	MONTH  = 6,
	YEAR   = 7
}

const SECONDS_PER_MINUTE:int = 60
const MINUTES_PER_HOUR:int = 60
const HOURS_PER_DAY:int = 24
const MILLIS_PER_SECOND:int = 1000
const MILLIS_PER_MINUTE:int = MILLIS_PER_SECOND * SECONDS_PER_MINUTE
const MILLIS_PER_HOUR:int   = MILLIS_PER_MINUTE * MINUTES_PER_HOUR

var _time :int
var _hour :int
var _minute :int
var _second :int
var _millisecond :int


static func now() -> LocalTime:
	return LocalTime.new(_get_system_time_msecs())


static func of_unix_time(time_ms :int) -> LocalTime:
	return LocalTime.new(time_ms)


static func local_time(hours :int, minutes :int, seconds :int, milliseconds :int) -> LocalTime:
	return LocalTime.new(MILLIS_PER_HOUR * hours\
		+ MILLIS_PER_MINUTE * minutes\
		+ MILLIS_PER_SECOND * seconds\
		+ milliseconds)


func elapsed_since() -> String:
	return LocalTime.elapsed(LocalTime._get_system_time_msecs() - _time)


func elapsed_since_ms() -> int:
	return LocalTime._get_system_time_msecs() - _time


func plus(time_unit :TimeUnit, value :int) -> LocalTime:
	var addValue:int = 0
	match time_unit:
		TimeUnit.MILLIS:
			addValue = value
		TimeUnit.SECOND:
			addValue = value * MILLIS_PER_SECOND
		TimeUnit.MINUTE:
			addValue = value * MILLIS_PER_MINUTE
		TimeUnit.HOUR:
			addValue = value * MILLIS_PER_HOUR
	@warning_ignore("return_value_discarded")
	_init(_time + addValue)
	return self


static func elapsed(p_time_ms :int) -> String:
	var local_time_ := LocalTime.new(p_time_ms)
	if local_time_._hour > 0:
		return "%dh %dmin %ds %dms" % [local_time_._hour, local_time_._minute, local_time_._second, local_time_._millisecond]
	if local_time_._minute > 0:
		return "%dmin %ds %dms" % [local_time_._minute, local_time_._second, local_time_._millisecond]
	if local_time_._second > 0:
		return "%ds %dms" % [local_time_._second, local_time_._millisecond]
	return "%dms" % local_time_._millisecond


# create from epoch timestamp in ms
func _init(time: int) -> void:
	_time = time
	@warning_ignore("integer_division")
	_hour  =  (time / MILLIS_PER_HOUR) % 24
	@warning_ignore("integer_division")
	_minute =  (time / MILLIS_PER_MINUTE) % 60
	@warning_ignore("integer_division")
	_second =  (time / MILLIS_PER_SECOND) % 60
	_millisecond = time % 1000


func hour() -> int:
	return _hour


func minute() -> int:
	return _minute


func second() -> int:
	return _second


func millis() -> int:
	return _millisecond


func _to_string() -> String:
	return "%02d:%02d:%02d.%03d" % [_hour, _minute, _second, _millisecond]


# wraper to old OS.get_system_time_msecs() function
static func _get_system_time_msecs() -> int:
	return Time.get_unix_time_from_system() * 1000 as int
