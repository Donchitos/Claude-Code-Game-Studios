class_name CampaignProfile
extends RefCounted
## CAMPAIGN_GAMEPLAY_V1 independent development profile, not STEAM_SAVE_V2.
## The root injects already initialized storage using dedicated campaign paths.

const DOMAIN := "campaign_game"
const LEGACY_CONTENT_HASH := "71d615925151600c8a1255808f20a03d5d44f5fa4efd9f047874e231f45949ca"
const PACKAGE_B_CONTENT_HASH := "8acdcfa43bc2312b9c0fa7d5992c0e70a889f380fca52931f71c2acb9b6ee7c4"
const PACKAGE_E_CONTENT_HASH := "ddd28d9e4d121e06046305cba134bad25f39250690e9eadde1b95f0f0a89dfaa"
const PACKAGE_D_CONTENT_HASH := "1e3c41e4223704a29050f28294bef4a38b9569186e6a6234a921c3685e92ab3e"
const PACKAGE_A_CONTENT_HASH := "6317cdd43003233238309a0ecadad895d4962cdf188dca3ff0802bba8f42125a"
const SAFE_INT := 9007199254740991
const MAX_DOCUMENT_BYTES := 4194304
const MAX_NODES := 150000
const COUNTERS := ["completed", "wins", "runs", "kills", "damage", "herbs_earned", "pills_cultivated", "pills_used", "branches_purchased", "total_branch_levels", "events_seen", "max_combo", "total_kills", "elite_kills", "boss_kills", "evolutions", "events_taken", "damage_taken", "elapsed", "level", "max_level", "total_runs", "victories", "skills_used", "damage_dealt", "safe_wins", "risk_wins"]
const RULE_ALIASES := {"character_win": "character_wins", "evolution_id": "evolution_ids", "challenge_win": "challenge_wins"}
const ID_COUNTERS := {"challenge_wins": "challenges", "character_wins": "characters", "evolution_ids": "evolutions"}
const COLLECTIONS := ["characters", "skills", "passives", "evolutions", "pills", "events", "challenges", "achievements"]

## Detached JSON-safe view. Mutations must use the transactional methods below.
var data: Dictionary:
	get:
		return _data.duplicate(true)
	set(_value):
		pass
## Latest validation or persistence failure; successful operations clear it.
var error: String = ""
var _data: Dictionary = {}
var _catalog: Dictionary = {}
var _storage: Node
var _content_hash := ""
var _ready := false
var _blocked := false

