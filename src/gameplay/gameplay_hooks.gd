class_name GameplayHooks
extends RefCounted
## Merkezi Oyun Dinamikleri Kanca Dağıtıcısı (Gameplay Event & Juice Bus).
## Tüm dinamik hissiyat (juice), kamera sarsıntısı, hit-stop ve Yönetmen olayları
## bu kanca yöneticisi üzerinden gevşek bağlı (loosely coupled) olarak dağıtılır.

signal shake_requested(trauma_amount: float)
signal hit_stop_requested(duration: float)
signal landing_impact(speed: float)
signal pacing_state_changed(new_state: String, tension: float)
signal director_event_triggered(event_name: String, payload: Dictionary)
signal synergy_changed(current_synergy: float, max_synergy: float)

var enabled: bool = true
var hit_stop_timer: float = 0.0


## Kamera sarsıntısı tetikler (trauma değeri 0.0 - 1.0 arası).
func request_shake(trauma: float) -> void:
	if not enabled or trauma <= 0.0:
		return
	shake_requested.emit(clampf(trauma, 0.0, 1.0))


## Ağır vuruş anında mikro-donma (hit-stop) kancasını çalıştırır.
func request_hit_stop(duration: float) -> void:
	if not enabled or duration <= 0.0:
		return
	hit_stop_timer = clampf(duration, 0.01, 0.15)
	hit_stop_requested.emit(hit_stop_timer)


## Karakter yere indiğinde düşüş hızına göre iniş darbe kancasını tetikler.
func notify_landing(speed: float) -> void:
	if not enabled or speed <= 0.0:
		return
	landing_impact.emit(speed)
	# Sert inişlerde (hız > 6.0 m/s) otomatik hafif kamera sarsıntısı
	if speed > 6.0:
		var trauma: float = clampf((speed - 6.0) / 12.0, 0.05, 0.45)
		request_shake(trauma)


## Ateş edildiğinde geri tepme sarsıntısı tetikler.
func notify_shot_fired() -> void:
	if not enabled:
		return
	request_shake(0.12)


## Hasar verildiğinde vuruş ağırlığını ve hit-stop'u yönetir.
func notify_damage_dealt(amount: float, is_critical: bool = false) -> void:
	if not enabled or amount <= 0.0:
		return
	if is_critical or amount >= 50.0:
		request_hit_stop(0.045)
		request_shake(0.35)
	else:
		request_shake(0.15)


## Hasar alındığında gerilim sarsıntısı tetikler.
func notify_damage_received(amount: float) -> void:
	if not enabled or amount <= 0.0:
		return
	var trauma: float = clampf(amount / 40.0, 0.2, 0.75)
	request_shake(trauma)


## Yönetmen gerilim durumunu günceller.
func notify_pacing(state_name: String, tension_score: float) -> void:
	if not enabled:
		return
	pacing_state_changed.emit(state_name, tension_score)


## Yönetmen sürpriz olayını tetikler (örn. Düşüş Kasası, Işık Kararması).
func trigger_director_event(event_name: String, payload: Dictionary = {}) -> void:
	if not enabled:
		return
	director_event_triggered.emit(event_name, payload)
