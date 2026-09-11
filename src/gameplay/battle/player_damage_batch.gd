extends RefCounted

# Current Stage adapter: contact cooldown applies only to ordinary contact.
# All other accepted damage is aggregated before lethal/recovery evaluation.
var contact_amount := 0.0
var attack_amount := 0.0
var valid := true
var attack_sources: Array[String] = []
var _committed := false

func clear() -> void:
	contact_amount = 0.0
	attack_amount = 0.0
	valid = true
	attack_sources.clear()
	_committed = false

func add(amount: float, contact: bool = false, source: String = "受击") -> void:
	if _committed:
		valid = false
		return
	if not is_finite(amount) or amount < 0.0:
		valid = false
		return
	if contact:
		contact_amount = maxf(contact_amount, amount)
	else:
		attack_amount += amount
		if amount > 0.0 and not attack_sources.has(source):
			attack_sources.append(source)
	valid = valid and is_finite(attack_amount)

func commit(player) -> bool:
	if not valid or _committed or player == null:
		return false
	var contact := contact_amount if player.invulnerability_left <= 0.0 else 0.0
	var total: float = contact + attack_amount
	if not is_finite(total):
		return false
	_committed = true
	var sources := attack_sources.duplicate()
	if contact > 0.0:
		sources.push_front("敌人碰撞")
	var applied: bool = player.apply_resolved_damage(total, " / ".join(sources))
	if applied and contact > 0.0:
		player.invulnerability_left = player.contact_cooldown
	return true
