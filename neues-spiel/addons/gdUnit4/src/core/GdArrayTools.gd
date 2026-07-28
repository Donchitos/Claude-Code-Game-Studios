## Small helper tool to work with Godot Arrays
class_name GdArrayTools
extends RefCounted


const max_elements := 32
const ARRAY_TYPES := [
	TYPE_ARRAY,
	TYPE_PACKED_BYTE_ARRAY,
	TYPE_PACKED_INT32_ARRAY,
	TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY,
	TYPE_PACKED_FLOAT64_ARRAY,
	TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_VECTOR2_ARRAY,
	TYPE_PACKED_VECTOR3_ARRAY,
	TYPE_PACKED_VECTOR4_ARRAY,
	TYPE_PACKED_COLOR_ARRAY
]


static func is_array_type(value: Variant) -> bool:
	return is_type_array(typeof(value))


static func is_type_array(type :int) -> bool:
	return  type in ARRAY_TYPES


## Filters an array by given value[br]
## If the given value not an array it returns null, will remove all occurence of given value.
static func filter_value(array: Variant, value: Variant) -> Variant:
	if not is_array_type(array):
		return null

	@warning_ignore("unsafe_method_access")
	var filtered_array: Variant = array.duplicate()
	@warning_ignore("unsafe_method_access")
	var index: int = filtered_array.find(value)
	while index != -1:
		@warning_ignore("unsafe_method_access")
		filtered_array.remove_at(index)
		@warning_ignore("unsafe_method_access")
		index = filtered_array.find(value)
	return filtered_array


## Groups an array by a custom key selector
## The function should take an item and return the group key
static func group_by(array: Array, key_selector: Callable) -> Dictionary:
	var result := {}

	for item: Variant in array:
		var group_key: Variant = key_selector.call(item)
		var values: Array = result.get_or_add(group_key, [])
		values.append(item)

	return result


## Erases a value from given array by using equals(l,r) to find the element to erase
static func erase_value(array :Array, value :Variant) -> void:
	for element :Variant in array:
		if GdObjects.equals(element, value):
			array.erase(element)


## Scans for the array build in type on a untyped array[br]
## Returns the buildin type by scan all values and returns the type if all values has the same type.
## If the values has different types TYPE_VARIANT is returend
static func scan_typed(array :Array) -> int:
	if array.is_empty():
		return TYPE_NIL
	var actual_type := GdObjects.TYPE_VARIANT
	for value :Variant in array:
		var current_type := typeof(value)
		if not actual_type in [GdObjects.TYPE_VARIANT, current_type]:
			return GdObjects.TYPE_VARIANT
		actual_type = current_type
	return actual_type


## Converts given array into a string presentation.[br]
## This function is different to the original Godot str(<array>) implementation.
## The string presentaion contains fullquallified typed informations.
##[br]
## Examples:
## 	[codeblock]
##		# will result in PackedString(["a", "b"])
## 		GdArrayTools.as_string(PackedStringArray("a", "b"))
##		# will result in PackedString(["a", "b"])
##		GdArrayTools.as_string(PackedColorArray(Color.RED, COLOR.GREEN))
## 	[/codeblock]
static func as_string(elements: Variant, encode_value := true) -> String:
	var delemiter := ", "
	if elements == null:
		return "<null>"
	@warning_ignore("unsafe_cast")
	if (elements as Array).is_empty():
		return "<empty>"
	var prefix := _typeof_as_string(elements) if encode_value else ""
	var formatted := ""
	var index := 0
	for element :Variant in elements:
		if max_elements != -1 and index > max_elements:
			return prefix + "[" + formatted + delemiter + "...]"
		if formatted.length() > 0 :
			formatted += delemiter
		formatted += GdDefaultValueDecoder.decode(element) if encode_value else str(element)
		index += 1
	return prefix + "[" + formatted + "]"


static func has_same_content(current: Array, other: Array) -> bool:
	if current.size() != other.size(): return false
	for element: Variant in current:
		if not other.has(element): return false
		if current.count(element) != other.count(element): return false
	return true


static func _typeof_as_string(value :Variant) -> String:
	var type := typeof(value)
	# for untyped array we retun empty string
	if type == TYPE_ARRAY:
		return ""
	return GdObjects.typeof_as_string(value)
