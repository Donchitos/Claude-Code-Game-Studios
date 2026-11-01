class_name LockRole
extends Node
## Lock (Kilit) role controller: Fuse Grid EMP and Remote Hack abilities.

signal fuse_grid_triggered(disabled_targets: int)
signal remote_hack_started(target: Node3D)
signal remote_hack_completed(target: Node3D)

var cooldown_q: float = 0.0
var cooldown_f: float = 0.0
var hack_progress: float = 0.0
var current_hack_target: Node3D

const EMP_RADIUS: float = 12.0
const HACK_RANGE: float = 10.0
const HACK_DURATION: float = 2.0 # 50% faster than standard terminal duration


func _process(delta: float) -> void:
	if cooldown_q > 0.0:
		cooldown_q = maxf(cooldown_q - delta, 0.0)
	if cooldown_f > 0.0:
		cooldown_f = maxf(cooldown_f - delta, 0.0)

	if is_instance_valid(current_hack_target):
		hack_progress += delta / HACK_DURATION
		if hack_progress >= 1.0:
			complete_remote_hack()


## Q: Sigorta Ağı (EMP Fuse Grid) disables electronics and turrets.
func trigger_fuse_grid(origin: Vector3, devices: Array[Node3D]) -> int:
	if cooldown_q > 0.0:
		return 0

	var count := 0
	for dev in devices:
		if is_instance_valid(dev) and dev.is_inside_tree():
			if origin.distance_to(dev.global_position) <= EMP_RADIUS:
				if dev.has_method(&"disarm"):
					dev.disarm()
					count += 1

	cooldown_q = 8.0
	fuse_grid_triggered.emit(count)
	return count


## F: Kablo Gözü (Remote Hack) starts hacking station from distance.
func start_remote_hack(origin: Vector3, station: Node3D) -> bool:
	if cooldown_f > 0.0 or not is_instance_valid(station):
		return false

	if origin.distance_to(station.global_position) > HACK_RANGE:
		return false

	current_hack_target = station
	hack_progress = 0.0
	remote_hack_started.emit(station)
	return true


func complete_remote_hack() -> void:
	if is_instance_valid(current_hack_target):
		if current_hack_target.has_method(&"activate"):
			current_hack_target.activate()
		remote_hack_completed.emit(current_hack_target)

	current_hack_target = null
	hack_progress = 0.0
	cooldown_f = 6.0


func cancel_hack() -> void:
	current_hack_target = null
	hack_progress = 0.0


func reset_role() -> void:
	cancel_hack()
	cooldown_q = 0.0
	cooldown_f = 0.0
