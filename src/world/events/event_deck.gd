class_name EventDeck
extends RefCounted
## Dynamic 10-event procedural card deck for Sector 9:
## Premonition -> Active -> Cleanup lifecycle, harmless event distinction, and resource cleanup.

signal event_warning(event_id: String, premonition_text: String)
signal event_started(event_id: String, duration: float)
signal event_ended(event_id: String)

enum EventType {
	FIRE_OUTBREAK,
	EXTRA_PATROL,
	POWER_CUT,
	FALSE_ALARM,
	CRATE_RAIN,
	RELOCATED_DOOR,
	LOST_ITEM,
	OVERHEAT,
	TWIN_BOT,
	CONFETTI,
}

var active_event: int = -1
var event_timer: float = 0.0
var premonition_timer: float = 0.0
var spawned_nodes: Array[Node] = []

const PREMONITION_DURATION: float = 2.5


func trigger_event(event: EventType, duration: float = 10.0) -> void:
	cleanup_active_event()
	active_event = event as int
	premonition_timer = PREMONITION_DURATION
	event_timer = duration
	event_warning.emit(get_event_name(event), get_premonition_text(event))


func advance(delta: float) -> void:
	if delta <= 0.0 or active_event == -1:
		return

	if premonition_timer > 0.0:
		premonition_timer -= delta
		if premonition_timer <= 0.0:
			event_started.emit(get_event_name(active_event as EventType), event_timer)
		return

	event_timer -= delta
	if event_timer <= 0.0:
		cleanup_active_event()


func cleanup_active_event() -> void:
	if active_event != -1:
		event_ended.emit(get_event_name(active_event as EventType))
	for n in spawned_nodes:
		if is_instance_valid(n):
			n.queue_free()
	spawned_nodes.clear()
	active_event = -1
	event_timer = 0.0
	premonition_timer = 0.0


func is_harmless(event: EventType) -> bool:
	return event == EventType.FALSE_ALARM or event == EventType.CONFETTI or event == EventType.CRATE_RAIN


func get_event_name(event: EventType) -> String:
	match event:
		EventType.FIRE_OUTBREAK: return "Yangın Çıkışı"
		EventType.EXTRA_PATROL: return "Ekstra Devriye"
		EventType.POWER_CUT: return "Güç Kesintisi"
		EventType.FALSE_ALARM: return "Yanlış Alarm"
		EventType.CRATE_RAIN: return "Kasa Yağmuru"
		EventType.RELOCATED_DOOR: return "Taşınmış Kapı"
		EventType.LOST_ITEM: return "Kayıp Eşya"
		EventType.OVERHEAT: return "Aşırı Isınma"
		EventType.TWIN_BOT: return "İkiz Bot"
		EventType.CONFETTI: return "Konfeti Yağmuru"
	return "Olay"


func get_premonition_text(event: EventType) -> String:
	match event:
		EventType.FIRE_OUTBREAK: return "UYARI: Havalandırmada aşırı ısı tespit edildi!"
		EventType.EXTRA_PATROL: return "TELSİZ: Sektöre ek devriye intikal ediyor."
		EventType.POWER_CUT: return "DİKKAT: Ana jeneratör voltajı düşüyor..."
		EventType.FALSE_ALARM: return "BİLGİ: Sensör hatası; yanlış anons."
		EventType.CRATE_RAIN: return "LOJİSTİK: İkmal kapsülü tavandan serbest bırakıldı."
		EventType.CONFETTI: return "KOMİK: Tatbikat başarı kutlaması!"
	return "DİKKAT: Çevresel anomali yaklaşıyor!"
