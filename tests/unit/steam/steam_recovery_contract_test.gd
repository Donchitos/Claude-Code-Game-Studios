extends SceneTree
## Pure WP04c logic checks, no runtime/file IO or persistent profile access.
const Contract = preload("res://src/data/steam_recovery_contract.gd")
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const LIMITS = {"max_bytes": 10000, "max_depth": 16}
var checks := 0
var failures := 0

func _initialize() -> void:
	var binding := {"recovery_profile": "TEST", "profile_id": "1".repeat(32), "branch_id": "2".repeat(32), "run_seq": "1", "mission_id": "TEST-M", "mission_definition_hash": "a".repeat(64), "config_hash": "b".repeat(64), "active_tick": "0"}
	var row := {"owner_id": "TEST", "schema": "2", "revision": "0", "payload": {"binding": binding.duplicate(), "state": {"text": "中文\"\\"}}}
	var cp := {"checkpoint_seq": "1", "active_tick": "0", "owner_snapshots": [row]}
	var rule := {"owner_id": "TEST", "schema": "2", "max_snapshot_bytes": str(Codec.encode(row, LIMITS).bytes), "state_shape": {"text": "string"}}
	var manifest := {"schema": "1", "scope": "TEST_ONLY", "recovery_profile": "TEST", "mission_id": binding.mission_id, "mission_definition_hash": binding.mission_definition_hash, "config_hash": binding.config_hash, "max_checkpoint_bytes": str(Codec.encode(cp, LIMITS).bytes), "owners": [rule]}
	var provider := func(_value: Dictionary, _binding: Dictionary) -> Dictionary: return {"status": "OK"}
	check(Contract.new().validate(cp, binding).status == "NOT_INITIALIZED", "uninitialized")
	for delta: int in [-1, 0, 1]:
		var m := manifest.duplicate(true)
		m.owners[0].max_snapshot_bytes = str(int(rule.max_snapshot_bytes) + delta)
		var c := Contract.new()
		check(c.initialize(m, {"TEST": provider}, LIMITS, provider).status == "OK", "configure utf8 ceiling")
		check(c.validate(cp, binding).status == ("TOO_LARGE" if delta < 0 else "OK"), "whole row includes escaped multibyte binding")
	for shape: Variant in [null, [], "string", {"x": "unknown"}, {"$array": "string"}, {"$array": "string", "$max": -1}, {"$array": "string", "$max": 1.0}, {"bad field": "string"}]:
		var m := manifest.duplicate(true)
		m.owners[0].state_shape = shape
		check(Contract.new().initialize(m, {"TEST": provider}, LIMITS, provider).status == "INVALID_CONFIG", "invalid shape registration")
	for value: Variant in ["", "0", "01", "-1", "9223372036854775808", 1, 1.0, null, true]:
		var m := manifest.duplicate(true)
		m.owners[0].schema = value
		check(Contract.new().initialize(m, {"TEST": provider}, LIMITS, provider).status == "INVALID_CONFIG", "schema must be positive canonical u63")
	var c := Contract.new()
	check(c.initialize(manifest, {"TEST": provider}, LIMITS, provider).status == "OK", "owner schema2 supported")
	for value: Variant in ["0", "01", "-1", null, 1, true]:
		var wrong := binding.duplicate(true)
		wrong.run_seq = value
		check(c.validate(cp, wrong).status == "INVALID", "bad run identity")
	var reversed := manifest.duplicate(true)
	reversed.max_checkpoint_bytes = "10001"
	check(Contract.new().initialize(reversed, {"TEST": provider}, LIMITS, provider).status == "INVALID_CONFIG", "budget cannot exceed tool ceiling")
	var ids := c.required_owner_ids()
	ids.clear()
	check(c.required_owner_ids() == ["TEST"], "returned owner list isolated")
	check(not c.production_admission().production_enabled, "success never release admission")
	print("STEAM_RECOVERY_UNIT_TEST checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
