class_name DirectorPacingHook
extends RefCounted
## Yönetmen ve Gerilim Temposu Kancası (Director & Pacing Dynamics).
## Sector 9 Tasarım Belgesi uyarınca oyunun temposunu (peaks and valleys)
## ve gerilim puanını hesaplayarak dinamik olaylar tetikler.

const GameplayHooksScript = preload("res://src/gameplay/gameplay_hooks.gd")

enum PacingState {
	CALM,       ## Nefes aralığı: düşük tehdit, toparlanma
	BUILDUP,    ## Gerilim tırmanışı: arama, yaklaşan tehlike
	PEAK,       ## Aksiyon zirvesi: yoğun temas, düşman dalgası
	RECOVERY    ## Çatışma sonrası: nefes alma ve yağmalama
}

var hooks: GameplayHooksScript
var current_state: PacingState = PacingState.CALM
var tension_score: float = 0.0  ## 0.0 - 100.0 arası gerilim metriği
var state_timer: float = 0.0
var time_since_last_event: float = 0.0
var airdrop_spawned: bool = false

const MAX_TENSION: float = 100.0
const EVENT_COOLDOWN: float = 15.0


func _init(p_hooks: GameplayHooksScript = null) -> void:
	if p_hooks != null:
		hooks = p_hooks
	else:
		hooks = GameplayHooksScript.new()


## Zaman ve durum güncellemesi
func advance(delta: float, health_percent: float, ammo_percent: float) -> void:
	if delta <= 0.0:
		return
	state_timer += delta
	time_since_last_event += delta

	# Kaynak baskısı hesabı: Can ve mermi çok azaldığında Yönetmen nefes aralığı tanır (GDD kuralı)
	var is_team_exhausted: bool = (health_percent < 0.25 or ammo_percent <= 0.0)

	# Doğal gerilim dalgalanması
	match current_state:
		PacingState.CALM:
			tension_score = maxf(tension_score - delta * 4.0, 0.0)
			if state_timer >= 10.0 and not is_team_exhausted:
				_transition_to(PacingState.BUILDUP)

		PacingState.BUILDUP:
			tension_score = minf(tension_score + delta * 6.0, 70.0)
			if state_timer >= 12.0 or tension_score >= 65.0:
				_transition_to(PacingState.PEAK)

		PacingState.PEAK:
			tension_score = minf(tension_score + delta * 3.0, MAX_TENSION)
			if state_timer >= 15.0 or is_team_exhausted:
				_transition_to(PacingState.RECOVERY)

		PacingState.RECOVERY:
			tension_score = maxf(tension_score - delta * 8.0, 10.0)
			if state_timer >= 8.0:
				_transition_to(PacingState.CALM)

	if hooks != null:
		hooks.notify_pacing(get_state_name(), tension_score)


## Çatışma aksiyonu anında gerilim puanını sıçratır.
func add_combat_heat(amount: float) -> void:
	tension_score = minf(tension_score + amount, MAX_TENSION)
	if tension_score >= 70.0 and current_state != PacingState.PEAK:
		_transition_to(PacingState.PEAK)


## Olay kontrolü: Uygun şartlar oluştuğunda Düşüş Kasası veya Dreamcore olayı tetikler.
func check_and_trigger_director_event() -> bool:
	if time_since_last_event < EVENT_COOLDOWN:
		return false

	if not airdrop_spawned and current_state == PacingState.BUILDUP and tension_score >= 40.0:
		airdrop_spawned = true
		time_since_last_event = 0.0
		if hooks != null:
			hooks.trigger_director_event("airdrop_crate", {
				"type": "airdrop",
				"message": "Düşüş Kasası tespit edildi! Tavandan duman işareti yükseliyor."
			})
		return true

	if current_state == PacingState.PEAK and time_since_last_event >= EVENT_COOLDOWN:
		time_since_last_event = 0.0
		if hooks != null:
			hooks.trigger_director_event("light_flicker", {
				"type": "dreamcore_anomaly",
				"message": "Işıklarda anlık gerilim dalgalanması!"
			})
		return true

	return false


func get_state_name() -> String:
	match current_state:
		PacingState.CALM: return "CALM"
		PacingState.BUILDUP: return "BUILDUP"
		PacingState.PEAK: return "PEAK"
		PacingState.RECOVERY: return "RECOVERY"
	return "UNKNOWN"


func _transition_to(new_state: PacingState) -> void:
	current_state = new_state
	state_timer = 0.0
	if hooks != null:
		hooks.notify_pacing(get_state_name(), tension_score)