## Load the existing domain strictly, or persist a new domain if absent.
func initialize(catalog: Dictionary, storage: Node) -> bool:
	if _ready or not _data.is_empty():
		return _fail("ALREADY_INITIALIZED")
	if not is_instance_valid(storage) or not storage.has_method("profile_snapshot") or not storage.has_method("commit_domain_after_images"):
		return _fail("INVALID_STORAGE")
	_catalog = catalog.duplicate(true)
	if not _catalog.has("characters") and _catalog.has("chars"):
		_catalog.characters = _catalog.chars
	if not _valid_catalog():
		return _fail("INVALID_CATALOG: " + error)
	_content_hash = catalog.content_hash
	_storage = storage
	var profile: Variant = storage.call("profile_snapshot")
	if not profile is Dictionary or profile.is_empty() or not profile.get("domains") is Dictionary:
		return _fail("STORAGE_NOT_INITIALIZED")
	if profile.domains.has(DOMAIN):
		var existing: Variant = profile.domains[DOMAIN]
		if not existing is Dictionary:
			return _fail("INVALID_OR_INCOMPATIBLE_CAMPAIGN_DOMAIN")
		var candidate: Dictionary = existing.duplicate(true)
		# This read-only gate precedes even the six-setting migration. A known
		# catalog identity is a routing hint, never permission to load its snapshot.
		var active: Variant = candidate.get("current_run")
		if active is Dictionary and active.get("content_hash") != _content_hash:
			return _fail("LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION" if active.get("content_hash") in [LEGACY_CONTENT_HASH, PACKAGE_A_CONTENT_HASH, PACKAGE_B_CONTENT_HASH, PACKAGE_D_CONTENT_HASH, PACKAGE_E_CONTENT_HASH] else "UNKNOWN_ACTIVE_RUN_CONTENT")
		var migrate_fullscreen := _integer(candidate.get("schema"), 1, 1) and candidate.get("settings") is Dictionary and _keys(candidate.settings, ["locale", "master", "music", "sfx", "font_scale", "reduce_motion"])
		if migrate_fullscreen:
			candidate.settings["fullscreen"] = false
		if not _valid_data(candidate):
			return _fail("INVALID_OR_INCOMPATIBLE_CAMPAIGN_DOMAIN")
		if migrate_fullscreen:
			# Only the exact earlier six-setting schema is migrated. Publish nothing
			# until the same afterimage transaction and readback succeeds.
			var current: Dictionary = _storage.call("profile_snapshot")
			if current.get("domains", {}).get(DOMAIN, {}) != existing:
				_blocked = true
				return _fail("STALE_PROFILE_RELOAD_REQUIRED")
			var status: Variant = _storage.call("commit_domain_after_images", {DOMAIN: candidate.duplicate(true)})
			if not status is int or status != 0:
				_blocked = true
				return _fail("SETTINGS_MIGRATION_COMMIT_FAILED_RELOAD_REQUIRED")
		_data = JSON.parse_string(JSON.stringify(candidate, "", true, true))
		_ready = true
		_blocked = false
		error = ""
		return true
	var counts := {}
	for key in COUNTERS:
		counts[key] = 0
	for key in ID_COUNTERS:
		counts[key] = {}
	var initial := {"schema": 1, "completed": 0, "pages": 0, "branches": [0, 0, 0], "herbs": 0, "pills": {}, "character_id": "", "difficulty": 0, "settings": {"locale": "zh-CN", "master": 1.0, "music": 1.0, "sfx": 1.0, "font_scale": 1.0, "reduce_motion": false, "fullscreen": false}, "current_run": null, "next_run_id": 1, "last_resolved_run_id": 0, "stats": counts, "achievements": [], "seen": [], "challenges": [], "ending_seen": false}
	for character in _catalog.characters:
		if int(character.unlock_after) == 0:
			initial.character_id = character.id
			break
	_ready = true
	if not _publish(initial):
		_ready = false
		return false
	return true

## Select an unlocked character for the next run; active runs retain their loadout.
func select_character(id: String) -> bool:
	if not _available():
		return false
	if not unlocked("characters").has(id):
		return _fail("CHARACTER_LOCKED_OR_UNKNOWN")
	var next := _data.duplicate(true)
	next.character_id = id
	return _publish(next)

## Persist one of the three supported difficulty settings.
func set_difficulty(value: int) -> bool:
	if not _available():
		return false
	if value < 0 or value > 2:
		return _fail("INVALID_DIFFICULTY")
	var next := _data.duplicate(true)
	next.difficulty = value
	return _publish(next)

## Atomically persist a validated settings patch; unknown settings are rejected.
func update_settings(changes: Dictionary) -> bool:
	if not _available():
		return false
	var next := _data.duplicate(true)
	for key in changes:
		if not next.settings.has(key):
			return _fail("UNKNOWN_SETTING")
		next.settings[key] = changes[key]
	if not _valid_settings(next.settings):
		return _fail("INVALID_SETTINGS")
	return _publish(next)

## Spend catalog base + current level * step pages, up to level five in each branch.
func purchase_branch(index: int) -> bool:
	if not _available():
		return false
	if index < 0 or index > 2 or int(_data.branches[index]) >= 5:
		return _fail("INVALID_OR_MAX_BRANCH")
	if int(_data.completed) < branch_requirement(index):
		return _fail("BRANCH_CHAPTER_LOCKED")
	var price := _tune("progression_cost_base") + int(_data.branches[index]) * _tune("progression_cost_step")
	if int(_data.pages) < price:
		return _fail("INSUFFICIENT_PAGES")
	var next := _data.duplicate(true)
	next.pages -= price
	next.branches[index] += 1
	next.stats.branches_purchased += 1
	next.stats.total_branch_levels += 1
	_award(next)
	return _publish(next)

## Required completed-mission count for the next purchase; -1 means unavailable/max.
## Existing ranks are not checked against this purchase-only restriction.
func branch_requirement(index: int) -> int:
	if not _ready or index < 0 or index > 2 or int(_data.branches[index]) >= 5:
		return -1
	return int(_catalog.tuning.progression_unlock_completed[int(_data.branches[index])])

