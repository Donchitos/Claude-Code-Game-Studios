extends SceneTree

const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const Schema = preload("res://src/data/steam_campaign_schema.gd")
const LIMITS := {"max_bytes": 131072, "max_depth": 32} # test-only bounds
var checks := 0
var failures := 0

func _initialize() -> void:
	var golden: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/steam/codec-golden.json"))
	for vector: Dictionary in golden:
		var encoded: Dictionary = Codec.encode(vector.value, LIMITS)
		_check(encoded.status == "OK" and encoded.text == vector.canonical and encoded.sha256 == vector.sha256, "Python canonical+hash oracle")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/steam/campaign-fixture.json"))
	var schema := Schema.new()
	_check(schema.initialize(fixture.definition, fixture.catalog, LIMITS).status == "OK", "64-row definition")
	var payload := {"schema": "1", "domain_revision": "0", "completed_mission_ids": [], "ending_seen": false}
	var unlocks := {"schema": "1", "domain_revision": "0", "unlocked_content_ids": ["TEST-START"]}
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "OK", "new campaign domains")
	payload.completed_mission_ids = ["S1-M01-02"]
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "INVALID", "non-prefix rejected")
	payload.completed_mission_ids = ["S1-M01-01"]
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "INVALID", "missing first grant rejected")
	unlocks.unlocked_content_ids = ["TEST-FIRST", "TEST-START"]
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "OK", "first grant exact")
	payload.ending_seen = true
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "INVALID", "premature ending")
	payload.ending_seen = false
	unlocks.unlocked_content_ids = ["TEST-FIRST", "TEST-PREP", "TEST-START"]
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "INVALID", "premature prep unlock")
	payload.completed_mission_ids = ["S1-M01-01", "S1-M01-02", "S1-M01-03"]
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "OK", "M01-03 prep grant")
	payload.domain_revision = "9223372036854775808"
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "INVALID", "revision overflow")
	payload.domain_revision = "1"
	var unknown := _wrap(payload)
	unknown.extra = null
	_check(schema.validate_domains(unknown, _wrap(unlocks)).status == "INVALID", "unknown wrapper field")
	unknown = _wrap(payload)
	unknown.schema = "2"
	_check(schema.validate_domains(unknown, _wrap(unlocks)).status == "UNSUPPORTED_SCHEMA", "future schema")
	_check(schema.validate_domains(null, _wrap(unlocks)).status == "INVALID", "missing wrapper")
	for mode: String in ["duplicate", "cycle", "short", "hash", "grant", "prep", "unknown", "numeric"]:
		var definition: Dictionary = fixture.definition.duplicate(true)
		match mode:
			"duplicate": definition.missions[1].mission_id = definition.missions[0].mission_id
			"cycle": definition.missions[0].prerequisite_id_or_null = definition.missions[63].mission_id
			"short": definition.missions.pop_back()
			"hash": definition.missions[0].mission_definition_hash = "0".repeat(64)
			"grant": definition.missions[0].first_grants = ["UNKNOWN"]
			"prep": definition.missions[0].first_grants.append("TEST-PREP")
			"unknown": definition.missions[0].extra = true
			"numeric": definition.missions[0].ordinal = 1
		_check(Schema.new().initialize(definition, fixture.catalog, LIMITS).status != "OK", "definition rejection " + mode)
	var shared_def: Dictionary = fixture.definition.duplicate(true)
	shared_def.missions[1].first_grants = ["TEST-FIRST"]
	var shared := Schema.new()
	_check(shared.initialize(shared_def, fixture.catalog, LIMITS).status == "OK", "repeated content grant allowed by union")
	var shared_campaign := {"schema": "1", "domain_revision": "1", "completed_mission_ids": ["S1-M01-01"], "ending_seen": false}
	var shared_unlocks := {"schema": "1", "domain_revision": "1", "unlocked_content_ids": ["TEST-FIRST", "TEST-START"]}
	_check(shared.validate_domains(_wrap(shared_campaign), _wrap(shared_unlocks)).status == "OK", "future repeated grant does not invalidate past unlock")
	var ascii_catalog: Dictionary = fixture.catalog.duplicate(true)
	ascii_catalog.unlock_ids.append("content.lower:one")
	ascii_catalog.unlock_ids.sort()
	_check(Schema.new().initialize(fixture.definition, ascii_catalog, LIMITS).status == "OK", "ASCII IDs not restricted to uppercase")
	var all_done := {"schema": "1", "domain_revision": "0", "completed_mission_ids": [], "ending_seen": false}
	var all_unlocks := {"schema": "1", "domain_revision": "0", "unlocked_content_ids": fixture.catalog.initial_unlock_ids.duplicate()}
	for count: int in range(65):
		_check(schema.validate_domains(_wrap(all_done), _wrap(all_unlocks)).status == "OK", "valid complete prefix %d" % count)
		if count < 64:
			all_done.completed_mission_ids.append(fixture.definition.missions[count].mission_id)
			for grant: String in fixture.definition.missions[count].first_grants:
				if not all_unlocks.unlocked_content_ids.has(grant):
					all_unlocks.unlocked_content_ids.append(grant)
			all_unlocks.unlocked_content_ids.sort()
	all_done.ending_seen = true
	_check(schema.validate_domains(_wrap(all_done), _wrap(all_unlocks)).status == "OK", "final ending legal")
	_check(Schema.new().validate_domains(_wrap(payload), _wrap(unlocks)).status == "NOT_INITIALIZED", "no use before validation")
	_check(schema.initialize(fixture.definition, fixture.catalog, LIMITS).status == "ALREADY_INITIALIZED", "no configuration replacement")
	var extra_catalog: Dictionary = fixture.catalog.duplicate(true)
	extra_catalog.extra = null
	_check(Schema.new().initialize(fixture.definition, extra_catalog, LIMITS).status == "INVALID", "unknown catalog field")
	var extra_payload := _wrap(payload)
	extra_payload.payload.extra = null
	_check(schema.validate_domains(extra_payload, _wrap(unlocks)).status == "INVALID", "unknown payload field")
	fixture.catalog.unlock_ids.clear()
	_check(schema.validate_domains(_wrap(payload), _wrap(unlocks)).status == "OK", "frozen catalog does not alias caller")
	_check(schema.production_admission().status == "UNSUPPORTED_SCHEMA", "missing recovery domains never enabled")
	print("STEAM_SCHEMA_TEST checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _wrap(payload: Dictionary) -> Dictionary:
	return {"schema": "1", "payload": payload.duplicate(true)}

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
