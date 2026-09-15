extends SceneTree
const Schema = preload("res://src/data/steam_save_domains.gd")
const Campaign = preload("res://src/data/steam_campaign_schema.gd")
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const LIMITS = {"max_bytes": 8000000, "max_depth": 48}
var checks := 0
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _run() -> void:
	var f: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/steam/domains-fixture.json"))
	var cf: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/steam/campaign-fixture.json"))
	var campaign := Campaign.new()
	check(campaign.initialize(cf.definition, cf.catalog, LIMITS).status == "OK", "campaign")
	f.context.offer_max = int(f.context.offer_max)
	f.context.loadout_max = int(f.context.loadout_max)
	f.context.refresh_max = int(f.context.refresh_max)
	# Explicit synthetic owner; does not install or imply a Mission runtime.
	f.context.owner_validators = {"LEGACY_STAGE": func(owner: Dictionary, tick: String) -> Dictionary:
		return {"status": "OK"} if owner.payload == {"test_tick": tick} else {"status": "INVALID"}}
	f.context.complete_validator = null
	f.context.preparation_validator = func(_run: Dictionary, _domains: Dictionary) -> Dictionary: return {"status": "OK"}
	var schema := Schema.new()
	check(schema.initialize(campaign, f.context, LIMITS).status == "OK", "initialize five schemas")
	check(schema.validate(f.domains, f.root).status == "OK", "seven domains")
	for name: String in Schema.KEYS:
		var bad: Dictionary = f.domains.duplicate(true)
		bad.erase(name)
		check(schema.validate(bad, f.root).status != "OK", "missing domain " + name)
	for name: String in Schema.FIVE:
		for key: String in f.domains[name].payload:
			var bad: Dictionary = f.domains.duplicate(true)
			bad[name].payload.erase(key)
			check(schema.validate(bad, f.root).status != "OK", "missing field " + name + key)
		for mutation: Variant in [null, {}, [], "2", true, 3, 3.0]:
			var bad: Dictionary = f.domains.duplicate(true)
			bad[name] = mutation
			check(schema.validate(bad, f.root).status != "OK", "wrong domain type")
	var d: Dictionary = f.domains.duplicate(true)
	d.records.payload.spirit_stones = {"unspent": Codec.U63_MAX, "earned": "0", "spent": "1"}
	check(schema.validate(d, f.root).status == "INVALID", "checked ledger overflow")
	d = f.domains.duplicate(true)
	d.preparation.payload.seed_ledgers[0].available = "9"
	d.preparation.payload.seed_ledgers[0].earned = "9"
	d.preparation.payload.legacy_starter_claimed = true
	check(schema.validate(d, f.root).status == "OK", "legacy inventory retained while prep chapter locked")
	d.user_settings.payload.volume_percent.master = "101"
	check(schema.validate(d, f.root).status == "INVALID", "volume range")
	d.user_settings.payload.volume_percent.master = "100"
	d.user_settings.payload.locale_id = "unknown"
	check(schema.validate(d, f.root).status == "INVALID", "locale catalog")
	d = f.domains.duplicate(true)
	d.current_run.payload.run = f.prepared_run.duplicate(true)
	d.preparation.payload.active_reservation = {"receipt": f.prepared_run.prep_receipt.duplicate(true), "state": "RESERVED", "recovery_revision": "0"}
	d.preparation.payload.next_preparation_id = "2"
	check(schema.validate(d, f.root).status == "OK", "PREPARED complete reservation")
	check(Schema.cancellation_allowed(d.current_run.payload.run.preparation_checkpoint), "pre-offer cancel")
	d.current_run.payload.run.preparation_checkpoint.offer_revision = "1"
	d.current_run.payload.run.preparation_checkpoint.offer_rows = [{"candidate_id": "TEST-C1", "skill_id": "TEST-S1", "rank": "1"}]
	d.current_run.payload.run.preparation_checkpoint.offer_hash = Codec.encode(d.current_run.payload.run.preparation_checkpoint.offer_rows, LIMITS).sha256
	check(schema.validate(d, f.root).status == "OK", "durable offer")
	check(not Schema.cancellation_allowed(d.current_run.payload.run.preparation_checkpoint), "visible offer cannot reroll via cancel")
	d.current_run.payload.run.run_status = "SUSPENDED"
	d.preparation.payload.active_reservation.state = "CONSUMED"
	d.current_run.payload.run.checkpoint = {"checkpoint_seq": "1", "active_tick": "12", "owner_snapshots": [{"owner_id": "LEGACY_STAGE", "schema": "1", "revision": "1", "payload": {"test_tick": "12"}}]}
	check(schema.validate(d, f.root).status == "INVALID", "unresolved preactive selection rejected")
	d.current_run.payload.run.preparation_checkpoint.selected_candidate_id = "TEST-C1"
	d.current_run.payload.run.preparation_checkpoint.choice_command_id = "6".repeat(32)
	d.current_run.payload.run.preparation_checkpoint.handoff_revision = "1"
	check(schema.validate(d, f.root).status == "OK", "strict registered checkpoint")
	d.current_run.payload.run.checkpoint.owner_snapshots = []
	check(schema.validate(d, f.root).status == "UNSUPPORTED_SCHEMA", "missing owner rejected")
	var p: Dictionary = f.domains.progression.payload.duplicate(true)
	p.domain_revision = "2"
	p.unspent_pages = "6"
	p.earned_pages_total = "10"
	p.spent_pages_total = "4"
	p.upgrade_sequence = "1"
	p.next_purchase_id = "2"
	p.branch_levels.QINGYUAN = "1"
	p.last_purchase_receipt = {"kind": "V2", "purchase_id": "1", "branch_id": "QINGYUAN", "from_level": "0", "to_level": "1", "cost_pages": "4", "balance_before": "4", "balance_after": "0", "base_domain_revision": "0", "next_domain_revision": "1", "request_hash": "a".repeat(64)}
	var income: Dictionary = f.domains.duplicate(true)
	income.progression.payload = p
	check(schema.validate(income, f.root).status == "OK", "income preserves historical purchase receipt")
	income.progression.payload.spent_pages_total = "0"
	income.progression.payload.earned_pages_total = "6"
	check(schema.validate(income, f.root).status == "INVALID", "historical purchase must be covered by lifetime spent")
	print("STEAM_DOMAINS_TEST checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