## Convert earned herbs into one unlocked pill, without wall-clock timers.
func cultivate(pill_id: String) -> bool:
	if not _available():
		return false
	var pill := _lookup("pills", pill_id)
	if pill.is_empty() or not unlocked("pills").has(pill_id):
		return _fail("PILL_LOCKED_OR_UNKNOWN")
	if int(_data.herbs) < int(pill.cost) or int(_data.pills.get(pill_id, 0)) >= _tune("profile_pill_cap"):
		return _fail("INSUFFICIENT_HERBS_OR_INVENTORY_FULL")
	var next := _data.duplicate(true)
	next.herbs -= int(pill.cost)
	next.pills[pill_id] = int(next.pills.get(pill_id, 0)) + 1
	next.stats.pills_cultivated += 1
	_award(next)
	return _publish(next)

## Persist identity, seed, immutable loadout and pill debit in the same afterimage.
## Optional challenge binds its catalog mission and pill restrictions before charging.
func begin_run(mission_index: int, pill_id: String = "", challenge_id: String = "") -> Dictionary:
	if not _available():
		return _result_error(error)
	if _data.current_run != null or mission_index < 0 or mission_index >= 64 or mission_index > int(_data.completed):
		return _result_error("RUN_ACTIVE_OR_MISSION_LOCKED")
	if int(_catalog.missions[mission_index].unlock_after) > int(_data.completed):
		return _result_error("MISSION_LOCKED")
	if not unlocked("characters").has(_data.character_id):
		return _result_error("CHARACTER_LOCKED")
	if not pill_id.is_empty() and (not unlocked("pills").has(pill_id) or int(_data.pills.get(pill_id, 0)) <= 0):
		return _result_error("PILL_UNAVAILABLE")
	if not challenge_id.is_empty():
		var challenge := _lookup("challenges", challenge_id)
		if challenge.is_empty() or int(challenge.unlock_after) > int(_data.completed) or challenge.mission_id != _catalog.missions[mission_index].id:
			return _result_error("CHALLENGE_LOCKED_OR_WRONG_MISSION")
		if not pill_id.is_empty() and not challenge.allow_pills:
			return _result_error("CHALLENGE_FORBIDS_PILLS")
	if int(_data.next_run_id) >= SAFE_INT:
		return _result_error("RUN_ID_EXHAUSTED")
	var next := _data.duplicate(true)
	var run_id := int(next.next_run_id)
	var run := {"run_id": run_id, "mission_id": _catalog.missions[mission_index].id, "mission_index": mission_index, "character_id": next.character_id, "difficulty": next.difficulty, "pill_id": pill_id, "challenge_id": challenge_id, "seed": str(randi()), "content_hash": _content_hash, "loadout": {"branches": next.branches.duplicate(), "completed": next.completed, "character_id": next.character_id, "difficulty": next.difficulty, "pill_id": pill_id, "challenge_id": challenge_id}, "snapshot": {}}
	next.current_run = run
	next.next_run_id = run_id + 1
	if not pill_id.is_empty():
		next.pills[pill_id] -= 1
		next.stats.pills_used += 1
	_award(next)
	if not _publish(next):
		return _result_error(error)
	return {"status": "OK", "run": run.duplicate(true)}

## Persist a JSON-safe bounded checkpoint, preserving run identity and loadout.
## Reject unrecoverable battle state before touching either durable slot.
func save_run(snapshot: Dictionary) -> bool:
	if not _available():
		return false
	if _data.current_run == null or not _json_document(snapshot):
		return _fail("NO_RUN_OR_INVALID_SNAPSHOT")
	if not _valid_checkpoint(snapshot):
		return _fail("INVALID_BATTLE_CHECKPOINT")
	var next := _data.duplicate(true)
	next.current_run.snapshot = snapshot.duplicate(true)
	return _publish(next)

## Bind the checkpoint to the current run and the same Arena restore contract.
func _valid_checkpoint(snapshot: Dictionary) -> bool:
	var run: Dictionary = _data.current_run
	if not preload("res://src/campaign/campaign_arena_validation.gd").same_values(snapshot.get("loadout", {}), run.loadout) or snapshot.get("rng_seed") != run.seed:
		return false
	return preload("res://src/campaign/campaign_arena.gd").validate_snapshot(_catalog, _catalog.missions[int(run.mission_index)], snapshot)

