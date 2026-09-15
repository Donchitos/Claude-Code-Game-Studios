class_name SteamRecoveryContract
extends RefCounted
## ADR-0006 WP04c. Relative-to-config checkpoint validation for tests/adapters.
## Does not restore objects, write saves, or admit the commercial Steam profile.
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const Fields = preload("res://src/data/steam_campaign_schema.gd")
const Types = preload("res://src/persistence/steam_wire_types.gd")
const MANIFEST_FIELDS = ["schema", "scope", "recovery_profile", "mission_id", "mission_definition_hash", "config_hash", "max_checkpoint_bytes", "owners"]
const BINDING_FIELDS = ["recovery_profile", "profile_id", "branch_id", "run_seq", "mission_id", "mission_definition_hash", "config_hash", "active_tick"]
var _manifest := {}
var _providers := {}
var _limits := {}
var _joint: Callable
var _ready := false

## Manifest/shapes/providers are trusted installed configuration, never save data.
## Registration is immutable. All budgets are explicit test/adapter ceilings.
func initialize(manifest: Variant, providers: Dictionary, limits: Dictionary, joint: Callable) -> Dictionary:
	if _ready:
		return {"status": "ALREADY_INITIALIZED"}
	if Codec.encode({}, limits).status != "OK" or not _manifest_valid(manifest, limits):
		return _error("INVALID_CONFIG", "manifest")
	if not joint.is_valid():
		return _error("UNSUPPORTED_SCHEMA", "joint_validator")
	var ids: Array = []
	for rule: Dictionary in manifest.owners:
		ids.append(rule.owner_id)
		if not providers.get(rule.owner_id) is Callable or not providers[rule.owner_id].is_valid():
			return _error("UNSUPPORTED_SCHEMA", rule.owner_id)
	var actual := providers.keys()
	actual.sort()
	if actual != ids:
		return _error("INVALID_CONFIG", "provider_set")
	_manifest = manifest.duplicate(true)
	_providers = providers.duplicate()
	_limits = limits.duplicate(true)
	_joint = joint
	_ready = true
	return {"status": "OK"}

## Full preflight precedes all semantic callbacks. Each receives detached copies;
## trusted callback code is still responsible for avoiding external side effects.
func validate(checkpoint: Variant, binding: Variant) -> Dictionary:
	if not _ready:
		return {"status": "NOT_INITIALIZED"}
	var checked := preflight(checkpoint, binding)
	if checked.status != "OK":
		return checked
	for owner: Dictionary in checkpoint.owner_snapshots:
		if not _providers[owner.owner_id].is_valid():
			return _error("INVALID_PROVIDER", owner.owner_id)
		var result := _provider_result(_providers[owner.owner_id].call(owner.duplicate(true), binding.duplicate(true)))
		if result.status != "OK":
			return _error(result.status, owner.owner_id)
	if not _joint.is_valid():
		return _error("INVALID_PROVIDER", "joint")
	var joint_result := _provider_result(_joint.call(checkpoint.duplicate(true), binding.duplicate(true)))
	if joint_result.status != "OK":
		return _error(joint_result.status, "joint")
	return checked

## Performs every metadata/shape/byte check without invoking any callback.
## Save uses this before Preparation; validate repeats it before owner semantics.
func preflight(checkpoint: Variant, binding: Variant) -> Dictionary:
	if not _ready:
		return {"status": "NOT_INITIALIZED"}
	var result := _preflight(checkpoint, binding)
	if result.status != "OK":
		return result
	for id: String in _providers:
		if not _providers[id].is_valid():
			return _error("INVALID_PROVIDER", id)
	if not _joint.is_valid():
		return _error("INVALID_PROVIDER", "joint")
	return result

## Detached list for Save's configured owner-set binding. Not a discovery source.
func required_owner_ids() -> Array:
	var ids: Array = []
	for rule: Dictionary in _manifest.get("owners", []):
		ids.append(rule.owner_id)
	return ids

## Installed profile name for constructing the binding from validated Save data.
func recovery_profile() -> String:
	return _manifest.get("recovery_profile", "")

## Checkpoint validity is never a release certificate or measured slot budget.
func production_admission() -> Dictionary:
	return {"status": "UNSUPPORTED_SCHEMA", "production_enabled": false,
		"missing_evidence": ["commercial_owner_contracts", "mission_phase_capacity", "complete_transaction", "commercial_maximum_slot_budget", "windows_durability"]}

func _preflight(cp: Variant, binding: Variant) -> Dictionary:
	if not _binding_valid(binding):
		return _error("INVALID", "binding")
	var limits := _limits.duplicate()
	limits.max_bytes = int(_manifest.max_checkpoint_bytes)
	var encoded := Codec.encode(cp, limits)
	if encoded.status != "OK":
		return _error(encoded.status, "checkpoint.bytes")
	if not Fields._fields(cp, ["checkpoint_seq", "active_tick", "owner_snapshots"]) \
		or not _positive(cp.checkpoint_seq) or not cp.active_tick is String or cp.active_tick != binding.active_tick or not cp.owner_snapshots is Array:
		return _error("INVALID", "checkpoint")
	if cp.owner_snapshots.size() != _manifest.owners.size():
		return _error("UNSUPPORTED_SCHEMA", "checkpoint.owner_set")
	var sizes := {}
	for i: int in range(_manifest.owners.size()):
		var checked := _owner_preflight(cp.owner_snapshots[i], _manifest.owners[i], binding)
		if checked.status != "OK":
			return checked
		sizes[_manifest.owners[i].owner_id] = checked.bytes
	return {"status": "OK", "checkpoint_bytes": encoded.bytes, "owner_bytes": sizes, "production_enabled": false}

