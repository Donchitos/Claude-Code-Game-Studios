class_name CoreExtractionScenario
extends RefCounted
## End-to-end playable mission rehearsal loop:
## Infiltrate -> Secure Core -> Defend Carrier -> Evacuate -> Mission Accomplished / Wipe.

signal step_changed(old_step: Step, new_step: Step, description: String)
signal mission_completed(summary: Dictionary)
signal mission_failed(reason: String)

enum Step {
	INFILTRATE,         # Objective 1: Reach & hack vault terminal
	SECURE_CORE,        # Objective 2: Pick up heavy energy core
	DEFEND_CARRIER,     # Objective 3: Fight through pursuers while carrying core
	EVACUATE,           # Objective 4: Reach evacuation pad & hold for 5s
	COMPLETED,          # Mission victory
	FAILED,             # Squad wiped
}

var current_step: Step = Step.INFILTRATE
var evac_hold_progress: float = 0.0
var elapsed_time: float = 0.0
var enemies_defeated: int = 0
var damage_taken: float = 0.0
var seed_number: int = 42

const EVAC_HOLD_DURATION: float = 5.0


func advance(delta: float) -> void:
	if delta <= 0.0 or current_step == Step.COMPLETED or current_step == Step.FAILED:
		return

	elapsed_time += delta


## Advance objective on player actions: terminal hacked, core picked up, evac reached.
func report_terminal_hacked() -> bool:
	if current_step != Step.INFILTRATE:
		return false
	_transition_to(Step.SECURE_CORE, "Çekirdeği Ele Geçir!")
	return true


func report_core_secured() -> bool:
	if current_step != Step.SECURE_CORE:
		return false
	_transition_to(Step.DEFEND_CARRIER, "Taşıyıcıyı Koru ve Tahliye Noktasına İlerle!")
	return true


func step_evacuation_hold(delta: float, is_on_evac_pad: bool) -> bool:
	if current_step != Step.DEFEND_CARRIER and current_step != Step.EVACUATE:
		return false

	current_step = Step.EVACUATE

	if is_on_evac_pad:
		evac_hold_progress += delta / EVAC_HOLD_DURATION
		if evac_hold_progress >= 1.0:
			_transition_to(Step.COMPLETED, "Görev Başarılı! Tahliye Tamamlandı.")
			var summary := {
				"seed": seed_number,
				"elapsed_time": elapsed_time,
				"enemies_defeated": enemies_defeated,
				"damage_taken": damage_taken,
			}
			mission_completed.emit(summary)
			return true
	else:
		evac_hold_progress = maxf(evac_hold_progress - delta * 0.5, 0.0)

	return false


func report_squad_wiped() -> void:
	if current_step != Step.COMPLETED:
		_transition_to(Step.FAILED, "Tüm Takım Çöktü! Görev Başarısız.")
		mission_failed.emit("Sistem Çöküşü")


func _transition_to(new_step: Step, desc: String) -> void:
	var old: Step = current_step
	current_step = new_step
	step_changed.emit(old, new_step, desc)


func reset() -> void:
	current_step = Step.INFILTRATE
	evac_hold_progress = 0.0
	elapsed_time = 0.0
	enemies_defeated = 0
	damage_taken = 0.0
