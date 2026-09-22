class_name SteamSaveDomains
extends RefCounted
## ADR-0006 WP04b. Closed five-domain schemas plus seven-domain validation.
## Read-only validation, not the durable writer or a release admission switch.
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const Structure = preload("res://src/data/steam_structure_validator.gd")
const Campaign = preload("res://src/data/steam_campaign_schema.gd")
const Recovery = preload("res://src/data/steam_recovery_contract.gd")
const KEYS := ["campaign", "unlocks", "records", "progression", "preparation", "current_run", "user_settings"]
const FIVE := ["records", "progression", "preparation", "current_run", "user_settings"]
const MAX_I := 9223372036854775807
var _schemas := {}
var _context := {}
var _limits := {}
var _campaign: SteamCampaignSchema
var _ready := false
var _recovery: Recovery

## Context is explicit, version-bound owner configuration. No load-time defaults.
func initialize(campaign: SteamCampaignSchema, context: Dictionary, limits: Dictionary, recovery: Recovery = null) -> Dictionary:
	if _ready:
		return {"status": "ALREADY_INITIALIZED"}
	var fields := ["content_revision", "config_hash", "seed_caps", "recipe_seeds", "locale_ids", "offer_max", "loadout_max", "refresh_max", "required_owner_ids", "owner_validators", "mission_hashes", "complete_validator", "preparation_validator"]
	if campaign == null or not Campaign._fields(context, fields) or Codec.read_u63(context.content_revision).status != "OK" \
		or not Codec.is_hex(context.config_hash, 64) or not context.seed_caps is Dictionary \
		or not context.owner_validators is Dictionary or not context.mission_hashes is Dictionary:
		return {"status": "INVALID_CONFIG"}
	if context.mission_hashes != campaign._catalog.get("mission_hashes") or not context.recipe_seeds is Dictionary:
		return {"status": "INVALID_CONFIG"}
	for recipe: Variant in context.recipe_seeds:
		if not Campaign._sorted_ids([recipe]) or not context.seed_caps.has(context.recipe_seeds[recipe]):
			return {"status": "INVALID_CONFIG"}
	for key: String in ["locale_ids", "required_owner_ids"]:
		if not Campaign._sorted_ids(context[key]) or context[key].is_empty():
			return {"status": "INVALID_CONFIG"}
	for key: String in ["offer_max", "loadout_max", "refresh_max"]:
		if not context[key] is int or context[key] < 0 or (key != "refresh_max" and context[key] == 0):
			return {"status": "INVALID_CONFIG"}
	for key: Variant in context.seed_caps:
		if not Campaign._sorted_ids([key]) or Codec.read_u63(context.seed_caps[key]).status != "OK":
			return {"status": "INVALID_CONFIG"}
	for id: String in context.required_owner_ids:
		if not context.owner_validators.get(id) is Callable or not context.owner_validators[id].is_valid():
			return {"status": "UNSUPPORTED_SCHEMA", "owner_id": id}
	if Codec.encode({}, limits).status != "OK":
		return {"status": "INVALID_CONFIG"}
	if recovery != null and recovery.required_owner_ids() != context.required_owner_ids:
		return {"status": "INVALID_CONFIG", "path": "recovery.owner_set"}
	for domain: String in FIVE:
		var schema: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/schemas/steam/" + domain + "-domain-v1.schema.json"))
		if not schema is Dictionary:
			return {"status": "INVALID_CONFIG"}
		_schemas[domain] = schema
	_campaign = campaign
	_context = context.duplicate(true)
	_limits = limits.duplicate(true)
	_recovery = recovery
	_ready = true
	return {"status": "OK"}

