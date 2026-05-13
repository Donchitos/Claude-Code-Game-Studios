## Loads level data and validates it with minimal schema checks.
## ADR: docs/architecture/ADR-0001-level-data-schema-validation.md
class_name LevelData
extends RefCounted

## Validates schema and level JSON by verifying both files load and pass checks.
static func validate_schema(schema_path: String, level_path: String) -> Dictionary:
	var schema_data := _load_json(schema_path)
	if schema_data.is_empty():
		return {"is_valid": false, "errors": ["schema load failed"]}

	var level_data := _load_json(level_path)
	if level_data.is_empty():
		return {"is_valid": false, "errors": ["level load failed"]}

	return validate_schema_data(schema_data, level_data)

## Loads level JSON data from disk.
static func load(path: String) -> Dictionary:
	return _load_json(path)

## Saves level JSON data to disk.
static func save(path: String, level: Dictionary) -> void:
	var base_dir := path.get_base_dir()
	if base_dir != "":
		DirAccess.make_dir_recursive_absolute(base_dir)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return

	var text := JSON.stringify(level, "\t")
	file.store_string(text)

## Validates schema and level data without file I/O.
static func validate_schema_data(schema_data: Dictionary, level_data: Dictionary) -> Dictionary:
	var errors: Array = []
	var required := schema_data.get("required", [])
	for key in required:
		if not level_data.has(key):
			errors.append("missing required: %s" % key)

	var properties := schema_data.get("properties", {})
	for key in properties.keys():
		if not level_data.has(key):
			continue
		var expected_type := properties[key].get("type", "")
		if expected_type == "" :
			continue
		if not _matches_type(level_data[key], expected_type):
			errors.append("type mismatch: %s" % key)
			continue
		if expected_type == "integer" or expected_type == "number":
			var minimum := properties[key].get("minimum", null)
			if minimum != null and float(level_data[key]) < float(minimum):
				errors.append("below minimum: %s" % key)

	return {"is_valid": errors.is_empty(), "errors": errors}

static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var text := file.get_as_text()
	var data := JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	return data

static func _matches_type(value: Variant, expected_type: String) -> bool:
	match expected_type:
		"string":
			return typeof(value) == TYPE_STRING
		"number":
			return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
		"integer":
			return typeof(value) == TYPE_INT
		"array":
			return typeof(value) == TYPE_ARRAY
		"object":
			return typeof(value) == TYPE_DICTIONARY
		"boolean":
			return typeof(value) == TYPE_BOOL
		_:
			return true