## Resolve one live run once, committing retirement, rewards and achievements together.
## Arena supplies per-run stats; numeric counters accumulate, level takes the maximum.
## evolution_ids accepts an ID array or count map; safe/risk_choices count winning runs.
## challenges is the durable first-prize receipt; failed or repeated wins cannot re-award.
func finish_run(victory: bool, stats: Dictionary) -> Dictionary:
	if not _available():
		return _result_error(error)
	if _data.current_run == null or int(_data.current_run.run_id) <= int(_data.last_resolved_run_id):
		return _result_error("NO_UNRESOLVED_RUN")
	if not _json_document(stats):
		return _result_error("INVALID_STATS")
	for key in ["kills", "damage", "events_seen", "max_combo", "elite_kills", "boss_kills", "evolutions", "events_taken", "damage_taken", "elapsed", "level", "damage_dealt"]:
		if stats.has(key) and not _number(stats[key], 0, SAFE_INT):
			return _result_error("INVALID_STATS_" + key)
	for key in ["kills", "events_seen", "max_combo", "elite_kills", "boss_kills", "evolutions", "events_taken", "level", "safe_choices", "risk_choices"]:
		if stats.has(key) and not _integer(stats[key], 0, SAFE_INT):
			return _result_error("INVALID_COUNTER_" + key)
	# Event promises are paid on victory only. Bind the bounded amount to the
	# eligible event choices for this run, before constructing any afterimage.
	var event_reward := _validated_event_reward(stats)
	if event_reward < 0:
		return _result_error("INVALID_EVENT_REWARD")
	var next := _data.duplicate(true)
	var run: Dictionary = next.current_run
	var first := victory and int(run.mission_index) == int(next.completed)
	var previous_unlocks := _all_unlocked(int(next.completed))
	var kills := int(stats.get("kills", 0))
	var reward := mini(_tune("profile_battle_reward_cap"), kills / _tune("profile_kills_per_page"))
	if victory:
		reward += int(_catalog.missions[int(run.mission_index)].reward) if first else _tune("profile_replay_reward")
		reward += event_reward
	var herbs := mini(_tune("profile_battle_herb_cap"), kills / _tune("profile_kills_per_herb")) + (_tune("profile_first_herbs") if first else 0)
	if victory:
		if int(stats.get("safe_choices", 0)) > 0:
			next.stats.safe_wins += 1
		if int(stats.get("risk_choices", 0)) > 0:
			next.stats.risk_wins += 1
		next.stats.character_wins[run.character_id] = int(next.stats.character_wins.get(run.character_id, 0)) + 1
		if not run.challenge_id.is_empty():
			next.stats.challenge_wins[run.challenge_id] = int(next.stats.challenge_wins.get(run.challenge_id, 0)) + 1
			if not next.challenges.has(run.challenge_id):
				next.challenges.append(run.challenge_id)
				reward += int(_lookup("challenges", run.challenge_id).reward)
	next.pages += reward
	next.herbs += herbs
	next.completed += 1 if first else 0
	next.stats.completed = next.completed
	next.stats.runs += 1
	next.stats.wins += 1 if victory else 0
	next.stats.herbs_earned += herbs
	for key in ["kills", "damage", "events_seen", "elite_kills", "boss_kills", "evolutions", "events_taken", "damage_taken", "elapsed", "damage_dealt"]:
		next.stats[key] += stats.get(key, 0)
	next.stats.total_kills = next.stats.kills
	next.stats.total_runs = next.stats.runs
	next.stats.victories = next.stats.wins
	next.stats.max_level = maxi(int(next.stats.max_level), int(stats.get("level", 0)))
	next.stats.level = next.stats.max_level
	if stats.has("skills_used"):
		if stats.skills_used is Array:
			for id in stats.skills_used:
				if not id is String or _lookup("skills", id).is_empty():
					return _result_error("INVALID_SKILL_ID")
				if not next.seen.has(id):
					next.seen.append(id)
			next.stats.skills_used += stats.skills_used.size()
		elif _integer(stats.skills_used, 0, SAFE_INT):
			next.stats.skills_used += stats.skills_used
		else:
			return _result_error("INVALID_SKILLS_USED")
	next.stats.max_combo = maxf(float(next.stats.max_combo), float(stats.get("max_combo", 0)))
	if stats.has("evolution_ids"):
		var ids: Variant = stats.evolution_ids
		if not ids is Array and not ids is Dictionary:
			return _result_error("INVALID_EVOLUTION_IDS")
		var evolution_total := 0
		for id in ids:
			var count: Variant = ids[id] if ids is Dictionary else 1
			if not id is String or _lookup("evolutions", id).is_empty() or not _integer(count, 1, SAFE_INT):
				return _result_error("INVALID_EVOLUTION_ID_COUNT")
			evolution_total += int(count)
			next.stats.evolution_ids[id] = int(next.stats.evolution_ids.get(id, 0)) + int(count)
		if evolution_total > int(stats.get("evolutions", 0)):
			return _result_error("EVOLUTION_TOTAL_MISMATCH")
	if stats.has("seen"):
		if not stats.seen is Array:
			return _result_error("INVALID_SEEN")
		for id in stats.seen:
			if not id is String or not _known_id(id):
				return _result_error("INVALID_SEEN_ID")
			if not next.seen.has(id):
				next.seen.append(id)
	next.last_resolved_run_id = run.run_id
	next.current_run = null
	var ending := first and int(next.completed) == 64
	next.ending_seen = bool(next.ending_seen) or ending
	_award(next)
	var grants: Array[String] = []
	for id in _all_unlocked(int(next.completed)):
		if not previous_unlocks.has(id):
			grants.append(id)
	for key in ["achievements", "challenges"]:
		for id in next[key]:
			if not _data[key].has(id) and not grants.has(id):
				grants.append(id)
	if not _publish(next):
		return _result_error(error)
	return {"status": "OK", "first_clear": first, "reward": reward, "event_reward": event_reward if victory else 0, "unlocks": grants, "ending": ending}

