class_name LevelData
extends RefCounted

static func validate_schema(schema_path: String, level_path: String) -> Dictionary:
	var schema_data := _load_json(schema_path)
	if schema_data.is_empty():
		return {"is_valid": false, "errors": ["schema load failed"]}

	var level_data := _load_json(level_path)
	if level_data.is_empty():
		return {"is_valid": false, "errors": ["level load failed"]}

	return {"is_valid": true, "errors": []}

static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var text := file.get_as_text()
	var data := JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	return data