## Root identity is supplied by the validated Save envelope. No state is written.
func validate(domains: Variant, root_identity: Dictionary, final_after_image: bool = false) -> Dictionary:
	if not _ready:
		return {"status": "NOT_INITIALIZED"}
	var encoded := Codec.encode(domains, _limits)
	if encoded.status != "OK":
		return {"status": encoded.status}
	if not Campaign._fields(domains, KEYS) or not _root_valid(root_identity):
		return _invalid("root/domains")
	for name: String in FIVE:
		var schema: Dictionary = _schemas[name]
		if domains[name] is Dictionary and domains[name].get("schema") != "1":
			return {"status": "UNSUPPORTED_SCHEMA", "path": name}
		if domains[name] is Dictionary and domains[name].get("payload") is Dictionary and domains[name].payload.has("schema") and domains[name].payload.schema != "1":
			return {"status": "UNSUPPORTED_SCHEMA", "path": name + ".payload.schema"}
		if not Structure.valid(domains[name], schema, schema["$defs"]):
			return _invalid(name + ".structure")
		if name != "current_run" and domains[name].payload.content_revision != _context.content_revision:
			return {"status": "CONTENT_MISMATCH", "path": name}
	var cp := _campaign.validate_domains(domains.campaign, domains.unlocks)
	if cp.status != "OK":
		return cp
	if not _records(domains.records.payload):
		return _invalid("records.conservation")
	if not _progression(domains.progression.payload):
		return _invalid("progression.receipt/conservation")
	if not _preparation(domains.preparation.payload, domains.unlocks.payload.unlocked_content_ids):
		return _invalid("preparation.inventory/reservation")
	if not _context.locale_ids.has(domains.user_settings.payload.locale_id):
		return _invalid("user_settings.locale")
	var run: Variant = domains.current_run.payload.run
	if run == null:
		return {"status": "OK"} if domains.preparation.payload.active_reservation == null else _invalid("orphan_reservation")
	if final_after_image:
		return _invalid("recursive_intent")
	return _run(run, domains, root_identity)

## Exposed cancellation is derived from durable commitments, never a caller flag.
static func cancellation_allowed(checkpoint: Dictionary) -> bool:
	return checkpoint.get("offer_revision") == "0" and checkpoint.get("offer_rows") == [] \
		and checkpoint.get("offer_hash") == null and checkpoint.get("refresh_used") == "0" \
		and checkpoint.get("choice_command_id") == null and checkpoint.get("selected_candidate_id") == null \
		and checkpoint.get("loadout_rows") == [] and checkpoint.get("handoff_revision") == "0"

func _records(p: Dictionary) -> bool:
	var old: Dictionary = p.legacy_records
	var r: Dictionary = p.mission_records
	var count := 0
	for key: String in ["victories", "defeats", "abandoned", "technical_aborts"]:
		var amount := _n(r[key])
		if amount > MAX_I - count:
			return false
		count += amount
	return _n(old.victories) <= _n(old.total_runs) and Codec.hex_to_float(old.best_seconds).value >= 0 \
		and count == _n(r.completed_runs) and _sum_is([p.spirit_stones.unspent, p.spirit_stones.spent], p.spirit_stones.earned)

func _progression(p: Dictionary) -> bool:
	if not _sum_is([p.unspent_pages, p.spent_pages_total], p.earned_pages_total):
		return false
	var sequence := 0
	for level: String in p.branch_levels.values():
		sequence += _n(level)
	if sequence != _n(p.upgrade_sequence) or _n(p.next_purchase_id) != sequence + 1:
		return false
	var receipt: Variant = p.last_purchase_receipt
	if receipt == null:
		return sequence == 0
	if _n(receipt.purchase_id) != sequence or _n(receipt.to_level) != _n(receipt.from_level) + 1 \
		or receipt.to_level != p.branch_levels[receipt.branch_id] or _n(receipt.cost_pages) > _n(receipt.balance_before) \
		or _n(receipt.balance_before) - _n(receipt.cost_pages) != _n(receipt.balance_after) \
		or _n(receipt.cost_pages) > _n(p.spent_pages_total) or _n(receipt.balance_after) > _n(p.unspent_pages):
		return false
	if receipt.kind == "V2" and (_n(receipt.next_domain_revision) > _n(p.domain_revision) \
		or Codec.increment_u63(receipt.base_domain_revision).get("value") != receipt.next_domain_revision):
		return false
	return true # Historical prices are not recomputed under a new content revision.

