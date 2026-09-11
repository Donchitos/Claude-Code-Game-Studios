class_name ProductionProgressionSystem
extends Node

enum Status {
	OK,
	INVALID_ARGUMENT,
	NOT_INITIALIZED,
	INSUFFICIENT_PAGES,
	MAX_LEVEL,
}

const DOMAIN_KEY := "progression"
const DOMAIN_SCHEMA_VERSION := 1
const CONTENT_REVISION := 1
const MILESTONE_TICKS := 5400
const MAX_GRANT_PER_RUN := 8
const MAX_LEVEL := 5
const BRANCH_COUNT := 3

const QINGYUAN := 1
const LONGCHUN := 2
const DAYAN := 3

var _initialized := false
var _domain: Dictionary = {}


## Loads the durable domain after-image, or creates the canonical empty domain.
func initialize(domain_after_image: Dictionary = {}) -> int:
	if _initialized:
		return Status.INVALID_ARGUMENT
	var candidate := empty_domain() if domain_after_image.is_empty() else domain_after_image.duplicate(true)
	if not is_valid_domain(candidate):
		return Status.INVALID_ARGUMENT
	_domain = candidate
	_initialized = true
	return Status.OK

## Computes settlement income without publishing it before Save succeeds.
func build_income_after_image(survival_ticks: int, abandoned: bool = false) -> Dictionary:
	if not _initialized or survival_ticks < 0:
		return {"status": Status.NOT_INITIALIZED if not _initialized else Status.INVALID_ARGUMENT}
	var raw_pages := 0 if abandoned else mini(MAX_GRANT_PER_RUN, survival_ticks / MILESTONE_TICKS)
	var remaining_cost := _remaining_tree_cost(_domain)
	var grant_room := maxi(0, remaining_cost - int(_domain["unspent_pages"]))
	var granted_pages := mini(raw_pages, grant_room)
	var next_domain := _domain.duplicate(true)
	if granted_pages > 0:
		next_domain["domain_revision"] = int(next_domain["domain_revision"]) + 1
		next_domain["unspent_pages"] = int(next_domain["unspent_pages"]) + granted_pages
		next_domain["earned_pages_total"] = int(next_domain["earned_pages_total"]) + granted_pages
	return {"status": Status.OK, "granted_pages": granted_pages, "domain": next_domain}

## Computes one atomic branch purchase after-image; the caller persists it first.
func build_purchase_after_image(branch_id: int) -> Dictionary:
	if not _initialized:
		return {"status": Status.NOT_INITIALIZED}
	if branch_id < QINGYUAN or branch_id > DAYAN:
		return {"status": Status.INVALID_ARGUMENT}
	var levels: Array = _domain["branch_levels"]
	var branch_index := branch_id - 1
	var from_level := int(levels[branch_index])
	if from_level >= MAX_LEVEL:
		return {"status": Status.MAX_LEVEL}
	var to_level := from_level + 1
	var cost_pages := node_cost(to_level)
	var balance_before := int(_domain["unspent_pages"])
	if balance_before < cost_pages:
		return {"status": Status.INSUFFICIENT_PAGES}
	var next_domain := _domain.duplicate(true)
	var next_levels: Array = next_domain["branch_levels"]
	next_levels[branch_index] = to_level
	next_domain["branch_levels"] = next_levels
	next_domain["domain_revision"] = int(next_domain["domain_revision"]) + 1
	next_domain["unspent_pages"] = balance_before - cost_pages
	next_domain["spent_pages_total"] = int(next_domain["spent_pages_total"]) + cost_pages
	next_domain["upgrade_sequence"] = int(next_domain["upgrade_sequence"]) + 1
	var purchase_id := int(next_domain["next_purchase_id"])
	next_domain["next_purchase_id"] = purchase_id + 1
	next_domain["last_purchase_receipt"] = {
		"schema_version": 1,
		"purchase_id": purchase_id,
		"branch_id": branch_id,
		"from_level": from_level,
		"to_level": to_level,
		"cost_pages": cost_pages,
		"balance_before": balance_before,
		"balance_after": balance_before - cost_pages,
	}
	return {"status": Status.OK, "cost_pages": cost_pages, "domain": next_domain}