# Current Arena offers at most one encounter per run. Absent event_reward keeps
# older callers compatible; once present, counts and bounded reward must agree.
func _validated_event_reward(stats: Dictionary) -> int:
	if not stats.has("event_reward"):
		return 0
	if not _integer(stats.event_reward, 0, SAFE_INT):
		return -1
	var safe := int(stats.get("safe_choices", 0))
	var risk := int(stats.get("risk_choices", 0))
	if safe > 1 or risk > 1 or safe + risk > 1:
		return -1
	if int(stats.get("events_taken", 0)) != safe + risk:
		return -1
	var maximum := 0
	for row: Dictionary in _catalog.events:
		if int(row.unlock_after) > int(_data.current_run.loadout.completed):
			continue
		var choice := "safe" if safe == 1 else "risk"
		if safe + risk == 1 and row.get(choice) is Dictionary:
			var amount: Variant = row[choice].get("reward", 0)
			if not _integer(amount, 0, SAFE_INT):
				return -1
			maximum = maxi(maximum, int(amount))
	return int(stats.event_reward) if int(stats.event_reward) <= maximum else -1

## Retire a run without refunds, retaining all previously earned progression.
func abandon_run() -> bool:
	if not _available():
		return false
	if _data.current_run == null:
		return _fail("NO_UNRESOLVED_RUN")
	var next := _data.duplicate(true)
	next.last_resolved_run_id = next.current_run.run_id
	next.current_run = null
	return _publish(next)

## List content whose completed-mission threshold has been reached.
func unlocked(kind: String) -> Array[String]:
	return _unlocked_at("characters" if kind == "chars" else kind, int(_data.get("completed", 0))) if _ready else []

## True after storage loss, failed commit/readback or a stale-domain conflict.
## The UI must stop transitions and recreate storage/profile to reconcile disk state.
func is_storage_locked() -> bool:
	return _blocked

## Return a detached profile suitable for menu presentation.
func summary() -> Dictionary:
	return data

func _unlocked_at(kind: String, completed: int) -> Array[String]:
	var ids: Array[String] = []
	for row in _catalog.get(kind, []):
		if int(row.unlock_after) <= completed:
			ids.append(row.id)
	return ids

func _all_unlocked(completed: int) -> Array[String]:
	var result: Array[String] = []
	for kind in COLLECTIONS:
		if kind not in ["achievements", "challenges"]:
			result.append_array(_unlocked_at(kind, completed))
	return result

func _award(next: Dictionary) -> void:
	for kind in ["achievements"]:
		for row in _catalog.get(kind, []):
			var rule: Dictionary = row.rule
			if int(row.unlock_after) <= int(next.completed) and _rule_value(next.stats, rule) >= float(rule.target) and not next[kind].has(row.id):
				next[kind].append(row.id)

