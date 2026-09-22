class_name CampaignCatalog
extends RefCounted
## Validated offline content for the independent CAMPAIGN_GAMEPLAY_V1 profile.

const Encounter = preload("res://src/campaign/campaign_encounter.gd")
const PATH := "res://assets/config/campaign_game.json"
const COUNTS := {"chapters": 8, "missions": 64, "characters": 8, "skills": 24,
	"passives": 24, "evolutions": 16, "enemies": 24, "elites": 8, "bosses": 9,
	"pills": 12, "events": 24, "challenges": 24, "achievements": 60}
const MODES := ["sword", "fan", "orbit", "fireball", "flame", "meteor", "disc",
	"boomerang", "shield", "turret", "drone", "stomp", "chain", "lightning",
	"return_arc", "roots", "thorns", "spores", "ice_arrow", "frost", "winter", "ink", "seal", "void"]
const BEHAVIORS := ["chase", "spitter", "flanker", "trail", "strafe", "charger", "crab", "jet", "burrow", "reflector", "fan_shooter", "bouncer", "slider", "buffer", "spike_line", "exploder", "rooter", "decoy", "diver", "anchor", "barrier", "shield", "channeler", "absorber"]
const PATTERNS := ["pounce", "eruption", "cross_tide", "mirror", "dive", "spore_tide", "anchors", "seals", "nexus"]
const RULE_REFERENCES := {"character_win": "characters", "character_wins": "characters", "evolution_id": "evolutions", "evolution_ids": "evolutions", "challenge_win": "challenges", "challenge_wins": "challenges"}
const KINDS := ["SURVIVE", "BREAK", "CLEANSE", "HUNT", "ESCORT", "BOSS"]

## Returns the raw validated catalog, adding SHA256 of its exact UTF-8 file bytes.
## Missing, unreadable, malformed or invalid content fails closed with {}.
static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_as_text()
	var parser := JSON.new()
	if parser.parse(raw) != OK or not parser.data is Dictionary:
		return {}
	var data: Dictionary = parser.data
	if not validate(data).is_empty():
		return {}
	data["content_hash"] = raw.sha256_text()
	return data

