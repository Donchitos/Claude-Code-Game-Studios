class_name SteamCanonicalCodec
extends RefCounted
## ADR-0006 wire codec foundation; Godot String cannot represent U+0000.
## Escaped NUL returns UNSUPPORTED_STRING rather than corrupting payload bytes.
## Pure ADR-0006 wire codec. Does not validate domain semantics or read/write saves.
## Caller budgets are mandatory; HARD_MAX_DEPTH protects this recursive adapter,
## and is not a measured production snapshot budget.

const HARD_MAX_DEPTH := 64
const U63_MAX := "9223372036854775807"

## Encodes only objects/arrays/strings/bools/null; failures expose no partial text.
static func encode(value: Variant, limits: Dictionary) -> Dictionary:
	if not _valid_limits(limits):
		return {"status": "INVALID_CONFIG"}
	var state := {"status": "OK", "chunks": PackedStringArray(), "bytes": 0, "limits": limits}
	_encode_value(value, 0, state)
	if state.status != "OK":
		return {"status": state.status}
	var wire: String = "".join(state.chunks)
	return {"status": "OK", "text": wire, "bytes": state.bytes, "sha256": wire.sha256_text()}

## Requires canonical bytes before exposing parser data. Equality with a fresh
## encoding rejects duplicate keys, permissive parser syntax, escape aliases,
## BOM, numeric JSON and invalid UTF-8. Schemas reject unknown fields separately.
static func decode(bytes: PackedByteArray, limits: Dictionary) -> Dictionary:
	if not _valid_limits(limits):
		return {"status": "INVALID_CONFIG"}
	if bytes.size() > limits.max_bytes:
		return {"status": "TOO_LARGE"}
	if bytes.has(0):
		return {"status": "INVALID"}
	var wire := bytes.get_string_from_utf8()
	if wire.to_utf8_buffer() != bytes or wire.begins_with(String.chr(0xfeff)):
		return {"status": "INVALID"}
	if not _within_depth(wire, limits.max_depth):
		return {"status": "TOO_DEEP"}
	if _contains_nul_escape(wire):
		return {"status": "UNSUPPORTED_STRING"}
	var parser := JSON.new()
	if parser.parse(wire) != OK:
		return {"status": "INVALID"}
	var encoded := encode(parser.data, limits)
	if encoded.status != "OK":
		return {"status": encoded.status}
	if encoded.text != wire:
		return {"status": "NON_CANONICAL"}
	return {"status": "OK", "value": parser.data, "sha256": encoded.sha256}

## Reads a canonical nonnegative int64 decimal string without float conversion.
static func read_u63(value: Variant) -> Dictionary:
	if not value is String or value.is_empty() or value.length() > 19:
		return {"status": "INVALID"}
	if value.length() > 1 and value[0] == "0":
		return {"status": "INVALID"}
	for i: int in range(value.length()):
		var c: int = value.unicode_at(i)
		if c < 48 or c > 57:
			return {"status": "INVALID"}
	if value.length() == 19 and value > U63_MAX:
		return {"status": "INVALID"}
	return {"status": "OK", "value": value.to_int()}

## Increments a u63 string with explicit exhaustion; never wraps or rounds.
static func increment_u63(value: Variant) -> Dictionary:
	var parsed := read_u63(value)
	if parsed.status != "OK":
		return parsed
	if value == U63_MAX:
		return {"status": "OVERFLOW"}
	return {"status": "OK", "value": str(parsed.value + 1)}

## Tests exact lowercase hexadecimal wire width without numeric conversion.
static func is_hex(value: Variant, width: int) -> bool:
	if not value is String or value.length() != width:
		return false
	for i: int in range(value.length()):
		var code: int = value.unicode_at(i)
		if not ((code >= 48 and code <= 57) or (code >= 97 and code <= 102)):
			return false
	return true

## Encodes finite float64 bits most-significant-byte first, normalizing -0.
static func float_to_hex(value: float) -> Dictionary:
	if not is_finite(value):
		return {"status": "INVALID"}
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, 0.0 if value == 0.0 else value)
	var order := _double_byte_order()
	if order == 0:
		return {"status": "UNSUPPORTED_PLATFORM"}
	var bits := ""
	for i: int in range(8):
		bits += "%02x" % bytes[7 - i if order == 1 else i]
	return {"status": "OK", "value": bits}

