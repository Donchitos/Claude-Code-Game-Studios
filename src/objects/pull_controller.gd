class_name PullController
extends RefCounted
## Pull & Drag physics controller: pulls distant items/power cells toward player along ground.
## Enforces 6.0m max range, line-of-sight obstruction checks, weight damping, and release.

signal pull_started(target: Node3D)
signal pull_cancelled(reason: String)
signal pull_completed(target: Node3D)

var active_target: Node3D
var pull_strength: float = 14.0
var max_range: float = 6.0
var is_pulling: bool = false

const MIN_ARRIVAL_DISTANCE: float = 1.2


func try_start_pull(puller_pos: Vector3, candidate: Node3D, has_clear_los: bool) -> bool:
	if is_pulling or not is_instance_valid(candidate):
		return false

	var dist: float = puller_pos.distance_to(candidate.global_position)
	if dist > max_range:
		pull_cancelled.emit("Menzil Dışı")
		return false

	if not has_clear_los:
		pull_cancelled.emit("Görüş Engelli")
		return false

	active_target = candidate
	is_pulling = true
	pull_started.emit(candidate)
	return true


func step_pull(puller_pos: Vector3, delta: float, has_clear_los: bool) -> void:
	if not is_pulling or not is_instance_valid(active_target):
		cancel_pull("Hedef Kaybı")
		return

	if not has_clear_los:
		cancel_pull("Duvar Arkası")
		return

	var to_puller: Vector3 = puller_pos - active_target.global_position
	var dist: float = Vector2(to_puller.x, to_puller.z).length()

	if dist <= MIN_ARRIVAL_DISTANCE:
		# Object arrived within reach!
		var finished: Node3D = active_target
		cancel_pull("Ulaştı")
		pull_completed.emit(finished)
		return

	var pull_dir := Vector3(to_puller.x, 0.0, to_puller.z).normalized()
	var mass: float = active_target.get("mass") if "mass" in active_target else 1.0
	var speed: float = pull_strength / maxf(mass * 0.15, 1.0)

	if active_target is CharacterBody3D:
		active_target.velocity.x = pull_dir.x * speed
		active_target.velocity.z = pull_dir.z * speed
		active_target.move_and_slide()
	else:
		active_target.global_position += pull_dir * speed * delta


func cancel_pull(reason: String = "") -> void:
	is_pulling = false
	active_target = null
	if not reason.is_empty():
		pull_cancelled.emit(reason)


func reset() -> void:
	cancel_pull()