## Lists errors without changing data. Derived content_hash is deliberately ignored.
static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if data.get("schema") != 1:
		errors.append("schema must be 1")
	for key in ["title", "title_en"]:
		if not data.get(key) is String or str(data.get(key, "")).is_empty():
			errors.append("missing title: " + key)
	var ids: Dictionary = {}
	for kind: String in COUNTS:
		if not data.get(kind) is Array:
			errors.append("missing collection: " + kind)
			continue
		if data[kind].size() != COUNTS[kind]:
			errors.append("wrong count: " + kind)
		for row: Variant in data[kind]:
			if not row is Dictionary:
				errors.append("non-object row: " + kind)
				continue
			for field in ["id", "name", "name_en", "description", "description_en"]:
				if not row.get(field) is String or str(row.get(field, "")).is_empty():
					errors.append(kind + " missing text: " + field)
			var id := str(row.get("id", ""))
			if ids.has(id):
				errors.append("duplicate id: " + id)
			ids[id] = true
			if not _integer(row.get("unlock_after"), 0, 64):
				errors.append("invalid unlock_after: " + id)
	# Structural errors must stop deeper validation; malformed user data never traps.
	if not errors.is_empty():
		return errors
	var scenes: Dictionary = {}
	for chapter: Dictionary in data.chapters:
		if not chapter.get("scene_ids") is Array or chapter.scene_ids.size() != 2:
			errors.append("chapter must have two scenes: " + chapter.id)
		else:
			for id: Variant in chapter.scene_ids:
				scenes[str(id)] = true
	var modes: Dictionary = {}
	for skill: Dictionary in data.skills:
		var mode := str(skill.get("mode", ""))
		if not mode in MODES or modes.has(mode):
			errors.append("invalid/duplicate skill mode: " + skill.id)
		modes[mode] = true
		for field in ["damage", "cooldown", "range", "radius", "duration"]:
			_positive(skill, field, errors)
		if not _integer(skill.get("count"), 1, 400) or not _number(skill.get("speed"), 0):
			errors.append("skill count/speed: " + skill.id)
		_color(skill, errors)
	var stats: Dictionary = {}
	for passive: Dictionary in data.passives:
		var stat := str(passive.get("stat", ""))
		if stat.is_empty() or stats.has(stat):
			errors.append("invalid/duplicate passive stat: " + passive.id)
		stats[stat] = true
		_positive(passive, "amount", errors)
	for character: Dictionary in data.characters:
		_ref(data, "skills", character.get("start_skill"), errors)
		for field in ["hp_multiplier", "speed_multiplier", "damage_multiplier", "passive_amount"]:
			_positive(character, field, errors)
		if not stats.has(str(character.get("passive_stat", ""))):
			errors.append("unknown character passive")
		_color(character, errors)
	for evolution: Dictionary in data.evolutions:
		_ref(data, "skills", evolution.get("skill_id"), errors)
		_ref(data, "passives", evolution.get("passive_id"), errors)
		_positive(evolution, "effect_multiplier", errors)
		for pair in [["skills", "skill_id"], ["passives", "passive_id"]]:
			var ingredient := lookup(data, pair[0], str(evolution.get(pair[1], "")))
			if not ingredient.is_empty() and evolution.unlock_after < ingredient.unlock_after:
				errors.append("evolution unlock precedes ingredient")
	var behaviors: Dictionary = {}
	for kind in ["enemies", "elites", "bosses"]:
		for enemy: Dictionary in data[kind]:
			for field in ["hp", "speed", "radius", "damage"]:
				_positive(enemy, field, errors)
			_color(enemy, errors)
			if kind == "bosses":
				if not enemy.get("pattern") is String or not enemy.get("phase_patterns") is Array or enemy.get("phase_patterns", []).size() != 3:
					errors.append("boss patterns: " + enemy.id)
				else:
					if not enemy.pattern in PATTERNS:
						errors.append("unknown boss pattern")
					for pattern: Variant in enemy.phase_patterns:
						if not pattern in PATTERNS:
							errors.append("unknown boss phase pattern")
			else:
				if not enemy.get("behavior") in BEHAVIORS:
					errors.append("enemy behavior: " + enemy.id)
				if kind == "enemies":
					if behaviors.has(str(enemy.get("behavior", ""))):
						errors.append("duplicate enemy behavior")
					behaviors[str(enemy.get("behavior", ""))] = true
				_positive(enemy, "projectile_speed", errors)
				_positive(enemy, "attack_cooldown", errors)
	for index in range(data.missions.size()):
		var mission: Dictionary = data.missions[index]
		var label := str(mission.id)
		if mission.get("ordinal") != index + 1 or mission.unlock_after != index or mission.get("chapter") != int(index / 8) + 1 or mission.get("theme") != int(index / 8):
			errors.append("mission order/unlock: " + label)
		var previous: String = "START" if index == 0 else data.missions[index - 1].id
		if mission.get("prerequisite_id") != previous:
			errors.append("mission prerequisite: " + label)
		if not str(mission.get("kind", "")) in KINDS or not str(mission.get("order_mode", "")) in ["FIXED", "PLAYER_CHOICE"]:
			errors.append("mission kind/order: " + label)
		if not scenes.has(str(mission.get("scene_id", ""))):
			errors.append("mission scene: " + label)
		for field in ["briefing", "briefing_en", "success_text", "success_text_en"]:
			if not mission.get(field) is String or str(mission.get(field, "")).is_empty():
				errors.append("mission text: " + label + "/" + field)
		for field in ["timeout_seconds", "target_seconds", "target_hp", "target_radius", "hold_seconds", "escort_radius", "escort_hp", "escort_speed", "cleanse_enemy_radius"]:
			_positive(mission, field, errors)
		if not _integer(mission.get("target_count"), 1, 12) or not _integer(mission.get("reward"), 0, 100000):
			errors.append("mission count/reward: " + label)
		var count := int(mission.get("target_count", 0)) if _number(mission.get("target_count"), 0) else 0
		for field in ["target_positions", "target_ids", "enemy_ids", "first_grants"]:
			if not mission.get(field) is Array:
				errors.append("mission array: " + label + "/" + field)
		if not errors.is_empty():
			continue
		if mission.target_positions.size() != count or mission.target_ids.size() != count:
			errors.append("mission targets: " + label)
		var unique: Dictionary = {}
		for id: Variant in mission.target_ids:
			if not id is String or str(id).is_empty() or unique.has(id):
				errors.append("target id: " + label)
			unique[id] = true
		for point: Variant in mission.target_positions:
			if not _point(point):
				errors.append("target position: " + label)
		if mission.enemy_ids.is_empty():
			errors.append("empty enemy pool: " + label)
		for id: Variant in mission.enemy_ids:
			_ref(data, "enemies", id, errors)
		if mission.kind == "BOSS":
			_ref(data, "bosses", mission.get("boss_id"), errors)
			if mission.target_ids != [mission.boss_id]:
				errors.append("boss target identity: " + label)
		elif mission.get("boss_id") != "":
			errors.append("non-boss has boss_id: " + label)
		for id: Variant in mission.first_grants:
			if not ids.has(str(id)):
				errors.append("unknown first grant: " + str(id))
		if mission.timeout_seconds <= mission.target_seconds:
			errors.append("timeout before target: " + label)
	for chapter_index in range(data.chapters.size()):
		var chapter: Dictionary = data.chapters[chapter_index]
		for mission_index in range(chapter_index * 8, chapter_index * 8 + 8):
			if not data.missions[mission_index].get("scene_id", "") in chapter.get("scene_ids", []):
				errors.append("mission scene outside chapter")
	for pill: Dictionary in data.pills:
		if not pill.get("stat") is String or not _integer(pill.get("cost"), 0, 100000):
			errors.append("pill stat/cost: " + pill.id)
		_positive(pill, "amount", errors)
	for event: Dictionary in data.events:
		for choice in ["safe", "risk"]:
			if not event.get(choice) is Dictionary:
				errors.append("event choice: " + event.id)
				continue
			for field in ["reward", "damage", "pressure"]:
				if not _number(event[choice].get(field), 0):
					errors.append("event amount: " + event.id)
	for kind in ["challenges", "achievements"]:
		for row: Dictionary in data[kind]:
			if not row.get("rule") is Dictionary:
				errors.append("missing rule: " + row.id)
			elif not row.rule.get("stat") is String or not _number(row.rule.get("target"), 1):
				errors.append("invalid rule: " + row.id)
			else:
				var stat := str(row.rule.stat)
				if RULE_REFERENCES.has(stat):
					_ref(data, RULE_REFERENCES[stat], row.rule.get("id"), errors)
			if kind == "challenges":
				_ref(data, "missions", row.get("mission_id"), errors)
				for field in ["enemy_multiplier", "hazard_multiplier"]:
					_positive(row, field, errors)
				if not row.get("allow_pills") is bool or not _integer(row.get("max_skills"), 1, 4) or not _integer(row.get("reward"), 0, 100000):
					errors.append("invalid challenge restrictions: " + row.id)
	if not data.get("tuning") is Dictionary:
		errors.append("missing tuning")
	else:
		var gates: Variant = data.tuning.get("progression_unlock_completed")
		if not gates is Array or gates.size() != 5:
			errors.append("invalid progression gates")
		else:
			var previous := -1
			for gate in gates:
				if not _integer(gate, 0, 64) or int(gate) < previous:
					errors.append("invalid progression gates")
				else:
					previous = int(gate)
		for field in ["enemy_cap", "projectile_cap", "pickup_cap", "player_hp", "player_speed", "player_damage", "spawn_interval", "xp_base", "xp_step", "save_interval", "mission_enemy_scaling"]:
			_positive(data.tuning, field, errors)
		var size: Variant = data.tuning.get("arena_half_size")
		if not size is Array or size.size() != 2 or size[0] != 960 or size[1] != 640:
			errors.append("arena dimensions")
	if errors.is_empty():
		for m in data.missions:
			if not Encounter.valid_definition(data,m): errors.append("invalid encounter/layout: " + str(m.id))
	return errors