func _owner_preflight(owner: Variant, rule: Dictionary, binding: Dictionary) -> Dictionary:
	if not Fields._fields(owner, ["owner_id", "schema", "revision", "payload"]) or not owner.owner_id is String or owner.owner_id != rule.owner_id:
		return _error("INVALID", "checkpoint.owner_set/order")
	if not owner.schema is String or owner.schema != rule.schema:
		return _error("UNSUPPORTED_SCHEMA", rule.owner_id + ".schema")
	if Codec.read_u63(owner.revision).status != "OK" or not Fields._fields(owner.payload, ["binding", "state"]) \
		or not _binding_valid(owner.payload.binding) or owner.payload.binding != binding:
		return _error("INVALID", rule.owner_id + ".binding/revision")
	var limits := _limits.duplicate()
	limits.max_bytes = int(rule.max_snapshot_bytes)
	var encoded := Codec.encode(owner, limits)
	if encoded.status != "OK":
		return _error(encoded.status, rule.owner_id + ".bytes")
	if Types.transform(owner.payload.state, rule.state_shape, false).status != "OK":
		return _error("INVALID", rule.owner_id + ".state_shape")
	return {"status": "OK", "bytes": encoded.bytes}

func _binding_valid(binding: Variant) -> bool:
	if not Fields._fields(binding, BINDING_FIELDS):
		return false
	for key: String in ["recovery_profile", "mission_id", "mission_definition_hash", "config_hash"]:
		if not binding[key] is String or binding[key] != _manifest[key]:
			return false
	return Codec.is_hex(binding.profile_id, 32) and Codec.is_hex(binding.branch_id, 32) \
		and _positive(binding.run_seq) and Codec.read_u63(binding.active_tick).status == "OK"

static func _manifest_valid(m: Variant, limits: Dictionary) -> bool:
	if not Fields._fields(m, MANIFEST_FIELDS) or not m.schema is String or m.schema != "1" \
		or not m.scope is String or not ["TEST_ONLY", "LEGACY_ADAPTER_ONLY"].has(m.scope):
		return false
	if not _id(m.recovery_profile) or not _id(m.mission_id) or not Codec.is_hex(m.mission_definition_hash, 64) \
		or not Codec.is_hex(m.config_hash, 64) or not _positive(m.max_checkpoint_bytes):
		return false
	if int(m.max_checkpoint_bytes) > limits.max_bytes or not m.owners is Array or m.owners.is_empty():
		return false
	var previous := ""
	for rule: Variant in m.owners:
		if not _rule_valid(rule, limits) or rule.owner_id <= previous or int(rule.max_snapshot_bytes) > int(m.max_checkpoint_bytes):
			return false
		previous = rule.owner_id
	return true

static func _rule_valid(rule: Variant, limits: Dictionary) -> bool:
	return Fields._fields(rule, ["owner_id", "schema", "max_snapshot_bytes", "state_shape"]) \
		and _id(rule.owner_id) and _positive(rule.schema) and _positive(rule.max_snapshot_bytes) \
		and rule.state_shape is Dictionary and _shape_valid(rule.state_shape, limits.max_depth)

static func _shape_valid(shape: Variant, remaining: int) -> bool:
	if remaining < 0:
		return false
	if shape is String:
		return ["bool", "string", "u63", "f64", "f32", "vec2", "bits64"].has(shape)
	if not shape is Dictionary:
		return false
	if shape.has("$array"):
		return Fields._fields(shape, ["$array", "$max"]) and shape["$max"] is int \
			and shape["$max"] >= 0 and _shape_valid(shape["$array"], remaining - 1)
	for key: Variant in shape:
		if not _id(key) or not _shape_valid(shape[key], remaining - 1):
			return false
	return true

static func _provider_result(result: Variant) -> Dictionary:
	if not Fields._fields(result, ["status"]) or not result.status is String \
		or not ["OK", "INVALID", "UNSUPPORTED_SCHEMA", "CONTENT_MISMATCH", "TOO_LARGE"].has(result.status):
		return {"status": "INVALID_PROVIDER"}
	return result

static func _positive(value: Variant) -> bool:
	var parsed := Codec.read_u63(value)
	return parsed.status == "OK" and parsed.value > 0

static func _id(value: Variant) -> bool:
	if not value is String or value.is_empty():
		return false
	for i: int in range(value.length()):
		var code: int = value.unicode_at(i)
		if code < 33 or code > 126:
			return false
	return true

static func _error(status: String, path: String) -> Dictionary:
	return {"status": status, "path": path}
