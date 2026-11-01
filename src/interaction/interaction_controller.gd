extends Node
## Target selection is injected by world queries; UI only observes this state.

@export var reach: float = 2.5
var toggle_mode := false
var candidate: Node3D
var progress := 0.0
var reason := ""
var _active := false
var _elapsed := 0.0

## Update target admission every frame; changing or invalidating target cancels work.
func set_candidate(target: Node3D, player_point: Vector3, clear_los: bool) -> void:
	if target != candidate:
		cancel()
	candidate = target
	reason = ""
	if not is_instance_valid(candidate):
		cancel()
		return
	if candidate.completed:
		reason = tr("Tamamlandı")
	elif candidate.get("hack_only") == true:
		reason = tr("Kilit: Q ile hackle")
	elif player_point.distance_to(candidate.global_position) > reach:
		reason = tr("Çok uzak")
	elif not clear_los:
		reason = tr("Görüş engelli")
	if not reason.is_empty():
		cancel()

## Rising press starts an action; release cancels hold mode; a second toggle cancels.
func step(pressed: bool, held: bool, delta: float) -> void:
	if not is_instance_valid(candidate) or not reason.is_empty() or candidate.completed:
		cancel()
		return
	if pressed:
		if toggle_mode and _active:
			cancel()
			return
		_active = true
	if not toggle_mode and not held:
		cancel()
	if not _active or not is_finite(delta) or delta <= 0.0:
		return
	_elapsed += delta
	var duration: float = maxf(candidate.hold_duration, 0.0)
	progress = 1.0 if duration == 0.0 else clampf(_elapsed / duration, 0.0, 1.0)
	if progress >= 1.0:
		candidate.activate()
		cancel()

## Explicit cancellation is used on pause, focus loss, reset, target loss and mode changes.
func cancel() -> void:
	_active = false
	_elapsed = 0.0
	progress = 0.0
