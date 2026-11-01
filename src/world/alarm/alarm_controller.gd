class_name AlarmController
extends RefCounted
## 0-4 tier facility alarm system managing reinforcement gates, lockdowns, and terminal hacking reductions.

signal alarm_level_changed(old_level: int, new_level: int)
signal lockdown_triggered(doors_locked: bool)
signal reinforcements_spawned(count: int)

enum AlarmLevel {
	LEVEL_0_QUIET = 0,      # Normal quiet patrol, green lights, all gates open
	LEVEL_1_SUSPICIOUS = 1, # Yellow lighting, heightened guard vision
	LEVEL_2_ALERT = 2,      # Red alarm sirens, sector gates lock, first reinforcements
	LEVEL_3_BLOCKADE = 3,   # Heavy lockdown, auto-turrets enabled, 2x hack time
	LEVEL_4_COLLAPSE = 4,   # Full protocol collapse: emergency evacuation sequence & Chief spawn
}

var current_level: int = 0
var level_timer: float = 0.0

const TIME_TO_AUTO_DECAY: float = 45.0


func raise_alarm(to_level: int) -> void:
	var clamped: int = clampi(to_level, 0, 4)
	if clamped <= current_level:
		return

	var old: int = current_level
	current_level = clamped
	level_timer = 0.0
	alarm_level_changed.emit(old, current_level)

	if current_level >= AlarmLevel.LEVEL_2_ALERT:
		lockdown_triggered.emit(true)
		reinforcements_spawned.emit(current_level)


func reduce_alarm_at_terminal() -> bool:
	if current_level <= 0:
		return false

	var old: int = current_level
	current_level = maxi(current_level - 1, 0)
	alarm_level_changed.emit(old, current_level)

	if current_level < AlarmLevel.LEVEL_2_ALERT:
		lockdown_triggered.emit(false)

	return true


func advance(delta: float) -> void:
	if delta <= 0.0 or current_level == 0:
		return

	level_timer += delta
	# High alarms do not decay without terminal hack
	if current_level == AlarmLevel.LEVEL_1_SUSPICIOUS and level_timer >= TIME_TO_AUTO_DECAY:
		reduce_alarm_at_terminal()


func reset_alarm() -> void:
	var old: int = current_level
	current_level = 0
	level_timer = 0.0
	if old != 0:
		alarm_level_changed.emit(old, 0)
	lockdown_triggered.emit(false)