func _preparation(p: Dictionary, unlocked: Array) -> bool:
	if p.seed_ledgers.size() != _context.seed_caps.size() or _n(p.next_preparation_id) < 1 \
		or not Campaign._sorted_ids(p.applied_campaign_grant_ids):
		return false
	for grant: String in p.applied_campaign_grant_ids:
		if not unlocked.has(grant):
			return false
	var previous := ""
	var reserved := 0
	var reserved_seed := ""
	for row: Dictionary in p.seed_ledgers:
		if row.seed_id <= previous or not _context.seed_caps.has(row.seed_id) \
			or not _sum_is([row.available, row.reserved, row.consumed], row.earned) \
			or _n(row.available) > _n(_context.seed_caps[row.seed_id]) - _n(row.reserved) or _n(row.reserved) > 1:
			return false
		previous = row.seed_id
		reserved += _n(row.reserved)
		if row.reserved == "1":
			reserved_seed = row.seed_id
	if reserved > 1:
		return false
	var active: Variant = p.active_reservation
	if active == null:
		return reserved == 0
	var receipt: Dictionary = active.receipt
	if _n(receipt.preparation_id) < 1 or _n(receipt.preparation_id) >= _n(p.next_preparation_id) or receipt.source_content_hash != _context.config_hash:
		return false
	var pill: Dictionary = receipt.selection
	if pill.kind == "NO_PILL":
		return reserved == 0
	if not _context.seed_caps.has(pill.seed_id) or _context.recipe_seeds.get(pill.recipe_id) != pill.seed_id:
		return false
	for grant: String in _campaign._catalog.prep_unlock_ids:
		if not unlocked.has(grant):
			return false
	return reserved == 0 if active.state == "CONSUMED" else reserved == 1 and reserved_seed == pill.seed_id

func _run(run: Dictionary, domains: Dictionary, identity: Dictionary) -> Dictionary:
	var seq := _n(run.run_seq)
	if seq <= _n(identity.resolved_run_seq) or seq >= _n(identity.next_run_seq) \
		or run.config_hash != _context.config_hash or _context.mission_hashes.get(run.mission_id) != run.mission_definition_hash:
		return _invalid("run.identity/content")
	# A replay or the next prefix mission is playable; future missions are closed.
	var completed: Array = domains.campaign.payload.completed_mission_ids
	var ordinal: int
	var mission_ids: Array = _context.mission_hashes.keys()
	mission_ids.sort()
	ordinal = mission_ids.find(run.mission_id)
	if ordinal < 0 or ordinal > completed.size():
		return _invalid("run.mission_locked")
	var prep: Variant = domains.preparation.payload.active_reservation
	var pc: Dictionary = run.preparation_checkpoint
	if prep == null or prep.receipt != run.prep_receipt or prep.receipt.run_seq != run.run_seq \
		or pc.run_seq != run.run_seq or pc.preparation_id != prep.receipt.preparation_id \
		or pc.offer_rows.size() > _context.offer_max or pc.loadout_rows.size() > _context.loadout_max \
		or not _sum_is([pc.refresh_used, pc.refresh_remaining], str(_context.refresh_max)):
		return _invalid("run.preparation_binding")
	if pc.offer_rows.is_empty():
		if pc.offer_revision != "0" or pc.offer_hash != null or pc.selected_candidate_id != null:
			return _invalid("run.empty_offer")
	elif pc.offer_revision == "0" or _hash(pc.offer_rows) != pc.offer_hash:
		return _invalid("run.offer_hash")
	var candidates: Array = []
	for row: Dictionary in pc.offer_rows:
		if candidates.has(row.candidate_id):
			return _invalid("run.duplicate_candidate")
		candidates.append(row.candidate_id)
	if (pc.selected_candidate_id == null) != (pc.choice_command_id == null) \
		or (pc.selected_candidate_id != null and not candidates.has(pc.selected_candidate_id)) or _hash(pc.loadout_rows) != pc.loadout_hash:
		return _invalid("run.choice/loadout")
	if run.run_status == "PREPARED":
		if run.terminal_intent != null or run.checkpoint != null or prep.state != "RESERVED":
			return _invalid("run.prepared")
		return _call_domain_provider(_context.preparation_validator, run, domains, "Preparation")
	if not pc.offer_rows.is_empty() and (pc.selected_candidate_id == null or pc.handoff_revision == "0"):
		return _invalid("run.unresolved_offer")
	if prep.state != "CONSUMED" or run.checkpoint == null:
		return _invalid("run.start_consumption/checkpoint")
	if _recovery != null:
		var preflight := _recovery.preflight(run.checkpoint, _recovery_binding(run.checkpoint, run, identity))
		if preflight.status != "OK":
			return preflight
	var prep_result := _call_domain_provider(_context.preparation_validator, run, domains, "Preparation")
	if prep_result.status != "OK":
		return prep_result
	var checkpoint_result := _checkpoint(run.checkpoint, run, identity)
	if checkpoint_result.status != "OK":
		return checkpoint_result
	if run.run_status != "RESULT_PENDING":
		return {"status": "OK"} if run.terminal_intent == null else _invalid("run.unexpected_terminal")
	var intent: Variant = run.terminal_intent
	if intent == null or intent.complete_base_revision != identity.revision or intent.complete_operation_id == identity.operation_id \
		or _hash(intent.sealed_result) != intent.result_hash:
		return _invalid("run.terminal_identity")
	var result: Dictionary = intent.sealed_result
	for key: String in ["profile_id", "branch_id"]:
		if result[key] != identity[key]:
			return _invalid("result." + key)
	for key: String in ["run_seq", "mission_id", "mission_definition_hash"]:
		if result[key] != run[key]:
			return _invalid("result." + key)
	if _n(result.terminal_tick) < _n(run.checkpoint.active_tick):
		return _invalid("result.tick")
	var next := validate(intent.complete_next_domains, identity, true)
	if next.status != "OK":
		return next
	# Settlement must prove exact rewards/retirement and normal API request hash.
	# Its full Steam formula/protocol is not installed by this schema package.
	return _call_domain_provider(_context.complete_validator, domains, identity, "SettlementComplete")

