extends SceneTree
## Unit tests for EnemyBot Flinch & Suppression: attack interruption, flinch recovery, and speed suppression.

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

	var mock_player := Node3D.new()
	mock_player.position = Vector3.ZERO
	root.add_child(mock_player)
	bot.target = mock_player

	# 1. Light damage (<18) does not flinch
	bot.receive_hit(10.0, 0)
	_check(bot.flinch_timer == 0.0, "Light damage (10.0) does not trigger flinch")
	_check(not bot.is_suppressed, "Light damage does not trigger suppression")

	# 2. Heavy damage (>=18) triggers flinch & interrupts attack
	var flinch_seen := [false]
	bot.flinched.connect(func(): flinch_seen[0] = true)

	bot._attack_timer = 0.05 # About to strike
	bot.receive_hit(25.0, 0) # Heavy hit (e.g. Carbine or Active Reload)
	_check(bot.flinch_timer > 0.2 and flinch_seen[0], "Heavy damage (25.0) triggers flinch state")
	_check(bot._attack_timer >= 0.35, "Flinch interrupts active attack and adds +0.35s delay")

	# 3. During flinch, pursuit is halted
	bot.velocity = Vector3(5.0, 0.0, -5.0)
	bot._physics_process(0.1)
	_check(bot.velocity.length() < 6.0, "Flinching enemy decelerates instead of pursuing")

	# 4. Suppression slows down enemy
	_check(bot.is_suppressed, "Repeated hits accumulate suppression (>=45)")
	bot.flinch_timer = 0.0 # Clear flinch to test chase speed
	bot.global_position = Vector3(0.0, 0.0, 4.0)
	bot._physics_process(0.2)
	# Max speed should be 3.6 * 0.6 = 2.16 m/s
	_check(absf(bot.velocity.z) < 2.5, "Suppressed enemy moves at 60% speed")

	# 5. Reset
	bot.reset_bot()
	_check(bot.flinch_timer == 0.0 and not bot.is_suppressed and bot.suppression == 0.0, "Reset clears flinch and suppression")

	mock_player.queue_free()
	bot.queue_free()
	await process_frame

	print("Flinch & Suppression tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
