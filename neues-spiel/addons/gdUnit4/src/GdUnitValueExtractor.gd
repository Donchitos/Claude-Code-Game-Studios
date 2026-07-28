## This is the base interface for value extraction
class_name GdUnitValueExtractor
extends RefCounted


## Extracts a value by given implementation
func extract_value(value :Variant) -> Variant:
	push_error("Uninplemented func 'extract_value'")
	return value
