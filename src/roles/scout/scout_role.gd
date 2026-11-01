class_name ScoutRole
extends Node
## Scout role controller: Recon Drone and Sonar Scan abilities.

signal drone_deployed(drone: Node3D)
signal drone_recalled()
signal scan_triggered(detected_count: int)

const DroneScript = preload("res://src/roles/scout/recon_drone.gd")

var active_drone: Node3D
var cooldown_q: float = 0.0
var cooldown_f: float = 0.0
var scan_reveal_timer: float = 0.0
var scanned_targets: Array[Node3D] = []

const SCAN_RADIUS: float = 18.0
const SCAN_DURATION: float = 6.0


func _process(delta: float) -> void:
	if cooldown_q > 0.0:
		cooldown_q = maxf(cooldown_q - delta, 0.0)
	if cooldown_f > 0.0:
		cooldown_f = maxf(cooldown_f - delta, 0.0)
	if scan_reveal_timer > 0.0:
		scan_reveal_timer = maxf(scan_reveal_timer - delta, 0.0)
		if scan_reveal_timer <= 0.0:
			scanned_targets.clear()


## Toggle Q: Deploy or recall Recon Drone.
func toggle_drone(player: CharacterBody3D, parent_node: Node) -> Node3D:
	if is_instance_valid(active_drone):
		recall_active_drone()
		return null

	if cooldown_q > 0.0 or not is_instance_valid(player) or not is_instance_valid(parent_node):
		return null

	active_drone = DroneScript.new()
	active_drone.parent_player = player
	active_drone.position = player.global_position + Vector3(0.0, 1.8, 0.0)
	active_drone.rotation = player.rotation
	active_drone.recalled.connect(func():
		active_drone = null
		cooldown_q = 8.0
		drone_recalled.emit()
	)
	parent_node.add_child(active_drone)
	drone_deployed.emit(active_drone)
	return active_drone


func recall_active_drone() -> void:
	if is_instance_valid(active_drone):
		active_drone.recall_drone()


## Execute F: Alan Taraması (Sonar Scan).
func trigger_sonar_scan(origin: Vector3, candidate_targets: Array[Node3D]) -> int:
	if cooldown_f > 0.0:
		return 0

	scanned_targets.clear()
	for candidate in candidate_targets:
		if is_instance_valid(candidate) and candidate.is_inside_tree():
			var dist: float = origin.distance_to(candidate.global_position)
			if dist <= SCAN_RADIUS:
				scanned_targets.append(candidate)

	cooldown_f = 10.0
	scan_reveal_timer = SCAN_DURATION
	scan_triggered.emit(scanned_targets.size())
	return scanned_targets.size()


func reset_role() -> void:
	recall_active_drone()
	cooldown_q = 0.0
	cooldown_f = 0.0
	scan_reveal_timer = 0.0
	scanned_targets.clear()