func _rule_value(stats: Dictionary, rule: Dictionary) -> float:
	var stat: String = RULE_ALIASES.get(rule.stat, rule.stat)
	if ID_COUNTERS.has(stat):
		return float(stats[stat].get(rule.id, 0))
	return float(stats.get(rule.stat, 0))

func _lookup(kind: String, id: String) -> Dictionary:
	for row in _catalog.get(kind, []):
		if row.id == id:
			return row
	return {}

func _known_id(id: String) -> bool:
	for kind in _catalog:
		if _catalog[kind] is Array:
			for row in _catalog[kind]:
				if row is Dictionary and row.get("id") == id:
					return true
	return false

func _tune(key: String) -> int:
	return int(_catalog.tuning[key])

func _publish(next: Dictionary) -> bool:
	if not _valid_data(next):
		return _fail("INVALID_AFTERIMAGE")
	if not is_instance_valid(_storage):
		_blocked = true
		return _fail("STORAGE_UNAVAILABLE")
	# Detect another profile instance publishing into this domain before overwriting it.
	var current: Dictionary = _storage.call("profile_snapshot")
	if JSON.parse_string(JSON.stringify(current.get("domains", {}).get(DOMAIN, {}), "", true, true)) != _data:
		_blocked = true
		return _fail("STALE_PROFILE_RELOAD_REQUIRED")
	var status: Variant = _storage.call("commit_domain_after_images", {DOMAIN: next.duplicate(true)})
	if not status is int or status != 0:
		_blocked = true
		return _fail("STORAGE_COMMIT_FAILED_%s_RELOAD_REQUIRED" % str(status))
	_data = JSON.parse_string(JSON.stringify(next, "", true, true))
	error = ""
	return true

func _available() -> bool:
	if not _ready:
		return _fail("NOT_INITIALIZED")
	if _blocked:
		return _fail("STORAGE_BLOCKED_RELOAD_REQUIRED")
	return true

func _fail(reason: String) -> bool:
	error = reason
	return false

func _result_error(reason: String) -> Dictionary:
	error = reason
	return {"status": "ERROR", "reason": reason}

func _number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= low and float(value) <= high

func _integer(value: Variant, low: int, high: int) -> bool:
	return _number(value, low, high) and float(value) == floorf(float(value))

func _keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true

func _valid_settings(s: Variant) -> bool:
	if not s is Dictionary or not _keys(s, ["locale", "master", "music", "sfx", "font_scale", "reduce_motion", "fullscreen"]):
		return false
	if not s.locale is String or s.locale not in ["zh-CN", "en", "en-US"] or not s.reduce_motion is bool or not s.fullscreen is bool:
		return false
	for key in ["master", "music", "sfx"]:
		if not _number(s[key], 0, 1):
			return false
	return _number(s.font_scale, 0.75, 2.0)

