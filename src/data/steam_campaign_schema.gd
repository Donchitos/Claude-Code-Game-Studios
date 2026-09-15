class_name SteamCampaignSchema
extends RefCounted
## ADR-0006 / campaign-flow.md validation only. Config must supply already
## verified MissionDefinition hashes and content IDs; no CSV/runtime import.

const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const MISSION_COUNT := 64 # Version 1 product schema: eight chapters of eight.
const MISSIONS_PER_CHAPTER := 8
const DEFINITION_FIELDS := ["schema", "content_revision", "content_hash", "missions"]
const ROW_FIELDS := ["mission_id", "chapter_id", "ordinal", "prerequisite_id_or_null", "mission_definition_hash", "first_grants"]
const CATALOG_FIELDS := ["content_revision", "content_hash", "mission_hashes", "unlock_ids", "initial_unlock_ids", "prep_unlock_ids"]
const CAMPAIGN_FIELDS := ["schema", "domain_revision", "completed_mission_ids", "ending_seen"]
const UNLOCK_FIELDS := ["schema", "domain_revision", "unlocked_content_ids"]

var _ready := false
var _missions: Array = []
var _catalog: Dictionary = {}
var _limits: Dictionary = {}

## Validates the entire definition before retaining an immutable private copy.
## This accepts schema data, not a playable mission profile or production budget.
func initialize(definition: Variant, catalog: Variant, limits: Dictionary) -> Dictionary:
	if _ready:
		return _error("ALREADY_INITIALIZED", "$")
	var encoded := Codec.encode([definition, catalog], limits)
	if encoded.status != "OK":
		return _error(encoded.status, "$")
	if not _fields(definition, DEFINITION_FIELDS) or not _fields(catalog, CATALOG_FIELDS):
		return _error("INVALID", "definition/catalog")
	if definition.schema != "1":
		return _error("UNSUPPORTED_SCHEMA", "definition.schema")
	if not _valid_catalog(catalog) or definition.content_revision != catalog.content_revision \
		or definition.content_hash != catalog.content_hash:
		return _error("INVALID", "content_binding")
	if not definition.missions is Array or definition.missions.size() != MISSION_COUNT:
		return _error("INVALID", "missions")
	var result := _validate_rows(definition.missions, catalog)
	if result.status != "OK":
		return result
	_missions = definition.missions.duplicate(true)
	_catalog = catalog.duplicate(true)
	_limits = limits.duplicate(true)
	_ready = true
	return {"status": "OK"}

## Validates the campaign/unlock after-image pair including prefix, grant and
## ending invariants. Success makes no state changes and publishes no rewards.
func validate_domains(campaign: Variant, unlocks: Variant) -> Dictionary:
	if not _ready:
		return _error("NOT_INITIALIZED", "$")
	var encoded := Codec.encode([campaign, unlocks], _limits)
	if encoded.status != "OK":
		return _error(encoded.status, "domains")
	for entry: Array in [[campaign, CAMPAIGN_FIELDS, "campaign"], [unlocks, UNLOCK_FIELDS, "unlocks"]]:
		var result := _validate_wrapper(entry[0], entry[1], entry[2])
		if result.status != "OK":
			return result
	var cp: Dictionary = campaign.payload
	var up: Dictionary = unlocks.payload
	if not cp.completed_mission_ids is Array or not cp.ending_seen is bool \
		or not _sorted_ids(up.unlocked_content_ids):
		return _error("INVALID", "domain_fields")
	var completed: Array = cp.completed_mission_ids
	if completed.size() > MISSION_COUNT or (cp.ending_seen and completed.size() != MISSION_COUNT):
		return _error("INVALID", "campaign.ending/prefix")
	for i: int in range(completed.size()):
		if completed[i] != _missions[i].mission_id:
			return _error("INVALID", "campaign.completed_mission_ids")
	return _validate_unlocks(completed.size(), up.unlocked_content_ids)

## Campaign validation alone cannot admit Save v2. WP04b supplies the five
## domain structures separately; full owner/protocol/budget evidence is still open.
func production_admission() -> Dictionary:
	return {"status": "UNSUPPORTED_SCHEMA", "missing_evidence": ["commercial_owner_adapters", "complete_transaction", "measured_commercial_budget", "windows_durability"], "production_enabled": false}

