class_name SteamWireTypes
extends RefCounted
## ADR-0006: explicit, closed typed records. No native object serialization.
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")

## Converts a typed value to/from the canonical JSON value model atomically.
static func transform(value: Variant, shape: Variant, writing: bool) -> Dictionary:
	if shape is String:
		return _scalar(value, shape, writing)
	if not shape is Dictionary:
		return {"status": "INVALID_CONFIG"}
	if shape.has("$array"):
		if not value is Array or value.size() > shape["$max"]:
			return {"status": "INVALID"}
		var rows: Array = []
		for row: Variant in value:
			var result := transform(row, shape["$array"], writing)
			if result.status != "OK":
				return result
			rows.append(result.value)
		return {"status": "OK", "value": rows}
	if not value is Dictionary or value.size() != shape.size():
		return {"status": "INVALID"}
	var fields := {}
	for key: String in shape:
		if not value.has(key):
			return {"status": "INVALID", "path": key}
		var result := transform(value[key], shape[key], writing)
		if result.status != "OK":
			return {"status": result.status, "path": key + "." + result.get("path", "")}
		fields[key] = result.value
	return {"status": "OK", "value": fields}

static func _scalar(value: Variant, kind: String, writing: bool) -> Dictionary:
	match kind:
		"bool":
			if value is bool:
				return {"status": "OK", "value": value}
		"string":
			if value is String:
				return {"status": "OK", "value": value}
		"u63":
			if writing:
				if value is int and value >= 0:
					return {"status": "OK", "value": str(value)}
			else:
				return Codec.read_u63(value)
		"f64", "f32":
			var result: Dictionary
			if writing:
				if not (value is float or value is int):
					return {"status": "INVALID"}
				result = Codec.float_to_hex(float(value))
			else:
				result = Codec.hex_to_float(value)
			if result.status == "OK" and kind == "f32":
				var number: float = float(value) if writing else result.value
				if float(PackedFloat32Array([number])[0]) != number:
					return {"status": "INVALID"}
			return result
		"vec2":
			if writing:
				if value is Vector2 and value.is_finite():
					return {"status": "OK", "value": [Codec.float_to_hex(value.x).value, Codec.float_to_hex(value.y).value]}
			elif value is Array and value.size() == 2:
				var x := _scalar(value[0], "f32", false)
				var y := _scalar(value[1], "f32", false)
				if x.status == "OK" and y.status == "OK":
					return {"status": "OK", "value": Vector2(x.value, y.value)}
		"bits64":
			var bytes := PackedByteArray()
			bytes.resize(8)
			bytes.encode_s64(0, 0x0102030405060708)
			var little := bytes.hex_encode() == "0807060504030201"
			if not little and bytes.hex_encode() != "0102030405060708":
				return {"status": "UNSUPPORTED_PLATFORM"}
			if writing and value is int:
				bytes.encode_s64(0, value)
				if little:
					bytes.reverse()
				return {"status": "OK", "value": bytes.hex_encode()}
			if not writing and Codec.is_hex(value, 16):
				bytes = value.hex_decode()
				if little:
					bytes.reverse()
				return {"status": "OK", "value": bytes.decode_s64(0)}
	return {"status": "INVALID"}
