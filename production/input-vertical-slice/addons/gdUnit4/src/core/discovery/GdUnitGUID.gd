## A class representing a globally unique identifier for GdUnit test elements.
## Uses random values to generate unique identifiers that can be used
## to track and reference test cases and suites across the test framework.
class_name GdUnitGUID
extends RefCounted


## The internal string representation of the GUID.
## Generated using Godot's ResourceUID system when no existing GUID is provided.
var _guid: String


## Creates a new GUID instance.
## If no GUID is provided, generates a new one using Godot's ResourceUID system.
func _init(from_guid: String = "") -> void:
	if from_guid.is_empty():
		_guid = _generate_guid()
	else:
		_guid = from_guid


## Compares this GUID with another for equality.
## Returns true if both GUIDs represent the same unique identifier.
func equals(other: GdUnitGUID) -> bool:
	return other._guid == _guid


## Generates a custom GUID using random bytes.[br]
## The format uses 16 random bytes encoded to hex and formatted with hyphens.
static func _generate_guid() -> String:
	# Pre-allocate array with exact size needed
	var bytes := PackedByteArray()
	bytes.resize(16)

	# Fill with random bytes
	for i in range(16):
		bytes[i] = randi() % 256

	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80

	return bytes.hex_encode().insert(8, "-").insert(16, "-").insert(24, "-")


func _to_string() -> String:
	return _guid
