class_name RecoveryController
extends RefCounted
## Manages Downed (Sistem Çöktü), crawling, reviving, bleedout timer, and team recovery.

signal state_changed(old_state: State, new_state: State)
signal bleedout_tick(seconds_remaining: float)
signal revived(health_restored: float)
signal bleedout_expired()

enum State {
	HEALTHY,
	DOWNED,       # Sistem Çöktü: slow crawl, cannot shoot, bleedout timer active
	REVIVING,     # Being revived by ally
	DEAD,         # Bleedout expired
}

var current_state: State = State.HEALTHY
var bleedout_remaining: float = 20.0
var revive_progress: float = 0.0

const MAX_BLEEDOUT_TIME: float = 20.0
const REVIVE_DURATION_BASE: float = 3.0
const CRAWL_SPEED: float = 1.2


func enter_downed() -> void:
	if current_state == State.DOWNED or current_state == State.DEAD:
		return

	var old: State = current_state
	current_state = State.DOWNED
	bleedout_remaining = MAX_BLEEDOUT_TIME
	revive_progress = 0.0
	state_changed.emit(old, current_state)


func update(delta: float) -> void:
	if delta <= 0.0:
		return

	match current_state:
		State.DOWNED:
			bleedout_remaining -= delta
			bleedout_tick.emit(bleedout_remaining)
			if bleedout_remaining <= 0.0:
				var old: State = current_state
				current_state = State.DEAD
				state_changed.emit(old, current_state)
				bleedout_expired.emit()

		State.REVIVING:
			# Revive progress is stepped by rescuer
			pass


## Advance revive progress; speed multiplier applies for Scout passive.
func step_revive(delta: float, speed_mult: float = 1.0) -> bool:
	if current_state != State.DOWNED and current_state != State.REVIVING:
		return false

	current_state = State.REVIVING
	var duration: float = maxf(REVIVE_DURATION_BASE / maxf(speed_mult, 0.1), 0.1)
	revive_progress += delta / duration

	if revive_progress >= 1.0:
		var old: State = current_state
		current_state = State.HEALTHY
		revive_progress = 0.0
		state_changed.emit(old, current_state)
		revived.emit(35.0) # Restored with 35 HP
		return true

	return false


func cancel_revive() -> void:
	if current_state == State.REVIVING:
		var old: State = current_state
		current_state = State.DOWNED
		revive_progress = 0.0
		state_changed.emit(old, current_state)


func reset() -> void:
	current_state = State.HEALTHY
	bleedout_remaining = MAX_BLEEDOUT_TIME
	revive_progress = 0.0