static func _fields(value: Variant, names: Array) -> bool:
	if not value is Dictionary or value.size() != names.size():
		return false
	for name: String in names:
		if not value.has(name):
			return false
	return true

static func _valid_catalog(catalog: Dictionary) -> bool:
	var revision := Codec.read_u63(catalog.content_revision)
	if revision.status != "OK" or revision.value < 1 or not Codec.is_hex(catalog.content_hash, 64):
		return false
	if not catalog.mission_hashes is Dictionary or catalog.mission_hashes.size() != MISSION_COUNT:
		return false
	for field: String in ["unlock_ids", "initial_unlock_ids", "prep_unlock_ids"]:
		if not _sorted_ids(catalog[field]):
			return false
	if catalog.prep_unlock_ids.is_empty():
		return false
	for id: String in catalog.initial_unlock_ids + catalog.prep_unlock_ids:
		if not catalog.unlock_ids.has(id):
			return false
	for id: String in catalog.prep_unlock_ids:
		if catalog.initial_unlock_ids.has(id):
			return false
	return true

static func _validate_rows(rows: Array, catalog: Dictionary) -> Dictionary:
	for i: int in range(MISSION_COUNT):
		var row: Variant = rows[i]
		if not _fields(row, ROW_FIELDS):
			return _error("INVALID", "missions[%d]" % i)
		var chapter: int = i / MISSIONS_PER_CHAPTER + 1
		var mid := "S1-M%02d-%02d" % [chapter, i % MISSIONS_PER_CHAPTER + 1]
		if row.mission_id != mid or row.chapter_id != "S1-CH%02d" % chapter or row.ordinal != str(i + 1):
			return _error("INVALID", "missions[%d].identity" % i)
		var previous: Variant = null if i == 0 else rows[i - 1].mission_id
		if row.prerequisite_id_or_null != previous or not Codec.is_hex(row.mission_definition_hash, 64) \
			or row.mission_definition_hash != catalog.mission_hashes.get(mid):
			return _error("INVALID", "missions[%d].binding" % i)
		if not _sorted_ids(row.first_grants):
			return _error("INVALID", "missions[%d].first_grants" % i)
		for grant: String in row.first_grants:
			if not catalog.unlock_ids.has(grant):
				return _error("INVALID", "missions[%d].unknown_grant" % i)
			if catalog.prep_unlock_ids.has(grant) and i != 2:
				return _error("INVALID", "missions[%d].prep_grant" % i)
	for grant: String in catalog.prep_unlock_ids:
		if not rows[2].first_grants.has(grant):
			return _error("INVALID", "missions[2].missing_prep_grant")
	return {"status": "OK"}

static func _validate_wrapper(value: Variant, fields: Array, path: String) -> Dictionary:
	if not _fields(value, ["schema", "payload"]):
		return _error("INVALID", path)
	if value.schema != "1":
		return _error("UNSUPPORTED_SCHEMA", path + ".schema")
	if not _fields(value.payload, fields):
		return _error("INVALID", path + ".payload")
	if value.payload.schema != "1":
		return _error("UNSUPPORTED_SCHEMA", path + ".payload.schema")
	if Codec.read_u63(value.payload.domain_revision).status != "OK":
		return _error("INVALID", path + ".payload.domain_revision")
	return {"status": "OK"}

func _validate_unlocks(completed: int, actual: Array) -> Dictionary:
	var expected: Array = _catalog.initial_unlock_ids.duplicate()
	var future: Array = []
	for i: int in range(_missions.size()):
		if i < completed:
			expected.append_array(_missions[i].first_grants)
		else:
			future.append_array(_missions[i].first_grants)
	for id: String in expected:
		if not actual.has(id):
			return _error("INVALID", "unlocks.missing_committed_grant")
	for id: String in actual:
		if not _catalog.unlock_ids.has(id) or (future.has(id) and not expected.has(id)):
			return _error("INVALID", "unlocks.unknown/premature_grant")
	return {"status": "OK"}

static func _sorted_ids(value: Variant) -> bool:
	if not value is Array:
		return false
	var previous := ""
	for id: Variant in value:
		if not id is String or id.is_empty() or id <= previous:
			return false
		for i: int in range(id.length()):
			var c: int = id.unicode_at(i)
			if c > 127:
				return false
		previous = id
	return true

static func _error(status: String, path: String) -> Dictionary:
	return {"status": status, "path": path}
