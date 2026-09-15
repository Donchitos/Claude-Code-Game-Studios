extends SceneTree
## ADR-0006 WP04c: checkpoint envelope contract, not a Steam release gate.
const Contract = preload("res://src/data/steam_recovery_contract.gd")
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const Domains = preload("res://src/data/steam_save_domains.gd")
const Campaign = preload("res://src/data/steam_campaign_schema.gd")
const Snapshot = preload("res://src/persistence/steam_battle_snapshot.gd")
const LIMITS = {"max_bytes": 8000000, "max_depth": 48}
var checks := 0
var failures := 0
var calls := 0
var preparation_calls := 0
var joint_calls := 0

class ProviderNode:
	extends Node
	func accept(_first: Dictionary, _second: Dictionary) -> Dictionary:
		return {"status": "OK"}


func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func semantic(owner: Dictionary, binding: Dictionary) -> Dictionary:
	calls += 1
	return {"status": "OK"} if owner.payload.state == {"tick": binding.active_tick} else {"status": "INVALID"}

func fixture() -> Dictionary:
	var binding := {"recovery_profile": "TEST_RECOVERY_V1", "profile_id": "1".repeat(32), "branch_id": "2".repeat(32), "run_seq": "1", "mission_id": "TEST-M1", "mission_definition_hash": "a".repeat(64), "config_hash": "b".repeat(64), "active_tick": "12"}
	var owners: Array = []
	var rules: Array = []
	for id: String in ["TEST-A", "TEST-B"]:
		var payload := {"binding": binding.duplicate(true), "state": {"tick": "12"}}
		owners.append({"owner_id": id, "schema": "1", "revision": "0", "payload": payload})
		rules.append({"owner_id": id, "schema": "1", "max_snapshot_bytes": str(Codec.encode(owners[-1], LIMITS).bytes), "state_shape": {"tick": "u63"}})
	var checkpoint := {"checkpoint_seq": "1", "active_tick": "12", "owner_snapshots": owners}
	var manifest := {"schema": "1", "scope": "TEST_ONLY", "recovery_profile": binding.recovery_profile, "mission_id": binding.mission_id, "mission_definition_hash": binding.mission_definition_hash, "config_hash": binding.config_hash, "max_checkpoint_bytes": str(Codec.encode(checkpoint, LIMITS).bytes), "owners": rules}
	return {"binding": binding, "checkpoint": checkpoint, "manifest": manifest}

func initialized(f: Dictionary, validators: Dictionary = {}) -> RefCounted:
	var contract := Contract.new()
	if validators.is_empty():
		validators = {"TEST-A": semantic, "TEST-B": semantic}
	check(contract.initialize(f.manifest, validators, LIMITS, joint).status == "OK", "initialize")
	return contract

func joint(cp: Dictionary, _binding: Dictionary) -> Dictionary:
	joint_calls += 1
	# Synthetic stand-in for Stage applied/pending revision consistency.
	if cp.owner_snapshots.size() == 2 and cp.owner_snapshots[0].revision != cp.owner_snapshots[1].revision:
		return {"status": "INVALID"}
	return {"status": "OK"}

func roomy(f: Dictionary) -> Dictionary:
	var value := f.duplicate(true)
	value.manifest.max_checkpoint_bytes = str(int(value.manifest.max_checkpoint_bytes) + 4096)
	for rule: Dictionary in value.manifest.owners:
		rule.max_snapshot_bytes = str(int(rule.max_snapshot_bytes) + 2048)
	return value