## Publishes an after-image only after its enclosing profile commit is durable.
func publish_after_image(domain_after_image: Dictionary) -> int:
	if not _initialized:
		return Status.NOT_INITIALIZED
	if not is_valid_domain(domain_after_image):
		return Status.INVALID_ARGUMENT
	_domain = domain_after_image.duplicate(true)
	return Status.OK

## Builds the immutable values that a later battle-config integration will consume.
func battle_projection() -> Dictionary:
	if not _initialized:
		return {}
	var levels: Array = _domain["branch_levels"]
	var qingyuan_level := int(levels[QINGYUAN - 1])
	var longchun_level := int(levels[LONGCHUN - 1])
	var dayan_level := int(levels[DAYAN - 1])
	return {
		"schema_version": 1,
		"source_domain_revision": int(_domain["domain_revision"]),
		"progression_content_revision": CONTENT_REVISION,
		"qingyuan_level": qingyuan_level,
		"longchun_level": longchun_level,
		"dayan_level": dayan_level,
		"attack_bonus_ratio": 0.03 * qingyuan_level,
		"max_hp_bonus_ratio": 0.03 * longchun_level,
		"crit_bonus_points": 0.01 * dayan_level,
		"pickup_bonus_ratio": 0.02 * dayan_level,
		"qingyuan_extra_pierce": 1 if qingyuan_level == MAX_LEVEL else 0,
		"longchun_charge_count": 1 if longchun_level == MAX_LEVEL else 0,
		"longchun_threshold_ratio": 0.30,
		"longchun_recovery_ratio": 0.10,
		"extra_free_refreshes": 1 if dayan_level == MAX_LEVEL else 0,
	}

func domain_snapshot() -> Dictionary:
	return _domain.duplicate(true)

static func node_cost(target_level: int) -> int:
	return 4 * target_level if target_level >= 1 and target_level <= MAX_LEVEL else 0

static func empty_domain() -> Dictionary:
	return {
		"schema_version": DOMAIN_SCHEMA_VERSION,
		"domain_revision": 0,
		"progression_content_revision": CONTENT_REVISION,
		"unspent_pages": 0,
		"earned_pages_total": 0,
		"spent_pages_total": 0,
		"upgrade_sequence": 0,
		"next_purchase_id": 1,
		"branch_levels": [0, 0, 0],
		"last_purchase_receipt": {},
	}

static func is_valid_domain(domain: Dictionary) -> bool:
	if int(domain.get("schema_version", 0)) != DOMAIN_SCHEMA_VERSION \
			or int(domain.get("progression_content_revision", 0)) != CONTENT_REVISION:
		return false
	var levels_value: Variant = domain.get("branch_levels", [])
	if not levels_value is Array or (levels_value as Array).size() != BRANCH_COUNT:
		return false
	var levels := levels_value as Array
	var sequence := 0
	var expected_spent := 0
	for level_value: Variant in levels:
		var level := int(level_value)
		if level < 0 or level > MAX_LEVEL:
			return false
		sequence += level
		expected_spent += 2 * level * (level + 1)
	var domain_revision := int(domain.get("domain_revision", -1))
	var unspent := int(domain.get("unspent_pages", -1))
	var earned := int(domain.get("earned_pages_total", -1))
	var spent := int(domain.get("spent_pages_total", -1))
	var upgrade_sequence := int(domain.get("upgrade_sequence", -1))
	var next_purchase_id := int(domain.get("next_purchase_id", -1))
	return domain_revision >= 0 \
			and unspent >= 0 \
			and earned >= 0 \
			and spent == expected_spent \
			and unspent + spent == earned \
			and upgrade_sequence == sequence \
			and next_purchase_id == sequence + 1

func _remaining_tree_cost(domain: Dictionary) -> int:
	var remaining := 0
	for level_value: Variant in domain["branch_levels"]:
		var level := int(level_value)
		for target_level in range(level + 1, MAX_LEVEL + 1):
			remaining += node_cost(target_level)
	return remaining