## Finds a row by collection name and stable ID. Never resolves array positions.
static func lookup(data: Dictionary, kind: String, id: String) -> Dictionary:
	if not data.get(kind) is Array:
		return {}
	for row: Variant in data[kind]:
		if row is Dictionary and row.get("id") == id:
			return row
	return {}

## English locales prefer name_en; all other locales prefer name, with fallback.
static func localized(row: Dictionary, locale: String) -> String:
	var key := "name_en" if locale.to_lower().begins_with("en") else "name"
	var value := str(row.get(key, ""))
	return value if not value.is_empty() else str(row.get("name", row.get("name_en", row.get("id", ""))))

static func _number(value: Variant, minimum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return _number(value, minimum) and float(value) <= maximum and float(value) == floorf(float(value))

static func _positive(row: Dictionary, field: String, errors: Array[String]) -> void:
	if not _number(row.get(field), 0.000001):
		errors.append("positive number required: " + str(row.get("id", "tuning")) + "/" + field)

static func _ref(data: Dictionary, kind: String, id: Variant, errors: Array[String]) -> void:
	if not id is String or lookup(data, kind, str(id)).is_empty():
		errors.append("unknown reference: " + kind + "/" + str(id))

static func _point(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	return _number(value[0], -959) and _number(value[1], -639) and float(value[0]) <= 959 and float(value[1]) <= 639

static func _color(row: Dictionary, errors: Array[String]) -> void:
	var value := str(row.get("color", ""))
	if value.length() != 7 or not value.begins_with("#") or not value.substr(1).is_valid_hex_number():
		errors.append("invalid color: " + str(row.get("id", "")))