## Decodes canonical finite bits; negative zero and all nonfinite encodings fail.
static func hex_to_float(bits: Variant) -> Dictionary:
	if not is_hex(bits, 16) or bits == "8000000000000000":
		return {"status": "INVALID"}
	var order := _double_byte_order()
	if order == 0:
		return {"status": "UNSUPPORTED_PLATFORM"}
	var bytes := PackedByteArray()
	bytes.resize(8)
	for i: int in range(8):
		bytes[7 - i if order == 1 else i] = bits.substr(i * 2, 2).hex_to_int()
	var value := bytes.decode_double(0)
	if not is_finite(value):
		return {"status": "INVALID"}
	return {"status": "OK", "value": value}

static func _valid_limits(limits: Dictionary) -> bool:
	return limits.get("max_bytes") is int and limits.max_bytes > 0 \
		and limits.get("max_depth") is int and limits.max_depth > 0 \
		and limits.max_depth <= HARD_MAX_DEPTH

static func _within_depth(wire: String, limit: int) -> bool:
	var depth := 0
	var in_string := false
	var escaped := false
	for i: int in range(wire.length()):
		var c := wire.unicode_at(i)
		if in_string:
			if escaped:
				escaped = false
			elif c == 92:
				escaped = true
			elif c == 34:
				in_string = false
		elif c == 34:
			in_string = true
		elif c == 91 or c == 123:
			depth += 1
			if depth > limit:
				return false
		elif c == 93 or c == 125:
			depth -= 1
	return true

static func _encode_value(value: Variant, depth: int, state: Dictionary) -> void:
	if state.status != "OK":
		return
	if value is Array or value is Dictionary:
		if depth >= state.limits.max_depth:
			state.status = "TOO_DEEP"
			return
	match typeof(value):
		TYPE_NIL: _append("null", state)
		TYPE_BOOL: _append("true" if value else "false", state)
		TYPE_STRING: _encode_string(value, state)
		TYPE_ARRAY: _encode_array(value, depth, state)
		TYPE_DICTIONARY: _encode_object(value, depth, state)
		_: state.status = "INVALID"

static func _encode_array(value: Array, depth: int, state: Dictionary) -> void:
	_append("[", state)
	for i: int in range(value.size()):
		if state.status != "OK":
			return
		if i > 0:
			_append(",", state)
		_encode_value(value[i], depth + 1, state)
	_append("]", state)

static func _encode_object(value: Dictionary, depth: int, state: Dictionary) -> void:
	var keys := value.keys()
	for key: Variant in keys:
		if not key is String:
			state.status = "INVALID"
			return
		for i: int in range(key.length()):
			if key.unicode_at(i) > 127:
				state.status = "INVALID"
				return
	keys.sort()
	_append("{", state)
	for i: int in range(keys.size()):
		if state.status != "OK":
			return
		if i > 0:
			_append(",", state)
		_encode_string(keys[i], state)
		_append(":", state)
		_encode_value(value[keys[i]], depth + 1, state)
	_append("}", state)

static func _encode_string(value: String, state: Dictionary) -> void:
	_append('"', state)
	var start := 0
	for i: int in range(value.length()):
		var c := value.unicode_at(i)
		if c < 32 or c == 34 or c == 92:
			_append(value.substr(start, i - start), state)
			_append("\\u%04x" % c if c < 32 else "\\" + value[i], state)
			start = i + 1
		if state.status != "OK":
			return
	_append(value.substr(start), state)
	_append('"', state)

static func _append(fragment: String, state: Dictionary) -> void:
	if state.status != "OK":
		return
	var size := fragment.to_utf8_buffer().size()
	if size > state.limits.max_bytes - state.bytes:
		state.status = "TOO_LARGE"
		return
	state.bytes += size
	state.chunks.append(fragment)

static func _double_byte_order() -> int:
	var probe := PackedByteArray()
	probe.resize(8)
	probe.encode_double(0, 1.0)
	match probe.hex_encode():
		"000000000000f03f": return 1
		"3ff0000000000000": return 2
		_: return 0

static func _contains_nul_escape(wire: String) -> bool:
	var i := 0
	var in_string := false
	while i < wire.length():
		if wire[i] == '"':
			in_string = not in_string
		elif in_string and wire[i] == "\\":
			if wire.substr(i, 6) == "\\u0000":
				return true
			i += 1 # Skip any escaped slash/quote; a literal backslash-u is valid.
		i += 1
	return false
