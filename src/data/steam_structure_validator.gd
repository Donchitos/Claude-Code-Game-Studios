class_name SteamStructureValidator
extends RefCounted
## Restricted Draft 2020-12 structural evaluator for the generated Steam files.
## Semantic owner validation is compulsory after this structural pass.
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")

## Rejects unknown JSON fields/types; supports only this generator's vocabulary.
static func valid(value: Variant, rule: Dictionary, definitions: Dictionary) -> bool:
	if rule.has("$ref"):
		var key: String = rule["$ref"].trim_prefix("#/$defs/")
		return definitions.has(key) and valid(value, definitions[key], definitions)
	if rule.has("anyOf"):
		for branch: Dictionary in rule.anyOf:
			if valid(value, branch, definitions):
				return true
		return false
	if rule.has("const"):
		return typeof(value) == typeof(rule.const) and value == rule.const
	if rule.has("enum"):
		for option: Variant in rule.enum:
			if typeof(value) == typeof(option) and value == option:
				return true
		return false
	match rule.get("type", ""):
		"null": return value == null
		"boolean": return value is bool
		"string":
			if not value is String or value.length() < int(rule.get("minLength", 0)):
				return false
			if rule.has("pattern"):
				var expression := RegEx.new()
				if expression.compile(rule.pattern) != OK or expression.search(value) == null:
					return false
			return rule.get("format", "") != "steam-f64" or Codec.hex_to_float(value).status == "OK"
		"array":
			if not value is Array or value.size() > int(rule.get("maxItems", 9223372036854775807)) or value.size() < int(rule.get("minItems", 0)):
				return false
			var seen: Array = []
			for item: Variant in value:
				if not valid(item, rule.items, definitions) or (rule.get("uniqueItems", false) and seen.has(item)):
					return false
				seen.append(item)
			return true
		"object":
			if not value is Dictionary:
				return false
			if not rule.has("properties"):
				return true # The owner registry validates the two explicitly dynamic records.
			if value.size() != rule.properties.size():
				return false
			for key: String in rule.properties:
				if not value.has(key) or not valid(value[key], rule.properties[key], definitions):
					return false
			return true
	return false
