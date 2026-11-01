class_name ComboManager
extends RefCounted
## Manages 6 dual-role synergy combos, 3.0s event window, and Uyum (Synergy) team ultimate.

signal combo_triggered(combo_name: String, bonus_damage: float, bonus_synergy: float)
signal team_ultimate_ready()
signal synergy_updated(current: float, maximum: float)

enum ComboType {
	NONE,
	BASH_AND_SHOCK,   # Breaker bash + Shock stun: AOE paralysis
	SHIELD_AND_FIRE,  # Shield wall + Rear fire: +25% damage boost
	DRONE_AND_BOMB,   # Scout scan + Grenade: Critical burst
	SMOKE_AND_REVIVE, # Carrier smoke + Downed revive: Stealth protection
	EMP_AND_STRIKE,   # Lock EMP + Melee strike: Instant knockdown
	THROW_AND_SHOOT,  # Airborne prop + Weapon shot: Mid-air explosion
}

var synergy: float = 0.0
var max_synergy: float = 100.0
var combo_window_remaining: float = 0.0
var last_action_tag: String = ""

const COMBO_WINDOW_DURATION: float = 3.0


func record_action(tag: String) -> ComboType:
	if tag.is_empty():
		return ComboType.NONE

	var triggered: ComboType = ComboType.NONE

	if combo_window_remaining > 0.0:
		if (last_action_tag == "bash" and tag == "shock") or (last_action_tag == "shock" and tag == "bash"):
			triggered = ComboType.BASH_AND_SHOCK
		elif last_action_tag == "shield" and tag == "fire":
			triggered = ComboType.SHIELD_AND_FIRE
		elif (last_action_tag == "scan" and tag == "grenade") or (last_action_tag == "grenade" and tag == "scan"):
			triggered = ComboType.DRONE_AND_BOMB
		elif (last_action_tag == "smoke" and tag == "revive") or (last_action_tag == "revive" and tag == "smoke"):
			triggered = ComboType.SMOKE_AND_REVIVE
		elif (last_action_tag == "emp" and tag == "strike") or (last_action_tag == "strike" and tag == "emp"):
			triggered = ComboType.EMP_AND_STRIKE
		elif last_action_tag == "throw" and tag == "fire":
			triggered = ComboType.THROW_AND_SHOOT

	if triggered != ComboType.NONE:
		add_synergy(25.0)
		combo_triggered.emit(_get_combo_name(triggered), 35.0, 25.0)
		combo_window_remaining = 0.0
		last_action_tag = ""
		return triggered

	last_action_tag = tag
	combo_window_remaining = COMBO_WINDOW_DURATION
	return ComboType.NONE


func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	if combo_window_remaining > 0.0:
		combo_window_remaining = maxf(combo_window_remaining - delta, 0.0)
		if combo_window_remaining <= 0.0:
			last_action_tag = ""


func add_synergy(amount: float) -> void:
	var prev: float = synergy
	synergy = clampf(synergy + amount, 0.0, max_synergy)
	synergy_updated.emit(synergy, max_synergy)
	if prev < max_synergy and synergy >= max_synergy:
		team_ultimate_ready.emit()


func consume_team_ultimate() -> bool:
	if synergy >= max_synergy:
		synergy = 0.0
		synergy_updated.emit(synergy, max_synergy)
		return true
	return false


func _get_combo_name(combo: ComboType) -> String:
	match combo:
		ComboType.BASH_AND_SHOCK: return "Darbe & Şok Dalgası"
		ComboType.SHIELD_AND_FIRE: return "Kalkan Arkası Delici Atış"
		ComboType.DRONE_AND_BOMB: return "Tarama & Hassas Patlama"
		ComboType.SMOKE_AND_REVIVE: return "Duman Altı Gizli Kurtarma"
		ComboType.EMP_AND_STRIKE: return "EMP & Ağır İndirme"
		ComboType.THROW_AND_SHOOT: return "Uçan Hücre Havada Patlatma"
	return ""


func reset() -> void:
	synergy = 0.0
	combo_window_remaining = 0.0
	last_action_tag = ""
	synergy_updated.emit(0.0, max_synergy)