func _call_domain_provider(provider: Variant, first: Dictionary, second: Dictionary, owner_id: String) -> Dictionary:
	if not provider is Callable or not provider.is_valid():
		return {"status": "UNSUPPORTED_SCHEMA", "owner_id": owner_id}
	var result: Variant = provider.call(first.duplicate(true), second.duplicate(true))
	if not Campaign._fields(result, ["status"]) or not result.status is String \
		or not ["OK", "INVALID", "UNSUPPORTED_SCHEMA", "CONTENT_MISMATCH", "TOO_LARGE"].has(result.status):
		return {"status": "INVALID_PROVIDER", "owner_id": owner_id}
	return {"status": result.status, "owner_id": owner_id}

func _recovery_binding(cp: Dictionary, run: Dictionary, identity: Dictionary) -> Dictionary:
	return {"recovery_profile": _recovery.recovery_profile(), "profile_id": identity.profile_id,
		"branch_id": identity.branch_id, "run_seq": run.run_seq, "mission_id": run.mission_id,
		"mission_definition_hash": run.mission_definition_hash, "config_hash": run.config_hash, "active_tick": cp.active_tick}

func _checkpoint(cp: Dictionary, run: Dictionary, identity: Dictionary) -> Dictionary:
	if _recovery != null:
		return _recovery.validate(cp, _recovery_binding(cp, run, identity))
	var seen: Array = []
	for owner: Dictionary in cp.owner_snapshots:
		if seen.has(owner.owner_id) or not _context.required_owner_ids.has(owner.owner_id):
			return _invalid("checkpoint.owner_set")
		seen.append(owner.owner_id)
		if owner.schema != "1":
			return {"status": "UNSUPPORTED_SCHEMA", "owner_id": owner.owner_id}
		var validator: Callable = _context.owner_validators[owner.owner_id]
		if not validator.is_valid():
			return {"status": "INVALID_PROVIDER", "owner_id": owner.owner_id}
		var result: Variant = validator.call(owner.duplicate(true), cp.active_tick)
		if not result is Dictionary or not result.get("status") is String:
			return {"status": "INVALID_PROVIDER", "owner_id": owner.owner_id}
		if result.status != "OK":
			return result
	seen.sort()
	return {"status": "OK"} if seen == _context.required_owner_ids else {"status": "UNSUPPORTED_SCHEMA", "path": "checkpoint.missing_owner"}

static func _root_valid(identity: Dictionary) -> bool:
	if not Campaign._fields(identity, ["profile_id", "branch_id", "revision", "resolved_run_seq", "next_run_seq", "operation_id"]):
		return false
	for key: String in ["profile_id", "branch_id", "operation_id"]:
		if not Codec.is_hex(identity[key], 32):
			return false
	for key: String in ["revision", "resolved_run_seq", "next_run_seq"]:
		if Codec.read_u63(identity[key]).status != "OK":
			return false
	return _n(identity.next_run_seq) > _n(identity.resolved_run_seq)

static func _sum_is(parts: Array, total: String) -> bool:
	var remaining := _n(total)
	for part: String in parts:
		if _n(part) > remaining:
			return false
		remaining -= _n(part)
	return remaining == 0

static func _n(value: String) -> int:
	return value.to_int() # All callers follow strict structural u63 validation.

func _hash(value: Variant) -> String:
	return Codec.encode(value, _limits).get("sha256", "")

static func _invalid(path: String) -> Dictionary:
	return {"status": "INVALID", "path": path}