func _run() -> void:
	var f := fixture()
	var contract = initialized(f)
	check(contract.validate(f.checkpoint, f.binding).status == "OK", "exact byte limits accepted")
	check(calls == 2, "each semantic validator called once")
	check(contract.production_admission().production_enabled == false, "test ceilings never enable production")
	check(contract.initialize(f.manifest, {}, LIMITS, joint).status == "ALREADY_INITIALIZED", "immutable registration")
	contract = initialized(roomy(f))
	for field: String in f.binding:
		var bad: Dictionary = f.checkpoint.duplicate(true)
		bad.owner_snapshots[1].payload.binding[field] = "0"
		calls = 0
		check(contract.validate(bad, f.binding).status != "OK", "foreign binding " + field)
		check(calls == 0, "all metadata checked before callbacks " + field)
	for mutation: String in ["missing", "duplicate", "unknown", "schema", "revision", "tick", "seq", "extra", "payload_extra", "state_extra", "state_type", "oversize", "row_type"]:
		var bad: Dictionary = f.checkpoint.duplicate(true)
		match mutation:
			"missing": bad.owner_snapshots.pop_back()
			"duplicate": bad.owner_snapshots[1] = bad.owner_snapshots[0].duplicate(true)
			"unknown": bad.owner_snapshots[1].owner_id = "TEST-C"
			"schema": bad.owner_snapshots[1].schema = "2"
			"revision": bad.owner_snapshots[1].revision = "-1"
			"tick": bad.active_tick = "11"
			"seq": bad.checkpoint_seq = "0"
			"extra": bad["extra"] = true
			"payload_extra": bad.owner_snapshots[1].payload["extra"] = true
			"state_extra": bad.owner_snapshots[1].payload.state = {}
			"state_type": bad.owner_snapshots[1].payload.state.tick = "-1"
			"oversize": bad.owner_snapshots[1].payload.state.tick = "1".repeat(4096)
			"row_type": bad.owner_snapshots[1] = null
		calls = 0
		var expected := "INVALID"
		if mutation == "missing" or mutation == "schema":
			expected = "UNSUPPORTED_SCHEMA"
		if mutation == "oversize":
			expected = "TOO_LARGE"
		var result: Dictionary = contract.validate(bad, f.binding)
		check(result.get("status") == expected, "specific rejection " + mutation)
		if mutation == "extra":
			check(result.get("path") == "checkpoint", "string-key extra reaches closed checkpoint schema")
		if mutation == "payload_extra":
			check(result.get("path") == "TEST-B.binding/revision", "string-key extra reaches closed payload schema")
		check(calls == 0, "preflight " + mutation)
	var invalid: Dictionary = f.checkpoint.duplicate(true)
	invalid.owner_snapshots[1].payload.state.tick = "11"
	check(contract.validate(invalid, f.binding).status == "INVALID", "metadata is not semantic proof")
	for mutation: String in ["zero", "overflow", "numeric", "duplicate", "unsorted", "production", "missing", "unknown"]:
		var m: Dictionary = f.manifest.duplicate(true)
		match mutation:
			"zero": m.owners[0].max_snapshot_bytes = "0"
			"overflow": m.max_checkpoint_bytes = "9223372036854775808"
			"numeric": m.max_checkpoint_bytes = 4096
			"duplicate": m.owners[1].owner_id = m.owners[0].owner_id
			"unsorted": m.owners.reverse()
			"production": m.scope = "PRODUCTION"
			"missing": m.erase("owners")
			"unknown": m.unknown = false
		check(Contract.new().initialize(m, {"TEST-A": semantic, "TEST-B": semantic}, LIMITS, joint).status != "OK", "invalid config " + mutation)
	check(Contract.new().initialize(f.manifest, {"TEST-A": semantic}, LIMITS, joint).status == "UNSUPPORTED_SCHEMA", "absent provider")
	check(Contract.new().initialize(f.manifest, {"TEST-A": semantic, "TEST-B": semantic, "TEST-C": semantic}, LIMITS, joint).status != "OK", "extra provider")
	check(Contract.new().initialize(f.manifest, {"TEST-A": semantic, "TEST-B": semantic}, LIMITS, Callable()).status == "UNSUPPORTED_SCHEMA", "joint provider mandatory")
	var detached := fixture()
	var frozen = initialized(detached)
	detached.manifest.owners.pop_back()
	detached.checkpoint.owner_snapshots.pop_back()
	check(frozen.validate(detached.checkpoint, detached.binding).status != "OK", "cannot shrink installed contract via aliases")
	var tighter := fixture()
	tighter.manifest.owners[1].max_snapshot_bytes = str(int(tighter.manifest.owners[1].max_snapshot_bytes) - 1)
	check(initialized(tighter).validate(f.checkpoint, f.binding).status == "TOO_LARGE", "owner required minus one")
	tighter = fixture()
	tighter.manifest.max_checkpoint_bytes = str(int(tighter.manifest.max_checkpoint_bytes) - 1)
	check(initialized(tighter).validate(f.checkpoint, f.binding).status == "TOO_LARGE", "checkpoint required minus one")
	# Providers receive detached copies and cannot rewrite this or later checks.
	var mutator: Callable = func(owner: Dictionary, binding: Dictionary) -> Dictionary:
		owner.payload.state.tick = "99"
		binding.active_tick = "99"
		return {"status": "OK"}
	var before := f.duplicate(true)
	check(initialized(f, {"TEST-A": mutator, "TEST-B": semantic}).validate(f.checkpoint, f.binding).status == "OK", "detached callbacks")
	check(f == before, "caller data unchanged")
	for response: Variant in [null, true, {}, {"status": true}]:
		var malformed: Callable = func(_owner: Dictionary, _binding: Dictionary) -> Variant: return response
		check(initialized(f, {"TEST-A": malformed, "TEST-B": semantic}).validate(f.checkpoint, f.binding).status == "INVALID_PROVIDER", "malformed provider fails closed")
	var mismatch: Dictionary = f.checkpoint.duplicate(true)
	mismatch.owner_snapshots[1].revision = "1"
	check(contract.validate(mismatch, f.binding).status == "INVALID", "same tick but joint revision conflict")
	for key: String in ["owner_id", "schema", "binding"]:
		for value: Variant in [[], {}, true, null, 1]:
			var bad: Dictionary = f.checkpoint.duplicate(true)
			if key == "binding":
				bad.owner_snapshots[1].payload.binding = value
			else:
				bad.owner_snapshots[1][key] = value
			calls = 0
			check(contract.validate(bad, f.binding).get("status") in ["INVALID", "UNSUPPORTED_SCHEMA"], "wrong typed metadata returns status")
			check(calls == 0, "wrong types do not call providers")
	_lifetimes()
	_domains()
	_legacy()
	print("STEAM_RECOVERY_CONTRACT_TEST checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _legacy() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/config/production_defaults.json"))
	var wire: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://production/playtest-evidence/steam-domains-2026-09-11/snapshot-full.json"))
	var f := fixture()
	f.binding.config_hash = Snapshot.config_hash(config)
	f.binding.active_tick = wire.scope.completed_active_ticks
	var payload := {"binding": f.binding.duplicate(true), "state": wire}
	f.checkpoint.active_tick = f.binding.active_tick
	f.checkpoint.owner_snapshots = [{"owner_id": "LEGACY_STAGE", "schema": "1", "revision": "0", "payload": payload}]
	f.manifest.scope = "LEGACY_ADAPTER_ONLY"
	f.manifest.config_hash = f.binding.config_hash
	f.manifest.owners = [{"owner_id": "LEGACY_STAGE", "schema": "1", "max_snapshot_bytes": str(Codec.encode(f.checkpoint.owner_snapshots[0], LIMITS).bytes), "state_shape": Snapshot.shape(config)}]
	f.manifest.max_checkpoint_bytes = str(Codec.encode(f.checkpoint, LIMITS).bytes)
	var validator: Callable = func(owner: Dictionary, binding: Dictionary) -> Dictionary:
		if owner.payload.state.scope.completed_active_ticks != binding.active_tick:
			return {"status": "INVALID"}
		return {"status": Snapshot.validate(owner.payload.state, config, LIMITS).status}
	var c = initialized(f, {"LEGACY_STAGE": validator})
	check(c.validate(f.checkpoint, f.binding).status == "OK", "actual legacy pressure snapshot")
	var broken: Dictionary = f.checkpoint.duplicate(true)
	broken.owner_snapshots[0].payload.state.scope.completed_active_ticks = "0"
	check(c.validate(broken, f.binding).status != "OK", "payload tick cannot hide behind binding")
	broken = f.checkpoint.duplicate(true)
	broken.owner_snapshots[0].payload.state.player.hp = "0000000000000000"
	check(c.preflight(broken, f.binding).status == "OK", "zero HP shape and binding valid")
	check(c.validate(broken, f.binding).status == "INVALID", "actual legacy semantic validator rejects zero HP")

