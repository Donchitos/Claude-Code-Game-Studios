# this class used to mock testing with inner classes and default arguments in functions
class_name AdvancedTestClass
extends Resource

class SoundData:
	@warning_ignore("unused_private_class_variable")
	var _sample :String
	@warning_ignore("unused_private_class_variable")
	var _randomnes :float

class AtmosphereData:
	enum {
		WATER,
		AIR,
		SMOKY,
	}
	var _toxigen :float
	var _type :int

	func _init(type := AIR, toxigen := 0.0) -> void:
		_type = type
		_toxigen = toxigen
# some comment, and an row staring with an space to simmulate invalid formatting


	# seter func with default values
	func set_data(type := AIR, toxigen := 0.0) -> void:
		_type = type
		_toxigen = toxigen

	static func to_atmosphere(_value :Dictionary) -> AtmosphereData:
		return null

class Area4D extends Resource:

	const SOUND := 1
	const ATMOSPHERE := 2
	var _meta := Dictionary()

	func _init(_x :int, atmospere :AtmosphereData = null) -> void:
		_meta[ATMOSPHERE] = atmospere

	func get_sound() -> SoundData:
		# sounds are optional
		if _meta.has(SOUND):
			@warning_ignore("unsafe_cast")
			return _meta[SOUND] as SoundData
		return null

	func get_atmoshere() -> AtmosphereData:
		@warning_ignore("unsafe_cast")
		return _meta[ATMOSPHERE] as AtmosphereData

var _areas : = {}

func _init() -> void:
	# add default atmoshere
	_areas["default"] = Area4D.new(1, AtmosphereData.new())

func get_area(name :String, default :Area4D = null) -> Area4D:
	return _areas.get(name, default)


# test spy is called sub functions select(<type>) -> a(), b(), c()
enum {
	A, B, C
}

func a() -> String:
	return "a"

func b() -> String:
	return "b"

func c() -> String:
	return "c"

func select( type :int) -> String:
	match type:
		A: return a()
		B: return b()
		C: return c()
		_: return ""

static func to_foo() -> String:
	return "foo"
