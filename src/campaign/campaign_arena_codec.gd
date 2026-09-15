extends RefCounted
## Lossless numeric sidecar, applied only at save/restore boundaries, never on hot ticks.

## Deep copy with String dictionary keys and only JSON-safe values.
static func normalize(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[str(key)] = normalize(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child in value: result.append(normalize(child))
		return result
	return value

## Mirror tree containing exact original numeric representation; other leaves are null.
static func bits(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[str(key)] = bits(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child in value: result.append(bits(child))
		return result
	if value is int: return "i:" + str(value)
	if value is float:
		var bytes := PackedByteArray()
		bytes.resize(8)
		bytes.encode_double(0, value)
		return "f:" + bytes.hex_encode()
	return null

## Structural coverage and numeric mirrors are validated before decoding any live state.
static func valid(value: Variant, encoded: Variant, depth: int = 0) -> bool:
	if depth > 12: return false
	if value is Dictionary:
		if not encoded is Dictionary or value.size() != encoded.size(): return false
		for key in value:
			if not encoded.has(key) or not valid(value[key], encoded[key], depth + 1): return false
		return true
	if value is Array:
		if not encoded is Array or value.size() != encoded.size(): return false
		for i in value.size():
			if not valid(value[i], encoded[i], depth + 1): return false
		return true
	if value is int or value is float:
		if not encoded is String or not is_finite(float(value)): return false
		if encoded.begins_with("i:"):
			var raw: String = encoded.substr(2)
			return raw.length() <= 20 and raw.is_valid_int() and str(raw.to_int()) == raw and absf(float(raw.to_int())) <= 9007199254740991.0 and float(raw.to_int()) == float(value)
		if not encoded.begins_with("f:") or encoded.length() != 18: return false
		var hex: String = encoded.substr(2)
		for character in hex:
			if not character in "0123456789abcdef": return false
		var bytes: PackedByteArray = hex.hex_decode()
		if bytes.size() != 8: return false
		var exact: float = bytes.decode_double(0)
		# Accept exactly the raw numeric mirror or this engine's own full-precision JSON roundtrip.
		# Small magnitudes may lose multiple ULPs because stringify limits decimal places.
		if not is_finite(exact): return false
		var expected: Variant = JSON.parse_string(JSON.stringify(exact, "", true, true))
		return float(value) == exact or ((expected is float or expected is int) and float(value) == float(expected))
	return encoded == null

## Reconstructs original int/float types and IEEE bits after valid() has succeeded.
static func restore(value: Variant, encoded: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[str(key)] = restore(value[key], encoded[key])
		return result
	if value is Array:
		var result: Array = []
		for i in value.size(): result.append(restore(value[i], encoded[i]))
		return result
	if value is int or value is float:
		if str(encoded).begins_with("i:"): return str(encoded).substr(2).to_int()
		return str(encoded).substr(2).hex_decode().decode_double(0)
	return value
