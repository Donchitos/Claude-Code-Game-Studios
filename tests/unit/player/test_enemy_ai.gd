extends SceneTree
## Unit tests for EnemyBot AI: chasing, attacks, damage handling, stun and reset.

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
	var bot: CharacterBody3D = EnemyBotScript.new()
	bot.spawn_position = Vector3(0.0, 0.0, 5.0)
	root.add_child(bot)
	await process_frame

	# 1. Initialization
	_check(bot.health == 60.0, "EnemyBot starts with 60 max health")
	_check(bot.team == 1, "EnemyBot is on opposing team (1)")
	_check(bot.active, "EnemyBot is active by default")

	# 2. Damage reception
	var damaged: bool = bot.receive_hit(20.0, 0)
	_check(damaged and bot.health == 40.0, "Player hit (team 0) inflicts 20 damage")

	# Friendly fire rejection
	var friendly_hit: bool = bot.receive_hit(20.0, 1)
	_check(not friendly_hit and bot.health == 40.0, "Friendly hit (team 1) is rejected")

	# 3. Stun reaction
	var stun_hit: bool = bot.receive_hit(5.0, 0, 1.5)
	_check(stun_hit and bot.stun_remaining >= 1.4, "Stun parameter applies stun duration")

	# When stunned, bot does not chase
	var mock_player := Node3D.new()
	mock_player.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(mock_player)
	bot.target = mock_player
	bot.velocity = Vector3(5.0, 0.0, 5.0)
	bot._physics_process(0.1)
	_check(bot.velocity.length() < 7.0, "Stunned enemy decelerates instead of pursuing")

	# Clear stun
	bot.stun_remaining = 0.0

	# 4. Chasing target
	bot._physics_process(0.2)
	# Target is at Z=0, bot is at Z=5, so move direction is -Z
	_check(bot.velocity.z < 0.0, "Active enemy accelerates toward player (-Z)")

	# 5. Attack in melee range
	bot.global_position = Vector3(0.0, 0.0, 1.0) # within 1.3m attack range
	var attack_observed := [0.0]
	bot.attack_dealt.connect(func(amt: float): attack_observed[0] = amt)
	bot._physics_process(0.1)
	_check(attack_observed[0] == bot.attack_damage, "Enemy strikes when in melee range")
	_check(bot._attack_timer > 0.0, "Attack enters cooldown timer")

	# 6. Death
	var defeated_emitted := [false]
	bot.defeated.connect(func(): defeated_emitted[0] = true)
	bot.receive_hit(100.0, 0)
	await process_frame
	_check(bot.health == 0.0 and defeated_emitted[0], "Lethal damage reduces health to 0 and emits defeated")
	_check(bot._collision.disabled, "Defeat disables physics collision")

	# 7. Reset
	bot.reset_bot()
	_check(bot.health == bot.max_health, "Reset restores full health")
	_check(not bot._collision.disabled, "Reset re-enables collision")
	_check(bot.stun_remaining == 0.0, "Reset clears stun state")
	_check(bot.global_position.distance_to(bot.spawn_position) < 0.01, "Reset returns bot to spawn position")

	mock_player.queue_free()
	bot.queue_free()
	await process_frame

	print("EnemyBot tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
