extends SceneTree

const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const LIMITS := {"max_bytes": 65536, "max_depth": 32}
var checks := 0
var failures := 0

func _initialize() -> void:
	var valid := ['null', 'true', 'false', '""', '[]', '{}', '{"a":"9223372036854775807","b":[true,null,"次序"]}', '{"a":"\\u000a\\u0009\\\\\\\"/"}']
	for wire: String in valid:
		var decoded: Dictionary = Codec.decode(wire.to_utf8_buffer(), LIMITS)
		_check(decoded.status == "OK", "canonical decode " + wire)
		if decoded.status == "OK":
			_check(Codec.encode(decoded.value, LIMITS).text == wire, "exact roundtrip")
	for wire: String in ['{"a":true,"a":false}', '{"b":true,"a":false}', '{"a":[null,]}', '{ "a":null}', '"\\n"', '"\\u6b21"', '1', '1.0', '-0', '"unterminated', 'null null', '{"nested":{"x":null,"x":null}}', '"\\/"']:
		var result: Dictionary = Codec.decode(wire.to_utf8_buffer(), LIMITS)
		_check(result.status != "OK" and not result.has("value"), "reject without publication " + wire)
	_check(Codec.encode({"x": 1}, LIMITS).status == "INVALID", "native numeric forbidden")
	_check(Codec.encode({1: "x"}, LIMITS).status == "INVALID", "non-string key")
	_check(Codec.encode({"键": "x"}, LIMITS).status == "INVALID", "non-ascii key")
	_check(Codec.encode([], {}).status == "INVALID_CONFIG", "missing budgets")
	_check(Codec.decode('[[[]]]'.to_utf8_buffer(), {"max_bytes": 99, "max_depth": 2}).status == "TOO_DEEP", "decode depth guard")
	_check(Codec.encode([[[]]], {"max_bytes": 99, "max_depth": 2}).status == "TOO_DEEP", "encode depth guard")
	_check(Codec.encode("次", {"max_bytes": 4, "max_depth": 2}).status == "TOO_LARGE", "utf8 byte budget")
	_check(Codec.decode(PackedByteArray([0xef, 0xbb, 0xbf, 0x7b, 0x7d]), LIMITS).status != "OK", "BOM rejected")
	for value: String in ["0", "1", "9007199254740993", "9223372036854775807"]:
		_check(Codec.read_u63(value).status == "OK", "exact u63 " + value)
	for value: Variant in ["", "01", "+1", "-1", "1.0", "1e3", "9223372036854775808", "１２", 1, true]:
		_check(Codec.read_u63(value).status == "INVALID", "reject u63")
	_check(Codec.read_u63("9007199254740993").value == 9007199254740993, "above double precision exact")
	_check(Codec.increment_u63("9223372036854775807").status == "OVERFLOW", "checked increment")
	_check(Codec.increment_u63("9").value == "10", "decimal carry")
	_check(Codec.float_to_hex(1.0).value == "3ff0000000000000", "IEEE one")
	_check(Codec.float_to_hex(-0.0).value == "0000000000000000", "normalize negative zero")
	for bits: String in ["0000000000000001", "3ff0000000000000", "bff0000000000000", "7fefffffffffffff"]:
		var decoded: Dictionary = Codec.hex_to_float(bits)
		_check(decoded.status == "OK" and Codec.float_to_hex(decoded.value).value == bits, "float bits exact " + bits)
	for bits: String in ["8000000000000000", "7ff0000000000000", "7ff8000000000000", "fff0000000000000", "3FF0000000000000", "0"]:
		_check(Codec.hex_to_float(bits).status == "INVALID", "reject float bits")
	_check(Codec.float_to_hex(INF).status == "INVALID", "infinity rejected")
	_check(Codec.float_to_hex(NAN).status == "INVALID", "NaN rejected")
	_check(Codec.decode('"\\u0000"'.to_utf8_buffer(), LIMITS).status == "UNSUPPORTED_STRING", "NUL fails explicitly, never replacement")
	_check(Codec.decode('"\\\\u0000"'.to_utf8_buffer(), LIMITS).status == "OK", "literal backslash-u is preserved")
	_check(Codec.encode("次", {"max_bytes": 5, "max_depth": 1}).status == "OK", "exact utf8 byte boundary")
	_check(Codec.decode('"次"'.to_utf8_buffer(), {"max_bytes": 5, "max_depth": 1}).status == "OK", "decode exact byte boundary")
	_check(Codec.encode({}, {"max_bytes": true, "max_depth": 1}).status == "INVALID_CONFIG", "bool budget rejected")
	for hex: String in ["ff", "c080", "eda080", "f4908080", "80", "e282"]:
		var raw := PackedByteArray([34])
		raw.append_array(hex.hex_decode())
		raw.append(34)
		var decoded := Codec.decode(raw, LIMITS)
		_check(decoded.status != "OK" and not decoded.has("value"), "invalid UTF8 " + hex)
	var deep := "[".repeat(64) + "null" + "]".repeat(64)
	_check(Codec.decode(deep.to_utf8_buffer(), {"max_bytes": 999, "max_depth": 64}).status == "OK", "exact depth boundary")
	_check(Codec.decode(("[" + deep + "]").to_utf8_buffer(), {"max_bytes": 999, "max_depth": 64}).status == "TOO_DEEP", "depth beyond hard ceiling")
	var cycle: Array = []
	cycle.append(cycle)
	_check(Codec.encode(cycle, LIMITS).status == "TOO_DEEP", "cycle bounded")
	cycle.clear()
	print("STEAM_CODEC_TEST checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
