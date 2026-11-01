extends SceneTree
## Unit tests for Kırıcı (Breaker) role: Shoulder Bash, Shield Wall, and collision reactions.

const BreakerScript = preload("res://src/roles/breaker/breaker_role.gd")
const ShieldWallScript = preload("res://src/roles/breaker/shield_wall.gd")
const PropScript = preload("res://src/combat/damageable_prop.gd")
const EnemyBotScript = preload("res://src/combat/enemy_bot.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run_tests")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _run_tests() -> void:
	var breaker = BreakerScript.new()
	root.add_child(breaker)
	await process_frame

	# 1. Initialization
	_check(breaker.cooldown_q == 0.0 and breaker.cooldown_f == 0.0, "Cooldowns start ready")
	_check(not breaker.is_bashing, "Starts outside bash state")

	# Mock player
	var player = CharacterBody3D.new()
	player.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(player)

	# 2. Shoulder Bash execution
	var bash_started_seen := [false]
	breaker.bash_started.connect(func(): bash_started_seen[0] = true)
	var started: bool = breaker.try_shoulder_bash(player)
	_check(started and breaker.is_bashing and bash_started_seen[0], "Shoulder bash begins successfully")
	_check(breaker.cooldown_q > 4.0, "Bash sets Q cooldown to 5.0s")

	# Advance bash motion
	breaker.step_bash(player, 0.1)
	_check(player.velocity.length() > 10.0, "Bash applies high velocity forward")

	# Re-triggering during cooldown is rejected
	_check(not breaker.try_shoulder_bash(player), "Bash rejected during active cooldown")

	# Bash end
	breaker.end_bash()
	_check(not breaker.is_bashing, "Ending bash clears bashing flag")

	# 3. Shield Wall deployment
	var wall: Node3D = breaker.try_deploy_shield(player, root)
	_check(is_instance_valid(wall), "Deploy shield creates ShieldWall instance")
	_check(breaker.cooldown_f > 10.0, "Deploy shield sets F cooldown to 12.0s")

	# Test ShieldWall damage absorption
	if is_instance_valid(wall) and wall.has_method(&"receive_hit"):
		var prev_hp: float = wall.health
		# Enemy hit (team 1) damages wall
		var damaged: bool = wall.receive_hit(40.0, 1)
		_check(damaged and wall.health == prev_hp - 40.0, "Hostile damage (team 1) reduces shield wall health")
		# Friendly hit (team 0) passes through without damaging wall
		var friendly_hit: bool = wall.receive_hit(30.0, 0)
		_check(not friendly_hit and wall.health == prev_hp - 40.0, "Friendly damage passes through shield wall")

	# 4. Reset
	breaker.reset_role()
	_check(breaker.cooldown_q == 0.0 and breaker.cooldown_f == 0.0, "Reset clears all ability cooldowns")
	_check(not breaker.is_bashing, "Reset clears bash state")

	if is_instance_valid(wall):
		wall.queue_free()
	player.queue_free()
	breaker.queue_free()
	await process_frame

	print("BreakerRole tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