func _valid_catalog() -> bool:
	if not _catalog.get("content_hash") is String or _catalog.content_hash.length() != 64 or not _catalog.content_hash.is_valid_hex_number():
		return _fail("missing or invalid content_hash")
	if not _json_document(_catalog) or not _catalog.get("missions") is Array or _catalog.missions.size() != 64:
		return _fail("invalid JSON or mission count")
	for kind in COLLECTIONS + ["missions"]:
		if not _catalog.get(kind) is Array:
			return _fail("missing content collection")
		var ids := {}
		for row in _catalog[kind]:
			if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or ids.has(row.id) or not _integer(row.get("unlock_after"), 0, 64):
				return _fail("invalid duplicate ID or unlock threshold")
			ids[row.id] = true
			if kind in ["achievements", "challenges"]:
				if not row.get("rule") is Dictionary or row.rule.get("stat") not in COUNTERS + ID_COUNTERS.keys() + RULE_ALIASES.keys() or not _number(row.rule.get("target"), 0, SAFE_INT):
					return _fail("unsupported achievement rule")
			var rule_stat: String = RULE_ALIASES.get(row.get("rule", {}).get("stat", ""), row.get("rule", {}).get("stat", ""))
			if kind == "achievements" and ID_COUNTERS.has(rule_stat):
				if not row.rule.get("id") is String or _lookup(ID_COUNTERS[rule_stat], row.rule.id).is_empty():
					return _fail("invalid achievement rule ID")
			if kind == "challenges":
				if not row.get("mission_id") is String or _lookup("missions", row.mission_id).is_empty() or not row.get("allow_pills") is bool or not _integer(row.get("reward"), 0, SAFE_INT):
					return _fail("invalid challenge entry")
			if kind == "pills" and not _integer(row.get("cost"), 1, SAFE_INT):
				return _fail("invalid pill cost")
			if kind == "missions" and not _integer(row.get("reward"), 0, SAFE_INT):
				return _fail("invalid mission reward")
	if _catalog.characters.is_empty() or _unlocked_at("characters", 0).is_empty():
		return _fail("no initially unlocked character")
	if not _catalog.get("tuning", {}) is Dictionary:
		return _fail("missing tuning")
	var gates: Variant = _catalog.tuning.get("progression_unlock_completed")
	if not gates is Array or gates.size() != 5:
		return _fail("invalid progression gates")
	var previous := -1
	for gate in gates:
		if not _integer(gate, 0, 64) or int(gate) < previous:
			return _fail("invalid progression gates")
		previous = int(gate)
	for key in ["profile_pill_cap", "profile_kills_per_page", "profile_kills_per_herb", "progression_cost_base"]:
		if not _integer(_catalog.get("tuning", {}).get(key), 1, SAFE_INT):
			return _fail("invalid positive profile tuning")
	for key in ["profile_replay_reward", "profile_battle_reward_cap", "profile_first_herbs", "profile_battle_herb_cap", "progression_cost_step"]:
		if not _integer(_catalog.get("tuning", {}).get(key), 0, SAFE_INT):
			return _fail("invalid nonnegative profile tuning")
	return true

func _valid_data(d: Dictionary) -> bool:
	if not _json_document(d) or not _keys(d, ["schema", "completed", "pages", "branches", "herbs", "pills", "character_id", "difficulty", "settings", "current_run", "next_run_id", "last_resolved_run_id", "stats", "achievements", "seen", "challenges", "ending_seen"]):
		return false
	if not _integer(d.schema, 1, 1) or not _integer(d.completed, 0, 64) or not _integer(d.difficulty, 0, 2):
		return false
	for key in ["pages", "herbs", "last_resolved_run_id"]:
		if not _integer(d[key], 0, SAFE_INT):
			return false
	if not _integer(d.next_run_id, 1, SAFE_INT) or int(d.next_run_id) != int(d.last_resolved_run_id) + (1 if d.current_run == null else 2):
		return false
	if not d.branches is Array or d.branches.size() != 3:
		return false
	var levels := 0
	for level in d.branches:
		if not _integer(level, 0, 5):
			return false
		levels += int(level)
	if not d.character_id is String or not _unlocked_at("characters", int(d.completed)).has(d.character_id) or not _valid_settings(d.settings):
		return false
	if not d.pills is Dictionary:
		return false
	for id in d.pills:
		if not _unlocked_at("pills", int(d.completed)).has(id) or not _integer(d.pills[id], 0, _tune("profile_pill_cap")):
			return false
	if not d.stats is Dictionary or not _keys(d.stats, COUNTERS + ID_COUNTERS.keys()):
		return false
	for key in COUNTERS:
		if not _number(d.stats[key], 0, SAFE_INT) or (key not in ["damage", "damage_taken", "damage_dealt", "elapsed"] and not _integer(d.stats[key], 0, SAFE_INT)):
			return false
	if d.stats.completed != d.completed or d.stats.wins > d.stats.runs or d.stats.wins < d.completed or d.stats.total_branch_levels != levels or d.stats.branches_purchased != levels:
		return false
	for key in ID_COUNTERS:
		if not d.stats[key] is Dictionary:
			return false
		for id in d.stats[key]:
			if _lookup(ID_COUNTERS[key], id).is_empty() or not _integer(d.stats[key][id], 1, SAFE_INT):
				return false
	if d.stats.total_kills != d.stats.kills or d.stats.total_runs != d.stats.runs or d.stats.victories != d.stats.wins or d.stats.level != d.stats.max_level:
		return false
	for kind in ["achievements", "challenges", "seen"]:
		if not d[kind] is Array:
			return false
		var unique := {}
		for id in d[kind]:
			if not id is String or unique.has(id) or not _known_id(id):
				return false
			unique[id] = true
			if kind != "seen":
				var row := _lookup(kind, id)
				if row.is_empty() or int(row.unlock_after) > int(d.completed) or (kind == "achievements" and _rule_value(d.stats, row.rule) < float(row.rule.target)) or (kind == "challenges" and int(d.stats.challenge_wins.get(id, 0)) < 1):
					return false
	for id in d.stats.challenge_wins:
		if not d.challenges.has(id):
			return false
	var wins := 0
	for id in d.stats.character_wins:
		wins += int(d.stats.character_wins[id])
	var challenge_wins := 0
	for id in d.stats.challenge_wins:
		challenge_wins += int(d.stats.challenge_wins[id])
	var evolution_count := 0
	for id in d.stats.evolution_ids:
		evolution_count += int(d.stats.evolution_ids[id])
	if challenge_wins > int(d.stats.wins) or evolution_count > int(d.stats.evolutions) or d.stats.safe_wins > d.stats.wins or d.stats.risk_wins > d.stats.wins:
		return false
	if wins != int(d.stats.wins):
		return false
	if not d.ending_seen is bool or bool(d.ending_seen) != (int(d.completed) == 64):
		return false
	return d.current_run == null or _valid_run(d.current_run, d)