func _domains() -> void:
	var f := fixture()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/steam/domains-fixture.json"))
	var cf: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/steam/campaign-fixture.json"))
	var campaign := Campaign.new()
	check(campaign.initialize(cf.definition, cf.catalog, LIMITS).status == "OK", "domain campaign")
	for key: String in ["offer_max", "loadout_max", "refresh_max"]:
		d.context[key] = int(d.context[key])
	d.context.required_owner_ids = ["TEST-A", "TEST-B"]
	d.context.owner_validators = {"TEST-A": semantic, "TEST-B": semantic}
	d.context.preparation_validator = func(_run: Dictionary, _domains: Dictionary) -> Dictionary:
		preparation_calls += 1
		return {"status": "OK"}
	d.context.complete_validator = null
	var run: Dictionary = d.prepared_run.duplicate(true)
	run.run_status = "SUSPENDED"
	for key: String in ["mission_id", "mission_definition_hash", "config_hash"]:
		f.manifest[key] = run[key]
		f.binding[key] = run[key]
	for owner: Dictionary in f.checkpoint.owner_snapshots:
		owner.payload.binding = f.binding.duplicate(true)
	for i: int in range(f.manifest.owners.size()):
		f.manifest.owners[i].max_snapshot_bytes = str(Codec.encode(f.checkpoint.owner_snapshots[i], LIMITS).bytes)
	f.manifest.max_checkpoint_bytes = str(Codec.encode(f.checkpoint, LIMITS).bytes)
	# Exercise a registered owner version other than the original schema 1.
	for rule: Dictionary in f.manifest.owners:
		rule.schema = "2"
	for owner: Dictionary in f.checkpoint.owner_snapshots:
		owner.schema = "2"
	var contract = initialized(roomy(f))
	var schema := Domains.new()
	check(schema.initialize(campaign, d.context, LIMITS, contract).status == "OK", "install bound checkpoint in seven-domain validator")
	run.checkpoint = f.checkpoint.duplicate(true)
	d.domains.current_run.payload.run = run
	d.domains.preparation.payload.next_preparation_id = "2"
	d.domains.preparation.payload.active_reservation = {"receipt": run.prep_receipt.duplicate(true), "state": "CONSUMED", "recovery_revision": "0"}
	check(schema.validate(d.domains, d.root).status == "OK", "bound seven-domain suspended checkpoint")
	d.domains.current_run.payload.run.checkpoint.owner_snapshots[1].payload.binding.run_seq = "2"
	calls = 0
	preparation_calls = 0
	joint_calls = 0
	check(schema.validate(d.domains, d.root).status == "INVALID", "Save derives identity from run instead of snapshot")
	check(calls == 0 and preparation_calls == 0 and joint_calls == 0, "all callbacks including prep wait for checkpoint preflight")
	d.domains.current_run.payload.run.checkpoint.owner_snapshots[1].payload.binding = []
	check(schema.validate(d.domains, d.root).get("status") == "INVALID", "wrong binding type through full Save returns status")
	d.domains.current_run.payload.run.checkpoint = f.checkpoint.duplicate(true)
	for response: Variant in [true, null, {}, {"status": []}, {"status": "OK", "extra": true}]:
		d.context.preparation_validator = func(_run: Dictionary, _domains: Dictionary) -> Variant: return response
		var invalid_provider := Domains.new()
		check(invalid_provider.initialize(campaign, d.context, LIMITS, contract).status == "OK", "install malformed prep test provider")
		check(invalid_provider.validate(d.domains, d.root).get("status") == "INVALID_PROVIDER", "malformed preparation provider returns explicit rejection")
	d.context.preparation_validator = func(local_run: Dictionary, local_domains: Dictionary) -> Dictionary:
		local_run.checkpoint.owner_snapshots.clear()
		local_domains.current_run.payload.run.run_seq = "99"
		return {"status": "OK"}
	var mutating_prep := Domains.new()
	check(mutating_prep.initialize(campaign, d.context, LIMITS, contract).status == "OK", "install mutating prep test")
	var saved: Dictionary = d.domains.duplicate(true)
	check(mutating_prep.validate(d.domains, d.root).get("status") == "OK", "prep changes only detached copies")
	check(d.domains == saved, "caller seven-domain value not mutated")
	d.domains.current_run.payload.run.checkpoint.owner_snapshots[1].payload.binding.run_seq = "2"
	check(mutating_prep.validate(d.domains, d.root).get("status") == "INVALID", "prep cannot repair malformed original checkpoint")
	# Synthetic terminal intent tests only the callback boundary, not rewards/COMPLETE.
	d.domains.current_run.payload.run.checkpoint = f.checkpoint.duplicate(true)
	d.domains.current_run.payload.run.run_status = "RESULT_PENDING"
	var after_image: Dictionary = d.domains.duplicate(true)
	after_image.current_run.payload.run = null
	after_image.preparation.payload.active_reservation = null
	var result := {"schema": "1", "profile_id": d.root.profile_id, "branch_id": d.root.branch_id,
		"run_seq": "1", "mission_id": run.mission_id, "mission_definition_hash": run.mission_definition_hash,
		"terminal_tick": f.binding.active_tick, "result_kind": "ABANDONED", "reason": "TEST", "objective_progress_hash": "e".repeat(64)}
	d.domains.current_run.payload.run.terminal_intent = {"sealed_result": result,
		"result_hash": Codec.encode(result, LIMITS).sha256, "complete_operation_id": "6".repeat(32),
		"complete_base_revision": d.root.revision, "complete_request_hash": "d".repeat(64), "complete_next_domains": after_image}
	for response: Variant in [true, null, {"status": "OK"}]:
		d.context.complete_validator = func(local_domains: Dictionary, local_root: Dictionary) -> Variant:
			local_domains.current_run.payload.run = null
			local_root.revision = "99"
			return response
		var terminal_schema := Domains.new()
		check(terminal_schema.initialize(campaign, d.context, LIMITS, contract).status == "OK", "terminal callback test setup")
		var before_terminal: Dictionary = d.duplicate(true)
		var expected := "OK" if response is Dictionary else "INVALID_PROVIDER"
		check(terminal_schema.validate(d.domains, d.root).get("status") == expected, "complete result protocol")
		check(d == before_terminal, "complete callback does not mutate domains/root")
	d.context.required_owner_ids = ["TEST-A"]
	check(Domains.new().initialize(campaign, d.context, LIMITS, contract).status == "INVALID_CONFIG", "Save cannot narrow registered owner set")

func _lifetimes() -> void:
	var f := roomy(fixture())
	for kind: String in ["owner", "joint", "during_owner", "during_joint"]:
		var node := ProviderNode.new()
		var validators := {"TEST-A": semantic, "TEST-B": semantic}
		var joint_provider: Callable = joint
		if kind in ["owner", "during_owner"]:
			validators["TEST-B"] = node.accept
		else:
			joint_provider = node.accept
		if kind.begins_with("during"):
			validators["TEST-A"] = func(_owner: Dictionary, _binding: Dictionary) -> Dictionary:
				node.free()
				return {"status": "OK"}
		var contract := Contract.new()
		check(contract.initialize(f.manifest, validators, LIMITS, joint_provider).status == "OK", "lifetime initialize")
		if not kind.begins_with("during"):
			node.free()
		calls = 0
		check(contract.validate(f.checkpoint, f.binding).get("status") == "INVALID_PROVIDER", "freed provider " + kind)
		if not kind.begins_with("during"):
			check(calls == 0, "dead callbacks rejected before any semantic call")
