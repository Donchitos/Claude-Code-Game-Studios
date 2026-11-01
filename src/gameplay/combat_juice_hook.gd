class_name CombatJuiceHook
extends RefCounted
## Çatışma ve Hareket Hissiyatı Kancası (Juice & Feedback Coordinator).
## Ateş etme, hasar alma, vuruş tepkisi ve iniş darbesi olaylarını yakalayıp
## dinamik kamera sarsıntısı, hit-stop ve görsel gerilim katsayılarına dönüştürür.

const GameplayHooksScript = preload("res://src/gameplay/gameplay_hooks.gd")

var hooks: GameplayHooksScript
var hit_stop_remaining: float = 0.0
var low_health_pulse: float = 0.0
var combo_streak: int = 0
var combo_timer: float = 0.0

const COMBO_TIMEOUT: float = 3.0
const LOW_HEALTH_THRESHOLD: float = 25.0


func _init(p_hooks: GameplayHooksScript = null) -> void:
	if p_hooks != null:
		hooks = p_hooks
	else:
		hooks = GameplayHooksScript.new()


## Zaman ilerlemesi: hit-stop, kombo sayacı ve nabız zamanlayıcısını günceller.
func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	if hit_stop_remaining > 0.0:
		hit_stop_remaining = maxf(hit_stop_remaining - delta, 0.0)
	if combo_timer > 0.0:
		combo_timer = maxf(combo_timer - delta, 0.0)
		if combo_timer <= 0.0:
			combo_streak = 0
	low_health_pulse = wrapf(low_health_pulse + delta * 3.5, 0.0, TAU)


## Ateşleme kancası: tepme ve ses-görsel sarsıntı tetikler.
func on_fired() -> void:
	if hooks != null:
		hooks.notify_shot_fired()


## Hedefe başarılı vuruş kancası: kombo sayısını artırır ve vuruş ağırlığı verir.
func on_hit_confirmed(damage_amount: float, is_critical: bool = false) -> void:
	combo_streak += 1
	combo_timer = COMBO_TIMEOUT
	if hooks != null:
		hooks.notify_damage_dealt(damage_amount, is_critical)


## Oyuncu hasar aldığında tetiklenen kanca.
func on_player_damaged(amount: float) -> void:
	combo_streak = 0
	combo_timer = 0.0
	if hooks != null:
		hooks.notify_damage_received(amount)


## Yere iniş kancası: sert inişlerde kamera çökmesi ve darbe geri bildirimi.
func on_player_landed(impact_speed: float) -> void:
	if hooks != null:
		hooks.notify_landing(impact_speed)


## Can durumuna göre kritik sağlık gerilim faktörünü (0.0 - 1.0) döndürür.
func get_low_health_urgency(current_health: float, max_health: float) -> float:
	if max_health <= 0.0:
		return 0.0
	var ratio: float = (current_health / max_health) * 100.0
	if ratio >= LOW_HEALTH_THRESHOLD:
		return 0.0
	var urgency: float = 1.0 - (ratio / LOW_HEALTH_THRESHOLD)
	# Nabız dalgalanması ekle
	var wave: float = 0.8 + 0.2 * sin(low_health_pulse)
	return clampf(urgency * wave, 0.0, 1.0)
