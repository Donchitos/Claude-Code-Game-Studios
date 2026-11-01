extends SceneTree
## Unit test for GameplayHooks, CombatJuiceHook, DirectorPacingHook, and Camera Juice.

const GameplayHooksScript = preload("res://src/gameplay/gameplay_hooks.gd")
const CombatJuiceHookScript = preload("res://src/gameplay/combat_juice_hook.gd")
const DirectorPacingHookScript = preload("res://src/gameplay/director_pacing_hook.gd")
const CameraScript = preload("res://src/camera/player_camera.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_test_gameplay_hooks_bus()
	_test_combat_juice_hook()
	_test_director_pacing_hook()
	_test_camera_juice()
	_finish()


func _test_gameplay_hooks_bus() -> void:
	var bus = GameplayHooksScript.new()
	_expect(bus.enabled, "GameplayHooks starts enabled")

	var shake_val := [0.0]
	bus.shake_requested.connect(func(t: float): shake_val[0] = t)

	bus.request_shake(0.5)
	_expect(is_equal_approx(shake_val[0], 0.5), "request_shake transmits trauma value")

	bus.request_shake(1.5)
	_expect(is_equal_approx(shake_val[0], 1.0), "request_shake clamps trauma to 1.0 max")

	bus.request_shake(-0.2)
	_expect(is_equal_approx(shake_val[0], 1.0), "negative trauma does not emit")

	var hit_stop_val := [0.0]
	bus.hit_stop_requested.connect(func(d: float): hit_stop_val[0] = d)

	bus.request_hit_stop(0.05)
	_expect(is_equal_approx(hit_stop_val[0], 0.05), "hit_stop duration transmits")

	bus.request_hit_stop(0.5)
	_expect(is_equal_approx(hit_stop_val[0], 0.15), "hit_stop clamps to 0.15s max safeguard")

	# Landing notification
	var landing_val := [0.0]
	bus.landing_impact.connect(func(s: float): landing_val[0] = s)

	bus.notify_landing(4.0)
	_expect(is_equal_approx(landing_val[0], 4.0), "landing impact speed transmits")

	bus.notify_landing(10.0)
	_expect(is_equal_approx(landing_val[0], 10.0), "heavy landing transmits speed")
	_expect(shake_val[0] > 0.1, "heavy landing (>6.0m/s) triggers automatic shake trauma")

	# Damage dealt
	bus.notify_damage_dealt(60.0, true)
	_expect(is_equal_approx(hit_stop_val[0], 0.045), "critical heavy damage triggers hit-stop")


func _test_combat_juice_hook() -> void:
	var bus = GameplayHooksScript.new()
	var juice = CombatJuiceHookScript.new(bus)

	var shake_val := [0.0]
	bus.shake_requested.connect(func(t: float): shake_val[0] = t)

	juice.on_fired()
	_expect(is_equal_approx(shake_val[0], 0.12), "firing weapon requests shot trauma")

	_expect(juice.combo_streak == 0, "combo starts at 0")
	juice.on_hit_confirmed(25.0, false)
	_expect(juice.combo_streak == 1, "hit increments combo streak")
	_expect(juice.combo_timer > 2.0, "hit sets combo timer")

	juice.on_hit_confirmed(30.0, false)
	_expect(juice.combo_streak == 2, "consecutive hit increments combo streak")

	# Combo decay
	juice.advance(3.5)
	_expect(juice.combo_streak == 0, "combo resets when timer expires")

	# Damage taken resets combo
	juice.on_hit_confirmed(20.0, false)
	_expect(juice.combo_streak == 1, "new combo started")
	juice.on_player_damaged(15.0)
	_expect(juice.combo_streak == 0, "taking damage resets combo streak")

	# Low health urgency test
	var healthy_urgency: float = juice.get_low_health_urgency(100.0, 100.0)
	_expect(is_zero_approx(healthy_urgency), "healthy player (100%) has zero low health urgency")

	var mid_urgency: float = juice.get_low_health_urgency(50.0, 100.0)
	_expect(is_zero_approx(mid_urgency), "50% health is above 25% threshold, zero urgency")

	var critical_urgency: float = juice.get_low_health_urgency(10.0, 100.0)
	_expect(critical_urgency > 0.4, "critical health (10%) produces strong urgency wave")


func _test_director_pacing_hook() -> void:
	var bus = GameplayHooksScript.new()
	var director = DirectorPacingHookScript.new(bus)

	_expect(director.current_state == DirectorPacingHookScript.PacingState.CALM, "Director starts in CALM state")
	_expect(director.get_state_name() == "CALM", "get_state_name returns CALM")

	# Combat heat pushes to PEAK
	director.add_combat_heat(80.0)
	_expect(director.current_state == DirectorPacingHookScript.PacingState.PEAK, "High combat heat triggers PEAK state")

	# Relief under exhaustion
	director.advance(1.0, 0.15, 0.0) # team exhausted (low health & zero ammo)
	_expect(director.current_state == DirectorPacingHookScript.PacingState.RECOVERY, "Exhausted team transitions to RECOVERY for breathing room")

	# State transition to CALM
	director.advance(9.0, 0.5, 0.5)
	_expect(director.current_state == DirectorPacingHookScript.PacingState.CALM, "Recovery completes into CALM")

	# Airdrop crate event trigger test
	director.current_state = DirectorPacingHookScript.PacingState.BUILDUP
	director.tension_score = 45.0
	director.time_since_last_event = 20.0
	director.airdrop_spawned = false

	var event_triggered := [false]
	var event_name := [""]
	bus.director_event_triggered.connect(func(n: String, _p: Dictionary):
		event_triggered[0] = true
		event_name[0] = n
	)

	var did_trigger: bool = director.check_and_trigger_director_event()
	_expect(did_trigger, "Director triggers airdrop event when conditions met")
	_expect(event_triggered[0] and event_name[0] == "airdrop_crate", "Airdrop event matches GDD name")


func _test_camera_juice() -> void:
	var camera = CameraScript.new()
	_expect(camera.trauma == 0.0, "Camera starts with zero trauma")
	_expect(camera.landing_dip == 0.0, "Camera starts with zero landing dip")

	camera.add_trauma(0.4)
	_expect(is_equal_approx(camera.trauma, 0.4), "add_trauma applies trauma")

	camera.add_trauma(0.8)
	_expect(is_equal_approx(camera.trauma, 1.0), "add_trauma clamps to 1.0")

	camera.add_landing_dip(5.0)
	_expect(camera.landing_dip > 0.1, "add_landing_dip calculates downward dip on landing")
	camera.free()


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + description)


func _finish() -> void:
	print("Gameplay hooks tests: %d checks; %d failures." % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