func _valid_run(r: Variant, d: Dictionary) -> bool:
	if not r is Dictionary or not _keys(r, ["run_id", "mission_id", "mission_index", "character_id", "difficulty", "pill_id", "challenge_id", "seed", "content_hash", "loadout", "snapshot"]):
		return false
	if not _integer(r.run_id, 1, SAFE_INT - 1) or int(r.run_id) != int(d.last_resolved_run_id) + 1 or not _integer(r.mission_index, 0, mini(63, int(d.completed))):
		return false
	if r.mission_id != _catalog.missions[int(r.mission_index)].id or r.content_hash != _content_hash:
		return false
	if not r.character_id is String or not _unlocked_at("characters", int(d.completed)).has(r.character_id) or not _integer(r.difficulty, 0, 2):
		return false
	if not r.pill_id is String or (not r.pill_id.is_empty() and not _unlocked_at("pills", int(d.completed)).has(r.pill_id)):
		return false
	if not r.challenge_id is String:
		return false
	if not r.challenge_id.is_empty():
		var challenge := _lookup("challenges", r.challenge_id)
		if challenge.is_empty() or int(challenge.unlock_after) > int(d.completed) or challenge.mission_id != r.mission_id or (not challenge.allow_pills and not r.pill_id.is_empty()):
			return false
	if not ((r.seed is String and not r.seed.is_empty() and r.seed.length() <= 128) or _integer(r.seed, 0, SAFE_INT)):
		return false
	if not r.snapshot is Dictionary or not r.loadout is Dictionary or not _keys(r.loadout, ["branches", "completed", "character_id", "difficulty", "pill_id", "challenge_id"]):
		return false
	for key in ["character_id", "difficulty", "pill_id", "challenge_id"]:
		if r.loadout[key] != r[key]:
			return false
	if r.loadout.completed != d.completed or not r.loadout.branches is Array or r.loadout.branches.size() != 3:
		return false
	for index in 3:
		if not _integer(r.loadout.branches[index], 0, int(d.branches[index])):
			return false
	return true

func _json_document(value: Variant) -> bool:
	var budget := [MAX_NODES]
	return _json_value(value, 0, budget) and JSON.stringify(value, "", true, true).to_utf8_buffer().size() <= MAX_DOCUMENT_BYTES

func _json_value(value: Variant, depth: int, budget: Array) -> bool:
	budget[0] -= 1
	if depth > 32 or budget[0] < 0:
		return false
	if value == null or value is bool:
		return true
	if value is String:
		return value.length() <= MAX_DOCUMENT_BYTES
	if value is int or value is float:
		return _number(value, -SAFE_INT, SAFE_INT)
	if value is Array:
		if value.size() > MAX_NODES:
			return false
		for item in value:
			if not _json_value(item, depth + 1, budget):
				return false
		return true
	if value is Dictionary:
		if value.size() > MAX_NODES:
			return false
		for key in value:
			if not key is String or key.length() > 1024 or not _json_value(value[key], depth + 1, budget):
				return false
		return true
	return false
